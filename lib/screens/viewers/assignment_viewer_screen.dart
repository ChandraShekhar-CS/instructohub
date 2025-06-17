import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../theme/app_theme.dart';

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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(moduleName),
        backgroundColor: AppTheme.secondary2,
        foregroundColor: AppTheme.offwhite,
      ),
      body: foundContent == null 
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 80, color: AppTheme.primary2),
                  const SizedBox(height: 20),
                  Text('Assignment content not available', 
                       style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
          )
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary2.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.secondary2.withOpacity(0.2))
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary2.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: const Icon(Icons.assignment_outlined, color: AppTheme.secondary2, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                moduleName,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppTheme.primary1,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (assignmentData['intro'] != null && assignmentData['intro'].isNotEmpty) ...[
                          const SizedBox(height: 12),
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
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (assignmentData['duedate'] != null) ...[
                    _buildInfoCard(
                      icon: Icons.schedule,
                      title: 'Due Date',
                      content: _formatDate(assignmentData['duedate']),
                      color: assignmentData['duedate'] != 0 && 
                             DateTime.fromMillisecondsSinceEpoch(assignmentData['duedate'] * 1000).isBefore(DateTime.now())
                             ? Colors.red : AppTheme.primary2,
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (assignmentData['allowsubmissionsfromdate'] != null && assignmentData['allowsubmissionsfromdate'] != 0) ...[
                    _buildInfoCard(
                      icon: Icons.start,
                      title: 'Available From',
                      content: _formatDate(assignmentData['allowsubmissionsfromdate']),
                      color: AppTheme.primary2,
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (assignmentData['grade'] != null) ...[
                    _buildInfoCard(
                      icon: Icons.grade,
                      title: 'Maximum Grade',
                      content: '${assignmentData['grade']} points',
                      color: AppTheme.primary2,
                    ),
                    const SizedBox(height: 8),
                  ],

                  _buildSubmissionCard(assignmentData),
                  
                  const SizedBox(height: 12),
                  if (assignmentData['activity'] != null && assignmentData['activity']['instructions'] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 10,
                          )
                        ]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instructions',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.primary1,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Html(
                            data: assignmentData['activity']['instructions'],
                            style: {
                              "body": Style(
                                fontSize: FontSize(AppTheme.fontSizeBase),
                                color: AppTheme.primary1,
                              ),
                              "p": Style(lineHeight: const LineHeight(1.5)),
                              "a": Style(
                                color: AppTheme.secondary2,
                                textDecoration: TextDecoration.none,
                              ),
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
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
                  color: AppTheme.primary1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(dynamic assignmentData) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submission Details',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLg,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary1,
            ),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) => ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Submission feature coming soon!')),
                );
              },
            icon: const Icon(Icons.upload_file),
            label: const Text('Submit Assignment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary2,
              foregroundColor: AppTheme.offwhite,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          ),
        ],
      ),
    );
  }
}

  @override
  bool get wantKeepAlive => true; // Keep the state alive when navigating away
