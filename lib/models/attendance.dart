import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String attendanceId;
  final String classId;
  final String studentId;
  final String subjectName;
  final DateTime markedAt;
  final String status;
  final String deviceId;

  Attendance({
    required this.attendanceId,
    required this.classId,
    required this.studentId,
    required this.subjectName,
    required this.markedAt,
    required this.status,
    required this.deviceId,
  });

  factory Attendance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Attendance(
      attendanceId: doc.id,
      classId: data['classId'] ?? '',
      studentId: data['studentId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      markedAt: (data['markedAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'present',
      deviceId: data['deviceId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'studentId': studentId,
      'subjectName': subjectName,
      'markedAt': Timestamp.fromDate(markedAt),
      'status': status,
      'deviceId': deviceId,
    };
  }
}
