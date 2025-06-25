import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:InstructoHub/models/course_model.dart';
import 'package:InstructoHub/services/api_service.dart';
import 'package:InstructoHub/services/enhanced_icon_service.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';

import 'course_catalog_screen.dart';
import 'course_detail_screen.dart';
import 'package:InstructoHub/features/messaging/screens/chat_list_screen.dart';
import 'package:InstructoHub/screens/domain_config/domain_config_screen.dart';
import 'downloaded_courses_screen.dart';
import 'dashboard_widgets.dart';

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
  static const String downloadedCourses = 'Downloaded Courses';
}

enum DashboardWidgetType {
  continueLearning,
  courseCatalog,
  quickActions,
  recommendedCourses,
  keyMetrics,
  upcomingEvents,
  recentActivity,
  downloadedCourses,
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
      case DashboardWidgetType.downloadedCourses:
        return 'Downloaded Courses';
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
  late List<QuickActionItem> _quickActions;

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

    DynamicThemeService.instance.addListener(_onThemeChanged);

    _initializeServices();
    _fetchAllData();
    _animationController.forward();

    _drawerItems = [
      DashboardItem(id: 2, type: DashboardWidgetType.quickActions),
      DashboardItem(id: 3, type: DashboardWidgetType.recommendedCourses),
      DashboardItem(id: 4, type: DashboardWidgetType.keyMetrics),
      DashboardItem(id: 5, type: DashboardWidgetType.upcomingEvents),
      DashboardItem(id: 6, type: DashboardWidgetType.recentActivity),
      DashboardItem(id: 7, type: DashboardWidgetType.downloadedCourses),
    ];

