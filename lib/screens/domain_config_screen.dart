import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/icon_service.dart';
import '../theme/app_theme.dart';
import 'login/login_screen.dart';

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
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Connected to ${result['siteName']}!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
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
        const SnackBar(
          content: Text('Please test the connection first'),
          backgroundColor: AppTheme.secondary1,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Accept connection if either fully successful OR if Moodle instance was detected
    final isValidConnection = _connectionResult!['success'] == true ||
        (_connectionResult!['siteName'] != null &&
            _connectionResult!['apiDomain'] != null);

    if (!isValidConnection) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_connectionResult!['error'] ??
              'Unable to connect to Moodle instance'),
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
    final domainPattern = RegExp(
        r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$');

    String cleanDomain = domain;
    if (cleanDomain.startsWith('http://') ||
        cleanDomain.startsWith('https://')) {
      cleanDomain = Uri.parse(domain).host;
    }

    if (!domainPattern.hasMatch(cleanDomain)) {
      return 'Please enter a valid domain';
    }

    return null;
  }

  bool get _canProceed {
    if (_connectionResult == null || _isLoading) return false;

    return _connectionResult!['success'] == true ||
        (_connectionResult!['siteName'] != null &&
            _connectionResult!['apiDomain'] != null);
  }

  Widget _buildDetailedConnectionResult() {
    if (_connectionResult == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _connectionResult!['success'] == true
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _connectionResult!['success'] == true
              ? Colors.green
              : Colors.orange,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _connectionResult!['success'] == true
                    ? IconService.instance.getIcon('success')
                    : IconService.instance.infoIcon,
                color: _connectionResult!['success'] == true
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _connectionResult!['success'] == true
                      ? 'Connection Successful'
                      : 'Moodle Instance Detected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _connectionResult!['success'] == true
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Site Information
          if (_connectionResult!['siteName'] != null)
            _buildInfoRow('Site', _connectionResult!['siteName']),

          // Error details if any
          if (_connectionResult!['error'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(IconService.instance.getIcon('error'),
                      color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _connectionResult!['error'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
                'https://learn.instructohub.com/static/media/login-bg.e2a088d001b1fc451772.png'),
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
                                Icon(
                                  IconService.instance.cloudIcon,
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
                                    hintText: 'moodle.instructohub.com',
                                    prefixIcon: const Icon(
                                      Icons.public,
                                      color: AppTheme.secondary1,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppTheme.secondary1, width: 2),
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
                                  onPressed: _isTestingConnection
                                      ? null
                                      : _testConnection,
                                  icon: _isTestingConnection
                                      ? const SizedBox(
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
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.secondary2,
                                    foregroundColor: AppTheme.cardColor,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                if (_connectionResult != null) ...[
                                  const SizedBox(height: 16),
                                  _buildDetailedConnectionResult(),
                                ],
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed:
                                      _canProceed ? _saveAndContinue : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.secondary1,
                                    foregroundColor: AppTheme.cardColor,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
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
