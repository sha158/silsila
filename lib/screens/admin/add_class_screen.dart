import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../models/class_model.dart';

class AddClassScreen extends StatefulWidget {
  final String? classId;
  final Map<String, dynamic>? classData;

  const AddClassScreen({
    super.key,
    this.classId,
    this.classData,
  });

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseService = FirebaseService();

  final _nameController = TextEditingController();
  final _teacherController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.classData != null) {
      _loadClassData();
    } else {
      _generatePassword();
    }
  }

  void _loadClassData() {
    final data = widget.classData!;
    _nameController.text = data['subjectName'] ?? data['name'] ?? '';
    _teacherController.text = data['teacherName'] ?? data['teacher'] ?? '';
    _passwordController.text = data['password'] ?? '';
    _scheduleController.text = data['scheduledDate'] ?? data['schedule'] ?? '';
    _locationController.text = data['location'] ?? '';

    if (data['startDate'] != null) {
      try {
        if (data['startDate'] is DateTime) {
          _startDate = data['startDate'];
        } else if (data['startDate'].toDate != null) {
          _startDate = data['startDate'].toDate();
        }
      } catch (e) {
        // Ignore error
      }
    }

    if (data['endDate'] != null) {
      try {
        if (data['endDate'] is DateTime) {
          _endDate = data['endDate'];
        } else if (data['endDate'].toDate != null) {
          _endDate = data['endDate'].toDate();
        }
      } catch (e) {
        // Ignore error
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
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

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate
        ? _startDate ?? DateTime.now()
        : _endDate ?? DateTime.now().add(const Duration(days: 30));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.classId != null) {
        // Update existing class
        await _firebaseService.updateClass(
          widget.classId!,
          {
            'subjectName': _nameController.text.trim(),
            'teacherName': _teacherController.text.trim(),
            'scheduledDate': _scheduleController.text.trim(),
            'startTime': '', // Not used in this form
            'endTime': '', // Not used in this form
            'password': _passwordController.text.trim(),
            'passwordActiveFrom': Timestamp.fromDate(_startDate!),
            'passwordActiveUntil': Timestamp.fromDate(_endDate!),
          },
        );

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
          subjectName: _nameController.text.trim(),
          teacherName: _teacherController.text.trim(),
          scheduledDate: _scheduleController.text.trim(),
          startTime: '', // Not used in this form
          endTime: '', // Not used in this form
          password: _passwordController.text.trim(),
          passwordActiveFrom: _startDate!,
          passwordActiveUntil: _endDate!,
          isPasswordActive: DateTime.now().isAfter(_startDate!) && DateTime.now().isBefore(_endDate!),
          autoGenerate: false,
          createdAt: DateTime.now(),
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
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
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
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Class Name',
                              prefixIcon: const Icon(Icons.class_),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter class name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _teacherController,
                            decoration: InputDecoration(
                              labelText: 'Teacher Name',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter teacher name';
                              }
                              return null;
                            },
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
                                  onTap: () => _selectDate(context, true),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Start Date',
                                      prefixIcon: const Icon(Icons.calendar_today),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      _startDate != null
                                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                          : 'Select date',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context, false),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'End Date',
                                      prefixIcon: const Icon(Icons.calendar_today),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      _endDate != null
                                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                          : 'Select date',
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
