import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://moodle.instructohub.com/webservice/rest/server.php';

  static Future<dynamic> _post(String wsfunction, String token, Map<String, String> params) async {
    final url = Uri.parse('$_baseUrl?wsfunction=$wsfunction&moodlewsrestformat=json&wstoken=$token');
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

  static Future<List<dynamic>> getCoursePages(String courseId, String token) async {
    final response = await _post('mod_page_get_pages_by_courses', token, {'courseids[0]': courseId});
    return response['pages'] ?? [];
  }

  static Future<List<dynamic>> getCourseAssignments(String courseId, String token) async {
    final response = await _post('mod_assign_get_assignments', token, {'courseids[0]': courseId});
    return response['courses']?[0]?['assignments'] ?? [];
  }
  
  static Future<List<dynamic>> getCourseForums(String courseId, String token) async {
    return await _post('mod_forum_get_forums_by_courses', token, {'courseids[0]': courseId});
  }

  static Future<List<dynamic>> getQuizzesInCourse(String courseId, String token) async {
    final response = await _post('mod_quiz_get_quizzes_by_courses', token, {'courseids[0]': courseId});
    return response['quizzes'] ?? [];
  }

  static Future<List<dynamic>> getCourseResource(String courseId, String token) async {
    final response = await _post('mod_resource_get_resources_by_courses', token, {'courseids[0]': courseId});
    return response['resources'] ?? [];
  }

  static Future<List<dynamic>> getCourseContent(String courseId, String token) async {
    final modules = await _post('core_course_get_contents', token, {'courseid': courseId});

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

    for (var section in modules) {
        if (section['modules'] is List) {
            for (var item in section['modules']) {
                dynamic foundContent;
                switch(item['modname']) {
                  case 'page':
                    foundContent = pageData.firstWhere((p) => p['coursemodule'] == item['id'], orElse: () => null);
                    break;
                  case 'assign':
                    foundContent = assignData.firstWhere((a) => a['cmid'] == item['id'], orElse: () => null);
                    break;
                  case 'forum':
                    foundContent = forumData.firstWhere((f) => f['cmid'] == item['id'], orElse: () => null);
                    break;
                  case 'quiz':
                    foundContent = quizData.firstWhere((q) => q['coursemodule'] == item['id'], orElse: () => null);
                    break;
                  case 'resource':
                    foundContent = resourceData.firstWhere((r) => r['coursemodule'] == item['id'], orElse: () => null);
                    break;
                }
                
                item['foundContent'] = foundContent;
            }
        }
    }

    return modules;
  }
}