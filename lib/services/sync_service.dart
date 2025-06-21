import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/offline_submission_model.dart';

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
    await prefs.setString(_queueKey, json.encode(queue.map((s) => s.toJson()).toList()));
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
  Future<SubmissionStatus> getSubmissionStatus(int assignmentId) async {
      final queue = await _getQueue();
      final submission = queue.firstWhere((s) => s.assignmentId == assignmentId, orElse: () => OfflineSubmission(assignmentId: 0, filePath: ''));
      if(submission.assignmentId != 0) {
          return SubmissionStatus.pendingSync;
      }
      // Here you would normally check the server for a real submission status
      // For now, we'll assume if it's not in the queue, it's not submitted.
      return SubmissionStatus.notSubmitted;
  }

  /// Processes the entire queue, attempting to sync each item.
  Future<void> processSyncQueue(String token) async {
    // A simple check for internet connection can be added here
    if (token.isEmpty) return; // Can't sync without a token

    final queue = await _getQueue();
    if (queue.isEmpty) return;

    print('Starting sync process for ${queue.length} items...');

    List<OfflineSubmission> remainingSubmissions = [];

    for (final submission in queue) {
      bool success = await _syncSubmission(submission, token);
      if (!success) {
        // If sync fails, keep it in the queue for the next attempt
        remainingSubmissions.add(submission);
      }
    }

    // Update the queue with any remaining items
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_queueKey, json.encode(remainingSubmissions.map((s) => s.toJson()).toList()));
    
    print('Sync process finished.');
  }

  /// The actual logic to sync a single submission.
  Future<bool> _syncSubmission(OfflineSubmission submission, String token) async {
    try {
      final file = File(submission.filePath);
      if (!await file.exists()) {
        print('Error: File for submission ${submission.assignmentId} not found at ${submission.filePath}. Removing from queue.');
        return true; // Return true to remove it from the queue
      }

      final fileBytes = await file.readAsBytes();
      final filename = submission.filePath.split('/').last;
      
      // This is a simplified payload. Moodle's API for submitting an assignment
      // is more complex, often requiring a `draft` item ID first.
      // This is a placeholder for the real API call.
      await ApiService.instance.uploadFile(token, {
        'filearea': 'draft', // This usually needs to be 'submission_files' with an itemid
        'itemid': 0, // This needs to be a valid draft ID from another API call
        'filename': filename,
        'file': fileBytes,
        'contextid': submission.contextId, // You'll need to save this when downloading
        'component': 'mod_assign',
        'filearea_name': 'submission_files'
      });

      print('Successfully synced submission for assignment ${submission.assignmentId}');
      return true;
    } catch (e) {
      print('Failed to sync submission for assignment ${submission.assignmentId}: $e');
      return false;
    }
  }
}
