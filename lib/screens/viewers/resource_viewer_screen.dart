import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:open_filex/open_filex.dart'; // NEW: For opening local files
import 'package:url_launcher/url_launcher.dart';
import '../../services/icon_service.dart';
import '../../theme/dynamic_app_theme.dart';
typedef AppTheme = DynamicAppTheme;

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

  // MODIFIED: This function now handles both web URLs and local file paths
  Future<void> _openResource(String url, BuildContext context) async {
    try {
      final Uri uri = Uri.parse(url);
      
      if (uri.scheme.startsWith('http')) {
         // Online mode: launch URL in external app
         if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            throw 'Could not launch $url';
         }
      } else if (uri.scheme == 'file') {
        // Offline mode: use open_filex to open the local file
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
          SnackBar(content: Text('Error opening file: ${e.toString()}'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String moduleName = module['name'] ?? 'Resource';
    final resourceData = foundContent ?? module;
    final List<dynamic> contents = module['contents'] ?? [];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppTheme.buildDynamicAppBar(title: moduleName),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTheme.buildInfoCard(iconKey: 'resource', title: moduleName),
             if (resourceData['intro'] != null && resourceData['intro'].isNotEmpty) ...[
                SizedBox(height: AppTheme.spacingMd),
                Html(data: resourceData['intro'], style: {"body": Style(color: AppTheme.textSecondary)}),
             ],
            SizedBox(height: AppTheme.spacingMd),
            if (contents.isEmpty)
              Center(
                  child: Column(
                children: [
                  Icon(IconService.instance.getIcon('folder'), size: 64, color: AppTheme.textSecondary),
                  SizedBox(height: AppTheme.spacingMd),
                  Text('No files available', style: TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontSizeLg)),
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
    final String filename = file['filename'] ?? 'Unknown file';
    final String fileurl = file['fileurl'] ?? '';
    final String fileExtension = _getFileExtension(filename);

    return Card(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
        leading: Icon(IconService.instance.getIcon(fileExtension), size: 32, color: AppTheme.secondary1),
        title: Text(filename, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        subtitle: Text(_formatFileSize(file['filesize'] ?? 0), style: TextStyle(color: AppTheme.textSecondary)),
        trailing: Icon(IconService.instance.getIcon(isOffline ? 'launch' : 'download'), color: AppTheme.textSecondary),
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
