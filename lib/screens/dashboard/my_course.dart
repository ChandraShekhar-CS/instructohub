import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:InstructoHub/models/course_model.dart';
import 'package:InstructoHub/models/course_category_model.dart';
import 'course_detail_screen.dart';
import 'package:InstructoHub/services/api_service.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';
import 'package:InstructoHub/services/enhanced_icon_service.dart';

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
  String? _errorMessage;

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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _fetchCourseCategories(),
        _fetchCourses(),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0] as List<CourseCategory>;
          _courses = results[1] as List<Course>;
          _filterCourses();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error fetching data: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCategoryChange() async {
    setState(() => _isLoading = true);
    try {
      final courses = await _fetchCourses();
      if (mounted) {
        setState(() {
          _courses = courses;
          _filterCourses();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error fetching data: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<CourseCategory>> _fetchCourseCategories() async {
    final response = await ApiService.instance.callCustomAPI(
      'core_course_get_categories',
      widget.token,
      {},
      method: 'POST',
    );

    if (response is List) {
      return response.map((json) => CourseCategory.fromJson(json)).toList();
    }
    throw Exception('Failed to load course categories');
  }

  Future<List<Course>> _fetchCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfoString = prefs.getString('userInfo');
    if (userInfoString == null) throw Exception('User info not found');
    final userInfo = json.decode(userInfoString);
    final userId = userInfo['userid'];

    Map<String, String> params = {'userid': userId.toString()};

    if (_selectedCategoryIds.isNotEmpty) {
      for (int i = 0; i < _selectedCategoryIds.length; i++) {
        params['categoryids[$i]'] = _selectedCategoryIds[i].toString();
      }
    }

    final response = await ApiService.instance.callCustomAPI(
      'local_instructohub_get_all_courses_with_user_enrolment',
      widget.token,
      params,
      method: 'POST',
    );

    List<Course> courses = [];
    if (response is List) {
      courses = response
          .expand((category) => (category['courses'] as List<dynamic>))
          .map((courseJson) => Course.fromJson(courseJson))
          .toList();
    } else if (response is Map && response['courses'] != null) {
      courses = (response['courses'] as List)
          .map((courseJson) => Course.fromJson(courseJson))
          .toList();
    } else if (response is Map && response['data'] != null) {
      final data = response['data'];
      if (data is List) {
        courses = data
            .expand((category) => (category['courses'] as List<dynamic>))
            .map((courseJson) => Course.fromJson(courseJson))
            .toList();
      }
    }

    return courses;
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

  Future<void> _openCourse(Course course) async {
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
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              DynamicIconService.instance.getIcon('filter'),
              color: _isFilterPanelOpen 
                ? Theme.of(context).primaryColor
                : null,
            ),
            onPressed: _toggleFilterPanel,
            tooltip: 'Filters',
          ),
          IconButton(
            icon: Icon(DynamicIconService.instance.getIcon('refresh')),
            onPressed: _isLoading ? null : _fetchData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    return Row(
      children: [
        if (_isFilterPanelOpen) _buildFilterPanel(),
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  Widget _buildErrorState() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Container(
        padding: EdgeInsets.all(themeService.getSpacing('lg')),
        margin: EdgeInsets.all(themeService.getSpacing('lg')),
        decoration: BoxDecoration(
            color: themeService.getColor('error').withOpacity(0.1),
            borderRadius:
                BorderRadius.circular(themeService.getBorderRadius('medium')),
            border: Border.all(
                color: themeService.getColor('error').withOpacity(0.3))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(DynamicIconService.instance.getIcon('error'),
                size: 64, color: themeService.getColor('error')),
            SizedBox(height: themeService.getSpacing('md')),
            Text('Failed to Load Courses',
                style: textTheme.headlineSmall
                    ?.copyWith(color: themeService.getColor('error'))),
            SizedBox(height: themeService.getSpacing('sm')),
            Text(_errorMessage ?? 'An unexpected error occurred',
                textAlign: TextAlign.center, style: textTheme.bodyMedium),
            SizedBox(height: themeService.getSpacing('lg')),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: Icon(DynamicIconService.instance.getIcon('refresh')),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildSearchSection(),
        Expanded(child: _buildCourseGrid()),
      ],
    );
  }

  Widget _buildSearchSection() {
    final themeService = DynamicThemeService.instance;
    return Container(
      padding: EdgeInsets.all(themeService.getSpacing('md')),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for courses...',
              prefixIcon: Icon(
                DynamicIconService.instance.getIcon('search'),
                color: themeService.getColor('secondary1'),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(DynamicIconService.instance.getIcon('close'),
                          color: themeService.getColor('textSecondary')),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: themeService.getColor('borderColor'),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: themeService.getColor('borderColor'),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: themeService.getColor('primary'),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: themeService.getColor('cardColor'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filteredCourses.length} courses found',
                style: TextStyle(
                  color: themeService.getColor('textSecondary'),
                  fontSize: 14,
                ),
              ),
              if (_selectedCategoryIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeService.getColor('primary').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedCategoryIds.length} filters',
                    style: TextStyle(
                      color: themeService.getColor('primary'),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseGrid() {
    if (_filteredCourses.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: _filteredCourses.length,
      itemBuilder: (context, index) {
        final course = _filteredCourses[index];
        return CourseGridCard(
          course: course,
          token: widget.token,
          onCoursePressed: _openCourse,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    final bool hasContent =
        _searchController.text.isNotEmpty || _selectedCategoryIds.isNotEmpty;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(themeService.getSpacing('lg')),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              DynamicIconService.instance
                  .getIcon(hasContent ? 'search' : 'courses'),
              size: 64,
              color: themeService.getColor('textSecondary').withOpacity(0.5),
            ),
            SizedBox(height: themeService.getSpacing('md')),
            Text(hasContent ? 'No courses found' : 'No courses available',
                style: textTheme.headlineSmall),
            SizedBox(height: themeService.getSpacing('sm')),
            Text(
              hasContent
                  ? 'Try adjusting your search or filters'
                  : 'Check back later for new courses',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            if (hasContent) ...[
              SizedBox(height: themeService.getSpacing('lg')),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _selectedCategoryIds.clear());
                  _handleCategoryChange();
                },
                icon: Icon(DynamicIconService.instance.getIcon('close')),
                label: const Text('Clear Filters'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: themeService.getColor('cardColor'),
                    foregroundColor: themeService.getColor('textPrimary')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    final themeService = DynamicThemeService.instance;
    return Material(
      elevation: 4,
      child: Container(
        width: 280,
        height: double.infinity,
        color: themeService.getColor('cardColor'),
        child: Column(
          children: [
            _buildFilterHeader(),
            const Divider(),
            Expanded(child: _buildFilterContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterHeader() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.all(themeService.getSpacing('md')),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Filters', style: textTheme.headlineSmall),
          Row(
            children: [
              if (_selectedCategoryIds.isNotEmpty)
                IconButton(
                  icon: Icon(DynamicIconService.instance.getIcon('refresh'),
                      color: themeService.getColor('secondary1')),
                  onPressed: () {
                    setState(() => _selectedCategoryIds.clear());
                    _handleCategoryChange();
                  },
                  tooltip: 'Clear Filters',
                ),
              IconButton(
                icon: Icon(DynamicIconService.instance.getIcon('close')),
                onPressed: _toggleFilterPanel,
                tooltip: 'Close Filters',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterContent() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: themeService.getSpacing('md')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Categories', style: textTheme.titleLarge),
          SizedBox(height: themeService.getSpacing('sm')),
          Expanded(
            child: _categories.isEmpty
                ? const Center(child: Text("No categories found."))
                : _buildCategoriesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final isSelected = _selectedCategoryIds.contains(category.id);

        return CheckboxListTile(
          title: Text(category.name),
          value: isSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedCategoryIds.add(category.id);
              } else {
                _selectedCategoryIds.remove(category.id);
              }
            });
            _handleCategoryChange();
          },
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }
}

class CourseGridCard extends StatelessWidget {
  final Course course;
  final String token;
  final Function(Course) onCoursePressed;

  const CourseGridCard({
    required this.course,
    required this.token,
    required this.onCoursePressed,
    Key? key,
  }) : super(key: key);

  String _cleanHtmlContent(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => onCoursePressed(course),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                child: _buildCourseImage(context),
              ),
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
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        course.summary.isNotEmpty
                            ? _cleanHtmlContent(course.summary)
                            : 'Explore this course to learn new skills.',
                        style: textTheme.bodySmall?.copyWith(
                          color: themeService.getColor('textSecondary'),
                          height: 1.3,
                          fontSize: 12,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (course.progress != null && course.progress! > 0) 
                      _buildProgressSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    final progress = course.progress ?? 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  color: themeService.getColor('textSecondary'),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${progress.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: themeService.getColor('primary'),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress / 100.0,
              minHeight: 5,
              backgroundColor: themeService.getColor('borderColor').withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(progress, themeService),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress, DynamicThemeService themeService) {
    if (progress >= 100) {
      return Colors.green;
    } else if (progress >= 75) {
      return Colors.blue;
    } else if (progress >= 50) {
      return Colors.orange;
    } else if (progress > 0) {
      return themeService.getColor('primary');
    }
    return themeService.getColor('borderColor');
  }

  Widget _buildCourseImage(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    
    if (course.courseimage.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: course.courseimage,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildImagePlaceholder(context),
        errorWidget: (context, url, error) => _buildImagePlaceholder(context),
      );
    }
    
    return _buildImagePlaceholder(context);
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    final themeService = DynamicThemeService.instance;
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
      child: Center(
        child: Icon(
          DynamicIconService.instance.getIcon('courses'),
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }
}