import 'package:flutter/material.dart';
import 'package:InstructoHub/models/course_model.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';

class CourseDetailScreen extends StatelessWidget {
  final Course course;
  final String token;

  const CourseDetailScreen({
    required this.course,
    required this.token,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(course.fullname),
        backgroundColor: themeService.getColor('backgroundLight'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.courseimage.isNotEmpty)
              Image.network(
                course.courseimage,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  color: themeService.getColor('primary').withOpacity(0.1),
                  child: Icon(
                    Icons.school,
                    size: 80,
                    color: themeService.getColor('primary'),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(themeService.getSpacing('md')),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.fullname,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: themeService.getSpacing('sm')),
                  if (course.summary.isNotEmpty)
                    Text(
                      course.summary.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
                      style: textTheme.bodyLarge,
                    ),
                  SizedBox(height: themeService.getSpacing('lg')),
                  // Add more course detail widgets here
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
