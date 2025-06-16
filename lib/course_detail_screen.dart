import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'course_model.dart';
import 'app_theme.dart';

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
  double _courseProgress = 0.7;

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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCourseContents() async {
    final url = Uri.parse(
        'https://moodle.instructohub.com/webservice/rest/server.php?wsfunction=core_course_get_contents&moodlewsrestformat=json&wstoken=${widget.token}&courseid=${widget.course.id}');

    final response = await http.post(url);

    if (response.statusCode == 200) {
      setState(() {
        _courseContents = json.decode(response.body);
      });
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
        setState(() {
          _courseDetails = data['courses'][0];
        });
      }
    }
  }

  Widget _buildModuleItem(dynamic module) {
    IconData iconData;
    switch (module['modname']) {
      case 'forum':
        iconData = Icons.forum;
        break;
      case 'assign':
        iconData = Icons.assignment;
        break;
      case 'quiz':
        iconData = Icons.quiz;
        break;
      case 'resource':
        iconData = Icons.description;
        break;
      case 'url':
        iconData = Icons.link;
        break;
      case 'page':
        iconData = Icons.article;
        break;
      case 'video':
        iconData = Icons.video_library;
        break;
      default:
        iconData = Icons.school;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        leading: Icon(iconData, color: AppTheme.secondary1),
        title: Text(
          module['name'] ?? 'Unnamed Module',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: module['description'] != null
            ? Text(
                module['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening ${module['name'] ?? 'module'}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.fullname),
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
                    Container(
                      height: 200,
                      width: double.infinity,
                      child: Image.network(
                        widget.course.courseimage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppTheme.loginBgLeft,
                          child: const Icon(
                            Icons.school,
                            size: 80,
                            color: AppTheme.primary2,
                          ),
                        ),
                      ),
                    ),
                  // ADDED PROGRESS BAR HERE
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progress: ${(_courseProgress * 100).toStringAsFixed(0)}%', // Display percentage
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.primary1,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: _courseProgress,
                          backgroundColor: AppTheme
                              .secondary3, // Light orange for background
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.secondary1), // Orange for progress
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        bottom: 16.0), // Adjust padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.course.fullname,
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: AppTheme.primary1,
                              ),
                        ),
                        if (widget.course.summary.isNotEmpty)
                          const SizedBox(height: 8),
                        if (widget.course.summary.isNotEmpty)
                          Text(
                            widget.course.summary,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          ),
                        const SizedBox(height: 16),
                        if (_courseDetails != null) ...[
                          const SizedBox(height: 8),
                          if (_courseDetails!['enrolledusercount'] != null)
                            Row(
                              children: [
                                Icon(Icons.people,
                                    size: AppTheme.fontSizeSm,
                                    color: AppTheme.primary2),
                                const SizedBox(width: 8),
                                Text(
                                  '${_courseDetails!['enrolledusercount']} enrolled',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.primary2,
                                      ),
                                ),
                              ],
                            ),
                        ],
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Course Content',
                      style: TextStyle(
                        fontSize:
                            AppTheme.fontSize2xl, // Using 2xl for the heading
                        fontWeight: FontWeight.bold,
                        color: AppTheme
                            .primary1, // Ensure text color is from theme
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_courseContents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No course content available',
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

                        if (section['name'] == 'General') {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (section['name'] != null &&
                                section['name'].toString().isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16.0),
                                color: AppTheme.loginBgLeft,
                                child: Text(
                                  section['name'],
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: AppTheme.primary1,
                                      ),
                                ),
                              ),
                            if (section['modules'] != null)
                              ...List.generate(
                                section['modules'].length,
                                (moduleIndex) => _buildModuleItem(
                                  section['modules'][moduleIndex],
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
