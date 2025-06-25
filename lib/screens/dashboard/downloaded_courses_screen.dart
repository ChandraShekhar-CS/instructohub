import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:InstructoHub/models/course_model.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';
import 'package:InstructoHub/services/download_service.dart';
import 'package:InstructoHub/screens/dashboard/course_detail_screen.dart';
import 'package:InstructoHub/screens/dashboard/course_catalog_screen.dart';
import 'package:InstructoHub/screens/dashboard/dashboard_screen.dart'; // For AppStrings

class DownloadedCoursesScreen extends StatefulWidget {
  final String token;

  const DownloadedCoursesScreen({required this.token, Key? key})
      : super(key: key);

  @override
  State<DownloadedCoursesScreen> createState() =>
      _DownloadedCoursesScreenState();
}

class _DownloadedCoursesScreenState extends State<DownloadedCoursesScreen> {
  bool _isLoading = true;
  List<Course> _downloadedCourses = [];
  String? _errorMessage;
  final DownloadService _downloadService = DownloadService();

  @override
  void initState() {
    super.initState();
    DynamicThemeService.instance.addListener(_onThemeChanged);
    _loadDownloadedCourses();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    DynamicThemeService.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  Future<void> _debugDownloadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedIds = prefs.getStringList('downloaded_course_ids') ?? [];
    
    final appDir = await getApplicationDocumentsDirectory();
    final baseDir = Directory('${appDir.path}/offline_courses');


    if (await baseDir.exists()) {
      final subdirs = await baseDir.list().toList();

      for (String courseId in downloadedIds) {
        final courseDir = Directory('${baseDir.path}/$courseId');
        final metadataFile = File('${courseDir.path}/course_data.json');
        
        if (await metadataFile.exists()) {
          try {
            final content = await metadataFile.readAsString();
            final data = json.decode(content);

            if (data is Map) {
              if (data['course_info'] != null) {
              }
              if (data['sections'] != null) {
              }
            } else if (data is List) {
              if (data.isNotEmpty && data[0] is Map) {
                final firstItem = data[0] as Map;
                
                if (firstItem['modules'] is List) {
                }
              }
            }

          } catch (e) {
            // Error reading metadata
          }
        }
      }
    }
  }

  Future<void> _loadDownloadedCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadedIds = prefs.getStringList('downloaded_course_ids') ?? [];


      if (downloadedIds.isEmpty) {
        setState(() {
          _downloadedCourses = [];
          _isLoading = false;
        });
        return;
      }

      List<Course> courses = [];
      final appDir = await getApplicationDocumentsDirectory();

      for (String courseIdStr in downloadedIds) {
        try {
          final courseId = int.parse(courseIdStr);
          final courseDir =
              Directory('${appDir.path}/offline_courses/$courseId');
          final metadataFile = File('${courseDir.path}/course_data.json');


          if (await metadataFile.exists()) {
            final jsonString = await metadataFile.readAsString();
            final courseData = json.decode(jsonString);

            if (courseData is Map<String, dynamic>) {
              if (courseData['course_info'] != null) {
                final courseInfo = courseData['course_info'];
                courses.add(Course(
                  id: courseInfo['id'],
                  fullname: courseInfo['fullname'] ?? 'Course $courseId',
                  summary: courseInfo['summary'] ?? '',
                  courseimage: courseInfo['courseimage'] ?? '',
                  progress: (courseInfo['progress'] ?? 100.0).toDouble(),
                ));
              } else {
                courses.add(Course(
                  id: courseId,
                  fullname: 'Downloaded Course $courseId',
                  summary: 'Offline course content available',
                  courseimage: '',
                  progress: 100.0,
                ));
              }
            } else if (courseData is List) {
              String courseName = 'Downloaded Course $courseId';
              String courseSummary = '';

              try {
                if (courseData.isNotEmpty && courseData[0] is Map) {
                  final firstSection = courseData[0] as Map<String, dynamic>;

                  if (firstSection['name'] != null &&
                      firstSection['name'] != 'General' &&
                      firstSection['name'].toString().isNotEmpty) {
                    courseName = firstSection['name'];
                  }

                  if (firstSection['summary'] != null &&
                      firstSection['summary'].toString().isNotEmpty) {
                    courseSummary = firstSection['summary']
                        .toString()
                        .replaceAll(RegExp(r'<[^>]*>'), '')
                        .trim();
                  }

                  if (courseName == 'Downloaded Course $courseId' &&
                      firstSection['modules'] is List &&
                      (firstSection['modules'] as List).isNotEmpty) {
                    final modules = firstSection['modules'] as List;
                    if (modules[0] is Map && modules[0]['name'] != null) {
                      courseName = 'Course: ${modules[0]['name']}';
                    }
                  }
                }
              } catch (e) {
                // Error extracting course info from old format
              }

              courses.add(Course(
                id: courseId,
                fullname: courseName,
                summary: courseSummary,
                courseimage: '',
                progress: 100.0,
              ));
            } else {
              courses.add(Course(
                id: courseId,
                fullname: 'Downloaded Course $courseId',
                summary: 'Offline course content available',
                courseimage: '',
                progress: 100.0,
              ));
            }
          } else {
            downloadedIds.remove(courseIdStr);
            await prefs.setStringList('downloaded_course_ids', downloadedIds);
          }
        } catch (e) {
          // Don't add this course but continue with others
        }
      }


