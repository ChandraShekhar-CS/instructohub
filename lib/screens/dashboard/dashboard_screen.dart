import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../models/course_model.dart';
import '../../services/api_service.dart';
import '../../services/enhanced_icon_service.dart';
import '../../services/dynamic_theme_service.dart';

import 'course_catalog_screen.dart';
import 'course_detail_screen.dart';
import 'metrics_screen.dart';
import 'quick_actions_screen.dart';
import 'recent_activity_screen.dart';
import 'recommended_courses_screen.dart';
import 'upcoming_events_screen.dart';
import '../../features/messaging/screens/chat_list_screen.dart';
import '../domain_config/domain_config_screen.dart';

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
        if(mounted) setState(() => _isUserLoading = false);
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
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    
    return Drawer(
      child: Container(
        color: themeService.getColor('secondary1'),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _isUserLoading
                ? DrawerHeader(
                    decoration: BoxDecoration(color: themeService.getColor('secondary2')),
                    child: const Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                  )
                : UserAccountsDrawerHeader(
                    accountName: Text(
                      _userInfo?['fullname'] ?? 'User',
                      style: textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    accountEmail: Text(
                      _userInfo?['email'] ?? 'user@email.com',
                      style: textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
                    ),
                    currentAccountPicture: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
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
                      color: themeService.getColor('secondary2'),
                    ),
                  ),
            ..._drawerItems.map((item) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.1),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      DynamicIconService.instance.getIcon(item.type.name),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: textTheme.bodyLarge?.copyWith(color: Colors.white),
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
                color: Colors.red.withOpacity(0.2),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    DynamicIconService.instance.getIcon('logout'),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  AppStrings.logout,
                  style: textTheme.bodyLarge?.copyWith(color: Colors.white),
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
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: themeService.getDynamicButtonGradient(),
        borderRadius: BorderRadius.circular(themeService.getBorderRadius('large')),
        boxShadow: [
          BoxShadow(
            color: themeService.getColor('secondary1').withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()},',
                  style: textTheme.bodyLarge?.copyWith(color: Colors.white.withOpacity(0.9)),
                ),
                const SizedBox(height: 4),
                Text(
                  _userInfo?['fullname']?.split(' ').first ?? 'User',
                  style: textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.readyToContinue,
                  style: textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(themeService.getBorderRadius('medium')),
            ),
            child: Icon(
              DynamicIconService.instance.getIcon('school'),
              color: Colors.white,
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircularProgressIndicator(color: themeService.getColor('secondary1')),
              const SizedBox(height: 12),
              Text(AppStrings.loadingMetrics, style: textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.error_outline,
                    color: themeService.getColor('error'),
                    size: 48),
                const SizedBox(height: 12),
                Text(AppStrings.errorLoadingData,
                  style: textTheme.titleMedium?.copyWith(color: themeService.getColor('error'))),
                const SizedBox(height: 8),
                Text(_errorMessage!, style: textTheme.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchLearningMetrics,
                  child: const Text(AppStrings.tryAgain),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.yourLearningMetrics, style: textTheme.headlineSmall),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeService.getColor('secondary1').withOpacity(0.1),
                  themeService.getColor('secondary2').withOpacity(0.1)
                ],
              ),
              borderRadius: BorderRadius.circular(themeService.getBorderRadius('large')),
              border: Border.all(color: themeService.getColor('secondary1').withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(AppStrings.overallProgress, style: textTheme.titleLarge),
                const SizedBox(height: 16),
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
                          value: (_learningMetrics['overallProgress'] ?? 0.0) / 100,
                          strokeWidth: 12,
                          backgroundColor: themeService.getColor('textSecondary').withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(themeService.getColor('secondary1')),
                        ),
                      ),
                      Text(
                        '${(_learningMetrics['overallProgress'] ?? 0.0).toStringAsFixed(0)}%',
                        style: textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildMetricCard(
                AppStrings.totalCourses,
                _learningMetrics['totalCourses'] ?? '0',
                DynamicIconService.instance.getIcon('courses'),
                themeService.getColor('info'),
              ),
              _buildMetricCard(
                AppStrings.completed,
                _learningMetrics['completed'] ?? '0',
                DynamicIconService.instance.getIcon('check_circle'),
                themeService.getColor('success'),
              ),
              _buildMetricCard(
                AppStrings.activeCourses,
                _learningMetrics['activeCourses'] ?? '0',
                DynamicIconService.instance.getIcon('play'),
                themeService.getColor('warning'),
              ),
              _buildMetricCard(
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

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    final textTheme = Theme.of(context).textTheme;
    final themeService = DynamicThemeService.instance;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(themeService.getBorderRadius('medium')),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: textTheme.headlineSmall?.copyWith(color: themeService.getColor('textPrimary'))),
          const SizedBox(height: 4),
          Text(
            title,
            style: textTheme.bodySmall?.copyWith(color: themeService.getColor('textSecondary')),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.quickActions, style: textTheme.headlineSmall),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _quickActions.length,
            itemBuilder: (context, index) {
              final action = _quickActions[index];
              return GestureDetector(
                onTap: () => _navigateTo(action.type),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: action.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: action.color.withOpacity(0.3), width: 1),
                      ),
                      child: Icon(DynamicIconService.instance.getIcon(action.icon), color: action.color, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action.title,
                      style: textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.myCourses, style: textTheme.headlineSmall),
              TextButton(
                onPressed: () => _navigateToScreen(CourseCatalogScreen(token: widget.token), 'Course Catalog'),
                child: Text(AppStrings.viewAll, style: TextStyle(color: themeService.getColor('secondary1'))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isCoursesLoading)
            const Center(child: CircularProgressIndicator())
          else if (_myCourses.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: themeService.getColor('cardColor'),
                borderRadius: BorderRadius.circular(themeService.getBorderRadius('medium'))
              ),
              child: Column(
                children: [
                  Icon(
                    DynamicIconService.instance.getIcon('school'),
                    size: 64,
                    color: themeService.getColor('textSecondary').withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(AppStrings.noCoursesEnrolled, style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _navigateToScreen(CourseCatalogScreen(token: widget.token), 'Course Catalog'),
                    child: const Text(AppStrings.browseCourses),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _myCourses.take(10).length,
                itemBuilder: (context, index) {
                  final course = _myCourses[index];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _navigateToCourse(course),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 80,
                              width: double.infinity,
                              color: themeService.getColor('secondary3'),
                              child: course.courseimage.isNotEmpty
                                  ? Image.network(
                                      course.courseimage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                        Icon(DynamicIconService.instance.getIcon('school'), color: themeService.getColor('secondary1'), size: 32),
                                    )
                                  : Icon(DynamicIconService.instance.getIcon('school'), color: themeService.getColor('secondary1'), size: 32),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      course.fullname,
                                      style: textTheme.titleSmall,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    if (course.progress != null)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Progress', style: textTheme.bodySmall),
                                              Text('${course.progress!.toStringAsFixed(0)}%', style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          LinearProgressIndicator(
                                            value: course.progress! / 100,
                                            backgroundColor: themeService.getColor('textSecondary').withOpacity(0.2),
                                            valueColor: AlwaysStoppedAnimation<Color>(themeService.getColor('secondary1')),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                borderRadius: BorderRadius.circular(themeService.getBorderRadius('medium')),
              ),
              child: Column(
                children: [
                  Icon(
                    DynamicIconService.instance.getIcon('event'),
                    size: 48,
                    color: themeService.getColor('textSecondary').withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(AppStrings.noUpcomingEvents, style: textTheme.titleMedium),
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
                        color: themeService.getColor('warning').withOpacity(0.1),
                        borderRadius: BorderRadius.circular(themeService.getBorderRadius('small')),
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
                        Text(event.formattedDate, style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
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
        onPressed: () => _navigateToScreen(ChatListScreen(token: widget.token), 'Chat'),
        child: Icon(DynamicIconService.instance.getIcon('chat'), color: Colors.white),
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
      case DashboardWidgetType.continueLearning: return 'Continue Learning';
      case DashboardWidgetType.courseCatalog: return 'Course Catalog';
      case DashboardWidgetType.quickActions: return 'Quick Actions';
      case DashboardWidgetType.recommendedCourses: return 'Recommended Courses';
      case DashboardWidgetType.keyMetrics: return 'Key Metrics';
      case DashboardWidgetType.upcomingEvents: return 'Upcoming Events';
      case DashboardWidgetType.recentActivity: return 'Recent Activity';
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
    if(timestamp is int) {
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
          setState(() => _lastViewedCourse = Course.fromJson(json.decode(jsonString)));
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
          const SnackBar(
            content: Text(AppStrings.unableToContinue),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    final successColor = themeService.getColor('success');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            successColor.withOpacity(0.1),
            successColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(themeService.getBorderRadius('large')),
        border: Border.all(color: successColor.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(themeService.getBorderRadius('large')),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(themeService.getBorderRadius('medium')),
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
                        _lastViewedCourse == null ? AppStrings.startLearning : AppStrings.continueLearning,
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _lastViewedCourse?.fullname ?? AppStrings.exploreCatalog,
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
