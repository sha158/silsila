import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/attendance.dart';

class ManualAttendanceScreen extends StatefulWidget {
  const ManualAttendanceScreen({super.key});

  @override
  State<ManualAttendanceScreen> createState() => _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState extends State<ManualAttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedSubject;
  String? _selectedClassId;
  List<String> _subjects = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _filteredClasses = [];
  List<Map<String, dynamic>> _students = [];
  Set<String> _selectedStudentIds = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load subjects
      final subjectsSnapshot = await _firestore
          .collection('subjects')
          .orderBy('name')
          .get();
      _subjects = subjectsSnapshot.docs
          .map((doc) => doc['name'] as String)
          .toList();

      // Load classes
      final classesSnapshot = await _firestore.collection('classes').get();
      _classes = classesSnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      // Sort by date (most recent first)
      _classes.sort((a, b) {
        final aTime = (a['passwordActiveFrom'] as Timestamp?)?.toDate();
        final bTime = (b['passwordActiveFrom'] as Timestamp?)?.toDate();
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      // Load students
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('isActive', isEqualTo: true)
          .get();

      _students = studentsSnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      // Sort by name
      _students.sort((a, b) {
        final nameA = (a['name'] ?? '').toString().toLowerCase();
        final nameB = (b['name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
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

  void _filterClassesBySubject(String? subject) {
    if (subject == null || subject.isEmpty) {
      setState(() {
        _filteredClasses = [];
        _selectedClassId = null;
        _selectedStudentIds.clear();
      });
      return;
    }

    setState(() {
      _selectedSubject = subject;
      _filteredClasses = _classes
          .where((c) => c['subjectName'] == subject)
          .toList();
      _selectedClassId = null;
      _selectedStudentIds.clear();
    });
  }

  Future<void> _markAttendance() async {
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a class/session'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one student'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Confirm before marking
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Attendance'),
        content: Text(
          'Mark attendance for ${_selectedStudentIds.length} student(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final selectedClass = _classes.firstWhere((c) => c['id'] == _selectedClassId);
      int successCount = 0;
      int skipCount = 0;

      for (String studentId in _selectedStudentIds) {
        // Check if attendance already exists
        final existingAttendance = await _firestore
            .collection('attendance')
            .where('studentId', isEqualTo: studentId)
            .where('classId', isEqualTo: _selectedClassId)
            .get();

        if (existingAttendance.docs.isNotEmpty) {
          skipCount++;
          continue;
        }

        // Create attendance record
        final attendanceDoc = _firestore.collection('attendance').doc();
        final attendance = Attendance(
          attendanceId: attendanceDoc.id,
          studentId: studentId,
          classId: _selectedClassId!,
          subjectName: selectedClass['subjectName'] ?? 'Unknown',
          markedAt: DateTime.now(),
          status: 'present',
          deviceId: 'admin-manual',
        );

        await attendanceDoc.set(attendance.toMap());
        successCount++;
      }

      setState(() {
        _isSubmitting = false;
        _selectedStudentIds.clear();
        _selectedClassId = null;
      });

      if (mounted) {
        String message = 'Attendance marked successfully!\n';
        message += 'Marked: $successCount student(s)';
        if (skipCount > 0) {
          message += '\nSkipped: $skipCount (already marked)';
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
                const SizedBox(width: 12),
                const Text('Success'),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manual Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade900],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Subject and Class Selection
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject Dropdown
                      const Text(
                        '1. Select Subject',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedSubject,
                          isExpanded: true,
                          hint: const Text('Choose a subject'),
                          underline: const SizedBox(),
                          items: _subjects.map((subject) {
                            return DropdownMenuItem<String>(
                              value: subject,
                              child: Text(
                                subject,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            _filterClassesBySubject(value);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Class/Session Dropdown
                      const Text(
                        '2. Select Session',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: _selectedSubject == null ? Colors.grey.shade200 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedClassId,
                          isExpanded: true,
                          hint: Text(
                            _selectedSubject == null
                                ? 'Select subject first'
                                : 'Choose a session',
                          ),
                          underline: const SizedBox(),
                          items: _filteredClasses.map((classData) {
                          final time = (classData['passwordActiveFrom'] as Timestamp?)?.toDate();
                          final timeStr = time != null
                              ? '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                              : 'Unknown';
                          return DropdownMenuItem<String>(
                            value: classData['id'],
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${classData['teacherName'] ?? 'Unknown Teacher'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                          }).toList(),
                          onChanged: _selectedSubject == null
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedClassId = value;
                                    _selectedStudentIds.clear();
                                  });
                                },
                        ),
                      ),
                    ],
                  ),
                ),

                // Students List
                Expanded(
                  child: _students.isEmpty
                      ? const Center(
                          child: Text(
                            'No active students found',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : Column(
                          children: [
                            // Select All / Clear All
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Selected: ${_selectedStudentIds.length}/${_students.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _selectedStudentIds = _students
                                                .map((s) => s['id'] as String)
                                                .toSet();
                                          });
                                        },
                                        icon: const Icon(Icons.select_all),
                                        label: const Text('Select All'),
                                      ),
                                      TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _selectedStudentIds.clear();
                                          });
                                        },
                                        icon: const Icon(Icons.clear),
                                        label: const Text('Clear'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _students.length,
                                itemBuilder: (context, index) {
                                  final student = _students[index];
                                  final studentId = student['id'] as String;
                                  final isSelected = _selectedStudentIds.contains(studentId);

                                  return CheckboxListTile(
                                    value: isSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedStudentIds.add(studentId);
                                        } else {
                                          _selectedStudentIds.remove(studentId);
                                        }
                                      });
                                    },
                                    title: Text(
                                      student['name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'ID: $studentId',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    secondary: CircleAvatar(
                                      backgroundColor: isSelected
                                          ? Colors.green.shade600
                                          : Colors.blue.shade600,
                                      child: Text(
                                        student['name']?.toString()[0].toUpperCase() ?? 'S',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),

                // Submit Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _markAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(
                        _isSubmitting ? 'Marking Attendance...' : 'Mark Attendance',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
