import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

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
      final prefs = await SharedPreferences.getInstance();
      final userInfoString = prefs.getString('userInfo');
      if (userInfoString == null) throw Exception('User info not found');
      final userInfo = json.decode(userInfoString);
      final userId = userInfo['userid'];

      final url = Uri.parse(
        'https://moodle.instructohub.com/webservice/rest/server.php?wsfunction=local_instructohub_get_recent_activity&moodlewsrestformat=json&wstoken=${widget.token}&userid=$userId&limit=20&actions[0]=viewed&actions[1]=submitted&actions[2]=attempted&actions[3]=completed&actions[4]=answered&actions[5]=posted&actions[6]=created&actions[7]=uploaded&actions[8]=accessed&actions[9]=started&actions[10]=enrolled'
      );
      
      final response = await http.post(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Recent activity response: $data'); // Debug log
        
        List<dynamic> activitiesData = [];
        
        // Handle different response structures
        if (data is List) {
          activitiesData = data;
        } else if (data is Map) {
          // Check for common response structures
          if (data.containsKey('activities')) {
            var activities = data['activities'];
            if (activities is List) {
              activitiesData = activities;
            } else {
              activitiesData = [];
            }
          } else if (data.containsKey('data')) {
            var activities = data['data'];
            if (activities is List) {
              activitiesData = activities;
            } else {
              activitiesData = [];
            }
          } else if (data.containsKey('recent_activity')) {
            var activities = data['recent_activity'];
            if (activities is List) {
              activitiesData = activities;
            } else {
              activitiesData = [];
            }
          } else {
            // If it's a map but doesn't have expected keys, treat it as empty
            activitiesData = [];
          }
        }
        
        if (mounted) {
          setState(() {
            _activities = activitiesData;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Recent activity error: $e'); // Debug log
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading activity: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Activity'),
        backgroundColor: AppTheme.secondary1,
        foregroundColor: AppTheme.offwhite,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRecentActivity,
              child: _activities.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No recent activity',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
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
    final activityName = activity['name'] ?? 'Unknown Activity';
    final actionType = activity['action'] ?? '';
    final courseName = activity['course']?['fullname'] ?? '';
    
    // Handle timestamp conversion safely
    DateTime timestamp;
    try {
      var timeCreated = activity['timecreated'];
      if (timeCreated is String) {
        timeCreated = int.tryParse(timeCreated) ?? 0;
      }
      timestamp = DateTime.fromMillisecondsSinceEpoch(
        (timeCreated ?? 0) * 1000,
      );
    } catch (e) {
      timestamp = DateTime.now(); // Fallback to current time
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getActionColor(actionType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getActionIcon(actionType),
            color: _getActionColor(actionType),
            size: 24,
          ),
        ),
        title: Text(
          activityName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (courseName.isNotEmpty)
              Text(
                courseName,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primary2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getActionColor(actionType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getActionText(actionType),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getActionColor(actionType),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTimeAgo(timestamp),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.primary2,
                  ),
                ),
              ],
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'viewed':
        return Icons.visibility;
      case 'submitted':
        return Icons.upload;
      case 'attempted':
        return Icons.play_arrow;
      case 'completed':
        return Icons.check_circle;
      case 'answered':
        return Icons.question_answer;
      case 'posted':
        return Icons.send;
      case 'created':
        return Icons.add_circle;
      case 'uploaded':
        return Icons.cloud_upload;
      case 'accessed':
        return Icons.open_in_new;
      case 'started':
        return Icons.start;
      case 'enrolled':
        return Icons.person_add;
      default:
        return Icons.timeline;
    }
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'viewed':
        return AppTheme.secondary1;
      case 'submitted':
        return AppTheme.secondary2;
      case 'attempted':
        return AppTheme.navselected;
      case 'completed':
        return AppTheme.secondary2;
      case 'answered':
        return AppTheme.primary1;
      case 'posted':
        return AppTheme.secondary1;
      case 'created':
        return AppTheme.navbg;
      case 'uploaded':
        return AppTheme.primary1;
      case 'accessed':
        return AppTheme.secondary1;
      case 'started':
        return AppTheme.navselected;
      case 'enrolled':
        return AppTheme.secondary2;
      default:
        return AppTheme.primary2;
    }
  }

  String _getActionText(String action) {
    switch (action.toLowerCase()) {
      case 'viewed':
        return 'Viewed';
      case 'submitted':
        return 'Submitted';
      case 'attempted':
        return 'Attempted';
      case 'completed':
        return 'Completed';
      case 'answered':
        return 'Answered';
      case 'posted':
        return 'Posted';
      case 'created':
        return 'Created';
      case 'uploaded':
        return 'Uploaded';
      case 'accessed':
        return 'Accessed';
      case 'started':
        return 'Started';
      case 'enrolled':
        return 'Enrolled';
      default:
        return action;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}