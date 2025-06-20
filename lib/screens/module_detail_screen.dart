import 'package:flutter/material.dart';
import '../services/icon_service.dart';
import '../theme/dynamic_app_theme.dart';
typedef AppTheme = DynamicAppTheme;

class ModuleDetailScreen extends StatelessWidget {
  final dynamic module;
  final String token;

  const ModuleDetailScreen({
    required this.module,
    required this.token,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String moduleName = module['name'] ?? 'Module Details';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppTheme.buildDynamicAppBar(title: moduleName),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconService.instance.getIcon('construction'),
                size: 80,
                color: AppTheme.secondary1,
              ),
              SizedBox(height: AppTheme.spacingLg),
              Text(
                'Module Page for "$moduleName"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTheme.fontSize2xl,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: AppTheme.spacingMd),
              Text(
                'This page is under construction.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLg,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
