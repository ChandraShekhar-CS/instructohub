import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:InstructoHub/models/course_model.dart';
import 'package:InstructoHub/services/api_service.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';
import 'package:InstructoHub/services/enhanced_icon_service.dart';
import 'my_course.dart';
import 'course_detail_screen.dart';

class QuickActionsScreen extends StatelessWidget {
  final String token;

  const QuickActionsScreen({required this.token, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.instance;

    final List<Map<String, dynamic>> actions = [
      {
        'title': 'Browse Courses',
        'iconKey': 'catalog',
        'color': themeService.getColor('secondary1'),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseCatalogScreen(token: token),
              ),
            ),
      },
      {
        'title': 'My Profile',
        'iconKey': 'profile',
        'color': themeService.getColor('secondary2'),
        'onTap': () => _showComingSoon(context, 'Profile')
      },
      {
        'title': 'Messages',
        'iconKey': 'messages',
        'color': themeService.getColor('info'),
        'onTap': () => _showComingSoon(context, 'Messages')
      },
      {
        'title': 'Notifications',
        'iconKey': 'notifications',
        'color': themeService.getColor('primary1'),
        'onTap': () => _showComingSoon(context, 'Notifications')
      },
      {
        'title': 'Calendar',
        'iconKey': 'calendar',
        'color': themeService.getColor('success'),
        'onTap': () => _showComingSoon(context, 'Calendar')
      },
      {
        'title': 'Grades',
        'iconKey': 'grades',
        'color': themeService.getColor('secondary1'),
        'onTap': () => _showComingSoon(context, 'Grades')
      },
      {
        'title': 'Downloads',
        'iconKey': 'download',
        'color': themeService.getColor('secondary2'),
        'onTap': () => _showComingSoon(context, 'Downloads')
      },
      {
        'title': 'Settings',
        'iconKey': 'settings',
        'color': themeService.getColor('textSecondary'),
        'onTap': () => _showComingSoon(context, 'Settings')
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Quick Actions')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(
              context,
              action['title'],
              action['iconKey'],
              action['color'],
              action['onTap'],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String iconKey,
    Color color,
    VoidCallback onTap,
  ) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2.0,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(themeService.getBorderRadius('medium'))),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(DynamicIconService.instance.getIcon(iconKey),
                  color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center, style: textTheme.titleSmall),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
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
}

class RecommendedCoursesScreen extends StatefulWidget {
  final String token;
  const RecommendedCoursesScreen({required this.token, Key? key})
      : super(key: key);

  @override
  State<RecommendedCoursesScreen> createState() =>
      _RecommendedCoursesScreenState();
}

class _RecommendedCoursesScreenState extends State<RecommendedCoursesScreen> {
  bool _isLoading = true;
  List<Course> _courses = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoString = prefs.getString('userInfo');
      if (userInfoString == null) throw Exception('User info not found');
      final userInfo = json.decode(userInfoString);
      final userId = userInfo['userid'];

      Map<String, String> params = {'userid': userId.toString()};

      final response = await ApiService.instance.callCustomAPI(
        'local_instructohub_get_all_courses_with_user_enrolment',
        widget.token,
        params,
        method: 'POST',
      );

      List<Course> courses = [];
      if (response is List) {
        courses = response
            .expand((category) => (category['courses'] as List<dynamic>))
            .map((courseJson) => Course.fromJson(courseJson))
            .where((course) => !(course.isEnrolled ?? false))
            .toList();
      }

