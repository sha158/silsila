import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import 'student/student_login_screen.dart';
import 'student/student_home_screen.dart';
import 'admin/admin_login_screen.dart';
import 'admin/admin_dashboard.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    await Future.delayed(const Duration(seconds: 2));
    final result = await _authService.checkAutoLogin();

    if (!mounted) return;

    if (result['autoLogin'] == true) {
      if (result['type'] == 'student') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
        );
      } else if (result['type'] == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
      }
    } else {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);
    final double logoWidth = Responsive.value(
      context,
      mobile: 300,
      tablet: 350,
      desktop: 400,
    );
    final double logoHeight = Responsive.value(
      context,
      mobile: 225,
      tablet: 262,
      desktop: 300,
    );
    final double maxContentWidth = Responsive.value(
      context,
      mobile: double.infinity,
      tablet: 500,
      desktop: 550,
    );

    return Scaffold(
      backgroundColor: Colors.blue.shade700,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade700, Colors.blue.shade900],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
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
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Icon/Logo - Arabic Calligraphy
                        SizedBox(
                          width: logoWidth,
                          height: logoHeight,
                          child: Image.asset(
                            'assets/arabic_calligraphy_logo_1764850116827-removebg-preview.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(
                          height: Responsive.value(
                            context,
                            mobile: 32,
                            tablet: 40,
                            desktop: 48,
                          ),
                        ),

                        // App Title
                        Text(
                          AppConstants.appName,
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 28),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'سلسلة الهدى والنور',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 24),
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chain of Guidance and Light',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 16),
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: Responsive.value(
                            context,
                            mobile: 60,
                            tablet: 70,
                            desktop: 80,
                          ),
                        ),

                        if (_isChecking) ...[
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: Responsive.fontSize(context, 14),
                            ),
                          ),
                        ],

                        if (!_isChecking) ...[
                          // Student Login Button
                          SizedBox(
                            width: double.infinity,
                            height: Responsive.value(
                              context,
                              mobile: 56,
                              tablet: 60,
                              desktop: 64,
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const StudentLoginScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Student Login',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 18),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: Responsive.value(
                              context,
                              mobile: 16,
                              tablet: 20,
                              desktop: 24,
                            ),
                          ),

                          // Admin Login Button
                          SizedBox(
                            width: double.infinity,
                            height: Responsive.value(
                              context,
                              mobile: 56,
                              tablet: 60,
                              desktop: 64,
                            ),
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const AdminLoginScreen(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Admin Login',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 18),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
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
