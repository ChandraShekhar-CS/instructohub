import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_model.dart';
import '../models/course_category_model.dart';
import 'course_detail_screen.dart';
import '../theme/dynamic_app_theme.dart';
import '../services/api_service.dart';
import '../services/enhanced_icon_service.dart';

typedef AppTheme = DynamicAppTheme;

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
          _filteredCourses = _courses;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error fetching data: ${e.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  DynamicIconService.instance.errorIcon,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('Error fetching data: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<CourseCategory>> _fetchCourseCategories() async {
    try {
      final response = await ApiService.instance.callCustomAPI(
        'core_course_get_categories',
        widget.token,
        {},
        method: 'POST',
      );

      if (response is List) {
        return response
            .map((json) => CourseCategory.fromJson(json))
            .toList();
      } else if (response is Map && response['categories'] != null) {
        return (response['categories'] as List)
            .map((json) => CourseCategory.fromJson(json))
            .toList();
      } else {
        throw Exception('Invalid response format for course categories');
      }
    } catch (e) {
      print('Error fetching course categories: $e');
      throw Exception('Failed to load course categories: ${e.toString()}');
    }
  }

  Future<List<Course>> _fetchCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoString = prefs.getString('userInfo');
      if (userInfoString == null) {
        throw Exception('User info not found in local storage');
      }
      
      final userInfo = json.decode(userInfoString);
      final userId = userInfo['userid'];
      if (userId == null) {
        throw Exception('User ID not found in user info');
      }

      Map<String, String> params = {
        'userid': userId.toString(),
      };

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
    } catch (e) {
      print('Error fetching courses: $e');
      throw Exception('Failed to load courses: ${e.toString()}');
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

  Future<void> _openCourse(Course course) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastViewedCourse', json.encode(course.toJson()));

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseDetailScreen(
            course: course,
            token: widget.token,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  DynamicIconService.instance.errorIcon,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text('Error opening course: ${e.toString()}'),
              ],
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _refreshCourses() async {
    await _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Catalog'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        elevation: AppTheme.elevationLow,
        actions: [
          IconButton(
            icon: Icon(DynamicIconService.instance.filterIcon),
            onPressed: _toggleFilterPanel,
            tooltip: 'Filters',
          ),
          IconButton(
            icon: Icon(DynamicIconService.instance.refreshIcon),
            onPressed: _isLoading ? null : _refreshCourses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppTheme.buildLoadingIndicator(size: 48),
            SizedBox(height: AppTheme.spacingMd),
            Text(
              'Loading courses...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSizeBase,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return Row(
      children: [
        Expanded(child: _buildMainContent()),
        if (_isFilterPanelOpen) _buildFilterPanel(),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        margin: EdgeInsets.all(AppTheme.spacingLg),
        decoration: AppTheme.getStatusDecoration('error'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              DynamicIconService.instance.errorIcon,
              size: 64,
              color: AppTheme.error,
            ),
            SizedBox(height: AppTheme.spacingMd),
            Text(
              'Failed to Load Courses',
              style: TextStyle(
                fontSize: AppTheme.fontSizeXl,
                fontWeight: FontWeight.bold,
                color: AppTheme.error,
              ),
            ),
            SizedBox(height: AppTheme.spacingSm),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSizeBase,
              ),
            ),
            SizedBox(height: AppTheme.spacingLg),
            AppTheme.buildActionButton(
              text: 'Try Again',
              iconKey: 'refresh',
              onPressed: _refreshCourses,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(child: _buildCourseGrid()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for courses...',
          prefixIcon: Icon(
            DynamicIconService.instance.searchIcon,
            color: AppTheme.secondary1,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    DynamicIconService.instance.closeIcon,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _filterCourses();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(
              color: AppTheme.textSecondary.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(
              color: AppTheme.secondary1,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: AppTheme.cardColor,
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildCourseGrid() {
    if (_filteredCourses.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 500) {
          crossAxisCount = 2;
        }
        
        // REFACTORED: Adjusted childAspectRatio to provide more height for the cards.
        double childAspectRatio = (crossAxisCount == 1) ? 3.0 : 0.8;

        return GridView.builder(
          padding: EdgeInsets.all(AppTheme.spacingMd),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppTheme.spacingMd,
            mainAxisSpacing: AppTheme.spacingMd,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: _filteredCourses.length,
          itemBuilder: (context, index) {
            final course = _filteredCourses[index];
            return CourseCard(
              course: course,
              token: widget.token,
              onCoursePressed: _openCourse,
              layoutType: crossAxisCount == 1 ? CardLayoutType.list : CardLayoutType.grid,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final bool hasSearchTerm = _searchController.text.isNotEmpty;
    final bool hasFilters = _selectedCategoryIds.isNotEmpty;

    return Center(
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearchTerm || hasFilters
                  ? DynamicIconService.instance.searchIcon
                  : DynamicIconService.instance.coursesIcon,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: AppTheme.spacingMd),
            Text(
              hasSearchTerm || hasFilters
                  ? 'No courses found'
                  : 'No courses available',
              style: TextStyle(
                fontSize: AppTheme.fontSizeXl,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: AppTheme.spacingSm),
            Text(
              hasSearchTerm || hasFilters
                  ? 'Try adjusting your search or filters'
                  : 'Check back later for new courses',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.7),
                fontSize: AppTheme.fontSizeBase,
              ),
            ),
            if (hasSearchTerm || hasFilters) ...[
              SizedBox(height: AppTheme.spacingLg),
              AppTheme.buildActionButton(
                text: 'Clear Filters',
                iconKey: 'close',
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedCategoryIds.clear();
                  });
                  _fetchCourses().then((courses) {
                      setState(() {
                        _courses = courses;
                        _filterCourses();
                      });
                    });
                },
                style: AppTheme.outlinedButtonStyle,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Material(
      elevation: AppTheme.elevationMedium,
      child: Container(
        width: 280,
        height: double.infinity,
        color: AppTheme.cardColor,
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
    return Padding(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Filters',
            style: TextStyle(
              fontSize: AppTheme.fontSizeXl,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Row(
            children: [
              if (_selectedCategoryIds.isNotEmpty)
                IconButton(
                  icon: Icon(
                    DynamicIconService.instance.refreshIcon,
                    color: AppTheme.secondary1,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedCategoryIds.clear();
                    });
                    _fetchCourses().then((courses) {
                      setState(() {
                        _courses = courses;
                        _filterCourses();
                      });
                    });
                  },
                  tooltip: 'Clear Filters',
                ),
              IconButton(
                icon: Icon(
                  DynamicIconService.instance.closeIcon,
                  color: AppTheme.textPrimary,
                ),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLg,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: AppTheme.spacingSm),
          if (_selectedCategoryIds.isNotEmpty)
            Container(
              padding: EdgeInsets.all(AppTheme.spacingSm),
              decoration: AppTheme.getStatusDecoration('info'),
              child: Text(
                '${_selectedCategoryIds.length} categories selected',
                style: AppTheme.getStatusTextStyle('info'),
              ),
            ),
          SizedBox(height: AppTheme.spacingMd),
          Expanded(
            child: _categories.isEmpty
                ? _buildCategoriesLoadingState()
                : _buildCategoriesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppTheme.buildLoadingIndicator(),
          SizedBox(height: AppTheme.spacingSm),
          Text(
            'Loading categories...',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSizeSm,
            ),
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
          title: Text(
            category.name,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontSizeBase,
            ),
          ),
          subtitle: category.description.isNotEmpty
              ? Text(
                  category.description,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontSizeSm,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          value: isSelected,
          activeColor: AppTheme.secondary1,
          checkColor: Colors.white,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedCategoryIds.add(category.id);
              } else {
                _selectedCategoryIds.remove(category.id);
              }
            });
            
            _fetchCourses().then((courses) {
              setState(() {
                _courses = courses;
                _filterCourses();
              });
            }).catchError((error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error filtering courses: $error'),
                  backgroundColor: AppTheme.error,
                ),
              );
            });
          },
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }
}

enum CardLayoutType { grid, list }

class CourseCard extends StatelessWidget {
  final Course course;
  final String token;
  final Function(Course) onCoursePressed;
  final CardLayoutType layoutType;

  const CourseCard({
    required this.course,
    required this.token,
    required this.onCoursePressed,
    this.layoutType = CardLayoutType.grid,
    Key? key,
  }) : super(key: key);

  String _constructImageUrl(String courseImage) {
    if (courseImage.isEmpty || courseImage.contains('.svg')) {
      return '';
    }
    
    try {
      if (courseImage.startsWith('http://') || courseImage.startsWith('https://')) {
        return courseImage.contains('token=') 
          ? courseImage 
          : '$courseImage${courseImage.contains('?') ? '&' : '?'}token=$token';
      }
      
      final baseUrl = ApiService.instance.baseUrl;
      if (baseUrl.isNotEmpty) {
        final uri = Uri.parse(baseUrl);
        final baseDomain = '${uri.scheme}://${uri.host}';
        String cleanImagePath = courseImage.startsWith('/') ? courseImage.substring(1) : courseImage;
        return '$baseDomain/webservice/pluginfile.php/$cleanImagePath?token=$token';
      }
      return '';
    } catch (e) {
      print('Error constructing image URL: $e');
      return '';
    }
  }
  
  String _cleanHtmlContent(String htmlString) {
    return htmlString
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppTheme.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onCoursePressed(course),
        child: layoutType == CardLayoutType.grid 
            ? _buildGridContent() 
            : _buildListContent(),
      ),
    );
  }

  Widget _buildGridContent() {
    final imageUrl = _constructImageUrl(course.courseimage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _buildCourseImage(imageUrl),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.fullname,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppTheme.fontSizeLg,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    course.summary.isNotEmpty ? _cleanHtmlContent(course.summary) : 'Explore this course to learn new skills.',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeBase,
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 8),
                _buildActionButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListContent() {
    final imageUrl = _constructImageUrl(course.courseimage);
    final double progress = course.progress ?? 0.0;
    final double progressValue = progress / 100.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 120,
          child: _buildCourseImage(imageUrl),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  course.fullname,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppTheme.fontSizeLg,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (course.progress != null)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondary1),
                          // REFACTORED: Increased the height of the progress bar.
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '0% Complete',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeSm,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            '${progress.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeSm,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseImage(String imageUrl) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppTheme.secondary2.withOpacity(0.05),
      child: imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildImagePlaceholder(true),
              errorWidget: (context, url, error) => _buildImagePlaceholder(false),
            )
          : _buildImagePlaceholder(false),
    );
  }
  
  Widget _buildImagePlaceholder(bool isLoading) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            AppTheme.buildLoadingIndicator(size: 24)
          else
            Icon(
              DynamicIconService.instance.coursesIcon,
              size: 40,
              color: AppTheme.secondary1.withOpacity(0.6),
            ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({bool isCompact = false}) {
    return ElevatedButton.icon(
      onPressed: () => onCoursePressed(course),
      style: ElevatedButton.styleFrom(
        padding: isCompact ? const EdgeInsets.symmetric(vertical: 8, horizontal: 16) : const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: AppTheme.secondary1,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        elevation: 0,
      ),
      icon: Icon(
        DynamicIconService.instance.playIcon,
        size: isCompact ? 18 : 20,
      ),
      label: Text(
        'View Course',
        style: TextStyle(
          fontSize: isCompact ? AppTheme.fontSizeBase : AppTheme.fontSizeLg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