      if (mounted) {
        setState(() {
          _courses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load courses: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openCourse(Course course) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailScreen(
          course: course,
          token: widget.token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCourses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    if (_courses.isEmpty) {
      return _buildEmptyState();
    }
    return _buildCourseGrid();
  }

  Widget _buildCourseGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final themeService = DynamicThemeService.instance;
        int crossAxisCount = (constraints.maxWidth > 1200)
            ? 4
            : (constraints.maxWidth > 800)
                ? 3
                : (constraints.maxWidth > 500)
                    ? 2
                    : 1;
        double childAspectRatio = (crossAxisCount == 1) ? 3.0 : 0.8;

        return GridView.builder(
          padding: EdgeInsets.all(themeService.getSpacing('md')),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: themeService.getSpacing('md'),
            mainAxisSpacing: themeService.getSpacing('md'),
            childAspectRatio: childAspectRatio,
          ),
          itemCount: _courses.length,
          itemBuilder: (context, index) {
            final course = _courses[index];
            return CourseCard(
              course: course,
              token: widget.token,
              onCoursePressed: _openCourse,
              layoutType: crossAxisCount == 1
                  ? CardLayoutType.list
                  : CardLayoutType.grid,
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Container(
        padding: EdgeInsets.all(themeService.getSpacing('lg')),
        margin: EdgeInsets.all(themeService.getSpacing('lg')),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: themeService.getColor('error')),
            SizedBox(height: themeService.getSpacing('md')),
            Text('Failed to Load Courses', style: textTheme.headlineSmall),
            SizedBox(height: themeService.getSpacing('sm')),
            Text(_errorMessage ?? 'An unexpected error occurred.',
                textAlign: TextAlign.center, style: textTheme.bodyMedium),
            SizedBox(height: themeService.getSpacing('lg')),
            ElevatedButton.icon(
              onPressed: _fetchCourses,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(themeService.getSpacing('lg')),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.recommend,
              size: 64,
              color: themeService.getColor('textSecondary').withOpacity(0.5),
            ),
            SizedBox(height: themeService.getSpacing('md')),
            Text('No Recommendations', style: textTheme.headlineSmall),
            SizedBox(height: themeService.getSpacing('sm')),
            Text(
              'We don\'t have any new recommendations for you right now.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class MetricsScreen extends StatefulWidget {
  final String token;

  const MetricsScreen({required this.token, Key? key}) : super(key: key);

  @override
  _MetricsScreenState createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _metricsData = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMetricsData();
  }

  Future<void> _fetchMetricsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.instance.getUserProgress(widget.token);
      if (mounted) {
        setState(() {
          _metricsData = data ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading metrics: ${e.toString()}'),
            backgroundColor: DynamicThemeService.instance.getColor('error'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Metrics')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchMetricsData,
              child: _errorMessage != null
                  ? _buildErrorView()
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildStatCard(
                            title: 'Courses Enrolled',
                            value:
                                _metricsData['totalcourses']?.toString() ?? '0',
                            iconKey: 'school',
                            color: DynamicThemeService.instance
                                .getColor('secondary1'),
                          ),
                          const SizedBox(height: 16.0),
                          _buildStatCard(
                            title: 'Courses Completed',
                            value: _metricsData['completedcoursescount']
                                    ?.toString() ??
                                '0',
                            iconKey: 'check_circle',
                            color: DynamicThemeService.instance
                                .getColor('success'),
                          ),
                          const SizedBox(height: 16.0),
                          _buildStatCard(
                            title: 'In Progress',
                            value: _metricsData['activecoursescount']
                                    ?.toString() ??
                                '0',
                            iconKey: 'play_circle',
                            color:
                                DynamicThemeService.instance.getColor('info'),
                          ),
                          const SizedBox(height: 16.0),
                          _buildStatCard(
                            title: 'Not Started',
                            value:
                                _metricsData['notstartedcount']?.toString() ??
                                    '0',
                            iconKey: 'schedule',
                            color: DynamicThemeService.instance
                                .getColor('textSecondary'),
                          ),
                          const SizedBox(height: 16.0),
                          _buildProgressCard(),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            const Text("Failed to load metrics.",
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'An unknown error occurred.'),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _fetchMetricsData, child: const Text("Try Again"))
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String iconKey,
    required Color color,
  }) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(themeService.getBorderRadius('medium')),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                    themeService.getBorderRadius('small')),
              ),
              child: Icon(DynamicIconService.instance.getIcon(iconKey),
                  color: color, size: 24),
            ),
            const SizedBox(width: 16.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium),
                const SizedBox(height: 4.0),
                Text(value,
                    style: textTheme.headlineSmall?.copyWith(color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    double progress = 0.0;
    try {
      var progressValue = _metricsData['overallprogress'];
      if (progressValue is String) {
        progress = double.tryParse(progressValue) ?? 0.0;
      } else if (progressValue is num) {
        progress = progressValue.toDouble();
      }
    } catch (e) {
      progress = 0.0;
    }

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(themeService.getBorderRadius('medium')),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overall Progress', style: textTheme.titleLarge),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        themeService.getBorderRadius('large')),
                    child: LinearProgressIndicator(
                      value: progress / 100.0,
                      minHeight: 12,
                      backgroundColor: themeService
                          .getColor('textSecondary')
                          .withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          themeService.getColor('secondary1')),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Text('${progress.toStringAsFixed(0)}%',
                    style: textTheme.titleLarge
                        ?.copyWith(color: themeService.getColor('secondary1'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
      subtitle: (json['description'] as String? ?? '')
          .replaceAll(RegExp(r'<[^>]*>'), ''),
      formattedDate: _formatDate(date),
      formattedTime: _formatTime(date),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${date.minute.toString().padLeft(2, '0')} $period';
  }
}

class UpcomingEventsScreen extends StatefulWidget {
  final String token;
  const UpcomingEventsScreen({required this.token, Key? key}) : super(key: key);

  @override
  _UpcomingEventsScreenState createState() => _UpcomingEventsScreenState();
}

class _UpcomingEventsScreenState extends State<UpcomingEventsScreen> {
  bool _isLoading = true;
  List<UpcomingEvent> _events = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingEvents();
  }

  Future<void> _fetchUpcomingEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
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
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load events: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Events')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchUpcomingEvents,
              child: _errorMessage != null
                  ? _buildErrorView()
                  : _events.isEmpty
                      ? _buildEmptyView()
                      : ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            return _buildEventCard(_events[index]);
                          },
                        ),
            ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            const Text("Failed to load events.",
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'An unknown error occurred.'),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _fetchUpcomingEvents, child: const Text("Try Again"))
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text('No upcoming events', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Check back later for new events.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(UpcomingEvent event) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeService.getColor('warning').withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                    themeService.getBorderRadius('medium')),
              ),
              child: Icon(
                Icons.event_available,
                color: themeService.getColor('warning'),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.subtitle,
                      style: textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  event.formattedDate,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  event.formattedTime,
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RecentActivityScreen extends StatefulWidget {
  final String token;

  const RecentActivityScreen({required this.token, Key? key}) : super(key: key);

  @override
  _RecentActivityScreenState createState() => _RecentActivityScreenState();
}

class _RecentActivityScreenState extends State<RecentActivityScreen> {
  bool _isLoading = true;
  List<dynamic> _activities = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRecentActivity();
  }

  Future<void> _fetchRecentActivity() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoString = prefs.getString('userInfo');
      if (userInfoString == null) throw Exception('User info not found');
      final userInfo = json.decode(userInfoString);
      final userId = userInfo['userid'];

      final params = {
        'userid': userId.toString(),
        'limit': '20',
        'actions[0]': 'viewed',
        'actions[1]': 'submitted',
        'actions[2]': 'attempted'
      };

      final data = await ApiService.instance.callCustomAPI(
          'local_instructohub_get_recent_activity', widget.token, params);

      List<dynamic> activitiesData = [];
      if (data is List) {
        activitiesData = data;
      } else if (data is Map &&
          data.containsKey('activities') &&
          data['activities'] is List) {
        activitiesData = data['activities'];
      }

      if (mounted) {
        setState(() {
          _activities = activitiesData;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading activity: ${e.toString()}'),
            backgroundColor: DynamicThemeService.instance.getColor('error'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recent Activity')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRecentActivity,
              child: _errorMessage != null
                  ? _buildErrorView()
                  : _activities.isEmpty
                      ? _buildEmptyView()
                      : ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _activities.length,
                          itemBuilder: (context, index) {
                            final activity = _activities[index];
                            return _buildActivityCard(activity);
                          },
                        ),
            ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            const Text("Failed to load activity.",
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'An unknown error occurred.'),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _fetchRecentActivity, child: const Text("Try Again"))
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            DynamicIconService.instance.getIcon('history'),
            size: 80,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text('No recent activity', style: theme.textTheme.headlineSmall),
        ],
      ),
    );
  }

  Widget _buildActivityCard(dynamic activity) {
    final theme = Theme.of(context);
    final themeService = DynamicThemeService.instance;
    final String actionType = activity['action'] ?? 'unknown';
    final String moduleName = activity['modulename'] ?? 'unknown';

    DateTime timestamp;
    try {
      var timeCreated = activity['timecreated'];
      if (timeCreated is String) {
        timeCreated = int.tryParse(timeCreated) ?? 0;
      }
      timestamp =
          DateTime.fromMillisecondsSinceEpoch((timeCreated ?? 0) * 1000);
    } catch (e) {
      timestamp = DateTime.now();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(
          DynamicIconService.instance.getIcon(moduleName),
          color: themeService.getColor('secondary1'),
        ),
        title: Text(activity['name'] ?? 'Unknown Activity',
            style: theme.textTheme.titleMedium),
        subtitle: Text(
            '${activity['course']?['fullname'] ?? ''}\nAction: $actionType',
            style: theme.textTheme.bodySmall),
        trailing: Text(
          _formatTimeAgo(timestamp),
          style: theme.textTheme.bodySmall,
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}

enum CardLayoutType { grid, list }

class CourseCard extends StatelessWidget {
  final Course course;
  final String token;
  final Function(Course) onCoursePressed;
  final CardLayoutType layoutType;

  const CourseCard({
    required this.course,
    required this.token,
    required this.onCoursePressed,
    this.layoutType = CardLayoutType.grid,
    Key? key,
  }) : super(key: key);

  String _cleanHtmlContent(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onCoursePressed(course),
        child: layoutType == CardLayoutType.grid
            ? _buildGridContent(context)
            : _buildListContent(context),
      ),
    );
  }

  Widget _buildGridContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _buildCourseImage(context, course.courseimage),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.fullname,
                    style: textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    course.summary.isNotEmpty
                        ? _cleanHtmlContent(course.summary)
                        : 'Explore this course to learn new skills.',
                    style: textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                        onPressed: () => onCoursePressed(course),
                        child: const Text('View'))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final double progress = course.progress ?? 0.0;

    return Row(
      children: [
        SizedBox(
            width: 120, child: _buildCourseImage(context, course.courseimage)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.fullname,
                    style: textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const Spacer(),
                if (course.progress != null)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: progress / 100.0,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 6),
                      Text('${progress.toStringAsFixed(0)}% Complete',
                          style: textTheme.bodySmall),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseImage(BuildContext context, String imageUrl) {
    final themeService = DynamicThemeService.instance;
    return Container(
      color: themeService.getColor('secondary3'),
      child: imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: course.courseimage,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
                  _buildImagePlaceholder(context),
            )
          : _buildImagePlaceholder(context),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    return Center(
      child: Icon(
        DynamicIconService.instance.getIcon('courses'),
        size: 40,
        color: themeService.getColor('secondary1').withOpacity(0.6),
      ),
    );
  }
}
