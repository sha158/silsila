import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../services/excel_service.dart';
import 'student_detail_screen.dart';

class ViewStudentsScreen extends StatefulWidget {
  const ViewStudentsScreen({super.key});

  @override
  State<ViewStudentsScreen> createState() => _ViewStudentsScreenState();
}

class _ViewStudentsScreenState extends State<ViewStudentsScreen> {
  final _firebaseService = FirebaseService();
  final _excelService = ExcelService();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _isLoading = true;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      final studentsSnapshot = await _firebaseService.getAllStudents().first;
      final students = studentsSnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();

      // Sort by name alphabetically
      students.sort((a, b) {
        final nameA = (a['name'] ?? '').toString().toLowerCase();
        final nameB = (b['name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });

      setState(() {
        _allStudents = students;
        _filteredStudents = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading students: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _allStudents;
      } else {
        _filteredStudents = _allStudents.where((student) {
          final name = student['name']?.toString().toLowerCase() ?? '';
          final studentId = student['id']?.toString().toLowerCase() ?? '';
          final phone = student['phoneNumber']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();

          return name.contains(searchLower) ||
              studentId.contains(searchLower) ||
              phone.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _downloadTemplate() async {
    try {
      final result = await _excelService.downloadSampleTemplate();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: result.contains('success') ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading template: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importFromExcel() async {
    setState(() => _isImporting = true);

    try {
      final result = await _excelService.importStudentsFromExcel();

      if (mounted) {
        // Show result dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  result['success'] ? Icons.check_circle : Icons.error,
                  color: result['success'] ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 10),
                const Text('Import Result'),
              ],
            ),
            content: SingleChildScrollView(child: Text(result['message'])),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        // Reload students list
        await _loadStudents();
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
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _deleteAllStudents() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade700),
            const SizedBox(width: 10),
            const Text('Delete All Students'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ALL ${_allStudents.length} students?\n\n'
          'This action cannot be undone!',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        int deletedCount = 0;
        int failedCount = 0;

        for (var student in _allStudents) {
          try {
            await _firebaseService.deleteStudent(student['id']);
            deletedCount++;
          } catch (e) {
            failedCount++;
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Deleted $deletedCount students successfully' +
                    (failedCount > 0
                        ? '\nFailed to delete $failedCount students'
                        : ''),
              ),
              backgroundColor: failedCount > 0 ? Colors.orange : Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Reload students list
          await _loadStudents();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'View Students',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _downloadTemplate,
            tooltip: 'Download Excel Template',
          ),
          if (_allStudents.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _isLoading ? null : _deleteAllStudents,
              tooltip: 'Delete All Students',
            ),
          IconButton(
            icon: _isImporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.upload_file),
            onPressed: _isImporting ? null : _importFromExcel,
            tooltip: 'Import from Excel',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: _filterStudents,
                decoration: InputDecoration(
                  hintText: 'Search by name, ID, or place',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterStudents('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredStudents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'No students found'
                                : 'No matching students',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadStudents,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = _filteredStudents[index];
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
                                radius: 28,
                                child: Text(
                                  (student['name'] ?? 'N')
                                      .toString()
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                student['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${student['id'] ?? 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  if (student['phoneNumber'] != null &&
                                      student['phoneNumber']
                                          .toString()
                                          .isNotEmpty)
                                    Text(
                                      'Place: ${student['phoneNumber']}',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: () {
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) => StudentDetailScreen(
                                          studentId: student['id'],
                                        ),
                                      ),
                                    )
                                    .then((_) => _loadStudents());
                              },
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
