import 'package:flutter/material.dart';

class SpotlightPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color overlayColor;

  const SpotlightPainter({
    required this.center,
    required this.radius,
    this.overlayColor = const Color(0xCC1A1A18),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final spotlightPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final cutoutPath = Path.combine(
      PathOperation.difference,
      overlayPath,
      spotlightPath,
    );

    canvas.drawPath(cutoutPath, overlayPaint);

    final glowPaint = Paint()
      ..color = const Color(0xFFF4436C).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);

    canvas.drawCircle(center, radius, glowPaint);
  }

  @override
  bool shouldRepaint(covariant SpotlightPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.radius != radius ||
        oldDelegate.overlayColor != overlayColor;
  }
}
