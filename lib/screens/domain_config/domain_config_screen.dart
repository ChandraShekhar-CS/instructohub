import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:InstructoHub/services/api_service.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';
import 'package:InstructoHub/services/enhanced_icon_service.dart';
import 'package:InstructoHub/screens/login/login_screen.dart';

class DomainConfigScreen extends StatefulWidget {
  const DomainConfigScreen({super.key});

  @override
  State<DomainConfigScreen> createState() => _DomainConfigScreenState();
}

class _DomainConfigScreenState extends State<DomainConfigScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _tenantController = TextEditingController();
  bool _isLoading = false;
  bool _isTestingConnection = false;
  Map<String, dynamic>? _connectionResult;
  String? _constructedUrl;
  bool _isBrandingLoaded = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  static const Color primaryColor = Color(0xFFE16A3A);
  static const Color secondaryColor = Color(0xFF1B3942);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color successColor = Color(0xFF48BB78);
  static const Color errorColor = Color(0xFFE53E3E);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _tenantController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _constructTenantUrl(String tenantName) {
    final cleanTenant = tenantName.toLowerCase().trim();
    return '$cleanTenant.mdl.instructohub.com';
  }

  String? _validateTenant(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Organization name is required';
    }
    final cleanValue = value.trim();
    if (cleanValue.length < 3) {
      return 'Name must be at least 3 characters';
    }
    if (cleanValue.length > 20) {
      return 'Name must be less than 20 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9\-]+$').hasMatch(cleanValue)) {
      return 'Only letters, numbers, and hyphens allowed';
    }
    return null;
  }

  Map<String, dynamic>? _themeData;
  String? _logoUrl;

  Future<Map<String, dynamic>?> _fetchThemeData(String tenantUrl) async {
    try {
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
      print('Theme API Response Body: ${response.body}');
      
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
          } else {
            print('No active theme found');
          }
        }
      } else {
        print('Failed to fetch theme data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching theme data: $e');
    }
    return null;
  }

  Future<void> _testTenantConnection() async {
    final themeService = DynamicThemeService.instance;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final tenantName = _tenantController.text.trim();
    final constructedUrl = _constructTenantUrl(tenantName);

    setState(() {
      _isTestingConnection = true;
      _connectionResult = null;
      _isBrandingLoaded = false;
      _constructedUrl = constructedUrl;
    });

    try {
      final result = await ApiService.instance
          .testConnection(constructedUrl)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (result['success'] == true) {
        await ApiService.instance.configure(constructedUrl);
        await themeService.loadTheme();

        final themeData = await _fetchThemeData(constructedUrl);
        
        setState(() {
          _connectionResult = result;
          _isBrandingLoaded = true;
          _themeData = themeData;
          if (themeData != null && themeData['logo_image'] != null) {
            _logoUrl = themeData['logo_image'];
            print('Setting logo URL: $_logoUrl');
          }
        });

        _showSuccessSnackBar('Connected to ${themeService.siteName ?? tenantName} LMS!');
      } else {
        setState(() => _connectionResult = result);
        _showErrorSnackBar('Not registered. Please try again or contact your admin.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connectionResult = {
          'success': false,
          'error': 'An unexpected error occurred.',
          'originalDomain': constructedUrl
        };
      });
      _showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    if (_connectionResult == null || _connectionResult!['success'] != true) {
      _showErrorSnackBar('Please establish a successful connection first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Configuration failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool get _canProceed =>
      _connectionResult != null &&
      _connectionResult!['success'] == true &&
      !_isLoading;

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          height: 80,
          constraints: const BoxConstraints(
            minWidth: 80,
            maxWidth: 200,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.network(
            'https://static.instructohub.com/staticfiles/assets/images/website/Instructo_hub_logo.png',
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryColor,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stacktrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.cloud_outlined,
                  size: 32,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Connect to Your Organization',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: secondaryColor,
            letterSpacing: -0.9,
          ),
        ),
        
        const SizedBox(height: 4),
        Text(
          'Enter your organization name to get started',
          style: TextStyle(
            fontSize: 14,
            color: textSecondary.withOpacity(0.8),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildBrandingHeader() {
    final themeService = DynamicThemeService.instance;
    final siteName = themeService.siteName ?? _tenantController.text.trim();

    if (_isBrandingLoaded && _logoUrl != null && _logoUrl!.isNotEmpty) {
      print('Displaying logo: $_logoUrl');
      return Column(
        children: [
          Container(
            height: 80,
            constraints: const BoxConstraints(
              minWidth: 80,
              maxWidth: 250,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Image.network(
              _logoUrl!,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                print('Loading logo...');
                return Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryColor,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stacktrace) {
                print('Logo loading error: $error');
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business,
                    size: 32,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            siteName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: secondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: successColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 16, color: successColor),
                const SizedBox(width: 6),
                Text(
                  'Connected Successfully',
                  style: TextStyle(
                    color: successColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return _buildHeader();
  }

  Widget _buildInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'URL of your organization',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _tenantController,
          decoration: InputDecoration(
            hintText: 'INSTRUCTOHUB',
            helperText: 'Enter only your organization url',
            helperStyle: TextStyle(color: textSecondary, fontSize: 14),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.domain,
                size: 18,
                color: primaryColor,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: errorColor, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: errorColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
          style: TextStyle(
            fontSize: 16,
            color: textPrimary,
            fontWeight: FontWeight.w500,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
            LengthLimitingTextInputFormatter(20),
          ],
          validator: _validateTenant,
          onChanged: (value) {
            if (_connectionResult != null) {
              setState(() {
                _connectionResult = null;
                _isBrandingLoaded = false;
                _constructedUrl = null;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildTestButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
      ),
      child: ElevatedButton.icon(
        onPressed: _isTestingConnection ? null : _testTenantConnection,
        icon: _isTestingConnection
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryColor,
                ),
              )
            : Icon(Icons.wifi_find, color: primaryColor),
        label: Text(
          _isTestingConnection ? 'Checking Connection...' : 'Test Connection',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: primaryColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: _canProceed
              ? [primaryColor, primaryColor.withOpacity(0.8)]
              : [Colors.grey.shade400, Colors.grey.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: _canProceed
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: _canProceed ? _saveAndContinue : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Continue to Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: Colors.white,
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3, 1.0],
            colors: [
              primaryColor.withOpacity(0.05),
              backgroundColor.withOpacity(0.8),
              backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: secondaryColor.withOpacity(0.08),
                                  spreadRadius: 0,
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                ),
                                BoxShadow(
                                  color: secondaryColor.withOpacity(0.04),
                                  spreadRadius: 0,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildBrandingHeader(),
                                  const SizedBox(height: 40),
                                  _buildInputField(),
                                  const SizedBox(height: 24),
                                  _buildTestButton(),
                                  const SizedBox(height: 16),
                                  _buildContinueButton(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}