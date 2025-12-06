import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';
import 'admin_dashboard.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _keepMeLoggedIn = false;

  // SharedPreferences keys
  static const String _keyEmail = 'admin_saved_email';
  static const String _keyPassword = 'admin_saved_password';
  static const String _keyKeepLoggedIn = 'admin_keep_logged_in';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keepLoggedIn = prefs.getBool(_keyKeepLoggedIn) ?? false;

      if (keepLoggedIn) {
        final savedEmail = prefs.getString(_keyEmail) ?? '';
        final savedPassword = prefs.getString(_keyPassword) ?? '';

        setState(() {
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
          _keepMeLoggedIn = true;
        });
      }
    } catch (e) {
      // Ignore errors loading saved credentials
      debugPrint('Error loading saved credentials: $e');
    }
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_keepMeLoggedIn) {
        await prefs.setString(_keyEmail, _emailController.text.trim());
        await prefs.setString(_keyPassword, _passwordController.text);
        await prefs.setBool(_keyKeepLoggedIn, true);
      } else {
        await prefs.remove(_keyEmail);
        await prefs.remove(_keyPassword);
        await prefs.setBool(_keyKeepLoggedIn, false);
      }
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authService.adminLogin(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        if (result['success'] == true) {
          // Save credentials if "Keep me logged in" is checked
          await _saveCredentials();

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Login failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade700, Colors.blue.shade900],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.value(
                  context,
                  mobile: 24.0,
                  tablet: 48.0,
                  desktop: 64.0,
                ),
                vertical: 24.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.value(
                      context,
                      mobile: double.infinity,
                      tablet: 500,
                      desktop: 550,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Logo - Arabic Calligraphy
                        SizedBox(
                          width: Responsive.value(
                            context,
                            mobile: 250,
                            tablet: 280,
                            desktop: 300,
                          ),
                          height: Responsive.value(
                            context,
                            mobile: 180,
                            tablet: 200,
                            desktop: 220,
                          ),
                          child: Image.asset(
                            'assets/arabic_calligraphy_logo_1764850116827-removebg-preview.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(
                          height: Responsive.value(
                            context,
                            mobile: 30,
                            tablet: 35,
                            desktop: 40,
                          ),
                        ),
                        Text(
                          'Admin Login',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 32),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'سلسلة الهدى والنور',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 16),
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(
                          height: Responsive.value(
                            context,
                            mobile: 50,
                            tablet: 60,
                            desktop: 70,
                          ),
                        ),
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(Icons.email),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Keep me logged in checkbox
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _keepMeLoggedIn,
                                        onChanged: (value) {
                                          setState(() {
                                            _keepMeLoggedIn = value ?? false;
                                          });
                                        },
                                        activeColor: Colors.blue.shade700,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _keepMeLoggedIn = !_keepMeLoggedIn;
                                        });
                                      },
                                      child: Text(
                                        'Keep me logged in',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 4,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : const Text(
                                            'Login',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: Responsive.value(
                            context,
                            mobile: 30,
                            tablet: 35,
                            desktop: 40,
                          ),
                        ),

                        // Back to Role Selection
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Back to Role Selection',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.fontSize(context, 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
