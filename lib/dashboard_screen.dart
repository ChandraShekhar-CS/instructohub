import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // only needed if you fetch layout from API
import 'package:http/http.dart' as http; // only needed if you fetch layout from API
import 'dashboard_item_model.dart';

class DashboardScreen extends StatefulWidget {
  final String token;
  const DashboardScreen({required this.token, super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // State variables
  bool _isLoading = true;
  bool _isEditMode = false;

  // Lists to hold the widgets for each column
  List<DashboardItem> _mainItems = [];
  List<DashboardItem> _sidebarItems = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardLayout();
  }

  // Simulates fetching the dashboard layout from an API or local storage.
  Future<void> _fetchDashboardLayout() async {
    setState(() { _isLoading = true; });

    // In a real app, you would fetch this from your API.
    // For now, we'll use a default layout.
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _mainItems = [
        DashboardItem(id: 1, type: DashboardWidgetType.continueLearning, isMainArea: true),
        DashboardItem(id: 2, type: DashboardWidgetType.quickActions, isMainArea: true),
        DashboardItem(id: 3, type: DashboardWidgetType.recommendedCourses, isMainArea: true),
      ];
      _sidebarItems = [
        DashboardItem(id: 4, type: DashboardWidgetType.keyMetrics, isMainArea: false),
        DashboardItem(id: 5, type: DashboardWidgetType.upcomingEvents, isMainArea: false),
        DashboardItem(id: 6, type: DashboardWidgetType.recentActivity, isMainArea: false),
      ];
      _isLoading = false;
    });
  }

  // Saves the new layout. In a real app, this would be an API call.
  Future<void> _saveLayout() async {
    // This is where you would send the updated `_mainItems` and `_sidebarItems`
    // lists to your backend API to save the user's layout.
    
    // For now, we just toggle the edit mode and show a snackbar.
    setState(() {
      _isEditMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Layout saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  // Handles the logout process
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
      appBar: AppBar(
        title: const Text('My Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          // Edit/Save Button
          TextButton.icon(
            onPressed: () {
              if (_isEditMode) {
                _saveLayout();
              } else {
                setState(() { _isEditMode = true; });
              }
            },
            icon: Icon(_isEditMode ? Icons.check : Icons.edit_outlined),
            label: Text(_isEditMode ? 'Save' : 'Edit'),
            style: TextButton.styleFrom(
              foregroundColor: _isEditMode ? Colors.green : Theme.of(context).primaryColor,
            ),
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                // Use a responsive layout. Two columns for wide screens, one for narrow.
                if (constraints.maxWidth > 720) {
                  return _buildTwoColumnLayout();
                } else {
                  return _buildSingleColumnLayout();
                }
              },
            ),
    );
  }

  // --- Layout Builders ---

  Widget _buildTwoColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Content Column
        Expanded(
          flex: 2,
          child: _buildDroppableList(isMainArea: true, items: _mainItems),
        ),
        // Sidebar Column
        Expanded(
          flex: 1,
          child: _buildDroppableList(isMainArea: false, items: _sidebarItems),
        ),
      ],
    );
  }

  Widget _buildSingleColumnLayout() {
    // Combine both lists for single-column view
    final allItems = [..._mainItems, ..._sidebarItems];
    return _buildDroppableList(isMainArea: true, items: allItems, isSingleColumn: true);
  }

  // --- Drag and Drop List Builder ---

  Widget _buildDroppableList({required bool isMainArea, required List<DashboardItem> items, bool isSingleColumn = false}) {
    return DragTarget<DashboardItem>(
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: double.infinity, // Ensures the drop target fills the column
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? Colors.blue.withOpacity(0.05) : Colors.transparent,
            border: candidateData.isNotEmpty ? Border.all(color: Colors.blue, width: 2) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          // ReorderableListView handles reordering within the list
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
      // This is called when an item is dropped onto the list
      onAccept: (item) {
        setState(() {
          // Remove from the source list
          _mainItems.removeWhere((i) => i.id == item.id);
          _sidebarItems.removeWhere((i) => i.id == item.id);
          
          // Add to the destination list
          if (isMainArea) {
            _mainItems.add(item..isMainArea = true);
          } else {
            _sidebarItems.add(item..isMainArea = false);
          }
        });
      },
    );
  }
  
  // --- Draggable Item Builder ---

  Widget _buildDraggableItem(DashboardItem item, int index, List<DashboardItem> list, bool isSingleColumn) {
    Widget child = _isEditMode 
      ? Opacity(opacity: 0.8, child: item.widget) 
      : item.widget;

    // The key is crucial for ReorderableListView to identify items.
    Key key = ValueKey(item.id);

    if (!_isEditMode) {
      return Container(key: key, padding: const EdgeInsets.symmetric(vertical: 4), child: child);
    }
    
    // Draggable allows the item to be picked up and moved.
    return LongPressDraggable<DashboardItem>(
      key: key,
      data: item,
      // The widget that appears under the user's finger while dragging
      feedback: Material(
        elevation: 4.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * (isSingleColumn ? 0.9 : 0.6)),
          child: item.widget,
        ),
      ),
      // The widget that is left behind in the list
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: item.widget,
      ),
      child: Container(
        padding: const EdgeInsets.all(4.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(child: child),
            const Icon(Icons.drag_handle, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
