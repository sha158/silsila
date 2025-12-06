import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_students_screen.dart';
import 'manage_classes_screen.dart';
import 'export_attendance_screen.dart';
import 'attendance_analytics_screen.dart';
import 'attendance_report_screen.dart';
import 'manual_attendance_screen.dart';
import '../../services/auth_service.dart';
import '../launch_screen.dart';
import '../../widgets/premium_logout_dialog.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _todaysSessions = [];
  int _totalStudents = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodaysData();
  }

  Future<void> _loadTodaysData() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Get today's classes
      final classesSnapshot = await _firestore.collection('classes').get();

      // Get total active students
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('isActive', isEqualTo: true)
          .get();

      _totalStudents = studentsSnapshot.docs.length;

      // Get all attendance records
      final attendanceSnapshot = await _firestore.collection('attendance').get();

      // Build attendance map: classId -> set of studentIds
      Map<String, Set<String>> attendanceMap = {};
      for (var doc in attendanceSnapshot.docs) {
        final classId = doc.data()['classId'] as String?;
        final studentId = doc.data()['studentId'] as String?;
        if (classId != null && studentId != null) {
          attendanceMap.putIfAbsent(classId, () => {});
          attendanceMap[classId]!.add(studentId);
        }
      }

      // Filter today's classes
      _todaysSessions = [];
      for (var doc in classesSnapshot.docs) {
        final data = doc.data();
        final passwordActiveFrom = data['passwordActiveFrom'] as Timestamp?;

        if (passwordActiveFrom != null) {
          final classDate = passwordActiveFrom.toDate();
          final classDateOnly = DateTime(classDate.year, classDate.month, classDate.day);

          if (classDateOnly.isAtSameMomentAs(todayStart)) {
            final presentCount = attendanceMap[doc.id]?.length ?? 0;
            final absentCount = _totalStudents - presentCount;

            _todaysSessions.add({
              'id': doc.id,
              'subjectName': data['subjectName'] ?? 'Unknown',
              'teacherName': data['teacherName'] ?? 'Unknown',
              'time': passwordActiveFrom,
              'presentCount': presentCount,
              'absentCount': absentCount,
              'totalStudents': _totalStudents,
            });
          }
        }
      }

      // Sort by time
      _todaysSessions.sort((a, b) {
        final aTime = (a['time'] as Timestamp).toDate();
        final bTime = (b['time'] as Timestamp).toDate();
        return bTime.compareTo(aTime);
      });

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await PremiumLogoutDialog.show(
      context: context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      onConfirm: () async {
        final authService = AuthService();
        await authService.logout();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LaunchScreen()),
            (route) => false,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Modern Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6366F1),
                      const Color(0xFF8B5CF6),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Dashboard',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your attendance system',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            onPressed: () => _logout(context),
                            tooltip: 'Logout',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Today's Sessions Overview
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Today\'s Sessions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          onPressed: _loadTodaysData,
                          color: const Color(0xFF6366F1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_todaysSessions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy_rounded,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No sessions today',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._todaysSessions.map((session) {
                        final time = (session['time'] as Timestamp).toDate();
                        final presentCount = session['presentCount'] as int;
                        final absentCount = session['absentCount'] as int;
                        final totalStudents = session['totalStudents'] as int;
                        final percentage = totalStudents > 0
                            ? (presentCount / totalStudents * 100)
                            : 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.book_rounded,
                                      color: Color(0xFF6366F1),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          session['subjectName'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        Text(
                                          '${session['teacherName']} • ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: percentage >= 70
                                          ? Colors.green.shade50
                                          : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${percentage.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: percentage >= 70
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildAttendanceCount(
                                      'Present',
                                      presentCount,
                                      Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildAttendanceCount(
                                      'Absent',
                                      absentCount,
                                      Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildAttendanceCount(
                                      'Total',
                                      totalStudents,
                                      Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),

            // Quick Stats Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Access',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            context: context,
                            title: 'Today\'s\nAnalytics',
                            icon: Icons.insights_rounded,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AttendanceAnalyticsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionCard(
                            context: context,
                            title: 'Student\nReports',
                            icon: Icons.bar_chart_rounded,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AttendanceReportScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Management Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: const Text(
                  'Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ),

            // Management Grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildListDelegate([
                  _buildManagementCard(
                    context: context,
                    title: 'Students',
                    subtitle: 'Add & manage',
                    icon: Icons.group_rounded,
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ViewStudentsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildManagementCard(
                    context: context,
                    title: 'Classes',
                    subtitle: 'Sessions & QR',
                    icon: Icons.class_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ManageClassesScreen(),
                        ),
                      );
                    },
                  ),
                  _buildManagementCard(
                    context: context,
                    title: 'Mark Attendance',
                    subtitle: 'Manual entry',
                    icon: Icons.how_to_reg_rounded,
                    color: const Color(0xFFEC4899),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ManualAttendanceScreen(),
                        ),
                      );
                    },
                  ),
                  _buildManagementCard(
                    context: context,
                    title: 'Export',
                    subtitle: 'Download data',
                    icon: Icons.download_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ExportAttendanceScreen(),
                        ),
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCount(String label, int count, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
