import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';
import 'student_home_screen.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({Key? key}) : super(key: key);

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Login
      final result = await authService.studentLogin(
        _studentIdController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Navigate to home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[700]!, Colors.blue[900]!],
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
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo and Title
                          Container(
                            padding: EdgeInsets.all(
                              Responsive.value(
                                context,
                                mobile: 20,
                                tablet: 24,
                                desktop: 28,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.school,
                              size: Responsive.value(
                                context,
                                mobile: 80,
                                tablet: 90,
                                desktop: 100,
                              ),
                              color: Colors.blue[700],
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
                            'Student Portal',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 32),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
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

                          // Login Form Card
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: Responsive.value(
                                context,
                                mobile: 400,
                                tablet: 450,
                                desktop: 500,
                              ),
                            ),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 30),

                                  // Student ID Field
                                  TextFormField(
                                    controller: _studentIdController,
                                    decoration: InputDecoration(
                                      labelText: 'Student ID',
                                      hintText: 'Enter your student ID',
                                      prefixIcon: Icon(
                                        Icons.badge,
                                        color: Colors.blue[700],
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.blue[700]!,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _handleLogin(),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter your student ID';
                                      }
                                      if (value.trim().length < 3) {
                                        return 'Student ID must be at least 3 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 30),

                                  // Login Button
                                  SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[700],
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              'LOGIN',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Info Text
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.blue[200]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.blue[700],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Your device will be bound to your account on first login',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue[900],
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
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
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
      ),
    );
  }
}
