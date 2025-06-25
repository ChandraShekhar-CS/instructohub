import 'package:flutter/material.dart';
import 'package:InstructoHub/services/enhanced_icon_service.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';

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
    // Get an instance of the theme service for easier access
    final themeService = DynamicThemeService.instance;
    final String moduleName = module['name'] ?? 'Module Details';

    return Scaffold(
      // Use the background color from the dynamic theme
      backgroundColor: themeService.getColor('background'),

      // Use a standard AppBar; styling is automatically applied from the global theme
      appBar: AppBar(
        title: Text(moduleName),
      ),

      body: Center(
        child: Padding(
          // Use dynamic spacing from the theme service
          padding: EdgeInsets.all(themeService.getSpacing('lg')),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                // The icon service remains the same
                DynamicIconService.instance.getIcon('construction'),
                size: 80,
                // Use the primary accent color from the theme
                color: themeService.getColor('secondary1'),
              ),
              // Use dynamic spacing
              SizedBox(height: themeService.getSpacing('lg')),
              Text(
                'Module Page for "$moduleName"',
                textAlign: TextAlign.center,
                // Use a pre-defined text style from the theme for consistency
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              // Use dynamic spacing
              SizedBox(height: themeService.getSpacing('md')),
              Text(
                'This page is under construction.',
                textAlign: TextAlign.center,
                // Use a pre-defined text style for secondary text
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
