import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/student.dart';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'package:universal_io/io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';
import 'dart:convert';

class ExcelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> exportAttendanceToExcel() async {
    try {
      // Request storage permission (skip for web)
      if (!kIsWeb && Platform.isAndroid) {
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
      final timestamp = DateTime.now();
      final fileName =
          'attendance_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour}${timestamp.minute}${timestamp.second}.xlsx';

      final fileBytes = excel.save();
      if (fileBytes != null) {
        if (kIsWeb) {
          // Web platform - trigger download
          _downloadFileWeb(fileBytes, fileName);
          return 'Excel file downloaded successfully: $fileName';
        } else {
          // Mobile/Desktop platform - save to file system
          final directory = Platform.isAndroid
              ? Directory('/storage/emulated/0/Download')
              : await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(fileBytes);

          return 'Excel file saved successfully to:\n${directory.path}/$fileName';
        }
      } else {
        return 'Failed to generate Excel file';
      }
    } catch (e) {
      return 'Export failed: ${e.toString()}';
    }
  }

  Future<String> exportFilteredAttendanceToExcel({
    String? subjectName,
    String? teacherName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Request storage permission (skip for web)
      if (!kIsWeb && Platform.isAndroid) {
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

      // Build query based on filters
      Query<Map<String, dynamic>> query = _firestore.collection('attendance');

      // Apply filters
      if (subjectName != null && subjectName.isNotEmpty) {
        query = query.where('subjectName', isEqualTo: subjectName);
      }

      // Fetch attendance data (without orderBy to avoid composite index requirement)
      final attendanceSnapshot = await query.get();

      if (attendanceSnapshot.docs.isEmpty) {
        return 'No attendance records found for the selected filters';
      }

      // Fetch students and classes data
      final studentsSnapshot = await _firestore.collection('students').get();
      final classesSnapshot = await _firestore.collection('classes').get();

      // Convert to maps for easier lookup
      final studentsMap = <String, Map<String, dynamic>>{};
      for (var doc in studentsSnapshot.docs) {
        studentsMap[doc.id] = doc.data();
      }

      final classesMap = <String, Map<String, dynamic>>{};
      for (var doc in classesSnapshot.docs) {
        classesMap[doc.id] = doc.data();
      }

      // Filter records based on additional criteria
      final filteredRecords = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      for (final doc in attendanceSnapshot.docs) {
        final record = doc.data();
        final classId = record['classId'] ?? '';
        final classData = classesMap[classId];

        // Apply teacher filter
        if (teacherName != null && teacherName.isNotEmpty) {
          final recordTeacher = classData?['teacherName'] ?? '';
          if (recordTeacher != teacherName) {
            continue;
          }
        }

        // Apply date range filter
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

        if (startDate != null) {
          final startOfDay = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );
          if (timestamp.isBefore(startOfDay)) {
            continue;
          }
        }

        if (endDate != null) {
          final endOfDay = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            23,
            59,
            59,
          );
          if (timestamp.isAfter(endOfDay)) {
            continue;
          }
        }

        filteredRecords.add(doc);
      }

      if (filteredRecords.isEmpty) {
        return 'No attendance records found for the selected filters';
      }

      // Sort filtered records by date (descending - most recent first)
      filteredRecords.sort((a, b) {
        try {
          final aTime = a.data()['markedAt'] as Timestamp?;
          final bTime = b.data()['markedAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime); // descending order
        } catch (e) {
          return 0;
        }
      });

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
        TextCellValue('Teacher'),
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
      for (final doc in filteredRecords) {
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
            record['subjectName'] ?? classData?['subjectName'] ?? 'Unknown',
          ),
          TextCellValue(classData?['teacherName'] ?? 'Unknown'),
          TextCellValue(record['status'] ?? 'Present'),
        ];
        sheet.appendRow(row);
      }

      // Auto-fit columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      // Build filename based on filters
      final timestamp = DateTime.now();
      String fileNamePrefix = 'attendance';

      if (subjectName != null && subjectName.isNotEmpty) {
        final safeSubject = subjectName.replaceAll(RegExp(r'[^\w\s-]'), '');
        fileNamePrefix += '_${safeSubject}';
      }

      if (teacherName != null && teacherName.isNotEmpty) {
        final safeTeacher = teacherName.replaceAll(RegExp(r'[^\w\s-]'), '');
        fileNamePrefix += '_${safeTeacher}';
      }

