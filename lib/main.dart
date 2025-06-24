import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/splash/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/domain_config/domain_config_screen.dart';
import 'services/dynamic_theme_service.dart'; // Updated import

// Assuming the provider file is created at this path
import 'features/messaging/providers/messaging_provider.dart';


// The AppTheme typedef is no longer needed.


void main() async {
  // Ensure that widget binding is initialized before doing any async work.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load the dynamic theme before the app starts.
  // This prevents a theme flicker on app launch.
  await DynamicThemeService.instance.loadTheme();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ValueNotifier<ThemeData> _themeNotifier;

  @override
  void initState() {
    super.initState();
    // Initialize the notifier with the theme loaded at startup.
    _themeNotifier = ValueNotifier(DynamicThemeService.instance.currentTheme);
  }

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const String placeholderToken = "your_auth_token_goes_here";

    // Use a ValueListenableBuilder to rebuild the MaterialApp when the theme changes.
    return ValueListenableBuilder<ThemeData>(
      valueListenable: _themeNotifier,
      builder: (context, theme, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => MessagingProvider(placeholderToken),
            ),
            // You can add other providers here in the future.
          ],
          child: MaterialApp(
            title: 'InstructoHub LMS',
            debugShowCheckedModeBanner: false,
            // Use the theme from the ValueListenableBuilder.
            theme: theme,
            // Pass the themeNotifier to the SplashScreen.
            home: SplashScreen(themeNotifier: _themeNotifier),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/domain-config': (context) => const DomainConfigScreen(),
            },
            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                // Also pass it here for unknown routes.
                builder: (context) => SplashScreen(themeNotifier: _themeNotifier),
              );
            },
          ),
        );
      },
    );
  }
}
