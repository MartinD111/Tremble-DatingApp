import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated stick-figure runner shown in the center of the radar when Run Mode
/// is selected (replacing the Tremble logo). Faithful Flutter port of the
/// reference SVG: 28px round-cap limbs, locked elbows, pendulum arm/leg swing,
/// 15° forward lean, and a double-bob bounce — all on the original 0.9s cycle.
///
/// When [isRunning] is false the figure is frozen in a dynamic full-stride run
/// pose (cycle frame 0 — front knee up, arms split, leaning forward). Tapping
/// to start simply unfreezes the same cycle, so the runner elegantly picks up
/// from exactly the pose it was resting in — no pop, no reset jump.
class RunningStickman extends StatefulWidget {
  final bool isRunning;
  final double size;
  final Color color;

  const RunningStickman({
    super.key,
    required this.isRunning,
    this.size = 110,
    this.color = Colors.white,
  });

  @override
  State<RunningStickman> createState() => _RunningStickmanState();
}

class _RunningStickmanState extends State<RunningStickman>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Matches the reference animation cadence (0.9s "slower pace" cycle).
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isRunning) _controller.repeat();
  }

  @override
  void didUpdateWidget(RunningStickman oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _controller.repeat();
      } else {
        _controller.stop();
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
          size: Size.square(widget.size),
          painter: _StickmanPainter(
            // Frozen at cycle frame 0 when idle; the loop continues from this
            // exact pose on start, so the run begins seamlessly.
            t: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _StickmanPainter extends CustomPainter {
  /// Normalized cycle position, 0..1.
  final double t;
  final Color color;

  _StickmanPainter({
    required this.t,
    required this.color,
  });

  // Drawing happens in the original SVG user-space (pivot at 200,200), then a
  // single fit transform maps it into the widget box.
  static const double _nominalExtent = 340.0;

  void _rotateAbout(Canvas canvas, double ox, double oy, double degrees) {
    if (degrees == 0) return;
    canvas
      ..translate(ox, oy)
      ..rotate(degrees * math.pi / 180.0)
      ..translate(-ox, -oy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final limbPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // ── Per-frame limb angles ───────────────────────────────────────────────
    // The run pose is ALWAYS applied — when idle the controller simply rests at
    // frame 0 (a full-stride pose), so starting the loop continues seamlessly.
    //
    // cos(2πt) reproduces the keyframe pendulum (value at t=0/1, mirror at
    // t=0.5) with smooth ease-in-out motion at each turnaround.
    final c = math.cos(2 * math.pi * t);
    final double armF = -60 * c; // 0%/100%: -60° → 50%: +60°
    final double armB = 60 * c; // mirror of front arm
    final double thighF = -15 - 55 * c; // -70° → +40°
    final double thighB = -15 + 55 * c; // +40° → -70°
    final double calfF = 55 - 45 * c; // +10° → +100°
    final double calfB = 55 + 45 * c; // +100° → +10°
    const double forearm = -90; // locked elbow
    const double lean = 15; // forward body lean

    // Bounce: two bobs per cycle, linear (triangle) like the reference.
    final localPhase = (t * 2) % 1.0;
    final tri = 1 - (1 - 2 * localPhase).abs(); // 0→1→0
    final double ty = -12 + 12 * tri; // -12px → 0px → -12px

    // ── Fit transform: center the figure and uniformly scale to the box ──────
    final s = size.width / _nominalExtent;
    canvas.save();
    canvas
      ..translate(size.width / 2, size.height / 2)
      ..scale(s)
      // Anchor on the rendered pose's true bounding-box center. With the 15°
      // lean shifting the head/arms right and the legs spreading, the visible
      // figure spans roughly x[111..306], y[39..279] → center ≈ (208, 159).
      // Centering here keeps the runner balanced in the radar circle.
      ..translate(-208, -159);

    // ── Runner group: bounce (translateY) then 15° lean about pivot 200,200 ──
    canvas.save();
    canvas.translate(0, ty);
    _rotateAbout(canvas, 200, 200, lean);

    // 1. BACK ARM (drawn first → sits behind the torso)
    canvas.save();
    _rotateAbout(canvas, 200, 120, armB);
    canvas.drawLine(const Offset(200, 120), const Offset(200, 170), limbPaint);
    canvas.save();
    _rotateAbout(canvas, 200, 170, forearm);
    canvas.drawLine(const Offset(200, 170), const Offset(200, 220), limbPaint);
    canvas.restore();
    canvas.restore();

    // 2. BACK LEG
    canvas.save();
    _rotateAbout(canvas, 200, 200, thighB);
    canvas.drawLine(const Offset(200, 200), const Offset(200, 260), limbPaint);
    canvas.save();
    _rotateAbout(canvas, 200, 260, calfB);
    canvas.drawLine(const Offset(200, 260), const Offset(200, 320), limbPaint);
    canvas.restore();
    canvas.restore();

    // 3. TORSO / SPINE
    canvas.drawLine(const Offset(200, 120), const Offset(200, 200), limbPaint);

    // 4. HEAD
    canvas.drawCircle(const Offset(200, 75), 28, headPaint);

    // 5. FRONT LEG
    canvas.save();
    _rotateAbout(canvas, 200, 200, thighF);
    canvas.drawLine(const Offset(200, 200), const Offset(200, 260), limbPaint);
    canvas.save();
    _rotateAbout(canvas, 200, 260, calfF);
    canvas.drawLine(const Offset(200, 260), const Offset(200, 320), limbPaint);
    canvas.restore();
    canvas.restore();

    // 6. FRONT ARM (drawn last → sits in front of the torso)
    canvas.save();
    _rotateAbout(canvas, 200, 120, armF);
    canvas.drawLine(const Offset(200, 120), const Offset(200, 170), limbPaint);
    canvas.save();
    _rotateAbout(canvas, 200, 170, forearm);
    canvas.drawLine(const Offset(200, 170), const Offset(200, 220), limbPaint);
    canvas.restore();
    canvas.restore();

    canvas.restore(); // runner group
    canvas.restore(); // fit transform
  }

  @override
  bool shouldRepaint(covariant _StickmanPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.color != color;
  }
}
