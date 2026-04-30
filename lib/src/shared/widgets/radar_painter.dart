import 'package:flutter/material.dart';
import 'dart:math';

class RadarPainter extends CustomPainter {
  final double radarProgress;
  final double pingProgress;
  final double activationProgress;
  final double? pingDistance;
  final double pingAngle;
  final Color brandColor;
  final Color gridColor;

  final double
      signalPulseProgress; // 0.0→1.0 one-shot expanding ring on run encounter

  RadarPainter({
    required this.radarProgress,
    required this.pingProgress,
    required this.activationProgress,
    this.pingDistance,
    this.pingAngle = 0,
    this.brandColor = const Color(0xFFF4436C),
    this.gridColor = Colors.white,
    this.signalPulseProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.5;

    // Draw concentric circles
    final circlePaint = Paint()
      ..color = gridColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * (i / 4), circlePaint);
    }

    // Draw crosshairs
    final crosshairPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.05)
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
          brandColor.withValues(alpha: 0.3),
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
      ..color = brandColor.withValues(alpha: 0.6)
      ..strokeWidth = 2;
    canvas.drawLine(center, Offset(lineEndX, lineEndY), linePaint);

    // Center dot
    final centerDotPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, centerDotPaint);

    // ── Activation Echo Rings ───────────────────────────────────
    // Expanding rings that radiate from the center when the radar
    // is first activated.
    if (activationProgress > 0 && activationProgress < 1.0) {
      for (int i = 0; i < 3; i++) {
        final ringProgress = (activationProgress - (i * 0.15)).clamp(0.0, 1.0);
        if (ringProgress <= 0) continue;

        final radius = ringProgress * maxRadius * 1.5;
        final opacity = (1.0 - ringProgress).clamp(0.0, 1.0) * 0.5;

        final echoPaint = Paint()
          ..color = brandColor.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawCircle(center, radius, echoPaint);
      }
    }

    // Sonar ping (if active)
    if (pingDistance != null) {
      _drawSonarPing(canvas, center, maxRadius);
    }

    // Run Club signal pulse — single fast-expanding ring, fades in ~500ms
    if (signalPulseProgress > 0 && signalPulseProgress < 1.0) {
      _drawSignalPulse(canvas, center, maxRadius);
    }
  }

  void _drawSignalPulse(Canvas canvas, Offset center, double maxRadius) {
    final radius = signalPulseProgress * maxRadius * 1.2;
    final opacity = (1.0 - signalPulseProgress).clamp(0.0, 1.0) * 0.7;
    final pulsePaint = Paint()
      ..color = brandColor.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, pulsePaint);
  }

  void _drawSonarPing(Canvas canvas, Offset center, double maxRadius) {
    final dist = pingDistance! * maxRadius;
    final pingX = center.dx + dist * cos(pingAngle);
    final pingY = center.dy + dist * sin(pingAngle);
    final pingCenter = Offset(pingX, pingY);

    // Pulsing ring effect
    for (int i = 0; i < 4; i++) {
      final ringProgress = (pingProgress + i * 0.25) % 1.0;
      final ringRadius = 8.0 + ringProgress * 30.0;
      final ringAlpha = (1.0 - ringProgress) * 0.8;
      final ringPaint = Paint()
        ..color = brandColor.withValues(alpha: ringAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(pingCenter, ringRadius, ringPaint);
    }

    // Core dot
    final dotPaint = Paint()
      ..color = brandColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pingCenter, 8, dotPaint);

    // Glow
    final glowPaint = Paint()
      ..color = brandColor.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pingCenter, 15, glowPaint);
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.radarProgress != radarProgress ||
        oldDelegate.pingProgress != pingProgress ||
        oldDelegate.activationProgress != activationProgress ||
        oldDelegate.pingDistance != pingDistance ||
        oldDelegate.pingAngle != pingAngle ||
        oldDelegate.signalPulseProgress != signalPulseProgress;
  }
}
