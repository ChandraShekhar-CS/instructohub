import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:InstructoHub/models/course_model.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';
import 'package:InstructoHub/services/enhanced_icon_service.dart';

enum DashboardWidgetType {
  continueLearning,
  courseCatalog,
  quickActions,
  recommendedCourses,
  keyMetrics,
  upcomingEvents,
  recentActivity,
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
      case DashboardWidgetType.courseCatalog:
        return const CourseCatalogWidget();
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
    }
  }

  String get title {
    switch (type) {
      case DashboardWidgetType.continueLearning:
        return 'Continue Learning';
      case DashboardWidgetType.courseCatalog:
        return 'My Courses';
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
        if (mounted) {
          setState(() {
            _lastViewedCourse = Course.fromJson(map);
          });
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lastViewedCourse == null) {
      return const SizedBox.shrink();
    }
    return _buildInfoCard(
      context,
      iconKey: 'play_circle',
      title: 'Continue Learning',
      subtitle: _lastViewedCourse!.fullname,
    );
  }
}

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildInfoCard(
      context,
      iconKey: 'quick_actions',
      title: 'Quick Actions',
      subtitle: 'Shortcuts to common tasks',
    );
  }
}

class RecommendedCoursesWidget extends StatelessWidget {
  const RecommendedCoursesWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildInfoCard(
      context,
      iconKey: 'recommend',
      title: 'Recommended Courses',
      subtitle: 'Courses you might like',
    );
  }
}

class KeyMetricsWidget extends StatelessWidget {
  const KeyMetricsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildInfoCard(
      context,
      iconKey: 'metrics',
      title: 'Key Metrics',
      subtitle: 'Track your progress',
    );
  }
}

class UpcomingEventsWidget extends StatelessWidget {
  const UpcomingEventsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildInfoCard(
      context,
      iconKey: 'event',
      title: 'Upcoming Events',
      subtitle: 'View your calendar',
    );
  }
}

class RecentActivityWidget extends StatelessWidget {
  const RecentActivityWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildInfoCard(
      context,
      iconKey: 'history',
      title: 'Recent Activity',
      subtitle: 'See what\'s new',
    );
  }
}

class CourseCatalogWidget extends StatelessWidget {
  const CourseCatalogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildInfoCard(
      context,
      iconKey: 'catalog',
      title: 'Course Catalog',
      subtitle: 'Browse all available courses',
    );
  }
}

// Helper method to build a consistently styled card
Widget _buildInfoCard(BuildContext context,
    {required String iconKey,
    required String title,
    required String subtitle}) {
  final themeService = DynamicThemeService.instance;
  final textTheme = Theme.of(context).textTheme;

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(themeService.getBorderRadius('medium')),
    ),
    child: ListTile(
      leading: Icon(
        DynamicIconService.instance.getIcon(iconKey),
        color: themeService.getColor('secondary1'),
      ),
      title: Text(title, style: textTheme.titleMedium),
      subtitle: Text(subtitle, style: textTheme.bodySmall),
      trailing: Icon(DynamicIconService.instance.getIcon('arrow_forward'),
          size: 16, color: themeService.getColor('textSecondary')),
    ),
  );
}
