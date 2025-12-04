import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String studentId;
  final String name;
  final String? phoneNumber;
  final String? deviceId;
  final String? deviceModel;
  final bool isActive;
  final DateTime? registeredOn;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  Student({
    required this.studentId,
    required this.name,
    this.phoneNumber,
    this.deviceId,
    this.deviceModel,
    this.isActive = true,
    this.registeredOn,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      studentId: doc.id,
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'],
      deviceId: data['deviceId'],
      deviceModel: data['deviceModel'],
      isActive: data['isActive'] ?? true,
      registeredOn: data['registeredOn'] != null
          ? (data['registeredOn'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'deviceId': deviceId,
      'deviceModel': deviceModel,
      'isActive': isActive,
      'registeredOn': registeredOn != null ? Timestamp.fromDate(registeredOn!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }
}
