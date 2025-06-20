import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../services/icon_service.dart';
import '../../theme/dynamic_app_theme.dart';
typedef AppTheme = DynamicAppTheme;

class ForumViewerScreen extends StatelessWidget {
  final dynamic module;
  final dynamic foundContent;
  final String token;

  const ForumViewerScreen({
    required this.module,
    this.foundContent,
    required this.token,
    Key? key,
  }) : super(key: key);

  String _getForumType(String type) {
    switch (type) {
      case 'news': return 'Announcements';
      case 'single': return 'Single Discussion';
      case 'qanda': return 'Q&A Forum';
      case 'blog': return 'Blog-style';
      case 'general':
      default: return 'General Discussion';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String moduleName = module['name'] ?? 'Forum';
    final forumData = foundContent ?? module;
    final String forumType = forumData['type'] ?? 'general';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppTheme.buildDynamicAppBar(title: moduleName),
      body: foundContent == null
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(IconService.instance.getIcon('forum'), size: 80, color: AppTheme.textSecondary),
                    SizedBox(height: AppTheme.spacingLg),
                    Text('Forum content not available', style: TextStyle(fontSize: AppTheme.fontSizeLg, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTheme.buildInfoCard(
                    iconKey: forumType,
                    title: moduleName,
                    subtitle: _getForumType(forumType),
                  ),
                  if (forumData['intro'] != null && forumData['intro'].isNotEmpty) ...[
                    SizedBox(height: AppTheme.spacingMd),
                    Html(
                      data: forumData['intro'],
                      style: {
                        "body": Style(fontSize: FontSize(AppTheme.fontSizeBase), color: AppTheme.textSecondary, margin: Margins.zero),
                      },
                    ),
                  ],
                  SizedBox(height: AppTheme.spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: AppTheme.buildStatCard(
                          iconKey: 'chat',
                          title: 'Discussions',
                          value: (forumData['numdiscussions'] ?? 0).toString(),
                        ),
                      ),
                      SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: AppTheme.buildStatCard(
                          iconKey: 'messages',
                          title: 'Posts',
                          value: (forumData['numposts'] ?? 0).toString(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingMd),
                  _buildForumActions(context),
                ],
              ),
            ),
    );
  }

  Widget _buildForumActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: TextStyle(fontSize: AppTheme.fontSizeLg, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            SizedBox(height: AppTheme.spacingMd),
            AppTheme.buildActionButton(
              text: 'View Discussions',
              iconKey: 'view',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('View discussions feature coming soon!')),
                );
              },
            ),
            SizedBox(height: AppTheme.spacingSm),
            AppTheme.buildActionButton(
              text: 'Start New Topic',
              iconKey: 'add',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New discussion feature coming soon!')),
                );
              },
              style: AppTheme.secondaryButtonStyle,
            ),
          ],
        ),
      ),
    );
  }
}
