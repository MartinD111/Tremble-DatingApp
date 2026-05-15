import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/ui/tremble_logo.dart';

class RitualStep extends StatefulWidget {
  const RitualStep({super.key, required this.tr});

  final String Function(String) tr;

  @override
  State<RitualStep> createState() => _RitualStepState();
}

class _RitualStepState extends State<RitualStep>
    with TickerProviderStateMixin {
  // ── Master timeline ─────────────────────────────────────────────────────────
  // 0.0–2.5s  : footsteps walk outward, radar pulses gently
  // 2.5–3.0s  : radar hard-pulse + freeze
  // 3.0–4.5s  : footsteps walk back to center
  // 4.5–5.0s  : color wipe from radar center → full screen
  // 5.0–5.8s  : logo slides from center to top, shrinks
  // 5.8–6.5s  : "Tremble" wordmark fades in
  // 6.5–7.3s  : headline + subline fade in
  // 7.3–9.5s  : hold, then redirect
  late final AnimationController _master;

  static const _rose = Color(0xFFF4436C);
  static const _bg = Color(0xFF1A1A18);

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9500),
    );

    _master.forward();
    _scheduleHaptics();

    Future.delayed(const Duration(milliseconds: 9500), () {
      if (mounted) context.go('/');
    });
  }

  void _scheduleHaptics() async {
    // Radar hard-pulse haptics
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    HapticFeedback.heavyImpact();

    // Collision haptic when footsteps reach center
    await Future.delayed(const Duration(milliseconds: 1640));
    if (!mounted) return;
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _master.dispose();
    super.dispose();
  }

  // Timeline helpers — return progress [0..1] within a window, eased if asked.
  double _phase(double startSec, double endSec, {Curve curve = Curves.linear}) {
    final t = _master.value * 9.5; // total seconds
    if (t <= startSec) return 0.0;
    if (t >= endSec) return 1.0;
    final raw = (t - startSec) / (endSec - startSec);
    return curve.transform(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: _master,
        builder: (context, _) {
          final wipe = _phase(4.5, 5.0, curve: Curves.easeInOut);
          final logoMove = _phase(5.0, 5.8, curve: Curves.easeInOutCubic);
          final wordmark = _phase(5.8, 6.5, curve: Curves.easeOut);
          final textIn = _phase(6.5, 7.3, curve: Curves.easeOut);

          return LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              final center = Offset(size.width / 2, size.height / 2);

              return Stack(
                children: [
                  // ── Stage 1: Radar + footsteps (visible until wipe completes) ─
                  if (wipe < 1.0)
                    Positioned.fill(
                      child: _RadarStage(
                        master: _master,
                        size: size,
                      ),
                    ),

                  // ── Stage 2: Color wipe from radar center ─────────────────
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

                  // ── Stage 3: Logo (transitions from radar center to top) ──
                  if (wipe > 0.7)
                    Builder(builder: (_) {
                      final startY = center.dy;
                      final endY = MediaQuery.of(context).padding.top + 110;
                      final y = startY + (endY - startY) * logoMove;
                      final startSize = 52.0;
                      final endSize = 90.0;
                      final logoSize =
                          startSize + (endSize - startSize) * logoMove;

                      return Positioned(
                        left: center.dx - logoSize / 2,
                        top: y - logoSize / 2,
                        child: Opacity(
                          opacity: wipe,
                          child: TrembleLogo(
                            size: logoSize,
                            isAnimated: false,
                          ),
                        ),
                      );
                    }),

                  // ── Stage 4: "Tremble" wordmark ───────────────────────────
                  if (wordmark > 0)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 175,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: wordmark,
                        child: Transform.translate(
                          offset: Offset(0, (1 - wordmark) * 8),
                          child: Text(
                            'Tremble',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── Stage 5: Headline + subline ───────────────────────────
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
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.tr('ritual_subline'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lora(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  height: 1.6,
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
          );
        },
      ),
    );
  }
}

// ── Radar stage with walking footsteps ────────────────────────────────────────

class _RadarStage extends StatelessWidget {
  const _RadarStage({required this.master, required this.size});

  final AnimationController master;
  final Size size;

  // Phases:
  // walkOut    : 0.0 → 2.5s
  // hardPulse  : 2.5 → 3.0s
  // walkBack   : 3.0 → 4.5s
  double _t() => master.value * 9.5;

  @override
  Widget build(BuildContext context) {
    final t = _t();
    final center = Offset(size.width / 2, size.height / 2);

    // Walk progress
    double walkOut = ((t) / 2.5).clamp(0.0, 1.0);
    walkOut = Curves.easeOutCubic.transform(walkOut);

    final inHardPulse = t >= 2.5 && t < 3.0;
    final hardPulseT = ((t - 2.5) / 0.5).clamp(0.0, 1.0);

    double walkBack = 0.0;
    if (t >= 3.0) {
      walkBack = ((t - 3.0) / 1.5).clamp(0.0, 1.0);
      walkBack = Curves.easeInCubic.transform(walkBack);
    }

    // Footstep paths.
    // Pair A: top-left corner → near bottom-left (walking down-left).
    final aStart = Offset(size.width * 0.15, size.height * 0.10);
    final aEnd = Offset(size.width * 0.10, size.height * 0.78);
    // Pair B: bottom-right corner → near top-right (walking up-right).
    final bStart = Offset(size.width * 0.85, size.height * 0.90);
    final bEnd = Offset(size.width * 0.90, size.height * 0.22);

    // Walk-out reach: stop at 92% so they never quite arrive before reversing.
    final outFactor = walkOut * 0.92;

    // Current foot pair positions on outbound leg (used as start of return path)
    final aOutPos = Offset.lerp(aStart, aEnd, outFactor)!;
    final bOutPos = Offset.lerp(bStart, bEnd, outFactor)!;

    // Return positions: from outbound stop → radar center
    final aPos = Offset.lerp(aOutPos, center, walkBack)!;
    final bPos = Offset.lerp(bOutPos, center, walkBack)!;

    // Radar pulse intensity:
    //   normal scanning before 2.5s,
    //   hard-pulse spike at 2.5–3.0,
    //   frozen after 3.0.
    final radarScanning = t < 3.0;
    final hardPulseBoost = inHardPulse
        ? sin(hardPulseT * pi) * 1.0 // bell curve 0→1→0
        : 0.0;

    // Wipe is starting at 4.5 — we fade out the radar stage smoothly from 4.4–5.0
    final stageOpacity = (1.0 - ((t - 4.4) / 0.6).clamp(0.0, 1.0));

    return Opacity(
      opacity: stageOpacity,
      child: Stack(
        children: [
          // Background tint
          Container(color: const Color(0xFF1A1A18)),

          // Radar
          Center(
            child: SizedBox(
              width: size.shortestSide * 0.7,
              height: size.shortestSide * 0.7,
              child: CustomPaint(
                painter: _RadarPainter(
                  progress: (master.value * 9.5) % 3.0 / 3.0,
                  scanning: radarScanning,
                  hardPulse: hardPulseBoost,
                  color: const Color(0xFFF4436C),
                ),
              ),
            ),
          ),

          // Center logo on radar
          Positioned(
            left: center.dx - 26,
            top: center.dy - 26,
            child: const TrembleLogo(size: 52, isAnimated: true),
          ),

          // Footsteps — Pair A (down-left then back to center)
          ..._buildFootprints(
            outStart: aStart,
            outEnd: aOutPos,
            current: aPos,
            outProgress: walkOut,
            returnProgress: walkBack,
            isReturning: t >= 3.0,
          ),

          // Footsteps — Pair B (up-right then back to center)
          ..._buildFootprints(
            outStart: bStart,
            outEnd: bOutPos,
            current: bPos,
            outProgress: walkOut,
            returnProgress: walkBack,
            isReturning: t >= 3.0,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFootprints({
    required Offset outStart,
    required Offset outEnd,
    required Offset current,
    required double outProgress,
    required double returnProgress,
    required bool isReturning,
  }) {
    const trailCount = 6;
    final widgets = <Widget>[];

    // Outbound trail: persistent footprints fading in along the path
    final outDir = (outEnd - outStart);
    final outAngle = atan2(outDir.dy, outDir.dx);
    for (int i = 0; i < trailCount; i++) {
      final frac = i / (trailCount - 1);
      // Only show this footprint if walkOut has progressed past its position
      final visible = outProgress >= frac * 0.92;
      if (!visible) continue;
      // Fade out the outbound trail during return walk
      final fadeOnReturn = isReturning ? (1.0 - returnProgress) : 1.0;
      final pos = Offset.lerp(outStart, outEnd, frac)!;
      // Stagger left/right
      final side = i.isEven ? -1.0 : 1.0;
      final perp = Offset(-sin(outAngle), cos(outAngle)) * 8.0 * side;
      widgets.add(_buildFoot(
        pos + perp,
        outAngle + pi / 2,
        0.7 * fadeOnReturn,
        isLeft: side < 0,
      ));
    }

    // Return trail: footprints from outbound stop walking toward center
    if (isReturning) {
      final retDir = (current - outEnd);
      final retLen = retDir.distance;
      if (retLen > 1) {
        final retAngle = atan2(retDir.dy, retDir.dx);
        for (int i = 0; i < trailCount; i++) {
          final frac = i / (trailCount - 1);
          if (returnProgress < frac * 0.95) continue;
          final pos = Offset.lerp(outEnd, current, frac)!;
          final side = i.isEven ? -1.0 : 1.0;
          final perp = Offset(-sin(retAngle), cos(retAngle)) * 8.0 * side;
          widgets.add(_buildFoot(
            pos + perp,
            retAngle + pi / 2,
            0.95,
            isLeft: side < 0,
          ));
        }
      }
    }

    return widgets;
  }

  Widget _buildFoot(Offset pos, double rotation, double opacity,
      {required bool isLeft}) {
    return Positioned(
      left: pos.dx - 10,
      top: pos.dy - 14,
      child: Transform.rotate(
        angle: rotation,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: CustomPaint(
            size: const Size(20, 28),
            painter: _FootPainter(isLeft: isLeft),
          ),
        ),
      ),
    );
  }
}

// ── Radar painter ─────────────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.progress,
    required this.scanning,
    required this.hardPulse,
    required this.color,
  });

  final double progress; // 0..1 looping
  final bool scanning;
  final double hardPulse; // 0..1 bell during hard-pulse window
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide / 2;

    // Static concentric rings (frozen state)
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: 0.18);
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxR * (i / 4), ringPaint);
    }

    // Soft inner glow
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.35 + hardPulse * 0.4),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
          center: center, radius: maxR * (0.6 + hardPulse * 0.4)));
    canvas.drawCircle(center, maxR * (0.6 + hardPulse * 0.4), glow);

    // Scanning pulse ring (only when scanning, else frozen)
    if (scanning) {
      // Two staggered pulses for richer feel
      for (int i = 0; i < 2; i++) {
        final p = (progress + i * 0.5) % 1.0;
        final r = maxR * p;
        final alpha = (1.0 - p) * 0.6;
        final pulsePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = color.withValues(alpha: alpha);
        canvas.drawCircle(center, r, pulsePaint);
      }
    }

    // Hard pulse: a fast expanding bright ring during the alarm window
    if (hardPulse > 0) {
      final r = maxR * (0.3 + hardPulse * 0.9);
      final pulsePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 + hardPulse * 3.0
        ..color = color.withValues(alpha: 0.8 * (1 - hardPulse));
      canvas.drawCircle(center, r, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.progress != progress ||
      old.scanning != scanning ||
      old.hardPulse != hardPulse;
}

// ── Footprint painter ─────────────────────────────────────────────────────────

class _FootPainter extends CustomPainter {
  _FootPainter({required this.isLeft});
  final bool isLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);

    if (!isLeft) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    // Sole (oval)
    final sole = Path()
      ..addOval(Rect.fromLTWH(
          size.width * 0.20, size.height * 0.30, size.width * 0.55, size.height * 0.55));
    canvas.drawPath(sole, paint);

    // Heel circle
    canvas.drawCircle(
        Offset(size.width * 0.45, size.height * 0.88), size.width * 0.18, paint);

    // Toes (4 small dots)
    final toePaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (int i = 0; i < 4; i++) {
      final dx = size.width * (0.25 + i * 0.13);
      canvas.drawCircle(Offset(dx, size.height * 0.18), size.width * 0.06, toePaint);
    }
  }

  @override
  bool shouldRepaint(_FootPainter old) => false;
}

// ── Wipe painter ──────────────────────────────────────────────────────────────

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
    // Radius needed to cover the whole screen from center.
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

    final paint = Paint()..color = color;
    canvas.drawCircle(center, r, paint);
  }

  @override
  bool shouldRepaint(_WipePainter old) =>
      old.progress != progress || old.center != center;
}
