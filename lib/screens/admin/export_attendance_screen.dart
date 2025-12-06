import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/excel_service.dart';

class ExportAttendanceScreen extends StatefulWidget {
  const ExportAttendanceScreen({super.key});

  @override
  State<ExportAttendanceScreen> createState() => _ExportAttendanceScreenState();
}

class _ExportAttendanceScreenState extends State<ExportAttendanceScreen> {
  final ExcelService _excelService = ExcelService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedSubject;
  String? _selectedTeacher;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;

  List<String> _subjects = [];
  List<String> _teachers = [];

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    try {
      // Fetch unique subjects and teachers from classes
      final classesSnapshot = await _firestore.collection('classes').get();

      final subjects = <String>{};
      final teachers = <String>{};

      for (var doc in classesSnapshot.docs) {
        final data = doc.data();
        final subject = data['subjectName'] as String?;
        final teacher = data['teacherName'] as String?;

        if (subject != null && subject.isNotEmpty) {
          subjects.add(subject);
        }
        if (teacher != null && teacher.isNotEmpty) {
          teachers.add(teacher);
        }
      }

      setState(() {
        _subjects = subjects.toList()..sort();
        _teachers = teachers.toList()..sort();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading filters: $e')));
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _exportAttendance() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final result = await _excelService.exportFilteredAttendanceToExcel(
        subjectName: _selectedSubject,
        teacherName: _selectedTeacher,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            duration: const Duration(seconds: 5),
            backgroundColor: result.contains('success')
                ? Colors.green
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedSubject = null;
      _selectedTeacher = null;
      _startDate = null;
      _endDate = null;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not selected';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Attendance'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select filters to export specific attendance records. Leave filters empty to export all records.',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Filters Section
            Text(
              'Filters',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Subject Filter
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.book, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Subject',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      decoration: const InputDecoration(
                        hintText: 'Select a subject',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Subjects'),
                        ),
                        ..._subjects.map((subject) {
                          return DropdownMenuItem<String>(
                            value: subject,
                            child: Text(subject),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSubject = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Teacher Filter
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Teacher',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedTeacher,
                      decoration: const InputDecoration(
                        hintText: 'Select a teacher',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Teachers'),
                        ),
                        ..._teachers.map((teacher) {
                          return DropdownMenuItem<String>(
                            value: teacher,
                            child: Text(teacher),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedTeacher = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date Range Filter
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.date_range, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Date Range',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'From',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              OutlinedButton.icon(
                                onPressed: () => _selectDate(context, true),
                                icon: const Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                ),
                                label: Text(_formatDate(_startDate)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'To',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              OutlinedButton.icon(
                                onPressed: () => _selectDate(context, false),
                                icon: const Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                ),
                                label: Text(_formatDate(_endDate)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear Filters'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exportAttendance,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(
                      _isExporting ? 'Exporting...' : 'Export to Excel',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Applied Filters Summary
            if (_selectedSubject != null ||
                _selectedTeacher != null ||
                _startDate != null ||
                _endDate != null)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.filter_list, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Applied Filters',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_selectedSubject != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('• Subject: $_selectedSubject'),
                        ),
                      if (_selectedTeacher != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('• Teacher: $_selectedTeacher'),
                        ),
                      if (_startDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('• From: ${_formatDate(_startDate)}'),
                        ),
                      if (_endDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('• To: ${_formatDate(_endDate)}'),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
