import 'package:flutter/material.dart';
import 'package:InstructoHub/services/api_service.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';
import 'package:InstructoHub/screens/login/login_screen.dart';
import 'package:InstructoHub/screens/domain_config/domain_config_screen.dart';

class SplashScreen extends StatefulWidget {
  final ValueNotifier<ThemeData> themeNotifier;
  const SplashScreen({Key? key, required this.themeNotifier}) : super(key: key);

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
    // First, load the API configuration.
    final bool isApiConfigured = await ApiService.instance.loadConfiguration();

    // **CRUCIAL FIX**: Load the dynamic theme *after* API config is loaded
    // but *before* navigating away from the splash screen.
    await DynamicThemeService.instance.loadTheme();

    // Update the theme for the entire app via the ValueNotifier from main.dart
    widget.themeNotifier.value = DynamicThemeService.instance.currentTheme;

    // A short delay to make the splash screen visible.
    await Future.delayed(const Duration(seconds: 2));

    // Ensure the widget is still mounted before navigating.
    if (!mounted) return;

    // Navigate to the correct screen based on whether configuration was found.
    if (isApiConfigured) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DomainConfigScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Now this screen will correctly display the loaded dynamic theme colors.
    return Scaffold(
      backgroundColor: DynamicThemeService.instance.getColor('background'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  DynamicThemeService.instance.getColor('secondary1')),
            ),
            const SizedBox(height: 24),
            Text(
              'Initializing App...',
              style: TextStyle(
                fontSize: 16,
                // **FIX**: Consistently use the theme service to get colors.
                color: DynamicThemeService.instance.getColor('textSecondary'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
