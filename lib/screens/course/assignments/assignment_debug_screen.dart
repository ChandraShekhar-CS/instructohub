import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:InstructoHub/services/api_service.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';
import 'package:InstructoHub/services/enhanced_icon_service.dart';

class AssignmentDebugScreen extends StatefulWidget {
  final String token;
  final int assignmentId;

  const AssignmentDebugScreen({
    required this.token,
    required this.assignmentId,
    Key? key,
  }) : super(key: key);

  @override
  _AssignmentDebugScreenState createState() => _AssignmentDebugScreenState();
}

class _AssignmentDebugScreenState extends State<AssignmentDebugScreen> {
  bool _isRunningDebug = false;
  Map<String, dynamic>? _debugResults;
  String? _debugReport;

  @override
  void initState() {
    super.initState();
    _runQuickTest();
  }

  Future<void> _runQuickTest() async {
    try {
      await ApiService.instance
          .quickAssignmentTest(widget.token, widget.assignmentId);
    } catch (e) {
      print("Quick test failed: $e");
    }
  }

  Future<void> _runFullDebug() async {
    setState(() => _isRunningDebug = true);

    try {
      final results = await ApiService.instance
          .debugAssignmentIssue(widget.token, widget.assignmentId);

      final report = ApiService.instance.exportDebugResults(results);

      if (mounted) {
        setState(() {
          _debugResults = results;
          _debugReport = report;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debug failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRunningDebug = false);
      }
    }
  }

  Future<void> _copyReportToClipboard() async {
    if (_debugReport != null) {
      await Clipboard.setData(ClipboardData(text: _debugReport!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debug report copied to clipboard')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Assignment Debug'),
        backgroundColor: themeService.getColor('primary'),
        foregroundColor: themeService.getColor('onPrimary'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(themeService.getSpacing('md')),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assignment Info Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(themeService.getSpacing('md')),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assignment Debug Tool',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: themeService.getSpacing('sm')),
                    Text('Assignment ID: ${widget.assignmentId}'),
                    Text('Token: ${widget.token.substring(0, 10)}...'),
                  ],
                ),
              ),
            ),

            SizedBox(height: themeService.getSpacing('lg')),

            // Actions Section
            Text(
              'Debug Actions',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: themeService.getSpacing('md')),

            // Run Full Debug Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRunningDebug ? null : _runFullDebug,
                icon: _isRunningDebug
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(DynamicIconService.instance.getIcon('analytics')),
                label: Text(
                    _isRunningDebug ? 'Running Debug...' : 'Run Full Debug'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeService.getColor('primary'),
                  foregroundColor: themeService.getColor('onPrimary'),
                  padding: EdgeInsets.symmetric(
                      vertical: themeService.getSpacing('md')),
                ),
              ),
            ),

            SizedBox(height: themeService.getSpacing('md')),

            // Copy Report Button
            if (_debugReport != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _copyReportToClipboard,
                  icon: Icon(DynamicIconService.instance.getIcon('copy')),
                  label: Text('Copy Debug Report'),
                ),
              ),

            SizedBox(height: themeService.getSpacing('lg')),

            // Results Section
            if (_debugResults != null) ...[
              Text(
                'Debug Results',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: themeService.getSpacing('md')),
              _buildTestResults(),
              SizedBox(height: themeService.getSpacing('lg')),
              _buildRecommendations(),
              SizedBox(height: themeService.getSpacing('lg')),
              _buildRawReport(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestResults() {
    final themeService = DynamicThemeService.instance;
    final tests = _debugResults!['tests'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(themeService.getSpacing('md')),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Results',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: themeService.getSpacing('md')),
            ...tests.entries.map((entry) {
              final testName = entry.key;
              final result = entry.value as Map<String, dynamic>;
              final isSuccess = result['success'] ?? false;

              return Padding(
                padding: EdgeInsets.only(bottom: themeService.getSpacing('sm')),
                child: Row(
                  children: [
                    Icon(
                      isSuccess
                          ? SafeIconService.successIcon
                          : SafeIconService.errorIcon,
                      color: isSuccess
                          ? themeService.getColor('success')
                          : themeService.getColor('error'),
                      size: 20,
                    ),
                    SizedBox(width: themeService.getSpacing('sm')),
                    Expanded(
                      child: Text(
                        _formatTestName(testName),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    if (!isSuccess && result['error'] != null)
                      Tooltip(
                        message: result['error'].toString(),
                        child: Icon(
                          SafeIconService.infoIcon,
                          size: 16,
                          color: themeService.getColor('textSecondary'),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final themeService = DynamicThemeService.instance;
    final recommendations = _debugResults!['recommendations'] as List<String>;

    if (recommendations.isEmpty) return SizedBox.shrink();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(themeService.getSpacing('md')),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  DynamicIconService.instance.getIcon('lightbulb'),
                  color: themeService.getColor('warning'),
                ),
                SizedBox(width: themeService.getSpacing('sm')),
                Text(
                  'Recommendations',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: themeService.getSpacing('md')),
            ...recommendations
                .map((rec) => Padding(
                      padding: EdgeInsets.only(
                          bottom: themeService.getSpacing('sm')),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ',
                              style: Theme.of(context).textTheme.bodyMedium),
                          Expanded(
                            child: Text(
                              rec,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRawReport() {
    final themeService = DynamicThemeService.instance;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(themeService.getSpacing('md')),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Raw Debug Report',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: themeService.getSpacing('md')),
            Container(
              width: double.infinity,
              height: 300,
              padding: EdgeInsets.all(themeService.getSpacing('sm')),
              decoration: BoxDecoration(
                color: themeService.getColor('backgroundLight'),
                borderRadius: BorderRadius.circular(
                    themeService.getBorderRadius('small')),
                border: Border.all(color: themeService.getColor('borderColor')),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _debugReport ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTestName(String testName) {
    switch (testName) {
      case 'userAuth':
        return 'User Authentication';
      case 'assignmentAccess':
        return 'Assignment Access';
      case 'apiEndpoints':
        return 'API Endpoints';
      case 'fileUpload':
        return 'File Upload Capability';
      case 'assignmentConfig':
        return 'Assignment Configuration';
      case 'submissionStatus':
        return 'Submission Status';
      default:
        return testName;
    }
  }
}
