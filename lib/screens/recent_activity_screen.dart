import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/icon_service.dart';
import '../theme/dynamic_app_theme.dart';
typedef AppTheme = DynamicAppTheme;

class RecentActivityScreen extends StatefulWidget {
  final String token;

  const RecentActivityScreen({required this.token, Key? key}) : super(key: key);

  @override
  _RecentActivityScreenState createState() => _RecentActivityScreenState();
}

class _RecentActivityScreenState extends State<RecentActivityScreen> {
  bool _isLoading = true;
  List<dynamic> _activities = [];

  @override
  void initState() {
    super.initState();
    _fetchRecentActivity();
  }

  Future<void> _fetchRecentActivity() async {
    setState(() => _isLoading = true);
    
    try {
      // FIXED: Reverted to a direct API call to avoid the undefined_method error.
      final prefs = await SharedPreferences.getInstance();
      final userInfoString = prefs.getString('userInfo');
      if (userInfoString == null) throw Exception('User info not found');
      final userInfo = json.decode(userInfoString);
      final userId = userInfo['userid'];

      final url = Uri.parse(
        '${ApiService.instance.baseUrl}?wsfunction=local_instructohub_get_recent_activity&moodlewsrestformat=json&wstoken=${widget.token}&userid=$userId&limit=20&actions[0]=viewed&actions[1]=submitted&actions[2]=attempted&actions[3]=completed&actions[4]=answered&actions[5]=posted&actions[6]=created&actions[7]=uploaded&actions[8]=accessed&actions[9]=started&actions[10]=enrolled'
      );
      
      final response = await http.post(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> activitiesData = [];
        
        if (data is List) {
          activitiesData = data;
        } else if (data is Map && data.containsKey('activities') && data['activities'] is List) {
          activitiesData = data['activities'];
        }

        if (mounted) {
          setState(() {
            _activities = activitiesData;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load recent activity from API');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading activity: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppTheme.buildDynamicAppBar(title: 'Recent Activity'),
      body: _isLoading
          ? Center(child: AppTheme.buildLoadingIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRecentActivity,
              child: _activities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            IconService.instance.getIcon('history'),
                            size: 80,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(height: AppTheme.spacingMd),
                          Text(
                            'No recent activity',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeLg,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(AppTheme.spacingMd),
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                        final activity = _activities[index];
                        return _buildActivityCard(activity);
                      },
                    ),
            ),
    );
  }

  Widget _buildActivityCard(dynamic activity) {
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

    return AppTheme.buildInfoCard(
      iconKey: actionType,
      title: activity['name'] ?? 'Unknown Activity',
      subtitle: activity['course']?['fullname'] ?? '',
      trailing: Text(
        _formatTimeAgo(timestamp),
        style: TextStyle(
          fontSize: AppTheme.fontSizeXs,
          color: AppTheme.textSecondary,
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
