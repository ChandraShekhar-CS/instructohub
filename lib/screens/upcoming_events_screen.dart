import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';

class UpcomingEventsScreen extends StatefulWidget {
  final String token;

  const UpcomingEventsScreen({required this.token, Key? key}) : super(key: key);

  @override
  _UpcomingEventsScreenState createState() => _UpcomingEventsScreenState();
}

class _UpcomingEventsScreenState extends State<UpcomingEventsScreen> {
  bool _isLoading = true;
  List<dynamic> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchUpcomingEvents();
  }

  Future<void> _fetchUpcomingEvents() async {
    setState(() => _isLoading = true);
    
    try {
      final url = Uri.parse(
        'https://moodle.instructohub.com/webservice/rest/server.php?wsfunction=core_calendar_get_calendar_upcoming_view&moodlewsrestformat=json&wstoken=${widget.token}'
      );
      
      final response = await http.post(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _events = data['events'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Events'),
        backgroundColor: AppTheme.secondary1,
        foregroundColor: AppTheme.offwhite,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchUpcomingEvents,
              child: _events.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_note,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No upcoming events',
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
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        return _buildEventCard(event);
                      },
                    ),
            ),
    );
  }

  Widget _buildEventCard(dynamic event) {
    final eventName = event['name'] ?? 'Unknown Event';
    final eventDescription = event['description'] ?? '';
    final eventDate = DateTime.fromMillisecondsSinceEpoch(
      (event['timestart'] ?? 0) * 1000,
    );
    final courseName = event['course']?['fullname'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getEventIcon(event['eventtype'] ?? ''),
                    color: AppTheme.secondary1,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary1,
                        ),
                      ),
                      if (courseName.isNotEmpty)
                        Text(
                          courseName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.primary2,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  _formatEventDate(eventDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (eventDescription.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                eventDescription,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'assign':
        return Icons.assignment;
      case 'quiz':
        return Icons.quiz;
      case 'forum':
        return Icons.forum;
      case 'lesson':
        return Icons.school;
      default:
        return Icons.event;
    }
  }

  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[date.weekday - 1]} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}