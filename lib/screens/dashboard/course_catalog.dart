import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:InstructoHub/models/course_model.dart';
import 'package:InstructoHub/models/course_category_model.dart';
import 'course_detail_screen.dart';
import 'package:InstructoHub/services/api_service.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';

class CourseCatalogScreen extends StatefulWidget {
  final String token;
  const CourseCatalogScreen({required this.token, Key? key}) : super(key: key);

  @override
  _CourseCatalogScreenState createState() => _CourseCatalogScreenState();
}

class _CourseCatalogScreenState extends State<CourseCatalogScreen> {
  List<Course> _allCourses = [];
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
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final categoriesFuture = ApiService.instance.getCourseCategories(widget.token);
      final coursesFuture = ApiService.instance.getCoursesByCategories(widget.token);

      final results = await Future.wait([categoriesFuture, coursesFuture]);
      
      final categoriesData = results[0] as List;
      final coursesData = results[1] as List;

      if (mounted) {
        setState(() {
          _categories = categoriesData.map((cat) => CourseCategory.fromJson(cat)).toList();

          if (coursesData.isNotEmpty && coursesData.first is Map && coursesData.first.containsKey('courses')) {
               _allCourses = coursesData
                .expand((category) => (category['courses'] as List<dynamic>))
                .map((courseJson) => Course.fromJson(courseJson))
                .toList();
          } else {
              _allCourses = coursesData.map((course) => Course.fromJson(course)).toList();
          }

          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load catalog data: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<Course> tempCourses = List.from(_allCourses);
    final searchTerm = _searchController.text.toLowerCase();

    if (_selectedCategoryIds.isNotEmpty) {
        tempCourses = tempCourses.where((course) => _selectedCategoryIds.contains(course.categoryId)).toList();
    }
    
    if (searchTerm.isNotEmpty) {
      tempCourses = tempCourses.where((course) => course.fullname.toLowerCase().contains(searchTerm)).toList();
    }

    setState(() {
      _filteredCourses = tempCourses;
    });
  }

  void _toggleFilterPanel() {
    setState(() => _isFilterPanelOpen = !_isFilterPanelOpen);
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
    );
  }

   String _cleanHtmlContent(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
            ? _buildErrorState()
            : Row(
              children: [
                if (_isFilterPanelOpen) _buildFilterPanel(),
                Expanded(child: _buildMainContent()),
              ],
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(_errorMessage!, textAlign: TextAlign.center),
    ));
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildHeader(),
        _buildSearchSection(),
        Expanded(child: _filteredCourses.isEmpty ? _buildEmptyState() : _buildCourseGrid()),
      ],
    );
  }
  
  Widget _buildHeader() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Catalog', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: _selectedCategoryIds.isNotEmpty 
                  ? Theme.of(context).colorScheme.primary
                  : null,
              ),
              onPressed: _toggleFilterPanel,
              tooltip: 'Filters',
            ),
          ],
        ),
      );
  }

  Widget _buildSearchSection() {
    final themeService = DynamicThemeService.instance;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search courses...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: themeService.getColor('border')),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: themeService.getColor('border')),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: themeService.getColor('primary'), width: 2),
          ),
          filled: true,
          fillColor: themeService.getColor('backgroundLight'),
        ),
      ),
    );
  }

  Widget _buildCourseGrid() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        itemCount: _filteredCourses.length,
        itemBuilder: (context, index) {
          final course = _filteredCourses[index];
          return _buildCourseCard(course);
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

  Widget _buildEmptyState() {
     return const Center(child: Text("No courses found. Try adjusting your search or filters."));
  }

  Widget _buildFilterPanel() {
    return Material(
      elevation: 4,
      child: Container(
        width: 280,
        height: double.infinity,
        color: Theme.of(context).cardColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Categories', style: Theme.of(context).textTheme.titleLarge),
            ),
            const Divider(height: 1),
            Expanded(
              child: _categories.isEmpty
                ? const Center(child: Text("No categories to display."))
                : ListView.builder(
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
                            _applyFilters();
                          });
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
