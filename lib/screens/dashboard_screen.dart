import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/course_model.dart';
import '../services/enhanced_icon_service.dart';
import '../theme/dynamic_app_theme.dart';
import 'course_catalog_screen.dart';
import 'course_detail_screen.dart';
import 'metrics_screen.dart';
import 'quick_actions_screen.dart';
import 'recent_activity_screen.dart';
import 'recommended_courses_screen.dart';
import 'upcoming_events_screen.dart';

typedef AppTheme = DynamicAppTheme;

class DashboardScreen extends StatefulWidget {
  final String token;

  const DashboardScreen({required this.token, Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final List<DashboardItem> _dashboardItems;

  @override
  void initState() {
    super.initState();
    _dashboardItems = [
      DashboardItem(
          id: 1,
          type: DashboardWidgetType.continueLearning,
          token: widget.token),
      DashboardItem(id: 2, type: DashboardWidgetType.quickActions),
      DashboardItem(id: 3, type: DashboardWidgetType.recommendedCourses),
      DashboardItem(id: 4, type: DashboardWidgetType.keyMetrics),
      DashboardItem(id: 5, type: DashboardWidgetType.upcomingEvents),
      DashboardItem(id: 6, type: DashboardWidgetType.recentActivity),
      DashboardItem(id: 7, type: DashboardWidgetType.courseCatalog),
    ];
  }

  void _pushRoute(Widget destination) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  void _navigateTo(DashboardWidgetType type) {
    switch (type) {
      case DashboardWidgetType.quickActions:
        _pushRoute(QuickActionsScreen(token: widget.token));
        break;
      case DashboardWidgetType.recommendedCourses:
        _pushRoute(RecommendedCoursesScreen(token: widget.token));
        break;
      case DashboardWidgetType.keyMetrics:
        _pushRoute(MetricsScreen(token: widget.token));
        break;
      case DashboardWidgetType.upcomingEvents:
        _pushRoute(UpcomingEventsScreen(token: widget.token));
        break;
      case DashboardWidgetType.recentActivity:
        _pushRoute(RecentActivityScreen(token: widget.token));
        break;
      case DashboardWidgetType.courseCatalog:
        _pushRoute(CourseCatalogScreen(token: widget.token));
        break;
      case DashboardWidgetType.continueLearning:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppTheme.buildDynamicAppBar(title: 'Dashboard'),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        itemCount: _dashboardItems.length,
        itemBuilder: (context, index) {
          final item = _dashboardItems[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              onTap: item.type == DashboardWidgetType.continueLearning
                  ? null
                  : () => _navigateTo(item.type),
              child: item.widget,
            ),
          );
        },
      ),
    );
  }
}

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
  final String? token;

  DashboardItem({
    required this.id,
    required this.type,
    this.token,
  });

  Widget get widget {
    switch (type) {
      case DashboardWidgetType.continueLearning:
        return ContinueLearningWidget(token: token!);
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
        return 'My Courses';
    }
  }
}

class ContinueLearningWidget extends StatefulWidget {
  final String token;
  const ContinueLearningWidget({required this.token, Key? key})
      : super(key: key);

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

  void _handleTap() {
    if (_lastViewedCourse != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseDetailScreen(
            course: _lastViewedCourse!,
            token: widget.token,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseCatalogScreen(token: widget.token),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trailingIcon = Icon(
        DynamicIconService.instance.getIcon('arrow_forward'),
        size: 16,
        color: AppTheme.textSecondary);

    if (_lastViewedCourse == null) {
      return AppTheme.buildInfoCard(
        iconKey: 'play',
        title: 'Start Learning',
        subtitle: 'Explore the course catalog',
        trailing: trailingIcon,
        onTap: _handleTap,
      );
    }
    return AppTheme.buildInfoCard(
      iconKey: 'play',
      title: 'Continue Learning',
      subtitle: _lastViewedCourse!.fullname,
      trailing: trailingIcon,
      onTap: _handleTap,
    );
  }
}

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return AppTheme.buildInfoCard(
      iconKey: 'bolt',
      title: 'Quick Actions',
      subtitle: 'Shortcuts to common tasks',
      trailing: Icon(DynamicIconService.instance.getIcon('arrow_forward'),
          size: 16, color: AppTheme.textSecondary),
    );
  }
}

class RecommendedCoursesWidget extends StatelessWidget {
  const RecommendedCoursesWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return AppTheme.buildInfoCard(
      iconKey: 'star',
      title: 'Recommended Courses',
      subtitle: 'Courses you might like',
      trailing: Icon(DynamicIconService.instance.getIcon('arrow_forward'),
          size: 16, color: AppTheme.textSecondary),
    );
  }
}

class KeyMetricsWidget extends StatelessWidget {
  const KeyMetricsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return AppTheme.buildInfoCard(
      iconKey: 'chart',
      title: 'Key Metrics',
      subtitle: 'Track your progress',
      trailing: Icon(DynamicIconService.instance.getIcon('arrow_forward'),
          size: 16, color: AppTheme.textSecondary),
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
      trailing: Icon(DynamicIconService.instance.getIcon('arrow_forward'),
          size: 16, color: AppTheme.textSecondary),
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
      trailing: Icon(DynamicIconService.instance.getIcon('arrow_forward'),
          size: 16, color: AppTheme.textSecondary),
    );
  }
}

class CourseCatalogWidget extends StatelessWidget {
  const CourseCatalogWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return AppTheme.buildInfoCard(
      iconKey: 'search',
      title: 'Course Catalog',
      subtitle: 'Browse all available courses',
      trailing: Icon(DynamicIconService.instance.getIcon('arrow_forward'),
          size: 16, color: AppTheme.textSecondary),
    );
  }
}
// This file is part of InstructoHub, an open-source educational platform.