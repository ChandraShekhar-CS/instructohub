import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../dashboard_screen.dart';
import '../domain_config_screen.dart';
import '../../services/api_service.dart';
import '../../services/icon_service.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  bool _isLoadingBranding = true;

  String? _logoUrl;
  String? _siteName;

  @override
  void initState() {
    super.initState();
    _checkAPIConfiguration();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkAPIConfiguration() async {
    if (!ApiService.instance.isConfigured) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DomainConfigScreen(),
          ),
        );
      });
      return;
    }
    
    // Load icons and then fetch branding
    await IconService.instance.loadIcons();
    _fetchBrandAssets();
  }

  Future<void> _fetchBrandAssets() async {
    setState(() {
      _isLoadingBranding = true;
    });

    try {
      // Try to get site info using a basic webservice call
      // This will likely fail but might give us some site information
      final url = '${ApiService.instance.baseUrl}?wsfunction=core_webservice_get_site_info&moodlewsrestformat=json';
      final response = await http.get(Uri.parse(url));

      if (mounted && response.statusCode == 200) {
        final result = json.decode(response.body);
        
        // Even if there's an error, try to extract site name
        if (result != null && result is Map) {
          setState(() {
            _siteName = result['sitename'] ?? 'LMS Portal';
            // Don't try to get logo without proper token
            _logoUrl = 'https://static.instructohub.com/staticfiles/assets/images/website/Instructo_hub_logo.png';
          });
          return;
        }
      }
      
      // Fallback if API call fails
      if (mounted) {
        setState(() {
          _logoUrl = 'https://static.instructohub.com/staticfiles/assets/images/website/Instructo_hub_logo.png';
          _siteName = 'LMS Portal';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _logoUrl = 'https://static.instructohub.com/staticfiles/assets/images/website/Instructo_hub_logo.png';
          _siteName = 'LMS Portal';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBranding = false;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final loginResult = await ApiService.instance.login(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );

        if (mounted) {
          if (loginResult['success'] == true) {
            final String token = loginResult['token'];
            final prefs = await SharedPreferences.getInstance();
            
            if (_rememberMe) {
              await prefs.setString('authToken', token);
            } else {
              await prefs.remove('authToken');
            }

            // Fetch and save user info
            final userInfoResult = await ApiService.instance.getUserInfo(token);
            if (userInfoResult['success'] == true) {
              await prefs.setString('userInfo', userInfoResult['data'].toString());
            }

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardScreen(token: token),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loginResult['error'] ?? 'Login failed'),
                backgroundColor: AppTheme.secondary1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred: ${e.toString()}'),
              backgroundColor: AppTheme.secondary1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showDomainSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.secondary1.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                IconService.instance.settingsIcon,
                color: AppTheme.secondary1,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Domain Settings'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Configuration:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(IconService.instance.domainIcon, size: 16, color: AppTheme.secondary1),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'API: ${ApiService.instance.baseUrl}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (_siteName != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(IconService.instance.schoolIcon, size: 16, color: AppTheme.secondary1),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Site: $_siteName',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Would you like to change to a different LMS domain?',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.instance.clearConfiguration();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DomainConfigScreen(),
                ),
              );
            },
            icon: Icon(IconService.instance.swapIcon, size: 18),
            label: const Text('Change Domain'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary1,
              foregroundColor: AppTheme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNetworkImage(String? url, {double? height, double? width}) {
    if (_isLoadingBranding || url == null) {
      return Container(
        height: height ?? 50,
        width: width ?? 150,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2, 
            color: AppTheme.secondary1,
          ),
        ),
      );
    }
    
    return Image.network(
      url,
      height: height,
      width: width,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: height ?? 50,
          width: width ?? 150,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: AppTheme.secondary1,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height ?? 50,
          width: width ?? 150,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.secondary1.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.secondary1.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(IconService.instance.schoolIcon, color: AppTheme.secondary1, size: 24),
              const SizedBox(width: 8),
              const Text(
                'LMS',
                style: TextStyle(
                  color: AppTheme.secondary1,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.loginBgLeft,
              AppTheme.loginBgRight,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with logo and domain settings
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    Expanded(
                      child: Container(
                        height: 50,
                        alignment: Alignment.centerLeft,
                        child: _buildNetworkImage(_logoUrl, height: 50, width: 150),
                      ),
                    ),
                    // Domain settings button
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _showDomainSettings,
                        icon: Icon(
                          IconService.instance.settingsIcon,
                          color: AppTheme.secondary1,
                          size: 20,
                        ),
                        tooltip: 'Domain Settings',
                      ),
                    ),
                  ],
                ),
              ),
              
              // Site name if available
              if (_isLoadingBranding) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        width: 120,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primary2.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else if (_siteName != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary3,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.secondary1.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _siteName!,
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeSm,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondary1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Main login form
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              spreadRadius: 0,
                              blurRadius: 30,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Welcome text
                            const Text(
                              'Welcome Back!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.loginTextTitle,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Login to continue your learning journey',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.loginTextBody,
                                fontSize: AppTheme.fontSizeBase,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Login form
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Username field
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: InputDecoration(
                                      labelText: 'Username',
                                      hintText: 'Enter your username',
                                      labelStyle: const TextStyle(color: AppTheme.primary2),
                                      hintStyle: const TextStyle(color: AppTheme.primary2),
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(12),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondary3,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          IconService.instance.personIcon,
                                          color: AppTheme.secondary1,
                                          size: 20,
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(color: AppTheme.primary2.withOpacity(0.3)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(color: AppTheme.primary2.withOpacity(0.3)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(color: AppTheme.secondary1, width: 2),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(color: Colors.red, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.cardColor,
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                        horizontal: 16,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Username is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Password field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      hintText: 'Enter your password',
                                      labelStyle: const TextStyle(color: AppTheme.primary2),
                                      hintStyle: const TextStyle(color: AppTheme.primary2),
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(12),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondary3,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          IconService.instance.lockIcon,
                                          color: AppTheme.secondary1,
                                          size: 20,
                                        ),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? IconService.instance.visibilityOffIcon
                                              : IconService.instance.visibilityOnIcon,
                                          color: AppTheme.primary2,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(color: AppTheme.primary2.withOpacity(0.3)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(color: AppTheme.primary2.withOpacity(0.3)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(color: AppTheme.secondary1, width: 2),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(color: Colors.red, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.cardColor,
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                        horizontal: 16,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Password is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Remember me and forgot password
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: _rememberMe ? AppTheme.secondary1 : Colors.transparent,
                                                border: Border.all(
                                                  color: _rememberMe ? AppTheme.secondary1 : AppTheme.primary2,
                                                  width: 2,
                                                ),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _rememberMe = !_rememberMe;
                                                  });
                                                },
                                                borderRadius: BorderRadius.circular(4),
                                                child: _rememberMe
                                                    ? const Icon(
                                                        Icons.check,
                                                        size: 16,
                                                        color: AppTheme.cardColor,
                                                      )
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Flexible(
                                              child: Text(
                                                'Stay signed in',
                                                style: TextStyle(
                                                  color: AppTheme.primary1,
                                                  fontSize: AppTheme.fontSizeSm,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                        child: const Text(
                                          'Forgot password?',
                                          style: TextStyle(
                                            color: AppTheme.loginTextLink,
                                            fontSize: AppTheme.fontSizeSm,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  
                                  // Login button - Fixed overflow issue
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(
                                        colors: [AppTheme.secondary1, AppTheme.secondary2],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.secondary1.withOpacity(0.3),
                                          spreadRadius: 0,
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.loginButtonTextColor),
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'LOGIN',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: AppTheme.fontSizeBase,
                                                letterSpacing: 1,
                                                color: AppTheme.loginButtonTextColor,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Sign up link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "New User? ",
                                        style: TextStyle(
                                          color: AppTheme.loginTextBody,
                                          fontSize: AppTheme.fontSizeSm,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Create Account',
                                          style: TextStyle(
                                            color: AppTheme.secondary1,
                                            fontWeight: FontWeight.bold,
                                            fontSize: AppTheme.fontSizeSm,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}