import 'package:flutter/material.dart';

class QuickActionsScreen extends StatelessWidget {
  final String token;
  const QuickActionsScreen({required this.token, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Actions')),
      body: const Center(child: Text('Quick Actions Screen - Coming Soon')),
    );
  }
}

class RecommendedCoursesScreen extends StatelessWidget {
  final String token;
  const RecommendedCoursesScreen({required this.token, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommended Courses')),
      body:
          const Center(child: Text('Recommended Courses Screen - Coming Soon')),
    );
  }
}

class MetricsScreen extends StatelessWidget {
  final String token;
  const MetricsScreen({required this.token, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Metrics')),
      body: const Center(child: Text('Metrics Screen - Coming Soon')),
    );
  }
}

class UpcomingEventsScreen extends StatelessWidget {
  final String token;
  const UpcomingEventsScreen({required this.token, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Events')),
      body: const Center(child: Text('Upcoming Events Screen - Coming Soon')),
    );
  }
}

class RecentActivityScreen extends StatelessWidget {
  final String token;
  const RecentActivityScreen({required this.token, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recent Activity')),
      body: const Center(child: Text('Recent Activity Screen - Coming Soon')),
    );
  }
}
