import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:InstructoHub/models/course_model.dart';
import 'package:InstructoHub/services/api_service.dart';
import 'package:InstructoHub/services/enhanced_icon_service.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';

import 'package:InstructoHub/screens/dashboard/course_catalog_screen.dart';
import 'package:InstructoHub/screens/dashboard/course_detail_screen.dart';
import 'package:InstructoHub/screens/dashboard/metrics_screen.dart';
import 'package:InstructoHub/screens/dashboard/quick_actions_screen.dart';
import 'package:InstructoHub/screens/dashboard/recent_activity_screen.dart';
import 'package:InstructoHub/screens/dashboard/recommended_courses_screen.dart';
import 'package:InstructoHub/screens/dashboard/upcoming_events_screen.dart';
import 'package:InstructoHub/features/messaging/screens/chat_list_screen.dart';
import 'package:InstructoHub/screens/domain_config/domain_config_screen.dart';

// Constants class remains the same
class AppStrings {
  static const String dashboard = 'Dashboard';
  static const String goodMorning = 'Good morning';
  static const String goodAfternoon = 'Good afternoon';
  static const String goodEvening = 'Good evening';
  static const String readyToContinue =
      'Ready to continue your learning journey?';
  static const String yourLearningMetrics = 'Your Learning Metrics';
  static const String quickActions = 'Quick Actions';
  static const String myCourses = 'My Courses';
  static const String upcomingEvents = 'Upcoming Events';
  static const String viewAll = 'View All';
  static const String browseCourses = 'Browse Courses';
  static const String noCoursesEnrolled = 'No courses enrolled yet';
  static const String noUpcomingEvents = 'No upcoming events';
  static const String startLearning = 'Start Learning';
  static const String continueLearning = 'Continue Learning';
  static const String exploreCatalog = 'Explore the course catalog';
  static const String unableToContinue =
      'Unable to continue. Please try again.';
  static const String errorFetchingCourses = 'Error fetching course details';
  static const String errorLoadingData = 'Error loading data';
  static const String tryAgain = 'Try Again';
  static const String logout = 'Logout';
  static const String totalCourses = 'Total Courses';
  static const String notStarted = 'Not Started';
  static const String activeCourses = 'Active Courses';
  static const String completed = 'Completed';
  static const String overallProgress = 'Overall Progress';
  static const String loadingCourses = 'Loading courses...';
  static const String loadingMetrics = 'Loading metrics...';
  static const String loadingEvents = 'Loading events...';
}

class DashboardScreen extends StatefulWidget {
  final String token;

