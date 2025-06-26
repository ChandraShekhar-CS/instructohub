import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:InstructoHub/models/offline_submission_model.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';
import 'package:InstructoHub/services/enhanced_icon_service.dart';
import 'package:InstructoHub/services/sync_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';

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
  List<dynamic> _submittedFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSubmissionStatus();
  }

  Future<void> _checkSubmissionStatus({bool forceServerCheck = false}) async {
    if(mounted) setState(() => _isLoading = true);
    
    // Get the latest status from the service
    final status = await _syncService.getSubmissionStatus(widget.module['id'], token: widget.token);
    
    // After getting the status, if it's 'submitted' or if we just synced,
    // we must fetch the latest submission data from the server.
    if (status == SubmissionStatus.submitted || forceServerCheck) {
        try {
          final serverStatusResult = await ApiService.instance.getSubmissionStatus(widget.token, widget.module['id']);
          // This function will handle setting the state for the files
          _getSubmittedFiles(serverStatusResult);
        } catch (e) {
          print("Could not fetch submission status from server: $e");
          if(mounted) {
            setState(() {
              _submittedFiles = [];
            });
          }
        }
    } else {
        // If status is not submitted and we are not forcing a check, clear files.
        if (mounted) {
            setState(() {
                _submittedFiles = [];
            });
        }
    }
    
    // Finally, update the submission status and loading state
    if (mounted) {
      setState(() {
        _submissionStatus = status;
        _isLoading = false;
      });
    }
  }

  void _getSubmittedFiles(Map<String, dynamic> serverStatusResult) {
    List<dynamic> filesFound = [];
    try {
      final plugins = serverStatusResult['lastattempt']?['submission']?['plugins'] as List?;
      if (plugins != null) {
        final filePlugin = plugins.firstWhere((p) => p['type'] == 'file', orElse: () => null);
        if (filePlugin != null && (filePlugin['fileareas'] as List).isNotEmpty) {
           final files = filePlugin['fileareas'][0]['files'] as List?;
           if (files != null) {
             filesFound = files;
           }
        }
      }
    } catch(e) {
      print("Error parsing submitted files: $e");
    }

    // Update the state with what was found (or an empty list)
    if (mounted) {
      setState(() {
        _submittedFiles = filesFound;
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
      
      if (!widget.isOffline && widget.token.isNotEmpty) {
        await _syncService.processSyncQueue(widget.token);
      }

      if (mounted) {
        // Force a check against the server after attempting a sync
        _checkSubmissionStatus(forceServerCheck: true); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Submission saved. Attempting to sync...')),
        );
      }
    }
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return 'No due date';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _openResource(String url, BuildContext context) async {
    try {
      final Uri uri = Uri.parse(url);

      if (uri.scheme.startsWith('http')) {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw 'Could not launch $url';
        }
      } else if (uri.scheme == 'file') {
        final result = await OpenFilex.open(uri.path);
        if (result.type != ResultType.done) {
          throw 'Could not open file: ${result.message}';
        }
      } else {
        throw 'Unsupported URL scheme: ${uri.scheme}';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error opening file: ${e.toString()}'),
              backgroundColor: DynamicThemeService.instance.getColor('error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    final String moduleName = widget.module['name'] ?? 'Assignment';
    final assignmentData = widget.foundContent ?? widget.module;

    return Scaffold(
      appBar: AppBar(title: Text(moduleName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(themeService.getSpacing('sm')),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAssignmentHeader(context, assignmentData),
                    SizedBox(height: themeService.getSpacing('md')),
                    _buildSectionCard(
                      context: context,
                      title: 'Activity Instruction',
                      child: Html(
                        data: assignmentData['intro'] ?? "No instructions provided.",
                        style: {
                          "body": Style.fromTextStyle(
                              Theme.of(context).textTheme.bodyMedium!)
                        },
                      ),
                    ),
                    if (assignmentData['contents'] != null &&
                        (assignmentData['contents'] as List).isNotEmpty) ...[
                      SizedBox(height: themeService.getSpacing('md')),
                      _buildReferenceFiles(context, assignmentData['contents']),
                    ],
                    if (_submissionStatus == SubmissionStatus.submitted && _submittedFiles.isNotEmpty) ...[
                      SizedBox(height: themeService.getSpacing('md')),
                      _buildSubmittedFiles(context),
                    ],
                    SizedBox(height: themeService.getSpacing('md')),
                    _buildSubmissionSection(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAssignmentHeader(BuildContext context, dynamic assignmentData) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    final String moduleName = widget.module['name'] ?? 'Assignment';
    final String subtitle =
        assignmentData['subtitle'] ?? 'This is a sample assignment';

    return Container(
      padding: EdgeInsets.all(themeService.getSpacing('md')),
      decoration: BoxDecoration(
        color: Colors.orange[700],
        borderRadius: BorderRadius.circular(themeService.getBorderRadius('medium')),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(DynamicIconService.instance.getIcon('assign'),
              color: Colors.white, size: 28),
          SizedBox(width: themeService.getSpacing('md')),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(moduleName,
                    style: textTheme.titleLarge?.copyWith(color: Colors.white)),
                Text(subtitle,
                    style: textTheme.bodyMedium?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          SizedBox(width: themeService.getSpacing('md')),
          if (assignmentData['duedate'] != null && assignmentData['duedate'] != 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Due:', style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
                Text(_formatDate(assignmentData['duedate']),
                    style: textTheme.bodyMedium
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final themeService = DynamicThemeService.instance;
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(themeService.getBorderRadius('medium')),
      ),
      child: Padding(
        padding: EdgeInsets.all(themeService.getSpacing('md')),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(),
            SizedBox(height: themeService.getSpacing('xs')),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceFiles(BuildContext context, List<dynamic> files) {
    return _buildSectionCard(
        context: context,
        title: 'Reference Files',
        child: Column(
          children: files.map((file) {
            final String filename = file['filename'] ?? 'Unknown file';
            final String fileurl = file['fileurl'] ?? '';
            return ListTile(
              leading: Icon(
                DynamicIconService.instance.getIcon(_getFileExtension(filename)),
                color: Colors.orange[800],
              ),
              title: Text(filename),
              subtitle: Text(
                  '${_formatFileSize(file['filesize'] ?? 0)} • Added on ${_formatDate(file['timecreated'] ?? 0)}'),
              trailing: SizedBox(
                width: 110,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (fileurl.isNotEmpty) {
                      final urlToOpen =
                          widget.isOffline ? fileurl : '$fileurl&token=${widget.token}';
                      _openResource(urlToOpen, context);
                    }
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        ));
  }

  Widget _buildSubmittedFiles(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Submitted Files',
      child: Column(
        children: _submittedFiles.map((file) {
          final String filename = file['filename'] ?? 'Unknown file';
          final String fileurl = file['fileurl'] ?? '';
          return ListTile(
            leading: Icon(
              DynamicIconService.instance.getIcon(_getFileExtension(filename)),
              color: Colors.green[800],
            ),
            title: Text(filename),
            subtitle: Text(
                '${_formatFileSize(file['filesize'] ?? 0)} • Submitted on ${_formatDate(file['timemodified'] ?? 0)}'),
            trailing: SizedBox(
              width: 110,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (fileurl.isNotEmpty) {
                    final urlToOpen = '$fileurl?token=${widget.token}';
                    _openResource(urlToOpen, context);
                  }
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }
  
  String _getFileExtension(String filename) {
    try {
      return filename.split('.').last.toLowerCase();
    } catch (e) {
      return '';
    }
  }


  Widget _buildSubmissionSection(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    
    String statusText;
    String statusKey;

    switch (_submissionStatus) {
      case SubmissionStatus.submitted:
        statusText = 'Submitted';
        statusKey = 'success';
        break;
      case SubmissionStatus.pendingSync:
        statusText = 'Pending Sync';
        statusKey = 'warning';
        break;
      default:
        statusText = 'Not Submitted';
        statusKey = 'error';
    }


    return _buildSectionCard(
      context: context,
      title: 'Submission Requirements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Formats: ', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Text('Text + Files'),
            ],
          ),
          SizedBox(height: themeService.getSpacing('xs')),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Types: ', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Expanded(child: Text('.csv, .xlsx, .pdf, .docx, .doc, .ppt, .xls, .txt')),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Text('Status: ', style: textTheme.bodyMedium),
              _buildStatusChip(statusKey, statusText),
            ],
          ),
          SizedBox(height: themeService.getSpacing('sm')),
           if (_submissionStatus == SubmissionStatus.pendingSync)
              Text(
                'Your submission is saved locally and will sync automatically when online.',
                style: textTheme.bodySmall?.copyWith(color: themeService.getColor('textSecondary')),
              ),
          SizedBox(height: themeService.getSpacing('md')),
          Center(
            child: ElevatedButton.icon(
              onPressed: _submissionStatus != SubmissionStatus.submitted
                  ? _pickAndQueueFile
                  : null,
              icon: Icon(DynamicIconService.instance.getIcon('upload')),
              label: Text(_submissionStatus == SubmissionStatus.pendingSync
                  ? 'Change File'
                  : 'Add Submission'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: themeService.getSpacing('lg'),
                  vertical: themeService.getSpacing('md')
                ),
                textStyle: textTheme.titleMedium
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String statusKey, String text) {
    final themeService = DynamicThemeService.instance;
    final color = themeService.getColor(statusKey);
    return Chip(
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      labelStyle: TextStyle(color: color),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
