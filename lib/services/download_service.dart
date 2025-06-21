import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart'; // CORRECTED: Was 'moodle_api_service.dart'
import '../models/course_model.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio();
  final Map<int, StreamController<double>> _progressStreams = {};

  // --- Public API ---

  /// Returns a stream of download progress for a given course ID.
  Stream<double> getDownloadProgress(int courseId) {
    _progressStreams.putIfAbsent(courseId, () => StreamController<double>.broadcast());
    return _progressStreams[courseId]!.stream;
  }

  /// Checks if a course has been fully downloaded.
  Future<bool> isCourseDownloaded(int courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedIds = prefs.getStringList('downloaded_course_ids') ?? [];
    return downloadedIds.contains(courseId.toString());
  }

  /// Deletes a downloaded course and all its associated files.
  Future<void> deleteCourse(int courseId) async {
    final directory = await _getCourseDirectory(courseId);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    final prefs = await SharedPreferences.getInstance();
    final downloadedIds = prefs.getStringList('downloaded_course_ids') ?? [];
    downloadedIds.remove(courseId.toString());
    await prefs.setStringList('downloaded_course_ids', downloadedIds);
    _updateProgress(courseId, 0.0, isComplete: true); // Reset progress
  }

  /// Initiates the download process for a given course.
  Future<void> downloadCourse(Course course, String token) async {
    final courseId = course.id;
    if (await isCourseDownloaded(courseId)) {
        print('Course $courseId is already downloaded.');
        return;
    }

    try {
        _updateProgress(courseId, 0.0); // Start progress

        // 1. Fetch course content structure from the API
        // CORRECTED: Was 'MoodleApiService'
        final courseContent = await ApiService.instance.getCourseContent(courseId.toString(), token);
        _updateProgress(courseId, 0.1);

        // 2. Create local directories
        final courseDir = await _getCourseDirectory(courseId);
        final filesDir = Directory('${courseDir.path}/files');
        if (!await filesDir.exists()) {
            await filesDir.create(recursive: true);
        }
        _updateProgress(courseId, 0.15);

        // 3. Find all file URLs to download
        final List<Map<String, String>> filesToDownload = [];
        for (var section in courseContent) {
            if (section['modules'] is List) {
                for (var module in section['modules']) {
                    if (module['contents'] is List && (module['contents'] as List).isNotEmpty) {
                        for (var content in module['contents']) {
                           if (content['fileurl'] != null && content['filename'] != null) {
                                filesToDownload.add({
                                    'url': content['fileurl'],
                                    'filename': content['filename'],
                                });
                           }
                        }
                    }
                }
            }
        }
        _updateProgress(courseId, 0.2);

        // 4. Download all files
        if (filesToDownload.isNotEmpty) {
            double progressChunk = 0.6 / filesToDownload.length;
            for (int i = 0; i < filesToDownload.length; i++) {
                final fileInfo = filesToDownload[i];
                final localPath = '${filesDir.path}/${fileInfo['filename']}';
                final downloadUrl = '${fileInfo['url']}&token=$token';
                await _dio.download(downloadUrl, localPath);
                _updateProgress(courseId, 0.2 + ((i + 1) * progressChunk));
            }
        } else {
             _updateProgress(courseId, 0.8); // Skip to 80% if no files
        }

        // 5. Rewrite URLs in the JSON to point to local files
        final localCourseContent = _rewriteUrlsToLocal(courseContent, filesDir.path);

        // 6. Save the modified JSON locally
        final metadataFile = File('${courseDir.path}/course_data.json');
        await metadataFile.writeAsString(json.encode(localCourseContent));
        _updateProgress(courseId, 0.9);

        // 7. Mark download as complete
        final prefs = await SharedPreferences.getInstance();
        final downloadedIds = prefs.getStringList('downloaded_course_ids') ?? [];
        if (!downloadedIds.contains(courseId.toString())) {
            downloadedIds.add(courseId.toString());
            await prefs.setStringList('downloaded_course_ids', downloadedIds);
        }

        _updateProgress(courseId, 1.0, isComplete: true);
        print('Course $courseId downloaded successfully.');

    } catch (e) {
        print('Error downloading course $courseId: $e');
        _progressStreams[courseId]?.addError(e);
        await deleteCourse(courseId); // Clean up on failure
    }
  }

  // --- Private Helpers ---

  void _updateProgress(int courseId, double value, {bool isComplete = false}) {
    _progressStreams.putIfAbsent(courseId, () => StreamController<double>.broadcast());
    if (!(_progressStreams[courseId]?.isClosed ?? true)) {
       _progressStreams[courseId]!.add(value);
    }
    if (isComplete) {
       _progressStreams[courseId]?.close();
       _progressStreams.remove(courseId);
    }
  }

  Future<Directory> _getBaseDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final baseDir = Directory('${appDir.path}/offline_courses');
    if (!await baseDir.exists()) {
        await baseDir.create(recursive: true);
    }
    return baseDir;
  }

  Future<Directory> _getCourseDirectory(int courseId) async {
    final baseDir = await _getBaseDirectory();
    return Directory('${baseDir.path}/$courseId');
  }

  List<dynamic> _rewriteUrlsToLocal(List<dynamic> content, String localFilesPath) {
    String jsonContent = json.encode(content);
    // This is a simple regex, might need to be more robust
    // It finds URLs and replaces them with a local path based on the filename
    jsonContent = jsonContent.replaceAllMapped(
      RegExp(r'"fileurl":"(https?:\/\/[^"]*\/pluginfile\.php\/[^"]*?)"'),
      (match) {
        final url = match.group(1)!;
        final uri = Uri.parse(url);
        final filename = uri.pathSegments.last;
        final localPath = '$localFilesPath/$filename'.replaceAll(r'\', '/');
        return '"fileurl":"file://$localPath"';
      }
    );
    return json.decode(jsonContent);
  }
}
