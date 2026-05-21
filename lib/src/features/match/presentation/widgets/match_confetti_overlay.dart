import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MatchConfettiOverlay
//
// Full-screen confetti burst + "It's a match!" text.
// Insert as an OverlayEntry; call onDone to remove it when complete.
// ─────────────────────────────────────────────────────────────────────────────

class MatchConfettiOverlay extends StatefulWidget {
  final VoidCallback onDone;

  const MatchConfettiOverlay({super.key, required this.onDone});

  @override
  State<MatchConfettiOverlay> createState() => _MatchConfettiOverlayState();
}

class _MatchConfettiOverlayState extends State<MatchConfettiOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _confettiCtrl;
  late final AnimationController _textCtrl;
  late final List<_Particle>     _particles;

  static const _colors = [
    Color(0xFFFF004D), Color(0xFFFF7700), Color(0xFFFFE600),
    Color(0xFF00E676), Color(0xFF2979FF), Color(0xFFD500F9),
    Color(0xFFF4436C), Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();

    final rng = math.Random();
    _particles = List.generate(90, (_) => _Particle(
      x:        rng.nextDouble(),
      startY:   -(rng.nextDouble() * 0.12),
      speed:    0.5 + rng.nextDouble() * 0.9,
      drift:    (rng.nextDouble() - 0.5) * 0.18,
      color:    _colors[rng.nextInt(_colors.length)],
      size:     4.0 + rng.nextDouble() * 7.0,
      rotation: rng.nextDouble() * math.pi * 2,
      rotSpeed: (rng.nextDouble() - 0.5) * 10,
      isCircle: rng.nextBool(),
    ));

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) widget.onDone();
      });

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    HapticFeedback.heavyImpact();
    _confettiCtrl.forward();

    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _textCtrl.forward();
    });
    // Second haptic pulse to feel more celebratory
    Future.delayed(const Duration(milliseconds: 300), () {
      HapticFeedback.heavyImpact();
    });
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([_confettiCtrl, _textCtrl]),
      builder: (ctx, _) {
        // Text fades in quickly, then fades out in the last 30% of the animation.
        final fadeIn  = _textCtrl.value;
        final fadeOut = 1.0 - ((_confettiCtrl.value - 0.70).clamp(0.0, 0.30) / 0.30);
        final textOpacity = (fadeIn * fadeOut).clamp(0.0, 1.0);

        return IgnorePointer(
          child: Stack(
            children: [
              // ── Confetti particles ──────────────────────────────────
              CustomPaint(
                size: screenSize,
                painter: _ConfettiPainter(
                  particles:  _particles,
                  progress:   _confettiCtrl.value,
                  screenSize: screenSize,
                ),
              ),

              // ── "It's a match!" label ───────────────────────────────
              Positioned(
                top:   screenSize.height * 0.26,
                left:  0,
                right: 0,
                child: Opacity(
                  opacity: textOpacity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "It's a match!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize:   38,
                          fontWeight: FontWeight.w700,
                          color:      Colors.white,
                          shadows: const [
                            Shadow(
                              color:      Color(0x66000000),
                              blurRadius: 16,
                              offset:     Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('🎉', style: TextStyle(fontSize: 34)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Particle data
// ─────────────────────────────────────────────────────────────────────────────

class _Particle {
  final double x;        // 0–1 fraction of screen width
  final double startY;   // negative fraction — above top edge
  final double speed;    // fall-speed multiplier
  final double drift;    // horizontal drift over full animation
  final Color  color;
  final double size;
  final double rotation;
  final double rotSpeed;
  final bool   isCircle;

  const _Particle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.drift,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotSpeed,
    required this.isCircle,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double          progress;
  final Size            screenSize;

  const _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final t       = (progress * p.speed).clamp(0.0, 1.0);
      final easedT  = t * t; // quadratic gravity feel

      final cx = (p.x + p.drift * progress) * size.width;
      final cy = p.startY * size.height + easedT * (size.height + p.size * 3);

      // Fade in near top, fade out near bottom
      final fadeTop    = (cy / (size.height * 0.08)).clamp(0.0, 1.0);
      final fadeBottom = ((size.height - cy) / (size.height * 0.25)).clamp(0.0, 1.0);
      final alpha      = (fadeTop * fadeBottom).clamp(0.0, 1.0);

      if (alpha <= 0.01) continue;

      paint.color = p.color.withValues(alpha: alpha);

      final angle = p.rotation + p.rotSpeed * progress;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width:  p.size,
            height: p.size * 0.45,
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
