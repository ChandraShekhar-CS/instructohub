import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'course_model.dart';
import 'course_category_model.dart';
import 'course_detail_screen.dart';

class CourseCatalogScreen extends StatefulWidget {
  final String token;
  const CourseCatalogScreen({required this.token, Key? key}) : super(key: key);

  @override
  _CourseCatalogScreenState createState() => _CourseCatalogScreenState();
}

class _CourseCatalogScreenState extends State<CourseCatalogScreen> {
  List<Course> _courses = [];
  List<Course> _filteredCourses = [];
  List<CourseCategory> _categories = [];
  List<int> _selectedCategoryIds = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isFilterPanelOpen = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_filterCourses);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _fetchCourseCategories(),
        _fetchCourses(),
      ]);
      setState(() {
        _categories = results[0] as List<CourseCategory>;
        _courses = results[1] as List<Course>;
        _filteredCourses = _courses;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<CourseCategory>> _fetchCourseCategories() async {
    final url = Uri.parse(
        'https://moodle.instructohub.com/webservice/rest/server.php?wsfunction=core_course_get_categories&moodlewsrestformat=json&wstoken=${widget.token}');
    final response = await http.post(url);

    if (response.statusCode == 200) {
      final List<dynamic> categoriesJson = json.decode(response.body);
      return categoriesJson
          .map((json) => CourseCategory.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load course categories');
    }
  }

  Future<List<Course>> _fetchCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfoString = prefs.getString('userInfo');
    if (userInfoString == null) throw Exception('User info not found');
    final userInfo = json.decode(userInfoString);
    final userId = userInfo['userid'];

    String categoryParams = '';
    if (_selectedCategoryIds.isNotEmpty) {
      for (int i = 0; i < _selectedCategoryIds.length; i++) {
        categoryParams += '&categoryids[$i]=${_selectedCategoryIds[i]}';
      }
    }

    final url = Uri.parse(
        'https://moodle.instructohub.com/webservice/rest/server.php?wsfunction=local_instructohub_get_all_courses_with_user_enrolment&moodlewsrestformat=json&wstoken=${widget.token}&userid=$userId$categoryParams');

    final response = await http.post(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .expand((category) => (category['courses'] as List<dynamic>))
          .map((courseJson) => Course.fromJson(courseJson))
          .toList();
    } else {
      throw Exception('Failed to load courses');
    }
  }

  void _filterCourses() {
    List<Course> tempCourses = _courses;
    final searchTerm = _searchController.text.toLowerCase();

    if (searchTerm.isNotEmpty) {
      tempCourses = tempCourses
          .where((course) => course.fullname.toLowerCase().contains(searchTerm))
          .toList();
    }

    setState(() {
      _filteredCourses = tempCourses;
    });
  }

  void _toggleFilterPanel() {
    setState(() => _isFilterPanelOpen = !_isFilterPanelOpen);
  }

  // Modified _openCourse function
  Future<void> _openCourse(Course course) async {
    // Navigate directly to CourseDetailScreen without showing a dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailScreen(
          course: course,
          token: widget.token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _toggleFilterPanel,
            tooltip: 'Filters',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for courses...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _filteredCourses.isNotEmpty
                            ? LayoutBuilder(
                                builder: (context, constraints) {
                                  int crossAxisCount = 2;
                                  if (constraints.maxWidth > 1200) {
                                    crossAxisCount = 4;
                                  } else if (constraints.maxWidth > 800) {
                                    crossAxisCount = 3;
                                  }
                                  
                                  return GridView.builder(
                                    padding: const EdgeInsets.all(16.0),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 16.0,
                                      mainAxisSpacing: 16.0,
                                      childAspectRatio: 0.75,
                                    ),
                                    itemCount: _filteredCourses.length,
                                    itemBuilder: (context, index) {
                                      return CourseCard(
                                        course: _filteredCourses[index],
                                        onCoursePressed: _openCourse,
                                      );
                                    },
                                  );
                                },
                              )
                            : const Center(
                                child: Text('No courses found.'),
                              ),
                      ),
                    ],
                  ),
                ),
                if (_isFilterPanelOpen) _buildFilterPanel(),
              ],
            ),
    );
  }

  Widget _buildFilterPanel() {
    return Material(
      elevation: 4.0,
      child: Container(
        width: 280,
        height: double.infinity,
        color: Colors.grey[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filters',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleFilterPanel,
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              const Text('Categories',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return CheckboxListTile(
                      title: Text(category.name),
                      value: _selectedCategoryIds.contains(category.id),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedCategoryIds.add(category.id);
                          } else {
                            _selectedCategoryIds.remove(category.id);
                          }
                          _fetchCourses().then((courses) {
                            setState(() {
                              _courses = courses;
                              _filterCourses();
                            });
                          });
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final Course course;
  final Function(Course) onCoursePressed;

  const CourseCard({
    required this.course,
    required this.onCoursePressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onCoursePressed(course),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: constraints.maxHeight * 0.55,
                  width: double.infinity,
                  child: course.courseimage.isNotEmpty
                      ? Image.network(
                          course.courseimage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.school,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.school,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                ),
                Container(
                  height: constraints.maxHeight * 0.45,
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.fullname,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.0,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2.0),
                            Expanded(
                              child: Text(
                                course.summary.isNotEmpty 
                                    ? course.summary 
                                    : 'Course description not available',
                                style: TextStyle(
                                  fontSize: 10.0,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => onCoursePressed(course),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE16B3A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                            ),
                            child: const Text(
                              'View Course',
                              style: TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
