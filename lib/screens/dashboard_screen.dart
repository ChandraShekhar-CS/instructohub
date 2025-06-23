import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/course_model.dart';
import '../services/api_service.dart';
import '../services/enhanced_icon_service.dart';
import '../theme/dynamic_app_theme.dart';

// Import all the screens you will navigate to
import 'course_catalog_screen.dart';
import 'course_detail_screen.dart';
import 'metrics_screen.dart';
import 'quick_actions_screen.dart';
import 'recent_activity_screen.dart';
import 'recommended_courses_screen.dart';
import 'upcoming_events_screen.dart';
import '../../features/messaging/screens/chat_list_screen.dart';
import 'domain_config_screen.dart'; // Import for logout navigation

typedef AppTheme = DynamicAppTheme;

class DashboardScreen extends StatefulWidget {
  final String token;

  const DashboardScreen({required this.token, Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // State to hold user info for the drawer header
  Map<String, dynamic>? _userInfo;
  bool _isUserLoading = true;

  // List for items that will go into the side drawer
  late final List<DashboardItem> _drawerItems;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();

    // Populate the list for the drawer items
    _drawerItems = [
      DashboardItem(id: 2, type: DashboardWidgetType.quickActions),
      DashboardItem(id: 3, type: DashboardWidgetType.recommendedCourses),
      DashboardItem(id: 4, type: DashboardWidgetType.keyMetrics),
      DashboardItem(id: 5, type: DashboardWidgetType.upcomingEvents),
      DashboardItem(id: 6, type: DashboardWidgetType.recentActivity),
    ];
  }

  // Fetch user info to display in the drawer
  Future<void> _fetchUserInfo() async {
    try {
      final result = await ApiService.instance.getUserInfo(widget.token);
      if (mounted && result['success'] == true) {
        setState(() {
          _userInfo = result['data'];
          _isUserLoading = false;
        });
      } else {
        setState(() {
          _isUserLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUserLoading = false;
        });
        print('Failed to get user info: $e');
      }
    }
  }

  // Navigate to the selected screen
  void _navigateTo(DashboardWidgetType type) {
    // Close the drawer first
    Navigator.pop(context);

    // Push the new route
    Widget destination;
    switch (type) {
      case DashboardWidgetType.quickActions:
        destination = QuickActionsScreen(token: widget.token);
        break;
      case DashboardWidgetType.recommendedCourses:
        destination = RecommendedCoursesScreen(token: widget.token);
        break;
      case DashboardWidgetType.keyMetrics:
        destination = MetricsScreen(token: widget.token);
        break;
      case DashboardWidgetType.upcomingEvents:
        destination = UpcomingEventsScreen(token: widget.token);
        break;
      case DashboardWidgetType.recentActivity:
        destination = RecentActivityScreen(token: widget.token);
        break;
      case DashboardWidgetType.courseCatalog:
         destination = CourseCatalogScreen(token: widget.token);
         break;
      default:
        return; // Should not happen for drawer items
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  // Handle user logout
  Future<void> _logout() async {
    // Clear all saved data
    await ApiService.instance.clearConfiguration();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Navigate to the domain configuration screen and remove all previous routes
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DomainConfigScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // Build the side panel (Drawer)
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _isUserLoading
              ? DrawerHeader(
                  decoration: BoxDecoration(color: AppTheme.secondary1),
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                )
              : UserAccountsDrawerHeader(
                  accountName: Text(
                    _userInfo?['fullname'] ?? 'User Name',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  accountEmail: Text(_userInfo?['email'] ?? 'user@email.com'),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: AppTheme.secondary3,
                    backgroundImage: _userInfo?['userpictureurl'] != null
                        ? NetworkImage(_userInfo!['userpictureurl'])
                        : null,
                    child: _userInfo?['userpictureurl'] == null
                        ? Icon(Icons.person, color: AppTheme.secondary1)
                        : null,
                  ),
                  decoration: BoxDecoration(color: AppTheme.secondary1),
                ),
          // Map the drawer items to ListTiles
          ..._drawerItems.map((item) {
            return ListTile(
              leading: Icon(
                DynamicIconService.instance.getIcon(item.type.name),
                color: AppTheme.textSecondary
              ),
              title: Text(item.title),
              onTap: () => _navigateTo(item.type),
            );
          }).toList(),
          const Divider(),
          ListTile(
            leading: Icon(DynamicIconService.instance.getIcon('logout'), color: AppTheme.textSecondary),
            title: const Text('Logout'),
            onTap: _logout,
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppTheme.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        titleTextStyle: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      drawer: _buildDrawer(), // Add the drawer to the scaffold
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            // Main screen item: Continue Learning
            ContinueLearningWidget(token: widget.token),
            const SizedBox(height: 8),
            // Main screen item: Course Catalog
            InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CourseCatalogScreen(token: widget.token))),
              child: const CourseCatalogWidget(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatListScreen(token: widget.token),
            ),
          );
        },
        backgroundColor: AppTheme.secondary1,
        child: Icon(
          DynamicIconService.instance.getIcon('chat'),
          color: Colors.white,
        ),
      ),
    );
  }
}

// Enum and Class definitions for Dashboard items
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

  DashboardItem({
    required this.id,
    required this.type,
  });
  
  String get title {
    switch (type) {
      case DashboardWidgetType.continueLearning:
        return 'Continue Learning';
      case DashboardWidgetType.courseCatalog:
        return 'Course Catalog';
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


// --- WIDGETS (You can keep these as they are, or move them to separate files) ---

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
