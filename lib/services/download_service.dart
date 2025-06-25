import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:InstructoHub/services/api_service.dart';
import 'package:InstructoHub/models/course_model.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio();
  final Map<int, StreamController<double>> _progressStreams = {};

  Stream<double> getDownloadProgress(int courseId) {
    _progressStreams.putIfAbsent(
        courseId, () => StreamController<double>.broadcast());
    return _progressStreams[courseId]!.stream;
  }

  Future<bool> isCourseDownloaded(int courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedIds = prefs.getStringList('downloaded_course_ids') ?? [];
    return downloadedIds.contains(courseId.toString());
  }

  Future<void> deleteCourse(int courseId) async {
    final directory = await _getCourseDirectory(courseId);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    final prefs = await SharedPreferences.getInstance();
    final downloadedIds = prefs.getStringList('downloaded_course_ids') ?? [];
    downloadedIds.remove(courseId.toString());
    await prefs.setStringList('downloaded_course_ids', downloadedIds);
    _updateProgress(courseId, 0.0, isComplete: true);
  }

  Future<void> downloadCourse(Course course, String token) async {
    final courseId = course.id;
    print('Starting download for course: ${course.fullname} (ID: $courseId)');
    
    if (await isCourseDownloaded(courseId)) {
      print('Course $courseId is already downloaded.');
      return;
    }

    try {
      _updateProgress(courseId, 0.0);

      final courseDir = await _getCourseDirectory(courseId);
      final filesDir = Directory('${courseDir.path}/files');
      if (!await filesDir.exists()) {
        await filesDir.create(recursive: true);
      }
      _updateProgress(courseId, 0.1);

      final courseMetadata = {
        'course_info': {
          'id': course.id,
          'fullname': course.fullname,
          'summary': course.summary,
          'courseimage': course.courseimage,
          'progress': course.progress ?? 0.0,
          'downloaded_at': DateTime.now().toIso8601String(),
        },
        'sections': <dynamic>[]
      };

      try {
        final courseContent = await ApiService.instance
            .getCourseContent(courseId.toString(), token);
        _updateProgress(courseId, 0.2);

        courseMetadata['sections'] = courseContent;

        final List<Map<String, String>> filesToDownload = [];
        for (var section in courseContent) {
          if (section['modules'] is List) {
            for (var module in section['modules']) {
              if (module['contents'] is List &&
                  (module['contents'] as List).isNotEmpty) {
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
        _updateProgress(courseId, 0.3);

        if (filesToDownload.isNotEmpty) {
          print('Downloading ${filesToDownload.length} files for course $courseId');
          double progressChunk = 0.5 / filesToDownload.length;
          for (int i = 0; i < filesToDownload.length; i++) {
            final fileInfo = filesToDownload[i];
            final localPath = '${filesDir.path}/${fileInfo['filename']}';
            final downloadUrl = '${fileInfo['url']}&token=$token';
            
            try {
              await _dio.download(downloadUrl, localPath);
              print('Downloaded file: ${fileInfo['filename']}');
            } catch (e) {
              print('Failed to download file ${fileInfo['filename']}: $e');
            }
            
            _updateProgress(courseId, 0.3 + ((i + 1) * progressChunk));
          }
        } else {
          _updateProgress(courseId, 0.8);
        }

        final localCourseContent = _rewriteUrlsToLocal(courseContent, filesDir.path);
        courseMetadata['sections'] = localCourseContent;

      } catch (e) {
        print('Error fetching course content: $e');
        _updateProgress(courseId, 0.8);
      }

      final metadataFile = File('${courseDir.path}/course_data.json');
      await metadataFile.writeAsString(json.encode(courseMetadata));
      _updateProgress(courseId, 0.9);

      final prefs = await SharedPreferences.getInstance();
      final downloadedIds = prefs.getStringList('downloaded_course_ids') ?? [];
      if (!downloadedIds.contains(courseId.toString())) {
        downloadedIds.add(courseId.toString());
        await prefs.setStringList('downloaded_course_ids', downloadedIds);
        print('Course $courseId marked as downloaded. Total downloaded: ${downloadedIds.length}');
      }

      _updateProgress(courseId, 1.0, isComplete: true);
      print('Course $courseId downloaded successfully.');
    } catch (e) {
      print('Error downloading course $courseId: $e');
      _progressStreams[courseId]?.addError(e);
      rethrow;
    }
  }

  void _updateProgress(int courseId, double value, {bool isComplete = false}) {
    _progressStreams.putIfAbsent(
        courseId, () => StreamController<double>.broadcast());
    if (!(_progressStreams[courseId]?.isClosed ?? true)) {
      _progressStreams[courseId]!.add(value);
    }
    if (isComplete) {
      Timer(const Duration(seconds: 1), () {
        _progressStreams[courseId]?.close();
        _progressStreams.remove(courseId);
      });
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
    jsonContent = jsonContent.replaceAllMapped(
        RegExp(r'"fileurl":"(https?:\/\/[^"]*\/pluginfile\.php\/[^"]*?)"'),
        (match) {
      final url = match.group(1)!;
      final uri = Uri.parse(url);
      final filename = uri.pathSegments.last;
      final localPath = '$localFilesPath/$filename'.replaceAll(r'\', '/');
      return '"fileurl":"file://$localPath"';
    });
    return json.decode(jsonContent);
  }
}