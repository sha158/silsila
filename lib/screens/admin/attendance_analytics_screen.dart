import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceAnalyticsScreen extends StatefulWidget {
  const AttendanceAnalyticsScreen({super.key});

  @override
  State<AttendanceAnalyticsScreen> createState() =>
      _AttendanceAnalyticsScreenState();
}

class _AttendanceAnalyticsScreenState extends State<AttendanceAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _classes = [];
  Map<String, List<String>> _attendanceByClass =
      {}; // classId -> list of studentIds who attended

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load all registered students
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('isActive', isEqualTo: true)
          .get();

      _allStudents = studentsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Load classes for selected date
      final classesSnapshot = await _firestore.collection('classes').get();

      // Filter classes active on selected date
      _classes = [];
      for (var doc in classesSnapshot.docs) {
        final data = doc.data();
        DateTime? passwordActiveFrom;
        DateTime? passwordActiveUntil;

        if (data['passwordActiveFrom'] != null) {
          if (data['passwordActiveFrom'] is Timestamp) {
            passwordActiveFrom = (data['passwordActiveFrom'] as Timestamp)
                .toDate();
          }
        }
        if (data['passwordActiveUntil'] != null) {
          if (data['passwordActiveUntil'] is Timestamp) {
            passwordActiveUntil = (data['passwordActiveUntil'] as Timestamp)
                .toDate();
          }
        }

        // Check if class is/was active on selected date
        if (passwordActiveFrom != null) {
          final classDate = DateTime(
            passwordActiveFrom.year,
            passwordActiveFrom.month,
            passwordActiveFrom.day,
          );
          final selectedDateOnly = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
          );

          if (classDate.isAtSameMomentAs(selectedDateOnly)) {
            _classes.add({
              'id': doc.id,
              ...data,
              'passwordActiveFrom': passwordActiveFrom,
              'passwordActiveUntil': passwordActiveUntil,
            });
          }
        }
      }

      // Sort classes by start time
      _classes.sort((a, b) {
        final aTime = a['passwordActiveFrom'] as DateTime?;
        final bTime = b['passwordActiveFrom'] as DateTime?;
        if (aTime == null || bTime == null) return 0;
        return aTime.compareTo(bTime);
      });

      // Load attendance for each class
      _attendanceByClass = {};
      for (var classData in _classes) {
        final classId = classData['id'];
        final attendanceSnapshot = await _firestore
            .collection('attendance')
            .where('classId', isEqualTo: classId)
            .get();

        _attendanceByClass[classId] = attendanceSnapshot.docs
            .map((doc) => doc.data()['studentId'] as String)
            .toList();
      }

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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }

  void _showStudentList({
    required String title,
    required List<Map<String, dynamic>> students,
    required bool isPresent,
    required String subjectName,
    required String teacherName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isPresent
                                ? Colors.green[50]
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isPresent ? Icons.check_circle : Icons.cancel,
                            color: isPresent
                                ? Colors.green[700]
                                : Colors.red[700],
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${students.length} students',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.book, size: 18, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            subjectName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.person, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            teacherName,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Student list
              Expanded(
                child: students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isPresent ? Icons.celebration : Icons.thumb_up,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isPresent
                                  ? 'No students present'
                                  : 'All students attended! 🎉',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isPresent
                                    ? Colors.green[100]
                                    : Colors.red[100],
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isPresent
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                student['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'ID: ${student['id']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Icon(
                                isPresent ? Icons.check_circle : Icons.cancel,
                                color: isPresent ? Colors.green : Colors.red,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalStudents = _allStudents.length;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade700, Colors.indigo.shade900],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Date selector
            Container(
              margin: const EdgeInsets.all(16),
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
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_today, color: Colors.indigo[700]),
                ),
                title: Text(
                  dateFormat.format(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Total Registered: $totalStudents students',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                trailing: TextButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Change'),
                ),
              ),
            ),

            // Sessions list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _classes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No sessions on this date',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select a different date to view sessions',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _classes.length,
                        itemBuilder: (context, index) {
                          final classData = _classes[index];
                          final classId = classData['id'];
                          final subjectName =
                              classData['subjectName'] ?? 'Unknown Subject';
                          final teacherName =
                              classData['teacherName'] ?? 'Unknown Teacher';
                          final startTime =
                              classData['passwordActiveFrom'] as DateTime?;
                          final endTime =
                              classData['passwordActiveUntil'] as DateTime?;

                          final presentStudentIds =
                              _attendanceByClass[classId] ?? [];

                          // Get present and absent student details (only from registered students)
                          final presentStudents = _allStudents
                              .where((s) => presentStudentIds.contains(s['id']))
                              .toList();
                          final absentStudents = _allStudents
                              .where(
                                (s) => !presentStudentIds.contains(s['id']),
                              )
                              .toList();

                          // Calculate counts based on registered students only
                          final presentCount = presentStudents.length;
                          final absentCount = absentStudents.length;
                          final attendancePercentage = totalStudents > 0
                              ? (presentCount / totalStudents * 100)
                              : 0.0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.indigo.shade50.withOpacity(0.5),
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Session header
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.indigo[100],
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            'Session ${index + 1}',
                                            style: TextStyle(
                                              color: Colors.indigo[800],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        if (startTime != null)
                                          Text(
                                            '${DateFormat('h:mm a').format(startTime)} - ${endTime != null ? DateFormat('h:mm a').format(endTime) : ''}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Subject and teacher
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.book,
                                          size: 24,
                                          color: Colors.indigo[700],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            subjectName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 20,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          teacherName,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Progress bar
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: attendancePercentage / 100,
                                        backgroundColor: Colors.red[100],
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.green[600]!,
                                            ),
                                        minHeight: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${attendancePercentage.toStringAsFixed(1)}% attendance',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Present and Absent counts
                                    Row(
                                      children: [
                                        // Present card
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => _showStudentList(
                                              title: 'Present Students',
                                              students: presentStudents,
                                              isPresent: true,
                                              subjectName: subjectName,
                                              teacherName: teacherName,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.green[50],
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Colors.green[200]!,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green[700],
                                                    size: 32,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    '$presentCount',
                                                    style: TextStyle(
                                                      fontSize: 28,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.green[700],
                                                    ),
                                                  ),
                                                  Text(
                                                    'Present',
                                                    style: TextStyle(
                                                      color: Colors.green[700],
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Tap to view',
                                                    style: TextStyle(
                                                      color: Colors.green[400],
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Absent card
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => _showStudentList(
                                              title: 'Absent Students',
                                              students: absentStudents,
                                              isPresent: false,
                                              subjectName: subjectName,
                                              teacherName: teacherName,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.red[50],
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Colors.red[200]!,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  Icon(
                                                    Icons.cancel,
                                                    color: Colors.red[700],
                                                    size: 32,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    '$absentCount',
                                                    style: TextStyle(
                                                      fontSize: 28,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.red[700],
                                                    ),
                                                  ),
                                                  Text(
                                                    'Absent',
                                                    style: TextStyle(
                                                      color: Colors.red[700],
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Tap to view',
                                                    style: TextStyle(
                                                      color: Colors.red[400],
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
