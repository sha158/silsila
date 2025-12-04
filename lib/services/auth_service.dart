import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import '../models/admin.dart';
import 'device_service.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Student Authentication
  Future<Map<String, dynamic>> studentLogin(String studentId) async {
    try {
      // Get device info
      Map<String, String> deviceInfo = await DeviceService.getDeviceInfo();

      // Check if student exists
      DocumentSnapshot studentDoc = await _firestore
          .collection('students')
          .doc(studentId.toUpperCase())
          .get();

      if (!studentDoc.exists) {
        return {'success': false, 'message': 'Invalid Student ID'};
      }

      Student student = Student.fromFirestore(studentDoc);

      // Check if student is active
      if (!student.isActive) {
        return {
          'success': false,
          'message': 'Student account is inactive. Please contact admin.',
        };
      }

      // First-time login - bind device
      if (student.deviceId == null || student.deviceId!.isEmpty) {
        await _firestore
            .collection('students')
            .doc(studentId.toUpperCase())
            .update({
              'deviceId': deviceInfo['deviceId'],
              'deviceModel': deviceInfo['deviceModel'],
              'registeredOn': FieldValue.serverTimestamp(),
              'lastLoginAt': FieldValue.serverTimestamp(),
            });

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('studentId', studentId.toUpperCase());
        await prefs.setBool('isStudent', true);

        return {
          'success': true,
          'message': 'Device registered successfully!',
          'student': student,
          'firstTime': true,
        };
      }

      // Verify device binding
      if (student.deviceId != deviceInfo['deviceId']) {
        return {
          'success': false,
          'message': 'This Student ID is registered on another device',
        };
      }

      // Update last login
      await _firestore
          .collection('students')
          .doc(studentId.toUpperCase())
          .update({'lastLoginAt': FieldValue.serverTimestamp()});

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('studentId', studentId.toUpperCase());
      await prefs.setBool('isStudent', true);

      return {
        'success': true,
        'message': 'Login successful',
        'student': student,
        'firstTime': false,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Admin Authentication
  Future<Map<String, dynamic>> adminLogin(String email, String password) async {
    try {
      // Query admins collection
      QuerySnapshot adminQuery = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .get();

      if (adminQuery.docs.isEmpty) {
        return {'success': false, 'message': 'Invalid email or password'};
      }

      Admin admin = Admin.fromFirestore(adminQuery.docs.first);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('adminId', admin.adminId);
      await prefs.setBool('isAdmin', true);

      return {'success': true, 'message': 'Login successful', 'admin': admin};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Check auto-login
  Future<Map<String, dynamic>> checkAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isStudent = prefs.getBool('isStudent') ?? false;
      final isAdmin = prefs.getBool('isAdmin') ?? false;

      if (isStudent) {
        final studentId = prefs.getString('studentId');
        if (studentId != null) {
          // Verify device still matches
          Map<String, String> deviceInfo = await DeviceService.getDeviceInfo();
          DocumentSnapshot studentDoc = await _firestore
              .collection('students')
              .doc(studentId)
              .get();

          if (studentDoc.exists) {
            Student student = Student.fromFirestore(studentDoc);
            if (student.deviceId == deviceInfo['deviceId'] &&
                student.isActive) {
              return {'autoLogin': true, 'type': 'student', 'data': student};
            }
          }
        }
      }

      if (isAdmin) {
        final adminId = prefs.getString('adminId');
        if (adminId != null) {
          DocumentSnapshot adminDoc = await _firestore
              .collection('admins')
              .doc(adminId)
              .get();

          if (adminDoc.exists) {
            Admin admin = Admin.fromFirestore(adminDoc);
            return {'autoLogin': true, 'type': 'admin', 'data': admin};
          }
        }
      }

      return {'autoLogin': false};
    } catch (e) {
      return {'autoLogin': false};
    }
  }

  // Get current student
  Future<Student?> getCurrentStudent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getString('studentId');

      if (studentId != null) {
        DocumentSnapshot studentDoc = await _firestore
            .collection('students')
            .doc(studentId)
            .get();

        if (studentDoc.exists) {
          return Student.fromFirestore(studentDoc);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get current admin
  Future<Admin?> getCurrentAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminId = prefs.getString('adminId');

      if (adminId != null) {
        DocumentSnapshot adminDoc = await _firestore
            .collection('admins')
            .doc(adminId)
            .get();

        if (adminDoc.exists) {
          return Admin.fromFirestore(adminDoc);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
