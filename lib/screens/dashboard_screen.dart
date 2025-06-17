import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import 'course_catalog_screen.dart';
import 'course_detail_screen.dart';
import 'metrics_screen.dart';
import 'upcoming_events_screen.dart';
import 'recent_activity_screen.dart';
import 'quick_actions_screen.dart';
import 'recommended_courses_screen.dart';
import '../models/course_model.dart';
import '../models/dashboard_item_model.dart';

class DashboardScreen extends StatefulWidget {
  final String token;
  const DashboardScreen({required this.token, super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;

  List<DashboardItem> _mainItems = [];
  List<DashboardItem> _sidebarItems = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardItems();
  }

  Future<void> _handleContinueLearningTap() async {
    final prefs = await SharedPreferences.getInstance();
    final lastViewedCourseString = prefs.getString('lastViewedCourse');

    if (!mounted) return;

    if (lastViewedCourseString != null) {
      final courseJson = json.decode(lastViewedCourseString);
      final course = Course.fromJson(courseJson);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseDetailScreen(
            course: course,
            token: widget.token,
            showCatalogButton: true,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("No recent courses found. Let's find one for you!"),
          backgroundColor: AppTheme.secondary2,
        ),
      );
    }
  }

  void _handleQuickActionsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuickActionsScreen(token: widget.token),
      ),
    );
  }

  void _handleRecommendedCoursesTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendedCoursesScreen(token: widget.token),
      ),
    );
  }

  void _handleKeyMetricsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MetricsScreen(token: widget.token),
      ),
    );
  }

  void _handleUpcomingEventsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpcomingEventsScreen(token: widget.token),
      ),
    );
  }

  void _handleRecentActivityTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecentActivityScreen(token: widget.token),
      ),
    );
  }

  void _handleCourseCatalogTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseCatalogScreen(token: widget.token),
      ),
    );
  }

  void _loadDashboardItems() {
    setState(() { _isLoading = true; });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _mainItems = [
          DashboardItem(id: 7, type: DashboardWidgetType.courseCatalog, isMainArea: true),
          DashboardItem(id: 1, type: DashboardWidgetType.continueLearning, isMainArea: true),
          DashboardItem(id: 2, type: DashboardWidgetType.quickActions, isMainArea: true),
          DashboardItem(id: 3, type: DashboardWidgetType.recommendedCourses, isMainArea: true),
          
        ];
        _sidebarItems = [
          DashboardItem(id: 4, type: DashboardWidgetType.keyMetrics, isMainArea: false),
          DashboardItem(id: 5, type: DashboardWidgetType.upcomingEvents, isMainArea: false),
          DashboardItem(id: 6, type: DashboardWidgetType.recentActivity, isMainArea: false),
        ];
        _isLoading = false;
      });
    });
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _handleItemTap(DashboardWidgetType type) {
    switch (type) {
      case DashboardWidgetType.continueLearning:
        _handleContinueLearningTap();
        break;
      case DashboardWidgetType.quickActions:
        _handleQuickActionsTap();
        break;
      case DashboardWidgetType.recommendedCourses:
        _handleRecommendedCoursesTap();
        break;
      case DashboardWidgetType.courseCatalog:
        _handleCourseCatalogTap();
        break;
      case DashboardWidgetType.keyMetrics:
        _handleKeyMetricsTap();
        break;
      case DashboardWidgetType.upcomingEvents:
        _handleUpcomingEventsTap();
        break;
      case DashboardWidgetType.recentActivity:
        _handleRecentActivityTap();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Dashboard'),
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.secondary1),
              onPressed: _handleLogout,
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.secondary1,
              ),
            )
          : Container(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 720) {
                    return _buildTwoColumnLayout();
                  } else {
                    return _buildSingleColumnLayout();
                  }
                },
              ),
            ),
    );
  }

  Widget _buildTwoColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildItemsList(_mainItems),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: _buildItemsList(_sidebarItems),
        ),
      ],
    );
  }

  Widget _buildSingleColumnLayout() {
    final allItems = [..._mainItems, ..._sidebarItems];
    return _buildItemsList(allItems);
  }

  Widget _buildItemsList(List<DashboardItem> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _handleItemTap(item.type),
            child: item.widget,
          ),
        );
      },
    );
  }
}