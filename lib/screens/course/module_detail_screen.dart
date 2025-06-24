import 'package:flutter/material.dart';
import '../../services/dynamic_theme_service.dart';
import '../../services/enhanced_icon_service.dart';

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
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    final String moduleName = module['name'] ?? 'Module Details';

    return Scaffold(
      appBar: AppBar(title: Text(moduleName)),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(themeService.getSpacing('lg')),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                DynamicIconService.instance.getIcon('construction'),
                size: 80,
                color: themeService.getColor('secondary1'),
              ),
              SizedBox(height: themeService.getSpacing('lg')),
              Text(
                'Viewer for "$moduleName"',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall,
              ),
              SizedBox(height: themeService.getSpacing('md')),
              Text(
                'This module type is under construction.',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
