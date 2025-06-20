import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/course_model.dart';
// import '../theme/app_theme.dart'; // REMOVED: Old theme import
import '../services/api_service.dart';
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
  
  @override
  void initState() {
    super.initState();
    _fetchCourseDetails();
  }

  Future<void> _fetchCourseDetails() async {
    setState(() => _isLoading = true);

    try {
      final contents = await ApiService.instance.getCourseContent(widget.course.id.toString(), widget.token);
      
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
              backgroundColor: AppTheme.error, // CHANGED: Using theme color
          ),
        );
      }
    }
  }

  Future<void> _fetchExtendedCourseInfo() async {
    final url = Uri.parse(
        '${ApiService.instance.baseUrl}?wsfunction=core_course_get_courses_by_field&moodlewsrestformat=json&wstoken=${widget.token}&field=id&value=${widget.course.id}');

    final response = await http.post(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['courses'] != null && data['courses'].isNotEmpty) {
        if (mounted) {
          setState(() {
            _courseDetails = data['courses'][0];
          });
        }
      }
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

  // REFACTORED: This widget now uses the dynamic icon service
  Widget _buildModuleItem(dynamic module) {
    Widget destinationScreen;
    final dynamic foundContent = module['foundContent'];

    // Use a helper map for cleaner assignment
    final modScreenMap = {
      'forum': ForumViewerScreen(module: module, foundContent: foundContent, token: widget.token),
      'assign': AssignmentViewerScreen(module: module, foundContent: foundContent, token: widget.token),
      'quiz': QuizViewerScreen(module: module, foundContent: foundContent, token: widget.token),
      'resource': ResourceViewerScreen(module: module, foundContent: foundContent, token: widget.token),
      'page': PageViewerScreen(module: module, foundContent: foundContent, token: widget.token),
    };

    destinationScreen = modScreenMap[module['modname']] ?? ModuleDetailScreen(module: module, token: widget.token);

    return ListTile(
      leading: Icon(
        IconService.instance.getIcon(module['modname']), // CHANGED: Dynamic icon
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

  // REFACTORED: This widget now uses DynamicAppTheme helpers for styling
  Widget _buildProgressBar() {
    final double progress = widget.course.progress ?? 0.0;
    
    String status;
    if (progress >= 100) {
      status = 'completed';
    } else if (progress > 0) {
      status = 'in_progress';
    } else {
      status = 'draft'; // Or another default status like 'not_started'
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background, // CHANGED
      appBar: AppBar(
        // Using the theme's pre-defined AppBar style
        title: Text(widget.course.fullname, overflow: TextOverflow.ellipsis),
        actions: widget.showCatalogButton ? [
          IconButton(
            icon: Icon(IconService.instance.getIcon('catalog')), // CHANGED: Dynamic icon
            onPressed: _navigateToCatalog,
            tooltip: 'Browse Courses',
          ),
        ] : null,
      ),
      body: _isLoading
          ? Center( // REMOVED const
              child: CircularProgressIndicator(color: AppTheme.secondary1),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.course.courseimage.isNotEmpty)
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: Image.network(
                        widget.course.courseimage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          color: AppTheme.secondary3, // CHANGED
                          child: Icon( // REMOVED const
                            IconService.instance.getIcon('course'), // CHANGED
                            size: 80,
                            color: AppTheme.secondary1, // CHANGED
                          ),
                        ),
                      ),
                    ),
                  _buildProgressBar(),
                  if (widget.showCatalogButton) 
                  Padding(
                    padding: EdgeInsets.all(AppTheme.spacingMd), // CHANGED
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
                        if (widget.course.summary.isNotEmpty)
                          SizedBox(height: AppTheme.spacingSm), // CHANGED
                        if (widget.course.summary.isNotEmpty)
                          Text(
                            widget.course.summary,
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeBase,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        SizedBox(height: AppTheme.spacingMd), // CHANGED
                        if (_courseDetails != null &&
                            _courseDetails!['enrolledusercount'] != null)
                          Row(
                            children: [
                              Icon(
                                IconService.instance.getIcon('people'), // CHANGED
                                size: AppTheme.fontSizeBase, // CHANGED
                                color: AppTheme.textSecondary, // CHANGED
                              ),
                              SizedBox(width: AppTheme.spacingSm), // CHANGED
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
                  Padding( // CHANGED
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                    child: const Divider(),
                  ),
                  if (_courseContents.isEmpty)
                    Padding( // REMOVED const
                      padding: EdgeInsets.all(AppTheme.spacingMd), // CHANGED
                      child: Center(
                        child: Text(
                          'No course content available.',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeBase,
                            color: AppTheme.textSecondary, // CHANGED
                          ),
                        ),
                      ),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final filteredSections = _courseContents
                            .asMap()
                            .entries
                            .where((entry) {
                              final sectionIndex = entry.key;
                              final section = entry.value;
                              final modules = section['modules'] as List<dynamic>? ?? [];
                              return !(sectionIndex == 0 || section['name'] == 'General' || modules.isEmpty);
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

                            // Using the theme's CardTheme implicitly
                            return Card(
                              key: Key('card_$index'),
                              margin: EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm), // CHANGED
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  ListTile(
                                    title: Text(
                                      section['name'] ?? 'Unnamed Section',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary, // CHANGED
                                        fontWeight: FontWeight.bold,
                                        fontSize: AppTheme.fontSizeLg,
                                      ),
                                    ),
                                    trailing: Icon(
                                      _expandedSectionIndex == index 
                                          ? IconService.instance.getIcon('expand_less') // CHANGED
                                          : IconService.instance.getIcon('expand_more'), // CHANGED
                                      color: AppTheme.textPrimary, // CHANGED
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
                                      // The Card's color is set by the CardTheme in the main theme file
                                      child: Column(
                                        children: [
                                          const Divider(height: 1),
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
                  SizedBox(height: AppTheme.spacingLg), // CHANGED
                ],
              ),
            ),
    );
  }
}