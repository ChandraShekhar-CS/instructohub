import 'package:flutter/material.dart';

// An enum to represent the different types of widgets that can be on the dashboard.
enum DashboardWidgetType {
  continueLearning,
  quickActions,
  recommendedCourses,
  keyMetrics,
  upcomingEvents,
  recentActivity,
}

// A data model to hold the information for each dashboard item.
class DashboardItem {
  final int id;
  final DashboardWidgetType type;
  bool isMainArea; // To track if the item is in the main or sidebar area.

  DashboardItem({
    required this.id,
    required this.type,
    this.isMainArea = true,
  });

  // A helper method to get the widget corresponding to the type.
  // This makes the UI code cleaner.
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
    }
  }

  // A helper method for a user-friendly title.
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
    }
  }
}

// --- Placeholder Widgets ---
// In a real app, these would each be in their own file and contain complex logic.

class ContinueLearningWidget extends StatelessWidget {
  const ContinueLearningWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.play_circle_outline),
        title: Text('Continue Learning'),
        subtitle: Text('Your Courses'),
      ),
    );
  }
}

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.bolt_outlined),
        title: Text('Quick Actions'),
        subtitle: Text('Shortcuts'),
      ),
    );
  }
}

class RecommendedCoursesWidget extends StatelessWidget {
  const RecommendedCoursesWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.star_border_outlined),
        title: Text('Recommended Courses'),
        subtitle: Text('Trending'),
      ),
    );
  }
}

class KeyMetricsWidget extends StatelessWidget {
  const KeyMetricsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.show_chart_outlined),
        title: Text('Key Metrics'),
        subtitle: Text('Your Progress'),
      ),
    );
  }
}

class UpcomingEventsWidget extends StatelessWidget {
  const UpcomingEventsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.event_outlined),
        title: Text('Upcoming Events'),
        subtitle: Text('Calendar'),
      ),
    );
  }
}

class RecentActivityWidget extends StatelessWidget {
  const RecentActivityWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.history_outlined),
        title: Text('Recent Activity'),
        subtitle: Text('Timeline'),
      ),
    );
  }
}
