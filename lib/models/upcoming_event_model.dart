class UpcomingEvent {
  final int id;
  final String title;
  final String subtitle;
  final String eventType;
  final DateTime dateTime;
  final String? description;
  final String? courseId;
  final String? courseName;

  UpcomingEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.eventType,
    required this.dateTime,
    this.description,
    this.courseId,
    this.courseName,
  });

  factory UpcomingEvent.fromJson(Map<String, dynamic> json) {
    // Parse the event data from Moodle calendar API
    int eventId = 0;
    if (json['id'] != null) {
      eventId = json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0;
    }

    String eventTitle = json['name'] ?? json['title'] ?? 'Untitled Event';
    String eventSubtitle = '';
    
    // Build subtitle from available information
    if (json['coursename'] != null && json['coursename'].toString().isNotEmpty) {
      eventSubtitle = json['coursename'].toString();
    } else if (json['course'] != null && json['course']['fullname'] != null) {
      eventSubtitle = json['course']['fullname'].toString();
    }

    // Determine event type
    String eventType = 'event';
    if (json['eventtype'] != null) {
      eventType = json['eventtype'].toString();
    } else if (json['modulename'] != null) {
      eventType = json['modulename'].toString();
    } else if (eventTitle.toLowerCase().contains('assignment')) {
      eventType = 'assign';
    } else if (eventTitle.toLowerCase().contains('quiz')) {
      eventType = 'quiz';
    }

    // Parse date/time
    DateTime eventDateTime = DateTime.now();
    if (json['timestart'] != null) {
      int timestamp = json['timestart'] is int ? json['timestart'] : int.tryParse(json['timestart'].toString()) ?? 0;
      if (timestamp > 0) {
        eventDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
    } else if (json['timeduration'] != null) {
      // Some events might have duration instead of start time
      int timestamp = json['timeduration'] is int ? json['timeduration'] : int.tryParse(json['timeduration'].toString()) ?? 0;
      if (timestamp > 0) {
        eventDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
    }

    return UpcomingEvent(
      id: eventId,
      title: eventTitle,
      subtitle: eventSubtitle,
      eventType: eventType,
      dateTime: eventDateTime,
      description: json['description']?.toString(),
      courseId: json['courseid']?.toString(),
      courseName: json['coursename']?.toString(),
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (eventDate == today) {
      return 'Today';
    } else if (eventDate == today.add(Duration(days: 1))) {
      return 'Tomorrow';
    } else if (eventDate.isBefore(today.add(Duration(days: 7)))) {
      // Within a week - show day of week
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[eventDate.weekday - 1];
    } else {
      // Show month and day
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[eventDate.month - 1]} ${eventDate.day}';
    }
  }

  String get formattedTime {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(1, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String get timeUntilEvent {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.isNegative) {
      return 'Past due';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min';
    } else {
      return 'Now';
    }
  }

  bool get isOverdue {
    return DateTime.now().isAfter(dateTime);
  }

  bool get isDueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return eventDate == today;
  }

  bool get isDueTomorrow {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(Duration(days: 1));
    final eventDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return eventDate == tomorrow;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'eventType': eventType,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'description': description,
      'courseId': courseId,
      'courseName': courseName,
    };
  }

  @override
  String toString() {
    return 'UpcomingEvent(id: $id, title: $title, type: $eventType, date: ${formattedDate} ${formattedTime})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpcomingEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}