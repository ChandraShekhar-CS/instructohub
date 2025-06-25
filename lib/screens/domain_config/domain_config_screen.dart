import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // State to hold branding info after successful test
  bool _isBrandingLoaded = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
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
      // First, test the basic connection
      final result = await ApiService.instance
          .testConnection(constructedUrl)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (result['success'] == true) {
        // If connection is good, configure the API service to fetch theme
        await ApiService.instance.configure(constructedUrl);
        // Now, load the theme and branding data from the new domain
        await themeService.loadTheme();

        setState(() {
          _connectionResult = result;
          _isBrandingLoaded = true;
        });

        final snackBarContent = Row(
          children: [
            Icon(DynamicIconService.instance.getIcon('success'),
                color: themeService.getColor('loginButtonTextColor')),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    'Connected to ${themeService.siteName ?? tenantName} LMS!')),
          ],
        );

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: snackBarContent,
          backgroundColor: themeService.getColor('success'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(themeService.getBorderRadius('small'))),
        ));
      } else {
        // Handle failed connection
        setState(() => _connectionResult = result);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text(
              'Not registered. Please try again or contact your admin.'),
          backgroundColor: themeService.getColor('error'),
          behavior: SnackBarBehavior.floating,
        ));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('An error occurred. Please try again.'),
        backgroundColor: themeService.getColor('error'),
      ));
    } finally {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
        });
      }
    }
  }

  Future<void> _saveAndContinue() async {
    final themeService = DynamicThemeService.instance;
    if (!_formKey.currentState!.validate()) return;

    if (_connectionResult == null || _connectionResult!['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please establish a successful connection first'),
        backgroundColor:
            themeService.getColor(_connectionResult == null ? 'info' : 'error'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // The configuration is already set from the successful test
      // No need to call ApiService.instance.configure again
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Configuration failed: ${e.toString()}'),
          backgroundColor: themeService.getColor('error'),
          behavior: SnackBarBehavior.floating,
        ));
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

  Widget _buildLogoHeader() {
    final themeService = DynamicThemeService.instance;
    final logoUrl = themeService.logoUrl;
    final siteName = themeService.siteName;

    // Show the logo and site name if branding is loaded
    if (_isBrandingLoaded && logoUrl != null && logoUrl.isNotEmpty) {
      return Column(
        children: [
          Image.network(
            logoUrl,
            height: 64,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stacktrace) {
              // Fallback to text if image fails to load
              return Text(
                siteName ?? 'InstructoHub',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: themeService.getColor('secondary1'),
                    ),
              );
            },
          ),
          if (siteName != null) ...[
            const SizedBox(height: 16),
            Text(
              siteName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ]
        ],
      );
    }

    // Default icon before connection test
    return Icon(
      DynamicIconService.instance.getIcon('cloud'),
      size: 64,
      color: themeService.getColor('secondary1'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    final inputDecorationTheme = Theme.of(context).inputDecorationTheme;

    return Scaffold(
      backgroundColor: themeService.getColor('background'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeService.getColor('background').withOpacity(0.5),
              themeService.getColor('background'),
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
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: themeService.getColor('cardColor'),
                            borderRadius: BorderRadius.circular(
                                themeService.getBorderRadius('large')),
                            boxShadow: [
                              BoxShadow(
                                color: themeService
                                    .getColor('textPrimary')
                                    .withOpacity(0.1),
                                spreadRadius: 5,
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildLogoHeader(),
                                const SizedBox(height: 24),
                                if (!_isBrandingLoaded) ...[
                                  Text(
                                    'Connect to Your LMS',
                                    textAlign: TextAlign.center,
                                    style: textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Enter your organization name to get started',
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium,
                                  ),
                                ],
                                const SizedBox(height: 32),
                                TextFormField(
                                  controller: _tenantController,
                                  decoration: InputDecoration(
                                    labelText: 'LMS Domain',
                                    hintText: 'e.g., my-organization',
                                    helperText:
                                        'Enter only your organization name',
                                    prefixIcon: Icon(
                                      DynamicIconService.instance
                                          .getIcon('domain'),
                                      color:
                                          themeService.getColor('secondary1'),
                                    ),
                                    border: inputDecorationTheme.border,
                                    enabledBorder:
                                        inputDecorationTheme.enabledBorder,
                                    focusedBorder:
                                        inputDecorationTheme.focusedBorder,
                                    filled: inputDecorationTheme.filled,
                                    fillColor: inputDecorationTheme.fillColor,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[a-zA-Z0-9\-]')),
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
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _isTestingConnection
                                      ? null
                                      : _testTenantConnection,
                                  icon: _isTestingConnection
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: themeService
                                                .getColor('textPrimary'),
                                          ),
                                        )
                                      : Icon(
                                          DynamicIconService.instance
                                              .getIcon('wifi'),
                                          color: themeService
                                              .getColor('textPrimary')),
                                  label: Text(
                                    _isTestingConnection
                                        ? 'Checking...'
                                        : 'Check Registration',
                                    style: textTheme.bodyLarge?.copyWith(
                                        color: themeService
                                            .getColor('textPrimary')),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        themeService.getColor('cardColor'),
                                    side: BorderSide(
                                        color: themeService
                                            .getColor('secondary1')),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed:
                                      _canProceed ? _saveAndContinue : null,
                                  child: _isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: themeService.getColor(
                                                'loginButtonTextColor'),
                                          ),
                                        )
                                      : const Text('Continue to Login'),
                                ),
                              ],
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
