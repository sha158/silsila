import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';

class ViewAttendanceScreen extends StatefulWidget {
  const ViewAttendanceScreen({super.key});

  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  final _firebaseService = FirebaseService();

  List<Map<String, dynamic>> _allAttendance = [];
  List<Map<String, dynamic>> _filteredAttendance = [];
  List<Map<String, dynamic>> _classes = [];

  String? _selectedClassId;
  DateTime? _selectedDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final classesSnapshot = await _firebaseService.getAllClasses().first;
      final attendanceSnapshot = await _firebaseService.getAllAttendance().first;

      final classes = classesSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      final attendance = attendanceSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      setState(() {
        _classes = classes;
        _allAttendance = attendance;
        _filteredAttendance = attendance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredAttendance = _allAttendance.where((attendance) {
        bool matchesClass = _selectedClassId == null ||
            attendance['classId'] == _selectedClassId;

        bool matchesDate = _selectedDate == null;
        if (!matchesDate && _selectedDate != null) {
          try {
            DateTime attendanceDate;
            if (attendance['timestamp'] is DateTime) {
              attendanceDate = attendance['timestamp'];
            } else if (attendance['timestamp'].toDate != null) {
              attendanceDate = attendance['timestamp'].toDate();
            } else {
              return false;
            }

            matchesDate = attendanceDate.year == _selectedDate!.year &&
                         attendanceDate.month == _selectedDate!.month &&
                         attendanceDate.day == _selectedDate!.day;
          } catch (e) {
            return false;
          }
        }

        return matchesClass && matchesDate;
      }).toList();

      _filteredAttendance.sort((a, b) {
        try {
          DateTime dateA;
          DateTime dateB;

          if (a['timestamp'] is DateTime) {
            dateA = a['timestamp'];
          } else {
            dateA = a['timestamp'].toDate();
          }

          if (b['timestamp'] is DateTime) {
            dateB = b['timestamp'];
          } else {
            dateB = b['timestamp'].toDate();
          }

          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });
    });
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
      _applyFilters();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedClassId = null;
      _selectedDate = null;
    });
    _applyFilters();
  }

  String _getClassName(String? classId) {
    if (classId == null) return 'Unknown Class';
    final classData = _classes.firstWhere(
      (c) => c['id'] == classId,
      orElse: () => {'subjectName': 'Unknown Class'},
    );
    return classData['subjectName'] ?? 'Unknown Class';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'View Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
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
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedClassId,
                      decoration: InputDecoration(
                        labelText: 'Class',
                        prefixIcon: const Icon(Icons.class_),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Classes'),
                        ),
                        ..._classes.map((c) => DropdownMenuItem(
                              value: c['id'],
                              child: Text(c['subjectName'] ?? 'Unknown'),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedClassId = value;
                        });
                        _applyFilters();
                      },
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          prefixIcon: const Icon(Icons.calendar_today),
                          suffixIcon: _selectedDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = null;
                                    });
                                    _applyFilters();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'All Dates',
                        ),
                      ),
                    ),
                    if (_selectedClassId != null || _selectedDate != null) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Clear Filters'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredAttendance.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.checklist,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No attendance records found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredAttendance.length,
                            itemBuilder: (context, index) {
                              final record = _filteredAttendance[index];
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.shade700,
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    record['studentName'] ?? 'Unknown Student',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(_getClassName(record['classId'])),
                                      Text(_formatDateTime(record['timestamp'])),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Present',
                                      style: TextStyle(
                                        color: Colors.green.shade900,
                                        fontWeight: FontWeight.bold,
                                      ),
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

  String _formatDateTime(dynamic timestamp) {
    try {
      if (timestamp == null) return 'N/A';

      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp.toDate != null) {
        date = timestamp.toDate();
      } else {
        return 'N/A';
      }

      return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}
