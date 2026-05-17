import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

/// Final onboarding splash. Plays while the account loads — no waiting feel.
/// Storyboard (in seconds, total ~10.5s then auto-navigate):
///   0.0–5.0  : pink dot travels bottom→top (left lane), blue dot travels
///              top→bottom (right lane), both with trailing ping rings,
///              radar at center pulsing + sweep arm rotating.
///   5.0–5.7  : both pings freeze near their destinations (88%).
///   5.7–7.2  : both converge to radar center.
///   7.2–7.5  : hard-pulse on collision (haptic).
///   7.5–8.0  : rose-color radial wipe from center filling the screen.
///   8.0–8.8  : logo shifts from screen center to lockup position near top,
///              scaling 52→90.
///   8.8–9.5  : "tremble." wordmark fades in letter-by-letter beside logo.
///   9.8–10.5 : "Welcome [Name]." midline + secondary line fade in.
///  10.5–11.3 : headline + subline fade in below.
///  11.3–13.0 : hold, then auto-navigate to '/'.
class RitualStep extends StatefulWidget {
  const RitualStep({
    super.key,
    required this.tr,
    this.userName,
    this.gender,
  });

  final String Function(String) tr;
  final String? userName;
  final String? gender; // 'male' | 'female' | 'non_binary'

  @override
  State<RitualStep> createState() => _RitualStepState();
}

