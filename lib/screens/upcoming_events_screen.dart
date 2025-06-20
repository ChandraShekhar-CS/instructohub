import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../services/icon_service.dart';
import '../theme/dynamic_app_theme.dart';
typedef AppTheme = DynamicAppTheme;

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
      final data = await ApiService.instance.getUpcomingEvents(widget.token);
      if (mounted) {
        setState(() {
          _events = data['events'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading events: ${e.toString()}'),
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
      appBar: AppTheme.buildDynamicAppBar(title: 'Upcoming Events'),
      body: _isLoading
          ? Center(child: AppTheme.buildLoadingIndicator())
          : RefreshIndicator(
              onRefresh: _fetchUpcomingEvents,
              child: _events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            IconService.instance.getIcon('event'),
                            size: 80,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(height: AppTheme.spacingMd),
                          Text(
                            'No upcoming events',
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
    final eventDate = DateTime.fromMillisecondsSinceEpoch(
      (event['timestart'] ?? 0) * 1000,
    );

    return AppTheme.buildInfoCard(
      iconKey: event['eventtype'] ?? 'event',
      iconColor: AppTheme.secondary1,
      title: event['name'] ?? 'Unknown Event',
      subtitle: event['course']?['fullname'] ?? '',
      trailing: Text(
        _formatEventDate(eventDate),
        style: TextStyle(
          fontSize: AppTheme.fontSizeXs,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) return 'Today at ${_formatTime(date)}';
    if (difference.inDays == 1) return 'Tomorrow at ${_formatTime(date)}';
    
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (difference.inDays < 7) return '${weekdays[date.weekday - 1]} at ${_formatTime(date)}';
    
    return '${date.day}/${date.month} at ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
