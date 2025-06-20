import 'package:flutter/material.dart';
import 'course_catalog_screen.dart';
import '../services/icon_service.dart';
import '../theme/dynamic_app_theme.dart';
typedef AppTheme = DynamicAppTheme;

class QuickActionsScreen extends StatelessWidget {
  final String token;

  const QuickActionsScreen({required this.token, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {
        'title': 'Browse Courses',
        'iconKey': 'catalog',
        'color': AppTheme.secondary1,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseCatalogScreen(token: token),
              ),
            ),
      },
      {'title': 'My Profile', 'iconKey': 'profile', 'color': AppTheme.secondary2, 'onTap': () => _showComingSoon(context, 'Profile')},
      {'title': 'Messages', 'iconKey': 'messages', 'color': AppTheme.info, 'onTap': () => _showComingSoon(context, 'Messages')},
      {'title': 'Notifications', 'iconKey': 'notifications', 'color': AppTheme.primary1, 'onTap': () => _showComingSoon(context, 'Notifications')},
      {'title': 'Calendar', 'iconKey': 'calendar', 'color': AppTheme.success, 'onTap': () => _showComingSoon(context, 'Calendar')},
      {'title': 'Grades', 'iconKey': 'grades', 'color': AppTheme.secondary1, 'onTap': () => _showComingSoon(context, 'Grades')},
      {'title': 'Downloads', 'iconKey': 'download', 'color': AppTheme.secondary2, 'onTap': () => _showComingSoon(context, 'Downloads')},
      {'title': 'Settings', 'iconKey': 'settings', 'color': AppTheme.textSecondary, 'onTap': () => _showComingSoon(context, 'Settings')},
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppTheme.buildDynamicAppBar(title: 'Quick Actions'),
      body: Padding(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(
              context,
              action['title'],
              action['iconKey'],
              action['color'],
              action['onTap'],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String iconKey,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppTheme.buildInfoCard(
              title: '', // Title is outside the info card structure now
              iconKey: iconKey,
              iconColor: color,
            ),
            SizedBox(height: AppTheme.spacingSm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSm,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
          title: Text(feature),
          content: Text('$feature feature is coming soon!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: AppTheme.secondary1)),
            ),
          ],
        );
      },
    );
  }
}
