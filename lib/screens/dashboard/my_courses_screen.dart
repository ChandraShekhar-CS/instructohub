import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:InstructoHub/models/course_model.dart';
import 'package:InstructoHub/services/api_service.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';
import 'course_detail_screen.dart';

// Enum to manage filter state
enum CourseFilter { all, inProgress, completed, notStarted }

class MyCoursesScreen extends StatefulWidget {
  final String token;
  final CourseFilter? initialFilter;
  const MyCoursesScreen({required this.token, this.initialFilter, Key? key}) : super(key: key);

  @override
  _MyCoursesScreenState createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  bool _isLoading = true;
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  String? _errorMessage;
  late CourseFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter ?? CourseFilter.all;
    _fetchMyCourses();
  }

  Future<void> _fetchMyCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final progressData = await ApiService.instance.getUserProgress(widget.token);
      List<Course> courses = [];
      if (progressData != null && progressData['courses'] is List) {
        courses = (progressData['courses'] as List)
            .map((courseData) => Course.fromJson(courseData))
            .toList();
      }

      if (mounted) {
        setState(() {
          _allCourses = courses;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    setState(() {
      switch (_currentFilter) {
        case CourseFilter.inProgress:
          _filteredCourses = _allCourses.where((c) => (c.progress ?? 0) > 0 && (c.progress ?? 0) < 100).toList();
          break;
        case CourseFilter.completed:
          _filteredCourses = _allCourses.where((c) => (c.progress ?? 0) >= 100).toList();
          break;
        case CourseFilter.notStarted:
           _filteredCourses = _allCourses.where((c) => (c.progress ?? 0) == 0).toList();
          break;
        case CourseFilter.all:
        default:
          _filteredCourses = List.from(_allCourses);
          break;
      }
    });
  }

  void _navigateToCourse(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailScreen(
          course: course,
          token: widget.token,
        ),
      ),
    ).then((_) => _fetchMyCourses());
  }
  
  String _cleanHtmlContent(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    return Scaffold(
      backgroundColor: themeService.getColor('background'),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildFilterChips(),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _buildErrorView()
                      : _filteredCourses.isEmpty
                          ? _buildEmptyView()
                          : _buildCoursesGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4.0, 16.0, 16.0, 8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: DynamicThemeService.instance.getColor('textPrimary')),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            'My Learning',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildFilterChip(CourseFilter.all, 'All Courses'),
          _buildFilterChip(CourseFilter.inProgress, 'In Progress'),
          _buildFilterChip(CourseFilter.completed, 'Completed'),
          _buildFilterChip(CourseFilter.notStarted, 'Not Started'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(CourseFilter filter, String label) {
    final themeService = DynamicThemeService.instance;
    final bool isSelected = _currentFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _currentFilter = filter;
              _applyFilter();
            });
          }
        },
        backgroundColor: themeService.getColor('backgroundLight'),
        selectedColor: themeService.getColor('primary'),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : themeService.getColor('textPrimary'),
          fontWeight: FontWeight.w600,
        ),
        shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.transparent : themeService.getColor('border'))),
      ),
    );
  }

  Widget _buildCoursesGrid() {
    return RefreshIndicator(
      onRefresh: _fetchMyCourses,
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        itemCount: _filteredCourses.length,
        itemBuilder: (context, index) {
          return _buildCourseCard(_filteredCourses[index]);
        },
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToCourse(course),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: _buildCourseImage(course, themeService),
            ),
            Expanded(
              flex: 7,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      course.fullname,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        _cleanHtmlContent(course.summary).isNotEmpty
                            ? _cleanHtmlContent(course.summary)
                            : 'No summary for this course.',
                        style: textTheme.bodySmall?.copyWith(
                          color: themeService.getColor('textSecondary'),
                          height: 1.3,
                          fontSize: 12,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (course.progress != null)
                      _buildProgressSection(course, themeService, textTheme)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseImage(Course course, DynamicThemeService themeService) {
    if (course.courseimage.isNotEmpty) {
      String imageUrlWithToken = course.courseimage;
      if (!imageUrlWithToken.contains('token=')) {
          if (imageUrlWithToken.contains('?')) {
              imageUrlWithToken += '&token=${widget.token}';
          } else {
              imageUrlWithToken += '?token=${widget.token}';
          }
      }

      return CachedNetworkImage(
        imageUrl: imageUrlWithToken,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => _buildImagePlaceholder(themeService),
      );
    }
    return _buildImagePlaceholder(themeService);
  }

  Widget _buildImagePlaceholder(DynamicThemeService themeService) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeService.getColor('primary').withOpacity(0.3),
            themeService.getColor('secondary1').withOpacity(0.3),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.school_outlined,
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProgressSection(Course course, DynamicThemeService themeService, TextTheme textTheme) {
    final progress = course.progress ?? 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress / 100.0,
            minHeight: 6,
            backgroundColor: themeService.getColor('borderLight'),
            valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(progress, themeService)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${progress.toStringAsFixed(0)}% Complete',
          style: textTheme.bodySmall?.copyWith(color: themeService.getColor('textSecondary')),
        ),
      ],
    );
  }
  
  Color _getProgressColor(double progress, DynamicThemeService themeService) {
    if (progress >= 100) {
      return themeService.getColor('success');
    } else if (progress > 0) {
      return themeService.getColor('info');
    } else {
      return themeService.getColor('textMuted');
    }
  }

  Widget _buildErrorView() {
    return Center(child: Text("Error: $_errorMessage"));
  }

  Widget _buildEmptyView() {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: DynamicThemeService.instance.getColor('textSecondary')),
            const SizedBox(height: 16),
            const Text(
              "No Courses Found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "No courses match the selected filter.",
              style: TextStyle(color: DynamicThemeService.instance.getColor('textSecondary')),
            )
          ],
        ),
      );
  }
}
