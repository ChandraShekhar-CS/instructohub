import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../theme/app_theme.dart';

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

  IconData _getForumIcon(String type) {
    switch (type) {
      case 'news':
        return Icons.campaign;
      case 'single':
        return Icons.chat_bubble;
      case 'qanda':
        return Icons.help_outline;
      case 'blog':
        return Icons.article;
      case 'general':
      default:
        return Icons.forum;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String moduleName = module['name'] ?? 'Forum';
    final forumData = foundContent ?? module;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(moduleName),
        backgroundColor: AppTheme.secondary2,
        foregroundColor: AppTheme.offwhite,
      ),
      body: foundContent == null 
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined, size: 80, color: AppTheme.primary2),
                  const SizedBox(height: 20),
                  Text('Forum content not available', 
                       style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
          )
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
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
                              child: Icon(
                                _getForumIcon(forumData['type'] ?? 'general'), 
                                color: AppTheme.secondary2, 
                                size: 24
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    moduleName,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: AppTheme.primary1,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _getForumType(forumData['type'] ?? 'general'),
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeSm,
                                      color: AppTheme.secondary2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (forumData['intro'] != null && forumData['intro'].isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Html(
                            data: forumData['intro'],
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
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.chat_bubble_outline,
                          title: 'Discussions',
                          count: forumData['numdiscussions'] ?? 0,
                          color: AppTheme.primary2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.message_outlined,
                          title: 'Posts',
                          count: forumData['numposts'] ?? 0,
                          color: AppTheme.secondary1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildForumActions(forumData),
                  
                  const SizedBox(height: 12),
                  _buildRecentDiscussions(forumData),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: AppTheme.fontSizeLg,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary1,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: AppTheme.fontSizeSm,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForumActions(dynamic forumData) {
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
            'Forum Actions',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLg,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (BuildContext buttonContext) => ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(buttonContext).showSnackBar(
                        const SnackBar(content: Text('View discussions feature coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Discussions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary2,
                      foregroundColor: AppTheme.offwhite,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Builder(
                  builder: (BuildContext buttonContext) => ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(buttonContext).showSnackBar(
                        const SnackBar(content: Text('New discussion feature coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New Topic'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary1,
                      foregroundColor: AppTheme.offwhite,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDiscussions(dynamic forumData) {
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
            'Recent Activity',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLg,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary1,
            ),
          ),
          const SizedBox(height: 16),
          if ((forumData['numdiscussions'] ?? 0) == 0) ...[
            Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No discussions yet',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeBase,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to start a conversation!',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSm,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.secondary2.withOpacity(0.2),
                    child: Text('${index + 1}', style: TextStyle(color: AppTheme.secondary2)),
                  ),
                  title: Text(
                    'Discussion Topic ${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary1,
                    ),
                  ),
                  subtitle: Text(
                    'Recent activity in this discussion...',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontSizeSm,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Discussion details coming soon!')),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}