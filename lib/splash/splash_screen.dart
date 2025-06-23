import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/login/login_screen.dart';
import '../screens/domain_config_screen.dart';
import '../theme/dynamic_app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // This is the crucial step that fixes the error.
    // It attempts to load the previously saved API configuration from storage.
    final bool isApiConfigured = await ApiService.instance.loadConfiguration();

    // A short delay to make the splash screen visible.
    await Future.delayed(const Duration(seconds: 2));

    // Ensure the widget is still mounted before navigating.
    if (!mounted) return;

    // Navigate to the correct screen based on whether configuration was found.
    if (isApiConfigured) {
      // If config was loaded, the ApiService is ready. Go to Login.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      // If no config was found, the user needs to set it up.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DomainConfigScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // A simple splash screen UI.
    return Scaffold(
      backgroundColor: DynamicAppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(DynamicAppTheme.secondary1),
            ),
            const SizedBox(height: 24),
            // FIX: Removed 'const' from the Text widget because its style
            // uses a dynamic theme color which is not a compile-time constant.
            Text(
              'Initializing App...',
              style: TextStyle(
                fontSize: 16,
                color: DynamicAppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
