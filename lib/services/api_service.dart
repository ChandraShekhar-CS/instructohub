import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:InstructoHub/models/offline_submission_model.dart';
import 'configuration_service.dart';

class ApiService {
  static ApiService? _instance;
  String? _baseUrl;
  String? _loginUrl;
  String? _uploadUrl;
  String? _tenantName;
  String? _currentUserId;

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

  Future<List<dynamic>> getConversations(String token) async {
    try {
      final response = await _post('core_message_get_conversations', token, {
        'userid': await _getCurrentUserId(token),
        'limitfrom': '0',
        'limitnum': '10',
        'mergeself': '0',
      });
      return response['conversations'] is List ? response['conversations'] : [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getConversationMessages(String token, int conversationId) async {
    try {
      final response = await _post('core_message_get_conversation_messages', token, {
        'currentuserid': await _getCurrentUserId(token),
        'convid': conversationId.toString(),
        'limitfrom': '0',
        'limitnum': '0',
        'newest': '0',
        'timefrom': '0',
      });
      return response['messages'] is List ? response['messages'] : [];
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> sendMessage(String token, int recipientId, String text) async {
    try {
      return await _post('core_message_send_instant_messages', token, {
        'messages[0][touserid]': recipientId.toString(),
        'messages[0][text]': text,
        'messages[0][textformat]': '2',
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> markMessagesAsRead(String token, int conversationId) async {
    try {
      return await _post('core_message_mark_all_conversation_messages_as_read', token, {
        'userid': await _getCurrentUserId(token),
        'conversationid': conversationId.toString(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getContacts(String token) async {
    try {
      final response = await _post('core_message_get_user_contacts', token, {
        'userid': await _getCurrentUserId(token),
        'limitfrom': '0',
        'limitnum': '0',
      });
      return response is List ? response : [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> searchUsers(String token, String query) async {
    try {
      final response = await _post('core_message_search_contacts', token, {
        'searchtext': query,
        'onlymycourses': '0',
      });
      return response is List ? response : [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSubmissionStatus(String token, int assignmentId) async {
    try {
      final userId = await _getCurrentUserId(token);

      return await callCustomAPI(
        'mod_assign_get_submission_status',
        token,
        {
          'assignid': assignmentId.toString(),
          'userid': userId,
          'groupid': '0',
        },
        method: 'POST',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _getCurrentUserId(String token) async {
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      return _currentUserId!;
    }

    try {
      final userInfo = await getUserInfo(token);
      if (userInfo['success'] == true && userInfo['data']['userid'] != null) {
        _currentUserId = userInfo['data']['userid'].toString();
        return _currentUserId!;
      } else {
        throw Exception('User ID not found');
      }
    } catch (e) {
      throw Exception('Could not get user ID: ${e.toString()}');
    }
  }

  Future<int> _startSubmission(String token, int assignmentId) async {
    final result = await _post(
      'mod_assign_start_submission',
      token,
      {'assignid': assignmentId.toString()},
    );

    if (result['lastattempt']?['submission']?['plugins'] != null) {
      final plugins = result['lastattempt']['submission']['plugins'] as List;

      final filePlugin = plugins.firstWhere((p) => p['type'] == 'file', orElse: () => null);
      if (filePlugin != null && (filePlugin['fileareas'] as List).isNotEmpty) {
        return filePlugin['fileareas'][0]['itemid'] as int;
      }

      final onlinetextPlugin = plugins.firstWhere((p) => p['type'] == 'onlinetext', orElse: () => null);
      if (onlinetextPlugin != null) {
        return onlinetextPlugin['editorfields'][0]['itemid'] as int;
      }
    }
    throw Exception('Could not get a draft item ID to begin submission.');
  }

  Future<void> _saveSubmission(String token, int assignmentId, int itemId, String onlineText) async {
    await _post(
      'mod_assign_save_submission',
      token,
      {
        'assignmentid': assignmentId.toString(),
        'plugindata[onlinetext_editor][text]': onlineText,
        'plugindata[onlinetext_editor][format]': '1',
        'plugindata[files_filemanager]': itemId.toString(),
      },
    );
  }

  Future<void> _submitForGrading(String token, int assignmentId) async {
    await _post(
      'mod_assign_submit_for_grading',
      token,
      {
        'assignmentid': assignmentId.toString(),
        'acceptsubmissionstatement': '1',
      },
    );
  }

  Future<void> submitAssignmentDirectly({
    required String token,
    required int assignmentId,
    required String onlineText,
    required File file,
  }) async {
    try {
      final itemId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final fileBytes = await file.readAsBytes();
      final fileName = file.path.split('/').last;
      
      await uploadFile(token, {
        'itemid': itemId.toString(),
        'filename': fileName,
        'file': fileBytes,
        'filearea': 'draft',
        'filepath': '/',
      });
      
      await _saveSubmissionEnhanced(token, assignmentId, itemId, onlineText);
      await _submitForGradingEnhanced(token, assignmentId);

    } catch (e) {
      throw Exception('Assignment submission failed: ${e.toString()}');
    }
  }

  Future<void> submitOnlineTextOnly({
    required String token,
    required int assignmentId,
    required String onlineText,
  }) async {
    try {
      await _saveSubmissionEnhanced(token, assignmentId, 0, onlineText);
      await _submitForGradingEnhanced(token, assignmentId);
    } catch (e) {
      throw Exception('Online text submission failed: ${e.toString()}');
    }
  }

  Future<void> submitFileOnly({
    required String token,
    required int assignmentId,
    required File file,
  }) async {
    try {
      final itemId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final fileBytes = await file.readAsBytes();
      final fileName = file.path.split('/').last;
      
      await uploadFile(token, {
        'itemid': itemId.toString(),
        'filename': fileName,
        'file': fileBytes,
        'filearea': 'draft',
        'filepath': '/',
      });
      
      await _saveSubmissionEnhanced(token, assignmentId, itemId, '');
      await _submitForGradingEnhanced(token, assignmentId);
    } catch (e) {
      throw Exception('File submission failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> _uploadFileForAssignment(String token, File file) async {
    try {
      final itemId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final fileBytes = await file.readAsBytes();
      final fileName = file.path.split('/').last;
      
      final result = await uploadFile(token, {
        'itemid': itemId.toString(),
        'filename': fileName,
        'file': fileBytes,
        'filearea': 'draft',
        'filepath': '/',
      });
      
      return {
        'itemid': itemId,
        'filename': fileName,
        'filesize': fileBytes.length,
        'result': result,
      };
    } catch (e) {
      throw Exception('File upload failed: ${e.toString()}');
    }
  }

  Future<void> _saveSubmissionEnhanced(String token, int assignmentId, int itemId, String onlineText) async {
    try {
      final cleanText = onlineText.trim().isEmpty ? ' ' : onlineText.trim();
      
      final params = {
        'assignmentid': assignmentId.toString(),
        'plugindata[onlinetext_editor][text]': cleanText,
        'plugindata[onlinetext_editor][format]': '1',
        'plugindata[onlinetext_editor][itemid]': '0',
        'plugindata[files_filemanager]': itemId.toString(),
      };
      
      await callCustomAPI('mod_assign_save_submission', token, params, method: 'POST');
      
    } catch (e) {
      throw Exception('Failed to save submission: ${e.toString()}');
    }
  }

  Future<void> _submitForGradingEnhanced(String token, int assignmentId) async {
    try {
      await callCustomAPI(
        'mod_assign_submit_for_grading',
        token,
        {
          'assignmentid': assignmentId.toString(),
          'acceptsubmissionstatement': '1',
        },
        method: 'POST',
      );
    } catch (e) {
      throw Exception('Failed to submit for grading: ${e.toString()}');
    }
  }

  Future<void> submitAssignmentEnhanced({
    required String token,
    required int assignmentId,
    required String onlineText,
    required File file,
  }) async {
    try {
      final uploadResult = await _uploadFileForAssignment(token, file);
      final itemId = uploadResult['itemid'] ?? 0;
      
      await _saveSubmissionEnhanced(token, assignmentId, itemId, onlineText);
      await _submitForGradingEnhanced(token, assignmentId);
    } catch (e) {
      throw Exception('Assignment submission failed: ${e.toString()}');
    }
  }

  Future<void> submitAssignmentAlternative({
    required String token,
    required int assignmentId,
    required String onlineText,
    File? file,
  }) async {
    try {
      int itemId = 0;
      
      if (file != null) {
        itemId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final fileBytes = await file.readAsBytes();
        
        await uploadFile(token, {
          'itemid': itemId.toString(),
          'filename': file.path.split('/').last,
          'file': fileBytes,
          'filearea': 'draft',
          'filepath': '/',
        });
      }
      
      final params = <String, String>{
        'assignmentid': assignmentId.toString(),
      };
      
      if (onlineText.trim().isNotEmpty) {
        params['plugindata[onlinetext_editor][text]'] = onlineText.trim();
        params['plugindata[onlinetext_editor][format]'] = '1';
      }
      
      if (itemId > 0) {
        params['plugindata[files_filemanager]'] = itemId.toString();
      }
      
      await callCustomAPI('mod_assign_save_submission', token, params, method: 'POST');
      await callCustomAPI('mod_assign_submit_for_grading', token, {
        'assignmentid': assignmentId.toString(),
        'acceptsubmissionstatement': '1',
      }, method: 'POST');
      
    } catch (e) {
      throw Exception('Alternative submission failed: ${e.toString()}');
    }
  }

  Future<void> _saveSubmissionAlternative(String token, int assignmentId, int itemId, String onlineText) async {
    try {
      final cleanText = onlineText.trim().isEmpty ? ' ' : onlineText.trim();
      final params = <String, String>{};
      
      params['assignmentid'] = assignmentId.toString();
      
      if (cleanText.isNotEmpty && cleanText != ' ') {
        params['plugindata[onlinetext_editor][text]'] = cleanText;
        params['plugindata[onlinetext_editor][format]'] = '1';
        params['plugindata[onlinetext_editor][itemid]'] = '0';
      }
      
      if (itemId > 0) {
        params['plugindata[files_filemanager]'] = itemId.toString();
      }
      
      await _post('mod_assign_save_submission', token, params);
    } catch (e) {
      throw e;
    }
  }

  Future<Map<String, dynamic>> debugAssignmentIssue(String token, int assignmentId) async {
    final debugResults = <String, dynamic>{
      'tests': <String, dynamic>{},
      'recommendations': <String>[],
      'timestamp': DateTime.now().toIso8601String(),
      'assignmentId': assignmentId,
    };

    try {
      debugResults['tests']['userAuth'] = await _testUserAuth(token);
      debugResults['tests']['assignmentAccess'] = await _testAssignmentAccess(token, assignmentId);
      debugResults['tests']['apiEndpoints'] = await _testApiEndpoints(token);
      debugResults['tests']['fileUpload'] = await _testFileUpload(token);
      debugResults['tests']['assignmentConfig'] = await _testAssignmentConfig(token, assignmentId);
      debugResults['tests']['submissionStatus'] = await _testSubmissionStatus(token, assignmentId);
      
      debugResults['recommendations'] = _generateRecommendations(debugResults['tests']);
      
      return debugResults;
    } catch (e) {
      debugResults['error'] = e.toString();
      debugResults['recommendations'].add('Critical error occurred during debugging: ${e.toString()}');
      return debugResults;
    }
  }

  String exportDebugResults(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== ASSIGNMENT DEBUG REPORT ===');
    buffer.writeln('Generated: ${results['timestamp']}');
    buffer.writeln('Assignment ID: ${results['assignmentId']}');
    buffer.writeln('');
    
    buffer.writeln('=== TEST RESULTS ===');
    final tests = results['tests'] as Map<String, dynamic>;
    tests.forEach((testName, result) {
      final success = result['success'] ?? false;
      final status = success ? '✅ PASS' : '❌ FAIL';
      buffer.writeln('$testName: $status');
      
      if (!success && result['error'] != null) {
        buffer.writeln('  Error: ${result['error']}');
      }
      
      if (result['details'] != null) {
        buffer.writeln('  Details: ${result['details']}');
      }
      buffer.writeln('');
    });
    
    buffer.writeln('=== RECOMMENDATIONS ===');
    final recommendations = results['recommendations'] as List<String>;
    for (int i = 0; i < recommendations.length; i++) {
      buffer.writeln('${i + 1}. ${recommendations[i]}');
    }
    
    buffer.writeln('');
    buffer.writeln('=== RAW DATA ===');
    buffer.writeln(results.toString());
    
    return buffer.toString();
  }

  Future<Map<String, dynamic>> _testUserAuth(String token) async {
    try {
      final userInfo = await getUserInfo(token);
      if (userInfo['success'] == true) {
        final data = userInfo['data'];
        return {
          'success': true,
          'details': 'User: ${data['firstname']} ${data['lastname']} (ID: ${data['userid']})',
        };
      } else {
        return {
          'success': false,
          'error': 'User authentication failed',
          'details': userInfo['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _testAssignmentAccess(String token, int assignmentId) async {
    try {
      final assignments = await getCourseAssignments('1', token);
      final foundAssignment = assignments.any((a) => a['id'] == assignmentId);
      
      return {
        'success': foundAssignment,
        'details': foundAssignment 
            ? 'Assignment found in course assignments list'
            : 'Assignment not found in accessible assignments',
        'assignmentCount': assignments.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _testApiEndpoints(String token) async {
    final endpointTests = <String, bool>{};
    
    try {
      try {
        await callCustomAPI('core_webservice_get_site_info', token, {});
        endpointTests['site_info'] = true;
      } catch (e) {
        endpointTests['site_info'] = false;
      }
      
      try {
        await callCustomAPI('mod_assign_get_assignments', token, {'courseids[0]': '1'});
        endpointTests['get_assignments'] = true;
      } catch (e) {
        endpointTests['get_assignments'] = false;
      }
      
      try {
        await callCustomAPI('mod_assign_save_submission', token, {'assignmentid': '999999'});
        endpointTests['save_submission'] = true;
      } catch (e) {
        endpointTests['save_submission'] = !e.toString().contains('Invalid token');
      }
      
      final successCount = endpointTests.values.where((v) => v).length;
      
      return {
        'success': successCount >= 2,
        'details': 'Working endpoints: $successCount/${endpointTests.length}',
        'endpoints': endpointTests,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _testFileUpload(String token) async {
    try {
      final testContent = 'Test file for debugging assignment submission capabilities.';
      final testBytes = testContent.codeUnits;
      
      final result = await uploadFile(token, {
        'itemid': '0',
        'filename': 'debug_test.txt',
        'file': testBytes,
        'filearea': 'draft',
        'filepath': '/',
      });
      
      return {
        'success': true,
        'details': 'File upload successful',
        'uploadResult': result,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _testAssignmentConfig(String token, int assignmentId) async {
    try {
      final assignments = await getCourseAssignments('1', token);
      final assignment = assignments.firstWhere(
        (a) => a['id'] == assignmentId,
        orElse: () => null,
      );
      
      if (assignment == null) {
        return {
          'success': false,
          'error': 'Assignment not found',
        };
      }
      
      final configs = assignment['configs'] as List<dynamic>? ?? [];
      final submissionPlugins = configs.where((c) => 
          c['subtype'] == 'assignsubmission').toList();
      
      return {
        'success': true,
        'details': 'Assignment found with ${submissionPlugins.length} submission plugins',
        'submissionPlugins': submissionPlugins,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _testSubmissionStatus(String token, int assignmentId) async {
    try {
      final status = await getSubmissionStatus(token, assignmentId);
      return {
        'success': true,
        'details': 'Submission status retrieved successfully',
        'status': status,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  List<String> _generateRecommendations(Map<String, dynamic> tests) {
    final recommendations = <String>[];
    
    if (tests['userAuth']?['success'] != true) {
      recommendations.add('Check user authentication - token may be invalid or expired');
    }
    
    if (tests['assignmentAccess']?['success'] != true) {
      recommendations.add('Verify assignment ID and user permissions for this assignment');
    }
    
    if (tests['apiEndpoints']?['success'] != true) {
      recommendations.add('API endpoints may not be properly configured or accessible');
    }
    
    if (tests['fileUpload']?['success'] != true) {
      recommendations.add('File upload functionality is not working - check server configuration');
    }
    
    if (tests['submissionStatus']?['success'] != true) {
      recommendations.add('Cannot access submission status - assignment may not accept submissions');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('All tests passed - assignment submission should work normally');
    }
    
    return recommendations;
  }

  Future<Map<String, dynamic>> testAssignmentSubmissionCapabilities(String token, int assignmentId) async {
    final results = <String, dynamic>{
      'canGetStatus': false,
      'canUploadFile': false,
      'canSaveSubmission': false,
      'errors': <String>[],
      'warnings': <String>[],
    };
    
    try {
      try {
        await getSubmissionStatus(token, assignmentId);
        results['canGetStatus'] = true;
      } catch (e) {
        results['errors'].add('Cannot get submission status: $e');
      }
      
      try {
        final tempDir = await getTemporaryDirectory();
        final testFile = File('${tempDir.path}/test.txt');
        await testFile.writeAsString('Test submission file');
        
        final uploadResult = await _uploadFileForAssignment(token, testFile);
        results['canUploadFile'] = true;
        results['uploadResult'] = uploadResult;
        
        await testFile.delete();
      } catch (e) {
        results['errors'].add('Cannot upload files: $e');
      }
      
      try {
        await _getCurrentUserId(token);
        results['canSaveSubmission'] = true;
      } catch (e) {
        results['errors'].add('Cannot prepare for save: $e');
      }
      
      return results;
    } catch (e) {
      results['errors'].add('Test failed: $e');
      return results;
    }
  }

  Future<String> getUserRoleInCourse(String token, String courseId) async {
    try {
      final rolesData = await getUserRolesAndCapabilities(token);
      
      if (rolesData['courses'] != null) {
        for (var course in rolesData['courses']) {
          if (course['courseid'].toString() == courseId) {
            if (course['roles'] != null && course['roles'].isNotEmpty) {
              final role = course['roles'][0];
              if (role['roleid'] == 5) return 'student';
              if (role['roleid'] == 3) return 'teacher';
              if (role['roleid'] == 4) return 'teacher';
              return role['shortname'] ?? 'student';
            }
          }
        }
      }
      
      return 'student';
    } catch (e) {
      return 'student';
    }
  }

  Future<void> quickAssignmentTest(String token, int assignmentId) async {
    try {
      final userInfo = await getUserInfo(token);
      if (userInfo['success'] == true) {
        final data = userInfo['data'];
      }
      
      try {
        await getCourseAssignments('1', token);
      } catch (e) {
        // Continue test
      }
      
      try {
        await getSubmissionStatus(token, assignmentId);
      } catch (e) {
        // Continue test
      }
      
    } catch (e) {
      // Test failed
    }
  }

  Future<Map<String, dynamic>> validateAssignmentSubmission({
    required String token,
    required int assignmentId,
    String? onlineText,
    File? file,
  }) async {
    final validation = <String, dynamic>{
      'isValid': true,
      'errors': <String>[],
      'warnings': <String>[],
    };
    
    try {
      try {
        await getSubmissionStatus(token, assignmentId);
      } catch (e) {
        validation['warnings'].add('Could not verify submission status: $e');
      }
      
      try {
        await _getCurrentUserId(token);
      } catch (e) {
        validation['isValid'] = false;
        validation['errors'].add('User authentication failed: $e');
      }
      
      return validation;
    } catch (e) {
      validation['isValid'] = false;
      validation['errors'].add('Validation error: ${e.toString()}');
      return validation;
    }
  }

  Future<void> submitAssignmentManual({
    required String token,
    required int assignmentId,
    required String onlineText,
    File? file,
  }) async {
    try {
      final params = <String, String>{
        'assignmentid': assignmentId.toString(),
      };
      
      if (onlineText.trim().isNotEmpty) {
        params['onlinetext'] = onlineText.trim();
      }
      
      if (file != null) {
        final itemId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final fileBytes = await file.readAsBytes();
        
        await uploadFile(token, {
          'itemid': itemId.toString(),
          'filename': file.path.split('/').last,
          'file': fileBytes,
          'filearea': 'draft',
        });
        
        params['fileitemid'] = itemId.toString();
      }
      
      await callCustomAPI('mod_assign_save_submission', token, params, method: 'POST');
      await callCustomAPI('mod_assign_submit_for_grading', token, {
        'assignmentid': assignmentId.toString(),
        'acceptsubmissionstatement': '1',
      }, method: 'POST');
      
    } catch (e) {
      throw Exception('Manual submission failed: ${e.toString()}');
    }
  }

  Future<bool> validateAssignmentExists(String token, int assignmentId) async {
    try {
      final response = await _post('mod_assign_get_assignments', token, {
        'assignmentids[0]': assignmentId.toString(),
      });

      if (response is Map && response['assignments'] is List) {
        final assignments = response['assignments'] as List;
        return assignments.any((assignment) => assignment['id'] == assignmentId);
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getAssignmentsByCourse(String token, int courseId) async {
    try {
      final response = await _post('mod_assign_get_assignments', token, {
        'courseids[0]': courseId.toString(),
      });

      if (response is Map && response['courses'] is List) {
        final courses = response['courses'] as List;
        if (courses.isNotEmpty && courses[0]['assignments'] is List) {
          return courses[0]['assignments'] as List;
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<int?> findAssignmentIdByCmid(String token, int courseId, int cmid) async {
    try {
      final assignments = await getAssignmentsByCourse(token, courseId);

      for (var assignment in assignments) {
        if (assignment['cmid'] == cmid) {
          return assignment['id'] as int;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> configure(String domain) async {
    try {
      await ConfigurationService.instance.initialize();

      String cleanDomain = domain.trim();

      if (cleanDomain.startsWith('https://')) {
        cleanDomain = cleanDomain.replaceFirst('https://', '');
      }
      if (cleanDomain.startsWith('http://')) {
        cleanDomain = cleanDomain.replaceFirst('http://', '');
      }

      if (cleanDomain.endsWith('/')) {
        cleanDomain = cleanDomain.substring(0, cleanDomain.length - 1);
      }

      String fullDomain = 'https://$cleanDomain';

      String? extractedTenant;
      if (cleanDomain.contains('.mdl.instructohub.com')) {
        extractedTenant = cleanDomain.split('.mdl.instructohub.com')[0];
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
      } else {
        _baseUrl = '$fullDomain/webservice/rest/server.php';
        _loginUrl = '$fullDomain/login/token.php';
        _uploadUrl = '$fullDomain/webservice/upload.php';
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_tenant', _tenantName ?? '');
      await prefs.setString('api_domain', fullDomain);
      await prefs.setString('api_base_url', _baseUrl!);
      await prefs.setString('api_login_url', _loginUrl!);
      await prefs.setString('api_upload_url', _uploadUrl!);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> loadConfiguration() async {
    try {
      await ConfigurationService.instance.initialize();
    } catch (e) {}

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
        } catch (e) {}
      }

      return true;
    }
    return false;
  }

  Future<void> clearConfiguration() async {
    try {
      await ConfigurationService.instance.clearConfiguration();
    } catch (e) {}

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
    } catch (e) {}

    const fallbackMappings = {
      'get_site_info': 'core_webservice_get_site_info',
      'get_user_courses': 'core_enrol_get_users_courses',
      'get_course_contents': 'core_course_get_contents',
      'get_enrolled_users': 'core_enrol_get_enrolled_users',
      'get_upcoming_events': 'core_calendar_get_calendar_upcoming_view',
      'get_categories': 'core_course_get_categories',
      'get_assignments': 'mod_assign_get_assignments',
      'get_page_content': 'mod_page_get_pages_by_courses',
      'get_forums': 'mod_forum_get_forums_by_courses',
      'get_quizzes': 'mod_quiz_get_quizzes_by_courses',
      'get_resources': 'mod_resource_get_resources_by_courses',
      'mod_assign_get_submission_status': 'mod_assign_get_submission_status',
      'mod_assign_start_submission': 'mod_assign_start_submission',
      'mod_assign_save_submission': 'mod_assign_save_submission',
      'mod_assign_submit_for_grading': 'mod_assign_submit_for_grading',
      'get_user_progress': 'local_instructohub_get_user_course_progress',
      'local_chat_get_conversations': 'local_chat_get_conversations',
      'local_chat_get_messages': 'local_chat_get_messages',
      'local_chat_send_message': 'local_chat_send_message',
      'local_chat_mark_read': 'local_chat_mark_read',
      'local_chat_get_contacts': 'local_chat_get_contacts',
      'local_chat_search_users': 'local_chat_search_users',
      'core_message_get_conversations': 'core_message_get_conversations',
      'core_message_get_conversation_messages': 'core_message_get_conversation_messages',
      'core_message_send_instant_messages': 'core_message_send_instant_messages',
      'core_message_mark_all_conversation_messages_as_read': 'core_message_mark_all_conversation_messages_as_read',
      'core_message_get_user_contacts': 'core_message_get_user_contacts',
      'core_message_search_contacts': 'core_message_search_contacts',
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
          throw Exception('Moodle API Error for $wsfunction: ${decoded['message']}');
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

  Future<dynamic> getUserProgress(String token) async {
    try {
      final userInfoResult = await getUserInfo(token);
      if (userInfoResult['success'] != true) {
        throw Exception('Failed to get user info');
      }

      final userInfo = userInfoResult['data'];
      final userId = userInfo['userid'];

      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await _post('local_instructohub_get_user_course_progress', token, {'userid': userId.toString()});
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserRolesAndCapabilities(String token) async {
    try {
      final userInfoResult = await getUserInfo(token);
      if (userInfoResult['success'] != true) {
        throw Exception('Failed to get user info');
      }

      final userInfo = userInfoResult['data'];
      final userId = userInfo['userid'];

      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await _post('local_instructohub_get_user_roles_with_capabilities', token, {'userid': userId.toString()});
      return response is Map<String, dynamic> ? response : Map<String, dynamic>.from(response as Map);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isTeacher(String token) async {
    try {
      final rolesData = await getUserRolesAndCapabilities(token);

      if (rolesData['courses'] != null) {
        for (var course in rolesData['courses']) {
          if (course['roles'] != null) {
            for (var role in course['roles']) {
              if (role['roleid'] == 3 ||
                  role['name']?.toLowerCase().contains('teacher') == true ||
                  role['shortname']?.toLowerCase().contains('teacher') == true ||
                  role['name']?.toLowerCase().contains('editingteacher') == true) {
                return true;
              }
            }
          }
        }
      }

      if (rolesData['globalroles'] != null) {
        for (var role in rolesData['globalroles']) {
          if (role['roleid'] == 3 ||
              role['name']?.toLowerCase().contains('teacher') == true ||
              role['shortname']?.toLowerCase().contains('teacher') == true ||
              role['name']?.toLowerCase().contains('editingteacher') == true) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getTeachingCourses(String token) async {
    try {
      final userInfoResult = await getUserInfo(token);
      if (userInfoResult['success'] != true) {
        throw Exception('Failed to get user info');
      }

      final userInfo = userInfoResult['data'];
      final userId = userInfo['userid'];

      final response = await _post('local_instructohub_get_user_courses_with_roles', token, {'userid': userId.toString()});

      List<dynamic> teachingCourses = [];
      if (response is List) {
        teachingCourses = response.where((course) {
          if (course['roles'] != null) {
            return (course['roles'] as List).any((role) =>
                role['roleid'] == 3 ||
                role['shortname']?.toLowerCase().contains('teacher') == true ||
                role['name']?.toLowerCase().contains('teacher') == true ||
                role['name']?.toLowerCase().contains('editingteacher') == true);
          }
          return false;
        }).toList();
      }

      return teachingCourses;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getTeacherMetrics(String token) async {
    try {
      final userInfoResult = await getUserInfo(token);
      if (userInfoResult['success'] != true) {
        throw Exception('Failed to get user info');
      }

      final userInfo = userInfoResult['data'];
      final userId = userInfo['userid'];

      final response = await _post('local_instructohub_get_teacher_metrics', token, {'userid': userId.toString()});
      return response is Map<String, dynamic> ? response : Map<String, dynamic>.from(response as Map);
    } catch (e) {
      try {
        final teachingCourses = await getTeachingCourses(token);
        int totalStudents = 0;
        int pendingAssignments = 0;

        for (var course in teachingCourses) {
          totalStudents += (course['enrolleduserscount'] ?? 0) as int;
        }

        return <String, dynamic>{
          'coursesTaught': teachingCourses.length,
          'totalStudents': totalStudents,
          'pendingGrading': pendingAssignments,
          'avgCourseCompletion': 0.0,
        };
      } catch (e) {
        return <String, dynamic>{
          'coursesTaught': 0,
          'totalStudents': 0,
          'pendingGrading': 0,
          'avgCourseCompletion': 0.0,
        };
      }
    }
  }

  Future<List<dynamic>> getPendingAssignments(String token) async {
    try {
      final userInfoResult = await getUserInfo(token);
      if (userInfoResult['success'] != true) {
        throw Exception('Failed to get user info');
      }

      final userInfo = userInfoResult['data'];
      final userId = userInfo['userid'];

      final response = await _post('local_instructohub_get_teacher_pending_assignments', token, {'userid': userId.toString()});
      return response is List ? response : [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getStudentProgress(String courseId, String token) async {
    try {
      final response = await _post('local_instructohub_get_student_progress', token, {'courseid': courseId});
      return response is List ? response : [];
    } catch (e) {
      return [];
    }
  }

  Future<dynamic> createCourse(String token, Map<String, dynamic> courseData) async {
    try {
      final params = <String, String>{
        'courses[0][fullname]': courseData['fullname'].toString(),
        'courses[0][shortname]': courseData['shortname'].toString(),
        'courses[0][categoryid]': courseData['categoryid'].toString(),
        'courses[0][newsitems]': '0',
      };
      
      if (courseData['summary'] != null) {
        params['courses[0][summary]'] = courseData['summary'].toString();
      }
      if (courseData['startdate'] != null) {
        params['courses[0][startdate]'] = courseData['startdate'].toString();
      }
      if (courseData['enddate'] != null) {
        params['courses[0][enddate]'] = courseData['enddate'].toString();
      }
      
      return await _post('core_course_create_courses', token, params);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getCourseStudents(String courseId, String token) async {
    try {
      final students = await getEnrolledUsers(courseId, token);

      if (students is List) {
        return students.where((user) {
          if (user['roles'] != null) {
            return (user['roles'] as List).any((role) =>
                role['roleid'] == 5 ||
                role['shortname']?.toLowerCase().contains('student') == true);
          }
          return true;
        }).toList();
      }

      return students is List ? students : [];
    } catch (e) {
      return [];
    }
  }

  Future<dynamic> sendCourseAnnouncement(
    String token, {
    required String courseId,
    required String subject,
    required String message,
  }) async {
    try {
      final response = await _post('local_instructohub_send_course_announcement', token, {
        'courseid': courseId,
        'subject': subject,
        'message': message,
      });
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> gradeAssignment(
    String token, {
    required String assignmentId,
    required String userId,
    required String grade,
    String? feedback,
  }) async {
    try {
      final response = await _post('local_instructohub_grade_assignment', token, {
        'assignmentid': assignmentId,
        'userid': userId,
        'grade': grade,
        if (feedback != null) 'feedback': feedback,
      });
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCourseAnalytics(String courseId, String token) async {
    try {
      final response = await _post('local_instructohub_get_course_analytics', token, {'courseid': courseId});
      return response is Map<String, dynamic> ? response : Map<String, dynamic>.from(response as Map);
    } catch (e) {
      return <String, dynamic>{};
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
    }

    return modules is List ? modules : [];
  }

  Future<List<dynamic>> getEnrolledUsers(String courseId, String token) async {
    return await _post('get_enrolled_users', token, {'courseid': courseId});
  }

  Future<dynamic> getUpcomingEvents(String token) async {
    return await _post('get_upcoming_events', token, {});
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
            'file',
            fileData['file'],
            filename: fileData['filename'],
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final decoded = json.decode(responseBody);
        if (decoded is Map && decoded.containsKey('error')) {
          throw Exception('File upload error: ${decoded['error']}');
        }
        return decoded;
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

  Future<Map<String, dynamic>?> getBrandingConfig() async {
    try {
      final response = await _post('local_instructohub_get_branding_config', '', {});
      return response is Map ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getThemeConfig({String? token}) async {
    try {
      final response = await _post('local_instructohub_get_theme_config', token ?? '', {});
      return response is Map ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getIconConfig({String? token}) async {
    try {
      final response = await _post('local_instructohub_get_icon_config', token ?? '', {});
      return response is Map ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTenantConfig({String? token}) async {
    try {
      final response = await _post('local_instructohub_get_tenant_config', token ?? '', {
        'tenant': _tenantName ?? '',
        'include_branding': 'true',
        'include_theme': 'true',
        'include_icons': 'true',
      });
      return response is Map ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getLogoUrl() async {
    try {
      final brandingConfig = await getBrandingConfig();
      if (brandingConfig != null) {
        final logoUrl = brandingConfig['logo_url'] ?? brandingConfig['site_logo'];
        if (logoUrl != null && logoUrl.toString().isNotEmpty) {
          return logoUrl.toString();
        }
      }

      if (_tenantName != null && _tenantName!.isNotEmpty) {
        return 'https://static.instructohub.com/staticfiles/assets/tenants/$_tenantName/logo.png';
      }

      return 'https://static.instructohub.com/staticfiles/assets/images/website/Instructo_hub_logo.png';
    } catch (e) {
      return 'https://static.instructohub.com/staticfiles/assets/images/website/Instructo_hub_logo.png';
    }
  }

  Future<bool> validateLogoUrl(String logoUrl) async {
    try {
      final response = await http.head(Uri.parse(logoUrl));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getComprehensiveSiteInfo() async {
    try {
      final siteInfo = await getUserInfo('');
      final brandingConfig = await getBrandingConfig();
      final logoUrl = await getLogoUrl();

      return {
        'site_info': siteInfo['data'] ?? {},
        'branding': brandingConfig ?? {},
        'logo_url': logoUrl,
        'tenant_name': _tenantName,
        'base_url': _baseUrl,
        'success': true,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'tenant_name': _tenantName,
        'base_url': _baseUrl,
      };
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

  // New APIs from JavaScript file that weren't in the Dart file

  Future<List<dynamic>> getForumDiscussions(String token, int forumId) async {
    try {
      return await _post('mod_forum_get_forum_discussions', token, {
        'forumid': forumId.toString(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getForumDiscussionsPosts(String token, int discussionId) async {
    try {
      final response = await _post('mod_forum_get_discussion_posts', token, {
        'discussionid': discussionId.toString(),
      });
      return response['posts'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUnreadNotificationCount(String token) async {
    try {
      final userId = await _getCurrentUserId(token);
      return await _post('core_message_get_unread_notification_count', token, {
        'useridto': userId,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getUnreadNotificationsData(String token, {int limit = 10, int offset = 0}) async {
    try {
      final userId = await _getCurrentUserId(token);
      final response = await _post('core_message_get_messages', token, {
        'useridto': userId,
        'useridfrom': '0',
        'type': 'notifications',
        'read': '0',
        'newestfirst': '1',
        'limitfrom': offset.toString(),
        'limitnum': limit.toString(),
      });
      return response['messages'] ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<dynamic> markSingleNotificationAsRead(String token, int notificationId) async {
    try {
      final userId = await _getCurrentUserId(token);
      return await _post('local_instructohub_mark_notification_read', token, {
        'userid': userId,
        'notificationid': notificationId.toString(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> markAllNotificationsAsRead(String token) async {
    try {
      final userId = await _getCurrentUserId(token);
      return await _post('core_message_mark_all_notifications_as_read', token, {
        'useridto': userId,
        'useridfrom': '0',
        'timecreatedto': '0',
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String token, {String field = 'id'}) async {
    try {
      final userId = await _getCurrentUserId(token);
      final response = await _post('core_user_get_users', token, {
        'criteria[0][key]': field,
        'criteria[0][value]': userId,
      });
      return response['users']?[0] ?? {};
    } catch (e) {
      return {};
    }
  }

  Future<dynamic> updateOwnProfile(String token, Map<String, dynamic> userData) async {
    try {
      final params = <String, String>{
        'username': userData['username'].toString(),
        'firstname': userData['firstname'].toString(),
        'lastname': userData['lastname'].toString(),
      };
      
      if (userData['city'] != null) params['city'] = userData['city'].toString();
      if (userData['country'] != null) params['country'] = userData['country'].toString();
      if (userData['password'] != null) params['password'] = userData['password'].toString();
      
      return await _post('local_instructohub_update_own_profile', token, params);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getQuizAttemptStatus(String token, int quizId) async {
    try {
      final userId = await _getCurrentUserId(token);
      return await _post('local_instructohub_get_quiz_attempts_status', token, {
        'quizid': quizId.toString(),
        'userid': userId,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getQuizQuestionsAndAnswers(String token, int quizId) async {
    try {
      return await _post('local_instructohub_get_quiz_question_details', token, {
        'quizid': quizId.toString(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> startQuizAttempt(String token, int quizId) async {
    try {
      return await _post('mod_quiz_start_attempt', token, {
        'quizid': quizId.toString(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getQuizUserAttempts(String token, int quizId) async {
    try {
      final response = await _post('mod_quiz_get_user_attempts', token, {
        'quizid': quizId.toString(),
        'status': 'all',
        'includepreviews': '1',
      });
      return response['attempts'] ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<dynamic> submitQuizQuestions(String token, List<Map<String, dynamic>> questionsData) async {
    try {
      final params = <String, String>{};
      
      for (int i = 0; i < questionsData.length; i++) {
        final question = questionsData[i];
        params['questions[$i][attemptid]'] = question['attemptid'].toString();
        params['questions[$i][questionid]'] = question['questionid'].toString();
        params['questions[$i][questiontype]'] = question['questiontype'];
        params['questions[$i][response]'] = question['response'];
      }
      
      return await _post('local_instructohub_submit_question', token, params);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> finishQuizAttempt(String token, int attemptId) async {
    try {
      return await _post('local_instructohub_finish_attempt', token, {
        'attemptid': attemptId.toString(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> createForum(String token, {
    required int courseId,
    required int sectionId,
    required String name,
    required String description,
  }) async {
    try {
      return await _post('local_instructohub_create_forum', token, {
        'courseid': courseId.toString(),
        'sectionid': sectionId.toString(),
        'name': name,
        'description': description,
        'type': 'general',
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> addForumDiscussion(String token, Map<String, String> params) async {
    try {
      return await _post('mod_forum_add_discussion', token, params);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> addForumDiscussionPost(String token, Map<String, String> params) async {
    try {
      return await _post('mod_forum_add_discussion_post', token, params);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> deleteForumDiscussionPost(String token, int postId) async {
    try {
      return await _post('mod_forum_delete_post', token, {
        'postid': postId.toString(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updatePageContent(String token, {
    required int pageId,
    required String content,
    required String title,
    required String description,
  }) async {
    try {
      return await _post('local_instructohub_update_page_content', token, {
        'pageid': pageId.toString(),
        'title': title,
        'description': description,
        'content': content,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updateQuizDetails(String token, {
    required int quizId,
    required String name,
    required String intro,
    required int timeLimit,
    required int gradeMethod,
    required int attempts,
  }) async {
    try {
      return await _post('local_instructohub_update_quiz_settings', token, {
        'quizid': quizId.toString(),
        'name': name,
        'intro': intro,
        'introformat': '1',
        'timelimit': timeLimit.toString(),
        'grademethod': gradeMethod.toString(),
        'attempts': attempts.toString(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getCourseSections(String token, int courseId) async {
    try {
      return await _post('core_course_get_contents', token, {
        'courseid': courseId.toString(),
      });
    } catch (e) {
      return [];
    }
  }

  Future<dynamic> createAssignment(String token, {
    required int courseId,
    required int sectionId,
    required String name,
    required String description,
    required int allowSubmissionsFromDate,
    required int dueDate,
    required String activityInstruction,
    required List<String> submissionTypes,
    required String fileTypes,
    required String additionalFilesId,
  }) async {
    try {
      final params = {
        'courseid': courseId.toString(),
        'sectionid': sectionId.toString(),
        'name': name,
        'description': description,
        'allowsubmissionsfromdate': allowSubmissionsFromDate.toString(),
        'duedate': dueDate.toString(),
        'activityinstruction': activityInstruction,
      };
      
      String submissionTypesQuery = '';
      for (int i = 0; i < submissionTypes.length; i++) {
        submissionTypesQuery += '&submissiontypes[$i]=${submissionTypes[i]}';
      }
      
      final customUrl = '$_baseUrl?wsfunction=local_instructohub_create_assignment&moodlewsrestformat=json$submissionTypesQuery&filetypes=${Uri.encodeComponent(fileTypes)}&additionalfiles=$additionalFilesId&wstoken=$token';
      
      final response = await http.post(Uri.parse(customUrl), body: params);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded.containsKey('exception')) {
          throw Exception('API Error: ${decoded['message']}');
        }
        return decoded;
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> createSection(String token, {
    required int courseId,
    int position = 0,
    int number = 1,
    String name = 'New Module',
  }) async {
    try {
      return await _post('local_instructohub_create_sections', token, {
        'courseid': courseId.toString(),
        'position': position.toString(),
        'number': number.toString(),
        'name': name,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updateSectionName(String token, int sectionId, String name) async {
    try {
      return await _post('local_instructohub_update_section_name', token, {
        'sectionid': sectionId.toString(),
        'name': name,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> deleteSection(String token, int sectionId) async {
    try {
      return await _post('local_instructohub_delete_section', token, {
        'sectionid': sectionId.toString(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> createQuiz(String token, {
    required int courseId,
    required int sectionId,
    required String name,
    required String description,
    int timeLimit = 3600,
    int gradeMethod = 3,
    int attempts = 10,
  }) async {
    try {
      return await _post('local_instructohub_create_quiz', token, {
        'courseid': courseId.toString(),
        'sectionid': sectionId.toString(),
        'name': name,
        'description': description,
        'timelimit': timeLimit.toString(),
        'grademethod': gradeMethod.toString(),
        'attempts': attempts.toString(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> createSingleChoiceQuestions(String token, {
    required int quizId,
    required List<Map<String, dynamic>> questions,
  }) async {
    try {
      final params = <String, String>{
        'quizid': quizId.toString(),
      };
      
      for (int qi = 0; qi < questions.length; qi++) {
        final q = questions[qi];
        params['questions[$qi][name]'] = q['name'];
        params['questions[$qi][text]'] = q['text'];
        
        final answers = q['answers'] as List;
        for (int ai = 0; ai < answers.length; ai++) {
          final a = answers[ai];
          params['questions[$qi][answers][$ai][answer]'] = a['answer'];
          params['questions[$qi][answers][$ai][fraction]'] = a['fraction'].toString();
        }
      }
      
      return await _post('local_instructohub_create_quiz_questions', token, params);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> editForum(String token, {
    required int forumId,
    required String name,
    required String intro,
  }) async {
    try {
      return await _post('local_instructohub_update_forum_settings', token, {
        'forumid': forumId.toString(),
        'name': name,
        'intro': intro,
        'introformat': '1',
        'type': 'general',
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> createPage(String token, {
    required int courseId,
    required int sectionId,
    required String name,
    required String content,
    required String description,
  }) async {
    try {
      return await _post('local_instructohub_create_page', token, {
        'courseid': courseId.toString(),
        'sectionid': sectionId.toString(),
        'name': name,
        'description': description,
        'content': content,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> editAssignment(String token, {
    required int assignmentId,
    required String name,
    required String description,
    required int allowSubmissionsFromDate,
    required int dueDate,
    required String activityInstruction,
    required List<String> submissionTypes,
    required String fileTypes,
    required String additionalFilesId,
  }) async {
    try {
      final params = {
        'assignmentid': assignmentId.toString(),
        'name': name,
        'description': description,
        'allowsubmissionsfromdate': allowSubmissionsFromDate.toString(),
        'duedate': dueDate.toString(),
        'activityinstruction': activityInstruction,
      };
      
      String submissionTypesQuery = '';
      for (int i = 0; i < submissionTypes.length; i++) {
        submissionTypesQuery += '&submissiontypes[$i]=${submissionTypes[i]}';
      }
      
      final customUrl = '$_baseUrl?wsfunction=local_instructohub_update_assignment_settings&moodlewsrestformat=json$submissionTypesQuery&filetypes=${Uri.encodeComponent(fileTypes)}&additionalfiles=$additionalFilesId&wstoken=$token';
      
      final response = await http.post(Uri.parse(customUrl), body: params);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded.containsKey('exception')) {
          throw Exception('API Error: ${decoded['message']}');
        }
        return decoded;
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> deleteForum(String token, int forumId) async {
    try {
      return await _post('local_instructohub_delete_forum', token, {
        'forumid': forumId.toString(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> deleteAssignment(String token, int assignmentId) async {
    try {
      return await _post('local_instructohub_delete_assignment', token, {
        'assignmentid': assignmentId.toString(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> deleteQuiz(String token, int quizId) async {
    try {
      return await _post('local_instructohub_delete_quiz', token, {
        'quizid': quizId.toString(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> deletePage(String token, int pageId) async {
    try {
      return await _post('local_instructohub_delete_page', token, {
        'pageid': pageId.toString(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> createResourceActivity(String token, {
    required int courseId,
    required int sectionId,
    required String name,
    required String intro,
    required String fileItemId,
  }) async {
    try {
      return await _post('local_instructohub_create_resource_activity', token, {
        'courseid': courseId.toString(),
        'sectionid': sectionId.toString(),
        'name': name,
        'intro': intro,
        'fileitemid': fileItemId,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updateResourceActivity(String token, {
    required int activityId,
    required String name,
    required String intro,
    required String fileItemId,
  }) async {
    try {
      return await _post('local_instructohub_update_resource_activity', token, {
        'activityid': activityId.toString(),
        'name': name,
        'intro': intro,
        'fileitemid': fileItemId,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> deleteResourceActivity(String token, int activityId) async {
    try {
      return await _post('local_instructohub_delete_resource_activity', token, {
        'activityid': activityId.toString(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getUserCoursesWithRoles(String token) async {
    try {
      final userId = await _getCurrentUserId(token);
      return await _post('local_instructohub_get_user_courses_with_roles', token, {
        'userid': userId,
      });
    } catch (e) {
      return [];
    }
  }

  Future<dynamic> updateUser(String token, Map<String, dynamic> userData) async {
    try {
      final params = <String, String>{
        'users[0][id]': userData['id'].toString(),
        'users[0][username]': userData['username'].toString(),
        'users[0][firstname]': userData['firstname'].toString(),
        'users[0][lastname]': userData['lastname'].toString(),
        'users[0][email]': userData['email'].toString(),
      };
      
      if (userData['password'] != null) params['users[0][password]'] = userData['password'].toString();
      if (userData['city'] != null) params['users[0][city]'] = userData['city'].toString();
      if (userData['country'] != null) params['users[0][country]'] = userData['country'].toString();
      
      return await _post('core_user_update_users', token, params);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> deleteUser(String token, dynamic userIds) async {
    try {
      final idsArray = userIds is List ? userIds : [userIds];
      final params = <String, String>{};
      
      for (int i = 0; i < idsArray.length; i++) {
        params['userids[$i]'] = idsArray[i].toString();
      }
      
      return await _post('core_user_delete_users', token, params);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> enrollUsersToCourse(String token, int courseId, List<int> userIds, {int roleId = 5}) async {
    try {
      final results = <String, dynamic>{
        'successful': [],
        'failed': [],
        'totalProcessed': userIds.length,
      };
      
      for (final userId in userIds) {
        try {
          await _post('local_instructohub_enrol_user_in_course', token, {
            'userid': userId.toString(),
            'courseid': courseId.toString(),
            'roleid': roleId.toString(),
          });
          results['successful'].add(userId);
        } catch (e) {
          results['failed'].add({
            'userId': userId,
            'error': e.toString(),
          });
        }
      }
      
      return results;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> selfEnrollInCourse(String token, int courseId) async {
    try {
      return await _post('local_instructohub_self_enrol_user_in_course', token, {
        'courseid': courseId.toString(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updateUserProfilePicture(String token, {int? userId, required int draftItemId}) async {
    try {
      final params = {
        'userid': (userId ?? 0).toString(),
        'draftitemid': draftItemId.toString(),
      };
      
      return await _post('core_user_update_picture', token, params);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getCoursesByCategories(String token) async {
    try {
      return await _post('local_instructohub_get_all_courses', token, {});
    } catch (e) {
      return [];
    }
  }

  Future<dynamic> createCourseCategory(String token, Map<String, dynamic> categoryData) async {
    try {
      final params = <String, String>{
        'categories[0][name]': categoryData['name'].toString(),
        'categories[0][parent]': '0',
      };
      
      if (categoryData['description'] != null) {
        params['categories[0][description]'] = categoryData['description'].toString();
      }
      if (categoryData['idnumber'] != null) {
        params['categories[0][idnumber]'] = categoryData['idnumber'].toString();
      }
      
      return await _post('core_course_create_categories', token, params);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateCourseCategory(String token, Map<String, dynamic> categoryData) async {
    try {
      final params = <String, String>{
        'categories[0][id]': categoryData['id'].toString(),
      };
      
      if (categoryData['name'] != null) params['categories[0][name]'] = categoryData['name'].toString();
      if (categoryData['idnumber'] != null) params['categories[0][idnumber]'] = categoryData['idnumber'].toString();
      if (categoryData['description'] != null) params['categories[0][description]'] = categoryData['description'].toString();
      
      await _post('core_course_update_categories', token, params);
      
      return {
        'success': true,
        'status': 200,
        'categoryId': categoryData['id'],
      };
    } catch (e) {
      return {
        'success': false,
        'status': 0,
        'error': e.toString(),
        'categoryId': categoryData['id'],
      };
    }
  }

  Future<dynamic> deleteCourseCategory(String token, int categoryId, {int recursive = 1}) async {
    try {
      return await _post('core_course_delete_categories', token, {
        'categories[0][id]': categoryId.toString(),
        'categories[0][recursive]': recursive.toString(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> setCourseOverviewImage(String token, {required int courseId, required int draftItemId}) async {
    try {
      return await _post('local_instructohub_set_course_overview_image', token, {
        'courseid': courseId.toString(),
        'draftitemid': draftItemId.toString(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> createUser(String token, Map<String, dynamic> userData) async {
    try {
      final params = <String, String>{
        'users[0][username]': userData['username'].toString(),
        'users[0][password]': userData['password'].toString(),
        'users[0][firstname]': userData['firstname'].toString(),
        'users[0][lastname]': userData['lastname'].toString(),
        'users[0][email]': userData['email'].toString(),
      };
      
      if (userData['city'] != null) params['users[0][city]'] = userData['city'].toString();
      if (userData['country'] != null) params['users[0][country]'] = userData['country'].toString();
      
      return await _post('core_user_create_users', token, params);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> deleteCourse(String token, dynamic courseIds) async {
    try {
      final idsArray = courseIds is List ? courseIds : [courseIds];
      final params = <String, String>{};
      
      for (int i = 0; i < idsArray.length; i++) {
        params['courseids[$i]'] = idsArray[i].toString();
      }
      
      return await _post('core_course_delete_courses', token, params);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updateCourse(String token, Map<String, dynamic> courseData) async {
    try {
      final params = <String, String>{
        'courses[0][id]': courseData['id'].toString(),
        'courses[0][fullname]': courseData['fullname'].toString(),
        'courses[0][shortname]': courseData['shortname'].toString(),
        'courses[0][categoryid]': courseData['categoryid'].toString(),
        'courses[0][newsitems]': '0',
      };
      
      if (courseData['summary'] != null) params['courses[0][summary]'] = courseData['summary'].toString();
      if (courseData['startdate'] != null) params['courses[0][startdate]'] = courseData['startdate'].toString();
      if (courseData['enddate'] != null) params['courses[0][enddate]'] = courseData['enddate'].toString();
      
      return await _post('core_course_update_courses', token, params);
    } catch (e) {
      rethrow;
    }
  }
}