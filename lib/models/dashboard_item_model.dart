import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/course_model.dart';
import '../services/icon_service.dart';
import '../theme/dynamic_app_theme.dart';
typedef AppTheme = DynamicAppTheme;

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
      case DashboardWidgetType.continueLearning: return 'Continue Learning';
      case DashboardWidgetType.quickActions: return 'Quick Actions';
      case DashboardWidgetType.recommendedCourses: return 'Recommended Courses';
      case DashboardWidgetType.keyMetrics: return 'Key Metrics';
      case DashboardWidgetType.upcomingEvents: return 'Upcoming Events';
      case DashboardWidgetType.recentActivity: return 'Recent Activity';
      case DashboardWidgetType.courseCatalog: return 'My Courses';
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
      } catch (_) {
        // fail silently
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lastViewedCourse == null) {
      return const SizedBox.shrink();
    }
    return AppTheme.buildInfoCard(
      iconKey: 'play_circle',
      title: 'Continue Learning',
      subtitle: _lastViewedCourse!.fullname,
      trailing: Icon(IconService.instance.getIcon('arrow_forward'), size: 16),
    );
  }
}

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return AppTheme.buildInfoCard(
      iconKey: 'quick_actions',
      title: 'Quick Actions',
      subtitle: 'Shortcuts to common tasks',
      trailing: Icon(IconService.instance.getIcon('arrow_forward'), size: 16),
    );
  }
}

class RecommendedCoursesWidget extends StatelessWidget {
  const RecommendedCoursesWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return AppTheme.buildInfoCard(
      iconKey: 'recommend',
      title: 'Recommended Courses',
      subtitle: 'Courses you might like',
      trailing: Icon(IconService.instance.getIcon('arrow_forward'), size: 16),
    );
  }
}

class KeyMetricsWidget extends StatelessWidget {
  const KeyMetricsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return AppTheme.buildInfoCard(
      iconKey: 'metrics',
      title: 'Key Metrics',
      subtitle: 'Track your progress',
      trailing: Icon(IconService.instance.getIcon('arrow_forward'), size: 16),
    );
  }
}

class UpcomingEventsWidget extends StatelessWidget {
  const UpcomingEventsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return AppTheme.buildInfoCard(
      iconKey: 'event',
      title: 'Upcoming Events',
      subtitle: 'View your calendar',
      trailing: Icon(IconService.instance.getIcon('arrow_forward'), size: 16),
    );
  }
}

class RecentActivityWidget extends StatelessWidget {
  const RecentActivityWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return AppTheme.buildInfoCard(
      iconKey: 'history',
      title: 'Recent Activity',
      subtitle: 'See what\'s new',
      trailing: Icon(IconService.instance.getIcon('arrow_forward'), size: 16),
    );
  }
}

class CourseCatalogWidget extends StatelessWidget {
  const CourseCatalogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppTheme.buildInfoCard(
      iconKey: 'catalog',
      title: 'Course Catalog',
      subtitle: 'Browse all available courses',
      trailing: Icon(IconService.instance.getIcon('arrow_forward'), size: 16),
    );
  }
}
