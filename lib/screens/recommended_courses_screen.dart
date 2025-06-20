import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/course_model.dart';
import 'course_detail_screen.dart';
import '../services/api_service.dart';
import '../services/icon_service.dart';
import '../theme/dynamic_app_theme.dart';
typedef AppTheme = DynamicAppTheme;

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

  @override
  void initState() {
    super.initState();
    _fetchRecommendedCourses();
  }

  Future<void> _fetchRecommendedCourses() async {
    setState(() => _isLoading = true);

    try {
      // FIXED: Reverted to a direct API call to avoid the undefined_method error.
      final url = Uri.parse(
          '${ApiService.instance.baseUrl}?wsfunction=local_instructohub_get_trending_courses&moodlewsrestformat=json&wstoken=${widget.token}');

      final response = await http.post(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
            _isLoading = false;
          });
        }
      } else {
         throw Exception('Failed to load recommended courses from API');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading recommendations: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppTheme.buildDynamicAppBar(title: 'Recommended Courses'),
      body: _isLoading
          ? Center(child: AppTheme.buildLoadingIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRecommendedCourses,
              child: _recommendedCourses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            IconService.instance.getIcon('recommend'),
                            size: 80,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(height: AppTheme.spacingMd),
                          Text(
                            'No recommendations available',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeLg,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(AppTheme.spacingMd),
                      itemCount: _recommendedCourses.length,
                      itemBuilder: (context, index) {
                        final course = _recommendedCourses[index];
                        return _buildCourseCard(course);
                      },
                    ),
            ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Card(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
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
                    color: AppTheme.secondary3,
                    child: Icon(
                      IconService.instance.getIcon('school'),
                      size: 60,
                      color: AppTheme.secondary1,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.fullname,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLg,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppTheme.spacingSm),
                  if (course.summary.isNotEmpty)
                    Text(
                      course.summary,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeBase,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: AppTheme.spacingMd),
                  Row(
                    children: [
                      AppTheme.buildStatusChip('info', 'Recommended'),
                      const Spacer(),
                      Icon(
                        IconService.instance.getIcon('arrow_forward'),
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
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