  const DashboardScreen({required this.token, Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _userInfo;
  bool _isUserLoading = true;
  bool _isCoursesLoading = true;
  bool _isEventsLoading = true;
  bool _isMetricsLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Course> _myCourses = [];
  List<UpcomingEvent> _upcomingEvents = [];
  Map<String, dynamic> _learningMetrics = {};
  String? _errorMessage;

  late final List<DashboardItem> _drawerItems;
  late final List<QuickActionItem> _quickActions;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeServices();
    _fetchAllData();
    _animationController.forward();

    _drawerItems = [
      DashboardItem(id: 2, type: DashboardWidgetType.quickActions),
      DashboardItem(id: 3, type: DashboardWidgetType.recommendedCourses),
      DashboardItem(id: 4, type: DashboardWidgetType.keyMetrics),
      DashboardItem(id: 5, type: DashboardWidgetType.upcomingEvents),
      DashboardItem(id: 6, type: DashboardWidgetType.recentActivity),
    ];

    // CHANGED: Actions now get colors dynamically
    final themeService = DynamicThemeService.instance;
    _quickActions = [
      QuickActionItem(
        icon: 'quiz',
        title: 'Quiz',
        color: themeService.getColor('info'),
        type: DashboardWidgetType.quickActions,
      ),
      QuickActionItem(
        icon: 'certificate',
        title: 'Certificate',
        color: themeService.getColor('success'),
        type: DashboardWidgetType.keyMetrics,
      ),
      QuickActionItem(
        icon: 'discussions',
        title: 'Discussions',
        color: themeService.getColor('warning'),
        type: DashboardWidgetType.recentActivity,
      ),
      QuickActionItem(
        icon: 'assignments',
        title: 'Assignments',
        color: themeService.getColor('secondary2'),
        type: DashboardWidgetType.quickActions,
      ),
    ];
  }

  Future<void> _initializeServices() async {
    try {
      await DynamicIconService.instance.loadIcons(token: widget.token);
    } catch (e) {
      print('Failed to initialize icon service: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchUserInfo(),
      _fetchLearningMetrics(),
      _fetchUpcomingEvents(),
    ]);
  }

  Future<void> _fetchUserInfo() async {
    try {
      final result = await ApiService.instance.getUserInfo(widget.token);
      if (mounted && result['success'] == true) {
        setState(() {
          _userInfo = result['data'];
          _isUserLoading = false;
        });
      } else {
        if (mounted) setState(() => _isUserLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUserLoading = false);
        print('Failed to get user info: $e');
      }
    }
  }

  Future<void> _fetchLearningMetrics() async {
    setState(() => _isMetricsLoading = true);
    try {
      final progressData =
          await ApiService.instance.getUserProgress(widget.token);

      if (mounted && progressData != null) {
        final metrics = {
          'totalCourses': progressData['totalcourses']?.toString() ?? '0',
          'notStarted': progressData['notstartedcount']?.toString() ?? '0',
          'activeCourses':
              progressData['activecoursescount']?.toString() ?? '0',
          'completed': progressData['completedcoursescount']?.toString() ?? '0',
          'overallProgress':
              (progressData['overallprogress'] ?? 0.0).toDouble(),
        };

        List<Course> courses = [];
        if (progressData['courses'] is List) {
          courses = (progressData['courses'] as List)
              .map((courseData) => Course.fromJson(courseData))
              .toList();
        }

        setState(() {
          _learningMetrics = metrics;
          _myCourses = courses;
          _isMetricsLoading = false;
          _isCoursesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMetricsLoading = false;
          _isCoursesLoading = false;
          _errorMessage = e.toString();
        });
        print('Failed to get learning metrics: $e');
      }
    }
  }

  Future<void> _fetchUpcomingEvents() async {
    setState(() => _isEventsLoading = true);
    try {
      final eventsData =
          await ApiService.instance.getUpcomingEvents(widget.token);

      List<UpcomingEvent> events = [];
      if (eventsData is Map && eventsData['events'] is List) {
        final eventsList = eventsData['events'] as List;
        events = eventsList
            .map((eventData) => UpcomingEvent.fromJson(eventData))
            .toList();
      }

      if (mounted) {
        setState(() {
          _upcomingEvents = events;
          _isEventsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEventsLoading = false);
        print('Failed to get events: $e');
      }
    }
  }

  void _navigateToScreen(Widget screen, String screenName) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    } catch (e) {
      print('Navigation error to $screenName: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open $screenName. Please try again.'),
            // CHANGED: Using dynamic color
            backgroundColor: DynamicThemeService.instance.getColor('error'),
          ),
        );
      }
    }
  }

  void _navigateToCourse(Course course) {
    try {
      _saveLastViewedCourse(course);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseDetailScreen(
            course: course,
            token: widget.token,
          ),
        ),
      );
    } catch (e) {
      print('Error navigating to course: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to open course. Please try again.'),
            // CHANGED: Using dynamic color
            backgroundColor: DynamicThemeService.instance.getColor('error'),
          ),
        );
      }
    }
  }

  Future<void> _saveLastViewedCourse(Course course) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastViewedCourse', json.encode(course.toJson()));
    } catch (e) {
      print('Error saving last viewed course: $e');
    }
  }

  void _navigateTo(DashboardWidgetType type) {
    Navigator.pop(context);

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
        return;
    }
    _navigateToScreen(destination, type.toString().split('.').last);
  }

  Future<void> _logout() async {
    await ApiService.instance.clearConfiguration();
    await DynamicThemeService.instance.clearThemeCache();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DomainConfigScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Widget _buildDrawer() {
    // ADDED: Get theme service instance
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    final drawerHeaderColor = themeService.getColor('secondary2');
    final drawerBackgroundColor = themeService.getColor('secondary1');
    final iconColor = themeService.getColor('loginButtonTextColor');

    return Drawer(
      child: Container(
        // CHANGED: Dynamic color
        color: drawerBackgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _isUserLoading
                ? DrawerHeader(
                    decoration: BoxDecoration(color: drawerHeaderColor),
                    child: Center(
                        child: CircularProgressIndicator(color: iconColor)),
                  )
                : UserAccountsDrawerHeader(
                    accountName: Text(
                      _userInfo?['fullname'] ?? 'User',
                      style: textTheme.titleLarge?.copyWith(color: iconColor),
                    ),
                    accountEmail: Text(
                      _userInfo?['email'] ?? 'user@email.com',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: iconColor.withOpacity(0.9)),
                    ),
                    currentAccountPicture: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: iconColor, width: 2),
                      ),
                      child: CircleAvatar(
                        backgroundColor: themeService.getColor('secondary3'),
                        backgroundImage: _userInfo?['userpictureurl'] != null
                            ? NetworkImage(_userInfo!['userpictureurl'])
                            : null,
                        child: _userInfo?['userpictureurl'] == null
                            ? Icon(Icons.person,
                                color: themeService.getColor('secondary1'),
                                size: 30)
                            : null,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: drawerHeaderColor,
                    ),
                  ),
            ..._drawerItems.map((item) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  // CHANGED: Dynamic color
                  color: iconColor.withOpacity(0.1),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      DynamicIconService.instance.getIcon(item.type.name),
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: textTheme.bodyLarge?.copyWith(color: iconColor),
                  ),
                  onTap: () => _navigateTo(item.type),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: themeService.getColor('error').withOpacity(0.2),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeService.getColor('error').withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    DynamicIconService.instance.getIcon('logout'),
                    color: iconColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  AppStrings.logout,
                  style: textTheme.bodyLarge?.copyWith(color: iconColor),
                ),
                onTap: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return themeService.buildGradientContainer(
      margin: EdgeInsets.all(themeService.getSpacing('md')),
      gradient: themeService.getWelcomeGradient(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()},',
                  style: textTheme.bodyLarge?.copyWith(
                    color: themeService.getColor('textSecondary'),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userInfo?['fullname']?.split(' ').first ?? 'User',
                  style: textTheme.headlineSmall?.copyWith(
                    color: themeService.getColor('textPrimary'),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.readyToContinue,
                  style: textTheme.bodyMedium?.copyWith(
                    color: themeService.getColor('textSecondary'),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(themeService.getSpacing('sm') + 4),
            decoration: BoxDecoration(
              color: themeService.getColor('primary').withOpacity(0.15),
              borderRadius:
                  BorderRadius.circular(themeService.getBorderRadius('medium')),
            ),
            child: Icon(
              DynamicIconService.instance.getIcon('school'),
              color: themeService.getColor('primary'),
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 17) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }

  Widget _buildLearningMetrics() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    if (_isMetricsLoading) {
      return Center(
        child: themeService.buildFloatingCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                  color: themeService.getColor('primary')),
              SizedBox(height: themeService.getSpacing('sm')),
              Text(
                AppStrings.loadingMetrics,
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: themeService.getSpacing('md')),
        child: themeService.buildFloatingCard(
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: themeService.getColor('error'),
                size: 48,
              ),
              SizedBox(height: themeService.getSpacing('sm')),
              Text(
                AppStrings.errorLoadingData,
                style: textTheme.titleMedium?.copyWith(
                  color: themeService.getColor('error'),
                ),
              ),
              SizedBox(height: themeService.getSpacing('xs')),
              Text(
                _errorMessage!,
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: themeService.getSpacing('md')),
              ElevatedButton(
                onPressed: _fetchLearningMetrics,
                style: themeService.getPrimaryButtonStyle(),
                child: const Text(AppStrings.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: themeService.getSpacing('md')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.yourLearningMetrics,
            style: textTheme.headlineSmall,
          ),
          SizedBox(height: themeService.getSpacing('md')),

          // Overall Progress Card
          themeService.buildFloatingCard(
            child: Column(
              children: [
                Text(
                  AppStrings.overallProgress,
                  style: textTheme.titleLarge?.copyWith(
                    color: themeService.getColor('textPrimary'),
                  ),
                ),
                SizedBox(height: themeService.getSpacing('md')),
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: (_learningMetrics['overallProgress'] ?? 0.0) /
                              100,
                          strokeWidth: 12,
                          backgroundColor:
                              themeService.getColor('divider').withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            themeService.getColor('primary'),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(themeService.getSpacing('sm')),
                        decoration: BoxDecoration(
                          color: themeService.getColor('cardElevated'),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: themeService
                                  .getColor('textPrimary')
                                  .withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${(_learningMetrics['overallProgress'] ?? 0.0).toStringAsFixed(0)}%',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: themeService.getColor('primary'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: themeService.getSpacing('md')),

          // Metrics Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: themeService.getSpacing('sm'),
            mainAxisSpacing: themeService.getSpacing('sm'),
            childAspectRatio: 1.3,
            children: [
              _buildEnhancedMetricCard(
                AppStrings.totalCourses,
                _learningMetrics['totalCourses'] ?? '0',
                DynamicIconService.instance.getIcon('courses'),
                themeService.getColor('info'),
              ),
              _buildEnhancedMetricCard(
                AppStrings.completed,
                _learningMetrics['completed'] ?? '0',
                DynamicIconService.instance.getIcon('check_circle'),
                themeService.getColor('success'),
              ),
              _buildEnhancedMetricCard(
                AppStrings.activeCourses,
                _learningMetrics['activeCourses'] ?? '0',
                DynamicIconService.instance.getIcon('play'),
                themeService.getColor('warning'),
              ),
              _buildEnhancedMetricCard(
                AppStrings.notStarted,
                _learningMetrics['notStarted'] ?? '0',
                DynamicIconService.instance.getIcon('schedule'),
                themeService.getColor('textSecondary'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMetricCard(
      String title, String value, IconData icon, Color color) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: themeService.getDynamicCardDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: themeService.getColor('textPrimary').withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(themeService.getSpacing('md')),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(themeService.getSpacing('sm')),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                    themeService.getBorderRadius('small')),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: themeService.getSpacing('xs')),
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                color: themeService.getColor('textPrimary'),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: themeService.getSpacing('xs') / 2),
            Text(
              title,
              style: textTheme.bodySmall?.copyWith(
                color: themeService.getColor('textSecondary'),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    // ADDED: Get theme service instance
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius:
            BorderRadius.circular(themeService.getBorderRadius('medium')),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value,
              style: textTheme.headlineSmall
                  ?.copyWith(color: themeService.getColor('textPrimary'))),
          const SizedBox(height: 4),
          Text(
            title,
            style: textTheme.bodySmall
                ?.copyWith(color: themeService.getColor('textSecondary')),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: themeService.getSpacing('md')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.quickActions,
            style: textTheme.headlineSmall,
          ),
          SizedBox(height: themeService.getSpacing('sm')),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: themeService.getSpacing('sm'),
              mainAxisSpacing: themeService.getSpacing('sm'),
              childAspectRatio: 0.85,
            ),
            itemCount: _quickActions.length,
            itemBuilder: (context, index) {
              final action = _quickActions[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateTo(action.type),
                  borderRadius: BorderRadius.circular(
                      themeService.getBorderRadius('medium')),
                  child: Container(
                    decoration: themeService.getDynamicCardDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: action.color.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding:
                              EdgeInsets.all(themeService.getSpacing('sm')),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                action.color.withOpacity(0.1),
                                action.color.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(
                                themeService.getBorderRadius('small')),
                            border: Border.all(
                              color: action.color.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            DynamicIconService.instance.getIcon(action.icon),
                            color: action.color,
                            size: 24,
                          ),
                        ),
                        SizedBox(height: themeService.getSpacing('xs')),
                        Text(
                          action.title,
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMyCoursesSection() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: themeService.getSpacing('md')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.myCourses, style: textTheme.headlineSmall),
              TextButton(
                onPressed: () => _navigateToScreen(
                  CourseCatalogScreen(token: widget.token),
                  'Course Catalog',
                ),
                style: themeService.getSecondaryButtonStyle().copyWith(
                      padding: MaterialStateProperty.all(
                        EdgeInsets.symmetric(
                          horizontal: themeService.getSpacing('md'),
                          vertical: themeService.getSpacing('xs'),
                        ),
                      ),
                    ),
                child: Text(
                  AppStrings.viewAll,
                  style: TextStyle(color: themeService.getColor('primary')),
                ),
              ),
            ],
          ),
          SizedBox(height: themeService.getSpacing('sm')),
          if (_isCoursesLoading)
            Center(
              child: CircularProgressIndicator(
                color: themeService.getColor('primary'),
              ),
            )
          else if (_myCourses.isEmpty)
            themeService.buildFloatingCard(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(themeService.getSpacing('md')),
                    decoration: BoxDecoration(
                      color: themeService.getColor('primary').withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      DynamicIconService.instance.getIcon('school'),
                      size: 48,
                      color: themeService.getColor('primary'),
                    ),
                  ),
                  SizedBox(height: themeService.getSpacing('md')),
                  Text(
                    AppStrings.noCoursesEnrolled,
                    style: textTheme.titleMedium,
                  ),
                  SizedBox(height: themeService.getSpacing('xs')),
                  TextButton(
                    onPressed: () => _navigateToScreen(
                      CourseCatalogScreen(token: widget.token),
                      'Course Catalog',
                    ),
                    child: Text(
                      AppStrings.browseCourses,
                      style: TextStyle(color: themeService.getColor('primary')),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _myCourses.take(10).length,
                itemBuilder: (context, index) {
                  final course = _myCourses[index];
                  return Container(
                    width: 280,
                    margin:
                        EdgeInsets.only(right: themeService.getSpacing('sm')),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _navigateToCourse(course),
                        borderRadius: BorderRadius.circular(
                            themeService.getBorderRadius('medium')),
                        child: Container(
                          decoration: themeService.getElevatedCardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 100,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: themeService
                                      .getColor('primary')
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(
                                        themeService.getBorderRadius('medium')),
                                    topRight: Radius.circular(
                                        themeService.getBorderRadius('medium')),
                                  ),
                                ),
                                child: course.courseimage.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(themeService
                                              .getBorderRadius('medium')),
                                          topRight: Radius.circular(themeService
                                              .getBorderRadius('medium')),
                                        ),
                                        child: Image.network(
                                          course.courseimage,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Center(
                                            child: Icon(
                                              DynamicIconService.instance
                                                  .getIcon('school'),
                                              color: themeService
                                                  .getColor('primary'),
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Icon(
                                          DynamicIconService.instance
                                              .getIcon('school'),
                                          color:
                                              themeService.getColor('primary'),
                                          size: 32,
                                        ),
                                      ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(
                                      themeService.getSpacing('md')),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        course.fullname,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      if (course.progress != null) ...[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Progress',
                                              style:
                                                  textTheme.bodySmall?.copyWith(
                                                color: themeService
                                                    .getColor('textSecondary'),
                                              ),
                                            ),
                                            Text(
                                              '${course.progress!.toStringAsFixed(0)}%',
                                              style:
                                                  textTheme.bodySmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: themeService
                                                    .getColor('primary'),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                            height:
                                                themeService.getSpacing('xs')),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              themeService
                                                  .getBorderRadius('small')),
                                          child: LinearProgressIndicator(
                                            value: course.progress! / 100,
                                            backgroundColor: themeService
                                                .getColor('divider')
                                                .withOpacity(0.3),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              themeService.getColor('primary'),
                                            ),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsSection() {
    // ADDED: Get theme service instance
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: themeService.getSpacing('md')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.upcomingEvents, style: textTheme.headlineSmall),
          const SizedBox(height: 12),
          if (_isEventsLoading)
            const Center(child: CircularProgressIndicator())
          else if (_upcomingEvents.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: themeService.getColor('cardColor'),
                borderRadius: BorderRadius.circular(
                    themeService.getBorderRadius('medium')),
              ),
              child: Column(
                children: [
                  Icon(
                    DynamicIconService.instance.getIcon('event'),
                    size: 48,
                    color:
                        themeService.getColor('textSecondary').withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(AppStrings.noUpcomingEvents,
                      style: textTheme.titleMedium),
                ],
              ),
            )
          else
            ...(_upcomingEvents.take(3).map((event) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            themeService.getColor('warning').withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                            themeService.getBorderRadius('small')),
                      ),
                      child: Icon(
                        DynamicIconService.instance.getIcon('event'),
                        color: themeService.getColor('warning'),
                        size: 20,
                      ),
                    ),
                    title: Text(event.title, style: textTheme.titleSmall),
                    subtitle: Text(event.subtitle, style: textTheme.bodySmall),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(event.formattedDate,
                            style: textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(event.formattedTime, style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                ))).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ADDED: Get theme service instance
    final themeService = DynamicThemeService.instance;

    return Scaffold(
      backgroundColor: themeService.getColor('background'),
      appBar: AppBar(
        title: const Text(AppStrings.dashboard),
        actions: [
          IconButton(
            icon: Icon(DynamicIconService.instance.getIcon('notifications')),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _fetchAllData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isUserLoading) _buildWelcomeSection(),
                const SizedBox(height: 8),
                ContinueLearningWidget(token: widget.token),
                const SizedBox(height: 24),
                _buildLearningMetrics(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildMyCoursesSection(),
                const SizedBox(height: 24),
                _buildUpcomingEventsSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _navigateToScreen(ChatListScreen(token: widget.token), 'Chat'),
        // CHANGED: Dynamic icon color
        child: Icon(DynamicIconService.instance.getIcon('chat'),
            color: themeService.getColor('loginButtonTextColor')),
      ),
    );
  }
}

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

  DashboardItem({required this.id, required this.type});

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

class QuickActionItem {
  final String icon;
  final String title;
  final Color color;
  final DashboardWidgetType type;

  QuickActionItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.type,
  });
}

class UpcomingEvent {
  final String title;
  final String subtitle;
  final String formattedDate;
  final String formattedTime;

  UpcomingEvent({
    required this.title,
    required this.subtitle,
    required this.formattedDate,
    required this.formattedTime,
  });

  factory UpcomingEvent.fromJson(Map<String, dynamic> json) {
    final timestamp = json['timestart'];
    DateTime date = DateTime.now();
    if (timestamp is int) {
      date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    }

    return UpcomingEvent(
      title: json['name'] ?? 'Event',
      subtitle: json['description'] ?? '',
      formattedDate: _formatDate(date),
      formattedTime: _formatTime(date),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${date.minute.toString().padLeft(2, '0')} $period';
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
        if (mounted) {
          setState(() =>
              _lastViewedCourse = Course.fromJson(json.decode(jsonString)));
        }
      } catch (_) {}
    }
  }

  void _handleTap() {
    try {
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
    } catch (e) {
      print('Error in continue learning navigation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.unableToContinue),
            // CHANGED: Dynamic color
            backgroundColor: DynamicThemeService.instance.getColor('error'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ADDED: Get theme service instance
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    final successColor = themeService.getColor('success');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: themeService.getSpacing('md')),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            successColor.withOpacity(0.1),
            successColor.withOpacity(0.05),
          ],
        ),
        borderRadius:
            BorderRadius.circular(themeService.getBorderRadius('large')),
        border: Border.all(color: successColor.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius:
              BorderRadius.circular(themeService.getBorderRadius('large')),
          child: Padding(
            padding: EdgeInsets.all(themeService.getSpacing('lg') - 4), // 20
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                        themeService.getBorderRadius('medium')),
                  ),
                  child: Icon(
                    DynamicIconService.instance.getIcon('play'),
                    color: successColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _lastViewedCourse == null
                            ? AppStrings.startLearning
                            : AppStrings.continueLearning,
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _lastViewedCourse?.fullname ??
                            AppStrings.exploreCatalog,
                        style: textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: successColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