    _initializeQuickActions();
  }

  void _initializeQuickActions() {
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
        color: themeService.getColor('primary'),
        type: DashboardWidgetType.quickActions,
      ),
    ];
  }
  
  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        _initializeQuickActions();
      });
    }
  }

  Future<void> _initializeServices() async {
    try {
      await DynamicIconService.instance.loadIcons(token: widget.token);
    } catch (e) {
      // Failed to initialize icon service
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    DynamicThemeService.instance.removeListener(_onThemeChanged);
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

        if (progressData['courses'] is List &&
            (progressData['courses'] as List).isNotEmpty) {
          courses = (progressData['courses'] as List).map((courseData) {
            return Course.fromJson(courseData);
          }).toList();
        } else {
          try {
            final fallbackCourses =
                await ApiService.instance.getUserCourses(widget.token);
            courses = fallbackCourses.map((courseData) {
              return Course.fromJson({
                'id': courseData['id'],
                'fullname': courseData['fullname'] ??
                    courseData['displayname'] ??
                    courseData['shortname'] ??
                    'Course ${courseData['id']}',
                'summary': courseData['summary'] ?? '',
                'courseimage': courseData['courseimage'] ?? '',
                'progress': 0.0,
              });
            }).toList();
          } catch (e) {
            // Fallback course fetch failed
          }
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
      // Error saving last viewed course
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
      case DashboardWidgetType.downloadedCourses:
        destination = DownloadedCoursesScreen(token: widget.token);
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 17) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }

  IconData _getDrawerIcon(DashboardWidgetType type) {
    switch (type) {
      case DashboardWidgetType.quickActions:
        return Icons.flash_on;
      case DashboardWidgetType.recommendedCourses:
        return Icons.recommend;
      case DashboardWidgetType.keyMetrics:
        return Icons.analytics;
      case DashboardWidgetType.upcomingEvents:
        return Icons.event;
      case DashboardWidgetType.recentActivity:
        return Icons.history;
      case DashboardWidgetType.downloadedCourses:
        return Icons.download;
      default:
        return Icons.help_outline;
    }
  }

  Color _getProgressColor(double progress) {
    final themeService = DynamicThemeService.instance;
    if (progress >= 100) {
      return themeService.getColor('success');
    } else if (progress >= 50) {
      return themeService.getColor('info');
    } else if (progress > 0) {
      return themeService.getColor('warning');
    } else {
      return themeService.getColor('textMuted');
    }
  }

  String _getProgressStatus(double progress) {
    if (progress >= 100) {
      return 'Completed';
    } else if (progress >= 50) {
      return 'In Progress';
    } else if (progress > 0) {
      return 'Started';
    } else {
      return 'Not Started';
    }
  }

  Widget _buildWelcomeSection() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.all(themeService.getSpacing('md')),
      child: themeService.buildCleanCard(
        backgroundColor: themeService.getColor('primary'),
        padding: EdgeInsets.all(themeService.getSpacing('md')),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getGreeting()},',
                    style: textTheme.bodyMedium?.copyWith(
                      color:
                          themeService.getColor('onPrimary').withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userInfo?['fullname']?.split(' ').first ?? 'User',
                    style: textTheme.headlineSmall?.copyWith(
                      color: themeService.getColor('onPrimary'),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.readyToContinue,
                    style: textTheme.bodySmall?.copyWith(
                      color:
                          themeService.getColor('onPrimary').withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(themeService.getSpacing('sm')),
              decoration: BoxDecoration(
                color: themeService.getColor('onPrimary').withOpacity(0.15),
                borderRadius: BorderRadius.circular(
                    themeService.getBorderRadius('medium')),
              ),
              child: Icon(
                Icons.school,
                color: themeService.getColor('onPrimary'),
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueLearningWidget() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: themeService.getSpacing('md')),
      child: themeService.buildCleanCard(
        backgroundColor: themeService.getColor('success').withOpacity(0.05),
        onTap: () => _navigateToScreen(
            CourseCatalogScreen(token: widget.token), 'Course Catalog'),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(themeService.getSpacing('xs')),
              decoration: BoxDecoration(
                color: themeService.getColor('success').withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                    themeService.getBorderRadius('small')),
              ),
              child: Icon(
                Icons.play_arrow,
                color: themeService.getColor('success'),
                size: 20,
              ),
            ),
            SizedBox(width: themeService.getSpacing('md')),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.startLearning,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: themeService.getColor('textPrimary'),
                    ),
                  ),
                  SizedBox(height: themeService.getSpacing('xs') / 2),
                  Text(
                    AppStrings.exploreCatalog,
                    style: textTheme.bodySmall?.copyWith(
                      color: themeService.getColor('textSecondary'),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: themeService.getColor('success'),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningMetrics() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    if (_isMetricsLoading) {
      return Center(
        child: themeService.buildCleanCard(
          margin: EdgeInsets.all(themeService.getSpacing('md')),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                  color: themeService.getColor('primary')),
              SizedBox(height: themeService.getSpacing('sm')),
              Text(AppStrings.loadingMetrics, style: textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: themeService.getSpacing('md')),
        child: themeService.buildCleanCard(
          child: Column(
            children: [
              Icon(Icons.error_outline,
                  color: themeService.getColor('error'), size: 48),
              SizedBox(height: themeService.getSpacing('sm')),
              Text(AppStrings.errorLoadingData,
                  style: textTheme.titleMedium
                      ?.copyWith(color: themeService.getColor('error'))),
              SizedBox(height: themeService.getSpacing('xs')),
              Text(_errorMessage!,
                  style: textTheme.bodySmall, textAlign: TextAlign.center),
              SizedBox(height: themeService.getSpacing('md')),
              ElevatedButton(
                onPressed: _fetchLearningMetrics,
                child: const Text(AppStrings.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        themeService.buildSectionHeader(title: AppStrings.yourLearningMetrics),
        SizedBox(height: themeService.getSpacing('md')),
        Container(
          margin:
              EdgeInsets.symmetric(horizontal: themeService.getSpacing('md')),
          child: themeService.buildCleanCard(
            child: Column(
              children: [
                Text(
                  AppStrings.overallProgress,
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: themeService.getSpacing('lg')),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: (_learningMetrics['overallProgress'] ?? 0.0) /
                              100,
                          strokeWidth: 8,
                          backgroundColor: themeService.getColor('borderLight'),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              themeService.getColor('primary')),
                        ),
                      ),
                      Text(
                        '${(_learningMetrics['overallProgress'] ?? 0.0).toStringAsFixed(0)}%',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: themeService.getColor('primary'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: themeService.getSpacing('md')),
        Container(
          margin:
              EdgeInsets.symmetric(horizontal: themeService.getSpacing('md')),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: themeService.getSpacing('sm'),
            mainAxisSpacing: themeService.getSpacing('sm'),
            childAspectRatio: 1.4,
            children: [
              themeService.buildMetricCard(
                title: AppStrings.totalCourses,
                value: _learningMetrics['totalCourses'] ?? '0',
                icon: Icons.book,
                iconColor: themeService.getColor('info'),
              ),
              themeService.buildMetricCard(
                title: AppStrings.completed,
                value: _learningMetrics['completed'] ?? '0',
                icon: Icons.check_circle,
                iconColor: themeService.getColor('success'),
              ),
              themeService.buildMetricCard(
                title: AppStrings.activeCourses,
                value: _learningMetrics['activeCourses'] ?? '0',
                icon: Icons.play_circle,
                iconColor: themeService.getColor('warning'),
              ),
              themeService.buildMetricCard(
                title: AppStrings.notStarted,
                value: _learningMetrics['notStarted'] ?? '0',
                icon: Icons.schedule,
                iconColor: themeService.getColor('textMuted'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        themeService.buildSectionHeader(title: AppStrings.quickActions),
        SizedBox(height: themeService.getSpacing('md')),
        Container(
          margin:
              EdgeInsets.symmetric(horizontal: themeService.getSpacing('md')),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: themeService.getSpacing('sm'),
              mainAxisSpacing: themeService.getSpacing('sm'),
              childAspectRatio: 0.9,
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
                      padding: EdgeInsets.all(themeService.getSpacing('md')),
                      decoration: BoxDecoration(
                        color: action.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          themeService.getBorderRadius('large'),
                        ),
                      ),
                      child: Icon(
                        _getActionIcon(action.icon),
                        color: action.color,
                        size: 28,
                      ),
                    ),
                    SizedBox(height: themeService.getSpacing('sm')),
                    Text(
                      action.title,
                      style: textTheme.bodySmall,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getActionIcon(String iconKey) {
    const Map<String, IconData> iconMap = {
      'quiz': Icons.quiz,
      'certificate': Icons.workspace_premium,
      'discussions': Icons.forum,
      'assignments': Icons.assignment,
    };

    return iconMap[iconKey] ?? Icons.help_outline;
  }

  Widget _buildMyCoursesSection() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        themeService.buildSectionHeader(
          title: AppStrings.myCourses,
          actionText: AppStrings.viewAll,
          onActionTap: () => _navigateToScreen(
            CourseCatalogScreen(token: widget.token),
            'Course Catalog',
          ),
        ),
        SizedBox(height: themeService.getSpacing('md')),
        if (_isCoursesLoading)
          Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                    color: themeService.getColor('primary')),
                SizedBox(height: themeService.getSpacing('sm')),
                Text(AppStrings.loadingCourses, style: textTheme.bodyMedium),
              ],
            ),
          )
        else if (_myCourses.isEmpty)
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: themeService.getSpacing('md')),
            child: themeService.buildCleanCard(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(themeService.getSpacing('md')),
                    decoration: BoxDecoration(
                      color: themeService.getColor('primary').withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school,
                      size: 40,
                      color: themeService.getColor('primary'),
                    ),
                  ),
                  SizedBox(height: themeService.getSpacing('md')),
                  Text(
                    AppStrings.noCoursesEnrolled,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: themeService.getSpacing('xs')),
                  Text(
                    AppStrings.exploreCatalog,
                    style: textTheme.bodySmall?.copyWith(
                        color: themeService.getColor('textSecondary')),
                  ),
                  SizedBox(height: themeService.getSpacing('md')),
                  ElevatedButton(
                    onPressed: () => _navigateToScreen(
                      CourseCatalogScreen(token: widget.token),
                      'Course Catalog',
                    ),
                    child: const Text(AppStrings.browseCourses),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                  horizontal: themeService.getSpacing('md')),
              itemCount: _myCourses.take(10).length,
              itemBuilder: (context, index) {
                final course = _myCourses[index];
                return Container(
                  width: 280,
                  margin: EdgeInsets.only(
                    right: themeService.getSpacing('sm'),
                  ),
                  child: themeService.buildCleanCard(
                    onTap: () => _navigateToCourse(course),
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(
                                  themeService.getBorderRadius('large')),
                              topRight: Radius.circular(
                                  themeService.getBorderRadius('large')),
                            ),
                          ),
                          child: course.courseimage.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(
                                        themeService.getBorderRadius('large')),
                                    topRight: Radius.circular(
                                        themeService.getBorderRadius('large')),
                                  ),
                                  child: Image.network(
                                    course.courseimage,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Center(
                                      child: Icon(
                                        Icons.school,
                                        color: themeService.getColor('primary'),
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.school,
                                    color: themeService.getColor('primary'),
                                    size: 40,
                                  ),
                                ),
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                                EdgeInsets.all(themeService.getSpacing('sm')),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.fullname,
                                  style: textTheme.titleMedium?.copyWith(
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
                                        '${course.progress!.toStringAsFixed(0)}% complete',
                                        style: textTheme.bodySmall?.copyWith(
                                            color: themeService
                                                .getColor('textSecondary')),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                      height: themeService.getSpacing('xs')),
                                  LinearProgressIndicator(
                                    value: course.progress! / 100,
                                    backgroundColor:
                                        themeService.getColor('borderLight'),
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      _getProgressColor(course.progress!),
                                    ),
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(
                                      themeService.getBorderRadius('small'),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildUpcomingEventsSection() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        themeService.buildSectionHeader(title: AppStrings.upcomingEvents),
        SizedBox(height: themeService.getSpacing('md')),
        if (_isEventsLoading)
          Center(
            child: CircularProgressIndicator(
                color: themeService.getColor('primary')),
          )
        else if (_upcomingEvents.isEmpty)
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: themeService.getSpacing('md')),
            child: themeService.buildCleanCard(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(themeService.getSpacing('sm')),
                    decoration: BoxDecoration(
                      color: themeService.getColor('warning').withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event,
                      size: 32,
                      color: themeService.getColor('warning'),
                    ),
                  ),
                  SizedBox(height: themeService.getSpacing('md')),
                  Text(
                    AppStrings.noUpcomingEvents,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: themeService.getSpacing('md')),
            child: Column(
              children: _upcomingEvents
                  .take(3)
                  .map((event) => Padding(
                        padding: EdgeInsets.only(
                            bottom: themeService.getSpacing('xs')),
                        child: themeService.buildCleanCard(
                          padding: EdgeInsets.all(themeService.getSpacing('sm')),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(
                                    themeService.getSpacing('sm')),
                                decoration: BoxDecoration(
                                  color: themeService
                                      .getColor('warning')
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      themeService.getBorderRadius('medium')),
                                ),
                                child: Icon(
                                  Icons.event_available,
                                  color: themeService.getColor('warning'),
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: themeService.getSpacing('sm')),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (event.subtitle.isNotEmpty)
                                      Text(
                                        event.subtitle,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: themeService
                                              .getColor('textSecondary'),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    event.formattedDate,
                                    style: textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          themeService.getColor('textPrimary'),
                                    ),
                                  ),
                                  Text(
                                    event.formattedTime,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: themeService
                                          .getColor('textSecondary'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildCleanDrawer() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      backgroundColor: themeService.getColor('backgroundLight'),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              themeService.getSpacing('lg'),
              themeService.getSpacing('lg') + MediaQuery.of(context).padding.top,
              themeService.getSpacing('lg'),
              themeService.getSpacing('lg')),
            decoration: BoxDecoration(
              color: themeService.getColor('primary'),
            ),
            child: _isUserLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: themeService.getColor('onPrimary'),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: themeService
                                .getColor('onPrimary')
                                .withOpacity(0.2),
                            border: Border.all(
                              color: themeService.getColor('onPrimary'),
                              width: 2,
                            ),
                          ),
                          child: _userInfo?['userpictureurl'] != null
                              ? ClipOval(
                                  child: Image.network(
                                    _userInfo!['userpictureurl'],
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                      Icons.person,
                                      color: themeService.getColor('onPrimary'),
                                      size: 30,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: themeService.getColor('onPrimary'),
                                  size: 30,
                                ),
                        ),
                        SizedBox(height: themeService.getSpacing('md')),
                        Text(
                          _userInfo?['fullname'] ?? 'User',
                          style: textTheme.titleLarge?.copyWith(
                            color: themeService.getColor('onPrimary'),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: themeService.getSpacing('xs')),
                        Text(
                          _userInfo?['email'] ?? 'user@email.com',
                          style: textTheme.bodyMedium?.copyWith(
                            color: themeService
                                .getColor('onPrimary')
                                .withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
          ),
          Expanded(
            child: ListView(
              padding:
                  EdgeInsets.symmetric(vertical: themeService.getSpacing('md')),
              children: [
                ..._drawerItems.map((item) {
                  return Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: themeService.getSpacing('md'),
                      vertical: themeService.getSpacing('xs') / 2,
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(themeService.getSpacing('xs')),
                        decoration: BoxDecoration(
                          color:
                              themeService.getColor('primary').withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                              themeService.getBorderRadius('small')),
                        ),
                        child: Icon(
                          _getDrawerIcon(item.type),
                          color: themeService.getColor('primary'),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: textTheme.bodyLarge?.copyWith(
                          color: themeService.getColor('textPrimary'),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () => _navigateTo(item.type),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            themeService.getBorderRadius('medium')),
                      ),
                    ),
                  );
                }).toList(),
                SizedBox(height: themeService.getSpacing('md')),
                Container(
                  margin: EdgeInsets.symmetric(
                      horizontal: themeService.getSpacing('md')),
                  child: ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(themeService.getSpacing('xs')),
                      decoration: BoxDecoration(
                        color: themeService.getColor('error').withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                            themeService.getBorderRadius('small')),
                      ),
                      child: Icon(
                        Icons.logout,
                        color: themeService.getColor('error'),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      AppStrings.logout,
                      style: textTheme.bodyLarge?.copyWith(
                        color: themeService.getColor('error'),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: _logout,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          themeService.getBorderRadius('medium')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final themeService = DynamicThemeService.instance;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: themeService.getSpacing('sm')),
          if (!_isUserLoading) _buildWelcomeSection(),
          SizedBox(height: themeService.getSpacing('sm')),
          _buildContinueLearningWidget(),
          SizedBox(height: themeService.getSpacing('lg')),
          _buildLearningMetrics(),
          SizedBox(height: themeService.getSpacing('lg')),
          _buildQuickActions(),
          SizedBox(height: themeService.getSpacing('lg')),
          _buildMyCoursesSection(),
          SizedBox(height: themeService.getSpacing('lg')),
          _buildUpcomingEventsSection(),
          SizedBox(height: themeService.getSpacing('xl')),
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
        title: Text(DynamicThemeService.instance.siteName ?? AppStrings.dashboard),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: themeService.getColor('textPrimary'),
            ),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildCleanDrawer(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _fetchAllData,
          color: themeService.getColor('primary'),
          backgroundColor: themeService.getColor('backgroundLight'),
          child: _buildMainContent(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToScreen(
          ChatListScreen(token: widget.token),
          'Chat',
        ),
        backgroundColor: themeService.getColor('primary'),
        child: Icon(
          Icons.chat_bubble,
          color: themeService.getColor('onPrimary'),
        ),
      ),
    );
  }
}
