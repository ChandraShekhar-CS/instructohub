import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart'; // Assuming ApiService is in this file or imported correctly
import 'package:InstructoHub/models/offline_submission_model.dart';

// You will need to define ApiService or import it correctly
// For demonstration, a placeholder class is used.
class ApiService {
  static ApiService instance = ApiService();
  Future<Map<String, dynamic>> getSubmissionStatus(String token, int assignmentId) async {
    // This should make a real API call to your backend
    // e.g., using the function mod_assign_get_submission_status
    print('Making API call to check status for assignment $assignmentId');
    // Placeholder response. In a real app, this would be a network request.
    // A real implementation would be needed in your api_service.dart
    return {'status': 'submitted'}; // or 'notsubmitted'
  }

  Future<void> uploadFile(String token, Map<String, dynamic> data) async {
     // Placeholder for your actual file upload logic
     print("Uploading file with data: $data");
  }
}


class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const _queueKey = 'offline_submission_queue';

  /// Adds an assignment submission to the offline queue.
  Future<void> queueAssignmentSubmission(OfflineSubmission submission) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await _getQueue();
    // Prevent duplicate entries for the same assignment
    queue.removeWhere((s) => s.assignmentId == submission.assignmentId);
    queue.add(submission);
    await prefs.setString(
        _queueKey, json.encode(queue.map((s) => s.toJson()).toList()));
  }

  /// Retrieves the current submission queue from storage.
  Future<List<OfflineSubmission>> _getQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_queueKey);
    if (jsonString == null) {
      return [];
    }
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => OfflineSubmission.fromJson(json)).toList();
  }

  /// Gets the status of a specific assignment submission.
  Future<SubmissionStatus> getSubmissionStatus(int assignmentId, {String? token}) async {
    // 1. First, check if it's pending in the local offline queue.
    final queue = await _getQueue();
    final isPending = queue.any((s) => s.assignmentId == assignmentId);
    if (isPending) {
      return SubmissionStatus.pendingSync;
    }

    // 2. If not in the queue and we have a token, ask the server.
    if (token != null && token.isNotEmpty) {
      try {
        final serverStatusResult = await ApiService.instance.getSubmissionStatus(token, assignmentId);
        // NOTE: You must adapt this logic based on your actual API response structure.
        // This assumes your API returns a JSON with a 'status' key.
        final lastAttempt = serverStatusResult['lastattempt'];
        if (lastAttempt != null && lastAttempt['submission'] != null && lastAttempt['submission']['status'] == 'submitted') {
            return SubmissionStatus.submitted;
        }
      } catch (e) {
        print('Could not verify submission status with server: $e');
        // If server check fails, we can't be sure, so we default to not submitted.
        return SubmissionStatus.notSubmitted;
      }
    }

    // 3. If not in queue and no token (offline), it's not submitted from this device's perspective.
    return SubmissionStatus.notSubmitted;
  }


  /// Processes the entire queue, attempting to sync each item.
  Future<void> processSyncQueue(String token) async {
    if (token.isEmpty) return; 

    final queue = await _getQueue();
    if (queue.isEmpty) return;

    print('Starting sync process for ${queue.length} items...');

    List<OfflineSubmission> remainingSubmissions = [];

    for (final submission in queue) {
      bool success = await _syncSubmission(submission, token);
      if (!success) {
        remainingSubmissions.add(submission);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_queueKey,
        json.encode(remainingSubmissions.map((s) => s.toJson()).toList()));

    print('Sync process finished.');
  }

  /// The actual logic to sync a single submission.
  Future<bool> _syncSubmission(
      OfflineSubmission submission, String token) async {
    try {
      final file = File(submission.filePath);
      if (!await file.exists()) {
        print(
            'Error: File for submission ${submission.assignmentId} not found at ${submission.filePath}. Removing from queue.');
        return true; 
      }

      final fileBytes = await file.readAsBytes();
      final filename = submission.filePath.split('/').last;

    
      await ApiService.instance.uploadFile(token, {
        'filearea': 'draft', 
        'itemid': 0, // This needs a real draft ID from the server
        'filename': filename,
        'file': fileBytes,
        'contextid': submission.contextId,
        'component': 'mod_assign',
        'filearea_name': 'submission_files'
      });

      print(
          'Successfully synced submission for assignment ${submission.assignmentId}');
      return true;
    } catch (e) {
      print(
          'Failed to sync submission for assignment ${submission.assignmentId}: $e');
      return false;
    }
  }
}