      if (startDate != null || endDate != null) {
        if (startDate != null) {
          fileNamePrefix +=
              '_from_${startDate.year}${startDate.month.toString().padLeft(2, '0')}${startDate.day.toString().padLeft(2, '0')}';
        }
        if (endDate != null) {
          fileNamePrefix +=
              '_to_${endDate.year}${endDate.month.toString().padLeft(2, '0')}${endDate.day.toString().padLeft(2, '0')}';
        }
      }

      final fileName =
          '${fileNamePrefix}_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour}${timestamp.minute}${timestamp.second}.xlsx';

      final fileBytes = excel.save();
      if (fileBytes != null) {
        if (kIsWeb) {
          // Web platform - trigger download
          _downloadFileWeb(fileBytes, fileName);
          return 'Excel file downloaded successfully: $fileName\n${filteredRecords.length} records exported';
        } else {
          // Mobile/Desktop platform - save to file system
          final directory = Platform.isAndroid
              ? Directory('/storage/emulated/0/Download')
              : await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(fileBytes);

          return 'Excel file saved successfully to:\n${directory.path}/$fileName\n${filteredRecords.length} records exported';
        }
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
      // Request storage permission (skip for web)
      if (!kIsWeb && Platform.isAndroid) {
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
      final timestamp = DateTime.now();
      final safeClassName = className.replaceAll(RegExp(r'[^\w\s-]'), '');
      final fileName =
          '${safeClassName}_attendance_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}.xlsx';

      final fileBytes = excel.save();
      if (fileBytes != null) {
        if (kIsWeb) {
          // Web platform - trigger download
          _downloadFileWeb(fileBytes, fileName);
          return 'Excel file downloaded successfully: $fileName';
        } else {
          // Mobile/Desktop platform - save to file system
          final directory = Platform.isAndroid
              ? Directory('/storage/emulated/0/Download')
              : await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(fileBytes);

          return 'Excel file saved successfully to:\n${directory.path}/$fileName';
        }
      } else {
        return 'Failed to generate Excel file';
      }
    } catch (e) {
      return 'Export failed: ${e.toString()}';
    }
  }

  Future<Map<String, dynamic>> importStudentsFromExcel() async {
    try {
      // Pick Excel or CSV file - withData: true ensures bytes are loaded (required for web)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
        withData: true,
        allowMultiple: false,
      );

      if (result == null) {
        return {'success': false, 'message': 'No file selected'};
      }

      // Validate file extension
      final fileName = result.files.single.name.toLowerCase();

      // Check if it's a CSV file
      if (fileName.endsWith('.csv')) {
        return await _importFromCSV(result);
      }

      if (!fileName.endsWith('.xlsx')) {
        return {
          'success': false,
          'message': 'Invalid file format. Please upload an .xlsx or .csv file'
        };
      }

      // Read Excel file - on web use bytes, on mobile use path
      Uint8List bytes;
      if (kIsWeb) {
        // On web, path is not available - must use bytes
        final fileBytes = result.files.single.bytes;
        if (fileBytes == null) {
          return {'success': false, 'message': 'Could not read file data'};
        }
        bytes = fileBytes;
      } else {
        // On mobile/desktop, use file path
        final filePath = result.files.single.path;
        if (filePath == null) {
          return {'success': false, 'message': 'Could not read file path'};
        }
        bytes = File(filePath).readAsBytesSync();
      }

      // Try to decode the Excel file
      Excel? excel;
      try {
        // Try decoding with different approaches
        try {
          excel = Excel.decodeBytes(bytes);
        } catch (e1) {
          // If direct decoding fails, try creating a new Excel object
          // and loading the bytes differently
          try {
            excel = Excel.createExcel();
            // This is a workaround - the package might need the data in a specific way
            excel = Excel.decodeBytes(bytes);
          } catch (e2) {
            throw Exception('Could not decode Excel file: ${e1.toString()}');
          }
        }
      } catch (decodeError) {
        // More user-friendly error message
        String errorMsg = decodeError.toString();

        if (errorMsg.contains('Unsupported operation') ||
            errorMsg.contains('format unsupported')) {
          return {
            'success': false,
            'message': 'Excel file format issue detected.\n\n'
                '✅ RECOMMENDED SOLUTION (CSV):\n'
                '1. Open your Excel file\n'
                '2. Click "File" → "Save As"\n'
                '3. Choose "CSV (Comma delimited) (*.csv)"\n'
                '4. Save and upload the CSV file\n'
                '   (CSV files work better and are more reliable!)\n\n'
                'OR\n\n'
                '📥 Use Our Template:\n'
                '1. Click the download button (⬇️) above\n'
                '2. Copy your data to the template\n'
                '3. Save and upload\n\n'
                'Technical error: ${errorMsg}'
          };
        }

        return {
          'success': false,
          'message': 'Failed to read Excel file.\n\n'
              'Please ensure:\n'
              '• File is saved as .xlsx (Excel 2007 or newer)\n'
              '• File is not corrupted\n'
              '• File is not password-protected\n'
              '• File was saved properly from Excel/Google Sheets\n\n'
              'Try downloading our template and copying your data to it.\n\n'
              'Error: ${errorMsg}'
        };
      }

      if (excel == null) {
        return {
          'success': false,
          'message': 'Failed to load Excel file. Please download and use our template.'
        };
      }

      if (excel.tables.isEmpty) {
        return {
          'success': false,
          'message': 'Excel file has no sheets. Please use a valid Excel file with data.'
        };
      }

      // Get first sheet
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null || sheet.rows.isEmpty) {
        return {
          'success': false,
          'message': 'The sheet "$sheetName" is empty. Please add student data to the sheet.'
        };
      }

