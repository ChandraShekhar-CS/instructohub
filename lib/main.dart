import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'splash/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/domain_config_screen.dart';
import 'theme/dynamic_app_theme.dart';

// Assuming the provider file is created at this path
import 'features/messaging/providers/messaging_provider.dart';


typedef AppTheme = DynamicAppTheme;


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const String placeholderToken = "your_auth_token_goes_here";

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
      ),
    );
  }
}