class _RitualStepState extends State<RitualStep>
    with SingleTickerProviderStateMixin {
  static const _rose = Color(0xFFF4436C);
  static const _blue = Color(0xFF4A8FFF);
  static const _cream = Color(0xFFFAFAF7);
  static const _creamDeep = Color(0xFFF1EFE8);

  // Timeline boundaries (seconds)
  static const double _tTravelEnd = 5.0;
  static const double _tFreezeEnd = 5.7;
  static const double _tConvergeEnd = 7.2;
  static const double _tHardPulseEnd = 7.5;
  static const double _tWipeStart = 7.5;
  static const double _tWipeEnd = 8.0;
  static const double _tLogoStart = 8.0;
  static const double _tLogoEnd = 8.8;
  static const double _tMidStart = 9.8;
  static const double _tMidEnd = 10.5;
  static const double _tTextStart = 10.5;
  static const double _tTextEnd = 11.3;
  static const double _tTotal = 13.0;

  late final AnimationController _master;
  late final DateTime _start;
  Timer? _ticker;
  double _t = 0.0;

  bool _hardPulseFired = false;
  bool _collisionHaptic = false;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 13000),
    );
    _start = DateTime.now();

    // Manual ticker — we drive every frame from elapsed wallclock so
    // ping ring emission stays stable across rebuilds.
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      final elapsed =
          DateTime.now().difference(_start).inMicroseconds / 1000000.0;
      setState(() => _t = elapsed);

      if (!_hardPulseFired && elapsed >= _tConvergeEnd) {
        _hardPulseFired = true;
        HapticFeedback.mediumImpact();
      }
      if (!_collisionHaptic && elapsed >= _tHardPulseEnd) {
        _collisionHaptic = true;
        HapticFeedback.heavyImpact();
      }
      if (elapsed >= _tTotal) {
        _ticker?.cancel();
        if (mounted) context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _master.dispose();
    super.dispose();
  }

  // ── Easing ─────────────────────────────────────────────────────────────────
  double _easeOutCubic(double t) => 1 - pow(1 - t, 3).toDouble();
  double _easeInOutCubic(double t) =>
      t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;
  double _easeOut(double t) => 1 - pow(1 - t, 2).toDouble();
  double _easeInOut(double t) =>
      t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2;

  double _phase(double start, double end, double Function(double) ease) {
    if (_t <= start) return 0.0;
    if (_t >= end) return 1.0;
    return ease((_t - start) / (end - start));
  }

  // ── Gender-aware Welcome word ──────────────────────────────────────────────
  String _welcomeWord() {
    final lang = _detectLang();
    final isFemale = (widget.gender ?? '').toLowerCase() == 'female';
    final isMale = (widget.gender ?? '').toLowerCase() == 'male';

    switch (lang) {
      case 'sl': // Slovenian
        if (isFemale) return 'Dobrodošla';
        if (isMale) return 'Dobrodošel';
        return 'Dobrodošli';
      case 'hr': // Croatian
      case 'sr': // Serbian
      case 'bs': // Bosnian
        if (isFemale) return 'Dobrodošla';
        if (isMale) return 'Dobrodošao';
        return 'Dobrodošli';
      case 'de': // German — no gender variation
        return 'Willkommen';
      case 'fr': // French
        if (isFemale) return 'Bienvenue'; // same form, but italic name carries
        return 'Bienvenue';
      case 'it': // Italian
        if (isFemale) return 'Benvenuta';
        if (isMale) return 'Benvenuto';
        return 'Benvenuti';
      case 'es': // Spanish
        if (isFemale) return 'Bienvenida';
        if (isMale) return 'Bienvenido';
        return 'Bienvenidos';
      case 'pt': // Portuguese
        if (isFemale) return 'Bem-vinda';
        if (isMale) return 'Bem-vindo';
        return 'Bem-vindos';
      case 'hu': // Hungarian — no gender
        return 'Üdvözöllek';
      case 'pl': // Polish
        if (isFemale) return 'Witaj';
        if (isMale) return 'Witaj';
        return 'Witajcie';
      case 'en':
      default:
        return 'Welcome';
    }
  }

  String _detectLang() {
    // Use tr() to fingerprint the language. Cheap and avoids exposing locale.
    final probe = widget.tr('continue_btn');
    switch (probe) {
      case 'Nadaljuj':
        return 'sl';
      case 'Nastavi':
        return 'hr';
      case 'Nastavi.':
      case 'Nastavi ':
        return 'sr';
      case 'Weiter':
        return 'de';
      case 'Continuer':
        return 'fr';
      case 'Continua':
        return 'it';
      case 'Folytatás':
        return 'hu';
      default:
        return 'en';
    }
  }

  // ── Ping path helpers ──────────────────────────────────────────────────────
  Offset _lerpPt(Offset a, Offset b, double f) =>
      Offset(a.dx + (b.dx - a.dx) * f, a.dy + (b.dy - a.dy) * f);

  Offset _pingPath({
    required Offset start,
    required Offset stop,
    required Offset center,
    required double time,
  }) {
    if (time <= 0) return start;
    if (time < _tTravelEnd) {
      final p = _easeOutCubic(time / _tTravelEnd);
      return _lerpPt(start, stop, p);
    } else if (time < _tFreezeEnd) {
      return stop;
    } else if (time < _tConvergeEnd) {
      final p = _easeInOutCubic(
          (time - _tFreezeEnd) / (_tConvergeEnd - _tFreezeEnd));
      return _lerpPt(stop, center, p);
    }
    return center;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final center = Offset(size.width / 2, size.height / 2);

          final wipe = _phase(_tWipeStart, _tWipeEnd, _easeInOut);
          final logoMove = _phase(_tLogoStart, _tLogoEnd, _easeInOutCubic);
          final midIn = _phase(_tMidStart, _tMidEnd, _easeOut);
          final textIn = _phase(_tTextStart, _tTextEnd, _easeOut);

          // Hard pulse bell curve during the alarm window
          final inHardPulse = _t >= _tConvergeEnd && _t < _tHardPulseEnd;
          final hardPulseT = inHardPulse
              ? ((_t - _tConvergeEnd) / (_tHardPulseEnd - _tConvergeEnd))
                  .clamp(0.0, 1.0)
              : 0.0;
          final hardPulseBoost =
              inHardPulse ? sin(hardPulseT * pi).toDouble() : 0.0;
          final radarScanning = _t < _tConvergeEnd;

          // Stage opacity fades out 7.4 → 8.0
          final stageOpacity =
              1.0 - ((_t - 7.4) / 0.6).clamp(0.0, 1.0);

          // Radar geometry
          final radarSize = min(size.width, size.height) * 0.7;
          final scanProgress = (_t % 3.0) / 3.0;
          final sweepAngle = ((_t / 3.2) * 360) % 360;

          // Ping endpoints
          final pinkStart = Offset(size.width * 0.36, size.height * 0.95);
          final pinkEnd = Offset(size.width * 0.36, size.height * 0.06);
          final blueStart = Offset(size.width * 0.64, size.height * 0.06);
          final blueEnd = Offset(size.width * 0.64, size.height * 0.95);
          const traverseStop = 0.88;
          final pinkStop = _lerpPt(pinkStart, pinkEnd, traverseStop);
          final blueStop = _lerpPt(blueStart, blueEnd, traverseStop);

          // Logo lockup position (top of screen, beside wordmark)
          final safeTop = MediaQuery.of(context).padding.top;
          const lockupGap = 18.0;
          const logoEndSize = 90.0;
          const wordmarkEstW = 188.0;
          final lockupW = logoEndSize + lockupGap + wordmarkEstW;
          final logoEndCenterX = (size.width - lockupW) / 2 + logoEndSize / 2;
          final logoEndCenterY = safeTop + 110.0;
          final logoX =
              center.dx + (logoEndCenterX - center.dx) * logoMove;
          final logoY =
              center.dy + (logoEndCenterY - center.dy) * logoMove;
          final logoSize = 52.0 + (logoEndSize - 52.0) * logoMove;

          return Stack(
            children: [
              // ── Stage 1: Radar + traveling pings ───────────────────────
              if (stageOpacity > 0)
                Opacity(
                  opacity: stageOpacity,
                  child: Stack(
                    children: [
                      // Warm-cream vignette
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, -0.1),
                              radius: 1.2,
                              colors: const [_cream, _creamDeep],
                            ),
                          ),
                        ),
                      ),
                      // Radar canvas
                      Positioned(
                        left: center.dx - radarSize / 2,
                        top: center.dy - radarSize / 2,
                        width: radarSize,
                        height: radarSize,
                        child: CustomPaint(
                          painter: _RadarPainter(
                            scanProgress: scanProgress,
                            scanning: radarScanning,
                            hardPulse: hardPulseBoost,
                            sweepAngleDeg: sweepAngle,
                            color: _rose,
                          ),
                        ),
                      ),
                      // Center mark — rose CIRCLE with white heart-radar icon
                      Positioned(
                        left: center.dx - 30,
                        top: center.dy - 30,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _rose,
                            boxShadow: [
                              BoxShadow(
                                color: _rose.withValues(alpha: 0.33),
                                blurRadius: 32,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: CustomPaint(
                            painter: _TrembleMarkPainter(
                              pulseT: (_t / 1.4) % 1.0,
                            ),
                          ),
                        ),
                      ),
                      // Pink ping (bottom→top)
                      _MovingPing(
                        t: _t,
                        pathFn: (time) => _pingPath(
                          start: pinkStart,
                          stop: pinkStop,
                          center: center,
                          time: time,
                        ),
                        color: _rose,
                      ),
                      // Blue ping (top→bottom)
                      _MovingPing(
                        t: _t,
                        pathFn: (time) => _pingPath(
                          start: blueStart,
                          stop: blueStop,
                          center: center,
                          time: time,
                        ),
                        color: _blue,
                      ),
                    ],
                  ),
                ),

              // ── Stage 2: Rose wipe ─────────────────────────────────────
              if (wipe > 0)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WipePainter(
                      center: center,
                      progress: wipe,
                      color: _rose,
                    ),
                  ),
                ),

              // ── Stage 3: Logo (rose container with white mark) ─────────
              if (wipe > 0.7)
                Positioned(
                  left: logoX - logoSize / 2,
                  top: logoY - logoSize / 2,
                  width: logoSize,
                  height: logoSize,
                  child: Opacity(
                    opacity: wipe,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(logoSize * 0.22),
                        color: Colors.black.withValues(alpha: 0.18),
                      ),
                      child: CustomPaint(
                        painter: _TrembleMarkPainter(pulseT: 0, animated: false),
                      ),
                    ),
                  ),
                ),

              // ── Stage 4: "tremble." wordmark ───────────────────────────
              if (logoMove >= 1.0)
                _Wordmark(
                  t: _t,
                  left: logoEndCenterX + logoEndSize / 2 + lockupGap,
                  centerY: logoEndCenterY,
                  start: 8.8,
                ),

              // ── Stage 5a: Welcome [Name] midline ───────────────────────
              if (midIn > 0)
                Positioned(
                  left: 24,
                  right: 24,
                  top: size.height * 0.50,
                  child: FractionalTranslation(
                    translation: Offset(0, -0.5 + (1 - midIn) * 0.08),
                    child: Opacity(
                      opacity: midIn,
                      child: Column(
                        children: [
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w600,
                                height: 1.05,
                                letterSpacing: -0.5,
                              ),
                              children: [
                                TextSpan(text: '${_welcomeWord()} '),
                                TextSpan(
                                  text: (widget.userName?.isNotEmpty == true)
                                      ? widget.userName!
                                      : 'Friend',
                                  style: GoogleFonts.playfairDisplay(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                TextSpan(
                                  text: '.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Text(
                              widget.tr('ritual_midline'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lora(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 17,
                                fontStyle: FontStyle.italic,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Stage 5b: Headline + subline (bottom) ──────────────────
              if (textIn > 0)
                Positioned(
                  left: 32,
                  right: 32,
                  bottom: size.height * 0.18,
                  child: Opacity(
                    opacity: textIn,
                    child: Transform.translate(
                      offset: Offset(0, (1 - textIn) * 12),
                      child: Column(
                        children: [
                          Text(
                            widget.tr('ritual_headline'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 19,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.tr('ritual_subline'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lora(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tremble heart-radar mark — white strokes, drawn directly.
// ─────────────────────────────────────────────────────────────────────────────
class _TrembleMarkPainter extends CustomPainter {
  _TrembleMarkPainter({required this.pulseT, this.animated = true});
  final double pulseT;
  final bool animated;

  double _arcOpacity(double offset) {
    if (!animated) return 1.0;
    final t = (pulseT + offset) % 1.0;
    return 0.35 + 0.65 * max(0.0, sin(t * pi));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Match the SVG transform: translate(75,75) scale(0.82) translate(-3.5,-20)
    // Working in a 150x150 reference, scale to current size.
    final s = (size.width / 150.0) * 0.82;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(s);
    canvas.translate(-3.5, -20.0);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white;

    // Static base curve
    final pBase = Path()
      ..moveTo(-3, 70)
      ..cubicTo(-33, 60, -63, 30, -63, 0)
      ..cubicTo(-63, -35, -33, -50, -3, -20);
    canvas.drawPath(pBase, stroke);

    // Outer arc
    final outer = Path()
      ..moveTo(10, -20)
      ..cubicTo(40, -50, 70, -35, 70, 0)
      ..cubicTo(70, 30, 40, 60, 10, 70);
    canvas.drawPath(outer,
        stroke..color = Colors.white.withValues(alpha: _arcOpacity(0.0)));

    // Mid arc
    final mid = Path()
      ..moveTo(10, 5)
      ..cubicTo(27, -15, 44, -5, 44, 12)
      ..cubicTo(44, 28, 27, 42, 10, 50);
    canvas.drawPath(mid,
        stroke..color = Colors.white.withValues(alpha: _arcOpacity(0.33)));

    // Inner arc
    final inner = Path()
      ..moveTo(10, 21)
      ..cubicTo(14, 11, 24, 14, 24, 20)
      ..cubicTo(24, 26, 14, 31, 10, 36);
    canvas.drawPath(inner,
        stroke..color = Colors.white.withValues(alpha: _arcOpacity(0.66)));

    canvas.restore();
  }

  @override
  bool shouldRepaint(_TrembleMarkPainter old) =>
      old.pulseT != pulseT || old.animated != animated;
}

// ─────────────────────────────────────────────────────────────────────────────
// Radar painter — rings, glow, scanning pulses, hard pulse, sweep arm, crosshair
// ─────────────────────────────────────────────────────────────────────────────
class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.scanProgress,
    required this.scanning,
    required this.hardPulse,
    required this.sweepAngleDeg,
    required this.color,
  });

  final double scanProgress;
  final bool scanning;
  final double hardPulse;
  final double sweepAngleDeg;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide / 2;

    // Soft inner glow
    final glowR = maxR * (0.6 + hardPulse * 0.4);
    final glowAlpha = 0.22 + hardPulse * 0.35;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: glowAlpha),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: glowR));
    canvas.drawCircle(center, glowR, glowPaint);

    // Concentric rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: 0.32);
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxR * (i / 4), ringPaint);
    }

    // Scanning pulses (two staggered)
    if (scanning) {
      for (int i = 0; i < 2; i++) {
        final p = (scanProgress + i * 0.5) % 1.0;
        final r = maxR * p;
        final a = (1 - p) * 0.5;
        final pulse = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = color.withValues(alpha: a);
        canvas.drawCircle(center, r, pulse);
      }
    }

    // Hard pulse
    if (hardPulse > 0) {
      final r = maxR * (0.3 + hardPulse * 0.9);
      final pulse = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 + hardPulse * 3
        ..color = color.withValues(alpha: 0.9 * (1 - hardPulse));
      canvas.drawCircle(center, r, pulse);
    }

    // Crosshair (subtle)
    final cross = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.12);
    canvas.drawLine(Offset(center.dx, center.dy - maxR),
        Offset(center.dx, center.dy + maxR), cross);
    canvas.drawLine(Offset(center.dx - maxR, center.dy),
        Offset(center.dx + maxR, center.dy), cross);

    // Sweep arm + trailing fan
    if (scanning) {
      _drawSweep(canvas, center, maxR);
    }
  }

  void _drawSweep(Canvas canvas, Offset center, double r) {
    // Convert "0deg = north, clockwise" → standard math angle from +x
    final theta = (sweepAngleDeg - 90) * pi / 180.0;
    const fan = 80.0 * pi / 180.0; // 80° trailing fan

    // Trailing fan with sweep gradient
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    final sweepShader = SweepGradient(
      startAngle: theta - fan,
      endAngle: theta,
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.12),
        color.withValues(alpha: 0.33),
        color.withValues(alpha: 0.60),
      ],
      stops: const [0.0, 0.45, 0.85, 1.0],
      transform: GradientRotation(0),
    ).createShader(Rect.fromCircle(center: center, radius: r));
    final fanPaint = Paint()..shader = sweepShader;
    canvas.drawCircle(center, r, fanPaint);
    canvas.restore();

    // Leading line
    final lead = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.35),
          color,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r))
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final endX = center.dx + cos(theta) * r;
    final endY = center.dy + sin(theta) * r;
    canvas.drawLine(center, Offset(endX, endY), lead);

    // Head dot
    final headPaint = Paint()..color = color;
    canvas.drawCircle(Offset(endX, endY), 4, headPaint);
    final headGlow = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(endX, endY), 6, headGlow);
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.scanProgress != scanProgress ||
      old.scanning != scanning ||
      old.hardPulse != hardPulse ||
      old.sweepAngleDeg != sweepAngleDeg;
}

// ─────────────────────────────────────────────────────────────────────────────
// Moving ping — dot + expanding rings emitted at fixed intervals
// ─────────────────────────────────────────────────────────────────────────────
class _MovingPing extends StatelessWidget {
  const _MovingPing({
    required this.t,
    required this.pathFn,
    required this.color,
  });

  final double t;
  final Offset Function(double time) pathFn;
  final Color color;

  static const double emitInterval = 0.32;
  static const double ringLifetime = 1.5;
  static const double dotR = 6.0;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _MovingPingPainter(
        t: t,
        pathFn: pathFn,
        color: color,
      ),
    );
  }
}

class _MovingPingPainter extends CustomPainter {
  _MovingPingPainter({
    required this.t,
    required this.pathFn,
    required this.color,
  });

  final double t;
  final Offset Function(double time) pathFn;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const emitInterval = _MovingPing.emitInterval;
    const ringLifetime = _MovingPing.ringLifetime;
    const dotR = _MovingPing.dotR;

    // Trailing rings
    final firstEmit = max(0.0, t - ringLifetime);
    final startIdx = (firstEmit / emitInterval).ceil();
    final endIdx = (t / emitInterval).floor();
    final ringPaint = Paint()..style = PaintingStyle.stroke;
    for (int i = startIdx; i <= endIdx; i++) {
      final eT = i * emitInterval;
      if (eT < 0) continue;
      final life = t - eT;
      if (life > ringLifetime) continue;
      final pos = pathFn(eT);
      final p = life / ringLifetime;
      final radius = dotR + p * 56;
      final opacity = (1 - p) * 0.7;
      final stroke = 1.6 + (1 - p) * 0.6;
      ringPaint
        ..strokeWidth = stroke
        ..color = color.withValues(alpha: opacity);
      canvas.drawCircle(pos, radius, ringPaint);
    }

    // Current position
    final cur = pathFn(t);

    // Halos
    final halo1 = Paint()..color = color.withValues(alpha: 0.18);
    final halo2 = Paint()..color = color.withValues(alpha: 0.32);
    canvas.drawCircle(cur, dotR * 4.5, halo1);
    canvas.drawCircle(cur, dotR * 2.6, halo2);

    // Core dot
    final core = Paint()..color = color;
    canvas.drawCircle(cur, dotR, core);
    final centerDot = Paint()..color = Colors.white.withValues(alpha: 0.95);
    canvas.drawCircle(cur, dotR * 0.45, centerDot);
  }

  @override
  bool shouldRepaint(_MovingPingPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// Wipe painter — expanding rose circle from center
// ─────────────────────────────────────────────────────────────────────────────
class _WipePainter extends CustomPainter {
  _WipePainter({
    required this.center,
    required this.progress,
    required this.color,
  });

  final Offset center;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    double maxDist = 0;
    for (final c in corners) {
      final d = (c - center).distance;
      if (d > maxDist) maxDist = d;
    }
    final r = maxDist * progress;
    canvas.drawCircle(center, r, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WipePainter old) =>
      old.progress != progress || old.center != center;
}

// ─────────────────────────────────────────────────────────────────────────────
// "tremble." wordmark — letters fade in one at a time
// ─────────────────────────────────────────────────────────────────────────────
class _Wordmark extends StatelessWidget {
  const _Wordmark({
    required this.t,
    required this.left,
    required this.centerY,
    required this.start,
  });

  final double t;
  final double left;
  final double centerY;
  final double start;

  static const String _letters = 'tremble.';
  static const double _stagger = 0.07;
  static const double _fadeDur = 0.30;
  static const Color _rose = Color(0xFFF4436C);

  double _phase(double time, double s, double e) {
    if (time <= s) return 0.0;
    if (time >= e) return 1.0;
    final p = (time - s) / (e - s);
    return 1 - pow(1 - p, 2).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: centerY - 22, // 44px font / 2
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: List.generate(_letters.length, (i) {
          final ch = _letters[i];
          final s = start + i * _stagger;
          final op = _phase(t, s, s + _fadeDur);
          final drop = (1 - op) * 6;
          return Opacity(
            opacity: op,
            child: Transform.translate(
              offset: Offset(0, drop),
              child: Text(
                ch,
                style: GoogleFonts.playfairDisplay(
                  color: ch == '.' ? _rose : Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  height: 1.0,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
