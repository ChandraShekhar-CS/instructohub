// A simple data model class to represent a course.
// In a real app, this would be generated from your API schema (e.g., using Freezed or JSON Serializable).
class Course {
  final String id;
  final String title;
  final String description;
  final String instructor;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.instructor,
  });

  // A factory constructor for creating a new Course instance from a map.
  // This is useful for parsing the JSON response from your API.
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      instructor: json['instructor'] as String,
    );
  }
}
