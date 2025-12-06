import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;
  String? _studentId;
  bool _isLoading = true;

  // Stats data
  int _totalSessionsHeld = 0;
  int _sessionsAttended = 0;
  Map<String, Map<String, int>> _subjectStats =
      {}; // subject -> {attended, total}
  List<Map<String, dynamic>> _eventHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _studentId = prefs.getString('studentId');

      if (_studentId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get all classes ever held (source of truth)
      final classesSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .get();

      // Build set of valid class IDs
      final validClassIds = classesSnapshot.docs.map((d) => d.id).toSet();

      // Get student's attendance records
      final attendanceSnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('studentId', isEqualTo: _studentId)
          .get();

      // Only count attendance for classes that still exist
      final attendedClassIds = attendanceSnapshot.docs
          .map((doc) => doc.data()['classId'] as String)
          .where((classId) => validClassIds.contains(classId))
          .toSet();

      // Calculate stats
      _totalSessionsHeld = classesSnapshot.docs.length;
      _sessionsAttended = attendedClassIds.length;

      // Calculate subject-wise stats
      _subjectStats = {};
      Map<String, List<Map<String, dynamic>>> eventsByDate = {};

      for (var classDoc in classesSnapshot.docs) {
        final data = classDoc.data();
        final subjectName = data['subjectName'] ?? 'Unknown';
        final attended = attendedClassIds.contains(classDoc.id);

        // Subject stats
        if (!_subjectStats.containsKey(subjectName)) {
          _subjectStats[subjectName] = {'attended': 0, 'total': 0};
        }
        _subjectStats[subjectName]!['total'] =
            (_subjectStats[subjectName]!['total'] ?? 0) + 1;
        if (attended) {
          _subjectStats[subjectName]!['attended'] =
              (_subjectStats[subjectName]!['attended'] ?? 0) + 1;
        }

        // Group by date for event history
        DateTime? classDate;
        if (data['passwordActiveFrom'] != null) {
          if (data['passwordActiveFrom'] is Timestamp) {
            classDate = (data['passwordActiveFrom'] as Timestamp).toDate();
          }
        }

        if (classDate != null) {
          final dateKey = DateFormat('yyyy-MM-dd').format(classDate);
          if (!eventsByDate.containsKey(dateKey)) {
            eventsByDate[dateKey] = [];
          }
          eventsByDate[dateKey]!.add({
            'classId': classDoc.id,
            'subjectName': subjectName,
            'teacherName': data['teacherName'] ?? 'Unknown',
            'attended': attended,
            'time': classDate,
          });
        }
      }

      // Convert to event history
      _eventHistory = [];
      eventsByDate.forEach((dateKey, sessions) {
        final attendedCount = sessions
            .where((s) => s['attended'] == true)
            .length;
        final totalCount = sessions.length;
        _eventHistory.add({
          'date': DateTime.parse(dateKey),
          'sessions': sessions,
          'attended': attendedCount,
          'total': totalCount,
        });
      });

      // Sort by date descending
      _eventHistory.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading attendance data: $e');
    }
  }

  double get _overallPercentage {
    if (_totalSessionsHeld == 0) return 0;
    final percentage = (_sessionsAttended / _totalSessionsHeld) * 100;
    return percentage.clamp(0, 100); // Cap at 100%
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'My Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'By Subject'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSubjectTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main percentage card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[700]!, Colors.blue[900]!],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Overall Attendance',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: _overallPercentage / 100,
                        strokeWidth: 12,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getPercentageColor(_overallPercentage),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '${_overallPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$_sessionsAttended / $_totalSessionsHeld',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(
                      'Sessions Attended',
                      '$_sessionsAttended',
                      Icons.check_circle,
                      Colors.green,
                    ),
                    Container(width: 1, height: 50, color: Colors.white24),
                    _buildStatColumn(
                      'Sessions Missed',
                      '${(_totalSessionsHeld - _sessionsAttended).clamp(0, _totalSessionsHeld)}',
                      Icons.cancel,
                      Colors.red,
                    ),
                    Container(width: 1, height: 50, color: Colors.white24),
                    _buildStatColumn(
                      'Total Events',
                      '${_eventHistory.length}',
                      Icons.event,
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick stats cards
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  'Attendance Rate',
                  _overallPercentage >= 80
                      ? 'Excellent'
                      : _overallPercentage >= 60
                      ? 'Good'
                      : 'Needs Improvement',
                  _getPercentageColor(_overallPercentage),
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard(
                  'Total Subjects',
                  '${_subjectStats.length}',
                  Colors.purple,
                  Icons.library_books,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectTab() {
    if (_subjectStats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No subjects found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subjectStats.length,
      itemBuilder: (context, index) {
        final subject = _subjectStats.keys.elementAt(index);
        final stats = _subjectStats[subject]!;
        final attended = stats['attended'] ?? 0;
        final total = stats['total'] ?? 0;
        final percentage = total > 0 ? (attended / total) * 100 : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getPercentageColor(percentage).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.book,
                        color: _getPercentageColor(percentage),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$attended of $total sessions attended',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getPercentageColor(percentage),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getPercentageColor(percentage),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_eventHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No event history',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _eventHistory.length,
      itemBuilder: (context, index) {
        final event = _eventHistory[index];
        final date = event['date'] as DateTime;
        final sessions = event['sessions'] as List<Map<String, dynamic>>;
        final attended = event['attended'] as int;
        final total = event['total'] as int;
        final percentage = total > 0 ? (attended / total) * 100 : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getPercentageColor(percentage).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  percentage == 100
                      ? Icons.check_circle
                      : percentage > 0
                      ? Icons.remove_circle
                      : Icons.cancel,
                  color: _getPercentageColor(percentage),
                  size: 24,
                ),
              ),
              title: Text(
                DateFormat('EEEE, MMMM d, yyyy').format(date),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '$attended of $total sessions • ${percentage.toStringAsFixed(0)}%',
                style: TextStyle(color: Colors.grey[600]),
              ),
              children: sessions.map((session) {
                final isAttended = session['attended'] as bool;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        isAttended ? Icons.check_circle : Icons.cancel,
                        color: isAttended ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session['subjectName'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              session['teacherName'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isAttended ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAttended ? 'Present' : 'Absent',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isAttended
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
