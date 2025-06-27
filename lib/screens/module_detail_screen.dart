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
    // MODIFICATION: Extract the tenant name from the module data.
    // I am assuming the key is 'tenantname'. Adjust if it's different.
    final String? tenantName = module['tenantname']; 
    final String moduleName = module['name'] ?? 'Module Details';

    // MODIFICATION: Use a FutureBuilder to handle async theme loading.
    return FutureBuilder(
      // Call loadTheme with the extracted tenant name.
      future: DynamicThemeService.instance.loadTheme(tenantName: tenantName, token: token),
      builder: (context, snapshot) {
        // Show a loading indicator while the theme is being fetched for the first time.
        if (snapshot.connectionState == ConnectionState.waiting && !DynamicThemeService.instance.isLoaded) {
          return Scaffold(
            appBar: AppBar(title: Text(moduleName)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Once the future is complete, build the UI with the loaded theme.
        final themeService = DynamicThemeService.instance;
        return Scaffold(
          backgroundColor: themeService.getColor('background'),
          appBar: AppBar(
            title: Text(moduleName),
          ),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(themeService.getSpacing('lg')),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    DynamicIconService.instance.getIcon('construction'),
                    size: 80,
                    // MODIFICATION: Use a color key that exists in the theme map.
                    // 'secondary1' from the API is remapped to 'primary'.
                    color: themeService.getColor('primary'),
                  ),
                  SizedBox(height: themeService.getSpacing('lg')),
                  Text(
                    'Module Page for "$moduleName"',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: themeService.getSpacing('md')),
                  Text(
                    'This page is under construction.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
