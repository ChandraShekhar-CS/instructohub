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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    DynamicAppTheme.loadTheme();

    // Set default domain for development
    _tenantController.text = 'learn.instructohub.com';

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

    // Auto-test the default domain
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testConnection();
    });
  }

  @override
  void dispose() {
    _tenantController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateDomain(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Domain is required';
    }

    final cleanValue = value.trim();

    if (cleanValue.length < 3) {
      return 'Domain must be at least 3 characters';
    }

    return null;
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTestingConnection = true;
      _connectionResult = null;
    });

    try {
      final domain = _tenantController.text.trim();
      final result = await ApiService.instance.testConnection(domain).timeout(
        const Duration(seconds: 10),
        onTimeout: () => {
          'success': false,
          'error': 'Connection timeout. Please check your internet connection.',
          'originalDomain': domain,
        },
      );

      setState(() {
        _connectionResult = result;
      });

      if (result['success'] == true) {
        final siteName = result['siteName'] ?? 'LMS Portal';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(IconService.instance.getIcon('success'), color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Connected to $siteName!'),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(IconService.instance.getIcon('warning'), color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(result['error'] ?? 'Connection failed'),
                ),
              ],
            ),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _connectionResult = {
          'success': false,
          'error': 'Connection failed: ${e.toString()}',
          'originalDomain': _tenantController.text.trim(),
        };
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.instance.configure(_tenantController.text.trim());

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
    return !_isLoading;
  }

  Widget _buildConnectionStatus() {
    if (_connectionResult == null && !_isTestingConnection) return const SizedBox.shrink();

    if (_isTestingConnection) {
      return Container(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.info.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.info.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.info,
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Text(
              'Testing connection...',
              style: TextStyle(
                color: AppTheme.info,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final bool isSuccess = _connectionResult!['success'] == true;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: AppTheme.getStatusDecoration(isSuccess ? 'success' : 'warning'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                IconService.instance.getIcon(isSuccess ? 'success' : 'warning'),
                color: AppTheme.getStatusTextStyle(isSuccess ? 'success' : 'warning').color,
                size: 20,
              ),
              SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  isSuccess
                      ? 'Connection Successful'
                      : 'Connection Issues',
                  style: AppTheme.getStatusTextStyle(isSuccess ? 'success' : 'warning').copyWith(
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ],
          ),
          if (_connectionResult!['siteName'] != null) ...[
            SizedBox(height: AppTheme.spacingSm),
            Text(
              'Site: ${_connectionResult!['siteName']}',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          if (!isSuccess && _connectionResult!['error'] != null) ...[
            SizedBox(height: AppTheme.spacingSm),
            Text(
              _connectionResult!['error'],
              style: AppTheme.getStatusTextStyle('warning').copyWith(
                fontSize: 13
              ),
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
                                  'Connect to LMS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Configure your learning management system',
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
                                    hintText: 'learn.instructohub.com',
                                    helperText: 'Enter your LMS domain URL',
                                    prefixIcon: Icon(
                                      IconService.instance.getIcon('domain'),
                                      color: AppTheme.secondary1,
                                    ),
                                    border: AppTheme.inputDecorationTheme.border,
                                    enabledBorder: AppTheme.inputDecorationTheme.enabledBorder,
                                    focusedBorder: AppTheme.inputDecorationTheme.focusedBorder,
                                    filled: true,
                                    fillColor: AppTheme.cardColor,
                                  ),
                                  validator: _validateDomain,
                                  onChanged: (value) {
                                    if (_connectionResult != null) {
                                      setState(() {
                                        _connectionResult = null;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _isTestingConnection ? null : _testConnection,
                                  icon: _isTestingConnection
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.cardColor,
                                          ),
                                        )
                                      : Icon(IconService.instance.getIcon('wifi')),
                                  label: Text(_isTestingConnection
                                      ? 'Testing Connection...'
                                      : 'Test Connection'),
                                  style: AppTheme.secondaryButtonStyle,
                                ),
                                const SizedBox(height: 16),
                                _buildConnectionStatus(),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _canProceed ? _saveAndContinue : null,
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
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.info.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        IconService.instance.getIcon('info'),
                                        size: 16,
                                        color: AppTheme.info,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Development Mode: Using learn.instructohub.com as default',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.info,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
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