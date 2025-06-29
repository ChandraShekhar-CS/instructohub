bool? parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }
  return null;
}

class Course {
  final int id;
  final String fullname;
  final String summary;
  final String courseimage;
  final int categoryId;
  final double? progress;
  final bool? isEnrolled;

  Course({
    required this.id,
    required this.fullname,
    required this.summary,
    required this.courseimage,
    required this.categoryId,
    this.progress,
    this.isEnrolled,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    int courseId = 0;
    if (json['id'] != null) {
      courseId = json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0;
    } else if (json['courseid'] != null) {
      courseId = json['courseid'] is int
          ? json['courseid']
          : int.tryParse(json['courseid'].toString()) ?? 0;
    }

    String courseName = 'Untitled Course';
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

    String courseSummary = '';
    if (json['summary'] != null && json['summary'].toString().trim().isNotEmpty) {
      courseSummary = json['summary'].toString().trim();
      courseSummary = courseSummary.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    } else if (json['description'] != null && json['description'].toString().trim().isNotEmpty) {
        courseSummary = json['description'].toString().trim();
        courseSummary = courseSummary.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    }


    String courseImage = '';
    if (json['courseimage'] != null && json['courseimage'].toString().trim().isNotEmpty) {
      courseImage = json['courseimage'].toString().trim();
    } else if (json['image'] != null && json['image'].toString().trim().isNotEmpty) {
      courseImage = json['image'].toString().trim();
    } else if (json['imageurl'] != null && json['imageurl'].toString().trim().isNotEmpty) {
        courseImage = json['imageurl'].toString().trim();
    }
    
    double? courseProgress;
    if (json['progress'] != null) {
      courseProgress = (json['progress'] as num?)?.toDouble();
    } else if (json['progresspercentage'] != null) {
      courseProgress = (json['progresspercentage'] as num?)?.toDouble();
    }

    int categoryIdValue = 0;
    if (json['categoryid'] != null) {
        categoryIdValue = json['categoryid'] is int
            ? json['categoryid']
            : int.tryParse(json['categoryid'].toString()) ?? 0;
    } else if (json['category'] != null) {
         categoryIdValue = json['category'] is int
            ? json['category']
            : int.tryParse(json['category'].toString()) ?? 0;
    }

    return Course(
      id: courseId,
      fullname: courseName,
      summary: courseSummary,
      courseimage: courseImage,
      categoryId: categoryIdValue,
      progress: courseProgress,
      isEnrolled: parseBool(json['isenrolled']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullname': fullname,
      'summary': summary,
      'courseimage': courseimage,
      'categoryid': categoryId,
      'progress': progress,
      'isenrolled': isEnrolled,
    };
  }
}
