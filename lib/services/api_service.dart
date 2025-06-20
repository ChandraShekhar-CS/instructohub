import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'configuration_service.dart';

class ApiService {
  static ApiService? _instance;
  String? _baseUrl;
  String? _loginUrl;
  String? _uploadUrl;
  String? _tenantName;

  ApiService._internal();

  static ApiService get instance {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  bool get isConfigured => _baseUrl != null && _loginUrl != null;

  String get baseUrl => _baseUrl ?? '';
  String get loginUrl => _loginUrl ?? '';
  String get uploadUrl => _uploadUrl ?? '';
  String get tenantName => _tenantName ?? '';

  Future<void> configure(String domain) async {
    try {
      await ConfigurationService.instance.initialize();
      
      // Clean and normalize the domain
      String cleanDomain = domain.trim();
      
      // Remove protocol if present
      if (cleanDomain.startsWith('https://')) {
        cleanDomain = cleanDomain.replaceFirst('https://', '');
      }
      if (cleanDomain.startsWith('http://')) {
        cleanDomain = cleanDomain.replaceFirst('http://', '');
      }
      
      // Remove trailing slash
      if (cleanDomain.endsWith('/')) {
        cleanDomain = cleanDomain.substring(0, cleanDomain.length - 1);
      }
      
      // Construct the full domain URL
      String fullDomain = 'https://$cleanDomain';
      
      // Extract tenant name for future use
      String? extractedTenant;
      if (cleanDomain.contains('.mdl.instructohub.com')) {
        extractedTenant = cleanDomain.split('.mdl.instructohub.com')[0];
      } else if (cleanDomain.contains('learn.instructohub.com')) {
        extractedTenant = 'learn';
        // For learn.instructohub.com, we need to convert to moodle.instructohub.com
        fullDomain = 'https://moodle.instructohub.com';
      } else {
        extractedTenant = cleanDomain;
      }

      _tenantName = extractedTenant;
      await ConfigurationService.instance.loadForDomain(fullDomain);
      
      final config = ConfigurationService.instance.currentConfig;
      
      if (config != null && config.apiEndpoints['base']?.isNotEmpty == true) {
        _baseUrl = config.apiEndpoints['base'];
        _loginUrl = config.apiEndpoints['login'];
        _uploadUrl = config.apiEndpoints['upload'];
        
        print('✅ Using dynamic configuration for tenant: $_tenantName');
        print('✅ Base URL: $_baseUrl');
      } else {
        _baseUrl = '$fullDomain/webservice/rest/server.php';
        _loginUrl = '$fullDomain/login/token.php';
        _uploadUrl = '$fullDomain/webservice/upload.php';
        print('✅ Using standard configuration for tenant: $_tenantName');
        print('✅ Base URL: $_baseUrl');
        print('✅ Login URL: $_loginUrl');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_tenant', _tenantName ?? '');
      await prefs.setString('api_domain', fullDomain);
      await prefs.setString('api_base_url', _baseUrl!);
      await prefs.setString('api_login_url', _loginUrl!);
      await prefs.setString('api_upload_url', _uploadUrl!);
      
    } catch (e) {
      print('Error in tenant configuration: $e');
      rethrow;
    }
  }

  Future<bool> loadConfiguration() async {
    try {
      await ConfigurationService.instance.initialize();
    } catch (e) {
      print('Configuration service initialization failed: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final tenant = prefs.getString('api_tenant');
    final domain = prefs.getString('api_domain');
    final baseUrl = prefs.getString('api_base_url');
    final loginUrl = prefs.getString('api_login_url');
    final uploadUrl = prefs.getString('api_upload_url');

    if (tenant != null && domain != null && baseUrl != null && loginUrl != null && uploadUrl != null) {
      _tenantName = tenant;
      _baseUrl = baseUrl;
      _loginUrl = loginUrl;
      _uploadUrl = uploadUrl;
      
      if (domain.isNotEmpty) {
        try {
          await ConfigurationService.instance.loadForDomain(domain);
        } catch (e) {
          print('Failed to load configuration for cached domain: $e');
        }
      }
      
      return true;
    }
    return false;
  }

  Future<void> clearConfiguration() async {
    try {
      await ConfigurationService.instance.clearConfiguration();
    } catch (e) {
      print('Error clearing configuration service: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_tenant');
    await prefs.remove('api_domain');
    await prefs.remove('api_computed_domain');
    await prefs.remove('api_base_url');
    await prefs.remove('api_login_url');
    await prefs.remove('api_upload_url');
    
    _tenantName = null;
    _baseUrl = null;
    _loginUrl = null;
    _uploadUrl = null;
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw Exception('ApiService not configured. Call configure() first.');
    }
  }

  String _getAPIFunction(String functionKey) {
    try {
      final config = ConfigurationService.instance.currentConfig;
      if (config != null) {
        final customFunction = config.apiFunctions[functionKey];
        if (customFunction != null && customFunction.isNotEmpty) {
          return customFunction;
        }
      }
    } catch (e) {
      print('Error getting API function from config: $e');
    }
    
    const fallbackMappings = {
      'get_site_info': 'core_webservice_get_site_info',
      'get_user_courses': 'core_enrol_get_users_courses',
      'get_course_contents': 'core_course_get_contents',
      'get_user_progress': 'local_instructohub_get_user_course_progress',
    };
    
    return fallbackMappings[functionKey] ?? functionKey;
  }

  Future<dynamic> _post(String functionKey, String token, Map<String, String> params, {String? customUrl}) async {
    _ensureConfigured();

    final wsfunction = _getAPIFunction(functionKey);
    final url = Uri.parse('${customUrl ?? _baseUrl}?wsfunction=$wsfunction&moodlewsrestformat=json&wstoken=$token');

    try {
      final response = await http.post(url, body: params);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded.containsKey('exception')) {
          throw Exception('Moodle API Error: ${decoded['message']}');
        }
        return decoded;
      } else {
        throw Exception('Failed to connect to the server. Status code: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> _get(String functionKey, String token, Map<String, String> params) async {
    _ensureConfigured();

    final wsfunction = _getAPIFunction(functionKey);
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
        throw Exception('Failed to connect to the server. Status code: ${response.statusCode}');
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
          'error': 'Failed to connect to server. Status code: ${response.statusCode}',
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
      final response = await _post('get_site_info', token, {});
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
      final courses = await _post('get_user_courses', token, {
        'userid': userInfo['userid'].toString(),
      });

      if (courses is List) {
        for (var course in courses) {
          if (course['courseimage'] != null && course['courseimage'].contains('.svg')) {
            course['courseimage'] = '/assets/defaults/course.svg';
          }
          if (course['summary'] != null) {
            course['summary'] = course['summary'].replaceAll(RegExp(r'<[^>]*>'), '');
          }
        }
      }

      return courses is List ? courses : [];
    } catch (e) {
      throw Exception('Failed to get user courses: ${e.toString()}');
    }
  }

  Future<List<dynamic>> getCoursePages(String courseId, String token) async {
    final response = await _post('get_page_content', token, {'courseids[0]': courseId});
    return response['pages'] ?? [];
  }

  Future<List<dynamic>> getCourseAssignments(String courseId, String token) async {
    final response = await _post('get_assignments', token, {'courseids[0]': courseId});
    return response['courses']?[0]?['assignments'] ?? [];
  }

  Future<List<dynamic>> getCourseForums(String courseId, String token) async {
    return await _post('get_forums', token, {'courseids[0]': courseId});
  }

  Future<List<dynamic>> getQuizzesInCourse(String courseId, String token) async {
    final response = await _post('get_quizzes', token, {'courseids[0]': courseId});
    return response['quizzes'] ?? [];
  }

  Future<List<dynamic>> getCourseResource(String courseId, String token) async {
    final response = await _post('get_resources', token, {'courseids[0]': courseId});
    return response['resources'] ?? [];
  }

  Future<List<dynamic>> getCourseContent(String courseId, String token) async {
    final modules = await _post('get_course_contents', token, {'courseid': courseId});

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
    return await _post('get_enrolled_users', token, {'courseid': courseId});
  }

  Future<dynamic> getUpcomingEvents(String token) async {
    return await _post('get_upcoming_events', token, {});
  }

  Future<dynamic> getUserProgress(String token) async {
    try {
      return await _post('get_user_progress', token, {});
    } catch (e) {
      print('Error getting user progress: $e');
      return {};
    }
  }

  Future<List<dynamic>> getCourseCategories(String token) async {
    return await _post('get_categories', token, {});
  }

  Future<dynamic> uploadFile(String token, Map<String, dynamic> fileData) async {
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
        throw Exception('Upload failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('File upload error: ${e.toString()}');
    }
  }

  Future<dynamic> callCustomAPI(String functionKey, String token, Map<String, String> params, {String method = 'POST'}) async {
    if (method.toUpperCase() == 'GET') {
      return await _get(functionKey, token, params);
    } else {
      return await _post(functionKey, token, params);
    }
  }

  Future<Map<String, dynamic>> testConnection(String domain) async {
    try {
      await ConfigurationService.instance.initialize();
      
      String testDomain = domain;
      String? tenantName;
      
      if (domain.contains('.mdl.instructohub.com')) {
        tenantName = domain.split('.mdl.instructohub.com')[0];
        if (tenantName.startsWith('https://')) {
          tenantName = tenantName.replaceFirst('https://', '');
        }
        if (tenantName.startsWith('http://')) {
          tenantName = tenantName.replaceFirst('http://', '');
        }
        testDomain = 'https://$domain';
      } else {
        testDomain = 'https://$domain.mdl.instructohub.com';
        tenantName = domain;
      }

      if (!testDomain.startsWith('http://') && !testDomain.startsWith('https://')) {
        testDomain = 'https://$testDomain';
      }

      if (testDomain.endsWith('/')) {
        testDomain = testDomain.substring(0, testDomain.length - 1);
      }

      await ConfigurationService.instance.loadForDomain(testDomain);
      
      final config = ConfigurationService.instance.currentConfig;
      String testUrl;
      
      if (config != null && config.apiEndpoints['base']?.isNotEmpty == true) {
        testUrl = '${config.apiEndpoints['base']}?wsfunction=${_getAPIFunction('get_site_info')}&moodlewsrestformat=json';
      } else {
        testUrl = '$testDomain/webservice/rest/server.php?wsfunction=core_webservice_get_site_info&moodlewsrestformat=json';
      }

      final response = await http.get(Uri.parse(testUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['message'] != null && data['message'].toString().contains('Invalid token')) {
          return {
            'success': true,
            'siteName': tenantName?.toUpperCase() ?? 'LMS Instance',
            'siteUrl': config?.apiEndpoints['api'] ?? testDomain,
            'version': 'Connected',
            'originalDomain': domain,
            'apiDomain': config?.apiEndpoints['api'] ?? testDomain,
            'tenantName': tenantName,
            'message': 'Perfect! LMS API is working. The "Invalid token" error is expected during testing.',
          };
        }

        if (data['errorcode'] != null || data['exception'] != null) {
          return {
            'success': true,
            'siteName': tenantName?.toUpperCase() ?? 'LMS Instance',
            'siteUrl': config?.apiEndpoints['api'] ?? testDomain,
            'version': 'Connected',
            'originalDomain': domain,
            'apiDomain': config?.apiEndpoints['api'] ?? testDomain,
            'tenantName': tenantName,
            'message': 'LMS API detected and responding.',
          };
        }

        if (data['sitename'] != null) {
          return {
            'success': true,
            'siteName': data['sitename'],
            'siteUrl': data['siteurl'] ?? config?.apiEndpoints['api'] ?? testDomain,
            'version': data['release'] ?? 'LMS',
            'originalDomain': domain,
            'apiDomain': config?.apiEndpoints['api'] ?? testDomain,
            'tenantName': tenantName,
          };
        }
      }

      return {
        'success': false,
        'error': 'Not registered. Please try again or contact your admin.',
        'originalDomain': domain,
        'apiDomain': config?.apiEndpoints['api'] ?? testDomain,
        'tenantName': tenantName,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Not registered. Please try again or contact your admin.',
        'originalDomain': domain,
      };
    }
  }
}