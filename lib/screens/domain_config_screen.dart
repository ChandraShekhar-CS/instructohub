import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login/login_screen.dart';
import 'package:flutter/material.dart';

class DomainConfigScreen extends StatefulWidget {
  const DomainConfigScreen({super.key});

  @override
  State<DomainConfigScreen> createState() => _DomainConfigScreenState();
}

class _DomainConfigScreenState extends State<DomainConfigScreen> with SingleTickerProviderStateMixin {
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
      final result = await ApiService.instance.testConnection(_domainController.text.trim());
      setState(() {
        _connectionResult = result;
      });

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Connected to ${result['siteName']}!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    
    if (_connectionResult == null || _connectionResult!['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please test the connection first'),
          backgroundColor: AppTheme.secondary1,
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
            backgroundColor: AppTheme.secondary1,
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
    
    final domain = value.trim().toLowerCase();
    
    // Basic domain validation
    final domainPattern = RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$');
    
    String cleanDomain = domain;
    if (cleanDomain.startsWith('http://') || cleanDomain.startsWith('https://')) {
      cleanDomain = Uri.parse(domain).host;
    }
    
    if (!domainPattern.hasMatch(cleanDomain)) {
      return 'Please enter a valid domain';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage('https://learn.instructohub.com/static/media/login-bg.e2a088d001b1fc451772.png'),
            fit: BoxFit.cover,
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
                                const Icon(
                                  Icons.cloud_outlined,
                                  size: 64,
                                  color: AppTheme.secondary1,
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Configure Your LMS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
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
                                    hintText: 'learn.instructohub.com or moodle.instructohub.com',
                                    prefixIcon: const Icon(
                                      Icons.public,
                                      color: AppTheme.secondary1,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppTheme.secondary1, width: 2),
                                    ),
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
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.cardColor,
                                          ),
                                        )
                                      : const Icon(Icons.wifi_find),
                                  label: Text(_isTestingConnection ? 'Testing...' : 'Test Connection'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.secondary2,
                                    foregroundColor: AppTheme.cardColor,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                if (_connectionResult != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _connectionResult!['success'] == true
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _connectionResult!['success'] == true
                                            ? Colors.green
                                            : Colors.red,
                                        width: 1,
                                      ),
                                    ),
                                    child: _connectionResult!['success'] == true
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green.shade700,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    'Connection Successful',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text('Site: ${_connectionResult!['siteName']}'),
                                              Text('Version: ${_connectionResult!['version']}'),
                                              if (_connectionResult!['originalDomain'] != _connectionResult!['apiDomain']) ...[
                                                const SizedBox(height: 8),
                                                const Text(
                                                  'Domain Conversion:',
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                Text('Frontend: ${_connectionResult!['originalDomain']}'),
                                                Text('API: ${_connectionResult!['apiDomain']}'),
                                              ],
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              Icon(
                                                Icons.error,
                                                color: Colors.red.shade700,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _connectionResult!['error'] ?? 'Connection failed',
                                                  style: const TextStyle(color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: (_isLoading || _connectionResult?['success'] != true) 
                                      ? null 
                                      : _saveAndContinue,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.secondary1,
                                    foregroundColor: AppTheme.cardColor,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
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
                                const Text(
                                  'Examples:\n• learn.instructohub.com (will auto-convert to moodle.instructohub.com)\n• moodle.yourdomain.com\n• https://subdomain.university.edu',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
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