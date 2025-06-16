import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'course_model.dart';
import 'app_theme.dart';

// This file should NOT import 'course_catalog_screen.dart' to prevent circular dependencies.

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  final String token;

  const CourseDetailScreen({
    required this.course,
    required this.token,
    Key? key,
  }) : super(key: key);

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _isLoading = true;
  List<dynamic> _courseContents = [];
  Map<String, dynamic>? _courseDetails;
  
  @override
  void initState() {
    super.initState();
    _fetchCourseDetails();
  }

  Future<void> _fetchCourseDetails() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _fetchCourseContents(),
        _fetchExtendedCourseInfo(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error fetching course details: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchCourseContents() async {
    final url = Uri.parse(
        'https://moodle.instructohub.com/webservice/rest/server.php?wsfunction=core_course_get_contents&moodlewsrestformat=json&wstoken=${widget.token}&courseid=${widget.course.id}');

    final response = await http.post(url);

    if (response.statusCode == 200) {
      if (mounted) {
        setState(() {
          _courseContents = json.decode(response.body);
        });
      }
    } else {
      throw Exception('Failed to load course contents');
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

  Widget _buildModuleItem(dynamic module) {
    IconData iconData;
    switch (module['modname']) {
      case 'forum':
        iconData = Icons.forum_outlined;
        break;
      case 'assign':
        iconData = Icons.assignment_outlined;
        break;
      case 'quiz':
        iconData = Icons.quiz_outlined;
        break;
      case 'resource':
        iconData = Icons.description_outlined;
        break;
      case 'url':
        iconData = Icons.link_outlined;
        break;
      case 'page':
        iconData = Icons.article_outlined;
        break;
      case 'video':
        iconData = Icons.video_library_outlined;
        break;
      default:
        iconData = Icons.school_outlined;
    }

    return ListTile(
      leading: Icon(iconData, color: AppTheme.primary2),
      title: Text(
        module['name'] ?? 'Unnamed Module',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${module['name'] ?? 'module'}'),
            duration: const Duration(seconds: 1),
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
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Course Content',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeLg,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary1,
                      ),
                    ),
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
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _courseContents.length,
                      itemBuilder: (context, sectionIndex) {
                        final section = _courseContents[sectionIndex];
                        final modules =
                            section['modules'] as List<dynamic>? ?? [];

                        if (section['name'] == 'General' || modules.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          clipBehavior: Clip.antiAlias,
                          elevation: 2,
                          child: ExpansionTile(
                            title: Text(
                              section['name'] ?? 'Unnamed Section',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppTheme.primary1),
                            ),
                            backgroundColor: AppTheme.cardColor,
                            collapsedBackgroundColor: AppTheme.cardColor,
                            childrenPadding:
                                const EdgeInsets.only(bottom: 8.0),
                            children: modules
                                .map((module) => _buildModuleItem(module))
                                .toList(),
                          ),
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
