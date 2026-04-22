import 'package:flutter/material.dart';

/// Radial ping animation — two concentric fading circles — triggered on page
/// transitions in the registration flow. Fire [startAnimation] from a
/// [GlobalKey<PingOverlayState>] to play a single 450 ms pulse.
class PingOverlay extends StatefulWidget {
  const PingOverlay({super.key});

  @override
  State<PingOverlay> createState() => PingOverlayState();
}

class PingOverlayState extends State<PingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void startAnimation() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          if (_progress.value == 0) return const SizedBox.expand();
          return CustomPaint(
            size: Size.infinite,
            painter: _PingPainter(progress: _progress.value, color: color),
          );
        },
      ),
    );
  }
}

class _PingPainter extends CustomPainter {
  const _PingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.longestSide * 0.6;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Outer ring
    final outerRadius = maxRadius * progress;
    final outerOpacity = (0.2 * (1.0 - progress)).clamp(0.0, 0.2);
    paint.color = color.withValues(alpha: outerOpacity);
    canvas.drawCircle(center, outerRadius, paint);

    // Inner ring — 60 % of outer, starts half-way through animation
    if (progress > 0.3) {
      final innerProgress = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);
      final innerRadius = maxRadius * 0.6 * innerProgress;
      final innerOpacity = (0.2 * (1.0 - innerProgress)).clamp(0.0, 0.2);
      paint.color = color.withValues(alpha: innerOpacity);
      canvas.drawCircle(center, innerRadius, paint);
    }
  }

  @override
  bool shouldRepaint(_PingPainter old) => old.progress != progress;
}
