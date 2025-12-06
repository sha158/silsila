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
        return AttendanceResult(success: false, message: 'Student not found');
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
      DateTime today = DateTime(now.year, now.month, now.day);

      // Get all classes (not just isPasswordActive=true to be more flexible)
      QuerySnapshot activeClasses = await _firestore
          .collection('classes')
          .get();

      DocumentSnapshot? matchingClass;
      for (var doc in activeClasses.docs) {
        final classData = doc.data() as Map<String, dynamic>;

        // Check if password matches
        if (classData['password'] == enteredPassword) {
          // Check if password is active (time-based comparison for today)
          final activeFrom = (classData['passwordActiveFrom'] as Timestamp)
              .toDate()
              .toLocal();
          final activeUntil = (classData['passwordActiveUntil'] as Timestamp)
              .toDate()
              .toLocal();

          // Check if the class is scheduled for today
          final activeFromDay = DateTime(activeFrom.year, activeFrom.month, activeFrom.day);
          final activeUntilDay = DateTime(activeUntil.year, activeUntil.month, activeUntil.day);

          // Check if today matches the scheduled date
          bool isScheduledToday = today.isAtSameMomentAs(activeFromDay) &&
                                  today.isAtSameMomentAs(activeUntilDay);

          // Check if current time is within the active time range
          bool isActiveNow = now.isAfter(activeFrom) && now.isBefore(activeUntil);

          print('Attendance check - Password: ${classData['password']}, Entered: $enteredPassword, ScheduledToday: $isScheduledToday, ActiveNow: $isActiveNow, From: $activeFrom, Until: $activeUntil, Now: $now');

          if (isScheduledToday && isActiveNow) {
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

  // Mark attendance using QR code
  Future<AttendanceResult> markAttendanceByQR({
    required String studentId,
    required String classId,
  }) async {
    try {
      // 1. Get current device info
      Map<String, String> deviceInfo = await DeviceService.getDeviceInfo();

      // 2. Verify device binding
      DocumentSnapshot studentDoc = await _firestore
          .collection('students')
          .doc(studentId)
          .get();

      if (!studentDoc.exists) {
        return AttendanceResult(success: false, message: 'Student not found');
      }

      final studentData = studentDoc.data() as Map<String, dynamic>;
      if (studentData['deviceId'] != deviceInfo['deviceId']) {
        return AttendanceResult(
          success: false,
          message: 'Device verification failed',
        );
      }

      // 3. Get class details
      DocumentSnapshot classDoc = await _firestore
          .collection('classes')
          .doc(classId)
          .get();

      if (!classDoc.exists) {
        return AttendanceResult(success: false, message: 'Class not found');
      }

      final classData = classDoc.data() as Map<String, dynamic>;

      // 4. Verify class is active right now
      final activeFrom = (classData['passwordActiveFrom'] as Timestamp)
          .toDate()
          .toLocal();
      final activeUntil = (classData['passwordActiveUntil'] as Timestamp)
          .toDate()
          .toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check if the class is scheduled for today
      final activeFromDay = DateTime(activeFrom.year, activeFrom.month, activeFrom.day);
      final activeUntilDay = DateTime(activeUntil.year, activeUntil.month, activeUntil.day);

      bool isScheduledToday = today.isAtSameMomentAs(activeFromDay) &&
                              today.isAtSameMomentAs(activeUntilDay);

      // Check if current time is within the active time range
      bool isActiveNow = now.isAfter(activeFrom) && now.isBefore(activeUntil);

      if (!isScheduledToday) {
        return AttendanceResult(success: false, message: 'Class not scheduled for today');
      }

      if (!isActiveNow) {
        return AttendanceResult(success: false, message: 'Class is not active right now');
      }

      // 5. Check duplicate attendance
      QuerySnapshot existingAttendance = await _firestore
          .collection('attendance')
          .where('classId', isEqualTo: classId)
          .where('studentId', isEqualTo: studentId)
          .get();

      if (existingAttendance.docs.isNotEmpty) {
        return AttendanceResult(
          success: false,
          message: 'Attendance already marked for this class',
        );
      }

      // 6. Mark attendance
      await _firestore.collection('attendance').add({
        'classId': classId,
        'studentId': studentId,
        'subjectName': classData['subjectName'],
        'markedAt': FieldValue.serverTimestamp(),
        'status': 'present',
        'deviceId': deviceInfo['deviceId'],
        'method': 'qr_code', // Track that this was marked via QR
      });

      return AttendanceResult(
        success: true,
        message: 'Attendance marked successfully via QR code!',
        subjectName: classData['subjectName'],
      );
    } catch (e) {
      return AttendanceResult(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }
}
