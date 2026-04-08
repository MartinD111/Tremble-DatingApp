import 'package:flutter/material.dart';

class MatchBackgroundAnimation extends StatefulWidget {
  const MatchBackgroundAnimation({super.key});

  @override
  State<MatchBackgroundAnimation> createState() =>
      _MatchBackgroundAnimationState();
}

class _MatchBackgroundAnimationState extends State<MatchBackgroundAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
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
          painter: _PulsePainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double progress;
  _PulsePainter(this.progress);

  static const Color _rose = Color(0xFFF4436C);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.height / 1.5;

    for (int i = 0; i < 3; i++) {
      final currentProgress = (progress + (i * 0.33)) % 1.0;
      final radius = maxRadius * currentProgress;
      paint.color = _rose.withValues(alpha: (1 - currentProgress) * 0.4);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
