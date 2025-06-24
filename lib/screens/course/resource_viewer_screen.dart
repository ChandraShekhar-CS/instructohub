import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/dynamic_theme_service.dart';
import '../../services/enhanced_icon_service.dart';

class ResourceViewerScreen extends StatelessWidget {
  final dynamic module;
  final dynamic foundContent;
  final String token;
  final bool isOffline;

  const ResourceViewerScreen({
    required this.module,
    this.foundContent,
    required this.token,
    this.isOffline = false,
    Key? key,
  }) : super(key: key);

  String _getFileExtension(String filename) {
    try {
      return filename.split('.').last.toLowerCase();
    } catch (e) {
      return '';
    }
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
    final textTheme = Theme.of(context).textTheme;
    final String moduleName = module['name'] ?? 'Resource';
    final resourceData = foundContent ?? module;
    final List<dynamic> contents = module['contents'] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(moduleName)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(themeService.getSpacing('md')),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: Icon(DynamicIconService.instance.getIcon('resource'),
                    color: themeService.getColor('secondary1')),
                title: Text(moduleName, style: textTheme.titleMedium),
              ),
            ),
            if (resourceData['intro'] != null &&
                resourceData['intro'].isNotEmpty) ...[
              SizedBox(height: themeService.getSpacing('md')),
              Html(
                  data: resourceData['intro'],
                  style: {"body": Style.fromTextStyle(textTheme.bodyMedium!)}),
            ],
            SizedBox(height: themeService.getSpacing('md')),
            if (contents.isEmpty)
              Center(
                  child: Column(
                children: [
                  Icon(DynamicIconService.instance.getIcon('folder'),
                      size: 64, color: themeService.getColor('textSecondary')),
                  SizedBox(height: themeService.getSpacing('md')),
                  Text('No files available', style: textTheme.titleLarge),
                ],
              ))
            else
              ...contents.map((file) => _buildFileCard(file, context)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(dynamic file, BuildContext context) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    final String filename = file['filename'] ?? 'Unknown file';
    final String fileurl = file['fileurl'] ?? '';
    final String fileExtension = _getFileExtension(filename);

    return Card(
      margin: EdgeInsets.only(bottom: themeService.getSpacing('sm')),
      child: ListTile(
        leading: Icon(DynamicIconService.instance.getIcon(fileExtension),
            size: 32, color: themeService.getColor('secondary1')),
        title: Text(filename, style: textTheme.titleSmall),
        subtitle: Text(_formatFileSize(file['filesize'] ?? 0),
            style: textTheme.bodySmall),
        trailing: Icon(
            DynamicIconService.instance
                .getIcon(isOffline ? 'launch' : 'download'),
            color: themeService.getColor('textSecondary')),
        onTap: () {
          if (fileurl.isNotEmpty) {
            final urlToOpen = isOffline ? fileurl : '$fileurl&token=$token';
            _openResource(urlToOpen, context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File URL not available')),
            );
          }
        },
      ),
    );
  }
}
