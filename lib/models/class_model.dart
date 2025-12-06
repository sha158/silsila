import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String classId;
  final String subjectName;
  final String teacherName;
  final String scheduledDate;
  final String startTime;
  final String endTime;
  final String password;
  final DateTime passwordActiveFrom;
  final DateTime passwordActiveUntil;
  final bool isPasswordActive;
  final bool autoGenerate;
  final DateTime createdAt;

  ClassModel({
    required this.classId,
    required this.subjectName,
    this.teacherName = '',
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    required this.password,
    required this.passwordActiveFrom,
    required this.passwordActiveUntil,
    required this.isPasswordActive,
    required this.autoGenerate,
    required this.createdAt,
  });

  factory ClassModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassModel(
      classId: doc.id,
      subjectName: data['subjectName'] ?? '',
      teacherName: data['teacherName'] ?? '',
      scheduledDate: data['scheduledDate'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      password: data['password'] ?? '',
      passwordActiveFrom: data['passwordActiveFrom'] != null
          ? (data['passwordActiveFrom'] as Timestamp).toDate()
          : DateTime.now(),
      passwordActiveUntil: data['passwordActiveUntil'] != null
          ? (data['passwordActiveUntil'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(hours: 1)),
      isPasswordActive: data['isPasswordActive'] ?? false,
      autoGenerate: data['autoGenerate'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'teacherName': teacherName,
      'scheduledDate': scheduledDate,
      'startTime': startTime,
      'endTime': endTime,
      'password': password,
      'passwordActiveFrom': Timestamp.fromDate(passwordActiveFrom),
      'passwordActiveUntil': Timestamp.fromDate(passwordActiveUntil),
      'isPasswordActive': isPasswordActive,
      'autoGenerate': autoGenerate,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
