import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../theme/dynamic_app_theme.dart';

typedef AppTheme = DynamicAppTheme;

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
  late final WebViewController _controller;
  late String _pageTitle;
  late String _pageIntro;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    _prepareContent();
  }

  void _prepareContent() {
    final source = widget.foundContent ?? widget.module;
    _pageTitle = source['name'] as String? ?? 'Page';
    _pageIntro = source['intro'] as String? ?? '';
    
    final String contentBackgroundColor = AppTheme.background.value.toRadixString(16).substring(2);
    final String contentTextColor = AppTheme.textPrimary.value.toRadixString(16).substring(2);
    final String linkColor = AppTheme.secondary1.value.toRadixString(16).substring(2);

    final rawHtml = (source['content'] as String?)
            ?.replaceAll(
              '@@PLUGINFILE@@',
              'https://moodle.instructohub.com/pluginfile.php?token=${widget.token}',
            )
            ?? '<p>No content available.</p>';

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
          img, table { max-width: 100%; height: auto; }
          pre, code { white-space: pre-wrap; word-wrap: break-word; }
          a { color: var(--link-color); text-decoration: none; }
          iframe, embed, video, object {
            display: block;
            max-width: 100% !important;
            height: auto !important;
            margin: 0 auto;
            border-radius: 12px;
          }
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
