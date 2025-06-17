import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/course_model.dart';
import 'course_detail_screen.dart';

class RecommendedCoursesScreen extends StatefulWidget {
  final String token;

  const RecommendedCoursesScreen({required this.token, Key? key}) : super(key: key);

  @override
  _RecommendedCoursesScreenState createState() => _RecommendedCoursesScreenState();
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
      final url = Uri.parse(
        'https://moodle.instructohub.com/webservice/rest/server.php?wsfunction=local_instructohub_get_trending_courses&moodlewsrestformat=json&wstoken=${widget.token}'
      );
      
      final response = await http.post(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        List<dynamic> coursesData = [];
        
        // Handle different response structures
        if (data is List) {
          coursesData = data;
        } else if (data is Map) {
          // Check for common response structures
          if (data.containsKey('courses')) {
            coursesData = data['courses'] ?? [];
          } else if (data.containsKey('data')) {
            coursesData = data['data'] ?? [];
          } else if (data.containsKey('trending_courses')) {
            coursesData = data['trending_courses'] ?? [];
          } else {
            // If it's a map but doesn't have expected keys, treat it as empty
            coursesData = [];
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
      }
    } catch (e) {
      print('Recommended courses error: $e'); // Debug log
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recommendations: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended Courses'),
        backgroundColor: AppTheme.secondary1,
        foregroundColor: AppTheme.offwhite,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRecommendedCourses,
              child: _recommendedCourses.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.recommend,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No recommendations available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
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
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openCourse(course),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.courseimage.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  child: Image.network(
                    course.courseimage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppTheme.loginBgLeft,
                      child: const Icon(
                        Icons.school,
                        size: 60,
                        color: AppTheme.primary2,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.fullname,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (course.summary.isNotEmpty)
                    Text(
                      course.summary,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.primary2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary1.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Recommended',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.secondary1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.primary2,
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