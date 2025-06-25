import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:InstructoHub/models/course_model.dart';
import 'package:InstructoHub/services/api_service.dart';
import 'package:InstructoHub/services/download_service.dart';
import 'package:InstructoHub/screens/course/module_detail_screen.dart';
import 'package:InstructoHub/screens/course/page_viewer_screen.dart';
import 'package:InstructoHub/screens/course/assignment_viewer_screen.dart';
import 'package:InstructoHub/screens/course/quiz_viewer_screen.dart';
import 'package:InstructoHub/screens/course/forum_viewer_screen.dart';
import 'package:InstructoHub/screens/course/resource_viewer_screen.dart';
import 'course_catalog_screen.dart';
import 'package:InstructoHub/services/enhanced_icon_service.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';

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

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  void _listenToDownloadProgress() {
    _progressSubscription =
        _downloadService.getDownloadProgress(widget.course.id).listen(
      (progress) {
        if (!mounted) return;
        setState(() {
          _downloadProgress = progress;
          if (progress >= 1.0) {
            _isDownloaded = true;
            _downloadProgress = null;
          }
        });
      },
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Download failed: $error')));
        setState(() => _downloadProgress = null);
      },
    );
  }

  Future<void> _checkDownloadStatus() async {
    final status = await _downloadService.isCourseDownloaded(widget.course.id);
    if (mounted) setState(() => _isDownloaded = status);
  }

  Future<void> _fetchCourseDetails() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      List<dynamic> contents;
      if (_isDownloaded) {
        contents = await _loadCourseContentFromLocal();
      } else {
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
            backgroundColor: DynamicThemeService.instance.getColor('error'),
          ),
        );
      }
    }
  }

  Future<List<dynamic>> _loadCourseContentFromLocal() async {
    final appDir = await getApplicationDocumentsDirectory();
    final courseDir =
        Directory('${appDir.path}/offline_courses/${widget.course.id}');
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
      final response = await ApiService.instance.callCustomAPI(
          'core_course_get_courses_by_field',
          widget.token,
          {'field': 'id', 'value': widget.course.id.toString()},
          method: 'GET');
      if (mounted &&
          response['courses'] != null &&
          response['courses'].isNotEmpty) {
        setState(() => _courseDetails = response['courses'][0]);
      }
    } catch (e) {
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
    final theme = Theme.of(context);

    final modScreenMap = {
      'forum': ForumViewerScreen(
          module: module, foundContent: foundContent, token: widget.token),
      'assign': AssignmentViewerScreen(
          module: module, foundContent: foundContent, token: widget.token),
      'quiz': QuizViewerScreen(
          module: module, foundContent: foundContent, token: widget.token),
      'resource': ResourceViewerScreen(
          module: module,
          isOffline: _isDownloaded,
          foundContent: foundContent,
          token: widget.token),
      'page': PageViewerScreen(
          module: module,
          isOffline: _isDownloaded,
          foundContent: foundContent,
          token: widget.token),
    };

    destinationScreen = modScreenMap[module['modname']] ??
        ModuleDetailScreen(module: module, token: widget.token);

    return ListTile(
      leading: Icon(DynamicIconService.instance.getIcon(module['modname']),
          color: theme.textTheme.bodyMedium?.color),
      title: Text(module['name'] ?? 'Unnamed Module',
          style: theme.textTheme.titleSmall),
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => destinationScreen)),
    );
  }

  Widget _buildProgressBar() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    final double progress = widget.course.progress ?? 0.0;

    String statusText;
    Color statusColor;

    if (progress >= 100) {
      statusText = 'COMPLETED';
      statusColor = themeService.getColor('success');
    } else if (progress > 0) {
      statusText = 'IN PROGRESS';
      statusColor = themeService.getColor('info');
    } else {
      statusText = 'NOT STARTED';
      statusColor = themeService.getColor('warning');
    }

    return Padding(
      padding: EdgeInsets.all(themeService.getSpacing('md')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: themeService.getSpacing('md'),
                    vertical: themeService.getSpacing('xs')),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                        themeService.getBorderRadius('small'))),
                child: Text(statusText,
                    style: textTheme.labelSmall?.copyWith(
                        color: statusColor, fontWeight: FontWeight.bold)),
              ),
              Text('${progress.toStringAsFixed(0)}%',
                  style: textTheme.bodySmall?.copyWith(color: statusColor)),
            ],
          ),
          SizedBox(height: themeService.getSpacing('sm')),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(themeService.getBorderRadius('large')),
            child: LinearProgressIndicator(
              value: progress / 100.0,
              minHeight: 8,
              backgroundColor:
                  themeService.getColor('textSecondary').withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    if (_isDownloaded) {
      return IconButton(
        icon: Icon(DynamicIconService.instance.getIcon('delete')),
        tooltip: 'Delete Download',
        onPressed: () async {
          await _downloadService.deleteCourse(widget.course.id);
          setState(() => _isDownloaded = false);
          _fetchCourseDetails();
        },
      );
    }

    if (_downloadProgress != null &&
        _downloadProgress! > 0 &&
        _downloadProgress! < 1) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
              value: _downloadProgress, strokeWidth: 3),
        ),
      );
    }

    return IconButton(
      icon: Icon(DynamicIconService.instance.getIcon('download')),
      tooltip: 'Download Course',
      onPressed: () =>
          _downloadService.downloadCourse(widget.course, widget.token),
    );
  }

  Widget _buildCourseImage() {
    final themeService = DynamicThemeService.instance;
    if (widget.course.courseimage.isNotEmpty) {
      return SizedBox(
        height: 200,
        width: double.infinity,
        child: Image.network(
          widget.course.courseimage,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: themeService.getColor('secondary3'),
            child: Icon(
              DynamicIconService.instance.getIcon('course'),
              size: 80,
              color: themeService.getColor('secondary1'),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: themeService.getColor('background'),
      appBar: AppBar(
        title: Text(widget.course.fullname, overflow: TextOverflow.ellipsis),
        actions: [
          _buildDownloadButton(),
          if (widget.showCatalogButton)
            IconButton(
              icon: Icon(DynamicIconService.instance.getIcon('catalog')),
              onPressed: _navigateToCatalog,
              tooltip: 'Browse Courses',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourseImage(),
                  _buildProgressBar(),
                  Padding(
                    padding: EdgeInsets.all(themeService.getSpacing('md')),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.course.fullname,
                            style: textTheme.headlineSmall),
                        if (widget.course.summary.isNotEmpty) ...[
                          SizedBox(height: themeService.getSpacing('sm')),
                          Text(widget.course.summary,
                              style: textTheme.bodyMedium),
                        ],
                        SizedBox(height: themeService.getSpacing('md')),
                        if (_courseDetails != null &&
                            _courseDetails!['enrolledusercount'] != null)
                          Row(
                            children: [
                              Icon(
                                DynamicIconService.instance.getIcon('people'),
                                size: 16,
                                color: themeService.getColor('textSecondary'),
                              ),
                              SizedBox(width: themeService.getSpacing('sm')),
                              Text(
                                  '${_courseDetails!['enrolledusercount']} enrolled',
                                  style: textTheme.bodySmall),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const Divider(),
                  if (_courseContents.isEmpty)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No course content available.'),
                    ))
                  else
                    Builder(
                      builder: (context) {
                        final filteredSections =
                            _courseContents.asMap().entries.where((entry) {
                          final section = entry.value;
                          final modules =
                              section['modules'] as List<dynamic>? ?? [];
                          return !(section['name'] == 'General' &&
                              modules.isEmpty);
                        }).toList();

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredSections.length,
                          itemBuilder: (context, index) {
                            final entry = filteredSections[index];
                            final section = entry.value;
                            final modules =
                                section['modules'] as List<dynamic>? ?? [];

                            return Card(
                              key: Key('card_$index'),
                              margin: EdgeInsets.symmetric(
                                  horizontal: themeService.getSpacing('md'),
                                  vertical: themeService.getSpacing('sm')),
                              clipBehavior: Clip.antiAlias,
                              child: ExpansionTile(
                                key: PageStorageKey(
                                    'section_$index'), // Maintain expansion state
                                title: Text(
                                    section['name'] ?? 'Unnamed Section',
                                    style: textTheme.titleMedium),
                                children: [
                                  if (modules.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child:
                                          Text('No modules in this section.'),
                                    )
                                  else
                                    ...modules
                                        .map((module) =>
                                            _buildModuleItem(module))
                                        .toList()
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  SizedBox(height: themeService.getSpacing('lg')),
                ],
              ),
            ),
    );
  }
}
