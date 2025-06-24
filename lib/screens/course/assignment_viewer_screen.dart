import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../models/offline_submission_model.dart';
import '../../services/dynamic_theme_service.dart';
import '../../services/enhanced_icon_service.dart';
import '../../services/sync_service.dart';

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

      if (mounted) {
        setState(() {
          _pickedFilePath = result.files.single.path;
          _submissionStatus = SubmissionStatus.pendingSync;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Submission saved and will sync when online.')),
        );
      }
    }
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return 'No due date';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    final String moduleName = widget.module['name'] ?? 'Assignment';
    final assignmentData = widget.foundContent ?? widget.module;

    return Scaffold(
      appBar: AppBar(title: Text(moduleName)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(themeService.getSpacing('md')),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              context: context,
              iconKey: 'assign',
              title: moduleName,
              content: 'Review the assignment details below',
              color: themeService.getColor('textPrimary'),
              isSubtitle: true,
            ),
            if (assignmentData['intro'] != null &&
                assignmentData['intro'].isNotEmpty) ...[
              SizedBox(height: themeService.getSpacing('md')),
              Html(
                data: assignmentData['intro'],
                style: {"body": Style.fromTextStyle(textTheme.bodyMedium!)},
              ),
            ],
            SizedBox(height: themeService.getSpacing('md')),
            if (assignmentData['duedate'] != null) ...[
              _buildInfoCard(
                context: context,
                iconKey: 'time',
                title: 'Due Date',
                content: _formatDate(assignmentData['duedate']),
                color: assignmentData['duedate'] != 0 &&
                        DateTime.fromMillisecondsSinceEpoch(
                                assignmentData['duedate'] * 1000)
                            .isBefore(DateTime.now())
                    ? themeService.getColor('error')
                    : themeService.getColor('textSecondary'),
              ),
              SizedBox(height: themeService.getSpacing('sm')),
            ],
            if (assignmentData['allowsubmissionsfromdate'] != null &&
                assignmentData['allowsubmissionsfromdate'] != 0) ...[
              _buildInfoCard(
                context: context,
                iconKey: 'event_available',
                title: 'Available From',
                content:
                    _formatDate(assignmentData['allowsubmissionsfromdate']),
                color: themeService.getColor('textSecondary'),
              ),
              SizedBox(height: themeService.getSpacing('sm')),
            ],
            if (assignmentData['grade'] != null) ...[
              _buildInfoCard(
                context: context,
                iconKey: 'grades',
                title: 'Maximum Grade',
                content: '${assignmentData['grade']} points',
                color: themeService.getColor('textSecondary'),
              ),
              SizedBox(height: themeService.getSpacing('md')),
            ],
            _buildSubmissionCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String iconKey,
    required String title,
    required String content,
    required Color color,
    bool isSubtitle = false,
  }) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(themeService.getSpacing('md')),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius:
            BorderRadius.circular(themeService.getBorderRadius('medium')),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(DynamicIconService.instance.getIcon(iconKey),
              color: color, size: 20),
          SizedBox(width: themeService.getSpacing('md')),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: isSubtitle
                      ? textTheme.titleMedium
                      : textTheme.bodySmall?.copyWith(
                          color: color, fontWeight: FontWeight.w600),
                ),
                Text(
                  content,
                  style: isSubtitle
                      ? textTheme.bodyMedium
                      : textTheme.bodyLarge?.copyWith(
                          color: themeService.getColor('textPrimary'),
                          fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(themeService.getSpacing('md')),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your Submission', style: textTheme.titleLarge),
            SizedBox(height: themeService.getSpacing('md')),
            if (_submissionStatus == SubmissionStatus.submitted)
              _buildStatusChip('success', 'Submitted'),
            if (_submissionStatus == SubmissionStatus.pendingSync) ...[
              _buildStatusChip('warning', 'Pending Sync'),
              SizedBox(height: themeService.getSpacing('sm')),
              Text(
                _pickedFilePath != null
                    ? 'File ready for upload: ${_pickedFilePath!.split('/').last}'
                    : 'This submission will be uploaded automatically when you are back online.',
                style: textTheme.bodySmall,
              ),
              SizedBox(height: themeService.getSpacing('md')),
            ],
            ElevatedButton.icon(
              onPressed: _submissionStatus != SubmissionStatus.submitted
                  ? _pickAndQueueFile
                  : null,
              icon: Icon(DynamicIconService.instance.getIcon('upload')),
              label: Text(_submissionStatus == SubmissionStatus.pendingSync
                  ? 'Change File'
                  : 'Add Submission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String statusKey, String text) {
    final themeService = DynamicThemeService.instance;
    final color = themeService.getColor(statusKey);
    return Chip(
      label: Text(text),
      labelStyle: TextStyle(color: color),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }
}
