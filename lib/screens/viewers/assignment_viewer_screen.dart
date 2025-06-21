import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../models/offline_submission_model.dart';
import '../../services/icon_service.dart';
import '../../services/sync_service.dart';
import '../../theme/dynamic_app_theme.dart';

typedef AppTheme = DynamicAppTheme;

// MODIFIED: Converted to a StatefulWidget to manage submission state
class AssignmentViewerScreen extends StatefulWidget {
  final dynamic module;
  final dynamic foundContent;
  final String token;
  final bool isOffline;

  const AssignmentViewerScreen({
    required this.module,
    this.foundContent,
    required this.token,
    this.isOffline = false,
    Key? key,
  }) : super(key: key);

  @override
  _AssignmentViewerScreenState createState() => _AssignmentViewerScreenState();
}

class _AssignmentViewerScreenState extends State<AssignmentViewerScreen> {
  final SyncService _syncService = SyncService();
  SubmissionStatus _submissionStatus = SubmissionStatus.notSubmitted;
  String? _pickedFilePath;

  @override
  void initState() {
    super.initState();
    _checkSubmissionStatus();
  }

  Future<void> _checkSubmissionStatus() async {
    final status = await _syncService.getSubmissionStatus(widget.module['id']);
    if (mounted) {
      setState(() {
        _submissionStatus = status;
      });
    }
  }

  Future<void> _pickAndQueueFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      // FIXED: Added robust parsing for the contextid to prevent crashes.
      int? contextId;
      final rawContextId = widget.module['contextid'];
      if (rawContextId is int) {
        contextId = rawContextId;
      } else if (rawContextId is String) {
        contextId = int.tryParse(rawContextId);
      }

      final submission = OfflineSubmission(
        assignmentId: widget.module['id'],
        filePath: result.files.single.path!,
        contextId: contextId,
      );
      
      await _syncService.queueAssignmentSubmission(submission);
      
      if(mounted) {
        setState(() {
          _pickedFilePath = result.files.single.path;
          _submissionStatus = SubmissionStatus.pendingSync;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission saved and will sync when online.')),
        );
      }

    } else {
      // User canceled the picker
    }
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return 'No due date';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final String moduleName = widget.module['name'] ?? 'Assignment';
    final assignmentData = widget.foundContent ?? widget.module;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppTheme.buildDynamicAppBar(title: moduleName),
      body: SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTheme.buildInfoCard(
                    iconKey: 'assign',
                    title: moduleName,
                    subtitle: 'Review the assignment details below',
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
                      iconKey: 'event_available',
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
          Expanded(
            child: Column(
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
              'Your Submission',
              style: TextStyle(
                fontSize: AppTheme.fontSizeLg,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: AppTheme.spacingMd),
            if (_submissionStatus == SubmissionStatus.submitted)
              AppTheme.buildStatusChip('success', 'Submitted'),
            if (_submissionStatus == SubmissionStatus.pendingSync) ...[
                AppTheme.buildStatusChip('warning', 'Pending Sync'),
                SizedBox(height: AppTheme.spacingSm),
                Text(
                  _pickedFilePath != null 
                    ? 'File ready for upload: ${_pickedFilePath!.split('/').last}'
                    : 'This submission will be uploaded automatically when you are back online.', 
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontSizeXs)
                ),
                SizedBox(height: AppTheme.spacingMd),
            ],
            AppTheme.buildActionButton(
              text: _submissionStatus == SubmissionStatus.pendingSync ? 'Change File' : 'Add Submission',
              iconKey: 'upload',
              isEnabled: _submissionStatus != SubmissionStatus.submitted,
              onPressed: _pickAndQueueFile,
            ),
          ],
        ),
      ),
    );
  }
}
