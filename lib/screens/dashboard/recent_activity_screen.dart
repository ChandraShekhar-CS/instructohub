import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/dynamic_theme_service.dart';
import '../../services/enhanced_icon_service.dart';

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
      } else if (data is Map && data.containsKey('activities') && data['activities'] is List) {
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
            const Text("Failed to load activity.", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'An unknown error occurred.'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchRecentActivity, child: const Text("Try Again"))
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
            color: theme.textTheme.bodyMedium?.color,
          ),
          const SizedBox(height: 16),
          Text('No recent activity', style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }

  Widget _buildActivityCard(dynamic activity) {
    final theme = Theme.of(context);
    final themeService = DynamicThemeService.instance;
    final String actionType = activity['action'] ?? 'unknown';

    DateTime timestamp;
    try {
      var timeCreated = activity['timecreated'];
      if (timeCreated is String) {
        timeCreated = int.tryParse(timeCreated) ?? 0;
      }
      timestamp = DateTime.fromMillisecondsSinceEpoch((timeCreated ?? 0) * 1000);
    } catch (e) {
      timestamp = DateTime.now();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(
          DynamicIconService.instance.getIcon(actionType),
          color: themeService.getColor('secondary1'),
        ),
        title: Text(activity['name'] ?? 'Unknown Activity', style: theme.textTheme.titleSmall),
        subtitle: Text(activity['course']?['fullname'] ?? '', style: theme.textTheme.bodySmall),
        trailing: Text(
          _formatTimeAgo(timestamp),
          style: theme.textTheme.bodySmall,
        ),
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
