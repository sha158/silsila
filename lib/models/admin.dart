import 'package:cloud_firestore/cloud_firestore.dart';

class Admin {
  final String adminId;
  final String email;
  final String password;
  final String name;
  final String role;
  final DateTime createdAt;

  Admin({
    required this.adminId,
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  factory Admin.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Admin(
      adminId: doc.id,
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'admin',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
      'name': name,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
