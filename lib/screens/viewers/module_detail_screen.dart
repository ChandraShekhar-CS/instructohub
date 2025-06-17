// lib/screens/viewers/module_detail_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

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
      appBar: AppBar(
        title: Text(moduleName),
        backgroundColor: AppTheme.secondary1,
        foregroundColor: AppTheme.offwhite,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.construction,
                size: 80,
                color: AppTheme.primary2,
              ),
              const SizedBox(height: 20),
              Text(
                'Module Page for "$moduleName"',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              const Text(
                'This page is under construction.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeBase,
                  color: AppTheme.primary2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
