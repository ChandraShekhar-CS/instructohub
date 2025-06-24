import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/course_model.dart';
import 'course_detail_screen.dart';
import '../../services/api_service.dart';
import '../../services/dynamic_theme_service.dart';
import '../../services/enhanced_icon_service.dart';

class RecommendedCoursesScreen extends StatefulWidget {
  final String token;

  const RecommendedCoursesScreen({required this.token, Key? key})
      : super(key: key);

  @override
  _RecommendedCoursesScreenState createState() =>
      _RecommendedCoursesScreenState();
}

class _RecommendedCoursesScreenState extends State<RecommendedCoursesScreen> {
  bool _isLoading = true;
  List<Course> _recommendedCourses = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRecommendedCourses();
  }

  Future<void> _fetchRecommendedCourses() async {
    setState(() {
       _isLoading = true;
       _errorMessage = null;
    });

    try {
      final data = await ApiService.instance.callCustomAPI('local_instructohub_get_trending_courses', widget.token, {});
      
      List<dynamic> coursesData = [];
      if (data is List) {
        coursesData = data;
      } else if (data is Map) {
        if (data.containsKey('courses')) {
          coursesData = data['courses'] ?? [];
        } else if (data.containsKey('trending_courses')) {
          coursesData = data['trending_courses'] ?? [];
        }
      }

      if (mounted) {
        setState(() {
          _recommendedCourses = coursesData
              .map((courseJson) => Course.fromJson(courseJson))
              .take(10)
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading recommendations: ${e.toString()}'),
            backgroundColor: DynamicThemeService.instance.getColor('error'),
          ),
        );
      }
    } finally {
        if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommended Courses')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRecommendedCourses,
              child: _errorMessage != null
              ? _buildErrorView()
              : _recommendedCourses.isEmpty
                  ? _buildEmptyView()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _recommendedCourses.length,
                      itemBuilder: (context, index) {
                        final course = _recommendedCourses[index];
                        return _buildCourseCard(course);
                      },
                    ),
            ),
    );
  }

   Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            const Text("Failed to load recommendations.", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'An unknown error occurred.'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchRecommendedCourses, child: const Text("Try Again"))
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            DynamicIconService.instance.getIcon('recommend'),
            size: 80,
            color: theme.textTheme.bodyMedium?.color,
          ),
          const SizedBox(height: 16.0),
          Text(
            'No recommendations available',
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    final theme = Theme.of(context);
    final themeService = DynamicThemeService.instance;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openCourse(course),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.courseimage.isNotEmpty)
              SizedBox(
                height: 160,
                width: double.infinity,
                child: Image.network(
                  course.courseimage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: themeService.getColor('secondary3'),
                    child: Icon(
                      DynamicIconService.instance.getIcon('school'),
                      size: 60,
                      color: themeService.getColor('secondary1'),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.fullname, style: theme.textTheme.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8.0),
                  if (course.summary.isNotEmpty)
                    Text(
                      course.summary,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      Chip(
                        label: const Text('Recommended'),
                        backgroundColor: themeService.getColor('info').withOpacity(0.1),
                        labelStyle: theme.textTheme.labelSmall?.copyWith(color: themeService.getColor('info')),
                      ),
                      const Spacer(),
                      Icon(DynamicIconService.instance.getIcon('arrow_forward'), size: 16, color: theme.textTheme.bodyMedium?.color),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
}
