import 'package:flutter/material.dart';
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
  final _domainController = TextEditingController();
  bool _isLoading = false;
  bool _isTestingConnection = false;
  Map<String, dynamic>? _connectionResult;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Pre-load the default theme and icons for this screen
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
    _domainController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTestingConnection = true;
      _connectionResult = null;
    });

    try {
      final result = await ApiService.instance
          .testConnection(_domainController.text.trim());
      setState(() {
        _connectionResult = result;
      });

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(IconService.instance.getIcon('success'), color: Colors.white), // CHANGED
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Connected to ${result['siteName']}!'),
                ),
              ],
            ),
            backgroundColor: AppTheme.success, // CHANGED
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _connectionResult = {
          'success': false,
          'error': e.toString(),
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

    if (_connectionResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar( // REMOVED const
          content: const Text('Please test the connection first'),
          backgroundColor: AppTheme.info, // CHANGED
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isValidConnection = _connectionResult!['success'] == true ||
        (_connectionResult!['siteName'] != null &&
            _connectionResult!['apiDomain'] != null);

    if (!isValidConnection) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_connectionResult!['error'] ??
              'Unable to connect to Moodle instance'),
          backgroundColor: AppTheme.error, // CHANGED
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.instance.configure(_domainController.text.trim());

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
            backgroundColor: AppTheme.error, // CHANGED
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

  String? _validateDomain(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Domain is required';
    }
    // More robust validation can be added here
    return null;
  }

  bool get _canProceed {
    if (_connectionResult == null || _isLoading) return false;
    return _connectionResult!['success'] == true ||
        (_connectionResult!['siteName'] != null &&
            _connectionResult!['apiDomain'] != null);
  }

  // REFACTORED: This widget now uses dynamic theme colors for statuses
  Widget _buildDetailedConnectionResult() {
    if (_connectionResult == null) return const SizedBox.shrink();

    final bool isSuccess = _connectionResult!['success'] == true;
    final String status = isSuccess ? 'success' : 'warning';
    
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: AppTheme.getStatusDecoration(status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                IconService.instance.getIcon(status),
                color: AppTheme.getStatusTextStyle(status).color,
                size: 20,
              ),
              SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  isSuccess
                      ? 'Connection Successful'
                      : 'Moodle Instance Detected',
                  style: AppTheme.getStatusTextStyle(status).copyWith(
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),

          if (_connectionResult!['siteName'] != null)
            _buildInfoRow('Site', _connectionResult!['siteName']),
          
          if (_connectionResult!['error'] != null) ...[
            SizedBox(height: AppTheme.spacingSm),
            Container(
              padding: EdgeInsets.all(AppTheme.spacingSm),
              decoration: AppTheme.getStatusDecoration('error'),
              child: Row(
                children: [
                  Icon(
                    IconService.instance.getIcon('error'),
                    color: AppTheme.error,
                    size: 16
                  ),
                  SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      _connectionResult!['error'],
                      style: AppTheme.getStatusTextStyle('error').copyWith(
                        fontSize: AppTheme.fontSizeXs
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: AppTheme.textPrimary
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
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
          // Using a theme color as a semi-transparent overlay on the image
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
                                Text( // REMOVED const
                                  'Configure Your LMS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text( // REMOVED const
                                  'Enter your LMS domain to get started',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                TextFormField(
                                  controller: _domainController,
                                  decoration: InputDecoration(
                                    labelText: 'LMS Domain',
                                    hintText: 'moodle.instructohub.com',
                                    // Using the theme's input decoration as a base
                                    prefixIcon: Icon( // REMOVED const
                                      IconService.instance.getIcon('domain'), // CHANGED
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
                                  onPressed: _isTestingConnection
                                      ? null
                                      : _testConnection,
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
                                      ? 'Testing...'
                                      : 'Test Connection'),
                                  style: AppTheme.secondaryButtonStyle, // CHANGED
                                ),
                                if (_connectionResult != null) ...[
                                  const SizedBox(height: 16),
                                  _buildDetailedConnectionResult(),
                                ],
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed:
                                      _canProceed ? _saveAndContinue : null,
                                  style: AppTheme.primaryButtonStyle, // CHANGED
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