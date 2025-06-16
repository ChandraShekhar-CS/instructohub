class Course {
  final int id;
  final String fullname;
  final String summary;
  final String courseimage;
  final List<dynamic> contacts;

  Course({
    required this.id,
    required this.fullname,
    required this.summary,
    required this.courseimage,
    required this.contacts,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as int? ?? 0,
      fullname: (json['fullname'] as String?) ?? 'Untitled Course',
      summary: (json['summary'] as String?)?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '',
      courseimage: (json['courseimage'] as String?) ?? '',
      contacts: (json['contacts'] as List<dynamic>?) ?? [],
    );
  }
}