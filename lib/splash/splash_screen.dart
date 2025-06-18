import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/domain_config_screen.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    try {
      // First, try to load API configuration
      final isConfigured = await ApiService.instance.loadConfiguration();
      
      if (!isConfigured) {
        // No domain configured, go to domain config screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DomainConfigScreen(),
          ),
        );
        return;
      }

      // Domain is configured, check for existing auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      
      if (token != null && token.isNotEmpty) {
        // Verify the token is still valid
        final verificationResult = await ApiService.instance.verifyToken(token);
        
        if (verificationResult['success'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(token: token),
            ),
          );
        } else {
          // Token is invalid, remove it and go to login
          await prefs.remove('authToken');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        }
      } else {
        // No token, go to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } catch (e) {
      // Error occurred, go to domain config to reconfigure
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DomainConfigScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage('https://learn.instructohub.com/static/media/login-bg.e2a088d001b1fc451772.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Image.network(
                              'https://static.instructohub.com/staticfiles/assets/images/website/Instructo_hub_logo.png',
                              height: 80,
                              width: 200,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 80,
                                  width: 200,
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary1,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.school,
                                    color: AppTheme.cardColor,
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'InstructoHub',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Experience the future of education',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      const CircularProgressIndicator(
                        color: AppTheme.secondary1,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Initializing...',
                        style: TextStyle(
                          color: AppTheme.cardColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}