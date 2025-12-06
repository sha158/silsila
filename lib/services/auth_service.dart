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

      // Normalize input - trim and convert to uppercase
      String inputId = studentId.trim().toUpperCase();

      // Try to find student - first exact match
      DocumentSnapshot? studentDoc;
      String? actualStudentId;

      // Step 1: Try exact match with the input
      studentDoc = await _firestore.collection('students').doc(inputId).get();

      if (studentDoc.exists) {
        actualStudentId = inputId;
      } else {
        // Step 2: If input doesn't contain hyphen, search for ID ending with input
        // This allows "M001" to match "SHWN-M001"
        if (!inputId.contains('-')) {
          // Search for student where ID ends with the input
          QuerySnapshot querySnapshot = await _firestore
              .collection('students')
              .get();

          // Find the first document where ID ends with the input
          for (var doc in querySnapshot.docs) {
            String docId = doc.id.toUpperCase();
            // Check if document ID ends with "-{input}" or equals input
            if (docId.endsWith('-$inputId') || docId == inputId) {
              studentDoc = doc;
              actualStudentId = doc.id;
              break;
            }
          }
        }
      }

      // If still not found, return error
      if (studentDoc == null || !studentDoc.exists || actualStudentId == null) {
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
        await _firestore.collection('students').doc(actualStudentId).update({
          'deviceId': deviceInfo['deviceId'],
          'deviceModel': deviceInfo['deviceModel'],
          'registeredOn': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        // Save to SharedPreferences - use the actual student ID from database
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('studentId', actualStudentId);
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
      await _firestore.collection('students').doc(actualStudentId).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      // Save to SharedPreferences - use the actual student ID from database
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('studentId', actualStudentId);
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

    // Only remove session-related keys, preserve "Keep me logged in" credentials
    await prefs.remove('studentId');
    await prefs.remove('isStudent');
    await prefs.remove('adminId');
    await prefs.remove('isAdmin');

    // Keep the following keys intact for "Keep me logged in" feature:
    // - admin_saved_email
    // - admin_saved_password
    // - admin_keep_logged_in
  }
}
