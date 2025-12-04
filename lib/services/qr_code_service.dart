import 'dart:convert';
import 'package:crypto/crypto.dart';

class QRCodeService {
  // Generate QR code data for a class
  static String generateQRData({
    required String classId,
    required String subjectName,
    required DateTime validUntil,
  }) {
    final data = {
      'classId': classId,
      'subject': subjectName,
      'validUntil': validUntil.millisecondsSinceEpoch,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Add a simple hash for validation
    final dataString = jsonEncode(data);
    final hash = _generateHash(dataString);

    data['hash'] = hash;

    return jsonEncode(data);
  }

  // Validate QR code data
  static Map<String, dynamic> validateQRData(String qrData) {
    try {
      final Map<String, dynamic> data = jsonDecode(qrData);

      // Check if all required fields are present
      if (!data.containsKey('classId') ||
          !data.containsKey('subject') ||
          !data.containsKey('validUntil') ||
          !data.containsKey('timestamp') ||
          !data.containsKey('hash')) {
        return {'valid': false, 'message': 'Invalid QR code format'};
      }

      // Verify hash
      final receivedHash = data['hash'];
      data.remove('hash');
      final dataString = jsonEncode(data);
      final calculatedHash = _generateHash(dataString);

      if (receivedHash != calculatedHash) {
        return {'valid': false, 'message': 'QR code has been tampered with'};
      }

      // Check if QR code is still valid (time-based)
      final validUntil = DateTime.fromMillisecondsSinceEpoch(
        data['validUntil'],
      );
      final now = DateTime.now();

      if (now.isAfter(validUntil)) {
        return {'valid': false, 'message': 'QR code has expired'};
      }

      return {
        'valid': true,
        'classId': data['classId'],
        'subject': data['subject'],
        'validUntil': validUntil,
      };
    } catch (e) {
      return {'valid': false, 'message': 'Invalid QR code: ${e.toString()}'};
    }
  }

  // Generate a simple hash for validation
  static String _generateHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16); // Use first 16 characters
  }
}