      // Check if there's at least a header row and one data row
      if (sheet.rows.length < 2) {
        return {
          'success': false,
          'message': 'Excel file needs at least a header row and one student row.\n'
              'Please use our template for the correct format.'
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
          if (row.isEmpty ||
              row.every((cell) => cell == null || cell.value == null)) {
            continue;
          }

          // Extract data from columns (StudentID/RollNo, Name, PhoneNumber, Email)
          final studentId = row.isNotEmpty && row[0]?.value != null
              ? row[0]!.value.toString().trim().toUpperCase()
              : '';
          final name = row.length > 1 && row[1]?.value != null
              ? row[1]!.value.toString().trim()
              : '';
          final phoneNumber = row.length > 2 && row[2]?.value != null
              ? row[2]!.value.toString().trim()
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
      return {'success': false, 'message': 'Import failed: ${e.toString()}'};
    }
  }

  // Helper method to download file on web platform
  void _downloadFileWeb(List<int> bytes, String fileName) {
    if (kIsWeb) {
      // Create a blob from the bytes
      final blob = html.Blob([Uint8List.fromList(bytes)]);

      // Create a download link
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';

      // Trigger download
      html.document.body?.append(anchor);
      anchor.click();

      // Cleanup
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    }
  }

  // Get unique subjects from classes
  Future<List<String>> getUniqueSubjects() async {
    try {
      final classesSnapshot = await _firestore.collection('classes').get();
      final subjects = <String>{};

      for (var doc in classesSnapshot.docs) {
        final data = doc.data();
        final subject = data['subjectName'] as String?;
        if (subject != null && subject.isNotEmpty) {
          subjects.add(subject);
        }
      }

      return subjects.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  // Get unique teachers from classes
  Future<List<String>> getUniqueTeachers() async {
    try {
      final classesSnapshot = await _firestore.collection('classes').get();
      final teachers = <String>{};

      for (var doc in classesSnapshot.docs) {
        final data = doc.data();
        final teacher = data['teacherName'] as String?;
        if (teacher != null && teacher.isNotEmpty) {
          teachers.add(teacher);
        }
      }

      return teachers.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  // Import students from CSV file (more reliable alternative)
  Future<Map<String, dynamic>> _importFromCSV(FilePickerResult result) async {
    try {
      // Read CSV file
      Uint8List bytes;
      if (kIsWeb) {
        final fileBytes = result.files.single.bytes;
        if (fileBytes == null) {
          return {'success': false, 'message': 'Could not read file data'};
        }
        bytes = fileBytes;
      } else {
        final filePath = result.files.single.path;
        if (filePath == null) {
          return {'success': false, 'message': 'Could not read file path'};
        }
        bytes = File(filePath).readAsBytesSync();
      }

      // Convert bytes to string
      final csvString = utf8.decode(bytes);

      // Parse CSV
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(
        csvString,
        eol: '\n',
        fieldDelimiter: ',',
      );

      if (csvData.isEmpty) {
        return {'success': false, 'message': 'CSV file is empty'};
      }

      if (csvData.length < 2) {
        return {
          'success': false,
          'message': 'CSV file needs at least a header row and one student row'
        };
      }

      // Parse data (skip header row)
      int successCount = 0;
      int failCount = 0;
      List<String> errors = [];

      for (int i = 1; i < csvData.length; i++) {
        try {
          final row = csvData[i];

          // Skip empty rows
          if (row.isEmpty || row.every((cell) => cell == null || cell.toString().trim().isEmpty)) {
            continue;
          }

          // Extract data from columns
          final studentId = row.isNotEmpty && row[0] != null
              ? row[0].toString().trim().toUpperCase()
              : '';
          final name = row.length > 1 && row[1] != null
              ? row[1].toString().trim()
              : '';
          final phoneNumber = row.length > 2 && row[2] != null
              ? row[2].toString().trim()
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
      return {'success': false, 'message': 'CSV import failed: ${e.toString()}'};
    }
  }

  // Download sample Excel template for student import
  Future<String> downloadSampleTemplate() async {
    try {
      // Create Excel file
      final excel = Excel.createExcel();
      final sheet = excel['Students Template'];

      // Add headers
      final headers = [
        TextCellValue('Student ID'),
        TextCellValue('Name'),
        TextCellValue('Phone Number'),
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

      // Add sample data rows
      final sampleData = [
        [TextCellValue('ABC123'), TextCellValue('John Doe'), TextCellValue('1234567890')],
        [TextCellValue('XYZ456'), TextCellValue('Jane Smith'), TextCellValue('0987654321')],
        [TextCellValue('DEF789'), TextCellValue('Ali Ahmed'), TextCellValue('5555555555')],
      ];

      for (var row in sampleData) {
        sheet.appendRow(row);
      }

      // Add instructions sheet
      final instructionsSheet = excel['Instructions'];
      instructionsSheet.appendRow([TextCellValue('INSTRUCTIONS FOR IMPORTING STUDENTS')]);
      instructionsSheet.appendRow([TextCellValue('')]);
      instructionsSheet.appendRow([TextCellValue('1. Fill in the "Students Template" sheet with your student data')]);
      instructionsSheet.appendRow([TextCellValue('2. Student ID: Required, must be unique (e.g., ABC123)')]);
      instructionsSheet.appendRow([TextCellValue('3. Name: Required, student full name')]);
      instructionsSheet.appendRow([TextCellValue('4. Phone Number: Optional, contact number')]);
      instructionsSheet.appendRow([TextCellValue('')]);
      instructionsSheet.appendRow([TextCellValue('5. Delete the sample rows before importing')]);
      instructionsSheet.appendRow([TextCellValue('6. Keep the header row (first row)')]);
      instructionsSheet.appendRow([TextCellValue('7. Save as .xlsx format (Excel 2007 or newer)')]);
      instructionsSheet.appendRow([TextCellValue('')]);
      instructionsSheet.appendRow([TextCellValue('IMPORTANT:')]);
      instructionsSheet.appendRow([TextCellValue('- Do not use .xls format (old Excel)')]);
      instructionsSheet.appendRow([TextCellValue('- Do not password-protect the file')]);
      instructionsSheet.appendRow([TextCellValue('- Ensure file is not corrupted')]);

      // Auto-fit columns
      for (int i = 0; i < 3; i++) {
        sheet.setColumnWidth(i, 25);
      }
      instructionsSheet.setColumnWidth(0, 70);

      // Save file
      final fileName = 'students_import_template.xlsx';
      final fileBytes = excel.save();

      if (fileBytes != null) {
        if (kIsWeb) {
          // Web platform - trigger download
          _downloadFileWeb(fileBytes, fileName);
          return 'Template downloaded successfully: $fileName';
        } else {
          // Mobile/Desktop platform - save to file system
          final directory = Platform.isAndroid
              ? Directory('/storage/emulated/0/Download')
              : await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(fileBytes);

          return 'Template saved successfully to:\n${directory.path}/$fileName';
        }
      } else {
        return 'Failed to generate template';
      }
    } catch (e) {
      return 'Template download failed: ${e.toString()}';
    }
  }
  Future<String> exportDailyConsolidatedAttendance(DateTime date) async {
    try {
      // 1. Permission Check
      if (Platform.isAndroid) {
        if (await Permission.manageExternalStorage.isGranted) {
          // Granted
        } else {
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            final storageStatus = await Permission.storage.request();
            if (!storageStatus.isGranted) {
              return 'Storage permission denied.';
            }
          }
        }
      }

      // 2. Fetch All Students (Active ones preferably, or all)
      final studentsSnapshot = await _firestore.collection('students').get();
      if (studentsSnapshot.docs.isEmpty) {
        return 'No students found in the database.';
      }

      // Sort students by name or ID for better readability
      final students = studentsSnapshot.docs.map((doc) => doc.data()).toList();
      students.sort((a, b) =>
          (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));

      // 3. Fetch Classes for the specific date
      // Date format in DB seems to be String "YYYY-MM-DD" based on ClassModel?
      // Or we can construct it if it's consistent.
      // Let's assume standard ISO or the format used in existing code.
      // Checking ClassModel... scheduledDate is String.
      final dateString =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final classesSnapshot = await _firestore
          .collection('classes')
          .where('scheduledDate', isEqualTo: dateString)
          .orderBy('startTime') // Order columns by time
          .get();

      if (classesSnapshot.docs.isEmpty) {
        return 'No classes found scheduled for $dateString';
      }

      final classes = classesSnapshot.docs;

      // 4. Fetch Attendance for these classes
      final classIds = classes.map((c) => c.id).toList();
      // Firestore 'whereIn' supports up to 10 items. If > 10 classes, we might need multiple queries.
      // For now, let's assume < 10 classes/day.
      // Optimization: Fetch ALL attendance for this day? Or per class?
      // Since we want ALL students, fetching by classId list is efficient if count is low.

      // Map<ClassId, Map<StudentId, Status>>
      final Map<String, Map<String, String>> attendanceMap = {};

      // Initialize map entries for each class
      for (var cls in classes) {
        attendanceMap[cls.id] = {};
      }

      // Fetch attendance in batches if needed, or loop if class count is small
      for (var cls in classes) {
        final attSnap = await _firestore
            .collection('attendance')
            .where('classId', isEqualTo: cls.id)
            .get();

        for (var doc in attSnap.docs) {
          final data = doc.data();
          final sId = data['studentId'] as String?;
          final status = data['status'] as String? ?? 'Present';
          if (sId != null) {
            attendanceMap[cls.id]![sId] = status;
          }
        }
      }

      // 5. Build Excel
      final excel = Excel.createExcel();
      final sheet = excel['Daily Report'];
      
      // Delete default sheet if exists/renamed
      // if (excel.tables.keys.contains('Sheet1')) {
      //    excel.delete('Sheet1'); 
      // }
      
      // Header Row
      List<TextCellValue> headers = [
        TextCellValue('Student ID'),
        TextCellValue('Name'),
        TextCellValue('Phone'),
      ];

      // Add Class columns
      for (var cls in classes) {
        final data = cls.data();
        final subject = data['subjectName'] ?? 'Class';
        final time = data['startTime'] ?? '';
        headers.add(TextCellValue('$subject\n($time)'));
      }
      
      sheet.appendRow(headers);

      // Style Header
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue,
          fontColorHex: ExcelColor.white,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }

      // Data Rows
      for (var student in students) {
        final sId = student['studentId'] as String? ?? '';
        final sName = student['name'] as String? ?? 'Unknown';
        final sPhone = student['phoneNumber'] as String? ?? '';

        List<TextCellValue> row = [
           TextCellValue(sId),
           TextCellValue(sName),
           TextCellValue(sPhone),
        ];

        // For each class column, check attendance
        for (var cls in classes) {
          final status = attendanceMap[cls.id]?[sId];
          row.add(TextCellValue(status ?? 'Absent')); 
          // Defaulting to Absent if no record found for a registered student in a scheduled class
        }
        
        sheet.appendRow(row);
      }

      // Auto-fit (Simple approximation)
      sheet.setColumnWidth(0, 15); // ID
      sheet.setColumnWidth(1, 25); // Name
      sheet.setColumnWidth(2, 15); // Phone
      for (int i = 3; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20); // Class Columns
      }

      // 6. Save File
      final directory = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();

      final timestamp = DateTime.now();
      final fileName = 'Daily_Report_$dateString.xlsx';
      final filePath = '${directory.path}/$fileName';

      // Ensure unique name
      String finalPath = filePath;
      int counter = 1;
      while (await File(finalPath).exists()) {
         finalPath = '${directory.path}/Daily_Report_${dateString}_$counter.xlsx';
         counter++;
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(finalPath);
        await file.writeAsBytes(fileBytes);
        return 'Report saved to: \n$finalPath';
      } else {
        return 'Failed to generate file.';
      }

    } catch (e) {
      return 'Export Error: $e';
    }
  }
}
