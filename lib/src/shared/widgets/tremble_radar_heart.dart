import 'dart:math' as math;
import 'package:flutter/material.dart';

class TrembleRadarHeart extends StatefulWidget {
  final bool isScanning;
  final double size;
  final Color color;

  const TrembleRadarHeart({
    super.key,
    required this.isScanning,
    this.size = 80,
    this.color = Colors.white,
  });

  @override
  State<TrembleRadarHeart> createState() => _TrembleRadarHeartState();
}

class _TrembleRadarHeartState extends State<TrembleRadarHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isScanning) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TrembleRadarHeart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        // Animate back to idle state smoothly
        _controller.animateTo(0.0, duration: const Duration(milliseconds: 300));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _RadarHeartPainter(
            animationValue: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _RadarHeartPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _RadarHeartPainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // We draw a liquid heart shape
    final scale = (size.width / 220.0) * 1.25;

    canvas.save();
    canvas.translate(centerX - (3.5 * scale), centerY - (16.0 * scale));
    canvas.scale(scale);

    // Core paint
    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    // Draw paths (Base curve + waves)
    // 1. Static Base Curve
    final pathBase = Path()
      ..moveTo(-4, 70)
      ..cubicTo(-34, 60, -64, 30, -64, 0)
      ..cubicTo(-64, -35, -34, -50, -4, -20);

    // 2. Outer Wave (pulses)
    final pathOuter = Path()
      ..moveTo(12, -20)
      ..cubicTo(42, -50, 72, -35, 72, 0)
      ..cubicTo(72, 30, 42, 60, 12, 70);

    // 3. Mid Wave (pulses)
    final pathMid = Path()
      ..moveTo(12, 5)
      ..cubicTo(29, -15, 46, -5, 46, 12)
      ..cubicTo(46, 28, 29, 42, 12, 50);

    // 4. Inner Wave
    final pathInner = Path()
      ..moveTo(12, 21)
      ..cubicTo(16, 11, 26, 14, 26, 20)
      ..cubicTo(26, 26, 16, 31, 12, 36);

    // Draw glow first — use a smoothed sine curve so the glow never blinks
    // at the animation endpoints (avoids the hard cut when animationValue = 0).
    final glowStrength = (math.sin(animationValue * math.pi)).clamp(0.0, 1.0);
    final smoothGlowPaint = Paint()
      ..color = color.withValues(alpha: 0.6 * glowStrength)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9 + (4 * glowStrength)
      ..strokeCap = StrokeCap.round
      ..maskFilter =
          MaskFilter.blur(BlurStyle.normal, 8.0 * glowStrength + 0.01);

    canvas.drawPath(pathBase, smoothGlowPaint);
    canvas.drawPath(pathOuter, smoothGlowPaint);
    canvas.drawPath(pathMid, smoothGlowPaint);
    canvas.drawPath(pathInner, smoothGlowPaint);

    // Draw core over glow — use separate Paint instances to avoid mutation.
    canvas.drawPath(pathBase, corePaint);

    // Animate outer waves based on animationValue.
    final outerAlpha = 0.4 + (0.6 * animationValue);
    canvas.drawPath(
      pathOuter,
      Paint()
        ..color = color.withValues(alpha: outerAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );

    final midAlpha = 0.6 + (0.4 * animationValue);
    canvas.drawPath(
      pathMid,
      Paint()
        ..color = color.withValues(alpha: midAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );

    final innerAlpha = 0.8 + (0.2 * animationValue);
    canvas.drawPath(
      pathInner,
      Paint()
        ..color = color.withValues(alpha: innerAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RadarHeartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}
