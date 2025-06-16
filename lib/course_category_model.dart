class CourseCategory {
  final int id;
  final String name;
  final String description;

  CourseCategory({
    required this.id,
    required this.name,
    required this.description,
  });

  factory CourseCategory.fromJson(Map<String, dynamic> json) {
    return CourseCategory(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Uncategorized',
      description: (json['description'] as String?) ?? '',
    );
  }
}