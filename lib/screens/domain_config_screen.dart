import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/icon_service.dart';
import './login/login_screen.dart';
import '../theme/dynamic_app_theme.dart';

typedef AppTheme = DynamicAppTheme;

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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    DynamicAppTheme.loadTheme();

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

    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(cleanValue)) {
      return 'Only letters and numbers allowed';
    }

    return null;
  }

  Future<void> _testTenantConnection() async {
    print('[DEBUG] Starting tenant connection test...');

    if (!_formKey.currentState!.validate()) {
      print('[DEBUG] Form validation failed.');
      return;
    }

    final tenantName = _tenantController.text.trim();
    print('[DEBUG] Tenant name input: "$tenantName"');

    final constructedUrl = _constructTenantUrl(tenantName);
    print('[DEBUG] Constructed URL: $constructedUrl');

    setState(() {
      _isTestingConnection = true;
      _connectionResult = null;
      _constructedUrl = constructedUrl;
    });

    try {
      print('[DEBUG] Attempting connection to $constructedUrl');

      final result =
          await ApiService.instance.testConnection(constructedUrl).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('[ERROR] Connection timeout for $constructedUrl');
          return {
            'success': false,
            'error':
                'Connection timeout. Please check your internet connection.',
            'originalDomain': constructedUrl,
          };
        },
      );

      print('[DEBUG] Connection test result for $constructedUrl: $result');

      setState(() {
        _connectionResult = result;
      });

      if (result['success'] == true) {
        final siteName = result['siteName'] ?? tenantName;
        print(
            '[INFO] Successfully connected to tenant: $siteName at $constructedUrl');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(IconService.instance.getIcon('success'),
                    color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Connected to $tenantName LMS!')),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } else {
        print(
            '[WARN] Failed to connect to tenant: $tenantName at $constructedUrl. Reason: ${result['error']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(IconService.instance.getIcon('error'),
                    color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text(
                        'Not registered. Please try again or contact your admin.')),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e, stackTrace) {
      print(
          '[EXCEPTION] Error while testing connection for $tenantName at $constructedUrl: $e');
      print('[STACKTRACE] $stackTrace');
      setState(() {
        _connectionResult = {
          'success': false,
          'error': 'Not registered. Please try again or contact your admin.',
          'originalDomain': constructedUrl,
        };
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(IconService.instance.getIcon('error'), color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text(
                      'Not registered. Please try again or contact your admin.')),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
      print(
          '[DEBUG] Connection test finished for $tenantName at $constructedUrl');
    }
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    if (_connectionResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please test the connection first'),
          backgroundColor: AppTheme.info,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_connectionResult!['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please establish a successful connection first'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.instance.configure(_constructedUrl!);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Configuration failed: ${e.toString()}'),
            backgroundColor: AppTheme.error,
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

  bool get _canProceed {
    return _connectionResult != null &&
        _connectionResult!['success'] == true &&
        !_isLoading;
  }

  Widget _buildConnectionStatus() {
    if (_connectionResult == null) return const SizedBox.shrink();

    final bool isSuccess = _connectionResult!['success'] == true;
    final String tenantName = _tenantController.text.trim();

    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: AppTheme.getStatusDecoration(isSuccess ? 'success' : 'error'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                IconService.instance.getIcon(isSuccess ? 'success' : 'error'),
                color:
                    AppTheme.getStatusTextStyle(isSuccess ? 'success' : 'error')
                        .color,
                size: 20,
              ),
              SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  isSuccess ? 'Connected to $tenantName LMS' : 'Not Registered',
                  style: AppTheme.getStatusTextStyle(
                          isSuccess ? 'success' : 'error')
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (!isSuccess) ...[
            SizedBox(height: AppTheme.spacingSm),
            Text(
              'Please try again or contact your admin.',
              style:
                  AppTheme.getStatusTextStyle('error').copyWith(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.background.withOpacity(0.5),
              AppTheme.background,
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
                            color: AppTheme.cardColor.withOpacity(0.95),
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
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Icon(
                                  IconService.instance.cloudIcon,
                                  size: 64,
                                  color: AppTheme.secondary1,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Connect to Your LMS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Enter your organization name to get started',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                TextFormField(
                                  controller: _tenantController,
                                  decoration: InputDecoration(
                                    labelText: 'LMS Domain',
                                    hintText: 'instructohub.com',
                                    helperText:
                                        'Enter only your organization name',
                                    prefixIcon: Icon(
                                      IconService.instance.getIcon('domain'),
                                      color: AppTheme.secondary1,
                                    ),
                                    border:
                                        AppTheme.inputDecorationTheme.border,
                                    enabledBorder: AppTheme
                                        .inputDecorationTheme.enabledBorder,
                                    focusedBorder: AppTheme
                                        .inputDecorationTheme.focusedBorder,
                                    filled: true,
                                    fillColor: AppTheme.cardColor,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[a-zA-Z0-9]')),
                                    LengthLimitingTextInputFormatter(20),
                                  ],
                                  validator: _validateTenant,
                                  onChanged: (value) {
                                    if (_connectionResult != null) {
                                      setState(() {
                                        _connectionResult = null;
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
                                            color: AppTheme.cardColor,
                                          ),
                                        )
                                      : Icon(
                                          IconService.instance.getIcon('wifi')),
                                  label: Text(_isTestingConnection
                                      ? 'Checking Registration...'
                                      : 'Check Registration'),
                                  style: AppTheme.secondaryButtonStyle,
                                ),
                                if (_connectionResult != null) ...[
                                  const SizedBox(height: 16),
                                  _buildConnectionStatus(),
                                ],
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed:
                                      _canProceed ? _saveAndContinue : null,
                                  style: AppTheme.primaryButtonStyle,
                                  child: _isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.cardColor,
                                          ),
                                        )
                                      : const Text(
                                          'Continue to Login',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
