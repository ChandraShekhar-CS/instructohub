import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:InstructoHub/services/api_service.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';
import 'package:InstructoHub/services/enhanced_icon_service.dart';

class AssignmentSubmissionScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> assignment;
  final String courseId;

  const AssignmentSubmissionScreen({
    required this.token,
    required this.assignment,
    required this.courseId,
    Key? key,
  }) : super(key: key);

  @override
  _AssignmentSubmissionScreenState createState() =>
      _AssignmentSubmissionScreenState();
}

class _AssignmentSubmissionScreenState
    extends State<AssignmentSubmissionScreen> {
  final TextEditingController _onlineTextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _showTooltip = false;
  String? _submissionType;
  Map<String, dynamic>? _submissionStatus;
  List<File> _selectedFiles = [];
  List<String> _allowedFileTypes = [];
  int _maxFileSize = 512 * 1024 * 1024; // 512MB

  @override
  void initState() {
    super.initState();
    _initializeAssignment();
    _loadSubmissionStatus();
  }

  @override
  void dispose() {
    _onlineTextController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeAssignment() {
    _submissionType = _getSubmissionType();
    _allowedFileTypes = _getAllowedFileTypes();
    setState(() {});
  }

  String _getSubmissionType() {
    final configs = widget.assignment['configs'] as List<dynamic>? ?? [];

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

  List<String> _getAllowedFileTypes() {
    final configs = widget.assignment['configs'] as List<dynamic>? ?? [];

    for (var config in configs) {
      if (config['plugin'] == 'file' &&
          config['subtype'] == 'assignsubmission' &&
          config['name'] == 'filetypeslist' &&
          config['value'] != null) {
        return config['value']
            .toString()
            .split(',')
            .map((type) => type.trim())
            .where((type) => type.isNotEmpty)
            .toList();
      }
    }
    return []; // Allow all file types if not specified
  }

  Future<void> _loadSubmissionStatus() async {
    setState(() => _isLoading = true);

    try {
      final status = await ApiService.instance
          .getSubmissionStatus(widget.token, widget.assignment['id']);

      if (mounted) {
        setState(() {
          _submissionStatus = status;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error loading submission status: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getSubmissionLabel() {
    switch (_submissionType) {
      case 'online':
        return 'Please submit your assignment using the text editor below.';
      case 'upload':
        return 'Please upload a file to submit your assignment.';
      case 'both':
        return 'Please submit both a text response and a file for this assignment.';
      default:
        return 'Please complete your assignment submission.';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    int i = (bytes / k).floor();
    i = i > 3 ? 3 : i;
    return '${(bytes / (k * i)).toStringAsFixed(2)} ${sizes[i]}';
  }

  String _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'ppt':
      case 'pptx':
        return '📊';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return '🖼️';
      case 'mp4':
      case 'avi':
      case 'mov':
        return '🎥';
      case 'mp3':
      case 'wav':
        return '🎵';
      default:
        return '📎';
    }
  }

  bool _validateFile(File file) {
    // Check file size
    final fileSize = file.lengthSync();
    if (fileSize > _maxFileSize) {
      _showErrorSnackBar('File size exceeds maximum allowed size of 512MB');
      return false;
    }

    // Check file type if restrictions exist
    if (_allowedFileTypes.isNotEmpty) {
      final fileName = file.path.split('/').last;
      final extension = '.' + fileName.split('.').last.toLowerCase();

      final isValidType =
          _allowedFileTypes.any((type) => type.toLowerCase() == extension);

      if (!isValidType) {
        _showErrorSnackBar(
            'File type not allowed. Allowed types: ${_allowedFileTypes.join(', ')}');
        return false;
      }
    }

    return true;
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: _submissionType == 'upload',
        type: _allowedFileTypes.isNotEmpty ? FileType.custom : FileType.any,
        allowedExtensions: _allowedFileTypes.isNotEmpty
            ? _allowedFileTypes.map((e) => e.replaceFirst('.', '')).toList()
            : null,
      );

      if (result != null && result.files.isNotEmpty) {
        List<File> validFiles = [];

        for (var platformFile in result.files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            if (_validateFile(file)) {
              validFiles.add(file);
            }
          }
        }

        if (validFiles.isNotEmpty) {
          setState(() {
            if (_submissionType == 'upload') {
              _selectedFiles.addAll(validFiles);
            } else {
              _selectedFiles = [
                validFiles.first
              ]; // Only one file for 'both' type
            }
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting files: ${e.toString()}');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submitAssignment() async {
    if (_isSubmitting) return;

    // Validation
    final hasOnlineText = _onlineTextController.text.trim().isNotEmpty;
    final hasFiles = _selectedFiles.isNotEmpty;

    if ((_submissionType == 'online' && !hasOnlineText) ||
        (_submissionType == 'upload' && !hasFiles) ||
        (_submissionType == 'both' && (!hasOnlineText || !hasFiles))) {
      String message = '';
      if (_submissionType == 'online') {
        message = 'Please enter your assignment submission text.';
      } else if (_submissionType == 'upload') {
        message = 'Please select at least one file to upload.';
      } else {
        message = 'Please provide both text submission and file(s).';
      }

      _showErrorSnackBar(message);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final assignmentId = widget.assignment['id'];

      // Test assignment submission capabilities first
      print("🧪 Testing assignment submission capabilities...");
      final testResults = await ApiService.instance
          .testAssignmentSubmissionCapabilities(widget.token, assignmentId);

      print("📊 Test results: $testResults");

      // Show any warnings but continue if basic capabilities are available
      if (testResults['warnings'] != null &&
          (testResults['warnings'] as List).isNotEmpty) {
        final warnings = testResults['warnings'] as List<String>;
        print("⚠️ Capabilities warnings: ${warnings.join(', ')}");
      }

      // Try multiple submission methods in order of preference
      bool submissionSuccessful = false;
      String lastError = '';

      // Method 1: Enhanced submission (preferred)
      if (!submissionSuccessful) {
        try {
          print("🚀 Attempting enhanced submission method...");

          if (_submissionType == 'online') {
            await ApiService.instance.submitOnlineTextOnly(
              token: widget.token,
              assignmentId: assignmentId,
              onlineText: _onlineTextController.text.trim(),
            );
          } else if (_submissionType == 'upload') {
            await ApiService.instance.submitFileOnly(
              token: widget.token,
              assignmentId: assignmentId,
              file: _selectedFiles.first,
            );
          } else {
            await ApiService.instance.submitAssignmentDirectly(
              token: widget.token,
              assignmentId: assignmentId,
              onlineText: _onlineTextController.text.trim(),
              file: _selectedFiles.first,
            );
          }

          submissionSuccessful = true;
          print("✅ Enhanced submission successful!");
        } catch (e) {
          lastError = e.toString();
          print("❌ Enhanced submission failed: $e");
        }
      }

      // Method 2: Alternative submission (if enhanced fails)
      if (!submissionSuccessful) {
        try {
          print("🔄 Attempting alternative submission method...");

          await ApiService.instance.submitAssignmentAlternative(
            token: widget.token,
            assignmentId: assignmentId,
            onlineText: _onlineTextController.text.trim(),
            file: hasFiles ? _selectedFiles.first : null,
          );

          submissionSuccessful = true;
          print("✅ Alternative submission successful!");
        } catch (e) {
          lastError = e.toString();
          print("❌ Alternative submission failed: $e");
        }
      }

      // Method 3: Manual submission (last resort)
      if (!submissionSuccessful) {
        try {
          print("🆘 Attempting manual submission method (last resort)...");

          await ApiService.instance.submitAssignmentManual(
            token: widget.token,
            assignmentId: assignmentId,
            onlineText: _onlineTextController.text.trim(),
            file: hasFiles ? _selectedFiles.first : null,
          );

          submissionSuccessful = true;
          print("✅ Manual submission successful!");
        } catch (e) {
          lastError = e.toString();
          print("❌ Manual submission failed: $e");
        }
      }

      if (submissionSuccessful) {
        if (mounted) {
          _showSuccessSnackBar('Assignment submitted successfully!');
          _onlineTextController.clear();
          setState(() {
            _selectedFiles.clear();
          });
          await _loadSubmissionStatus(); // Refresh status
          _showSubmissionSuccessDialog();
        }
      } else {
        throw Exception(
            lastError.isNotEmpty ? lastError : 'All submission methods failed');
      }
    } catch (e) {
      print("❌ All submission methods failed: $e");
      if (mounted) {
        String errorMessage = _getReadableErrorMessage(e.toString());
        _showDetailedErrorDialog(errorMessage, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getReadableErrorMessage(String errorMessage) {
    String cleanMessage = errorMessage.replaceAll('Exception: ', '');

    // Enhanced error message mapping
    if (cleanMessage.contains('Could not get a draft item ID') ||
        cleanMessage.contains('start_submission')) {
      return 'Assignment submission initialization failed. This assignment may not be configured for submissions or may be closed.';
    } else if (cleanMessage.contains('Invalid token') ||
        cleanMessage.contains('token')) {
      return 'Your session has expired. Please log out and log back in.';
    } else if (cleanMessage.contains('Assignment not found') ||
        cleanMessage.contains('assignmentid')) {
      return 'This assignment is no longer available or you do not have permission to submit.';
    } else if (cleanMessage.contains('Submission not allowed') ||
        cleanMessage.contains('duedate') ||
        cleanMessage.contains('cutoffdate')) {
      return 'Submissions are not currently allowed. Check if the assignment is still open for submissions.';
    } else if (cleanMessage.contains('File upload failed') ||
        cleanMessage.contains('upload')) {
      return 'File upload failed. Check your internet connection and file size (max 512MB).';
    } else if (cleanMessage.contains('Network') ||
        cleanMessage.contains('connection') ||
        cleanMessage.contains('timeout')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (cleanMessage.contains('save_submission') ||
        cleanMessage.contains('submit_for_grading')) {
      return 'Submission failed to save. The assignment may not be accepting submissions at this time.';
    } else if (cleanMessage.contains('User ID not found') ||
        cleanMessage.contains('userid')) {
      return 'User identification failed. Please log out and log back in.';
    } else {
      // Truncate very long error messages
      if (cleanMessage.length > 120) {
        cleanMessage = cleanMessage.substring(0, 120) + '...';
      }
      return 'Submission failed: $cleanMessage';
    }
  }

  // Enhanced submission method with better error handling:
  Future<void> _submitAssignmentEnhanced() async {
    if (_isSubmitting) return;

    // Validation
    if (!_validateSubmissionContent()) return;

    setState(() => _isSubmitting = true);

    try {
      final assignmentId = widget.assignment['id'];

      // Pre-submission validation
      final validation = await ApiService.instance.validateAssignmentSubmission(
        token: widget.token,
        assignmentId: assignmentId,
        onlineText: _onlineTextController.text.trim(),
        file: _selectedFiles.isNotEmpty ? _selectedFiles.first : null,
      );

      if (!validation['isValid']) {
        final errors = validation['errors'] as List<String>;
        throw Exception('Validation failed: ${errors.join(', ')}');
      }

      // Try submission methods in order of reliability
      bool success = await _trySubmissionMethods(assignmentId);

      if (success) {
        _handleSubmissionSuccess();
      } else {
        throw Exception('All submission methods failed');
      }
    } catch (e) {
      _handleSubmissionError(e);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  bool _validateSubmissionContent() {
    final hasOnlineText = _onlineTextController.text.trim().isNotEmpty;
    final hasFiles = _selectedFiles.isNotEmpty;

    String? errorMessage;

    switch (_submissionType) {
      case 'online':
        if (!hasOnlineText)
          errorMessage = 'Please enter your assignment submission text.';
        break;
      case 'upload':
        if (!hasFiles)
          errorMessage = 'Please select at least one file to upload.';
        break;
      case 'both':
        if (!hasOnlineText || !hasFiles) {
          errorMessage = 'Please provide both text submission and file(s).';
        }
        break;
    }

    if (errorMessage != null) {
      _showErrorSnackBar(errorMessage);
      return false;
    }

    return true;
  }

  Future<bool> _trySubmissionMethods(int assignmentId) async {
    final methods = [
      () => _tryEnhancedSubmission(assignmentId),
      () => _tryAlternativeSubmission(assignmentId),
      () => _tryManualSubmission(assignmentId),
    ];

    for (final method in methods) {
      try {
        await method();
        return true;
      } catch (e) {
        print('Submission method failed: $e');
        // Continue to next method
      }
    }

    return false;
  }

  Future<void> _tryEnhancedSubmission(int assignmentId) async {
    if (_submissionType == 'online') {
      await ApiService.instance.submitOnlineTextOnly(
        token: widget.token,
        assignmentId: assignmentId,
        onlineText: _onlineTextController.text.trim(),
      );
    } else if (_submissionType == 'upload') {
      await ApiService.instance.submitFileOnly(
        token: widget.token,
        assignmentId: assignmentId,
        file: _selectedFiles.first,
      );
    } else {
      await ApiService.instance.submitAssignmentDirectly(
        token: widget.token,
        assignmentId: assignmentId,
        onlineText: _onlineTextController.text.trim(),
        file: _selectedFiles.first,
      );
    }
  }

  Future<void> _tryAlternativeSubmission(int assignmentId) async {
    await ApiService.instance.submitAssignmentAlternative(
      token: widget.token,
      assignmentId: assignmentId,
      onlineText: _onlineTextController.text.trim(),
      file: _selectedFiles.isNotEmpty ? _selectedFiles.first : null,
    );
  }

  Future<void> _tryManualSubmission(int assignmentId) async {
    await ApiService.instance.submitAssignmentManual(
      token: widget.token,
      assignmentId: assignmentId,
      onlineText: _onlineTextController.text.trim(),
      file: _selectedFiles.isNotEmpty ? _selectedFiles.first : null,
    );
  }

  void _handleSubmissionSuccess() {
    if (mounted) {
      _showSuccessSnackBar('Assignment submitted successfully!');
      _onlineTextController.clear();
      setState(() => _selectedFiles.clear());
      _loadSubmissionStatus();
      _showSubmissionSuccessDialog();
    }
  }

  void _handleSubmissionError(dynamic error) {
    if (mounted) {
      final userMessage = _getReadableErrorMessage(error.toString());
      _showDetailedErrorDialog(userMessage, error.toString());
    }
  }

  void _showDetailedErrorDialog(String userMessage, String technicalError) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final themeService = DynamicThemeService.instance;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(themeService.getBorderRadius('large')),
          ),
          title: Row(
            children: [
              Icon(
                DynamicIconService.instance.errorIcon,
                color: themeService.getColor('error'),
                size: 28,
              ),
              SizedBox(width: themeService.getSpacing('sm')),
              Text('Submission Failed'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userMessage),
              SizedBox(height: themeService.getSpacing('md')),
              ExpansionTile(
                title: Text(
                  'Technical Details',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(themeService.getSpacing('sm')),
                    decoration: BoxDecoration(
                      color: themeService.getColor('backgroundLight'),
                      borderRadius: BorderRadius.circular(
                          themeService.getBorderRadius('small')),
                    ),
                    child: Text(
                      technicalError,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: themeService.getSpacing('md')),
              Container(
                padding: EdgeInsets.all(themeService.getSpacing('sm')),
                decoration: BoxDecoration(
                  color: themeService.getColor('info').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                      themeService.getBorderRadius('small')),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Troubleshooting Tips:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: themeService.getSpacing('xs')),
                    Text(
                      '• Check your internet connection\n'
                      '• Verify the assignment is still accepting submissions\n'
                      '• Try submitting with smaller files\n'
                      '• Contact your instructor if the problem persists',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitAssignment(); // Retry submission
              },
              child: Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadReferenceFile(Map<String, dynamic> file) async {
    try {
      final url = file['fileurl'] + '?token=${widget.token}';
      if (await canLaunch(url)) {
        await launch(url);
        _showSuccessSnackBar('Downloading ${file['filename']}...');
      } else {
        _showErrorSnackBar('Cannot download file. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Download failed: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: DynamicThemeService.instance.getColor('error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: DynamicThemeService.instance.getColor('success'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSubmissionSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final themeService = DynamicThemeService.instance;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(themeService.getBorderRadius('large')),
          ),
          title: Row(
            children: [
              Icon(
                DynamicIconService.instance.successIcon,
                color: themeService.getColor('success'),
                size: 28,
              ),
              SizedBox(width: themeService.getSpacing('sm')),
              Text('Submission Complete'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your assignment has been submitted successfully!'),
              SizedBox(height: themeService.getSpacing('md')),
              Container(
                padding: EdgeInsets.all(themeService.getSpacing('sm')),
                decoration: BoxDecoration(
                  color: themeService.getColor('success').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                      themeService.getBorderRadius('small')),
                ),
                child: Row(
                  children: [
                    Icon(
                      DynamicIconService.instance.infoIcon,
                      size: 16,
                      color: themeService.getColor('success'),
                    ),
                    SizedBox(width: themeService.getSpacing('xs')),
                    Expanded(
                      child: Text(
                        'You can view your submission status in the assignment details.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context)
                    .pop(); // Go back to course/assignments list
              },
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: themeService.getColor('background'),
      appBar: AppBar(
        title: Text('Assignment Submission'),
        backgroundColor: themeService.getColor('primary'),
        foregroundColor: themeService.getColor('onPrimary'),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _buildAssignmentHeader(),
                  _buildAssignmentContent(),
                ],
              ),
            ),
    );
  }

  Widget _buildAssignmentHeader() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(themeService.getSpacing('lg')),
      decoration: BoxDecoration(
        color: themeService.getColor('primary'),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(themeService.getBorderRadius('large')),
          bottomRight: Radius.circular(themeService.getBorderRadius('large')),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(themeService.getSpacing('sm')),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(
                      themeService.getBorderRadius('medium')),
                ),
                child: Icon(
                  DynamicIconService.instance.assignmentsIcon,
                  color: themeService.getColor('onPrimary'),
                  size: 20,
                ),
              ),
              SizedBox(width: themeService.getSpacing('md')),
              Expanded(
                child: Text(
                  widget.assignment['name'] ?? 'Assignment',
                  style: textTheme.headlineSmall?.copyWith(
                    color: themeService.getColor('onPrimary'),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (widget.assignment['intro'] != null) ...[
            SizedBox(height: themeService.getSpacing('md')),
            Text(
              widget.assignment['intro'],
              style: textTheme.bodyMedium?.copyWith(
                color: themeService.getColor('onPrimary').withOpacity(0.9),
              ),
            ),
          ],
          SizedBox(height: themeService.getSpacing('md')),
          Row(
            children: [
              Icon(
                DynamicIconService.instance.calendarIcon,
                color: themeService.getColor('onPrimary'),
                size: 16,
              ),
              SizedBox(width: themeService.getSpacing('sm')),
              Text(
                'Due: ${_formatDate(widget.assignment['duedate'])}',
                style: textTheme.bodyMedium?.copyWith(
                  color: themeService.getColor('onPrimary'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentContent() {
    final themeService = DynamicThemeService.instance;

    return Padding(
      padding: EdgeInsets.all(themeService.getSpacing('lg')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActivityInstructions(),
          SizedBox(height: themeService.getSpacing('lg')),
          _buildReferenceFiles(),
          SizedBox(height: themeService.getSpacing('lg')),
          _buildSubmissionRequirements(),
          SizedBox(height: themeService.getSpacing('lg')),
          _buildSubmissionSection(),
        ],
      ),
    );
  }

  Widget _buildActivityInstructions() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return themeService.buildCleanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Activity Instructions',
                style: textTheme.titleLarge?.copyWith(
                  color: themeService.getColor('textPrimary'),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: themeService.getSpacing('sm')),
              GestureDetector(
                onTapDown: (_) => setState(() => _showTooltip = true),
                onTapUp: (_) => setState(() => _showTooltip = false),
                onTapCancel: () => setState(() => _showTooltip = false),
                child: Stack(
                  children: [
                    Icon(
                      DynamicIconService.instance.infoIcon,
                      size: 16,
                      color: themeService.getColor('textSecondary'),
                    ),
                    if (_showTooltip)
                      Positioned(
                        left: 20,
                        top: -50,
                        child: Container(
                          padding:
                              EdgeInsets.all(themeService.getSpacing('sm')),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(
                                themeService.getBorderRadius('small')),
                          ),
                          child: Text(
                            'Requirements:\n• Complete all sections thoroughly\n• Provide detailed explanations\n• Submit before deadline',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: themeService.getSpacing('md')),
          Container(
            padding: EdgeInsets.all(themeService.getSpacing('md')),
            decoration: BoxDecoration(
              color: themeService.getColor('backgroundLight'),
              borderRadius:
                  BorderRadius.circular(themeService.getBorderRadius('medium')),
              border: Border.all(
                color: themeService.getColor('borderColor'),
              ),
            ),
            child: Text(
              widget.assignment['activity'] ??
                  widget.assignment['intro'] ??
                  'Please complete this assignment according to the provided instructions.',
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceFiles() {
    final introAttachments =
        widget.assignment['introattachments'] as List<dynamic>? ?? [];

    if (introAttachments.isEmpty) return SizedBox.shrink();

    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return themeService.buildCleanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                DynamicIconService.instance.fileIcon,
                size: 16,
                color: themeService.getColor('primary'),
              ),
              SizedBox(width: themeService.getSpacing('sm')),
              Text(
                'Reference Files',
                style: textTheme.titleLarge?.copyWith(
                  color: themeService.getColor('textPrimary'),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: themeService.getSpacing('sm')),
          Text(
            'Download the files provided by your instructor for this assignment.',
            style: textTheme.bodySmall?.copyWith(
              color: themeService.getColor('textSecondary'),
            ),
          ),
          SizedBox(height: themeService.getSpacing('md')),
          ...introAttachments
              .map((file) => _buildReferenceFileItem(file))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildReferenceFileItem(Map<String, dynamic> file) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.only(bottom: themeService.getSpacing('sm')),
      padding: EdgeInsets.all(themeService.getSpacing('md')),
      decoration: BoxDecoration(
        color: themeService.getColor('backgroundLight'),
        borderRadius:
            BorderRadius.circular(themeService.getBorderRadius('medium')),
        border: Border.all(
          color: themeService.getColor('borderColor'),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: themeService.getColor('primaryLight').withOpacity(0.2),
              borderRadius:
                  BorderRadius.circular(themeService.getBorderRadius('medium')),
            ),
            child: Center(
              child: Text(
                _getFileIcon(file['filename'] ?? ''),
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          SizedBox(width: themeService.getSpacing('md')),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file['filename'] ?? 'File',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _formatFileSize(file['filesize'] ?? 0),
                      style: textTheme.bodySmall?.copyWith(
                        color: themeService.getColor('textSecondary'),
                      ),
                    ),
                    Text(' • ', style: textTheme.bodySmall),
                    Text(
                      (file['mimetype'] ?? 'file')
                          .split('/')
                          .last
                          .toUpperCase(),
                      style: textTheme.bodySmall?.copyWith(
                        color: themeService.getColor('textSecondary'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: themeService.getSpacing('sm')),
          ElevatedButton.icon(
            onPressed: () => _downloadReferenceFile(file),
            icon: Icon(DynamicIconService.instance.downloadIcon, size: 16),
            label: Text('Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeService.getColor('primary'),
              foregroundColor: themeService.getColor('onPrimary'),
              padding: EdgeInsets.symmetric(
                horizontal: themeService.getSpacing('md'),
                vertical: themeService.getSpacing('sm'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionRequirements() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    final allowedTypesString = _allowedFileTypes.isNotEmpty
        ? _allowedFileTypes.join(', ')
        : 'All file types';

    return Container(
      padding: EdgeInsets.all(themeService.getSpacing('md')),
      decoration: BoxDecoration(
        color: themeService.getColor('primaryLight').withOpacity(0.1),
        borderRadius:
            BorderRadius.circular(themeService.getBorderRadius('medium')),
        border: Border.all(
          color: themeService.getColor('borderColor'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: themeService.getColor('primary'),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: themeService.getSpacing('sm')),
              Text(
                'Submission Requirements',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: themeService.getSpacing('md')),
          Row(
            children: [
              Text(
                'Formats:',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: themeService.getColor('textSecondary'),
                ),
              ),
              SizedBox(width: themeService.getSpacing('sm')),
              ..._buildFormatChips(),
            ],
          ),
          if (_submissionType == 'upload' || _submissionType == 'both') ...[
            SizedBox(height: themeService.getSpacing('sm')),
            Row(
              children: [
                Text(
                  'Types:',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: themeService.getColor('textSecondary'),
                  ),
                ),
                SizedBox(width: themeService.getSpacing('sm')),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: themeService.getSpacing('sm'),
                    vertical: themeService.getSpacing('xs'),
                  ),
                  decoration: BoxDecoration(
                    color: themeService.getColor('backgroundLight'),
                    borderRadius: BorderRadius.circular(
                        themeService.getBorderRadius('small')),
                  ),
                  child: Text(
                    allowedTypesString,
                    style: textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: themeService.getColor('textSecondary'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildFormatChips() {
    final themeService = DynamicThemeService.instance;
    final List<Widget> chips = [];

    if (_submissionType == 'online' || _submissionType == 'both') {
      chips.add(_buildFormatChip('Text', Colors.blue));
    }

    if (_submissionType == 'upload' || _submissionType == 'both') {
      if (chips.isNotEmpty) {
        chips.add(Padding(
          padding:
              EdgeInsets.symmetric(horizontal: themeService.getSpacing('xs')),
          child: Text('+',
              style: TextStyle(color: themeService.getColor('textMuted'))),
        ));
      }
      chips.add(_buildFormatChip('Files', Colors.green));
    }

    return chips;
  }

  Widget _buildFormatChip(String label, Color color) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: themeService.getSpacing('sm'),
        vertical: themeService.getSpacing('xs'),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius:
            BorderRadius.circular(themeService.getBorderRadius('small')),
      ),
      child: Text(
        label,
        style: textTheme.bodySmall?.copyWith(
          color: color.withOpacity(0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSubmissionSection() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return themeService.buildCleanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                DynamicIconService.instance.uploadIcon,
                size: 16,
                color: themeService.getColor('primary'),
              ),
              SizedBox(width: themeService.getSpacing('sm')),
              Text(
                _getSubmissionLabel(),
                style: textTheme.titleLarge?.copyWith(
                  color: themeService.getColor('textPrimary'),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: themeService.getSpacing('lg')),

          // Online Text Editor
          if (_submissionType == 'online' || _submissionType == 'both')
            _buildOnlineTextSection(),

          if (_submissionType == 'both')
            SizedBox(height: themeService.getSpacing('lg')),

          // File Upload Section
          if (_submissionType == 'upload' || _submissionType == 'both')
            _buildFileUploadSection(),

          SizedBox(height: themeService.getSpacing('lg')),

          // Submit Button
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildOnlineTextSection() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Text Submission',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: themeService.getSpacing('sm')),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: themeService.getColor('borderColor')),
            borderRadius:
                BorderRadius.circular(themeService.getBorderRadius('medium')),
          ),
          child: TextField(
            controller: _onlineTextController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'Enter your assignment response here...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(themeService.getSpacing('md')),
            ),
          ),
        ),
        SizedBox(height: themeService.getSpacing('sm')),
        Text(
          '${_onlineTextController.text.length} characters',
          style: textTheme.bodySmall?.copyWith(
            color: themeService.getColor('textMuted'),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadSection() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    final allowedTypesString = _allowedFileTypes.isNotEmpty
        ? _allowedFileTypes.join(', ')
        : 'All file types';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'File Submission',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: themeService.getSpacing('sm')),

        // File Upload Area
        GestureDetector(
          onTap: _pickFiles,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(themeService.getSpacing('lg')),
            decoration: BoxDecoration(
              border: Border.all(
                color: themeService.getColor('borderColor'),
                style: BorderStyle.solid,
                width: 2,
              ),
              borderRadius:
                  BorderRadius.circular(themeService.getBorderRadius('medium')),
              color: themeService.getColor('backgroundLight'),
            ),
            child: Column(
              children: [
                Icon(
                  DynamicIconService.instance.uploadIcon,
                  size: 32,
                  color: themeService.getColor('primary'),
                ),
                SizedBox(height: themeService.getSpacing('sm')),
                Text(
                  'Drop files or click to browse',
                  style: textTheme.bodySmall?.copyWith(
                    color: themeService.getColor('textSecondary'),
                  ),
                ),
                SizedBox(height: themeService.getSpacing('xs')),
                Text(
                  '$allowedTypesString (Max: 512MB)',
                  style: textTheme.bodySmall?.copyWith(
                    color: themeService.getColor('textMuted'),
                  ),
                ),
                SizedBox(height: themeService.getSpacing('md')),
                ElevatedButton(
                  onPressed: _pickFiles,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeService.getColor('primary'),
                    foregroundColor: themeService.getColor('onPrimary'),
                  ),
                  child: Text('Choose File'),
                ),
              ],
            ),
          ),
        ),

        // Selected Files List
        if (_selectedFiles.isNotEmpty) ...[
          SizedBox(height: themeService.getSpacing('md')),
          Text(
            'Selected Files:',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: themeService.getSpacing('sm')),
          ..._selectedFiles.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return _buildSelectedFileItem(file, index);
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildSelectedFileItem(File file, int index) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    final fileName = file.path.split('/').last;
    final fileSize = file.lengthSync();

    return Container(
      margin: EdgeInsets.only(bottom: themeService.getSpacing('sm')),
      padding: EdgeInsets.all(themeService.getSpacing('md')),
      decoration: BoxDecoration(
        color: themeService.getColor('backgroundLight'),
        borderRadius:
            BorderRadius.circular(themeService.getBorderRadius('medium')),
        border: Border.all(
          color: themeService.getColor('borderColor'),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(themeService.getSpacing('sm')),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(themeService.getBorderRadius('small')),
            ),
            child: Icon(
              DynamicIconService.instance.fileIcon,
              size: 16,
              color: themeService.getColor('primary'),
            ),
          ),
          SizedBox(width: themeService.getSpacing('md')),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  _formatFileSize(fileSize),
                  style: textTheme.bodySmall?.copyWith(
                    color: themeService.getColor('textSecondary'),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: themeService.getSpacing('sm')),
          TextButton(
            onPressed: () => _removeFile(index),
            child: Text(
              'Remove',
              style: TextStyle(
                color: themeService.getColor('error'),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final themeService = DynamicThemeService.instance;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitAssignment,
        style: ElevatedButton.styleFrom(
          backgroundColor: themeService.getColor('primary'),
          foregroundColor: themeService.getColor('onPrimary'),
          padding:
              EdgeInsets.symmetric(vertical: themeService.getSpacing('md')),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(themeService.getBorderRadius('medium')),
          ),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        themeService.getColor('onPrimary'),
                      ),
                    ),
                  ),
                  SizedBox(width: themeService.getSpacing('sm')),
                  Text('Submitting...'),
                ],
              )
            : Text(
                'Submit Assignment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null || timestamp == 0) {
      return 'No due date set';
    }

    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp is int
          ? timestamp * 1000
          : int.parse(timestamp.toString()) * 1000);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
