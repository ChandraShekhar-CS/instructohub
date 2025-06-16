import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'app_theme.dart';
import 'course_catalog_screen.dart';
import 'course_detail_screen.dart';
import 'course_model.dart';
import 'dashboard_item_model.dart';

class DashboardScreen extends StatefulWidget {
  final String token;
  const DashboardScreen({required this.token, super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  bool _isEditMode = false;

  List<DashboardItem> _mainItems = [];
  List<DashboardItem> _sidebarItems = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardLayout();
  }

  Future<void> _handleContinueLearningTap() async {
    final prefs = await SharedPreferences.getInstance();
    final lastViewedCourseString = prefs.getString('lastViewedCourse');

    if (!mounted) return;

    if (lastViewedCourseString != null) {
      final courseJson = json.decode(lastViewedCourseString);
      final course = Course.fromJson(courseJson);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseDetailScreen(
            course: course,
            token: widget.token,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseCatalogScreen(token: widget.token),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("No recent courses found. Let's find one for you!"),
          backgroundColor: AppTheme.secondary2,
        ),
      );
    }
  }


  Future<void> _fetchDashboardLayout() async {
    setState(() { _isLoading = true; });

    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _mainItems = [
        DashboardItem(id: 1, type: DashboardWidgetType.continueLearning, isMainArea: true),
        DashboardItem(id: 2, type: DashboardWidgetType.quickActions, isMainArea: true),
        DashboardItem(id: 3, type: DashboardWidgetType.recommendedCourses, isMainArea: true),
        DashboardItem(id: 7, type: DashboardWidgetType.courseCatalog, isMainArea: true),
      ];
      _sidebarItems = [
        DashboardItem(id: 4, type: DashboardWidgetType.keyMetrics, isMainArea: false),
        DashboardItem(id: 5, type: DashboardWidgetType.upcomingEvents, isMainArea: false),
        DashboardItem(id: 6, type: DashboardWidgetType.recentActivity, isMainArea: false),
      ];
      _isLoading = false;
    });
  }

  Future<void> _saveLayout() async {
    setState(() {
      _isEditMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Layout saved!'),
        backgroundColor: AppTheme.secondary1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Dashboard'),
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () {
                if (_isEditMode) {
                  _saveLayout();
                } else {
                  setState(() { _isEditMode = true; });
                }
              },
              icon: Icon(
                _isEditMode ? Icons.check : Icons.edit_outlined,
                color: _isEditMode ? AppTheme.secondary1 : AppTheme.primary1,
              ),
              label: Text(
                _isEditMode ? 'Save' : 'Edit',
                style: TextStyle(
                  color: _isEditMode ? AppTheme.secondary1 : AppTheme.primary1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.secondary1),
              onPressed: _handleLogout,
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.secondary1,
              ),
            )
          : Container(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 720) {
                    return _buildTwoColumnLayout();
                  } else {
                    return _buildSingleColumnLayout();
                  }
                },
              ),
            ),
    );
  }

  Widget _buildTwoColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildDroppableList(isMainArea: true, items: _mainItems),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: _buildDroppableList(isMainArea: false, items: _sidebarItems),
        ),
      ],
    );
  }

  Widget _buildSingleColumnLayout() {
    final allItems = [..._mainItems, ..._sidebarItems];
    return _buildDroppableList(isMainArea: true, items: allItems, isSingleColumn: true);
  }

  Widget _buildDroppableList({required bool isMainArea, required List<DashboardItem> items, bool isSingleColumn = false}) {
    return DragTarget<DashboardItem>(
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty 
                ? AppTheme.secondary1.withOpacity(0.05) 
                : Colors.transparent,
            border: candidateData.isNotEmpty 
                ? Border.all(color: AppTheme.secondary1, width: 2) 
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ReorderableListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildDraggableItem(item, index, items, isSingleColumn);
            },
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = items.removeAt(oldIndex);
                items.insert(newIndex, item);
              });
            },
          ),
        );
      },
      onAccept: (item) {
        setState(() {
          _mainItems.removeWhere((i) => i.id == item.id);
          _sidebarItems.removeWhere((i) => i.id == item.id);
          
          if (isMainArea) {
            _mainItems.add(item..isMainArea = true);
          } else {
            _sidebarItems.add(item..isMainArea = false);
          }
        });
      },
    );
  }
  
  Widget _buildDraggableItem(DashboardItem item, int index, List<DashboardItem> list, bool isSingleColumn) {
    Key key = ValueKey(item.id);

    if (item.type == DashboardWidgetType.continueLearning && !_isEditMode) {
      return GestureDetector(
        key: key,
        onTap: _handleContinueLearningTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: item.widget,
        ),
      );
    }
    
    if (item.type == DashboardWidgetType.courseCatalog && !_isEditMode) {
      return GestureDetector(
        key: key,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseCatalogScreen(token: widget.token),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: item.widget,
        ),
      );
    }
    
    Widget child = _isEditMode 
      ? Opacity(opacity: 0.8, child: item.widget) 
      : item.widget;

    if (!_isEditMode) {
      return Container(
        key: key, 
        margin: const EdgeInsets.only(bottom: 12),
        child: child,
      );
    }
    
    return LongPressDraggable<DashboardItem>(
      key: key,
      data: item,
      feedback: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * (isSingleColumn ? 0.9 : 0.6)
          ),
          child: item.widget,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: item.widget,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.secondary1.withOpacity(0.3), width: 2),
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            child,
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.secondary1,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.drag_handle,
                  color: AppTheme.cardColor,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
