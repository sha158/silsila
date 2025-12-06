import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String _sortBy = 'percentage_desc'; // percentage_desc, percentage_asc, name
  String _filterSubject = 'All';

  List<Map<String, dynamic>> _studentReports = [];
  List<String> _subjects = ['All'];
  int _totalSessions = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get all classes
      final classesSnapshot = await _firestore.collection('classes').get();
      _totalSessions = classesSnapshot.docs.length;

      // Get unique subjects and track all valid class IDs
      Set<String> subjectsSet = {};
      Map<String, Set<String>> subjectClassIds = {}; // subject -> classIds
      Set<String> validClassIds = {}; // All valid class IDs

      for (var doc in classesSnapshot.docs) {
        final subject = doc.data()['subjectName'] ?? 'Unknown';
        subjectsSet.add(subject);

        if (!subjectClassIds.containsKey(subject)) {
          subjectClassIds[subject] = {};
        }
        subjectClassIds[subject]!.add(doc.id);
        validClassIds.add(doc.id); // Track valid class IDs
      }

      _subjects = ['All', ...subjectsSet.toList()..sort()];

      // Get all active students
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('isActive', isEqualTo: true)
          .get();

      // Get all attendance records
      final attendanceSnapshot = await _firestore
          .collection('attendance')
          .get();

      // Map: studentId -> Set of attended classIds (only for valid classes)
      Map<String, Set<String>> studentAttendance = {};
      for (var doc in attendanceSnapshot.docs) {
        final studentId = doc.data()['studentId'] as String;
        final classId = doc.data()['classId'] as String;

        // Only count attendance for classes that still exist
        if (!validClassIds.contains(classId)) {
          continue;
        }

        if (!studentAttendance.containsKey(studentId)) {
          studentAttendance[studentId] = {};
        }
        studentAttendance[studentId]!.add(classId);
      }

      // Build student reports
      _studentReports = [];

      for (var studentDoc in studentsSnapshot.docs) {
        final studentId = studentDoc.id;
        final studentData = studentDoc.data();
        final studentName = studentData['name'] ?? 'Unknown';

        final attendedClassIds = studentAttendance[studentId] ?? {};

        // Calculate per-subject stats
        Map<String, Map<String, int>> subjectStats = {};
        for (var subject in subjectsSet) {
          final subjectClasses = subjectClassIds[subject] ?? {};
          final attendedInSubject = attendedClassIds
              .intersection(subjectClasses)
              .length;
          subjectStats[subject] = {
            'attended': attendedInSubject,
            'total': subjectClasses.length,
          };
        }

        final totalAttended = attendedClassIds.length;
        final percentage = _totalSessions > 0
            ? (totalAttended / _totalSessions) * 100
            : 0.0;

        _studentReports.add({
          'id': studentId,
          'name': studentName,
          'attended': totalAttended,
          'total': _totalSessions,
          'percentage': percentage,
          'subjectStats': subjectStats,
        });
      }

      _sortReports();
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

  void _sortReports() {
    switch (_sortBy) {
      case 'percentage_desc':
        _studentReports.sort(
          (a, b) =>
              (b['percentage'] as double).compareTo(a['percentage'] as double),
        );
        break;
      case 'percentage_asc':
        _studentReports.sort(
          (a, b) =>
              (a['percentage'] as double).compareTo(b['percentage'] as double),
        );
        break;
      case 'name':
        _studentReports.sort(
          (a, b) => (a['name'] as String).compareTo(b['name'] as String),
        );
        break;
    }
  }

  List<Map<String, dynamic>> get _filteredReports {
    if (_filterSubject == 'All') return _studentReports;

    return _studentReports.map((report) {
      final subjectStats =
          report['subjectStats'] as Map<String, Map<String, int>>;
      final stats = subjectStats[_filterSubject] ?? {'attended': 0, 'total': 0};
      final attended = stats['attended'] ?? 0;
      final total = stats['total'] ?? 0;
      // Clamp percentage to max 100%
      final percentage = total > 0 ? ((attended / total) * 100).clamp(0.0, 100.0) : 0.0;

      return {
        ...report,
        'attended': attended,
        'total': total,
        'percentage': percentage,
      };
    }).toList()..sort((a, b) {
      if (_sortBy == 'percentage_asc') {
        return (a['percentage'] as double).compareTo(b['percentage'] as double);
      } else if (_sortBy == 'name') {
        return (a['name'] as String).compareTo(b['name'] as String);
      }
      return (b['percentage'] as double).compareTo(a['percentage'] as double);
    });
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    final subjectStats =
        student['subjectStats'] as Map<String, Map<String, int>>;

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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _getPercentageColor(
                        student['percentage'] as double,
                      ).withOpacity(0.1),
                      child: Text(
                        (student['name'] as String)
                            .substring(0, 1)
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getPercentageColor(
                            student['percentage'] as double,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student['name'] as String,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ID: ${student['id']}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getPercentageColor(
                          student['percentage'] as double,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${(student['percentage'] as double).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Subject breakdown
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Subject-wise Breakdown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...subjectStats.entries.map((entry) {
                      final subject = entry.key;
                      final stats = entry.value;
                      final attended = stats['attended'] ?? 0;
                      final total = stats['total'] ?? 0;
                      final pct = total > 0 ? (attended / total) * 100 : 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.book,
                                  color: _getPercentageColor(pct),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    subject,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$attended/$total',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${pct.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getPercentageColor(pct),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 6,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getPercentageColor(pct),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
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
    final lowAttendance = _filteredReports
        .where((r) => (r['percentage'] as double) < 70)
        .toList();
    final avgPercentage = _filteredReports.isNotEmpty
        ? _filteredReports
                  .map((r) => r['percentage'] as double)
                  .reduce((a, b) => a + b) /
              _filteredReports.length
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance Report',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.teal.shade900],
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Stats header
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.teal.shade600, Colors.teal.shade800],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Total Students',
                          '${_studentReports.length}',
                          Icons.people,
                        ),
                        Container(width: 1, height: 50, color: Colors.white24),
                        _buildStatItem(
                          'Avg Attendance',
                          '${avgPercentage.toStringAsFixed(1)}%',
                          Icons.analytics,
                        ),
                        Container(width: 1, height: 50, color: Colors.white24),
                        _buildStatItem(
                          'Low Attendance',
                          '${lowAttendance.length}',
                          Icons.warning,
                          color: lowAttendance.isNotEmpty
                              ? Colors.orange
                              : Colors.white,
                        ),
                      ],
                    ),
                  ),

                  // Filters
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Subject filter
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _filterSubject,
                                isExpanded: true,
                                icon: const Icon(Icons.filter_list),
                                items: _subjects
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _filterSubject = value!);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Sort options
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.sort),
                            onSelected: (value) {
                              setState(() {
                                _sortBy = value;
                                _sortReports();
                              });
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'percentage_desc',
                                child: Text('Highest First'),
                              ),
                              const PopupMenuItem(
                                value: 'percentage_asc',
                                child: Text('Lowest First'),
                              ),
                              const PopupMenuItem(
                                value: 'name',
                                child: Text('By Name'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Low attendance warning
                  if (lowAttendance.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${lowAttendance.length} student(s) with attendance below 70%',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Student list
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredReports.length,
                        itemBuilder: (context, index) {
                          final report = _filteredReports[index];
                          final percentage = report['percentage'] as double;
                          final isTopThree =
                              index < 3 && _sortBy == 'percentage_desc';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              onTap: () => _showStudentDetails(report),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Rank or Avatar
                                    if (isTopThree)
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: index == 0
                                              ? Colors.amber
                                              : index == 1
                                              ? Colors.grey[400]
                                              : Colors.brown[300],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            ['🥇', '🥈', '🥉'][index],
                                            style: const TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: _getPercentageColor(
                                          percentage,
                                        ).withOpacity(0.1),
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _getPercentageColor(
                                              percentage,
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 16),

                                    // Name and stats
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            report['name'] as String,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${report['attended']}/${report['total']} sessions',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Percentage
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${percentage.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: _getPercentageColor(
                                              percentage,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          width: 60,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: percentage / 100,
                                              minHeight: 6,
                                              backgroundColor: Colors.grey[200],
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    _getPercentageColor(
                                                      percentage,
                                                    ),
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

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: (color ?? Colors.white).withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
