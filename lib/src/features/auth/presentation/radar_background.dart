import 'dart:math' as math;
import 'package:flutter/material.dart';

class RadarBackground extends StatefulWidget {
  final Widget child;
  final Color? accentColor;

  const RadarBackground({
    super.key,
    required this.child,
    this.accentColor,
  });

  @override
  State<RadarBackground> createState() => _RadarBackgroundState();
}

class _RadarBackgroundState extends State<RadarBackground>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  final List<PulsingDot> _dots = [];

  @override
  void initState() {
    super.initState();

    // Slow rotation animation for radar circles
    _rotationController = AnimationController(
      duration: const Duration(seconds: 24),
      vsync: this,
    )..repeat();

    // Slow pulse animation for dots
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();

    // Generate random pulsing dots
    _generateDots();
  }

  void _generateDots() {
    final random = math.Random();
    for (int i = 0; i < 12; i++) {
      _dots.add(PulsingDot(
        angle: random.nextDouble() * 2 * math.pi,
        distance: 0.3 + random.nextDouble() * 0.6,
        delay: random.nextDouble(),
      ));
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine base colors from Theme
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryColor = widget.accentColor ?? Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        // Ambient background
        Container(
          color: bgColor,
        ),

        // Animated soft radial pulses
        AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            return CustomPaint(
              painter: RadarPainter(
                rotation: _rotationController.value,
                pulseAnimation: _pulseController,
                dots: _dots,
                accentColor: primaryColor,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Content
        SafeArea(child: widget.child),
      ],
    );
  }
}

class PulsingDot {
  final double angle;
  final double distance;
  final double delay;

  PulsingDot({
    required this.angle,
    required this.distance,
    required this.delay,
  });
}

class RadarPainter extends CustomPainter {
  final double rotation;
  final Animation<double> pulseAnimation;
  final List<PulsingDot> dots;
  final Color? accentColor;

  RadarPainter({
    required this.rotation,
    required this.pulseAnimation,
    required this.dots,
    this.accentColor,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.8;

    final primaryColor = accentColor ?? const Color(0xFFF4436C); // Fallback to rose if null
    final secondaryColor = accentColor != null ? accentColor!.withValues(alpha: 0.5) : const Color(0xFFC2185B);

    // Draw 4 concentric circles with alternating colors
    for (int i = 0; i < 4; i++) {
      final radius = maxRadius * (i + 1) / 4;
      final isPrimary = i % 2 == 0;
      final colorToUse = isPrimary ? primaryColor : secondaryColor;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            colorToUse.withValues(alpha: 0.3),
            colorToUse.withValues(alpha: 0.1),
            colorToUse.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius, paint);

      // Draw circle outline with glassy effect
      final strokePaint = Paint()
        ..color = colorToUse.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4);

      canvas.drawCircle(center, radius, strokePaint);
    }

    // Draw rotating scanning line
    final angle = rotation * 2 * math.pi;
    final lineEnd = Offset(
      center.dx + maxRadius * math.cos(angle),
      center.dy + maxRadius * math.sin(angle),
    );

    final linePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          primaryColor.withValues(alpha: 0.2),
          primaryColor.withValues(alpha: 0.4),
        ],
      ).createShader(Rect.fromPoints(center, lineEnd))
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawLine(center, lineEnd, linePaint);

    // Draw pulsing dots
    for (final dot in dots) {
      final dotAngle = dot.angle;
      final dotDistance = dot.distance * maxRadius;

      // Calculate pulse phase with delay
      final pulsePhase = (pulseAnimation.value + dot.delay) % 1.0;
      final pulseSize = 4 + math.sin(pulsePhase * math.pi) * 4;
      final pulseOpacity = (1 - pulsePhase) * 0.8;

      final dotPosition = Offset(
        center.dx + dotDistance * math.cos(dotAngle),
        center.dy + dotDistance * math.sin(dotAngle),
      );

      // Outer glow
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: pulseOpacity * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(dotPosition, pulseSize * 2, glowPaint);

      // Inner dot
      final dotPaint = Paint()
        ..color = Colors.white.withValues(alpha: pulseOpacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(dotPosition, pulseSize, dotPaint);

      // Dot core
      final corePaint = Paint()
        ..color = primaryColor.withValues(alpha: pulseOpacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(dotPosition, pulseSize * 0.5, corePaint);
    }
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) {
    return rotation != oldDelegate.rotation ||
        accentColor != oldDelegate.accentColor;
  }
}
