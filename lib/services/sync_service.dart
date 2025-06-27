import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:InstructoHub/models/offline_submission_model.dart';
import 'package:InstructoHub/services/api_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const _queueKey = 'offline_submission_queue';

  // Queue assignment submission for offline/online processing
  Future<void> queueAssignmentSubmission(OfflineSubmission submission) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await _getQueue();
      
      // Remove any existing submission for the same assignment
      queue.removeWhere((s) => s.assignmentId == submission.assignmentId);
      
      // Add new submission
      queue.add(submission);
      
      // Save queue
      await prefs.setString(
        _queueKey, 
        json.encode(queue.map((s) => s.toJson()).toList())
      );
      
      print('Queued submission for assignment ${submission.assignmentId}');
    } catch (e) {
      print('Error queueing submission: $e');
      throw Exception('Failed to queue submission: $e');
    }
  }

  // Get current submission queue
  Future<List<OfflineSubmission>> _getQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_queueKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => OfflineSubmission.fromJson(json)).toList();
    } catch (e) {
      print('Error getting queue: $e');
      return [];
    }
  }

  // Get submission status for an assignment
  Future<SubmissionStatus> getSubmissionStatus(int assignmentId, {String? token}) async {
    try {
      // Check if there's a queued submission
      final queue = await _getQueue();
      if (queue.any((s) => s.assignmentId == assignmentId)) {
        return SubmissionStatus.pendingSync;
      }

      // Check server status if token is provided
      if (token != null && token.isNotEmpty) {
        try {
          final serverStatusResult = await ApiService.instance.getSubmissionStatus(token, assignmentId);
          
          if (serverStatusResult['lastattempt']?['submission']?['status'] == 'submitted') {
            return SubmissionStatus.submitted;
          }
        } catch (e) {
          print('Could not verify submission status with server: $e');
        }
      }

      return SubmissionStatus.notSubmitted;
    } catch (e) {
      print('Error getting submission status: $e');
      return SubmissionStatus.notSubmitted;
    }
  }

  // Process sync queue - try to submit all queued submissions
  Future<void> processSyncQueue(String token) async {
    if (token.isEmpty) {
      print('Cannot sync: No token provided');
      return;
    }

    try {
      final queue = await _getQueue();
      if (queue.isEmpty) {
        print('Sync queue is empty');
        return;
      }

      print('Starting sync process for ${queue.length} items...');
      List<OfflineSubmission> remainingSubmissions = List.from(queue);

      for (final submission in queue) {
        try {
          final success = await _syncSubmission(submission, token);
          if (success) {
            remainingSubmissions.removeWhere((s) => s.assignmentId == submission.assignmentId);
            print('Successfully synced assignment ${submission.assignmentId}');
          } else {
            print('Failed to sync assignment ${submission.assignmentId}');
          }
        } catch (e) {
          print('Error syncing assignment ${submission.assignmentId}: $e');
        }
      }

      // Update queue with remaining submissions
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _queueKey, 
        json.encode(remainingSubmissions.map((s) => s.toJson()).toList())
      );

      print('Sync process finished. ${remainingSubmissions.length} items remaining in queue.');
    } catch (e) {
      print('Error processing sync queue: $e');
      throw Exception('Sync process failed: $e');
    }
  }

  // Sync individual submission
  Future<bool> _syncSubmission(OfflineSubmission submission, String token) async {
    try {
      print("Attempting to sync submission for assignment ${submission.assignmentId}");
      
      // Check if file exists (if file path is provided)
      File? file;
      if (submission.filePath.isNotEmpty) {
        file = File(submission.filePath);
        if (!await file.exists()) {
          print('File not found at ${submission.filePath}. Removing from queue.');
          return true; // Remove from queue since file is missing
        }
      }

      // Determine submission type and call appropriate method
      final hasOnlineText = submission.onlineText.trim().isNotEmpty;
      final hasFile = file != null && await file.exists();

      if (hasOnlineText && hasFile) {
        // Both text and file
        await ApiService.instance.submitAssignmentDirectly(
          token: token,
          assignmentId: submission.assignmentId,
          onlineText: submission.onlineText,
          file: file,
        );
      } else if (hasOnlineText) {
        // Online text only
        await ApiService.instance.submitOnlineTextOnly(
          token: token,
          assignmentId: submission.assignmentId,
          onlineText: submission.onlineText,
        );
      } else if (hasFile) {
        // File only
        await ApiService.instance.submitFileOnly(
          token: token,
          assignmentId: submission.assignmentId,
          file: file,
        );
      } else {
        throw Exception('No content to submit');
      }

      print('Successfully synced and submitted assignment ${submission.assignmentId}');
      return true;
    } catch (e) {
      print('Failed to sync submission for assignment ${submission.assignmentId}: $e');
      return false;
    }
  }

  // Clear all queued submissions
  Future<void> clearQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_queueKey);
      print('Submission queue cleared');
    } catch (e) {
      print('Error clearing queue: $e');
    }
  }

  // Get queue size
  Future<int> getQueueSize() async {
    try {
      final queue = await _getQueue();
      return queue.length;
    } catch (e) {
      print('Error getting queue size: $e');
      return 0;
    }
  }

  // Remove specific submission from queue
  Future<void> removeFromQueue(int assignmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await _getQueue();
      
      queue.removeWhere((s) => s.assignmentId == assignmentId);
      
      await prefs.setString(
        _queueKey, 
        json.encode(queue.map((s) => s.toJson()).toList())
      );
      
      print('Removed assignment $assignmentId from queue');
    } catch (e) {
      print('Error removing from queue: $e');
    }
  }

  // Get all queued submissions (for debugging/monitoring)
  Future<List<OfflineSubmission>> getAllQueuedSubmissions() async {
    return await _getQueue();
  }

  // Check if specific assignment is queued
  Future<bool> isAssignmentQueued(int assignmentId) async {
    try {
      final queue = await _getQueue();
      return queue.any((s) => s.assignmentId == assignmentId);
    } catch (e) {
      print('Error checking if assignment is queued: $e');
      return false;
    }
  }

  // Force sync specific assignment
  Future<bool> forceSyncAssignment(int assignmentId, String token) async {
    try {
      final queue = await _getQueue();
      final submission = queue.firstWhere(
        (s) => s.assignmentId == assignmentId,
        orElse: () => throw Exception('Assignment not found in queue')
      );

      final success = await _syncSubmission(submission, token);
      
      if (success) {
        await removeFromQueue(assignmentId);
      }
      
      return success;
    } catch (e) {
      print('Error force syncing assignment $assignmentId: $e');
      return false;
    }
  }
}