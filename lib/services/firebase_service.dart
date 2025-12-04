import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
import '../models/class_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Student Management
  Future<bool> addStudent(Student student) async {
    try {
      await _firestore
          .collection('students')
          .doc(student.studentId)
          .set(student.toMap());
      return true;
    } catch (e) {
      print('Error adding student: $e');
      return false;
    }
  }

  Future<bool> updateStudent(String studentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('students').doc(studentId).update(data);
      return true;
    } catch (e) {
      print('Error updating student: $e');
      return false;
    }
  }

  Future<bool> deleteStudent(String studentId) async {
    try {
      await _firestore.collection('students').doc(studentId).delete();
      return true;
    } catch (e) {
      print('Error deleting student: $e');
      return false;
    }
  }

  Stream<QuerySnapshot> getAllStudents() {
    return _firestore
        .collection('students')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<DocumentSnapshot> getStudent(String studentId) {
    return _firestore.collection('students').doc(studentId).get();
  }

  // Class Management
  Future<String?> addClass(ClassModel classModel) async {
    try {
      final docRef = await _firestore.collection('classes').add(classModel.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding class: $e');
      return null;
    }
  }

  Future<bool> updateClass(String classId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('classes').doc(classId).update(data);
      return true;
    } catch (e) {
      print('Error updating class: $e');
      return false;
    }
  }

  Future<bool> deleteClass(String classId) async {
    try {
      await _firestore.collection('classes').doc(classId).delete();
      return true;
    } catch (e) {
      print('Error deleting class: $e');
      return false;
    }
  }

  Stream<QuerySnapshot> getAllClasses() {
    return _firestore
        .collection('classes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUpcomingClasses() {
    DateTime now = DateTime.now();
    return _firestore
        .collection('classes')
        .where('passwordActiveFrom', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('passwordActiveFrom')
        .snapshots();
  }

  Stream<QuerySnapshot> getActiveClasses() {
    DateTime now = DateTime.now();
    return _firestore
        .collection('classes')
        .where('isPasswordActive', isEqualTo: true)
        .where('passwordActiveUntil', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('passwordActiveUntil')
        .snapshots();
  }

  // Attendance Management
  Stream<QuerySnapshot> getAttendanceForClass(String classId) {
    return _firestore
        .collection('attendance')
        .where('classId', isEqualTo: classId)
        .orderBy('markedAt')
        .snapshots();
  }

  Stream<QuerySnapshot> getAllAttendance() {
    return _firestore
        .collection('attendance')
        .orderBy('markedAt', descending: true)
        .snapshots();
  }

  Future<QuerySnapshot> getAttendanceForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection('attendance')
        .where('markedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('markedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('markedAt', descending: true)
        .get();
  }

  // Reset device binding
  Future<bool> resetDeviceBinding(String studentId) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'deviceId': null,
        'deviceModel': null,
        'registeredOn': null,
      });
      return true;
    } catch (e) {
      print('Error resetting device: $e');
      return false;
    }
  }
}
