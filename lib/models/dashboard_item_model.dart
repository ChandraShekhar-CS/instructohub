import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/course_model.dart';

enum DashboardWidgetType {
  continueLearning,
  quickActions,
  recommendedCourses,
  keyMetrics,
  upcomingEvents,
  recentActivity,
  courseCatalog,
}

class DashboardItem {
  final int id;
  final DashboardWidgetType type;
  bool isMainArea;

  DashboardItem({
    required this.id,
    required this.type,
    this.isMainArea = true,
  });

  Widget get widget {
    switch (type) {
      case DashboardWidgetType.continueLearning:
        return const ContinueLearningWidget();
      case DashboardWidgetType.quickActions:
        return const QuickActionsWidget();
      case DashboardWidgetType.recommendedCourses:
        return const RecommendedCoursesWidget();
      case DashboardWidgetType.keyMetrics:
        return const KeyMetricsWidget();
      case DashboardWidgetType.upcomingEvents:
        return const UpcomingEventsWidget();
      case DashboardWidgetType.recentActivity:
        return const RecentActivityWidget();
      case DashboardWidgetType.courseCatalog:
        return const CourseCatalogWidget();
    }
  }

  String get title {
     switch (type) {
      case DashboardWidgetType.continueLearning:
        return 'Continue Learning';
      case DashboardWidgetType.quickActions:
        return 'Quick Actions';
      case DashboardWidgetType.recommendedCourses:
        return 'Recommended Courses';
      case DashboardWidgetType.keyMetrics:
        return 'Key Metrics';
      case DashboardWidgetType.upcomingEvents:
        return 'Upcoming Events';
      case DashboardWidgetType.recentActivity:
        return 'Recent Activity';
      case DashboardWidgetType.courseCatalog:
        return 'My Course';
    }
  }
}

class ContinueLearningWidget extends StatefulWidget {
  const ContinueLearningWidget({Key? key}) : super(key: key);

  @override
  _ContinueLearningWidgetState createState() => _ContinueLearningWidgetState();
}

class _ContinueLearningWidgetState extends State<ContinueLearningWidget> {
  Course? _lastViewedCourse;

  @override
  void initState() {
    super.initState();
    _loadLastViewedCourse();
  }

  Future<void> _loadLastViewedCourse() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('lastViewedCourse');
    if (jsonString != null) {
      try {
        final map = json.decode(jsonString);
        setState(() {
          _lastViewedCourse = Course.fromJson(map);
        });
      } catch (_) {
        // fail silently or handle error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lastViewedCourse == null) {
      // you can return a placeholder, empty container, or spinner
      return const SizedBox.shrink();
    }

    return Container(
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.secondary1,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: const Icon(
                Icons.play_circle_outline,
                color: AppTheme.cardColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Continue Learning',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _lastViewedCourse!.fullname,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.secondary1,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: const Icon(
                Icons.bolt_outlined,
                color: AppTheme.cardColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Shortcuts',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class RecommendedCoursesWidget extends StatelessWidget {
  const RecommendedCoursesWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.secondary1,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: const Icon(
                Icons.star_border_outlined,
                color: AppTheme.cardColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Recommended Courses',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Trending',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class KeyMetricsWidget extends StatelessWidget {
  const KeyMetricsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.secondary1,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: const Icon(
                Icons.show_chart_outlined,
                color: AppTheme.cardColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Key Metrics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your Progress',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class UpcomingEventsWidget extends StatelessWidget {
  const UpcomingEventsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.secondary1,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: const Icon(
                Icons.event_outlined,
                color: AppTheme.cardColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Upcoming Events',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Calendar',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class RecentActivityWidget extends StatelessWidget {
  const RecentActivityWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.secondary1,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: const Icon(
                Icons.history_outlined,
                color: AppTheme.cardColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Timeline',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class CourseCatalogWidget extends StatelessWidget {
  const CourseCatalogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.secondary1,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: const Icon(
                Icons.search,
                color: AppTheme.cardColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'My Course',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Browse all courses',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}