import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'course_catalog_screen.dart';
import 'course_detail_screen.dart';
import 'metrics_screen.dart';
import 'upcoming_events_screen.dart';
import 'recent_activity_screen.dart';
import 'quick_actions_screen.dart';
import 'recommended_courses_screen.dart';
import 'domain_config_screen.dart';
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
  Map<String, dynamic>? _userInfo;
  List<dynamic> _userCourses = [];
  String? _currentDomain;

  List<DashboardItem> _mainItems = [];
  List<DashboardItem> _sidebarItems = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current domain info
      final prefs = await SharedPreferences.getInstance();
      _currentDomain = prefs.getString('api_domain');

      // Load user info
      final userInfoResult = await ApiService.instance.getUserInfo(widget.token);
      if (userInfoResult['success'] == true) {
        _userInfo = userInfoResult['data'];
      }

      // Load user courses
      final courses = await ApiService.instance.getUserCourses(widget.token);
      _userCourses = courses;

      _loadDashboardItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard: ${e.toString()}'),
            backgroundColor: AppTheme.secondary1,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          content:
              const Text("No recent courses found. Let's find one for you!"),
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
    setState(() {
      _mainItems = [
        DashboardItem(
            id: 1,
            type: DashboardWidgetType.continueLearning,
            isMainArea: true),
        DashboardItem(
            id: 7, type: DashboardWidgetType.courseCatalog, isMainArea: true),
        DashboardItem(
            id: 2, type: DashboardWidgetType.quickActions, isMainArea: true),
        DashboardItem(
            id: 3,
            type: DashboardWidgetType.recommendedCourses,
            isMainArea: true),
      ];
      _sidebarItems = [
        DashboardItem(
            id: 4, type: DashboardWidgetType.keyMetrics, isMainArea: false),
        DashboardItem(
            id: 5,
            type: DashboardWidgetType.upcomingEvents,
            isMainArea: false),
        DashboardItem(
            id: 6,
            type: DashboardWidgetType.recentActivity,
            isMainArea: false),
      ];
    });
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userInfo');
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _showDomainInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('LMS Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_userInfo != null) ...[
              Text('Site: ${_userInfo!['sitename'] ?? 'Unknown'}'),
              Text('Version: ${_userInfo!['release'] ?? 'Unknown'}'),
              const SizedBox(height: 16),
            ],
            if (_currentDomain != null) ...[
              Text('Frontend: $_currentDomain'),
              FutureBuilder<String?>(
                future: _getComputedDomain(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != _currentDomain) {
                    return Text('API: ${snapshot.data}');
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 8),
            ],
            Text('User: ${_userInfo?['fullname'] ?? 'Unknown'}'),
            Text('Courses: ${_userCourses.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.instance.clearConfiguration();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DomainConfigScreen(),
                ),
              );
            },
            child: const Text('Change Domain'),
          ),
        ],
      ),
    );
  }

  Future<String?> _getComputedDomain() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_computed_domain');
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
        title: Text(_userInfo != null 
            ? 'Welcome, ${_userInfo!['firstname'] ?? 'User'}!'
            : 'My Dashboard'),
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
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
              icon: const Icon(Icons.info_outline, color: AppTheme.secondary1),
              onPressed: _showDomainInfo,
              tooltip: 'LMS Info',
            ),
          ),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.secondary1,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading your dashboard...',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
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