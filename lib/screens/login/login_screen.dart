import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:InstructoHub/screens/dashboard/dashboard_screen.dart';
import 'package:InstructoHub/screens/domain_config/domain_config_screen.dart';
import 'package:InstructoHub/services/api_service.dart';
import 'package:InstructoHub/services/enhanced_icon_service.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';

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
  bool _isCheckingAuth = true;

  Map<String, dynamic>? _brandingData;
  Map<String, dynamic>? _themeData;
  String? _logoUrl;
  String? _siteName;
  String? _welcomeMessage;
  String? _loginSubtitle;
  Map<String, String>? _customLabels;

  @override
  void initState() {
    super.initState();
    _initializeLoginScreen();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initializeLoginScreen() async {
    if (!ApiService.instance.isConfigured) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DomainConfigScreen(),
            ),
          );
        }
      });
      return;
    }

    await DynamicIconService.instance.loadIcons();
    
    await _checkStoredAuth();
    
    await _fetchBrandingData();
  }

  Future<void> _checkStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('authToken');
      
      if (storedToken != null && storedToken.isNotEmpty) {
        final isValid = await _validateToken(storedToken);
        
        if (isValid && mounted) {
          await DynamicThemeService.instance.loadTheme(token: storedToken);
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(token: storedToken),
            ),
          );
          return;
        } else {
          await prefs.remove('authToken');
          await prefs.remove('userInfo');
        }
      }
    } catch (e) {
      print('Error checking stored auth: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    }
  }

  Future<bool> _validateToken(String token) async {
    try {
      final userInfoResult = await ApiService.instance.getUserInfo(token);
      return userInfoResult['success'] == true;
    } catch (e) {
      print('Token validation error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _fetchThemeData() async {
    try {
      final tenantUrl = ApiService.instance.baseUrl.replaceAll('https://', '').replaceAll('/webservice/rest/server.php', '');
      final themeApiUrl = 'https://$tenantUrl/local/instructohub/theme.php';
      print('Fetching theme data from: $themeApiUrl');
      
      final response = await http.get(
        Uri.parse(themeApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('Theme API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData != null && responseData['themes'] != null) {
          final themes = responseData['themes'] as List;
          print('Found ${themes.length} themes');
          
          final activeTheme = themes.firstWhere(
            (theme) => theme['active_theme'] == 1,
            orElse: () => null,
          );
          
          if (activeTheme != null) {
            print('Active theme found: ${activeTheme['theme_name']}');
            print('Logo URL: ${activeTheme['logo_image']}');
            return activeTheme;
          }
        }
      }
    } catch (e) {
      print('Error fetching theme data: $e');
    }
    return null;
  }

  Future<void> _fetchBrandingData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBranding = true;
    });

    try {
      final themeData = await _fetchThemeData();
      
      if (themeData != null) {
        setState(() {
          _themeData = themeData;
          if (themeData['logo_image'] != null && themeData['logo_image'].toString().isNotEmpty) {
            _logoUrl = themeData['logo_image'];
          }
        });
      }

      final brandingResult = await _fetchLMSBranding();
      
      if (mounted && brandingResult != null) {
        setState(() {
          _brandingData = brandingResult;
          _logoUrl ??= brandingResult['logo_url'] ?? brandingResult['site_logo'];
          _siteName = brandingResult['site_name'] ?? brandingResult['sitename'];
          _welcomeMessage = brandingResult['welcome_message'] ?? 'Welcome Back!';
          _loginSubtitle = brandingResult['login_subtitle'] ?? 'Login to continue your learning journey';
          _customLabels = Map<String, String>.from(brandingResult['custom_labels'] ?? {});
        });
      }

      if (_logoUrl == null || _siteName == null) {
        await _fallbackBrandingFetch();
      }
    } catch (e) {
      print('Error fetching branding data: $e');
      await _fallbackBrandingFetch();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBranding = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchLMSBranding() async {
    try {
      final url = '${ApiService.instance.baseUrl}?wsfunction=local_instructohub_get_branding_config&moodlewsrestformat=json';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        if (result != null && result is Map && !result.containsKey('exception')) {
          return Map<String, dynamic>.from(result);
        }
      }
    } catch (e) {
      print('Error fetching LMS branding: $e');
    }
    return null;
  }

  Future<void> _fallbackBrandingFetch() async {
    try {
      final url = '${ApiService.instance.baseUrl}?wsfunction=core_webservice_get_site_info&moodlewsrestformat=json';
      final response = await http.get(Uri.parse(url));

      if (mounted && response.statusCode == 200) {
        final result = json.decode(response.body);

        if (result != null && result is Map) {
          setState(() {
            _siteName ??= result['sitename'] ?? _extractTenantName();
            _logoUrl ??= _buildDefaultLogoUrl();
            _welcomeMessage ??= 'Welcome Back!';
            _loginSubtitle ??= 'Login to continue your learning journey';
          });
          return;
        }
      }
      
    } catch (e) {
      print('Fallback branding error: $e');
    } finally {
        if(mounted) {
            setState(() {
                _siteName ??= _extractTenantName();
                _logoUrl ??= _buildDefaultLogoUrl();
                _welcomeMessage ??= 'Welcome Back!';
                _loginSubtitle ??= 'Login to continue your learning journey';
            });
        }
    }
  }

  String _extractTenantName() {
    final tenantName = ApiService.instance.tenantName;
    if (tenantName.isNotEmpty) {
      return tenantName.toUpperCase();
    }
    return 'LMS Portal';
  }

  String _buildDefaultLogoUrl() {
    final tenant = ApiService.instance.tenantName;
    if (tenant.isNotEmpty) {
      return 'https://static.instructohub.com/staticfiles/assets/tenants/$tenant/logo.png';
    }
    return 'https://static.instructohub.com/staticfiles/assets/images/website/Instructo_hub_logo.png';
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

            final userInfoResult = await ApiService.instance.getUserInfo(token);
            if (userInfoResult['success'] == true) {
              await prefs.setString('userInfo', json.encode(userInfoResult['data']));
            }

            await DynamicThemeService.instance.loadTheme(token: token);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardScreen(token: token),
              ),
            );
          } else {
            _showErrorSnackBar(loginResult['error'] ?? 'Login failed');
          }
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('An error occurred: ${e.toString()}');
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

  void _showErrorSnackBar(String message) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
                color: const Color(0xFFE16A3A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.settings,
                color: Color(0xFFE16A3A),
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
            const Text('Current Configuration:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.domain, size: 16, color: Color(0xFFE16A3A)),
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
                        const Icon(Icons.school, size: 16, color: Color(0xFFE16A3A)),
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
            const Text('Would you like to change to a different LMS domain?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.instance.clearConfiguration();
              await DynamicThemeService.instance.clearThemeCache();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('authToken');
              await prefs.remove('userInfo');
              if(mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DomainConfigScreen()),
                );
              }
            },
            icon: const Icon(Icons.swap_horiz, size: 18),
            label: const Text('Change Domain'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE16A3A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicLogo({double? height, double? width}) {
    if (_isLoadingBranding || _logoUrl == null) {
      return Container(
        height: height ?? 50,
        width: width ?? 150,
        decoration: BoxDecoration(
          color: const Color(0xFFE16A3A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFE16A3A),
          ),
        ),
      );
    }

    return Image.network(
      _logoUrl!,
      height: height,
      width: width,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: height ?? 50,
          width: width ?? 150,
          decoration: BoxDecoration(
            color: const Color(0xFFE16A3A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFE16A3A),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height ?? 50,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE16A3A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE16A3A).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.school,
                color: Color(0xFFE16A3A),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _siteName ?? 'LMS',
                style: const TextStyle(
                  color: Color(0xFFE16A3A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String labelKey,
    required String hintKey,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: _customLabels?[labelKey] ?? (labelKey == 'username' ? 'Username' : 'Password'),
        hintText: _customLabels?[hintKey] ?? (hintKey == 'username_hint' ? 'Enter your username' : 'Enter your password'),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE16A3A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(prefixIcon, color: const Color(0xFFE16A3A), size: 20),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE16A3A), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: Colors.grey),
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFE16A3A)),
              SizedBox(height: 16),
              Text(
                'Checking authentication...',
                style: TextStyle(
                  color: Color(0xFF1B3942),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3, 1.0],
            colors: [
              const Color(0xFFE16A3A).withOpacity(0.05),
              const Color(0xFFF8F9FA).withOpacity(0.8),
              const Color(0xFFF8F9FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        alignment: Alignment.centerLeft,
                        child: _buildDynamicLogo(height: 50, width: 150),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE16A3A).withOpacity(0.3)),
                      ),
                      child: IconButton(
                        onPressed: _showDomainSettings,
                        icon: const Icon(
                          Icons.settings,
                          color: Color(0xFFE16A3A),
                          size: 20,
                        ),
                        tooltip: 'Domain Settings',
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoadingBranding)
                LinearProgressIndicator(
                  backgroundColor: const Color(0xFFE16A3A).withOpacity(0.2),
                  color: const Color(0xFFE16A3A),
                )
              else if (_siteName != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE16A3A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE16A3A).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _siteName!,
                          style: const TextStyle(
                            color: Color(0xFFE16A3A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1B3942).withOpacity(0.08),
                              spreadRadius: 0,
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                            BoxShadow(
                              color: const Color(0xFF1B3942).withOpacity(0.04),
                              spreadRadius: 0,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _welcomeMessage ?? 'Welcome Back!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF1B3942),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _loginSubtitle ?? 'Login to continue your learning journey',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF718096),
                                fontSize: 16,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 40),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildCustomTextField(
                                    controller: _usernameController,
                                    labelKey: 'username',
                                    hintKey: 'username_hint',
                                    prefixIcon: Icons.person,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return _customLabels?['username_required'] ?? 'Username is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  _buildCustomTextField(
                                    controller: _passwordController,
                                    labelKey: 'password',
                                    hintKey: 'password_hint',
                                    prefixIcon: Icons.lock,
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return _customLabels?['password_required'] ?? 'Password is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: InkWell(
                                          onTap: () {
                                            setState(() => _rememberMe = !_rememberMe);
                                          },
                                          borderRadius: BorderRadius.circular(4),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Checkbox(
                                                value: _rememberMe,
                                                onChanged: (value) {
                                                  setState(() => _rememberMe = value ?? false);
                                                },
                                                activeColor: const Color(0xFFE16A3A),
                                              ),
                                              const SizedBox(width: 8),
                                              const Flexible(
                                                child: Text(
                                                  'Stay signed in',
                                                  style: TextStyle(color: Color(0xFF2D3748)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {},
                                        child: const Text(
                                          'Forgot password?',
                                          style: TextStyle(
                                            color: Color(0xFFE16A3A),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFE16A3A), Color(0xFFCC5A30)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFE16A3A).withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
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
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'LOGIN',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Icon(
                                                  Icons.arrow_forward,
                                                  size: 20,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (_brandingData?['show_signup'] != false) ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          "New User? ",
                                          style: TextStyle(
                                            color: Color(0xFF718096),
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
                                              color: Color(0xFFE16A3A),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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