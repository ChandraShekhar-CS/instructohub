class Course {
  final int id;
  final String fullname;
  final String summary;
  final String courseimage;
  final double? progress;

  Course({
    required this.id,
    required this.fullname,
    required this.summary,
    required this.courseimage,
    this.progress,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    // Parse course ID - try different field names
    int courseId = 0;
    if (json['id'] != null) {
      courseId = json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0;
    } else if (json['courseid'] != null) {
      courseId = json['courseid'] is int ? json['courseid'] : int.tryParse(json['courseid'].toString()) ?? 0;
    }

    // Parse course name - try multiple field names in priority order
    String courseName = 'Untitled Course';
    
    // Priority order: fullname -> displayname -> shortname -> name -> coursename
    if (json['fullname'] != null && json['fullname'].toString().trim().isNotEmpty) {
      courseName = json['fullname'].toString().trim();
    } else if (json['displayname'] != null && json['displayname'].toString().trim().isNotEmpty) {
      courseName = json['displayname'].toString().trim();
    } else if (json['shortname'] != null && json['shortname'].toString().trim().isNotEmpty) {
      courseName = json['shortname'].toString().trim();
    } else if (json['name'] != null && json['name'].toString().trim().isNotEmpty) {
      courseName = json['name'].toString().trim();
    } else if (json['coursename'] != null && json['coursename'].toString().trim().isNotEmpty) {
      courseName = json['coursename'].toString().trim();
    } else if (courseId > 0) {
      courseName = 'Course $courseId';
    }

    // Parse summary/description
    String courseSummary = '';
    if (json['summary'] != null && json['summary'].toString().trim().isNotEmpty) {
      courseSummary = json['summary'].toString().trim();
      // Remove HTML tags
      courseSummary = courseSummary.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    } else if (json['description'] != null && json['description'].toString().trim().isNotEmpty) {
      courseSummary = json['description'].toString().trim();
      courseSummary = courseSummary.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    }

    // Parse course image
    String courseImage = '';
    if (json['courseimage'] != null && json['courseimage'].toString().trim().isNotEmpty) {
      courseImage = json['courseimage'].toString().trim();
    } else if (json['image'] != null && json['image'].toString().trim().isNotEmpty) {
      courseImage = json['image'].toString().trim();
    } else if (json['imageurl'] != null && json['imageurl'].toString().trim().isNotEmpty) {
      courseImage = json['imageurl'].toString().trim();
    }

    // Parse progress - try different field names
    double? courseProgress;
    if (json['progress'] != null) {
      if (json['progress'] is num) {
        courseProgress = json['progress'].toDouble();
      } else {
        courseProgress = double.tryParse(json['progress'].toString());
      }
    } else if (json['completionpercentage'] != null) {
      if (json['completionpercentage'] is num) {
        courseProgress = json['completionpercentage'].toDouble();
      } else {
        courseProgress = double.tryParse(json['completionpercentage'].toString());
      }
    } else if (json['completion'] != null) {
      if (json['completion'] is num) {
        courseProgress = json['completion'].toDouble();
      } else {
        courseProgress = double.tryParse(json['completion'].toString());
      }
    } else if (json['progresspercentage'] != null) {
      if (json['progresspercentage'] is num) {
        courseProgress = json['progresspercentage'].toDouble();
      } else {
        courseProgress = double.tryParse(json['progresspercentage'].toString());
      }
    }

    return Course(
      id: courseId,
      fullname: courseName,
      summary: courseSummary,
      courseimage: courseImage,
      progress: courseProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullname': fullname,
      'summary': summary,
      'courseimage': courseimage,
      'progress': progress,
    };
  }

  @override
  String toString() {
    return 'Course(id: $id, fullname: $fullname, progress: $progress)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}