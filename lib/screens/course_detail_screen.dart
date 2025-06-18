import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/course_model.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'viewers/module_detail_screen.dart'; 
import 'viewers/page_viewer_screen.dart';
import 'viewers/assignment_viewer_screen.dart';
import 'viewers/quiz_viewer_screen.dart';
import 'viewers/forum_viewer_screen.dart';
import 'viewers/resource_viewer_screen.dart';
import 'course_catalog_screen.dart';

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
      // Corrected line: Use ApiService.instance to call the method
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
              content: Text('Error fetching course details: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _fetchExtendedCourseInfo() async {
    final url = Uri.parse(
        'https://moodle.instructohub.com/webservice/rest/server.php?wsfunction=core_course_get_courses_by_field&moodlewsrestformat=json&wstoken=${widget.token}&field=id&value=${widget.course.id}');

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

  Widget _buildModuleItem(dynamic module) {
    IconData iconData;
    Widget destinationScreen;
    final dynamic foundContent = module['foundContent'];

    switch (module['modname']) {
      case 'forum':
        iconData = Icons.forum_outlined;
        destinationScreen = ForumViewerScreen(module: module, foundContent: foundContent, token: widget.token);
        break;
      case 'assign':
        iconData = Icons.assignment_outlined;
        destinationScreen = AssignmentViewerScreen(module: module, foundContent: foundContent, token: widget.token);
        break;
      case 'quiz':
        iconData = Icons.quiz_outlined;
        destinationScreen = QuizViewerScreen(module: module, foundContent: foundContent, token: widget.token);
        break;
      case 'resource':
        iconData = Icons.description_outlined;
        destinationScreen = ResourceViewerScreen(module: module, foundContent: foundContent, token: widget.token);
        break;
      case 'page':
        iconData = Icons.article_outlined;
        destinationScreen = PageViewerScreen(module: module, foundContent: foundContent, token: widget.token);
        break;
      default:
        iconData = Icons.school_outlined;
        destinationScreen = ModuleDetailScreen(module: module, token: widget.token);
    }

    return ListTile(
      leading: Icon(iconData, color: AppTheme.primary2),
      title: Text(
        module['name'] ?? 'Unnamed Module',
        style: const TextStyle(fontWeight: FontWeight.w500),
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
    final double progressValue = (widget.course.progress ?? 0.0) / 100.0;
    final String progressPercent = (progressValue * 100).toStringAsFixed(0);

    String statusText;
    Color statusColor;
    Color statusBgColor;

    if (progressValue <= 0) {
      statusText = 'NOT STARTED';
      statusColor = Colors.red.shade600;
      statusBgColor = Colors.red.shade50;
    } else if (progressValue > 0 && progressValue < 1.0) {
      statusText = 'IN PROGRESS';
      statusColor = Colors.blue.shade600;
      statusBgColor = Colors.blue.shade50;
    } else {
      statusText = 'COMPLETED';
      statusColor = Colors.green.shade600;
      statusBgColor = Colors.green.shade50;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: AppTheme.fontSizeXs,
                  ),
                ),
              ),
              Text(
                '$progressPercent%',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.fontSizeSm,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.fullname, overflow: TextOverflow.ellipsis),
        backgroundColor: AppTheme.secondary1,
        foregroundColor: AppTheme.offwhite,
        actions: widget.showCatalogButton ? [
          IconButton(
            icon: const Icon(Icons.library_books_outlined),
            onPressed: _navigateToCatalog,
            tooltip: 'Browse Courses',
          ),
        ] : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                          color: AppTheme.loginBgLeft,
                          child: const Icon(
                            Icons.school,
                            size: 80,
                            color: AppTheme.primary2,
                          ),
                        ),
                      ),
                    ),
                  _buildProgressBar(),
                  if (widget.showCatalogButton) 
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.course.fullname,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: AppTheme.primary1),
                        ),
                        if (widget.course.summary.isNotEmpty)
                          const SizedBox(height: 8),
                        if (widget.course.summary.isNotEmpty)
                          Text(
                            widget.course.summary,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        const SizedBox(height: 16),
                        if (_courseDetails != null &&
                            _courseDetails!['enrolledusercount'] != null)
                          Row(
                            children: [
                              Icon(Icons.people_outline, 
                              size: AppTheme.fontSizeSm,
                              color: AppTheme.primary2),
                              const SizedBox(width: 8),
                              Text(
                                '${_courseDetails!['enrolledusercount']} enrolled',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppTheme.primary2),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(),
                  ),
                  if (_courseContents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No course content available.',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeBase,
                            color: AppTheme.primary2,
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

                            return Card(
                              key: Key('card_$index'),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              clipBehavior: Clip.antiAlias,
                              elevation: 2,
                              child: Column(
                                children: [
                                  Container(
                                    color: AppTheme.cardColor,
                                    child: ListTile(
                                      title: Text(
                                        section['name'] ?? 'Unnamed Section',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(color: AppTheme.primary1),
                                      ),
                                      trailing: Icon(
                                        _expandedSectionIndex == index 
                                            ? Icons.expand_less 
                                            : Icons.expand_more,
                                        color: AppTheme.primary1,
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
                                  ),
                                  if (_expandedSectionIndex == index)
                                    Container(
                                      color: AppTheme.cardColor,
                                      child: Column(
                                        children: modules
                                            .map((module) => _buildModuleItem(module))
                                            .toList(),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
