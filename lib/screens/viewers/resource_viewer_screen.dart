import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class ResourceViewerScreen extends StatelessWidget {
  final dynamic module;
  final dynamic foundContent;
  final String token;

  const ResourceViewerScreen({
    required this.module,
    this.foundContent,
    required this.token,
    Key? key,
  }) : super(key: key);

  String _getFileExtension(String filename) {
    return filename.split('.').last.toLowerCase();
  }

  IconData _getFileIcon(String filename) {
    final extension = _getFileExtension(filename);
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        return Icons.videocam;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Icons.audiotrack;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String filename) {
    final extension = _getFileExtension(filename);
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Colors.purple;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        return Colors.indigo;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Colors.pink;
      default:
        return AppTheme.primary2;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _launchURL(String url, BuildContext context) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open this file')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening file')),
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(moduleName),
        backgroundColor: AppTheme.secondary2,
        foregroundColor: AppTheme.offwhite,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppTheme.secondary2.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.secondary2.withOpacity(0.2))
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary2.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: const Icon(Icons.folder_open, color: AppTheme.secondary2, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            moduleName,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.primary1,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (resourceData['intro'] != null && resourceData['intro'].isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Html(
                        data: resourceData['intro'],
                        style: {
                          "body": Style(
                            fontSize: FontSize(AppTheme.fontSizeBase),
                            color: AppTheme.textSecondary,
                            margin: Margins.zero,
                          ),
                        },
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (contents.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No files available',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeLg,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Files (${contents.length})',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeLg,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary1,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: contents.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final file = contents[index];
                    return _buildFileCard(file, context);
                  },
                ),
              ],
              
              const SizedBox(height: 16),
              _buildResourceInfo(resourceData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileCard(dynamic file, BuildContext context) {
    final String filename = file['filename'] ?? 'Unknown file';
    final String fileurl = file['fileurl'] ?? '';
    final int filesize = file['filesize'] ?? 0;
    final String mimetype = file['mimetype'] ?? '';
    
    final IconData fileIcon = _getFileIcon(filename);
    final Color fileColor = _getFileColor(filename);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: fileColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            fileIcon,
            color: fileColor,
            size: 28,
          ),
        ),
        title: Text(
          filename,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.primary1,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (filesize > 0)
              Text(
                _formatFileSize(filesize),
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.fontSizeSm,
                ),
              ),
            if (mimetype.isNotEmpty)
              Text(
                mimetype,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.fontSizeXs,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                if (fileurl.isNotEmpty) {
                  _launchURL('$fileurl&token=$token', context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download link not available')),
                  );
                }
              },
              tooltip: 'Download',
              color: AppTheme.secondary2,
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () {
                if (fileurl.isNotEmpty) {
                  _launchURL('$fileurl&token=$token', context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File link not available')),
                  );
                }
              },
              tooltip: 'Open',
              color: AppTheme.primary2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceInfo(dynamic resourceData) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resource Information',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLg,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary1,
            ),
          ),
          const SizedBox(height: 12),
          if (resourceData['display'] != null) ...[
            _buildInfoRow(
              icon: Icons.visibility,
              label: 'Display',
              value: _getDisplayType(resourceData['display']),
            ),
            const SizedBox(height: 8),
          ],
          if (resourceData['showsize'] != null && resourceData['showsize'] == 1) ...[
            _buildInfoRow(
              icon: Icons.info_outline,
              label: 'Show file size',
              value: 'Yes',
            ),
            const SizedBox(height: 8),
          ],
          if (resourceData['showtype'] != null && resourceData['showtype'] == 1) ...[
            _buildInfoRow(
              icon: Icons.category,
              label: 'Show file type',
              value: 'Yes',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary2),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: AppTheme.fontSizeSm,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTheme.fontSizeSm,
            color: AppTheme.primary1,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getDisplayType(int display) {
    switch (display) {
      case 0:
        return 'Automatic';
      case 1:
        return 'Embed';
      case 2:
        return 'Download';
      case 3:
        return 'Open';
      case 4:
        return 'In popup';
      case 5:
        return 'In frame';
      case 6:
        return 'New window';
      default:
        return 'Unknown';
    }
  }
}