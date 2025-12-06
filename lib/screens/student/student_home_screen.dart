import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../models/class_model.dart';
import '../launch_screen.dart';
import 'student_attendance_screen.dart';
import 'student_profile_screen.dart';
import '../../widgets/premium_logout_dialog.dart';
import '../../widgets/attendance_success_dialog.dart';
import 'qr_scanner_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({Key? key}) : super(key: key);

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const _HomeTab(),
      const StudentAttendanceScreen(),
      const StudentProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QRScannerScreen(),
                  ),
                );
                // Optionally refresh the page if attendance was marked
                if (result == true && mounted) {
                  setState(() {});
                }
              },
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label: const Text(
                'Scan QR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'My Attendance',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab({Key? key}) : super(key: key);

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  late ConfettiController _confettiController;
  String? _studentId;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _loadStudentId();
  }

  Future<void> _loadStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studentId = prefs.getString('studentId');
    });
  }

  Future<Map<String, dynamic>> _getStudentInfoWithStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getString('studentId');

      String name = 'Student';
      int attended = 0;
      int total = 0;

      if (studentId != null) {
        // Get student name
        final doc = await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .get();

        if (doc.exists) {
          final data = doc.data();
          name = data?['name'] ?? studentId;
        }

        // Get all classes (this is the source of truth for total)
        final classesSnapshot = await FirebaseFirestore.instance
            .collection('classes')
            .get();
        total = classesSnapshot.docs.length;

        // Get the set of valid class IDs
        final validClassIds = classesSnapshot.docs.map((d) => d.id).toSet();

        // Get attended classes - only count those that exist in classes collection
        final attendanceSnapshot = await FirebaseFirestore.instance
            .collection('attendance')
            .where('studentId', isEqualTo: studentId)
            .get();

        // Only count attendance for classes that still exist
        attended = attendanceSnapshot.docs
            .where((doc) => validClassIds.contains(doc.data()['classId']))
            .length;
      }

      return {'name': name, 'attended': attended, 'total': total};
    } catch (e) {
      return {'name': 'Student', 'attended': 0, 'total': 0};
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<bool> _isAttendanceMarked(String classId) async {
    if (_studentId == null) return false;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('classId', isEqualTo: classId)
          .where('studentId', isEqualTo: _studentId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _showMarkAttendanceDialog(ClassModel classModel) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title with icon
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.blue[700],
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Mark Attendance',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Class info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue[100]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.book,
                                  size: 20,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    classModel.subjectName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (classModel.teacherName.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 18,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    classModel.teacherName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  classModel.scheduledDate,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Password field
                      Text(
                        'Enter Session Password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          hintText:
                              'Enter the password provided by your teacher',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Colors.blue[700],
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setModalState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.blue[700]!,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        obscureText: obscurePassword,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the password';
                          }
                          return null;
                        },
                        onFieldSubmitted: (value) async {
                          if (!formKey.currentState!.validate()) return;

                          final password = passwordController.text.trim();
                          if (password != classModel.password) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text('Incorrect password!'),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(context, true);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;

                                final password = passwordController.text.trim();
                                if (password != classModel.password) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text('Incorrect password!'),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                Navigator.pop(context, true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 2,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle),
                                  SizedBox(width: 8),
                                  Text(
                                    'Submit',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (result == true && mounted) {
      await _markAttendance(classModel);
    }
  }

  Future<void> _markAttendance(ClassModel classModel) async {
    try {
      final attendanceService = Provider.of<AttendanceService>(
        context,
        listen: false,
      );

      // Get student ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getString('studentId');

      if (studentId == null) {
        throw Exception('User not logged in');
      }

      // Use verifyAndMarkAttendance from AttendanceService
      final result = await attendanceService.verifyAndMarkAttendance(
        studentId,
        classModel.password,
      );

      if (!mounted) return;

      if (result.success) {
        // Refresh the UI to show updated attendance status
        setState(() {});

        // Show beautiful animated success dialog
        await showAttendanceSuccessDialog(
          context: context,
          subject: classModel.subjectName,
          message: result.message,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: Colors.red),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back button
        title: const Text(
          'Active Classes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await PremiumLogoutDialog.show(
                context: context,
                title: 'Logout',
                message: 'Are you sure you want to logout?',
                onConfirm: () async {
                  final authService = Provider.of<AuthService>(
                    context,
                    listen: false,
                  );
                  await authService.logout();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LaunchScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Header with gradient
              FutureBuilder<Map<String, dynamic>>(
                future: _getStudentInfoWithStats(),
                builder: (context, snapshot) {
                  final studentName = snapshot.data?['name'] ?? 'Student';
                  final attendedCount = snapshot.data?['attended'] ?? 0;
                  final totalClasses = snapshot.data?['total'] ?? 0;
                  final percentage = totalClasses > 0
                      ? (attendedCount / totalClasses * 100)
                      : 0.0;

                  // Time-based greeting
                  final hour = DateTime.now().hour;
                  String greeting = 'Good morning';
                  if (hour >= 12 && hour < 17) {
                    greeting = 'Good afternoon';
                  } else if (hour >= 17) {
                    greeting = 'Good evening';
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.blue[700]!, Colors.blue[900]!],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$greeting,',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    studentName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Mini attendance indicator
                            if (totalClasses > 0)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: CircularProgressIndicator(
                                            value: percentage / 100,
                                            strokeWidth: 4,
                                            backgroundColor: Colors.white
                                                .withOpacity(0.2),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  percentage >= 80
                                                      ? Colors.greenAccent
                                                      : percentage >= 60
                                                      ? Colors.orangeAccent
                                                      : Colors.redAccent,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          '${percentage.toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Attendance',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Quick stats row
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _QuickStat(
                                icon: Icons.check_circle,
                                label: 'Attended',
                                value: '$attendedCount',
                                color: Colors.greenAccent,
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              _QuickStat(
                                icon: Icons.event,
                                label: 'Total',
                                value: '$totalClasses',
                                color: Colors.white,
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              _QuickStat(
                                icon: Icons.cancel,
                                label: 'Missed',
                                value:
                                    '${(totalClasses - attendedCount).clamp(0, totalClasses)}',
                                color: Colors.redAccent,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Active Classes List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('classes')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      print('Error loading classes: ${snapshot.error}');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading classes',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Colors.blue[700],
                        ),
                      );
                    }

                    final now = DateTime.now();

                    final classes = snapshot.data!.docs
                        .map((doc) => ClassModel.fromFirestore(doc))
                        .where((classModel) {
                          // Check if current time is within the active time window
                          // passwordActiveFrom and passwordActiveUntil include both date AND time
                          final isActive =
                              now.isAfter(classModel.passwordActiveFrom) &&
                              now.isBefore(classModel.passwordActiveUntil);

                          // Also consider exactly at the boundaries
                          final isAtStart = now.isAtSameMomentAs(
                            classModel.passwordActiveFrom,
                          );
                          final isAtEnd = now.isAtSameMomentAs(
                            classModel.passwordActiveUntil,
                          );

                          final shouldShow = isActive || isAtStart || isAtEnd;

                          print(
                            'Class: ${classModel.subjectName}, '
                            'Now: $now, '
                            'ActiveFrom: ${classModel.passwordActiveFrom}, '
                            'ActiveUntil: ${classModel.passwordActiveUntil}, '
                            'IsActive: $shouldShow',
                          );

                          return shouldShow;
                        })
                        .toList();

                    if (classes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No active classes',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check back when a class is in session',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        // Refresh is automatic with StreamBuilder
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: classes.length,
                        itemBuilder: (context, index) {
                          final classModel = classes[index];
                          return FutureBuilder<bool>(
                            future: _isAttendanceMarked(classModel.classId),
                            builder: (context, snapshot) {
                              final isMarked = snapshot.data ?? false;
                              return _ClassCard(
                                classModel: classModel,
                                isAttendanceMarked: isMarked,
                                onMarkAttendance: () =>
                                    _showMarkAttendanceDialog(classModel),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Confetti animation
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.3,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ClassModel classModel;
  final bool isAttendanceMarked;
  final VoidCallback onMarkAttendance;

  const _ClassCard({
    Key? key,
    required this.classModel,
    required this.isAttendanceMarked,
    required this.onMarkAttendance,
  }) : super(key: key);

  String _formatTimeRemaining(DateTime activeUntil) {
    final now = DateTime.now();
    final difference = activeUntil.difference(now);

    if (difference.inHours > 0) {
      return 'Expires in ${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inMinutes > 0) {
      return 'Expires in ${difference.inMinutes}m';
    } else {
      return 'Expiring soon';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.blue[50]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with subject and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      classModel.subjectName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Teacher info
              if (classModel.teacherName.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.person, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      classModel.teacherName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Date info
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    classModel.scheduledDate,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Time info
              Row(
                children: [
                  Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${classModel.startTime} - ${classModel.endTime}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Expires info
              Row(
                children: [
                  Icon(Icons.timer, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimeRemaining(classModel.passwordActiveUntil),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mark Attendance Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isAttendanceMarked ? null : onMarkAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAttendanceMarked
                        ? Colors.green[600]
                        : Colors.blue[700],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.green[600],
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isAttendanceMarked
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAttendanceMarked
                            ? 'Attendance Marked ✓'
                            : 'Mark Attendance',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStat({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
        ),
      ],
    );
  }
}
