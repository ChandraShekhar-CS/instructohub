import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:InstructoHub/models/course_model.dart';
import 'package:InstructoHub/services/api_service.dart';
import 'package:InstructoHub/services/enhanced_icon_service.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';

import 'my_courses_screen.dart';
import 'course_catalog.dart';
import 'course_detail_screen.dart';
import 'package:InstructoHub/features/messaging/screens/chat_list_screen.dart';
import 'package:InstructoHub/screens/domain_config/domain_config_screen.dart';
import 'downloaded_courses_screen.dart';


class AppStrings {
  static const String dashboard = 'Dashboard';
  static const String goodMorning = 'Good morning';
  static const String goodAfternoon = 'Good afternoon';
  static const String goodEvening = 'Good evening';
  static const String readyToContinue =
      'Ready to continue your learning journey?';
  static const String yourLearningMetrics = 'Your Learning Metrics';
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
  static const String activeCourses = 'In Progress';
  static const String completed = 'Completed';
  static const String overallProgress = 'Overall Progress';
  static const String loadingCourses = 'Loading courses...';
  static const String loadingMetrics = 'Loading metrics...';
  static const String loadingEvents = 'Loading events...';
  static const String downloadedCourses = 'Downloaded Courses';
  static const String courses = 'Courses';
  static const String account = 'Account';
  static const String catalog = 'Catalog';
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

  int _currentIndex = 0;
  late PageController _pageController;

  // Teacher-specific variables
  bool _isTeacher = false;
  bool _isCheckingRole = true;
  Map<String, dynamic> _teacherMetrics = {};
  List<dynamic> _teachingCourses = [];
  List<dynamic> _pendingAssignments = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    DynamicThemeService.instance.addListener(_onThemeChanged);

    _initializeServices();
    _checkUserRole();
    _fetchAllData();
    _animationController.forward();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeServices() async {
    try {
      await DynamicIconService.instance.loadIcons(token: widget.token);
    } catch (e) {}
  }

