// lib/screens/viewers/page_viewer_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Renders raw HTML content responsively in a full-screen WebView on mobile,
/// with a native AppBar and optional intro section.
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

    final rawHtml = (source['content'] as String?)
            ?.replaceAll(
              '@@PLUGINFILE@@',
              'https://moodle.instructohub.com/pluginfile.php?token=${widget.token}',
            )
            ?? '<p>No content available.</p>';

    // Added responsive CSS for images, tables, pre/code, and embeddings (iframe, video, etc.)
    final fullHtml = '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
      body { margin:0; padding:0; }
      img, table { max-width: 100%; height: auto; }
      pre, code { white-space: pre-wrap; word-wrap: break-word; }
      iframe, embed, video, object {
        display: block;
        max-width: 100% !important;
        height: auto !important;
        margin: 0 auto;
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

    _controller.loadRequest(Uri.parse(uri.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle, overflow: TextOverflow.ellipsis),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          if (_pageIntro.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                _pageIntro,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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
