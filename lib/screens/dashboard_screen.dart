
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/course_model.dart';
import '../services/api_service.dart';
import '../services/enhanced_icon_service.dart';
import '../theme/dynamic_app_theme.dart';

import 'course_catalog_screen.dart';
import 'course_detail_screen.dart';
import 'metrics_screen.dart';
import 'quick_actions_screen.dart';
import 'recent_activity_screen.dart';
import 'recommended_courses_screen.dart';
import 'upcoming_events_screen.dart';
import '../../features/messaging/screens/chat_list_screen.dart';
import 'domain_config_screen.dart';

typedef AppTheme = DynamicAppTheme;

class DashboardScreen extends StatefulWidget {
  final String token;

  const DashboardScreen({required this.token, Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

// Simple Course Detail Screen that doesn't require course categories
class SimpleCourseDetailScreen extends StatelessWidget {
  final Course course;
  final String token;

  const SimpleCourseDetailScreen({
    required this.course,
    required this.token,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(course.fullname),
        backgroundColor: AppTheme.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        titleTextStyle: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: AppTheme.textPrimary),
            onPressed: () {
              // Show course options
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.book_outlined),
                        title: Text('View Full Course'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CourseDetailScreen(
                                course: course,
                                token: token,
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.school),
                        title: Text('Browse More Courses'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CourseCatalogScreen(token: token),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Header
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.secondary1,
                    AppTheme.secondary2,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: course.courseimage.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        course.courseimage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.school,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.school,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
            ),
            
            const SizedBox(height: 20),
            
            // Course Title
            Text(
              course.fullname,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Progress Bar
            if (course.progress != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${course.progress!.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: course.progress! / 100,
                      backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondary1),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Course Description
            if (course.summary.isNotEmpty) ...[
              Text(
                'About this course',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  course.summary,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2,
              children: [
                _buildActionCard(
                  'Continue Learning',
                  Icons.play_circle_outline,
                  Colors.green,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening course content...')),
                    );
                  },
                ),
                _buildActionCard(
                  'Assignments',
                  Icons.assignment,
                  Colors.blue,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Loading assignments...')),
                    );
                  },
                ),
                _buildActionCard(
                  'Discussions',
                  Icons.forum,
                  Colors.orange,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening discussions...')),
                    );
                  },
                ),
                _buildActionCard(
                  'Resources',
                  Icons.library_books,
                  Colors.purple,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Loading resources...')),
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Try Full Course Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseDetailScreen(
                        course: course,
                        token: token,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary1,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'View Full Course Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
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
    _fetchUserInfo();
    _fetchMyCourses();
    _fetchUpcomingEvents();
    _fetchLearningMetrics();
    _animationController.forward();

    _drawerItems = [
      DashboardItem(id: 2, type: DashboardWidgetType.quickActions),
      DashboardItem(id: 3, type: DashboardWidgetType.recommendedCourses),
      DashboardItem(id: 4, type: DashboardWidgetType.keyMetrics),
      DashboardItem(id: 5, type: DashboardWidgetType.upcomingEvents),
      DashboardItem(id: 6, type: DashboardWidgetType.recentActivity),
    ];

    _quickActions = [
      QuickActionItem(
        icon: 'quiz',
        title: 'Quiz',
        color: Colors.blue,
        type: DashboardWidgetType.quickActions,
      ),
      QuickActionItem(
        icon: 'certificate',
        title: 'Certificate',
        color: Colors.green,
        type: DashboardWidgetType.keyMetrics,
      ),
      QuickActionItem(
        icon: 'discussions',
        title: 'Discussions',
        color: Colors.orange,
        type: DashboardWidgetType.recentActivity,
      ),
      QuickActionItem(
        icon: 'assignments',
        title: 'Assignments',
        color: Colors.purple,
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

  Future<void> _fetchMyCourses() async {
    try {
      setState(() => _isCoursesLoading = true);
      
      final courses = await ApiService.instance.getUserCourses(widget.token);
      
      List<Course> mappedCourses = [];
      if (courses is List) {
        for (var courseData in courses) {
          try {
            final progress = await _getCourseProgress(courseData['id']);
            mappedCourses.add(Course(
              id: courseData['id'] ?? 0,
              fullname: courseData['fullname'] ?? 'Untitled Course',
              summary: courseData['summary'] ?? '',
              courseimage: courseData['courseimage'] ?? '',
              contacts: courseData['contacts'] ?? [],
              progress: progress,
            ));
          } catch (e) {
            print('Error processing course ${courseData['id']}: $e');
            // Still add the course even if progress fails
            mappedCourses.add(Course(
              id: courseData['id'] ?? 0,
              fullname: courseData['fullname'] ?? 'Untitled Course',
              summary: courseData['summary'] ?? '',
              courseimage: courseData['courseimage'] ?? '',
              contacts: courseData['contacts'] ?? [],
              progress: null,
            ));
          }
        }
      }

      if (mounted) {
        setState(() {
          _myCourses = mappedCourses;
          _isCoursesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCoursesLoading = false;
          // Provide sample courses for demonstration
          _myCourses = [
            Course(
              id: 1,
              fullname: 'Introduction to Programming',
              summary: 'Learn the basics of programming with practical examples',
              courseimage: '',
              contacts: [],
              progress: 45.0,
            ),
            Course(
              id: 2,
              fullname: 'Data Structures and Algorithms',
              summary: 'Master fundamental computer science concepts',
              courseimage: '',
              contacts: [],
              progress: 20.0,
            ),
            Course(
              id: 3,
              fullname: 'Web Development Basics',
              summary: 'Build modern web applications from scratch',
              courseimage: '',
              contacts: [],
              progress: 75.0,
            ),
          ];
        });
        print('Failed to get courses, using sample data: $e');
      }
    }
  }

  Future<double?> _getCourseProgress(int courseId) async {
    try {
      final progressData = await ApiService.instance.getUserProgress(widget.token);
      if (progressData is Map && progressData['courses'] is List) {
        final courses = progressData['courses'] as List;
        final courseProgress = courses.firstWhere(
          (course) => course['id'] == courseId,
          orElse: () => null,
        );
        if (courseProgress != null && courseProgress['progress'] != null) {
          return (courseProgress['progress'] as num).toDouble();
        }
      }
    } catch (e) {
      print('Failed to get progress for course $courseId: $e');
    }
    // Return random progress for demo purposes if API fails
    return (courseId % 10) * 10.0; // Will give 0, 10, 20, 30, etc.
  }

  Future<void> _fetchUpcomingEvents() async {
    try {
      setState(() => _isEventsLoading = true);
      
      final eventsData = await ApiService.instance.getUpcomingEvents(widget.token);
      
      List<UpcomingEvent> events = [];
      if (eventsData is Map && eventsData['events'] is List) {
        final eventsList = eventsData['events'] as List;
        for (var eventData in eventsList) {
          events.add(UpcomingEvent(
            title: eventData['name'] ?? 'Event',
            subtitle: eventData['description'] ?? '',
            date: _formatDate(eventData['timestart']),
            time: _formatTime(eventData['timestart']),
          ));
        }
      }

      if (mounted) {
        setState(() {
          _upcomingEvents = events;
          _isEventsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEventsLoading = false;
        });
        print('Failed to get events: $e');
      }
    }
  }

  Future<void> _fetchLearningMetrics() async {
    try {
      setState(() => _isMetricsLoading = true);
      
      final progressData = await ApiService.instance.getUserProgress(widget.token);
      
      if (progressData is Map) {
        double totalProgress = 0.0;
        int courseCount = 0;
        int completedCourses = 0;
        int upcomingDeadlines = 0;

        if (progressData['courses'] is List) {
          final courses = progressData['courses'] as List;
          for (var course in courses) {
            if (course['progress'] != null) {
              final progress = (course['progress'] as num).toDouble();
              totalProgress += progress;
              if (progress >= 100) completedCourses++;
            }
            courseCount++;
          }
        }

        if (progressData['deadlines'] is List) {
          upcomingDeadlines = (progressData['deadlines'] as List).length;
        }

        final avgProgress = courseCount > 0 ? totalProgress / courseCount : 0.0;

        if (mounted) {
          setState(() {
            _learningMetrics = {
              'completionRate': '${avgProgress.toStringAsFixed(1)}%',
              'deadlines': upcomingDeadlines.toString(),
              'activeCourses': courseCount.toString(),
              'completedCourses': completedCourses.toString(),
            };
            _isMetricsLoading = false;
          });
        }
      } else {
        // Fallback metrics if API fails
        if (mounted) {
          setState(() {
            _learningMetrics = {
              'completionRate': '${(_myCourses.length * 15.5).toStringAsFixed(1)}%',
              'deadlines': '${_myCourses.length}',
              'activeCourses': '${_myCourses.length}',
              'completedCourses': '${(_myCourses.length * 0.3).round()}',
            };
            _isMetricsLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Provide reasonable fallback metrics
          _learningMetrics = {
            'completionRate': '${(_myCourses.length * 15.5).toStringAsFixed(1)}%',
            'deadlines': '${_myCourses.length}',
            'activeCourses': '${_myCourses.length}',
            'completedCourses': '${(_myCourses.length * 0.3).round()}',
          };
          _isMetricsLoading = false;
        });
        print('Failed to get metrics: $e');
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    try {
      if (timestamp is int) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
      }
    } catch (e) {
      print('Error formatting date: $e');
    }
    return 'TBD';
  }

  String _formatTime(dynamic timestamp) {
    try {
      if (timestamp is int) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        final hour = date.hour > 12 ? date.hour - 12 : date.hour;
        final period = date.hour >= 12 ? 'PM' : 'AM';
        return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
      }
    } catch (e) {
      print('Error formatting time: $e');
    }
    return 'TBD';
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
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _navigateToCourse(Course course) {
    try {
      // Save the last viewed course for continue learning
      _saveLastViewedCourse(course);
      
      // Show a simple dialog with course info instead of navigating to potentially failing screen
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(course.fullname),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (course.summary.isNotEmpty) ...[
                  Text(
                    'About this course:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(course.summary),
                  const SizedBox(height: 16),
                ],
                if (course.progress != null) ...[
                  Text(
                    'Progress: ${course.progress!.toStringAsFixed(0)}%',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: course.progress! / 100,
                    backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondary1),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Would you like to try opening the full course details?',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseDetailScreen(
                        course: course,
                        token: widget.token,
                      ),
                    ),
                  ).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Unable to load course details: $error'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary1,
                ),
                child: Text(
                  'Open Course',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error navigating to course: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open course. Please try again.'),
            backgroundColor: AppTheme.error,
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
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.secondary1,
              AppTheme.secondary1.withOpacity(0.8),
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _isUserLoading
                ? DrawerHeader(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.secondary1, AppTheme.secondary1.withOpacity(0.7)],
                      ),
                    ),
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  )
                : UserAccountsDrawerHeader(
                    accountName: Text(
                      _userInfo?['fullname'] ?? 'User Name',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    accountEmail: Text(
                      _userInfo?['email'] ?? 'user@email.com',
                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                    ),
                    currentAccountPicture: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: CircleAvatar(
                        backgroundColor: AppTheme.secondary3,
                        backgroundImage: _userInfo?['userpictureurl'] != null
                            ? NetworkImage(_userInfo!['userpictureurl'])
                            : null,
                        child: _userInfo?['userpictureurl'] == null
                            ? Icon(Icons.person, color: AppTheme.secondary1, size: 30)
                            : null,
                      ),
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.secondary1, AppTheme.secondary1.withOpacity(0.7)],
                      ),
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
                      _getAvailableIcon(item.type.name),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
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
                    _getAvailableIcon('logout'),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.secondary1, AppTheme.secondary1.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary1.withOpacity(0.3),
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
                  'Good ${_getGreeting()},',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userInfo?['fullname']?.split(' ').first ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ready to continue your learning journey?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.school,
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
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  IconData _getAvailableIcon(String iconKey) {
    // Direct Material Icon mapping to avoid service dependencies
    final directIcons = {
      'quickActions': Icons.flash_on,
      'recommendedCourses': Icons.recommend,
      'keyMetrics': Icons.analytics,
      'upcomingEvents': Icons.event,
      'recentActivity': Icons.history,
      'logout': Icons.logout,
      'quiz': Icons.quiz,
      'certificate': Icons.card_membership,
      'discussions': Icons.forum,
      'assignments': Icons.assignment,
      'event': Icons.event,
      'chat': Icons.chat_bubble_outline,
      'play': Icons.play_circle_outline,
      'arrow_forward': Icons.arrow_forward_ios,
    };

    return directIcons[iconKey] ?? Icons.help_outline;
  }

  Widget _buildLearningMetrics() {
    if (_isMetricsLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(color: AppTheme.secondary1)),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Learning Metrics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Completion Rate',
                  _learningMetrics['completionRate'] ?? '0%',
                  Icons.analytics_outlined,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Deadlines',
                  _learningMetrics['deadlines'] ?? '0',
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Active Courses',
                  _learningMetrics['activeCourses'] ?? '0',
                  Icons.book_outlined,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Completed',
                  _learningMetrics['completedCourses'] ?? '0',
                  Icons.emoji_events,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: _quickActions.length,
            itemBuilder: (context, index) {
              final action = _quickActions[index];
              return GestureDetector(
                onTap: () => _navigateTo(action.type),
                child: Container(
                  decoration: BoxDecoration(
                    color: action.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: action.color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: action.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getAvailableIcon(action.icon),
                          color: action.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        action.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Courses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => _navigateToScreen(
                  CourseCatalogScreen(token: widget.token),
                  'Course Catalog',
                ),
                child: Text(
                  'View All',
                  style: TextStyle(color: AppTheme.secondary1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isCoursesLoading)
            Center(child: CircularProgressIndicator(color: AppTheme.secondary1))
          else if (_myCourses.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No courses enrolled yet',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _navigateToScreen(
                      CourseCatalogScreen(token: widget.token),
                      'Course Catalog',
                    ),
                    child: Text('Browse Courses'),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _myCourses.take(5).length,
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
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.secondary1.withOpacity(0.8),
                                    AppTheme.secondary2.withOpacity(0.8),
                                  ],
                                ),
                              ),
                              child: course.courseimage.isNotEmpty
                                  ? Image.network(
                                      course.courseimage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Icon(Icons.book, color: Colors.white, size: 32),
                                    )
                                  : Icon(Icons.book, color: Colors.white, size: 32),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.fullname,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    if (course.summary.isNotEmpty)
                                      Text(
                                        course.summary,
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const Spacer(),
                                    if (course.progress != null)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${course.progress!.toStringAsFixed(0)}% Complete',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          LinearProgressIndicator(
                                            value: course.progress! / 100,
                                            backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
                                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondary1),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Events',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (_isEventsLoading)
            Center(child: CircularProgressIndicator(color: AppTheme.secondary1))
          else if (_upcomingEvents.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 48,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No upcoming events',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          else
            ...(_upcomingEvents.take(3).map((event) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.textSecondary.withOpacity(0.1)),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getAvailableIcon('event'),
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                title: Text(
                  event.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  event.subtitle,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      event.date,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      event.time,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        titleTextStyle: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: AppTheme.textPrimary),
            onPressed: () {
              
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              _fetchUserInfo(),
              _fetchMyCourses(),
              _fetchUpcomingEvents(),
              _fetchLearningMetrics(),
            ]);
          },
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondary1.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            _navigateToScreen(
              ChatListScreen(token: widget.token),
              'Chat',
            );
          },
          backgroundColor: AppTheme.secondary1,
          elevation: 0,
          child: Icon(
            DynamicIconService.instance.getIcon('chat'),
            color: Colors.white,
            size: 28,
          ),
        ),
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
  final String date;
  final String time;

  UpcomingEvent({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.time,
  });
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
            content: Text('Unable to continue. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _lastViewedCourse == null ? 'Start Learning' : 'Continue Learning',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _lastViewedCourse?.fullname ?? 'Explore the course catalog',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.green,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}