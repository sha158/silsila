import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExcelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> exportAttendanceToExcel() async {
    try {
      // Request storage permission
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), use manageExternalStorage
        if (await Permission.manageExternalStorage.isGranted) {
          // Already granted
        } else {
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            // Try legacy storage permission for older Android versions
            final storageStatus = await Permission.storage.request();
            if (!storageStatus.isGranted) {
              return 'Storage permission denied. Please grant storage access in app settings.';
            }
          }
        }
      }

      // Fetch data from Firestore
      final attendanceSnapshot = await _firestore
          .collection('attendance')
          .orderBy('markedAt', descending: true)
          .get();

      final studentsSnapshot = await _firestore.collection('students').get();

      final classesSnapshot = await _firestore.collection('classes').get();

      if (attendanceSnapshot.docs.isEmpty) {
        return 'No attendance records to export';
      }

      // Convert to maps for easier lookup
      final studentsMap = <String, Map<String, dynamic>>{};
      for (var doc in studentsSnapshot.docs) {
        studentsMap[doc.id] = doc.data();
      }

      final classesMap = <String, Map<String, dynamic>>{};
      for (var doc in classesSnapshot.docs) {
        classesMap[doc.id] = doc.data();
      }

      // Create Excel file
      final excel = Excel.createExcel();
      final sheet = excel['Attendance Records'];

      // Add headers
      final headers = [
        TextCellValue('Date'),
        TextCellValue('Time'),
        TextCellValue('Student Name'),
        TextCellValue('Student ID'),
        TextCellValue('Subject'),
        TextCellValue('Status'),
      ];
      sheet.appendRow(headers);

      // Style headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue,
          fontColorHex: ExcelColor.white,
        );
      }

      // Add data rows
      for (final doc in attendanceSnapshot.docs) {
        final record = doc.data();
        final studentId = record['studentId'] ?? '';
        final classId = record['classId'] ?? '';

        final studentData = studentsMap[studentId];
        final classData = classesMap[classId];

        DateTime timestamp;
        try {
          if (record['markedAt'] != null) {
            timestamp = (record['markedAt'] as Timestamp).toDate();
          } else {
            timestamp = DateTime.now();
          }
        } catch (e) {
          timestamp = DateTime.now();
        }

        final row = [
          TextCellValue(
            '${timestamp.day}/${timestamp.month}/${timestamp.year}',
          ),
          TextCellValue(
            '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
          ),
          TextCellValue(studentData?['name'] ?? 'Unknown'),
          TextCellValue(studentId),
          TextCellValue(
            record['subjectName'] ?? classData?['name'] ?? 'Unknown',
          ),
          TextCellValue(record['status'] ?? 'Present'),
        ];
        sheet.appendRow(row);
      }

      // Auto-fit columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      // Save file
      final directory = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();

      final timestamp = DateTime.now();
      final fileName =
          'attendance_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour}${timestamp.minute}${timestamp.second}.xlsx';
      final filePath = '${directory.path}/$fileName';

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        return 'Excel file saved successfully to:\n${directory.path}/$fileName';
      } else {
        return 'Failed to generate Excel file';
      }
    } catch (e) {
      return 'Export failed: ${e.toString()}';
    }
  }

  Future<String> exportClassAttendanceToExcel(
    String classId,
    String className,
  ) async {
    try {
      // Request storage permission
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), use manageExternalStorage
        if (await Permission.manageExternalStorage.isGranted) {
          // Already granted
        } else {
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            // Try legacy storage permission for older Android versions
            final storageStatus = await Permission.storage.request();
            if (!storageStatus.isGranted) {
              return 'Storage permission denied. Please grant storage access in app settings.';
            }
          }
        }
      }

      // Fetch data from Firestore
      final attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('classId', isEqualTo: classId)
          .orderBy('markedAt', descending: true)
          .get();

      final studentsSnapshot = await _firestore.collection('students').get();

      if (attendanceSnapshot.docs.isEmpty) {
        return 'No attendance records found for this class';
      }

      // Convert to map for easier lookup
      final studentsMap = <String, Map<String, dynamic>>{};
      for (var doc in studentsSnapshot.docs) {
        studentsMap[doc.id] = doc.data();
      }

      // Create Excel file
      final excel = Excel.createExcel();
      final sheet = excel['Attendance'];

      // Add headers
      final headers = [
        TextCellValue('Date'),
        TextCellValue('Time'),
        TextCellValue('Student Name'),
        TextCellValue('Student ID'),
        TextCellValue('Status'),
      ];
      sheet.appendRow(headers);

      // Style headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue,
          fontColorHex: ExcelColor.white,
        );
      }

      // Add data rows
      for (final doc in attendanceSnapshot.docs) {
        final record = doc.data();
        final studentId = record['studentId'] ?? '';
        final studentData = studentsMap[studentId];

        DateTime timestamp;
        try {
          if (record['markedAt'] != null) {
            timestamp = (record['markedAt'] as Timestamp).toDate();
          } else {
            timestamp = DateTime.now();
          }
        } catch (e) {
          timestamp = DateTime.now();
        }

        final row = [
          TextCellValue(
            '${timestamp.day}/${timestamp.month}/${timestamp.year}',
          ),
          TextCellValue(
            '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
          ),
          TextCellValue(studentData?['name'] ?? 'Unknown'),
          TextCellValue(studentId),
          TextCellValue(record['status'] ?? 'Present'),
        ];
        sheet.appendRow(row);
      }

      // Auto-fit columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      // Save file
      final directory = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();

      final timestamp = DateTime.now();
      final safeClassName = className.replaceAll(RegExp(r'[^\w\s-]'), '');
      final fileName =
          '${safeClassName}_attendance_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}.xlsx';
      final filePath = '${directory.path}/$fileName';

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        return 'Excel file saved successfully to:\n${directory.path}/$fileName';
      } else {
        return 'Failed to generate Excel file';
      }
    } catch (e) {
      return 'Export failed: ${e.toString()}';
    }
  }
}
