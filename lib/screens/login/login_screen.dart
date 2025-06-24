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
                color: themeService.getColor('secondary1').withOpacity(0.1),
                borderRadius: BorderRadius.circular(themeService.getBorderRadius('small')),
              ),
              child: Icon(
                DynamicIconService.instance.settingsIcon,
                color: themeService.getColor('secondary1'),
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
              decoration: BoxDecoration(
                color: themeService.getColor('background'),
                borderRadius: BorderRadius.circular(themeService.getBorderRadius('medium')),
                border: Border.all(color: themeService.getColor('textSecondary').withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(DynamicIconService.instance.domainIcon, size: 16, color: themeService.getColor('secondary1')),
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
                        Icon(DynamicIconService.instance.schoolIcon, size: 16, color: themeService.getColor('secondary1')),
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
            // Style is inherited from the global theme
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
        decoration: themeService.getDynamicCardDecoration().copyWith(
          color: themeService.getColor('secondary1').withOpacity(0.1),
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: themeService.getColor('secondary1'),
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
          decoration: themeService.getDynamicCardDecoration().copyWith(
            color: themeService.getColor('secondary1').withOpacity(0.1),
          ),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: themeService.getColor('secondary1'),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height ?? 50,
          padding: EdgeInsets.all(themeService.getSpacing('sm')),
          decoration: BoxDecoration(
            color: themeService.getColor('secondary1').withOpacity(0.1),
            borderRadius: BorderRadius.circular(themeService.getBorderRadius('small')),
            border: Border.all(color: themeService.getColor('secondary1').withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                DynamicIconService.instance.schoolIcon,
                color: themeService.getColor('secondary1'),
                size: 24,
              ),
              SizedBox(width: themeService.getSpacing('sm')),
              Text(
                _siteName ?? 'LMS',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: themeService.getColor('secondary1'),
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
    final inputTheme = Theme.of(context).inputDecorationTheme;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: _customLabels?[labelKey] ?? (labelKey == 'username' ? 'Username' : 'Password'),
        hintText: _customLabels?[hintKey] ?? (hintKey == 'username_hint' ? 'Enter your username' : 'Enter your password'),
        prefixIcon: Container(
          margin: EdgeInsets.all(themeService.getSpacing('md')),
          padding: EdgeInsets.all(themeService.getSpacing('sm')),
          decoration: BoxDecoration(
            color: themeService.getColor('secondary3'),
            borderRadius: BorderRadius.circular(themeService.getBorderRadius('small')),
          ),
          child: Icon(prefixIcon, color: themeService.getColor('secondary1'), size: 20),
        ),
        suffixIcon: suffixIcon,
      ).copyWith( // Inherit from theme and override specific properties
        labelStyle: inputTheme.labelStyle?.copyWith(color: themeService.getColor('primary2')),
        hintStyle: inputTheme.hintStyle?.copyWith(color: themeService.getColor('primary2')),
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
          gradient: themeService.getDynamicBackgroundGradient(),
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
                    Container(
                      decoration: themeService.getDynamicCardDecoration(),
                      child: IconButton(
                        onPressed: _showDomainSettings,
                        icon: Icon(
                          DynamicIconService.instance.settingsIcon,
                          color: themeService.getColor('secondary1'),
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
                  backgroundColor: themeService.getColor('secondary1').withOpacity(0.2),
                  color: themeService.getColor('secondary1'),
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
                          color: themeService.getColor('secondary3'),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: themeService.getColor('secondary1').withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _siteName!,
                          style: textTheme.labelLarge?.copyWith(
                             color: themeService.getColor('secondary1'),
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
                      child: Container(
                        padding: EdgeInsets.all(themeService.getSpacing('xl')),
                        decoration: themeService.getDynamicCardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _welcomeMessage ?? 'Welcome Back!',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineMedium,
                            ),
                            SizedBox(height: themeService.getSpacing('sm')),
                            Text(
                              _loginSubtitle ?? 'Login to continue your learning journey',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium,
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
                                        color: themeService.getColor('primary2'),
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
                                            children: [
                                              Checkbox(
                                                value: _rememberMe,
                                                onChanged: (value) {
                                                  setState(() => _rememberMe = value ?? false);
                                                },
                                                // Checkbox theme is handled globally
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
                                            color: themeService.getColor('secondary1'),
                                            fontWeight: FontWeight.bold
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
                                      borderRadius: BorderRadius.circular(themeService.getBorderRadius('large')),
                                      gradient: themeService.getDynamicButtonGradient(),
                                      boxShadow: [
                                        BoxShadow(
                                          color: themeService.getColor('secondary1').withOpacity(0.3),
                                          spreadRadius: 0,
                                          blurRadius: themeService.getElevation('medium') * 3,
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
                                          borderRadius: BorderRadius.circular(themeService.getBorderRadius('large')),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  themeService.getColor('loginButtonTextColor'),
                                                ),
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              _customLabels?['login_button'] ?? 'LOGIN',
                                               style: textTheme.labelLarge?.copyWith(
                                                color: themeService.getColor('loginButtonTextColor'),
                                                fontWeight: FontWeight.bold,
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
                                          style: textTheme.bodyMedium,
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
                                              color: themeService.getColor('secondary1'),
                                              fontWeight: FontWeight.bold,
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
