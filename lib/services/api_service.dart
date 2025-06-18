import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static ApiService? _instance;
  String? _baseUrl;
  String? _loginUrl;
  String? _uploadUrl;

  ApiService._internal();

  static ApiService get instance {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  bool get isConfigured => _baseUrl != null && _loginUrl != null;

  String get baseUrl => _baseUrl ?? '';
  String get loginUrl => _loginUrl ?? '';
  String get uploadUrl => _uploadUrl ?? '';

  Future<void> configure(String domain) async {
    if (!domain.startsWith('http://') && !domain.startsWith('https://')) {
      domain = 'https://$domain';
    }

    if (domain.endsWith('/')) {
      domain = domain.substring(0, domain.length - 1);
    }

    // Handle different domain patterns
    String apiDomain = domain;

    // Convert frontend domains to API domains
    if (domain.contains('learn.instructohub.com')) {
      apiDomain = domain.replaceAll(
          'learn.instructohub.com', 'moodle.instructohub.com');
    } else if (domain.contains('//learn.')) {
      // Handle pattern like https://learn.client.com -> https://moodle.client.com
      apiDomain = domain.replaceAll('//learn.', '//moodle.');
    } else if (domain.contains('//www.')) {
      // Handle pattern like https://www.client.com -> https://moodle.client.com
      apiDomain = domain.replaceAll('//www.', '//moodle.');
    } else if (!domain.contains('moodle') && !domain.contains('webservice')) {
      // If no moodle in domain and no webservice, assume we need moodle subdomain
      final uri = Uri.parse(domain);
      if (uri.host.split('.').length >= 2) {
        final parts = uri.host.split('.');
        parts[0] = 'moodle'; // Replace first subdomain with 'moodle'
        apiDomain = '${uri.scheme}://${parts.join('.')}';
      }
    }

    _baseUrl = '$apiDomain/webservice/rest/server.php';
    _loginUrl = '$apiDomain/login/token.php';
    _uploadUrl = '$apiDomain/webservice/upload.php';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_domain', domain); // Store original domain
    await prefs.setString(
        'api_computed_domain', apiDomain); // Store computed API domain
    await prefs.setString('api_base_url', _baseUrl!);
    await prefs.setString('api_login_url', _loginUrl!);
    await prefs.setString('api_upload_url', _uploadUrl!);
  }

  Future<bool> loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final domain = prefs.getString('api_domain');
    final computedDomain = prefs.getString('api_computed_domain');
    final baseUrl = prefs.getString('api_base_url');
    final loginUrl = prefs.getString('api_login_url');
    final uploadUrl = prefs.getString('api_upload_url');

    if (domain != null &&
        baseUrl != null &&
        loginUrl != null &&
        uploadUrl != null) {
      _baseUrl = baseUrl;
      _loginUrl = loginUrl;
      _uploadUrl = uploadUrl;
      return true;
    }
    return false;
  }

  Future<void> clearConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_domain');
    await prefs.remove('api_computed_domain');
    await prefs.remove('api_base_url');
    await prefs.remove('api_login_url');
    await prefs.remove('api_upload_url');
    _baseUrl = null;
    _loginUrl = null;
    _uploadUrl = null;
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw Exception('ApiService not configured. Call configure() first.');
    }
  }

  Future<dynamic> _post(
      String wsfunction, String token, Map<String, String> params,
      {String? customUrl}) async {
    _ensureConfigured();

    final url = Uri.parse(
        '${customUrl ?? _baseUrl}?wsfunction=$wsfunction&moodlewsrestformat=json&wstoken=$token');

    try {
      final response = await http.post(url, body: params);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded.containsKey('exception')) {
          throw Exception('Moodle API Error: ${decoded['message']}');
        }
        return decoded;
      } else {
        throw Exception(
            'Failed to connect to the server. Status code: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> _get(
      String wsfunction, String token, Map<String, String> params) async {
    _ensureConfigured();

    final queryParams = <String, String>{
      'wsfunction': wsfunction,
      'moodlewsrestformat': 'json',
      'wstoken': token,
      ...params,
    };

    final url = Uri.parse(_baseUrl!).replace(queryParameters: queryParams);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded.containsKey('exception')) {
          throw Exception('Moodle API Error: ${decoded['message']}');
        }
        return decoded;
      } else {
        throw Exception(
            'Failed to connect to the server. Status code: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    _ensureConfigured();

    final url = Uri.parse('$_loginUrl?service=dapi');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': username.trim(),
          'password': password.trim(),
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        if (responseBody['token'] != null) {
          return {
            'success': true,
            'token': responseBody['token'],
            'data': responseBody,
          };
        } else {
          return {
            'success': false,
            'error': responseBody['error'] ?? 'Invalid username or password',
          };
        }
      } else {
        return {
          'success': false,
          'error':
              'Failed to connect to server. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getUserInfo(String token) async {
    try {
      final response = await _post('core_webservice_get_site_info', token, {});
      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> verifyToken(String token) async {
    try {
      final result = await getUserInfo(token);
      if (result['success'] == true) {
        final data = result['data'];
        return {
          'success': !(data['errorcode'] != null),
          'data': data,
        };
      }
      return result;
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<List<dynamic>> getUserCourses(String token) async {
    try {
      final userInfoResult = await getUserInfo(token);
      if (userInfoResult['success'] != true) {
        throw Exception('Failed to get user info');
      }

      final userInfo = userInfoResult['data'];
      final courses = await _post('core_enrol_get_users_courses', token, {
        'userid': userInfo['userid'].toString(),
      });

      if (courses is List) {
        for (var course in courses) {
          if (course['courseimage'] != null &&
              course['courseimage'].contains('.svg')) {
            course['courseimage'] = '/assets/defaults/course.svg';
          }
          if (course['summary'] != null) {
            course['summary'] =
                course['summary'].replaceAll(RegExp(r'<[^>]*>'), '');
          }
        }
      }

      return courses is List ? courses : [];
    } catch (e) {
      throw Exception('Failed to get user courses: ${e.toString()}');
    }
  }

  Future<List<dynamic>> getCoursePages(String courseId, String token) async {
    final response = await _post(
        'mod_page_get_pages_by_courses', token, {'courseids[0]': courseId});
    return response['pages'] ?? [];
  }

  Future<List<dynamic>> getCourseAssignments(
      String courseId, String token) async {
    final response = await _post(
        'mod_assign_get_assignments', token, {'courseids[0]': courseId});
    return response['courses']?[0]?['assignments'] ?? [];
  }

  Future<List<dynamic>> getCourseForums(String courseId, String token) async {
    return await _post(
        'mod_forum_get_forums_by_courses', token, {'courseids[0]': courseId});
  }

  Future<List<dynamic>> getQuizzesInCourse(
      String courseId, String token) async {
    final response = await _post(
        'mod_quiz_get_quizzes_by_courses', token, {'courseids[0]': courseId});
    return response['quizzes'] ?? [];
  }

  Future<List<dynamic>> getCourseResource(String courseId, String token) async {
    final response = await _post('mod_resource_get_resources_by_courses', token,
        {'courseids[0]': courseId});
    return response['resources'] ?? [];
  }

  Future<List<dynamic>> getCourseContent(String courseId, String token) async {
    final modules =
        await _post('core_course_get_contents', token, {'courseid': courseId});

    final results = await Future.wait([
      getCoursePages(courseId, token),
      getCourseAssignments(courseId, token),
      getCourseForums(courseId, token),
      getQuizzesInCourse(courseId, token),
      getCourseResource(courseId, token),
    ]);

    final pageData = results[0];
    final assignData = results[1];
    final forumData = results[2];
    final quizData = results[3];
    final resourceData = results[4];

    if (modules is List) {
      for (var section in modules) {
        if (section['modules'] is List) {
          for (var item in section['modules']) {
            dynamic foundContent;
            switch (item['modname']) {
              case 'page':
                foundContent = pageData.firstWhere(
                    (p) => p['coursemodule'] == item['id'],
                    orElse: () => null);
                break;
              case 'assign':
                foundContent = assignData.firstWhere(
                    (a) => a['cmid'] == item['id'],
                    orElse: () => null);
                break;
              case 'forum':
                foundContent = forumData.firstWhere(
                    (f) => f['cmid'] == item['id'],
                    orElse: () => null);
                break;
              case 'quiz':
                foundContent = quizData.firstWhere(
                    (q) => q['coursemodule'] == item['id'],
                    orElse: () => null);
                break;
              case 'resource':
                foundContent = resourceData.firstWhere(
                    (r) => r['coursemodule'] == item['id'],
                    orElse: () => null);
                break;
            }

            item['foundContent'] = foundContent;
          }
        }
      }
    }

    return modules is List ? modules : [];
  }

  Future<List<dynamic>> getEnrolledUsers(String courseId, String token) async {
    return await _post(
        'core_enrol_get_enrolled_users', token, {'courseid': courseId});
  }

  Future<dynamic> getUpcomingEvents(String token) async {
    return await _post('core_calendar_get_calendar_upcoming_view', token, {});
  }

  Future<List<dynamic>> getCourseCategories(String token) async {
    return await _post('core_course_get_categories', token, {});
  }

  Future<dynamic> uploadFile(
      String token, Map<String, dynamic> fileData) async {
    _ensureConfigured();

    try {
      var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl!));

      request.fields['token'] = token;
      request.fields['filearea'] = fileData['filearea'] ?? 'draft';
      request.fields['itemid'] = fileData['itemid']?.toString() ?? '0';
      request.fields['filepath'] = fileData['filepath'] ?? '/';
      request.fields['filename'] = fileData['filename'] ?? '';

      if (fileData['file'] != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'filecontent',
            fileData['file'],
            filename: fileData['filename'],
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        throw Exception(
            'Upload failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('File upload error: ${e.toString()}');
    }
  }

  Future<dynamic> callCustomAPI(
      String wsfunction, String token, Map<String, String> params,
      {String method = 'POST'}) async {
    if (method.toUpperCase() == 'GET') {
      return await _get(wsfunction, token, params);
    } else {
      return await _post(wsfunction, token, params);
    }
  }

  // Replace ONLY the testConnection method in your api_service.dart with this:

  Future<Map<String, dynamic>> testConnection(String domain) async {
    try {
      if (!domain.startsWith('http://') && !domain.startsWith('https://')) {
        domain = 'https://$domain';
      }

      if (domain.endsWith('/')) {
        domain = domain.substring(0, domain.length - 1);
      }

      // Convert learn.instructohub.com to moodle.instructohub.com
      String apiDomain = domain;
      if (domain.contains('learn.instructohub.com')) {
        apiDomain = domain.replaceAll(
            'learn.instructohub.com', 'moodle.instructohub.com');
      }

      // Test the API endpoint
      final testUrl =
          '$apiDomain/webservice/rest/server.php?wsfunction=core_webservice_get_site_info&moodlewsrestformat=json';
      final response = await http.get(Uri.parse(testUrl));

      if (response.statusCode == 200) {
        // Parse the JSON response
        final data = json.decode(response.body);

        // Check for the specific error message you're getting
        if (data['message'] != null &&
            data['message'].toString().contains('Invalid token')) {
          // This is exactly what we want! Moodle is responding correctly
          return {
            'success': true,
            'siteName': 'InstructoHub LMS',
            'siteUrl': apiDomain,
            'version': 'Moodle Connected',
            'originalDomain': domain,
            'apiDomain': apiDomain,
            'message':
                'Perfect! Moodle API is working. The "Invalid token" error is expected during testing.',
          };
        }

        // Check for any other Moodle error response (also means it's working)
        if (data['errorcode'] != null || data['exception'] != null) {
          return {
            'success': true,
            'siteName': 'LMS Instance',
            'siteUrl': apiDomain,
            'version': 'Connected',
            'originalDomain': domain,
            'apiDomain': apiDomain,
            'message': 'Moodle API detected and responding.',
          };
        }

        // If we got actual site info
        if (data['sitename'] != null) {
          return {
            'success': true,
            'siteName': data['sitename'],
            'siteUrl': data['siteurl'] ?? apiDomain,
            'version': data['release'] ?? 'Moodle',
            'originalDomain': domain,
            'apiDomain': apiDomain,
          };
        }
      }

      return {
        'success': false,
        'error': 'Server responded with status ${response.statusCode}',
        'originalDomain': domain,
        'apiDomain': apiDomain,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection failed: $e',
        'originalDomain': domain,
      };
    }
  }
}
