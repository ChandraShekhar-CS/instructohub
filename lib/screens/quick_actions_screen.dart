import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'course_catalog_screen.dart';

class QuickActionsScreen extends StatelessWidget {
  final String token;

  const QuickActionsScreen({required this.token, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Actions'),
        backgroundColor: AppTheme.secondary1,
        foregroundColor: AppTheme.offwhite,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildActionCard(
              context,
              'Browse Courses',
              Icons.library_books,
              AppTheme.secondary1,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseCatalogScreen(token: token),
                ),
              ),
            ),
            _buildActionCard(
              context,
              'My Profile',
              Icons.person,
              AppTheme.secondary2,
              () => _showComingSoon(context, 'Profile'),
            ),
            _buildActionCard(
              context,
              'Messages',
              Icons.message,
              AppTheme.navselected,
              () => _showComingSoon(context, 'Messages'),
            ),
            _buildActionCard(
              context,
              'Notifications',
              Icons.notifications,
              AppTheme.primary1,
              () => _showComingSoon(context, 'Notifications'),
            ),
            _buildActionCard(
              context,
              'Calendar',
              Icons.calendar_today,
              AppTheme.navbg,
              () => _showComingSoon(context, 'Calendar'),
            ),
            _buildActionCard(
              context,
              'Grades',
              Icons.grade,
              AppTheme.secondary1,
              () => _showComingSoon(context, 'Grades'),
            ),
            _buildActionCard(
              context,
              'Downloads',
              Icons.download,
              AppTheme.secondary2,
              () => _showComingSoon(context, 'Downloads'),
            ),
            _buildActionCard(
              context,
              'Settings',
              Icons.settings,
              AppTheme.primary2,
              () => _showComingSoon(context, 'Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$feature'),
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