import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../models/class_model.dart';

class AddClassScreen extends StatefulWidget {
  final String? classId;
  final Map<String, dynamic>? classData;

  const AddClassScreen({super.key, this.classId, this.classData});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _passwordController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedSubject;
  String? _selectedTeacher;
  List<String> _subjects = [];
  List<String> _teachers = [];
  bool _isLoadingData = true;

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSubjectsAndTeachers();
    if (widget.classData != null) {
      _loadClassData();
    } else {
      _generatePassword();
    }
  }

  Future<void> _loadSubjectsAndTeachers() async {
    try {
      final subjectsSnapshot = await _firestore
          .collection('subjects')
          .orderBy('name')
          .get();
      final teachersSnapshot = await _firestore
          .collection('teachers')
          .orderBy('name')
          .get();

      setState(() {
        _subjects = subjectsSnapshot.docs
            .map((doc) => doc['name'] as String)
            .toList();
        _teachers = teachersSnapshot.docs
            .map((doc) => doc['name'] as String)
            .toList();
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _loadClassData() {
    final data = widget.classData!;
    _selectedSubject = data['subjectName'] ?? data['name'];
    _selectedTeacher = data['teacherName'] ?? data['teacher'];
    _passwordController.text = data['password'] ?? '';
    _scheduleController.text = data['scheduledDate'] ?? data['schedule'] ?? '';
    _locationController.text = data['location'] ?? '';

    // Load start and end times from passwordActiveFrom/Until
    if (data['passwordActiveFrom'] != null) {
      try {
        DateTime startDateTime;
        if (data['passwordActiveFrom'] is DateTime) {
          startDateTime = data['passwordActiveFrom'];
        } else if (data['passwordActiveFrom'].toDate != null) {
          startDateTime = data['passwordActiveFrom'].toDate();
        } else {
          return;
        }
        _startTime = TimeOfDay(
          hour: startDateTime.hour,
          minute: startDateTime.minute,
        );
      } catch (e) {
        // Ignore error
      }
    }

    if (data['passwordActiveUntil'] != null) {
      try {
        DateTime endDateTime;
        if (data['passwordActiveUntil'] is DateTime) {
          endDateTime = data['passwordActiveUntil'];
        } else if (data['passwordActiveUntil'].toDate != null) {
          endDateTime = data['passwordActiveUntil'].toDate();
        } else {
          return;
        }
        _endTime = TimeOfDay(
          hour: endDateTime.hour,
          minute: endDateTime.minute,
        );
      } catch (e) {
        // Ignore error
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _scheduleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final password = String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    _passwordController.text = password;
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final initialTime = isStartTime
        ? _startTime ?? TimeOfDay.now()
        : _endTime ?? const TimeOfDay(hour: 23, minute: 59);

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = pickedTime;
        } else {
          _endTime = pickedTime;
        }
      });
    }
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end times'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Convert TimeOfDay to DateTime for today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final startDateTime = DateTime(
      today.year,
      today.month,
      today.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final endDateTime = DateTime(
      today.year,
      today.month,
      today.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    if (endDateTime.isBefore(startDateTime) ||
        endDateTime.isAtSameMomentAs(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Format times for display
      final startTimeStr = _startTime!.format(context);
      final endTimeStr = _endTime!.format(context);

      if (widget.classId != null) {
        // Update existing class
        await _firebaseService.updateClass(widget.classId!, {
          'subjectName': _selectedSubject!,
          'teacherName': _selectedTeacher!,
          'scheduledDate': _scheduleController.text.trim(),
          'startTime': startTimeStr,
          'endTime': endTimeStr,
          'password': _passwordController.text.trim(),
          'passwordActiveFrom': Timestamp.fromDate(startDateTime),
          'passwordActiveUntil': Timestamp.fromDate(endDateTime),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Class updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        // Add new class
        final classModel = ClassModel(
          classId: '', // Will be set by Firestore
          subjectName: _selectedSubject!,
          teacherName: _selectedTeacher!,
          scheduledDate: _scheduleController.text.trim(),
          startTime: startTimeStr,
          endTime: endTimeStr,
          password: _passwordController.text.trim(),
          passwordActiveFrom: startDateTime,
          passwordActiveUntil: endDateTime,
          isPasswordActive:
              now.isAfter(startDateTime) && now.isBefore(endDateTime),
          autoGenerate: false,
          createdAt: now,
        );

        await _firebaseService.addClass(classModel);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Class added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
    final isEditing = widget.classId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Class' : 'Add Class',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade900],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Class Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Subject Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedSubject,
                            decoration: InputDecoration(
                              labelText: 'Subject Name',
                              prefixIcon: const Icon(Icons.book),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _subjects.map((subject) {
                              return DropdownMenuItem(
                                value: subject,
                                child: Text(subject),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSubject = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a subject';
                              }
                              return null;
                            },
                            hint: _isLoadingData
                                ? const Text('Loading subjects...')
                                : _subjects.isEmpty
                                ? const Text(
                                    'No subjects available - Add in Subjects & Teachers',
                                  )
                                : const Text('Select a subject'),
                          ),
                          const SizedBox(height: 16),
                          // Teacher Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedTeacher,
                            decoration: InputDecoration(
                              labelText: 'Teacher Name',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _teachers.map((teacher) {
                              return DropdownMenuItem(
                                value: teacher,
                                child: Text(teacher),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedTeacher = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a teacher';
                              }
                              return null;
                            },
                            hint: _isLoadingData
                                ? const Text('Loading teachers...')
                                : _teachers.isEmpty
                                ? const Text(
                                    'No teachers available - Add in Subjects & Teachers',
                                  )
                                : const Text('Select a teacher'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Class Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _generatePassword,
                                tooltip: 'Generate Password',
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter or generate password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectTime(context, true),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Start Time',
                                      prefixIcon: const Icon(Icons.access_time),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      _startTime != null
                                          ? _startTime!.format(context)
                                          : 'Select time',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectTime(context, false),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'End Time',
                                      prefixIcon: const Icon(Icons.access_time),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      _endTime != null
                                          ? _endTime!.format(context)
                                          : 'Select time',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: Text(
                              'Active today: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _scheduleController,
                            decoration: InputDecoration(
                              labelText: 'Schedule (Optional)',
                              prefixIcon: const Icon(Icons.schedule),
                              hintText: 'e.g., Mon & Wed 6-8 PM',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              labelText: 'Location (Optional)',
                              prefixIcon: const Icon(Icons.location_on),
                              hintText: 'e.g., Room 101',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveClass,
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              isEditing ? 'Update Class' : 'Add Class',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
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
  }
}
