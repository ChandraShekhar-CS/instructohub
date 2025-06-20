import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../services/icon_service.dart';
import '../../theme/dynamic_app_theme.dart';

typedef AppTheme = DynamicAppTheme;

class AssignmentViewerScreen extends StatelessWidget {
  final dynamic module;
  final dynamic foundContent;
  final String token;

  const AssignmentViewerScreen({
    required this.module,
    this.foundContent,
    required this.token,
    Key? key,
  }) : super(key: key);

  String _formatDate(int timestamp) {
    if (timestamp == 0) return 'No due date';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final String moduleName = module['name'] ?? 'Assignment';
    final assignmentData = foundContent ?? module;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppTheme.buildDynamicAppBar(title: moduleName),
      body: foundContent == null
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(IconService.instance.getIcon('assign'), size: 80, color: AppTheme.textSecondary),
                    SizedBox(height: AppTheme.spacingLg),
                    Text('Assignment content not available', style: TextStyle(fontSize: AppTheme.fontSizeLg, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTheme.buildInfoCard(
                    iconKey: 'assign',
                    title: moduleName,
                    subtitle: (assignmentData['intro'] != null && assignmentData['intro'].isNotEmpty)
                        ? 'See description below'
                        : null,
                  ),
                  if (assignmentData['intro'] != null && assignmentData['intro'].isNotEmpty) ...[
                    SizedBox(height: AppTheme.spacingMd),
                    Html(
                      data: assignmentData['intro'],
                      style: {
                        "body": Style(
                          fontSize: FontSize(AppTheme.fontSizeBase),
                          color: AppTheme.textSecondary,
                          margin: Margins.zero,
                        ),
                      },
                    ),
                  ],
                  SizedBox(height: AppTheme.spacingMd),
                  if (assignmentData['duedate'] != null) ...[
                    _buildInfoCard(
                      iconKey: 'time',
                      title: 'Due Date',
                      content: _formatDate(assignmentData['duedate']),
                      color: assignmentData['duedate'] != 0 &&
                              DateTime.fromMillisecondsSinceEpoch(assignmentData['duedate'] * 1000).isBefore(DateTime.now())
                          ? AppTheme.error
                          : AppTheme.textSecondary,
                    ),
                    SizedBox(height: AppTheme.spacingSm),
                  ],
                  if (assignmentData['allowsubmissionsfromdate'] != null && assignmentData['allowsubmissionsfromdate'] != 0) ...[
                    _buildInfoCard(
                      iconKey: 'event',
                      title: 'Available From',
                      content: _formatDate(assignmentData['allowsubmissionsfromdate']),
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(height: AppTheme.spacingSm),
                  ],
                  if (assignmentData['grade'] != null) ...[
                    _buildInfoCard(
                      iconKey: 'grades',
                      title: 'Maximum Grade',
                      content: '${assignmentData['grade']} points',
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(height: AppTheme.spacingMd),
                  ],
                  _buildSubmissionCard(context),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required String iconKey,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(IconService.instance.getIcon(iconKey), color: color, size: 20),
          SizedBox(width: AppTheme.spacingMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSm,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                content,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeBase,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Submission',
              style: TextStyle(
                fontSize: AppTheme.fontSizeLg,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: AppTheme.spacingMd),
            AppTheme.buildActionButton(
              text: 'Submit Assignment',
              iconKey: 'upload',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Submission feature coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
