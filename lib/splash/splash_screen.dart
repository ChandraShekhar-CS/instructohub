import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:InstructoHub/screens/login/login_screen.dart';
import 'package:InstructoHub/screens/dashboard_screen.dart';
import 'package:InstructoHub/screens/domain_config_screen.dart';
import 'package:InstructoHub/services/api_service.dart';
import 'package:InstructoHub/services/icon_service.dart';
import 'package:InstructoHub/theme/dynamic_app_theme.dart';

typedef AppTheme = DynamicAppTheme;

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
    await DynamicAppTheme.loadTheme();
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    try {
      final isConfigured = await ApiService.instance.loadConfiguration();
      
      if (!isConfigured) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DomainConfigScreen(),
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      
      if (token != null && token.isNotEmpty) {
        await DynamicAppTheme.loadTheme(token: token);
        
        final verificationResult = await ApiService.instance.verifyToken(token);
        
        if (verificationResult['success'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(token: token),
            ),
          );
        } else {
          await prefs.remove('authToken');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } catch (e) {
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
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.secondary2.withOpacity(0.8),
                AppTheme.secondary1.withOpacity(0.9),
              ]),
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
                                    color: AppTheme.secondary3,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    IconService.instance.getIcon('school'),
                                    color: AppTheme.secondary1,
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'InstructoHub',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
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
                      CircularProgressIndicator(
                        color: AppTheme.cardColor,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
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