      setState(() {
        _downloadedCourses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading downloaded courses: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCourse(Course course) async {
    try {
      await _downloadService.deleteCourse(course.id);
      await _loadDownloadedCourses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${course.fullname} deleted successfully'),
            backgroundColor: DynamicThemeService.instance.getColor('success'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting course: ${e.toString()}'),
            backgroundColor: DynamicThemeService.instance.getColor('error'),
          ),
        );
      }
    }
  }

  void _openCourse(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailScreen(
          course: course,
          token: widget.token,
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: themeService.getSpacing('md'),
        vertical: themeService.getSpacing('xs'),
      ),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: themeService.getColor('primary').withOpacity(0.1),
            borderRadius:
                BorderRadius.circular(themeService.getBorderRadius('medium')),
          ),
          child: course.courseimage.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(
                      themeService.getBorderRadius('medium')),
                  child: Image.network(
                    course.courseimage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.school,
                      color: themeService.getColor('primary'),
                      size: 30,
                    ),
                  ),
                )
              : Icon(
                  Icons.school,
                  color: themeService.getColor('primary'),
                  size: 30,
                ),
        ),
        title: Text(
          course.fullname,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.summary.isNotEmpty) ...[
              SizedBox(height: themeService.getSpacing('xs')),
              Text(
                course.summary.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
                style: textTheme.bodySmall?.copyWith(
                  color: themeService.getColor('textSecondary'),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: themeService.getSpacing('xs')),
            Row(
              children: [
                Icon(
                  Icons.offline_pin,
                  size: 16,
                  color: themeService.getColor('success'),
                ),
                SizedBox(width: themeService.getSpacing('xs')),
                Text(
                  'Downloaded',
                  style: textTheme.bodySmall?.copyWith(
                    color: themeService.getColor('success'),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _showDeleteConfirmation(course);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _openCourse(course),
      ),
    );
  }

  void _showDeleteConfirmation(Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Downloaded Course'),
        content: Text(
            'Are you sure you want to delete "${course.fullname}"? This will remove all offline content.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCourse(course);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.instance;

    return Scaffold(
      backgroundColor: themeService.getColor('background'),
      appBar: AppBar(
        title: const Text(AppStrings.downloadedCourses),
        backgroundColor: themeService.getColor('backgroundLight'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _debugDownloadStatus,
            tooltip: 'Debug',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDownloadedCourses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _downloadedCourses.isEmpty
                  ? _buildEmptyState()
                  : _buildCoursesList(),
    );
  }

  Widget _buildErrorState() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(themeService.getSpacing('lg')),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(themeService.getSpacing('xl')),
              decoration: BoxDecoration(
                color: themeService.getColor('error').withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error,
                size: 64,
                color: themeService.getColor('error'),
              ),
            ),
            SizedBox(height: themeService.getSpacing('lg')),
            Text(
              'Error Loading Downloads',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: themeService.getSpacing('sm')),
            Text(
              _errorMessage!,
              style: textTheme.bodyMedium?.copyWith(
                color: themeService.getColor('textSecondary'),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: themeService.getSpacing('xl')),
            ElevatedButton.icon(
              onPressed: _loadDownloadedCourses,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(themeService.getSpacing('lg')),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(themeService.getSpacing('xl')),
              decoration: BoxDecoration(
                color: themeService.getColor('primary').withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.download,
                size: 64,
                color: themeService.getColor('primary'),
              ),
            ),
            SizedBox(height: themeService.getSpacing('lg')),
            Text(
              'No Downloaded Courses',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: themeService.getSpacing('sm')),
            Text(
              'Download courses from the catalog to access them offline',
              style: textTheme.bodyMedium?.copyWith(
                color: themeService.getColor('textSecondary'),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: themeService.getSpacing('xl')),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CourseCatalogScreen(token: widget.token),
                  ),
                );
              },
              icon: const Icon(Icons.school),
              label: const Text('Browse Courses'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesList() {
    return RefreshIndicator(
      onRefresh: _loadDownloadedCourses,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
            vertical: DynamicThemeService.instance.getSpacing('md')),
        itemCount: _downloadedCourses.length,
        itemBuilder: (context, index) {
          return _buildCourseCard(_downloadedCourses[index]);
        },
      ),
    );
  }
}
