import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TrembleLogo extends StatelessWidget {
  final double size;

  const TrembleLogo({super.key, this.size = 120.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Icon Backing with 3D Gradients
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.22),
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 0.8,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                  Theme.of(context).colorScheme.primary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),

          // 2. Rim-Light Overlay
          CustomPaint(
            size: Size(size, size),
            painter: _RimLightPainter(size),
          ),

          // 3. Heart-Wifi Icon with Animation
          _AnimatedHeartWifi(size: size * 0.8),
        ],
      ),
    );
  }
}

class _AnimatedHeartWifi extends StatelessWidget {
  final double size;

  const _AnimatedHeartWifi({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HeartWifiPainter(0.06, 0.06, 0.06), // Initial opacity
    ).animate(onPlay: (controller) => controller.repeat()).custom(
          duration: 2800.ms,
          builder: (context, value, child) {
            // We pulse the 3 waves sequentially
            // This is a rough estimation of the liquid pulse keyframes from SVG
            double calcOpacity(double delay, double localValue) {
              double p = (localValue - delay) % 1.0;
              if (p < 0) p += 1.0;
              // Pulse peaks at 0.3, fades out at 0.6
              // Base visibility increased to 0.3 per founder request for "opacity za lines"
              if (p < 0.3) return 0.3 + (p / 0.3) * 0.7;
              if (p < 0.6) return 1.0 - ((p - 0.3) / 0.3) * 0.7;
              return 0.3;
            }

            return CustomPaint(
              size: Size(size, size),
              painter: _HeartWifiPainter(
                calcOpacity(0.0, value), // Inner
                calcOpacity(0.12, value), // Mid
                calcOpacity(0.25, value), // Outer
              ),
            );
          },
        );
  }
}

class _RimLightPainter extends CustomPainter {
  final double size;
  _RimLightPainter(this.size);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final radius = size.width * 0.22;
    // Top-left rim highlight
    final path = Path()
      ..moveTo(size.width * 0.22, 2.5)
      ..lineTo(size.width * 0.78, 2.5)
      ..arcToPoint(Offset(size.width * 0.98, size.width * 0.22),
          radius: Radius.circular(radius));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeartWifiPainter extends CustomPainter {
  final double innerOpacity;
  final double midOpacity;
  final double outerOpacity;

  _HeartWifiPainter(this.innerOpacity, this.midOpacity, this.outerOpacity);

  @override
  void paint(Canvas canvas, Size size) {
    // Scaling and centering parameters match the SVG logic
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // SVG coordinates was basically (110, 110) as center, icon scale 1.12
    // We adjust drawing coordinates to match the paths extracted from the original
    final scale = (size.width / 220.0) * 1.12;

    canvas.save();
    canvas.translate(centerX - (3.5 * scale), centerY - (20.0 * scale));
    canvas.scale(scale);

    final Paint basePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    // 1. Static Base Curve
    final pathBase = Path()
      ..moveTo(-4, 70)
      ..cubicTo(-34, 60, -64, 30, -64, 0)
      ..cubicTo(-64, -35, -34, -50, -4, -20);
    canvas.drawPath(pathBase, basePaint);

    // 2. Animated Outer Wave
    final pathOuter = Path()
      ..moveTo(12, -20)
      ..cubicTo(42, -50, 72, -35, 72, 0)
      ..cubicTo(72, 30, 42, 60, 12, 70);
    canvas.drawPath(pathOuter,
        basePaint..color = Colors.white.withValues(alpha: outerOpacity));

    // 3. Animated Mid Wave
    final pathMid = Path()
      ..moveTo(12, 5)
      ..cubicTo(29, -15, 46, -5, 46, 12)
      ..cubicTo(46, 28, 29, 42, 12, 50);
    canvas.drawPath(
        pathMid, basePaint..color = Colors.white.withValues(alpha: midOpacity));

    // 4. Animated Inner Wave
    // Matches SVG: M 12, 21 C 16, 11 26, 14 26, 20 C 26, 26 16, 31 12, 36
    final pathInner = Path()
      ..moveTo(12, 21)
      ..cubicTo(16, 11, 26, 14, 26, 20)
      ..cubicTo(26, 26, 16, 31, 12, 36);
    canvas.drawPath(pathInner,
        basePaint..color = Colors.white.withValues(alpha: innerOpacity));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HeartWifiPainter oldDelegate) => true;
}
