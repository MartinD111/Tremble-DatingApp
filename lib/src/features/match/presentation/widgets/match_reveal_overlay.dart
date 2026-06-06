import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MatchRevealOverlay
//
// Full-screen match celebration:
//   rose background → "IT'S A MATCH" fades above →
//   spinning ring with match photo inside → confetti from bottom.
//
// Insert as an OverlayEntry; calls onDone when exit animation completes so
// the caller can remove it. Tap anywhere to early-dismiss.
// ─────────────────────────────────────────────────────────────────────────────

class MatchRevealOverlay extends StatefulWidget {
  final VoidCallback onDone;

  /// URL of the matched person's avatar. Shown inside the spinning ring.
  /// Falls back to a person icon when null or empty.
  final String? matchImageUrl;

  const MatchRevealOverlay({
    super.key,
    required this.onDone,
    this.matchImageUrl,
  });

  @override
  State<MatchRevealOverlay> createState() => _MatchRevealOverlayState();
}

class _MatchRevealOverlayState extends State<MatchRevealOverlay>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────

  late final AnimationController _bgCtrl;
  late final AnimationController _spinCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _confettiCtrl;
  late final AnimationController _exitCtrl;

  // ── Animations ───────────────────────────────────────────────────────────

  late final Animation<double> _bgFade;
  late final Animation<double> _spinAngle;
  late final Animation<double> _ringScale;
  late final Animation<double> _textScale;
  late final Animation<double> _textOpacity;
  late final Animation<double> _exitFade;

  // ── Particles ────────────────────────────────────────────────────────────

  final List<_Particle> _particles = [];
  final _rng = math.Random();

  bool _dismissed = false;

  // ── Ring gradient ────────────────────────────────────────────────────────

  static const _ringColors = [
    TrembleTheme.rose, // rose
    Color(0xFFFF8FAB), // blush
    TrembleTheme.accentYellow, // gold
    Color(0xFFFFE082), // champagne
    Color(0xFFFFB3C6), // petal
    TrembleTheme.rose, // back to rose — seamless
  ];

  // Photo diameter inside the ring (must fit within ring radius − stroke)
  static const double _photoDiameter = 164.0;
  static const double _ringSize = 196.0;

  // ─── Init ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn);

    // Ring spin: 2.5 rotations with strong deceleration
    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _spinAngle = Tween<double>(begin: 0, end: 2.5 * 2 * math.pi)
        .animate(CurvedAnimation(parent: _spinCtrl, curve: Curves.easeOut));

    // Ring scale-pulse when spin settles
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _ringScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.20), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.20, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Text spring-in (above the ring)
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _textScale = Tween<double>(begin: 0.35, end: 1.0)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.elasticOut));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.0, 0.30, curve: Curves.easeIn),
    ));

    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600));

    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _exitFade = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

    _particles.addAll(List.generate(110, (_) => _Particle(_rng)));

    _runSequence();
  }

  Future<void> _runSequence() async {
    _bgCtrl.forward();
    HapticFeedback.heavyImpact();

    await _delay(150);
    if (!mounted) return;
    _spinCtrl.forward();

    await _delay(700); // mid-spin
    if (!mounted) return;
    HapticFeedback.mediumImpact();

    await _delay(700); // spin approaching settle
    if (!mounted) return;
    _pulseCtrl.forward();
    HapticFeedback.heavyImpact();

    await _delay(90);
    if (!mounted) return;
    _textCtrl.forward();

    await _delay(200);
    if (!mounted) return;
    _confettiCtrl.forward();

    await _delay(2200);
    _startExit();
  }

  Future<void> _delay(int ms) => Future.delayed(Duration(milliseconds: ms));

  void _startExit() {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    _exitCtrl.forward().then((_) {
      if (mounted) widget.onDone();
    });
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _bgCtrl.dispose();
    _spinCtrl.dispose();
    _pulseCtrl.dispose();
    _textCtrl.dispose();
    _confettiCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _startExit,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _bgCtrl,
          _spinCtrl,
          _pulseCtrl,
          _textCtrl,
          _confettiCtrl,
          _exitCtrl,
        ]),
        builder: (_, __) {
          final exitOpacity = (_exitCtrl.isAnimating || _exitCtrl.isCompleted)
              ? _exitFade.value
              : 1.0;

          return Opacity(
            opacity: exitOpacity.clamp(0.0, 1.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Rose background ─────────────────────────────────────
                _buildBackground(),

                // ── Text above + ring+photo below, vertically centred ───
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMatchText(),
                      const SizedBox(height: 28),
                      _buildRingWithPhoto(),
                    ],
                  ),
                ),

                // ── Confetti on top of everything ───────────────────────
                CustomPaint(
                  size: size,
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _confettiCtrl.value,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Background ───────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return Opacity(
      opacity: _bgFade.value,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.05),
            radius: 1.35,
            colors: [
              Color(0xFF6B0025), // deep rose core
              Color(0xFF2B000F), // dark rose mid
              Color(0xFF0C0008), // near-black edge
            ],
            stops: [0.0, 0.52, 1.0],
          ),
        ),
      ),
    );
  }

  // ─── "IT'S A MATCH" — above the ring ─────────────────────────────────────
  //
  // Transform.scale keeps the widget's layout size constant (Flutter measures
  // the un-scaled box) so the Column stays stable while the text springs in.

  Widget _buildMatchText() {
    return Opacity(
      opacity: _textOpacity.value,
      child: Transform.scale(
        scale: _textScale.value,
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFD0DF), // soft petal
              TrembleTheme.rose, // brand rose
              Color(0xFFFFD700), // gold shimmer
            ],
            stops: [0.0, 0.55, 1.0],
          ).createShader(bounds),
          child: Text(
            "IT'S A MATCH",
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: Colors.white, // overridden by ShaderMask
              letterSpacing: 3.0,
              height: 1.1,
              shadows: const [
                Shadow(color: Color(0xCCF4436C), blurRadius: 40),
                Shadow(color: Color(0x88FF8FAB), blurRadius: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Spinning ring with match photo inside ────────────────────────────────

  Widget _buildRingWithPhoto() {
    // Reserve fixed space so the Column layout doesn't jump before spin starts.
    if (_spinCtrl.value < 0.01 && !_spinCtrl.isCompleted) {
      return const SizedBox(width: _ringSize, height: _ringSize);
    }

    final scale = (_pulseCtrl.isAnimating || _pulseCtrl.isCompleted)
        ? _ringScale.value
        : 1.0;

    final hasPhoto =
        widget.matchImageUrl != null && widget.matchImageUrl!.isNotEmpty;

    return Transform.scale(
      scale: scale,
      child: SizedBox(
        width: _ringSize,
        height: _ringSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Match photo (static — doesn't spin) ──────────────────
            Container(
              width: _photoDiameter,
              height: _photoDiameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3A0015),
                border: Border.all(
                  color: TrembleTheme.rose.withValues(alpha: 0.35),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: hasPhoto
                    ? Image.network(
                        widget.matchImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPhotoFallback(),
                      )
                    : _buildPhotoFallback(),
              ),
            ),

            // ── Rotating gradient ring (drawn on top of photo) ───────
            Transform.rotate(
              angle: _spinAngle.value,
              child: CustomPaint(
                size: const Size(_ringSize, _ringSize),
                painter: _RingPainter(
                  progress: _spinCtrl.value,
                  colors: _ringColors,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoFallback() {
    return const ColoredBox(
      color: Color(0xFF3A0015),
      child: Center(
        child: Icon(Icons.person_rounded, color: TrembleTheme.rose, size: 64),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ring painter — gradient sweep arc with glow + sparkle dots
// ─────────────────────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;

  const _RingPainter({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Outer glow
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..color =
          TrembleTheme.rose.withValues(alpha: 0.14 * progress.clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, radius, glowPaint);

    // Gradient arc — grows from 0 → full circle at the start of the spin
    final sweepAngle =
        (math.pi * 2 * math.min(1.0, progress * 3.0)).clamp(0.001, math.pi * 2);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + math.pi * 2,
        colors: colors,
      ).createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, arcPaint);

    // Sparkle dots at 8 evenly spaced positions
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color =
          Colors.white.withValues(alpha: (0.88 * progress).clamp(0.0, 0.88));

    for (int i = 0; i < 8; i++) {
      final fraction = i / 8.0;
      if (fraction * math.pi * 2 > sweepAngle) break;
      final angle = -math.pi / 2 + fraction * math.pi * 2;
      canvas.drawCircle(
        Offset(center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle)),
        2.6,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Confetti particles — shoot upward from the bottom
// ─────────────────────────────────────────────────────────────────────────────

class _Particle {
  final double startX;
  final double vx;
  final double vy;
  final double gravity;
  final double delay;
  final Color color;
  final double size;
  final double rotation;
  final double rotSpeed;
  final bool isCircle;

  _Particle(math.Random rng)
      : startX = rng.nextDouble(),
        vx = (rng.nextDouble() - 0.5) * 0.55,
        vy = 0.90 + rng.nextDouble() * 1.30,
        gravity = 0.55 + rng.nextDouble() * 0.90,
        delay = rng.nextDouble() * 0.22,
        color = _colors[rng.nextInt(_colors.length)],
        size = 5.0 + rng.nextDouble() * 9.0,
        rotation = rng.nextDouble() * math.pi * 2,
        rotSpeed = (rng.nextDouble() - 0.5) * 10,
        isCircle = rng.nextBool();

  static const _colors = [
    TrembleTheme.rose,
    Color(0xFFFF8FAB),
    TrembleTheme.accentYellow,
    Color(0xFFFFE082),
    Color(0xFFFFFFFF),
    Color(0xFFFF6B9D),
    Color(0xFFFFD700),
    Color(0xFFFFB3C6),
  ];
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  const _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final t = (progress - p.delay).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final dx = p.startX + p.vx * t;
      final dy = 1.0 - (p.vy * t - 0.5 * p.gravity * t * t);

      final cx = dx * size.width;
      final cy = dy * size.height;

      if (cy > size.height + p.size || cy < -p.size * 2) continue;

      final fadeIn = (t / 0.08).clamp(0.0, 1.0);
      final fadeOut = progress < 0.85
          ? 1.0
          : (1.0 - (progress - 0.85) / 0.15).clamp(0.0, 1.0);
      final alpha = (fadeIn * fadeOut).clamp(0.0, 1.0);
      if (alpha <= 0.01) continue;

      paint.color = p.color.withValues(alpha: alpha);

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(p.rotation + p.rotSpeed * t);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.44,
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
