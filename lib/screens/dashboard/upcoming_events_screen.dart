import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/dynamic_theme_service.dart';
import '../../services/enhanced_icon_service.dart';

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
      final data = await ApiService.instance.getUpcomingEvents(widget.token);
      if (mounted) {
        setState(() {
          _events = (data['events'] as List? ?? [])
              .map((eventJson) => UpcomingEvent.fromJson(eventJson))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading events: ${e.toString()}'),
            backgroundColor: DynamicThemeService.instance.getColor('error'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                            final event = _events[index];
                            return _buildEventCard(event);
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
            const Text("Failed to load events.", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'An unknown error occurred.'),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _fetchUpcomingEvents,
                child: const Text("Try Again"))
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
            DynamicIconService.instance.getIcon('event'),
            size: 80,
            color: theme.textTheme.bodyMedium?.color,
          ),
          const SizedBox(height: 16.0),
          Text(
            'No upcoming events',
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(UpcomingEvent event) {
    final theme = Theme.of(context);
    final themeService = DynamicThemeService.instance;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(
          DynamicIconService.instance.getIcon(event.eventType),
          color: themeService.getColor('secondary1'),
        ),
        title: Text(event.name, style: theme.textTheme.titleSmall),
        subtitle: event.courseFullName.isNotEmpty
            ? Text(event.courseFullName, style: theme.textTheme.bodySmall)
            : null,
        trailing: Text(
          event.formattedDate,
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}

// Data model for an upcoming event
class UpcomingEvent {
  final String name;
  final String courseFullName;
  final String eventType;
  final String formattedDate;

  UpcomingEvent({
    required this.name,
    required this.courseFullName,
    required this.eventType,
    required this.formattedDate,
  });

  factory UpcomingEvent.fromJson(Map<String, dynamic> json) {
    final DateTime eventDate = DateTime.fromMillisecondsSinceEpoch(
      ((json['timestart'] ?? 0) as int) * 1000,
    );

    return UpcomingEvent(
      name: json['name'] ?? 'Unknown Event',
      courseFullName: json['course']?['fullname'] ?? '',
      eventType: json['eventtype'] ?? 'event',
      formattedDate: _formatEventDate(eventDate),
    );
  }

  static String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today at ${_formatTime(date)}';
    }
    if (difference.inDays == 1 && date.day == now.day +1) {
       return 'Tomorrow at ${_formatTime(date)}';
    }

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (difference.inDays < 7 && difference.inDays > 0) {
      return '${weekdays[date.weekday - 1]} at ${_formatTime(date)}';
    }
    return '${date.day}/${date.month} at ${_formatTime(date)}';
  }

  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
