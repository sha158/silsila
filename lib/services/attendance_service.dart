import 'package:cloud_firestore/cloud_firestore.dart';
import 'device_service.dart';

class AttendanceResult {
  final bool success;
  final String message;
  final String? subjectName;

  AttendanceResult({
    required this.success,
    required this.message,
    this.subjectName,
  });
}

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AttendanceResult> verifyAndMarkAttendance(
    String studentId,
    String enteredPassword,
  ) async {
    try {
      // 1. Get current device info
      Map<String, String> deviceInfo = await DeviceService.getDeviceInfo();

      // 2. Verify device binding
      DocumentSnapshot studentDoc = await _firestore
          .collection('students')
          .doc(studentId)
          .get();

      if (!studentDoc.exists) {
        return AttendanceResult(
          success: false,
          message: 'Student not found',
        );
      }

      final studentData = studentDoc.data() as Map<String, dynamic>;
      if (studentData['deviceId'] != deviceInfo['deviceId']) {
        return AttendanceResult(
          success: false,
          message: 'Device verification failed',
        );
      }

      // 3. Find active class with matching password
      DateTime now = DateTime.now();
      QuerySnapshot activeClasses = await _firestore
          .collection('classes')
          .where('isPasswordActive', isEqualTo: true)
          .where('passwordActiveUntil', isGreaterThan: Timestamp.fromDate(now))
          .get();

      DocumentSnapshot? matchingClass;
      for (var doc in activeClasses.docs) {
        final classData = doc.data() as Map<String, dynamic>;
        if (classData['password'] == enteredPassword) {
          // Also check if password is active from time
          final activeFrom = (classData['passwordActiveFrom'] as Timestamp).toDate();
          if (now.isAfter(activeFrom)) {
            matchingClass = doc;
            break;
          }
        }
      }

      if (matchingClass == null) {
        return AttendanceResult(
          success: false,
          message: 'Incorrect password or class not active',
        );
      }

      final classData = matchingClass.data() as Map<String, dynamic>;

      // 4. Check duplicate attendance
      QuerySnapshot existingAttendance = await _firestore
          .collection('attendance')
          .where('classId', isEqualTo: matchingClass.id)
          .where('studentId', isEqualTo: studentId)
          .get();

      if (existingAttendance.docs.isNotEmpty) {
        return AttendanceResult(
          success: false,
          message: 'Attendance already marked for this class',
        );
      }

      // 5. Mark attendance
      await _firestore.collection('attendance').add({
        'classId': matchingClass.id,
        'studentId': studentId,
        'subjectName': classData['subjectName'],
        'markedAt': FieldValue.serverTimestamp(),
        'status': 'present',
        'deviceId': deviceInfo['deviceId'],
      });

      return AttendanceResult(
        success: true,
        message: 'Attendance marked successfully!',
        subjectName: classData['subjectName'],
      );
    } catch (e) {
      return AttendanceResult(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  // Get student attendance history
  Stream<QuerySnapshot> getStudentAttendance(String studentId) {
    return _firestore
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .orderBy('markedAt', descending: true)
        .snapshots();
  }

  // Get active classes for students
  Stream<QuerySnapshot> getActiveClasses() {
    DateTime now = DateTime.now();
    return _firestore
        .collection('classes')
        .where('isPasswordActive', isEqualTo: true)
        .where('passwordActiveUntil', isGreaterThan: Timestamp.fromDate(now))
        .snapshots();
  }
}
