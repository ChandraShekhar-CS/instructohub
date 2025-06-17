// lib/screens/viewers/page_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../theme/app_theme.dart';
import 'edit_page_screen.dart';

class PageViewerScreen extends StatefulWidget {
  final dynamic module;
  final dynamic foundContent;
  final String token;

  const PageViewerScreen({
    required this.module,
    this.foundContent,
    required this.token,
    Key? key,
  }) : super(key: key);

  @override
  _PageViewerScreenState createState() => _PageViewerScreenState();
}

class _PageViewerScreenState extends State<PageViewerScreen> {
  bool _isEditing = false;
  late String _pageContent;
  late String _pageTitle;
  late String _pageIntro;

  @override
  void initState() {
    super.initState();
    _updatePageData();
  }

  void _updatePageData() {
    final contentSource = widget.foundContent ?? widget.module;
    _pageTitle = contentSource['name'] ?? 'Page';
    _pageContent = contentSource['content']?.replaceAll('@@PLUGINFILE@@', 'https://moodle.instructohub.com/pluginfile.php') ?? 'No content available.';
    _pageIntro = contentSource['intro'] ?? '';
  }

  void _handleSave(String newTitle, String newContent) {
    setState(() {
      _pageTitle = newTitle;
      _pageContent = newContent;
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved! (Locally)'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return EditPageScreen(
        initialTitle: _pageTitle,
        initialContent: _pageContent,
        onSave: _handleSave,
      );
    }
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_pageTitle, overflow: TextOverflow.ellipsis),
        backgroundColor: AppTheme.secondary1,
        foregroundColor: AppTheme.offwhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
            tooltip: 'Edit Page',
          ),
        ],
      ),
      body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary1.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.secondary1.withOpacity(0.2))
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary1.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8)
                                ),
                                child: const Icon(Icons.article_outlined, color: AppTheme.secondary1, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _pageTitle,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: AppTheme.primary1,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_pageIntro.isNotEmpty) ...[
                             const SizedBox(height: 12),
                             Text(_pageIntro, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      child: Html(
                        data: _pageContent,
                        style: {
                          "body": Style(
                            fontSize: FontSize(AppTheme.fontSizeBase),
                            color: AppTheme.primary1,
                          ),
                          "p": Style(
                            lineHeight: const LineHeight(1.5),
                          ),
                           "a": Style(
                            color: AppTheme.secondary1,
                            textDecoration: TextDecoration.none,
                          ),
                           "h1, h2, h3, h4, h5, h6": Style(
                            color: AppTheme.primary1,
                            fontWeight: FontWeight.bold
                           )
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
