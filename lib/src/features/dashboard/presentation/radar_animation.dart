import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_background_service/flutter_background_service.dart';

class RadarAnimation extends StatefulWidget {
  final bool isScanning;
  final double? pingDistance; // 0.0 = center, 1.0 = edge, null = no ping
  final double? pingAngle; // angle in radians for ping position

  const RadarAnimation({
    super.key,
    this.isScanning = true,
    this.pingDistance,
    this.pingAngle,
  });

  @override
  State<RadarAnimation> createState() => _RadarAnimationState();
}

class _RadarAnimationState extends State<RadarAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _radarController;
  late final AnimationController _pingController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.isScanning) {
      _radarController.repeat();
    }

    if (widget.pingDistance != null) {
      _pingController.repeat();
    }

    _initBackgroundService();
  }

  void _initBackgroundService() async {
    final service = FlutterBackgroundService();
    service.on('update').listen((event) {});
  }

  @override
  void didUpdateWidget(covariant RadarAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_radarController.isAnimating) {
      _radarController.repeat();
    } else if (!widget.isScanning && _radarController.isAnimating) {
      _radarController.stop();
    }

    if (widget.pingDistance != null && !_pingController.isAnimating) {
      _pingController.repeat();
    } else if (widget.pingDistance == null && _pingController.isAnimating) {
      _pingController.stop();
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_radarController, _pingController]),
      builder: (context, child) {
        return CustomPaint(
          painter: RadarPainter(
            radarProgress: _radarController.value,
            pingProgress: _pingController.value,
            pingDistance: widget.pingDistance,
            pingAngle: widget.pingAngle ?? pi / 4,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class RadarPainter extends CustomPainter {
  final double radarProgress;
  final double pingProgress;
  final double? pingDistance;
  final double pingAngle;

  RadarPainter({
    required this.radarProgress,
    required this.pingProgress,
    this.pingDistance,
    this.pingAngle = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.45;

    // Draw concentric circles
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * (i / 4), circlePaint);
    }

    // Draw crosshairs
    final crosshairPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(center.dx - maxRadius, center.dy),
        Offset(center.dx + maxRadius, center.dy), crosshairPaint);
    canvas.drawLine(Offset(center.dx, center.dy - maxRadius),
        Offset(center.dx, center.dy + maxRadius), crosshairPaint);

    // Draw scanning line
    final sweepAngle = radarProgress * 2 * pi;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle - 0.5,
        endAngle: sweepAngle,
        colors: [
          Colors.transparent,
          const Color(0xFFF4436C).withValues(alpha: 0.3),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.save();
    final sweepPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: maxRadius),
        sweepAngle - 0.5,
        0.5,
        false,
      )
      ..close();
    canvas.drawPath(sweepPath, sweepPaint);
    canvas.restore();

    // Draw scanning line itself
    final lineEndX = center.dx + maxRadius * cos(sweepAngle);
    final lineEndY = center.dy + maxRadius * sin(sweepAngle);
    final linePaint = Paint()
      ..color = const Color(0xFFF4436C).withValues(alpha: 0.6)
      ..strokeWidth = 2;
    canvas.drawLine(center, Offset(lineEndX, lineEndY), linePaint);

    // Center dot
    final centerDotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, centerDotPaint);

    // Sonar ping (if active)
    if (pingDistance != null) {
      _drawSonarPing(canvas, center, maxRadius);
    }
  }

  void _drawSonarPing(Canvas canvas, Offset center, double maxRadius) {
    final dist = pingDistance! * maxRadius;
    final pingX = center.dx + dist * cos(pingAngle);
    final pingY = center.dy + dist * sin(pingAngle);
    final pingCenter = Offset(pingX, pingY);

    // Pulsing ring effect - made stronger
    for (int i = 0; i < 4; i++) {
      final ringProgress = (pingProgress + i * 0.25) % 1.0;
      final ringRadius = 8.0 + ringProgress * 30.0;
      final ringAlpha = (1.0 - ringProgress) * 0.8;
      final ringPaint = Paint()
        ..color = const Color(0xFFF4436C).withValues(alpha: ringAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(pingCenter, ringRadius, ringPaint);
    }

    // Core dot - larger
    final dotPaint = Paint()
      ..color = const Color(0xFFF4436C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pingCenter, 8, dotPaint);

    // Glow - more intense
    final glowPaint = Paint()
      ..color = const Color(0xFFF4436C).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pingCenter, 15, glowPaint);
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.radarProgress != radarProgress ||
        oldDelegate.pingProgress != pingProgress ||
        oldDelegate.pingDistance != pingDistance;
  }
}
