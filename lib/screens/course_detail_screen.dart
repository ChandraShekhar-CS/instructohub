import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/course_model.dart';
import '../services/api_service.dart'; 
import '../services/download_service.dart';
import 'viewers/module_detail_screen.dart';
import 'viewers/page_viewer_screen.dart';
import 'viewers/assignment_viewer_screen.dart';
import 'viewers/quiz_viewer_screen.dart';
import 'viewers/forum_viewer_screen.dart';
import 'viewers/resource_viewer_screen.dart';
import 'course_catalog_screen.dart';
import '../services/icon_service.dart';
import '../theme/dynamic_app_theme.dart';

typedef AppTheme = DynamicAppTheme;

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  final String token;
  final bool showCatalogButton;

  const CourseDetailScreen({
    required this.course,
    required this.token,
    this.showCatalogButton = false,
    Key? key,
  }) : super(key: key);

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _isLoading = true;
  List<dynamic> _courseContents = [];
  Map<String, dynamic>? _courseDetails;
  int? _expandedSectionIndex;

  // --- State for download functionality ---
  final DownloadService _downloadService = DownloadService();
  bool _isDownloaded = false;
  double? _downloadProgress;
  StreamSubscription? _progressSubscription;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus().then((_) {
      _fetchCourseDetails();
    });
    _listenToDownloadProgress();
  }

  void _listenToDownloadProgress() {
    _progressSubscription =
        _downloadService.getDownloadProgress(widget.course.id).listen(
      (progress) {
        if (!mounted) return;
        setState(() {
          _downloadProgress = progress;
          if (progress == 1.0) {
            _isDownloaded = true;
            _downloadProgress = null;
          }
        });
      },
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download failed: $error')));
        setState(() {
          _downloadProgress = null;
        });
      },
    );
  }

  Future<void> _checkDownloadStatus() async {
    final status = await _downloadService.isCourseDownloaded(widget.course.id);
    if (mounted) {
      setState(() {
        _isDownloaded = status;
      });
    }
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchCourseDetails() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      List<dynamic> contents;
      if (_isDownloaded) {
        contents = await _loadCourseContentFromLocal();
      } else {
        // CORRECTED: Was 'MoodleApiService'
        contents = await ApiService.instance
            .getCourseContent(widget.course.id.toString(), widget.token);
      }
      
      await _fetchExtendedCourseInfo();

      if (mounted) {
        setState(() {
          _courseContents = contents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching course details: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<List<dynamic>> _loadCourseContentFromLocal() async {
    final appDir = await getApplicationDocumentsDirectory();
    final courseDir = Directory('${appDir.path}/offline_courses/${widget.course.id}');
    final metadataFile = File('${courseDir.path}/course_data.json');

    if (await metadataFile.exists()) {
      final jsonString = await metadataFile.readAsString();
      return json.decode(jsonString) as List<dynamic>;
    } else {
      throw Exception('Offline data not found, please re-download.');
    }
  }

  Future<void> _fetchExtendedCourseInfo() async {
     try {
      // CORRECTED: Was 'MoodleApiService'
      final response = await ApiService.instance.callCustomAPI(
        'core_course_get_courses_by_field',
        widget.token,
        {'field': 'id', 'value': widget.course.id.toString()},
        method: 'GET'
      );
      if (mounted && response['courses'] != null && response['courses'].isNotEmpty) {
        setState(() {
          _courseDetails = response['courses'][0];
        });
      }
    } catch(e) {
        print('Could not fetch extended course info: $e');
    }
  }
  
  void _navigateToCatalog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseCatalogScreen(token: widget.token),
      ),
    );
  }

  Widget _buildModuleItem(dynamic module) {
    Widget destinationScreen;
    final dynamic foundContent = module['foundContent'];

    final modScreenMap = {
      'forum': ForumViewerScreen(module: module, foundContent: foundContent, token: widget.token),
      'assign': AssignmentViewerScreen(module: module, foundContent: foundContent, token: widget.token),
      'quiz': QuizViewerScreen(module: module, foundContent: foundContent, token: widget.token),
      'resource': ResourceViewerScreen(module: module, isOffline: _isDownloaded, foundContent: foundContent, token: widget.token),
      'page': PageViewerScreen(module: module, isOffline: _isDownloaded, foundContent: foundContent, token: widget.token),
    };

    destinationScreen = modScreenMap[module['modname']] ?? ModuleDetailScreen(module: module, token: widget.token);

    return ListTile(
      leading: Icon(
        IconService.instance.getIcon(module['modname']),
        color: AppTheme.textSecondary
      ),
      title: Text(
        module['name'] ?? 'Unnamed Module',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => destinationScreen,
          ),
        );
      },
    );
  }
  
  Widget _buildProgressBar() {
    final double progress = widget.course.progress ?? 0.0;
    
    String status;
    if (progress >= 100) {
      status = 'completed';
    } else if (progress > 0) {
      status = 'in_progress';
    } else {
      status = 'draft';
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingXs),
                decoration: AppTheme.getStatusDecoration(status),
                child: Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: AppTheme.getStatusTextStyle(status),
                ),
              ),
              Text(
                '${progress.toStringAsFixed(0)}%',
                style: AppTheme.getStatusTextStyle(status).copyWith(
                  fontSize: AppTheme.fontSizeSm,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: LinearProgressIndicator(
              value: progress / 100.0,
              minHeight: 8,
              backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.getStatusTextStyle(status).color!,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    if (_isDownloaded) {
      return IconButton(
        icon: Icon(IconService.instance.getIcon('delete')),
        tooltip: 'Delete Download',
        onPressed: () async {
          await _downloadService.deleteCourse(widget.course.id);
          setState(() {
            _isDownloaded = false;
          });
          _fetchCourseDetails();
        },
      );
    }

    if (_downloadProgress != null &&
        _downloadProgress! > 0 &&
        _downloadProgress! < 1) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
          value: _downloadProgress,
          strokeWidth: 3,
          color: AppTheme.secondary1,
        ),
      );
    }

    return IconButton(
      icon: Icon(IconService.instance.getIcon('download')),
      tooltip: 'Download Course',
      onPressed: () {
        _downloadService.downloadCourse(widget.course, widget.token);
      },
    );
  }

  Widget _buildCourseImage() {
    if (widget.course.courseimage.isNotEmpty) {
        return SizedBox(
            height: 200,
            width: double.infinity,
            child: Image.network(
                widget.course.courseimage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(
                        color: AppTheme.secondary3,
                        child: Icon(
                            IconService.instance.getIcon('course'),
                            size: 80,
                            color: AppTheme.secondary1,
                        ),
                    ),
            ),
        );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.course.fullname, overflow: TextOverflow.ellipsis),
        actions: [
          _buildDownloadButton(),
          if (widget.showCatalogButton)
            IconButton(
              icon: Icon(IconService.instance.getIcon('catalog')),
              onPressed: _navigateToCatalog,
              tooltip: 'Browse Courses',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.secondary1))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourseImage(),
                  _buildProgressBar(),
                  Padding(
                    padding: EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.course.fullname,
                          style: TextStyle(
                            fontSize: AppTheme.fontSize2xl,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary
                          ),
                        ),
                        if (widget.course.summary.isNotEmpty) ...[
                          SizedBox(height: AppTheme.spacingSm),
                          Text(
                            widget.course.summary,
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeBase,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                        SizedBox(height: AppTheme.spacingMd),
                        if (_courseDetails != null &&
                            _courseDetails!['enrolledusercount'] != null)
                          Row(
                            children: [
                              Icon(
                                IconService.instance.getIcon('people'),
                                size: AppTheme.fontSizeBase,
                                color: AppTheme.textSecondary,
                              ),
                              SizedBox(width: AppTheme.spacingSm),
                              Text(
                                '${_courseDetails!['enrolledusercount']} enrolled',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeSm,
                                  color: AppTheme.textSecondary
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                    child: const Divider(),
                  ),
                   if (_courseContents.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No course content available.'),
                    ))
                  else
                    Builder(
                      builder: (context) {
                        final filteredSections = _courseContents
                            .asMap()
                            .entries
                            .where((entry) {
                              final section = entry.value;
                              final modules = section['modules'] as List<dynamic>? ?? [];
                              return !(section['name'] == 'General' && modules.isEmpty);
                            })
                            .toList();

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredSections.length,
                          itemBuilder: (context, index) {
                            final entry = filteredSections[index];
                            final section = entry.value;
                            final modules = section['modules'] as List<dynamic>? ?? [];

                            return Card(
                              key: Key('card_$index'),
                              margin: EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  ListTile(
                                    title: Text(
                                      section['name'] ?? 'Unnamed Section',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: AppTheme.fontSizeLg,
                                      ),
                                    ),
                                    trailing: Icon(
                                      _expandedSectionIndex == index 
                                          ? IconService.instance.getIcon('expand_less')
                                          : IconService.instance.getIcon('expand_more'),
                                      color: AppTheme.textPrimary,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        if (_expandedSectionIndex == index) {
                                          _expandedSectionIndex = null;
                                        } else {
                                          _expandedSectionIndex = index;
                                        }
                                      });
                                    },
                                  ),
                                  if (_expandedSectionIndex == index)
                                    Container(
                                      child: Column(
                                        children: [
                                          const Divider(height: 1),
                                          if (modules.isEmpty)
                                            const Padding(
                                                padding: EdgeInsets.all(16.0),
                                                child: Text('No modules in this section.'),
                                            )
                                          else
                                            ...modules.map((module) => _buildModuleItem(module)).toList()
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  SizedBox(height: AppTheme.spacingLg),
                ],
              ),
            ),
    );
  }
}
