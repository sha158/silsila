import 'dart:math';
import 'package:flutter/material.dart';

/// Shows a beautiful animated success dialog for attendance confirmation
Future<void> showAttendanceSuccessDialog({
  required BuildContext context,
  required String subject,
  required String message,
  VoidCallback? onDone,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Success Dialog',
    barrierColor: Colors.black.withOpacity(0.6),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) {
      return AttendanceSuccessDialog(
        subject: subject,
        message: message,
        onDone: () {
          Navigator.pop(context);
          onDone?.call();
        },
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return ScaleTransition(
        scale: curvedAnimation,
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

// Beautiful animated success dialog
class AttendanceSuccessDialog extends StatefulWidget {
  final String subject;
  final String message;
  final VoidCallback onDone;

  const AttendanceSuccessDialog({
    Key? key,
    required this.subject,
    required this.message,
    required this.onDone,
  }) : super(key: key);

  @override
  State<AttendanceSuccessDialog> createState() =>
      _AttendanceSuccessDialogState();
}

class _AttendanceSuccessDialogState extends State<AttendanceSuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _pulseController;
  late AnimationController _contentController;
  late AnimationController _confettiController;

  late Animation<double> _checkAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _subjectSlideAnimation;
  late Animation<double> _subjectFadeAnimation;
  late Animation<double> _messageSlideAnimation;
  late Animation<double> _messageFadeAnimation;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // Checkmark draw animation
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeOutCubic),
    );

    // Pulse glow animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Content stagger animations
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _titleSlideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _titleFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _subjectSlideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _subjectFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _messageSlideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
      ),
    );
    _messageFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
      ),
    );

    _buttonScaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Confetti animation
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  void _startAnimations() async {
    // Start check animation
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _checkController.forward();

    // Start pulse animation (looping)
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      _pulseController.repeat(reverse: true);
    }

    // Start content animations
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _contentController.forward();

    // Start confetti
    if (mounted) _confettiController.forward();
  }

  @override
  void dispose() {
    _checkController.dispose();
    _pulseController.dispose();
    _contentController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti particles
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(350, 450),
                painter: ConfettiPainter(progress: _confettiController.value),
              );
            },
          ),

          // Main dialog
          Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.green.shade50],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated checkmark with glow
                  _buildAnimatedCheckmark(),
                  const SizedBox(height: 28),

                  // Animated title
                  AnimatedBuilder(
                    animation: _contentController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _titleSlideAnimation.value),
                        child: Opacity(
                          opacity: _titleFadeAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.green.shade700, Colors.green.shade500],
                      ).createShader(bounds),
                      child: const Text(
                        '🎉 Attendance Marked!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Animated subject
                  AnimatedBuilder(
                    animation: _contentController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _subjectSlideAnimation.value),
                        child: Opacity(
                          opacity: _subjectFadeAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school_rounded,
                            size: 20,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.subject,
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Animated message
                  AnimatedBuilder(
                    animation: _contentController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _messageSlideAnimation.value),
                        child: Opacity(
                          opacity: _messageFadeAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Animated button
                  AnimatedBuilder(
                    animation: _contentController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _buttonScaleAnimation.value,
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade500,
                              Colors.green.shade700,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: widget.onDone,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCheckmark() {
    return AnimatedBuilder(
      animation: Listenable.merge([_checkController, _pulseController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: 110 * _pulseAnimation.value,
              height: 110 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.green.withOpacity(0.3 * (2 - _pulseAnimation.value)),
                    Colors.green.withOpacity(0),
                  ],
                ),
              ),
            ),

            // Middle glow
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade300.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),

            // Main circle with gradient
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade400.withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CustomPaint(
                size: const Size(90, 90),
                painter: CheckmarkPainter(progress: _checkAnimation.value),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Custom painter for animated checkmark
class CheckmarkPainter extends CustomPainter {
  final double progress;

  CheckmarkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path();

    // Checkmark points
    final startPoint = Offset(size.width * 0.25, size.height * 0.5);
    final midPoint = Offset(size.width * 0.42, size.height * 0.68);
    final endPoint = Offset(size.width * 0.75, size.height * 0.35);

    // Calculate current progress point
    if (progress <= 0.5) {
      // First line (start to mid)
      final p = progress * 2;
      checkPath.moveTo(startPoint.dx, startPoint.dy);
      checkPath.lineTo(
        startPoint.dx + (midPoint.dx - startPoint.dx) * p,
        startPoint.dy + (midPoint.dy - startPoint.dy) * p,
      );
    } else {
      // Complete first line and partial second line
      checkPath.moveTo(startPoint.dx, startPoint.dy);
      checkPath.lineTo(midPoint.dx, midPoint.dy);

      final p = (progress - 0.5) * 2;
      checkPath.lineTo(
        midPoint.dx + (endPoint.dx - midPoint.dx) * p,
        midPoint.dy + (endPoint.dy - midPoint.dy) * p,
      );
    }

    canvas.drawPath(checkPath, paint);
  }

  @override
  bool shouldRepaint(covariant CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Custom painter for confetti effect
class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  ConfettiPainter({required this.progress}) : particles = _generateParticles();

  static List<_ConfettiParticle> _generateParticles() {
    final random = Random();
    final particles = <_ConfettiParticle>[];
    final colors = [
      Colors.green.shade300,
      Colors.green.shade500,
      Colors.yellow.shade400,
      Colors.orange.shade300,
      Colors.blue.shade300,
      Colors.pink.shade300,
      Colors.purple.shade300,
      Colors.teal.shade300,
    ];

    for (int i = 0; i < 40; i++) {
      particles.add(
        _ConfettiParticle(
          x: random.nextDouble() * 350,
          initialY: 220 + random.nextDouble() * 60,
          speedY: 120 + random.nextDouble() * 180,
          speedX: -60 + random.nextDouble() * 120,
          size: 5 + random.nextDouble() * 8,
          color: colors[random.nextInt(colors.length)],
          rotation: random.nextDouble() * 360,
          rotationSpeed: random.nextDouble() * 6,
        ),
      );
    }
    return particles;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final yOffset = particle.initialY - (particle.speedY * progress);
      final xOffset = particle.x + (particle.speedX * progress);
      final opacity = (1 - progress * 0.8).clamp(0.0, 1.0);

      if (yOffset > -20 && opacity > 0) {
        final paint = Paint()
          ..color = particle.color.withOpacity(opacity)
          ..style = PaintingStyle.fill;

        canvas.save();
        canvas.translate(xOffset, yOffset);
        canvas.rotate(
          (particle.rotation + progress * particle.rotationSpeed) * pi / 180,
        );

        // Draw different shapes for variety
        final shapeType = (particle.rotation.toInt() % 3);
        if (shapeType == 0) {
          // Rectangle
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size * 0.6,
            ),
            paint,
          );
        } else if (shapeType == 1) {
          // Circle
          canvas.drawCircle(Offset.zero, particle.size / 2, paint);
        } else {
          // Star/diamond shape
          final path = Path();
          path.moveTo(0, -particle.size / 2);
          path.lineTo(particle.size / 4, 0);
          path.lineTo(0, particle.size / 2);
          path.lineTo(-particle.size / 4, 0);
          path.close();
          canvas.drawPath(path, paint);
        }

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ConfettiParticle {
  final double x;
  final double initialY;
  final double speedY;
  final double speedX;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;

  _ConfettiParticle({
    required this.x,
    required this.initialY,
    required this.speedY,
    required this.speedX,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
}
