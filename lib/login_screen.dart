import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'app_theme.dart';

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

  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _fetchBrandAssets();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchBrandAssets() async {
    const String serviceToken = "74bfeaa03d534620f3b431d223330c68";
    final url = Uri.parse('https://moodle.instructohub.com/webservice/rest/server.php?wsfunction=core_webservice_get_site_info&moodlewsrestformat=json&wstoken=$serviceToken');
    const String fallbackLogoUrl = 'https://static.instructohub.com/staticfiles/assets/images/website/Instructo_hub_logo.png';

    try {
        final response = await http.get(url);

        if (mounted) {
            if (response.statusCode == 200) {
                final responseBody = json.decode(response.body);
                
                String? fetchedLogoUrl = responseBody['logourl'] ?? responseBody['userpictureurl'];
                
                if (fetchedLogoUrl != null && fetchedLogoUrl.isNotEmpty) {
                    if (fetchedLogoUrl.contains('pluginfile.php')) {
                        if (fetchedLogoUrl.contains('?')) {
                            fetchedLogoUrl += '&token=$serviceToken';
                        } else {
                            fetchedLogoUrl += '?token=$serviceToken';
                        }
                    }
                    
                    setState(() {
                        _logoUrl = fetchedLogoUrl;
                    });
                } else {
                    setState(() {
                        _logoUrl = fallbackLogoUrl;
                    });
                }
            } else {
                setState(() {
                    _logoUrl = fallbackLogoUrl;
                });
            }
        }
    } catch (e) {
      if (mounted) {
        setState(() {
            _logoUrl = fallbackLogoUrl;
        });
      }
    }
  }

  Future<void> _fetchAndSaveUserInfo(String token) async {
    final url = Uri.parse('https://moodle.instructohub.com/webservice/rest/server.php?wsfunction=core_webservice_get_site_info&moodlewsrestformat=json&wstoken=$token');
    try {
      final response = await http.post(url);
      if (mounted) {
        if (response.statusCode == 200) {
          final responseBody = json.decode(response.body);
          if (responseBody['errorcode'] == null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('userInfo', response.body);
          } else {
            throw Exception('Failed to fetch user info: ${responseBody['error']}');
          }
        } else {
          throw Exception('Failed to fetch user info. Status code: ${response.statusCode}');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final url = Uri.parse('https://moodle.instructohub.com/login/token.php?service=dapi');

      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'username': _usernameController.text.trim(),
            'password': _passwordController.text.trim(),
          },
        );

        if (mounted) {
          final contentType = response.headers['content-type'];
          
          if (response.statusCode == 200 && contentType != null && contentType.contains('application/json')) {
            final responseBody = json.decode(response.body);
            
            if (responseBody['token'] != null) {
              final String token = responseBody['token'];
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('authToken', token);

              await _fetchAndSaveUserInfo(token);

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DashboardScreen(token: token),
                ),
              );
            } else {
              String error = responseBody['error'] ?? 'Invalid username or password.';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: AppTheme.secondary1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else {
            String error = 'Failed to login (Code: ${response.statusCode}). Please try again later.';
            if (contentType != null && contentType.contains('application/json')) {
                final responseBody = json.decode(response.body);
                error = responseBody['error'] ?? 'An unknown error occurred.';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: AppTheme.secondary1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred: ${e.toString()}'),
              backgroundColor: AppTheme.secondary1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
  }
  
  Widget _buildNetworkImage(String? url, {double? height, double? width}) {
    if (url == null) {
      return SizedBox(
        height: height ?? 5,
        width: width ?? 100,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2, 
            color: AppTheme.primary1,
          ),
        ),
      );
    } else {
      return Image.network(
        url,
        height: height,
        width: width,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            height: height ?? 5,
            width: width ?? 100,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: AppTheme.primary1,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height ?? 5,
            width: width ?? 100,
            child: Image.network(
              'https://static.instructohub.com/staticfiles/assets/images/website/Instructo_hub_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error_outline, color: Colors.grey);
              },
            ),
          );
        },
      );
    }
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
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNetworkImage(_logoUrl, height: 20),
                const SizedBox(height: 60),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 1),
                            const Text(
                              'Welcome! Login to experience the future of education.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    decoration: AppTheme.inputDecoration,
                                    child: TextFormField(
                                      controller: _usernameController,
                                      decoration: InputDecoration(
                                        hintText: 'Enter your username',
                                        hintStyle: TextStyle(color: Colors.grey.shade400),
                                        prefixIcon: const Icon(
                                          Icons.person_outline, 
                                          color: AppTheme.secondary1,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(50),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: AppTheme.cardColor,
                                        contentPadding: const EdgeInsets.symmetric(
                                          vertical: 16, 
                                          horizontal: 16,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Username is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    decoration: AppTheme.inputDecoration,
                                    child: TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        hintText: 'Enter your password',
                                        hintStyle: TextStyle(color: Colors.grey.shade400),
                                        prefixIcon: const Icon(
                                          Icons.lock_outline, 
                                          color: AppTheme.secondary1,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: Colors.grey.shade400,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8.0),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: AppTheme.cardColor,
                                        contentPadding: const EdgeInsets.symmetric(
                                          vertical: 16, 
                                          horizontal: 16,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Password is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: _rememberMe ? AppTheme.secondary1 : Colors.transparent,
                                              border: Border.all(
                                                color: _rememberMe ? AppTheme.secondary1 : Colors.grey,
                                                width: 2,
                                              ),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _rememberMe = !_rememberMe;
                                                });
                                              },
                                              child: _rememberMe
                                                  ? const Icon(
                                                      Icons.check,
                                                      size: 16,
                                                      color: AppTheme.cardColor,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Stay signed in',
                                            style: TextStyle(
                                              color: AppTheme.primary1,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () {},
                                        child: const Text(
                                          'Forgot password?',
                                          style: TextStyle(
                                            color: AppTheme.primary1,
                                            fontSize: 14,
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
                                      borderRadius: BorderRadius.circular(8.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.secondary1,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                        foregroundColor: AppTheme.cardColor,
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.cardColor),
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'LOGIN',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "New User? ",
                                        style: TextStyle(
                                          color: AppTheme.secondary1,
                                          fontSize: 14,
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
                                          'Signup',
                                          style: TextStyle(
                                            color: AppTheme.primary1,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
