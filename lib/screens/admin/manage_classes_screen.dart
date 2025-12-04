import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../models/class_model.dart';
import '../../widgets/qr_code_display_dialog.dart';
import 'add_class_screen.dart';

class ManageClassesScreen extends StatefulWidget {
  const ManageClassesScreen({super.key});

  @override
  State<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

class _ManageClassesScreenState extends State<ManageClassesScreen>
    with SingleTickerProviderStateMixin {
  final _firebaseService = FirebaseService();
  late TabController _tabController;

  List<Map<String, dynamic>> _activeClasses = [];
  List<Map<String, dynamic>> _pastClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClasses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);

    try {
      // getAllClasses returns a Stream, so we need to listen to it
      final snapshot = await _firebaseService.getAllClasses().first;
      final classes = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      final now = DateTime.now();

      setState(() {
        _activeClasses = classes.where((c) {
          final endDate = c['passwordActiveUntil'];
          if (endDate == null) return true;

          try {
            DateTime date;
            if (endDate is DateTime) {
              date = endDate;
            } else if (endDate.toDate != null) {
              date = endDate.toDate();
            } else {
              return true;
            }
            return date.isAfter(now);
          } catch (e) {
            return true;
          }
        }).toList();

        _pastClasses = classes.where((c) {
          final endDate = c['passwordActiveUntil'];
          if (endDate == null) return false;

          try {
            DateTime date;
            if (endDate is DateTime) {
              date = endDate;
            } else if (endDate.toDate != null) {
              date = endDate.toDate();
            } else {
              return false;
            }
            return date.isBefore(now);
          } catch (e) {
            return false;
          }
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading classes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteClass(String classId, String className) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text(
          'Are you sure you want to delete "$className"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firebaseService.deleteClass(classId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Class deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadClasses();
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Classes',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(text: 'Active Classes'),
            Tab(text: 'Past Classes'),
          ],
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildClassList(_activeClasses, true),
                  _buildClassList(_pastClasses, false),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const AddClassScreen()))
              .then((_) => _loadClasses());
        },
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
      ),
    );
  }

  Widget _buildClassList(List<Map<String, dynamic>> classes, bool isActive) {
    if (classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active classes' : 'No past classes',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClasses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: classes.length,
        itemBuilder: (context, index) {
          final classData = classes[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade700,
                child: const Icon(Icons.class_, color: Colors.white),
              ),
              title: Text(
                classData['subjectName'] ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (classData['teacherName'] != null &&
                      classData['teacherName'].toString().isNotEmpty)
                    Text('Teacher: ${classData['teacherName']}'),
                  Text('Schedule: ${classData['scheduledDate'] ?? 'N/A'}'),
                  Text(
                    '${_formatDate(classData['passwordActiveFrom'])} - ${_formatDate(classData['passwordActiveUntil'])}',
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (classData['teacherName'] != null &&
                          classData['teacherName'].toString().isNotEmpty) ...[
                        _InfoRow(
                          icon: Icons.person,
                          label: 'Teacher',
                          value: classData['teacherName'],
                        ),
                        const SizedBox(height: 8),
                      ],
                      _InfoRow(
                        icon: Icons.lock,
                        label: 'Password',
                        value: classData['password'] ?? 'N/A',
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.schedule,
                        label: 'Start Time',
                        value: classData['startTime']?.isNotEmpty == true
                            ? classData['startTime']
                            : 'Not specified',
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.schedule,
                        label: 'End Time',
                        value: classData['endTime']?.isNotEmpty == true
                            ? classData['endTime']
                            : 'Not specified',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Show QR Code button (only for active classes)
                          if (isActive) ...[
                            ElevatedButton.icon(
                              onPressed: () {
                                // Convert classData map to ClassModel
                                final classModel = ClassModel(
                                  classId: classData['id'],
                                  subjectName:
                                      classData['subjectName'] ?? 'Unknown',
                                  teacherName: classData['teacherName'] ?? '',
                                  scheduledDate:
                                      classData['scheduledDate'] ?? '',
                                  startTime: classData['startTime'] ?? '',
                                  endTime: classData['endTime'] ?? '',
                                  password: classData['password'] ?? '',
                                  passwordActiveFrom:
                                      (classData['passwordActiveFrom']
                                              as Timestamp)
                                          .toDate(),
                                  passwordActiveUntil:
                                      (classData['passwordActiveUntil']
                                              as Timestamp)
                                          .toDate(),
                                  isPasswordActive:
                                      classData['isPasswordActive'] ?? false,
                                  autoGenerate:
                                      classData['autoGenerate'] ?? false,
                                  createdAt:
                                      (classData['createdAt'] as Timestamp)
                                          .toDate(),
                                );

                                showDialog(
                                  context: context,
                                  builder: (context) => QRCodeDisplayDialog(
                                    classModel: classModel,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.qr_code_2),
                              label: const Text('QR Code'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => AddClassScreen(
                                        classId: classData['id'],
                                        classData: classData,
                                      ),
                                    ),
                                  )
                                  .then((_) => _loadClasses());
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _deleteClass(
                              classData['id'],
                              classData['subjectName'] ?? 'Unknown',
                            ),
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
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

      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(value, style: TextStyle(color: Colors.grey.shade700)),
        ),
      ],
    );
  }
}
