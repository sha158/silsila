import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/qr_code_service.dart';
import '../../services/attendance_service.dart';
import '../../widgets/attendance_success_dialog.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _scanCompleted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _scanCompleted) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrData = barcodes.first.rawValue;
    if (qrData == null || qrData.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // Validate QR code
      final validation = QRCodeService.validateQRData(qrData);

      if (!validation['valid']) {
        _showErrorDialog(validation['message'] ?? 'Invalid QR code');
        setState(() => _isProcessing = false);
        return;
      }

      // Get student ID
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getString('studentId');

      if (studentId == null) {
        _showErrorDialog('Please login first');
        setState(() => _isProcessing = false);
        return;
      }

      // Mark attendance
      final attendanceService = Provider.of<AttendanceService>(
        context,
        listen: false,
      );
      final result = await attendanceService.markAttendanceByQR(
        studentId: studentId,
        classId: validation['classId'],
      );

      if (!mounted) return;

      setState(() => _scanCompleted = true);

      if (result.success) {
        _showSuccessDialog(validation['subject'], result.message);
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog(String subject, String message) {
    showAttendanceSuccessDialog(
      context: context,
      subject: subject,
      message: message,
      onDone: () {
        Navigator.pop(context, true);
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _scanCompleted = false;
                _isProcessing = false;
              });
            },
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan QR Code',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Overlay with scanning frame
          CustomPaint(painter: ScannerOverlay(), child: Container()),

          // Instructions
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Position the QR code within the frame',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Processing...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Flash toggle button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.flash_on,
                    color: Colors.blue.shade700,
                    size: 32,
                  ),
                  onPressed: () => _controller.toggleTorch(),
                  iconSize: 32,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for scanner overlay
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 280,
      height: 280,
    );

    // Draw overlay with transparent center
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(20)))
        ..fillType = PathFillType.evenOdd,
      paint,
    );

    // Draw corner borders
    final borderPaint = Paint()
      ..color = Colors.blue.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerLength = 30.0;
    final corners = [
      // Top-left
      [
        Offset(scanArea.left, scanArea.top + cornerLength),
        Offset(scanArea.left, scanArea.top),
        Offset(scanArea.left + cornerLength, scanArea.top),
      ],
      // Top-right
      [
        Offset(scanArea.right - cornerLength, scanArea.top),
        Offset(scanArea.right, scanArea.top),
        Offset(scanArea.right, scanArea.top + cornerLength),
      ],
      // Bottom-right
      [
        Offset(scanArea.right, scanArea.bottom - cornerLength),
        Offset(scanArea.right, scanArea.bottom),
        Offset(scanArea.right - cornerLength, scanArea.bottom),
      ],
      // Bottom-left
      [
        Offset(scanArea.left + cornerLength, scanArea.bottom),
        Offset(scanArea.left, scanArea.bottom),
        Offset(scanArea.left, scanArea.bottom - cornerLength),
      ],
    ];

    for (final corner in corners) {
      final path = Path()
        ..moveTo(corner[0].dx, corner[0].dy)
        ..lineTo(corner[1].dx, corner[1].dy)
        ..lineTo(corner[2].dx, corner[2].dy);
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
