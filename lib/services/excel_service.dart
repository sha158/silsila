import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../models/student.dart';

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

  Future<Map<String, dynamic>> importStudentsFromExcel() async {
    try {
      // Pick Excel file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null) {
        return {
          'success': false,
          'message': 'No file selected',
        };
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        return {
          'success': false,
          'message': 'Could not read file path',
        };
      }

      // Read Excel file
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        return {
          'success': false,
          'message': 'Excel file is empty',
        };
      }

      // Get first sheet
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null || sheet.rows.isEmpty) {
        return {
          'success': false,
          'message': 'Sheet is empty',
        };
      }

      // Parse data (skip header row)
      int successCount = 0;
      int failCount = 0;
      List<String> errors = [];

      for (int i = 1; i < sheet.rows.length; i++) {
        try {
          final row = sheet.rows[i];

          // Skip empty rows
          if (row.isEmpty || row.every((cell) => cell == null || cell.value == null)) {
            continue;
          }

          // Extract data from columns (StudentID/RollNo, Name, PhoneNumber, Email)
          final studentId = row.length > 0 && row[0]?.value != null
              ? row[0]!.value.toString().trim().toUpperCase()
              : '';
          final name = row.length > 1 && row[1]?.value != null
              ? row[1]!.value.toString().trim()
              : '';
          final phoneNumber = row.length > 2 && row[2]?.value != null
              ? row[2]!.value.toString().trim()
              : '';
          final email = row.length > 3 && row[3]?.value != null
              ? row[3]!.value.toString().trim()
              : '';

          // Validate required fields
          if (name.isEmpty || studentId.isEmpty) {
            errors.add('Row ${i + 1}: Missing name or student ID');
            failCount++;
            continue;
          }

          // Create student object
          final student = Student(
            studentId: studentId,
            name: name,
            phoneNumber: phoneNumber,
            isActive: true,
            createdAt: DateTime.now(),
          );

          // Save to Firestore
          await _firestore
              .collection('students')
              .doc(student.studentId)
              .set(student.toMap());

          successCount++;
        } catch (e) {
          errors.add('Row ${i + 1}: ${e.toString()}');
          failCount++;
        }
      }

      // Build result message
      String message = 'Import completed!\n';
      message += 'Successfully added: $successCount students\n';
      if (failCount > 0) {
        message += 'Failed: $failCount students\n';
        if (errors.isNotEmpty) {
          message += '\nErrors:\n${errors.take(5).join('\n')}';
          if (errors.length > 5) {
            message += '\n... and ${errors.length - 5} more errors';
          }
        }
      }

      return {
        'success': successCount > 0,
        'message': message,
        'successCount': successCount,
        'failCount': failCount,
        'errors': errors,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Import failed: ${e.toString()}',
      };
    }
  }
}
