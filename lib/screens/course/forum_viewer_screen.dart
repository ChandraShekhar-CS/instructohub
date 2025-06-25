import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';
import 'package:InstructoHub/services/enhanced_icon_service.dart';

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
      case 'news':
        return 'Announcements';
      case 'single':
        return 'Single Discussion';
      case 'qanda':
        return 'Q&A Forum';
      case 'blog':
        return 'Blog-style';
      case 'general':
      default:
        return 'General Discussion';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    final String moduleName = module['name'] ?? 'Forum';
    final forumData = foundContent ?? module;
    final String forumType = forumData['type'] ?? 'general';

    return Scaffold(
      appBar: AppBar(title: Text(moduleName)),
      body: foundContent == null
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(themeService.getSpacing('lg')),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(DynamicIconService.instance.getIcon('forum'),
                        size: 80, color: themeService.getColor('textSecondary')),
                    SizedBox(height: themeService.getSpacing('lg')),
                    Text('Forum content not available',
                        style: textTheme.titleLarge),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(themeService.getSpacing('md')),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(context,
                      iconKey: forumType,
                      title: moduleName,
                      subtitle: _getForumType(forumType)),
                  if (forumData['intro'] != null &&
                      forumData['intro'].isNotEmpty) ...[
                    SizedBox(height: themeService.getSpacing('md')),
                    Html(
                      data: forumData['intro'],
                      style: {"body": Style.fromTextStyle(textTheme.bodyMedium!)},
                    ),
                  ],
                  SizedBox(height: themeService.getSpacing('md')),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(context,
                            iconKey: 'chat',
                            title: 'Discussions',
                            value: (forumData['numdiscussions'] ?? 0).toString()),
                      ),
                      SizedBox(width: themeService.getSpacing('md')),
                      Expanded(
                        child: _buildStatCard(context,
                            iconKey: 'messages',
                            title: 'Posts',
                            value: (forumData['numposts'] ?? 0).toString()),
                      ),
                    ],
                  ),
                  SizedBox(height: themeService.getSpacing('md')),
                  _buildForumActions(context),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(BuildContext context,
      {required String iconKey,
      required String title,
      required String subtitle}) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: ListTile(
        leading: Icon(DynamicIconService.instance.getIcon(iconKey),
            color: themeService.getColor('secondary1')),
        title: Text(title, style: textTheme.titleMedium),
        subtitle: Text(subtitle, style: textTheme.bodyMedium),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required String iconKey, required String title, required String value}) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(themeService.getSpacing('md')),
        child: Column(
          children: [
            Icon(DynamicIconService.instance.getIcon(iconKey),
                color: themeService.getColor('secondary1'), size: 32),
            SizedBox(height: themeService.getSpacing('sm')),
            Text(value, style: textTheme.headlineSmall),
            Text(title, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildForumActions(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(themeService.getSpacing('md')),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Actions', style: textTheme.titleLarge),
            SizedBox(height: themeService.getSpacing('md')),
            ElevatedButton.icon(
              icon: Icon(DynamicIconService.instance.getIcon('view')),
              label: const Text('View Discussions'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('View discussions feature coming soon!')),
                );
              },
            ),
            SizedBox(height: themeService.getSpacing('sm')),
            ElevatedButton.icon(
              icon: Icon(DynamicIconService.instance.getIcon('add')),
              label: const Text('Start New Topic'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: themeService.getColor('cardColor'),
                  foregroundColor: themeService.getColor('textPrimary')),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('New discussion feature coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