  Future<void> _checkUserRole() async {
    try {
      final isTeacher = await ApiService.instance.isTeacher(widget.token);
      if (mounted) {
        setState(() {
          _isTeacher = isTeacher;
          _isCheckingRole = false;
        });

        if (_isTeacher) {
          _fetchTeacherData();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTeacher = false;
          _isCheckingRole = false;
        });
      }
    }
  }

  Future<void> _fetchTeacherData() async {
    try {
      final results = await Future.wait([
        _fetchTeachingCourses(),
        _fetchPendingAssignments(),
        _fetchTeacherMetrics(),
      ]);
    } catch (e) {}
  }

  Future<void> _fetchTeachingCourses() async {
    try {
      final teachingCourses =
          await ApiService.instance.getTeachingCourses(widget.token);

      if (mounted) {
        setState(() {
          _teachingCourses = teachingCourses;
        });
      }
    } catch (e) {}
  }

  Future<void> _fetchPendingAssignments() async {
    try {
      final pendingAssignments =
          await ApiService.instance.getPendingAssignments(widget.token);

      if (mounted) {
        setState(() {
          _pendingAssignments = pendingAssignments;
        });
      }
    } catch (e) {}
  }

  Future<void> _fetchTeacherMetrics() async {
    try {
      final metrics = await ApiService.instance.getTeacherMetrics(widget.token);

      if (mounted) {
        setState(() {
          _teacherMetrics = metrics;
        });
      }
    } catch (e) {
      setState(() {
        _teacherMetrics = {
          'coursesTaught': _teachingCourses.length,
          'totalStudents': _teachingCourses.fold(
              0,
              (sum, course) =>
                  sum + ((course['enrolleduserscount'] ?? 0) as int)),
          'pendingGrading': _pendingAssignments.length,
          'avgCourseCompletion': 0.0,
        };
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
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
          } catch (e) {}
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

  void _navigateToMyCoursesWithFilter(CourseFilter filter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyCoursesScreen(
          token: widget.token,
          initialFilter: filter,
        ),
      ),
    );
  }

  Future<void> _saveLastViewedCourse(Course course) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastViewedCourse', json.encode(course.toJson()));
    } catch (e) {}
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

  Widget _buildTeacherMetrics() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        themeService.buildSectionHeader(title: 'Teaching Overview'),
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
                title: 'Courses Teaching',
                value: _teacherMetrics['coursesTaught']?.toString() ?? '0',
                icon: Icons.school,
                iconColor: themeService.getColor('primary'),
              ),
              themeService.buildMetricCard(
                title: 'Total Students',
                value: _teacherMetrics['totalStudents']?.toString() ?? '0',
                icon: Icons.people,
                iconColor: themeService.getColor('info'),
              ),
              themeService.buildMetricCard(
                title: 'Pending Grading',
                value: _teacherMetrics['pendingGrading']?.toString() ?? '0',
                icon: Icons.assignment_late,
                iconColor: themeService.getColor('warning'),
              ),
              themeService.buildMetricCard(
                title: 'Avg Completion',
                value:
                    '${(_teacherMetrics['avgCourseCompletion'] ?? 0.0).toStringAsFixed(0)}%',
                icon: Icons.trending_up,
                iconColor: themeService.getColor('success'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeachingCoursesSection() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        themeService.buildSectionHeader(
          title: 'My Teaching Courses',
          actionText: 'Manage All',
          onActionTap: () => _showComingSoon('Course Management'),
        ),
        SizedBox(height: themeService.getSpacing('md')),
        if (_teachingCourses.isEmpty)
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: themeService.getSpacing('md')),
            child: themeService.buildCleanCard(
              child: Column(
                children: [
                  Icon(
                    Icons.school,
                    size: 48,
                    color: themeService.getColor('textSecondary'),
                  ),
                  SizedBox(height: themeService.getSpacing('md')),
                  Text(
                    'No Teaching Courses',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: themeService.getSpacing('xs')),
                  Text(
                    'Contact admin to get teaching access',
                    style: textTheme.bodySmall?.copyWith(
                      color: themeService.getColor('textSecondary'),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                  horizontal: themeService.getSpacing('md')),
              itemCount: _teachingCourses.length,
              itemBuilder: (context, index) {
                final course = _teachingCourses[index];
                return Container(
                  width: 300,
                  margin: EdgeInsets.only(right: themeService.getSpacing('sm')),
                  child: themeService.buildCleanCard(
                    onTap: () => _navigateToTeacherCourse(course),
                    child: Padding(
                      padding: EdgeInsets.all(themeService.getSpacing('sm')),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  course['fullname'] ?? 'Course',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(
                                    themeService.getSpacing('xs')),
                                decoration: BoxDecoration(
                                  color: themeService
                                      .getColor('primary')
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    themeService.getBorderRadius('small'),
                                  ),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: themeService.getColor('primary'),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: themeService.getSpacing('sm')),
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 16,
                                color: themeService.getColor('textSecondary'),
                              ),
                              SizedBox(width: themeService.getSpacing('xs')),
                              Text(
                                '${course['enrolleduserscount'] ?? 0} students',
                                style: textTheme.bodySmall?.copyWith(
                                  color: themeService.getColor('textSecondary'),
                                ),
                              ),
                              Spacer(),
                              if (course['pendingassignments'] != null &&
                                  course['pendingassignments'] > 0)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: themeService.getSpacing('sm'),
                                    vertical: themeService.getSpacing('xs'),
                                  ),
                                  decoration: BoxDecoration(
                                    color: themeService
                                        .getColor('warning')
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      themeService.getBorderRadius('small'),
                                    ),
                                  ),
                                  child: Text(
                                    '${course['pendingassignments']} to grade',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: themeService.getColor('warning'),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
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
    );
  }

  Widget _buildTeacherQuickActions() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    final teacherActions = [
      {
        'title': 'Create Course',
        'icon': Icons.add_circle,
        'color': themeService.getColor('success'),
        'onTap': () => _showComingSoon('Create Course'),
      },
      {
        'title': 'Grade Assignments',
        'icon': Icons.assignment_turned_in,
        'color': themeService.getColor('warning'),
        'onTap': () => _showComingSoon('Grade Assignments'),
      },
      {
        'title': 'Student Reports',
        'icon': Icons.analytics,
        'color': themeService.getColor('info'),
        'onTap': () => _showComingSoon('Student Reports'),
      },
      {
        'title': 'Live Session',
        'icon': Icons.videocam,
        'color': themeService.getColor('primary'),
        'onTap': () => _showComingSoon('Live Session'),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        themeService.buildSectionHeader(title: 'Teacher Tools'),
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
            itemCount: teacherActions.length,
            itemBuilder: (context, index) {
              final action = teacherActions[index];
              return GestureDetector(
                onTap: action['onTap'] as VoidCallback,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(themeService.getSpacing('md')),
                      decoration: BoxDecoration(
                        color: (action['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          themeService.getBorderRadius('large'),
                        ),
                      ),
                      child: Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 28,
                      ),
                    ),
                    SizedBox(height: themeService.getSpacing('sm')),
                    Text(
                      action['title'] as String,
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

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
        onTap: () => _onBottomNavTap(1),
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

    final double progress = (_learningMetrics['overallProgress'] ?? 0.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        themeService.buildSectionHeader(title: AppStrings.yourLearningMetrics),
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
               GestureDetector(
                onTap: () => _navigateToMyCoursesWithFilter(CourseFilter.all),
                child: themeService.buildMetricCard(
                  title: AppStrings.totalCourses,
                  value: _learningMetrics['totalCourses'] ?? '0',
                  icon: Icons.book,
                  iconColor: themeService.getColor('info'),
                ),
              ),
              GestureDetector(
                onTap: () => _navigateToMyCoursesWithFilter(CourseFilter.notStarted),
                child: themeService.buildMetricCard(
                  title: AppStrings.notStarted,
                  value: _learningMetrics['notStarted'] ?? '0',
                  icon: Icons.schedule,
                  iconColor: themeService.getColor('textMuted'),
                ),
              ),
               GestureDetector(
                onTap: () => _navigateToMyCoursesWithFilter(CourseFilter.inProgress),
                child: themeService.buildMetricCard(
                  title: AppStrings.activeCourses,
                  value: _learningMetrics['activeCourses'] ?? '0',
                  icon: Icons.play_circle,
                  iconColor: themeService.getColor('warning'),
                ),
              ),
              GestureDetector(
                onTap: () => _navigateToMyCoursesWithFilter(CourseFilter.completed),
                child: themeService.buildMetricCard(
                  title: AppStrings.completed,
                  value: _learningMetrics['completed'] ?? '0',
                  icon: Icons.check_circle,
                  iconColor: themeService.getColor('success'),
                ),
              ),
             
              
            ],
          ),
        ),
        SizedBox(height: themeService.getSpacing('md')),
        Container(
          margin:
              EdgeInsets.symmetric(horizontal: themeService.getSpacing('md')),
          child: themeService.buildCleanCard(
            padding: EdgeInsets.all(themeService.getSpacing('lg')),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.overallProgress,
                      style: textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: themeService.getSpacing('md'),
                        vertical: themeService.getSpacing('sm'),
                      ),
                      decoration: BoxDecoration(
                        color: _getProgressColor(progress).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                            themeService.getBorderRadius('large')),
                      ),
                      child: Text(
                        '${progress.toStringAsFixed(0)}%',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _getProgressColor(progress),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: themeService.getSpacing('lg')),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                      themeService.getBorderRadius('large')),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 12,
                    backgroundColor: themeService.getColor('borderLight'),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(progress)),
                  ),
                ),
                SizedBox(height: themeService.getSpacing('md')),
                Text(
                  _getProgressText(progress),
                  style: textTheme.bodyMedium?.copyWith(
                    color: themeService.getColor('textSecondary'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getProgressText(double progress) {
    if (progress >= 100) {
      return 'Congratulations! You\'ve completed all your courses.';
    } else if (progress >= 75) {
      return 'You\'re almost there! Keep up the great work.';
    } else if (progress >= 50) {
      return 'Great progress! You\'re halfway through your learning journey.';
    } else if (progress >= 25) {
      return 'Good start! Continue learning to reach your goals.';
    } else if (progress > 0) {
      return 'You\'ve started your learning journey. Keep going!';
    } else {
      return 'Start your learning journey by enrolling in courses.';
    }
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
          onActionTap: () => _navigateToMyCoursesWithFilter(CourseFilter.all),
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
                    onPressed: () => _onBottomNavTap(1),
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
                  margin: EdgeInsets.only(right: themeService.getSpacing('sm')),
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
                                  style: textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        _getProgressColor(course.progress!)),
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(
                                        themeService.getBorderRadius('small')),
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
                          padding:
                              EdgeInsets.all(themeService.getSpacing('sm')),
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
                                          fontWeight: FontWeight.w600),
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

  Widget _buildDashboardContent() {
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
          if (_isTeacher && !_isCheckingRole) ...[
            _buildTeacherMetrics(),
            SizedBox(height: themeService.getSpacing('lg')),
            _buildTeacherQuickActions(),
            SizedBox(height: themeService.getSpacing('lg')),
            _buildTeachingCoursesSection(),
            SizedBox(height: themeService.getSpacing('lg')),
          ],
          _buildLearningMetrics(),
          SizedBox(height: themeService.getSpacing('lg')),
          _buildMyCoursesSection(),
          SizedBox(height: themeService.getSpacing('lg')),
          _buildUpcomingEventsSection(),
          SizedBox(height: themeService.getSpacing('xl')),
        ],
      ),
    );
  }

  void _navigateToTeacherCourse(dynamic course) {
    _showComingSoon('Teacher Course Management');
  }

  Widget _buildCoursesContent() {
    return CourseCatalogScreen(token: widget.token);
  }

  Widget _buildDownloadedCoursesContent() {
    return DownloadedCoursesScreen(token: widget.token);
  }

  Widget _buildAccountContent() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: EdgeInsets.all(themeService.getSpacing('md')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isUserLoading) ...[
            themeService.buildCleanCard(
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: themeService.getColor('primary').withOpacity(0.1),
                      border: Border.all(
                        color: themeService.getColor('primary'),
                        width: 2,
                      ),
                    ),
                    child: _userInfo?['userpictureurl'] != null
                        ? ClipOval(
                            child: Image.network(
                              _userInfo!['userpictureurl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                Icons.person,
                                color: themeService.getColor('primary'),
                                size: 30,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            color: themeService.getColor('primary'),
                            size: 30,
                          ),
                  ),
                  SizedBox(width: themeService.getSpacing('md')),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userInfo?['fullname'] ?? 'User',
                          style: textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: themeService.getSpacing('xs')),
                        Text(
                          _userInfo?['email'] ?? 'user@email.com',
                          style: textTheme.bodyMedium?.copyWith(
                            color: themeService.getColor('textSecondary'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: themeService.getSpacing('lg')),
          ],
          Text(
            'Account Settings',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: themeService.getSpacing('md')),
          _buildAccountOption(
            icon: Icons.person_outline,
            title: 'Profile Settings',
            subtitle: 'Manage your personal information',
            onTap: () => _showComingSoon('Profile Settings'),
          ),
          _buildAccountOption(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Configure notification preferences',
            onTap: () => _showComingSoon('Notifications'),
          ),
          _buildAccountOption(
            icon: Icons.security_outlined,
            title: 'Privacy & Security',
            subtitle: 'Password and security settings',
            onTap: () => _showComingSoon('Privacy & Security'),
          ),
          _buildAccountOption(
            icon: Icons.language_outlined,
            title: 'Language & Region',
            subtitle: 'Set your preferred language',
            onTap: () => _showComingSoon('Language & Region'),
          ),
          _buildAccountOption(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () => _showComingSoon('Help & Support'),
          ),
          _buildAccountOption(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () => _showComingSoon('About'),
          ),
          SizedBox(height: themeService.getSpacing('lg')),
          themeService.buildCleanCard(
            backgroundColor: themeService.getColor('error').withOpacity(0.05),
            onTap: _showLogoutConfirmation,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(themeService.getSpacing('sm')),
                  decoration: BoxDecoration(
                    color: themeService.getColor('error').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                        themeService.getBorderRadius('medium')),
                  ),
                  child: Icon(
                    Icons.logout,
                    color: themeService.getColor('error'),
                    size: 20,
                  ),
                ),
                SizedBox(width: themeService.getSpacing('md')),
                Expanded(
                  child: Text(
                    AppStrings.logout,
                    style: textTheme.titleMedium?.copyWith(
                      color: themeService.getColor('error'),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: themeService.getColor('error'),
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.only(bottom: themeService.getSpacing('sm')),
      child: themeService.buildCleanCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(themeService.getSpacing('sm')),
              decoration: BoxDecoration(
                color: themeService.getColor('primary').withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                    themeService.getBorderRadius('medium')),
              ),
              child: Icon(
                icon,
                color: themeService.getColor('primary'),
                size: 20,
              ),
            ),
            SizedBox(width: themeService.getSpacing('md')),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: themeService.getSpacing('xs') / 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: themeService.getColor('textSecondary'),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: themeService.getColor('textSecondary'),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(feature),
          content: Text('$feature feature is coming soon!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return AppStrings.dashboard;
      case 1:
        return AppStrings.catalog;
      case 2:
        return AppStrings.downloadedCourses;
      case 3:
        return AppStrings.account;
      default:
        return AppStrings.dashboard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.instance;

    return Scaffold(
      backgroundColor: themeService.getColor('background'),
      appBar: _currentIndex == 0
          ? AppBar(
              title: Text(DynamicThemeService.instance.siteName ??
                  AppStrings.dashboard),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: themeService.getColor('textPrimary'),
                  ),
                  onPressed: () => _showComingSoon('Notifications'),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    color: themeService.getColor('textPrimary'),
                  ),
                  onPressed: () => _navigateToScreen(
                    ChatListScreen(token: widget.token),
                    'Chat',
                  ),
                ),
              ],
            )
          : AppBar(
              title: Text(_getAppBarTitle()),
              automaticallyImplyLeading: false,
            ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            RefreshIndicator(
              onRefresh: _fetchAllData,
              color: themeService.getColor('primary'),
              backgroundColor: themeService.getColor('backgroundLight'),
              child: _buildDashboardContent(),
            ),
            _buildCoursesContent(),
            _buildDownloadedCoursesContent(),
            _buildAccountContent(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        selectedItemColor: themeService.getColor('primary'),
        unselectedItemColor: themeService.getColor('textSecondary'),
        backgroundColor: themeService.getColor('backgroundLight'),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: AppStrings.dashboard,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: AppStrings.catalog,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download_outlined),
            activeIcon: Icon(Icons.download),
            label: AppStrings.downloadedCourses,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: AppStrings.account,
          ),
        ],
      ),
    );
  }
}
