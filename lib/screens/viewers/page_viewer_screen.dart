import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../theme/dynamic_app_theme.dart';

typedef AppTheme = DynamicAppTheme;

class PageViewerScreen extends StatefulWidget {
  final dynamic module;
  final dynamic foundContent;
  final String token;
  final bool isOffline; // ADDED: To handle offline mode

  const PageViewerScreen({
    required this.module,
    this.foundContent,
    required this.token,
    this.isOffline = false, // ADDED: Default to false
    Key? key,
  }) : super(key: key);

  @override
  _PageViewerScreenState createState() => _PageViewerScreenState();
}

class _PageViewerScreenState extends State<PageViewerScreen> {
  late final WebViewController _controller;
  late String _pageTitle;
  late String _pageIntro;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Prevent all navigation within the webview for simplicity
            return NavigationDecision.prevent;
          },
        ),
      );
    _prepareContent();
  }

  void _prepareContent() {
    final source = widget.foundContent ?? widget.module;
    _pageTitle = source['name'] as String? ?? 'Page';
    _pageIntro = source['intro'] as String? ?? '';
    
    final String contentBackgroundColor = AppTheme.background.value.toRadixString(16).substring(2);
    final String contentTextColor = AppTheme.textPrimary.value.toRadixString(16).substring(2);
    final String linkColor = AppTheme.secondary1.value.toRadixString(16).substring(2);

    String rawHtml = source['content'] as String? ?? '<p>No content available.</p>';
    
    // MODIFIED: Replace pluginfile URLs differently for online vs. offline
    if (!widget.isOffline) {
        rawHtml = rawHtml.replaceAll(
            '@@PLUGINFILE@@',
            'https://moodle.instructohub.com/pluginfile.php?token=${widget.token}',
        );
    } else {
        // In offline mode, URLs should already be local file paths. 
        // We just need to ensure the placeholder isn't there.
        rawHtml = rawHtml.replaceAll('@@PLUGINFILE@@', '');
    }


    final fullHtml = '''
    <!DOCTYPE html>
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          :root {
            --bg-color: #${contentBackgroundColor};
            --text-color: #${contentTextColor};
            --link-color: #${linkColor};
          }
          body { 
            margin: 16px; 
            padding: 0; 
            font-family: sans-serif;
            background-color: var(--bg-color);
            color: var(--text-color);
            line-height: 1.6;
          }
          img, table, video, iframe { max-width: 100%; height: auto; border-radius: 8px; }
          pre, code { white-space: pre-wrap; word-wrap: break-word; }
          a { color: var(--link-color); text-decoration: none; }
        </style>
      </head>
      <body>
        $rawHtml
      </body>
    </html>
    ''';

    final uri = Uri.dataFromString(
      fullHtml,
      mimeType: 'text/html',
      encoding: Encoding.getByName('utf-8'),
    );

    _controller.loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppTheme.buildDynamicAppBar(title: _pageTitle),
      body: Column(
        children: [
          if (_pageIntro.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
              child: Text(_pageIntro, style: TextStyle(color: AppTheme.textSecondary)),
            ),
            const Divider(height: 1),
          ],
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
