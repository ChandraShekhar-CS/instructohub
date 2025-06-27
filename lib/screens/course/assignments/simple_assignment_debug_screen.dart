import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:InstructoHub/services/api_service.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';
import 'package:InstructoHub/services/enhanced_icon_service.dart';

class SimpleAssignmentDebugScreen extends StatefulWidget {
  final String token;
  final int assignmentId;

  const SimpleAssignmentDebugScreen({
    required this.token,
    required this.assignmentId,
    Key? key,
  }) : super(key: key);

  @override
  _SimpleAssignmentDebugScreenState createState() => _SimpleAssignmentDebugScreenState();
}

class _SimpleAssignmentDebugScreenState extends State<SimpleAssignmentDebugScreen> {
  bool _isRunningTest = false;
  List<String> _testResults = [];
  Map<String, dynamic>? _testData;

  @override
  void initState() {
    super.initState();
    _runQuickTest();
  }

  Future<void> _runQuickTest() async {
    setState(() {
      _isRunningTest = true;
      _testResults.clear();
    });

    try {
      await ApiService.instance.quickAssignmentTest(widget.token, widget.assignmentId);
      
      if (mounted) {
        setState(() {
          _testResults.add("✅ Quick test completed - check console for details");
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResults.add("❌ Quick test failed: $e");
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isRunningTest = false);
      }
    }
  }

  Future<void> _runCapabilityTest() async {
    setState(() {
      _isRunningTest = true;
      _testResults.clear();
    });

    try {
      final results = await ApiService.instance.testAssignmentSubmissionCapabilities(
        widget.token, 
        widget.assignmentId
      );
      
      if (mounted) {
        setState(() {
          _testData = results;
          
          if (results['canGetStatus'] == true) {
            _testResults.add("✅ Can get submission status");
          } else {
            _testResults.add("❌ Cannot get submission status");
          }
          
          if (results['canUploadFile'] == true) {
            _testResults.add("✅ Can upload files");
          } else {
            _testResults.add("❌ Cannot upload files");
          }
          
          if (results['canSaveSubmission'] == true) {
            _testResults.add("✅ Can prepare submission");
          } else {
            _testResults.add("❌ Cannot prepare submission");
          }
          
          final errors = results['errors'] as List<String>;
          for (String error in errors) {
            _testResults.add("⚠️ $error");
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResults.add("❌ Capability test failed: $e");
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isRunningTest = false);
      }
    }
  }

  Future<void> _testSubmissionMethods() async {
    setState(() {
      _isRunningTest = true;
      _testResults.clear();
    });

    try {
      _testResults.add("🧪 Testing submission methods...");
      
      // Test 1: Try to get submission status
      try {
        await ApiService.instance.getSubmissionStatus(widget.token, widget.assignmentId);
        _testResults.add("✅ Submission status API works");
      } catch (e) {
        _testResults.add("❌ Submission status failed: ${e.toString().substring(0, 50)}...");
      }
      
      // Test 2: Try to get user info
      try {
        final userInfo = await ApiService.instance.getUserInfo(widget.token);
        if (userInfo['success'] == true) {
          _testResults.add("✅ User info API works");
        } else {
          _testResults.add("❌ User info failed");
        }
      } catch (e) {
        _testResults.add("❌ User info failed: ${e.toString().substring(0, 50)}...");
      }
      
      // Test 3: Try basic file upload
      try {
        final testContent = 'Test file content for capability check';
        final testBytes = testContent.codeUnits;
        
        await ApiService.instance.uploadFile(widget.token, {
          'itemid': '0',
          'filename': 'test_capability.txt',
          'file': testBytes,
          'filearea': 'draft',
          'filepath': '/',
        });
        
        _testResults.add("✅ File upload API works");
      } catch (e) {
        _testResults.add("❌ File upload failed: ${e.toString().substring(0, 50)}...");
      }
      
      setState(() {});
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResults.add("❌ Submission method test failed: $e");
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isRunningTest = false);
      }
    }
  }

  void _copyResultsToClipboard() {
    final resultsText = _testResults.join('\n');
    Clipboard.setData(ClipboardData(text: resultsText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Test results copied to clipboard')),
    );
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
      body: Padding(
        padding: EdgeInsets.all(themeService.getSpacing('md')),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(themeService.getSpacing('md')),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assignment Debug Tool',
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: themeService.getSpacing('sm')),
                    Text('Assignment ID: ${widget.assignmentId}'),
                    Text('Token: ${widget.token.substring(0, 10)}...'),
                    SizedBox(height: themeService.getSpacing('md')),
                    Text(
                      'This tool helps diagnose assignment submission issues.',
                      style: textTheme.bodySmall?.copyWith(
                        color: themeService.getColor('textSecondary'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: themeService.getSpacing('lg')),
            
            // Action Buttons
            Text(
              'Debug Tests',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: themeService.getSpacing('md')),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunningTest ? null : _runQuickTest,
                    icon: Icon(DynamicIconService.instance.getIcon('play')),
                    label: Text('Quick Test'),
                  ),
                ),
                SizedBox(width: themeService.getSpacing('sm')),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunningTest ? null : _runCapabilityTest,
                    icon: Icon(DynamicIconService.instance.getIcon('analytics')),
                    label: Text('Capability Test'),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: themeService.getSpacing('sm')),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRunningTest ? null : _testSubmissionMethods,
                icon: Icon(DynamicIconService.instance.getIcon('assignment')),
                label: Text('Test Submission APIs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeService.getColor('secondary'),
                ),
              ),
            ),
            
            if (_testResults.isNotEmpty) ...[
              SizedBox(height: themeService.getSpacing('sm')),
              OutlinedButton.icon(
                onPressed: _copyResultsToClipboard,
                icon: Icon(DynamicIconService.instance.getIcon('copy')),
                label: Text('Copy Results'),
              ),
            ],
            
            SizedBox(height: themeService.getSpacing('lg')),
            
            // Results Section
            if (_isRunningTest)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: themeService.getSpacing('sm')),
                    Text('Running tests...'),
                  ],
                ),
              )
            else if (_testResults.isNotEmpty) ...[
              Text(
                'Test Results',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: themeService.getSpacing('md')),
              
              Expanded(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(themeService.getSpacing('md')),
                    child: ListView.builder(
                      itemCount: _testResults.length,
                      itemBuilder: (context, index) {
                        final result = _testResults[index];
                        Color textColor = themeService.getColor('textPrimary');
                        
                        if (result.startsWith('✅')) {
                          textColor = themeService.getColor('success');
                        } else if (result.startsWith('❌')) {
                          textColor = themeService.getColor('error');
                        } else if (result.startsWith('⚠️')) {
                          textColor = themeService.getColor('warning');
                        }
                        
                        return Padding(
                          padding: EdgeInsets.only(bottom: themeService.getSpacing('sm')),
                          child: Text(
                            result,
                            style: textTheme.bodySmall?.copyWith(
                              color: textColor,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}