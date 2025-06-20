import 'package:flutter/material.dart';
import 'splash/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/domain_config_screen.dart';
import 'theme/dynamic_app_theme.dart';

typedef AppTheme = DynamicAppTheme;


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InstructoHub LMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/domain-config': (context) => const DomainConfigScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const SplashScreen(),
        );
      },
    );
  }
}