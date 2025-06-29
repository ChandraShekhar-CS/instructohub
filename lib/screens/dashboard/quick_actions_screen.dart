import 'package:flutter/material.dart';
import 'my_course.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';
import 'package:InstructoHub/services/enhanced_icon_service.dart';

class QuickActionsScreen extends StatelessWidget {
  final String token;

  const QuickActionsScreen({required this.token, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    final List<Map<String, dynamic>> actions = [
      {
        'title': 'Browse Courses',
        'iconKey': 'catalog',
        'color': themeService.getColor('secondary1'),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseCatalogScreen(token: token),
              ),
            ),
      },
      {
        'title': 'My Profile',
        'iconKey': 'profile',
        'color': themeService.getColor('secondary2'),
        'onTap': () => _showComingSoon(context, 'Profile')
      },
      {
        'title': 'Messages',
        'iconKey': 'messages',
        'color': themeService.getColor('info'),
        'onTap': () => _showComingSoon(context, 'Messages')
      },
      {
        'title': 'Notifications',
        'iconKey': 'notifications',
        'color': themeService.getColor('primary1'),
        'onTap': () => _showComingSoon(context, 'Notifications')
      },
      {
        'title': 'Calendar',
        'iconKey': 'calendar',
        'color': themeService.getColor('success'),
        'onTap': () => _showComingSoon(context, 'Calendar')
      },
      {
        'title': 'Grades',
        'iconKey': 'grades',
        'color': themeService.getColor('secondary1'),
        'onTap': () => _showComingSoon(context, 'Grades')
      },
      {
        'title': 'Downloads',
        'iconKey': 'download',
        'color': themeService.getColor('secondary2'),
        'onTap': () => _showComingSoon(context, 'Downloads')
      },
      {
        'title': 'Settings',
        'iconKey': 'settings',
        'color': themeService.getColor('textSecondary'),
        'onTap': () => _showComingSoon(context, 'Settings')
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Quick Actions')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
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
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2.0,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(themeService.getBorderRadius('medium'))),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(DynamicIconService.instance.getIcon(iconKey),
                  color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center, style: textTheme.titleSmall),
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
          title: Text(feature),
          content: Text('$feature feature is coming soon!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
