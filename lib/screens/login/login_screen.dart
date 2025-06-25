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

  Map<String, dynamic>? _brandingData;
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
    await _fetchBrandingData();
  }

  Future<void> _fetchBrandingData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBranding = true;
    });

    try {
      final brandingResult = await _fetchLMSBranding();
      
      if (mounted && brandingResult != null) {
        setState(() {
          _brandingData = brandingResult;
          _logoUrl = brandingResult['logo_url'] ?? brandingResult['site_logo'];
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
      // Fallback in case of any error
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
    final themeService = DynamicThemeService.instance;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: themeService.getColor('error'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeService.getBorderRadius('small')),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDomainSettings() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeService.getBorderRadius('large')),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(themeService.getSpacing('sm')),
              decoration: BoxDecoration(
                color: themeService.getColor('primary').withOpacity(0.1),
                borderRadius: BorderRadius.circular(themeService.getBorderRadius('small')),
              ),
              child: Icon(
                DynamicIconService.instance.settingsIcon,
                color: themeService.getColor('primary'),
                size: 20,
              ),
            ),
            SizedBox(width: themeService.getSpacing('md')),
            Text('Domain Settings', style: textTheme.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Configuration:',
              style: textTheme.titleMedium,
            ),
            SizedBox(height: themeService.getSpacing('md')),
            Container(
              padding: EdgeInsets.all(themeService.getSpacing('md')),
              decoration: themeService.getCleanCardDecoration(
                backgroundColor: themeService.getColor('surface'),
                borderColor: themeService.getColor('border'),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(DynamicIconService.instance.domainIcon, size: 16, color: themeService.getColor('primary')),
                      SizedBox(width: themeService.getSpacing('sm')),
                      Expanded(
                        child: Text(
                          'API: ${ApiService.instance.baseUrl}',
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  if (_siteName != null) ...[
                    SizedBox(height: themeService.getSpacing('sm')),
                    Row(
                      children: [
                        Icon(DynamicIconService.instance.schoolIcon, size: 16, color: themeService.getColor('primary')),
                        SizedBox(width: themeService.getSpacing('sm')),
                        Expanded(
                          child: Text(
                            'Site: $_siteName',
                            style: textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: themeService.getSpacing('md')),
            Text(
              'Would you like to change to a different LMS domain?',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: themeService.getColor('textSecondary')),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.instance.clearConfiguration();
              await DynamicThemeService.instance.clearThemeCache();
              if(mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DomainConfigScreen()),
                );
              }
            },
            icon: Icon(DynamicIconService.instance.swapIcon, size: 18),
            label: const Text('Change Domain'),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicLogo({double? height, double? width}) {
    final themeService = DynamicThemeService.instance;
    
    if (_isLoadingBranding || _logoUrl == null) {
      return Container(
        height: height ?? 50,
        width: width ?? 150,
        decoration: themeService.getCleanCardDecoration(
          backgroundColor: themeService.getColor('primary').withOpacity(0.1),
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: themeService.getColor('primary'),
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
          decoration: themeService.getCleanCardDecoration(
            backgroundColor: themeService.getColor('primary').withOpacity(0.1),
          ),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: themeService.getColor('primary'),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height ?? 50,
          padding: EdgeInsets.all(themeService.getSpacing('sm')),
          decoration: BoxDecoration(
            color: themeService.getColor('primary').withOpacity(0.1),
            borderRadius: BorderRadius.circular(themeService.getBorderRadius('small')),
            border: Border.all(color: themeService.getColor('primary').withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                DynamicIconService.instance.schoolIcon,
                color: themeService.getColor('primary'),
                size: 24,
              ),
              SizedBox(width: themeService.getSpacing('sm')),
              Text(
                _siteName ?? 'LMS',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: themeService.getColor('primary'),
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
    final themeService = DynamicThemeService.instance;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: _customLabels?[labelKey] ?? (labelKey == 'username' ? 'Username' : 'Password'),
        hintText: _customLabels?[hintKey] ?? (hintKey == 'username_hint' ? 'Enter your username' : 'Enter your password'),
        prefixIcon: Container(
          margin: EdgeInsets.all(themeService.getSpacing('xs')),
          padding: EdgeInsets.all(themeService.getSpacing('xs')),
          decoration: BoxDecoration(
            color: themeService.getColor('primary').withOpacity(0.1),
            borderRadius: BorderRadius.circular(themeService.getBorderRadius('small')),
          ),
          child: Icon(prefixIcon, color: themeService.getColor('primary'), size: 20),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: themeService.getColor('surface'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(themeService.getBorderRadius('medium')),
          borderSide: BorderSide(color: themeService.getColor('border')),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(themeService.getBorderRadius('medium')),
          borderSide: BorderSide(color: themeService.getColor('border')),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(themeService.getBorderRadius('medium')),
          borderSide: BorderSide(color: themeService.getColor('primary'), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(themeService.getBorderRadius('medium')),
          borderSide: BorderSide(color: themeService.getColor('error'), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(themeService.getBorderRadius('medium')),
          borderSide: BorderSide(color: themeService.getColor('error'), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: themeService.getSpacing('md'),
          vertical: themeService.getSpacing('md'),
        ),
        labelStyle: TextStyle(color: themeService.getColor('textSecondary')),
        hintStyle: TextStyle(color: themeService.getColor('textMuted')),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: themeService.getColor('background'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeService.getColor('background'),
              themeService.getColor('surface'),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: themeService.getSpacing('lg'),
                  vertical: themeService.getSpacing('md'),
                ),
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
                    themeService.buildCleanCard(
                      padding: EdgeInsets.all(themeService.getSpacing('xs')),
                      child: IconButton(
                        onPressed: _showDomainSettings,
                        icon: Icon(
                          DynamicIconService.instance.settingsIcon,
                          color: themeService.getColor('primary'),
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
                  backgroundColor: themeService.getColor('primary').withOpacity(0.2),
                  color: themeService.getColor('primary'),
                )
              else if (_siteName != null) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: themeService.getSpacing('lg')),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: themeService.getSpacing('md'),
                          vertical: themeService.getSpacing('xs'),
                        ),
                        decoration: BoxDecoration(
                          color: themeService.getColor('primary').withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: themeService.getColor('primary').withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _siteName!,
                          style: textTheme.labelLarge?.copyWith(
                             color: themeService.getColor('primary'),
                          )
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: themeService.getSpacing('lg')),
              ],
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: themeService.getSpacing('lg')),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: themeService.buildCleanCard(
                        padding: EdgeInsets.all(themeService.getSpacing('xl')),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _welcomeMessage ?? 'Welcome Back!',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineMedium?.copyWith(
                                color: themeService.getColor('textPrimary'),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: themeService.getSpacing('sm')),
                            Text(
                              _loginSubtitle ?? 'Login to continue your learning journey',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: themeService.getColor('textSecondary'),
                              ),
                            ),
                            SizedBox(height: themeService.getSpacing('xl')),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildCustomTextField(
                                    controller: _usernameController,
                                    labelKey: 'username',
                                    hintKey: 'username_hint',
                                    prefixIcon: DynamicIconService.instance.personIcon,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return _customLabels?['username_required'] ?? 'Username is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: themeService.getSpacing('lg')),
                                  _buildCustomTextField(
                                    controller: _passwordController,
                                    labelKey: 'password',
                                    hintKey: 'password_hint',
                                    prefixIcon: DynamicIconService.instance.lockIcon,
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? DynamicIconService.instance.visibilityOffIcon
                                            : DynamicIconService.instance.visibilityOnIcon,
                                        color: themeService.getColor('textSecondary'),
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
                                  SizedBox(height: themeService.getSpacing('lg')),
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
                                                activeColor: themeService.getColor('primary'),
                                              ),
                                              SizedBox(width: themeService.getSpacing('sm')),
                                              Flexible(
                                                child: Text(
                                                  _customLabels?['remember_me'] ?? 'Stay signed in',
                                                  style: textTheme.bodyMedium?.copyWith(
                                                    color: themeService.getColor('textPrimary')
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {},
                                        child: Text(
                                          _customLabels?['forgot_password'] ?? 'Forgot password?',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: themeService.getColor('primary'),
                                            fontWeight: FontWeight.w500
                                          )
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: themeService.getSpacing('xl')),
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(themeService.getBorderRadius('medium')),
                                      gradient: LinearGradient(
                                        colors: [
                                          themeService.getColor('primary'),
                                          themeService.getColor('primaryDark'),
                                        ],
                                      ),
                                      boxShadow: [
                                        themeService.getCardShadow(opacity: 0.3),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(themeService.getBorderRadius('medium')),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  themeService.getColor('onPrimary'),
                                                ),
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              _customLabels?['login_button'] ?? 'LOGIN',
                                               style: textTheme.labelLarge?.copyWith(
                                                color: themeService.getColor('onPrimary'),
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1,
                                              )
                                            ),
                                    ),
                                  ),
                                  SizedBox(height: themeService.getSpacing('lg')),
                                  if (_brandingData?['show_signup'] != false) ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _customLabels?['new_user_text'] ?? "New User? ",
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: themeService.getColor('textSecondary'),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {},
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text(
                                            _customLabels?['create_account'] ?? 'Create Account',
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: themeService.getColor('primary'),
                                              fontWeight: FontWeight.w600,
                                            )
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