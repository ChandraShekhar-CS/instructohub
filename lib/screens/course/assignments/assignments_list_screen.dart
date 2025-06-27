import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:InstructoHub/services/api_service.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';
import 'package:InstructoHub/services/enhanced_icon_service.dart';
import 'assignment_submission_screen.dart';

class AssignmentsListScreen extends StatefulWidget {
  final String token;
  final String courseId;
  final String courseName;

  const AssignmentsListScreen({
    required this.token,
    required this.courseId,
    required this.courseName,
    Key? key,
  }) : super(key: key);

  @override
  _AssignmentsListScreenState createState() => _AssignmentsListScreenState();
}

class _AssignmentsListScreenState extends State<AssignmentsListScreen> {
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterStatus = 'all'; // all, pending, submitted, overdue

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  Future<void> _fetchAssignments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final assignments = await ApiService.instance.getCourseAssignments(
        widget.courseId,
        widget.token,
      );

      if (mounted) {
        setState(() {
          _assignments = List<Map<String, dynamic>>.from(assignments);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error fetching assignments: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredAssignments {
    if (_filterStatus == 'all') return _assignments;
    
    return _assignments.where((assignment) {
      final dueDate = _getDueDate(assignment);
      final now = DateTime.now();
      
      switch (_filterStatus) {
        case 'pending':
          return dueDate == null || now.isBefore(dueDate);
        case 'overdue':
          return dueDate != null && now.isAfter(dueDate);
        case 'submitted':
          // This would require submission status, which we'd need to fetch separately
          return false;
        default:
          return true;
      }
    }).toList();
  }

  DateTime? _getDueDate(Map<String, dynamic> assignment) {
    final duedate = assignment['duedate'];
    if (duedate == null || duedate == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(duedate * 1000);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No due date';
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText(Map<String, dynamic> assignment) {
    final dueDate = _getDueDate(assignment);
    final now = DateTime.now();
    
    if (dueDate == null) return 'No deadline';
    
    if (now.isAfter(dueDate)) {
      return 'Overdue';
    } else {
      final difference = dueDate.difference(now);
      if (difference.inDays > 0) {
        return '${difference.inDays} days left';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours left';
      } else {
        return '${difference.inMinutes} minutes left';
      }
    }
  }

  Color _getStatusColor(Map<String, dynamic> assignment) {
    final themeService = DynamicThemeService.instance;
    final dueDate = _getDueDate(assignment);
    final now = DateTime.now();
    
    if (dueDate == null) return themeService.getColor('textSecondary');
    
    if (now.isAfter(dueDate)) {
      return themeService.getColor('error');
    } else {
      final difference = dueDate.difference(now);
      if (difference.inDays <= 1) {
        return themeService.getColor('warning');
      } else {
        return themeService.getColor('success');
      }
    }
  }

  void _openAssignment(Map<String, dynamic> assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentSubmissionScreen(
          token: widget.token,
          assignment: assignment,
          courseId: widget.courseId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    
    return Scaffold(
      backgroundColor: themeService.getColor('background'),
      appBar: AppBar(
        title: Text('Assignments - ${widget.courseName}'),
        backgroundColor: themeService.getColor('primary'),
        foregroundColor: themeService.getColor('onPrimary'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(DynamicIconService.instance.refreshIcon),
            onPressed: _isLoading ? null : _fetchAssignments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    
    return Column(
      children: [
        _buildFilterSection(),
        Expanded(child: _buildAssignmentsList()),
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
          borderRadius: BorderRadius.circular(themeService.getBorderRadius('medium')),
          border: Border.all(
            color: themeService.getColor('error').withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              DynamicIconService.instance.errorIcon,
              size: 64,
              color: themeService.getColor('error'),
            ),
            SizedBox(height: themeService.getSpacing('md')),
            Text(
              'Failed to Load Assignments',
              style: textTheme.headlineSmall?.copyWith(
                color: themeService.getColor('error'),
              ),
            ),
            SizedBox(height: themeService.getSpacing('sm')),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            SizedBox(height: themeService.getSpacing('lg')),
            ElevatedButton.icon(
              onPressed: _fetchAssignments,
              icon: Icon(DynamicIconService.instance.refreshIcon),
              label: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final themeService = DynamicThemeService.instance;
    
    return Container(
      padding: EdgeInsets.all(themeService.getSpacing('md')),
      decoration: BoxDecoration(
        color: themeService.getColor('cardBackground'),
        border: Border(
          bottom: BorderSide(
            color: themeService.getColor('borderColor'),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_filteredAssignments.length} assignments',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: themeService.getSpacing('sm')),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                SizedBox(width: themeService.getSpacing('sm')),
                _buildFilterChip('Pending', 'pending'),
                SizedBox(width: themeService.getSpacing('sm')),
                _buildFilterChip('Overdue', 'overdue'),
                SizedBox(width: themeService.getSpacing('sm')),
                _buildFilterChip('Submitted', 'submitted'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final themeService = DynamicThemeService.instance;
    final isSelected = _filterStatus == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      backgroundColor: themeService.getColor('cardBackground'),
      selectedColor: themeService.getColor('primary').withOpacity(0.2),
      checkmarkColor: themeService.getColor('primary'),
      labelStyle: TextStyle(
        color: isSelected 
            ? themeService.getColor('primary')
            : themeService.getColor('textSecondary'),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected 
            ? themeService.getColor('primary')
            : themeService.getColor('borderColor'),
      ),
    );
  }

  Widget _buildAssignmentsList() {
    final filteredAssignments = _filteredAssignments;
    
    if (filteredAssignments.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(DynamicThemeService.instance.getSpacing('md')),
      itemCount: filteredAssignments.length,
      itemBuilder: (context, index) {
        final assignment = filteredAssignments[index];
        return _buildAssignmentCard(assignment);
      },
    );
  }

  Widget _buildEmptyState() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(themeService.getSpacing('lg')),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              DynamicIconService.instance.assignmentsIcon,
              size: 64,
              color: themeService.getColor('textSecondary').withOpacity(0.5),
            ),
            SizedBox(height: themeService.getSpacing('md')),
            Text(
              'No assignments found',
              style: textTheme.headlineSmall,
            ),
            SizedBox(height: themeService.getSpacing('sm')),
            Text(
              _filterStatus == 'all' 
                  ? 'No assignments available in this course'
                  : 'No assignments match the selected filter',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            if (_filterStatus != 'all') ...[
              SizedBox(height: themeService.getSpacing('lg')),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _filterStatus = 'all');
                },
                icon: Icon(DynamicIconService.instance.closeIcon),
                label: Text('Clear Filter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeService.getColor('cardBackground'),
                  foregroundColor: themeService.getColor('textPrimary'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    final dueDate = _getDueDate(assignment);
    final statusText = _getStatusText(assignment);
    final statusColor = _getStatusColor(assignment);
    
    return Card(
      margin: EdgeInsets.only(bottom: themeService.getSpacing('md')),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(themeService.getBorderRadius('large')),
      ),
      child: InkWell(
        onTap: () => _openAssignment(assignment),
        borderRadius: BorderRadius.circular(themeService.getBorderRadius('large')),
        child: Padding(
          padding: EdgeInsets.all(themeService.getSpacing('md')),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(themeService.getSpacing('sm')),
                    decoration: BoxDecoration(
                      color: themeService.getColor('primary').withOpacity(0.1),
                      borderRadius: BorderRadius.circular(themeService.getBorderRadius('small')),
                    ),
                    child: Icon(
                      DynamicIconService.instance.assignmentsIcon,
                      size: 20,
                      color: themeService.getColor('primary'),
                    ),
                  ),
                  SizedBox(width: themeService.getSpacing('md')),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment['name'] ?? 'Untitled Assignment',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: themeService.getColor('textPrimary'),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: themeService.getSpacing('xs')),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: themeService.getSpacing('sm'),
                            vertical: themeService.getSpacing('xs'),
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(themeService.getBorderRadius('small')),
                          ),
                          child: Text(
                            statusText,
                            style: textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    DynamicIconService.instance.forwardIcon,
                    size: 16,
                    color: themeService.getColor('textSecondary'),
                  ),
                ],
              ),
              
              // Description
              if (assignment['intro'] != null && assignment['intro'].toString().isNotEmpty) ...[
                SizedBox(height: themeService.getSpacing('md')),
                Text(
                  _cleanHtmlContent(assignment['intro']),
                  style: textTheme.bodyMedium?.copyWith(
                    color: themeService.getColor('textSecondary'),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              SizedBox(height: themeService.getSpacing('md')),
              
              // Footer with due date and submission info
              Row(
                children: [
                  Icon(
                    DynamicIconService.instance.calendarIcon,
                    size: 16,
                    color: themeService.getColor('textSecondary'),
                  ),
                  SizedBox(width: themeService.getSpacing('xs')),
                  Text(
                    'Due: ${_formatDate(dueDate)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: themeService.getColor('textSecondary'),
                    ),
                  ),
                  Spacer(),
                  _buildSubmissionTypeIndicator(assignment),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionTypeIndicator(Map<String, dynamic> assignment) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    final submissionType = _getSubmissionType(assignment);
    
    List<Widget> indicators = [];
    
    if (submissionType == 'online' || submissionType == 'both') {
      indicators.add(
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: themeService.getSpacing('xs'),
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(themeService.getBorderRadius('small')),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                DynamicIconService.instance.editIcon,
                size: 12,
                color: Colors.blue,
              ),
              SizedBox(width: 2),
              Text(
                'Text',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (submissionType == 'upload' || submissionType == 'both') {
      if (indicators.isNotEmpty) {
        indicators.add(SizedBox(width: themeService.getSpacing('xs')));
      }
      indicators.add(
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: themeService.getSpacing('xs'),
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(themeService.getBorderRadius('small')),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                DynamicIconService.instance.uploadIcon,
                size: 12,
                color: Colors.green,
              ),
              SizedBox(width: 2),
              Text(
                'File',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: indicators,
    );
  }

  String _getSubmissionType(Map<String, dynamic> assignment) {
    final configs = assignment['configs'] as List<dynamic>? ?? [];
    
    bool hasOnlineText = false;
    bool hasFile = false;
    
    for (var config in configs) {
      if (config['plugin'] == 'onlinetext' && 
          config['subtype'] == 'assignsubmission' && 
          config['name'] == 'enabled' && 
          config['value'] == '1') {
        hasOnlineText = true;
      }
      if (config['plugin'] == 'file' && 
          config['subtype'] == 'assignsubmission' && 
          config['name'] == 'enabled' && 
          config['value'] == '1') {
        hasFile = true;
      }
    }
    
    if (hasOnlineText && hasFile) return 'both';
    if (hasOnlineText) return 'online';
    if (hasFile) return 'upload';
    return 'both'; // Default fallback
  }

  String _cleanHtmlContent(String htmlString) {
    return htmlString
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}