import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/icon_utils.dart';

// ─── Public API ───────────────────────────────────────────────────────────────

enum PillState {
  waitingForAction, // "Ana, 23, is nearby"
  waveSent, // legacy — handled internally
  waveReceived, // "Ana, 23, sent you a wave!"
}

// ─── Internal stage machine ───────────────────────────────────────────────────

enum _Stage {
  entering, // avatar circle drops in
  expanding, // circle widens to full pill
  idle, // interactive
  shaking, // decaying oscillation
  success, // confirmation + rainbow
  dismissing, // leaving screen
}

// ─── Widget ───────────────────────────────────────────────────────────────────

/// Foreground proximity / wave notification pill.
/// All animation stages are self-contained.  [onIgnore] fires exactly once
/// after the dismiss animation completes — use it to remove the pill from the
/// widget tree or OverlayEntry.
class MatchNotificationPill extends StatefulWidget {
  final String name;
  final int age;
  final String imageUrl;
  final DateTime? birthDate;
  final PillState pillState;

  /// 'male' | 'female' — drives accent + background tint.
  /// Null → female/rose (Tremble default).
  final String? gender;

  final FutureOr<void> Function() onWave;

  /// Called ONCE after dismiss animation ends.
  final VoidCallback onIgnore;

  /// Called when the wave is confirmed and the success state begins.
  /// Use this to trigger a match confetti overlay.
  final VoidCallback? onMatch;

  /// Tap on avatar / label — open profile or paywall.
  final VoidCallback? onTap;

  /// Show a "Swipe away to ignore" hint below the pill.
  final bool showSwipeHint;

  const MatchNotificationPill({
    super.key,
    required this.name,
    required this.age,
    required this.imageUrl,
    this.birthDate,
    required this.pillState,
    this.gender,
    required this.onWave,
    required this.onIgnore,
    this.onMatch,
    this.onTap,
    this.showSwipeHint = false,
  });

  @override
  State<MatchNotificationPill> createState() => _MatchNotificationPillState();
}

class _MatchNotificationPillState extends State<MatchNotificationPill>
    with TickerProviderStateMixin {
  // ── Dimensions ───────────────────────────────────────────────────────────
  static const _pillH = 72.0;
  static const _circleW = 72.0;
  static const _circleBR = 36.0;
  static const _idleBR = 36.0; // height/2 → perfect pill
  static const _successW = 248.0;
  static const _avatarD = 54.0;

  // ── Rainbow colours ───────────────────────────────────────────────────────
  static const _rainbow = [
    Color(0xFFFF004D),
    Color(0xFFFF7700),
    Color(0xFFFFE600),
    Color(0xFF00E676),
    Color(0xFF2979FF),
    Color(0xFFD500F9),
    Color(0xFFFF004D),
  ];

  // ── Layout state ─────────────────────────────────────────────────────────
  _Stage _stage = _Stage.entering;
  double _pillW = _circleW;
  double _pillBR = _circleBR;
  double _fullWidth = 380.0;

  // ── Swipe state ───────────────────────────────────────────────────────────
  double _swipeDx = 0.0;
  bool _swipeCommitted = false;
  String? _waveErrorText;

  // ── Controllers ───────────────────────────────────────────────────────────
  late final AnimationController _dropCtrl;
  late final Animation<double> _dropY;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeX;

  late final AnimationController _rainbowCtrl;

  late final AnimationController _dismissCtrl;
  late final Animation<double> _dismissY;

  late final AnimationController _swipeCtrl;
  late Animation<double> _swipeSlide;
  late final Animation<double> _swipeFade;

  @override
  void initState() {
    super.initState();

    _dropCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _dropY = Tween<double>(begin: -(_pillH + 100), end: 0.0).animate(
      CurvedAnimation(parent: _dropCtrl, curve: Curves.easeOutQuart),
    );
    _dropCtrl.addStatusListener(_onDropStatus);

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _shakeX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 14.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 14.0, end: -11.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -11.0, end: 9.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 9.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 3.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 3.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.linear));

    _rainbowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _dismissCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _dismissY = Tween<double>(begin: 0.0, end: -(_pillH + 140.0)).animate(
      CurvedAnimation(parent: _dismissCtrl, curve: Curves.easeInCubic),
    );
    _dismissCtrl.addStatusListener(_onDismissStatus);

    _swipeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _swipeSlide = Tween<double>(begin: 0, end: 0).animate(_swipeCtrl);
    _swipeFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _swipeCtrl, curve: Curves.easeInQuart),
    );
    _swipeCtrl.addStatusListener(_onSwipeOutStatus);

    _dropCtrl.forward();

    // Vibrate on arrival — medium pulse so the user notices without it being harsh.
    HapticFeedback.mediumImpact();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void didUpdateWidget(MatchNotificationPill old) {
    super.didUpdateWidget(old);
    final becameWaveReceived = old.pillState != PillState.waveReceived &&
        widget.pillState == PillState.waveReceived;
    if (becameWaveReceived &&
        (_stage == _Stage.idle || _stage == _Stage.expanding)) {
      _triggerWaveReceivedEntry();
    }
  }

  // ── Status listeners ──────────────────────────────────────────────────────

  void _onDropStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed || !mounted) return;
    setState(() {
      _stage = _Stage.expanding;
      _pillW = _fullWidth;
      _pillBR = _idleBR;
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || _stage != _Stage.expanding) return;
      setState(() => _stage = _Stage.idle);
      if (widget.pillState == PillState.waveReceived) {
        _triggerWaveReceivedEntry();
      }
    });
  }

  void _onDismissStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed || !mounted) return;
    widget.onIgnore();
  }

  void _onSwipeOutStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed || !mounted) return;
    widget.onIgnore();
  }

  // ── Interactions ──────────────────────────────────────────────────────────

  /// Transition into waveReceived: vibrate, start rainbow, then shake.
  Future<void> _triggerWaveReceivedEntry() async {
    if (_stage != _Stage.idle) return;
    HapticFeedback.heavyImpact();
    if (!_rainbowCtrl.isAnimating) _rainbowCtrl.repeat();
    setState(() => _stage = _Stage.shaking);
    _shakeCtrl.reset();
    await _shakeCtrl.forward();
    if (!mounted) return;
    setState(() => _stage = _Stage.idle);
    // Rainbow continues while user decides.
  }

  Future<void> _handleWave() async {
    if (_stage != _Stage.idle) return;
    HapticFeedback.lightImpact();

    // Capture callbacks before the async gap — the parent widget may unmount
    // this pill (e.g. DevSim flips hasPillVisible→false on the same frame as
    // onWave()), so widget.onMatch would never be reached past `if (!mounted)`.
    final capturedOnWave = widget.onWave;
    final capturedOnMatch = widget.onMatch;

    setState(() => _waveErrorText = null);

    try {
      await Future<void>.sync(capturedOnWave);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.idle;
        _waveErrorText = 'Ni uspelo. Poskusi znova.';
      });
      return;
    }

    setState(() => _stage = _Stage.shaking);
    _shakeCtrl.reset();
    await _shakeCtrl.forward();

    // Fire onMatch regardless of mount state — it's a side-effect on the
    // overlay layer and must run even if the pill itself was removed.
    HapticFeedback.heavyImpact();
    capturedOnMatch?.call();

    if (!mounted) return;
    if (!_rainbowCtrl.isAnimating) _rainbowCtrl.repeat();
    setState(() {
      _stage = _Stage.success;
      _pillW = _successW;
    });

    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    _beginVerticalDismiss();
  }

  void _beginVerticalDismiss() {
    if (_stage == _Stage.dismissing) return;
    setState(() => _stage = _Stage.dismissing);
    _rainbowCtrl.stop();
    _dismissCtrl.forward();
  }

  // ── Swipe ─────────────────────────────────────────────────────────────────

  void _onDragUpdate(DragUpdateDetails d) {
    if (_swipeCommitted ||
        _stage == _Stage.dismissing ||
        _stage == _Stage.entering) return;
    setState(() => _swipeDx += d.delta.dx);
  }

  void _onDragEnd(DragEndDetails d) {
    if (_swipeCommitted || _stage == _Stage.dismissing) return;
    final velocity = d.primaryVelocity ?? 0;
    final threshold = _fullWidth * 0.30;
    if (_swipeDx.abs() > threshold || velocity.abs() > 500) {
      _commitSwipeDismiss(_swipeDx >= 0 ? 1.0 : -1.0);
    } else {
      setState(() => _swipeDx = 0.0);
    }
  }

  void _onDragCancel() {
    if (!_swipeCommitted) setState(() => _swipeDx = 0.0);
  }

  void _commitSwipeDismiss(double direction) {
    if (_stage == _Stage.dismissing) return;
    HapticFeedback.lightImpact();
    setState(() {
      _stage = _Stage.dismissing;
      _swipeCommitted = true;
    });
    _rainbowCtrl.stop();
    _swipeSlide = Tween<double>(
      begin: _swipeDx,
      end: direction * (_fullWidth + 320),
    ).animate(CurvedAnimation(parent: _swipeCtrl, curve: Curves.easeInCubic));
    _swipeCtrl.forward();
  }

  @override
  void dispose() {
    _dropCtrl.dispose();
    _shakeCtrl.dispose();
    _rainbowCtrl.dispose();
    _dismissCtrl.dispose();
    _swipeCtrl.dispose();
    super.dispose();
  }

  // ── Derived ───────────────────────────────────────────────────────────────

  bool get _isWaveBack => widget.pillState == PillState.waveReceived;
  bool get _isSuccess => _stage == _Stage.success;
  bool get _showRainbow =>
      _rainbowCtrl.isAnimating &&
      _stage != _Stage.entering &&
      _stage != _Stage.expanding;

  String get _titleText {
    if (_isSuccess)
      return _isWaveBack ? 'Waved back! \u{1F44B}' : 'Wave sent! \u{1F44B}';
    return '${widget.name}, ${widget.age}';
  }

  String? get _subtitleText {
    if (_isSuccess) return null;
    return _isWaveBack ? 'sent you a wave' : 'is nearby';
  }

  // ── Theme helpers (gender + dark/light aware) ─────────────────────────────

  bool get _isMale => widget.gender?.toLowerCase() == 'male';

  /// Accent: rose (female/default) or sky-blue (male).
  Color _accent(bool isDark) => _isMale
      ? (isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0))
      : TrembleTheme.rose;

  /// Background: dark graphite / light rose-tint (female) or blue-tint (male).
  Color _bg(bool isDark) {
    if (isDark) return const Color(0xFF1C1C20);
    return _isMale ? const Color(0xFFF0F5FF) : const Color(0xFFFDF3F4);
  }

  /// Border: subtle tinted line matching the bg.
  Color _borderC(bool isDark) {
    if (isDark) return const Color(0xFF3A3A40);
    return _isMale ? const Color(0xFFBFD0EC) : const Color(0xFFE8C4C8);
  }

  Color _textC(bool isDark) =>
      isDark ? const Color(0xFFFAFAF7) : const Color(0xFF18181C);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _fullWidth = MediaQuery.of(context).size.width - 80.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent(isDark);
    final bg = _bg(isDark);
    final borderC = _borderC(isDark);
    final textC = _textC(isDark);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _dropCtrl,
        _shakeCtrl,
        _rainbowCtrl,
        _dismissCtrl,
        _swipeCtrl,
      ]),
      builder: (ctx, _) {
        final dy = _dropY.value + _dismissY.value;
        final shakeX = _stage == _Stage.shaking ? _shakeX.value : 0.0;
        final swipeX = _swipeCommitted ? _swipeSlide.value : _swipeDx;
        final opacity =
            (_swipeCommitted ? _swipeFade.value : 1.0).clamp(0.0, 1.0);

        final showHint = widget.showSwipeHint &&
            _stage != _Stage.success &&
            _stage != _Stage.dismissing;
        final showError = _waveErrorText != null &&
            _stage != _Stage.success &&
            _stage != _Stage.dismissing;

        return Transform.translate(
          offset: Offset(shakeX + swipeX, dy),
          child: Opacity(
            opacity: opacity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  onHorizontalDragCancel: _onDragCancel,
                  child: _buildShell(
                    isDark: isDark,
                    accent: accent,
                    bg: bg,
                    borderC: borderC,
                    textC: textC,
                  ),
                ),
                if (showError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _waveErrorText!,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TrembleTheme.rose,
                      ),
                    ),
                  ),
                if (showHint)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Swipe away to ignore',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.45),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Shell ─────────────────────────────────────────────────────────────────

  Widget _buildShell({
    required bool isDark,
    required Color accent,
    required Color bg,
    required Color borderC,
    required Color textC,
  }) {
    // CustomPaint draws the border (solid or rainbow) as a foreground layer
    // so it is never clipped by the inner container's Clip.hardEdge.
    return CustomPaint(
      foregroundPainter: _BorderPainter(
        rainbowProgress: _rainbowCtrl.value,
        showRainbow: _showRainbow,
        radius: _pillBR,
        solidColor: borderC,
        rainbowColors: _rainbow,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        width: _pillW,
        height: _pillH,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(_pillBR),
        ),
        child: _buildContentRow(
          accent: accent,
          textC: textC,
        ),
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────

  Widget _buildContentRow({required Color accent, required Color textC}) {
    final labelVisible = _stage != _Stage.entering;
    final showWaveBtn = _stage == _Stage.idle || _stage == _Stage.shaking;

    return AnimatedOpacity(
      opacity: labelVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 220),
      child: SizedBox(
        height: _pillH,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Full-body tap target — first = lowest z-order, reached only
            // when the wave button (last child) is NOT in the hit area ─────
            if (widget.onTap != null)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onTap,
                ),
              ),

            // ── Label — true pill center ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 72),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _LabelText(
                  key: ValueKey(_isSuccess ? 'success' : widget.pillState),
                  title: _titleText,
                  subtitle: _subtitleText,
                  titleColor: textC,
                  subtitleColor: textC.withValues(alpha: 0.55),
                  iconColor: textC.withValues(alpha: 0.32),
                  birthDate: _isSuccess ? null : widget.birthDate,
                ),
              ),
            ),

            // ── Avatar (pinned left) ──────────────────────────────────────
            Positioned(
              left: 10,
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  width: _avatarD,
                  height: _avatarD,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: accent.withValues(alpha: 0.1),
                        child:
                            Icon(Icons.person_rounded, color: accent, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Wave button — only shown when pill is interactive ─────────
            if (showWaveBtn)
              Positioned(
                right: 10,
                child: _CircleBtn(
                  icon: LucideIcons.hand,
                  color: accent,
                  size: 38,
                  iconSize: 19,
                  onTap: _handleWave,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Border painter ───────────────────────────────────────────────────────────

class _BorderPainter extends CustomPainter {
  final double rainbowProgress;
  final bool showRainbow;
  final double radius;
  final Color solidColor;
  final List<Color> rainbowColors;

  const _BorderPainter({
    required this.rainbowProgress,
    required this.showRainbow,
    required this.radius,
    required this.solidColor,
    required this.rainbowColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeW = showRainbow ? 2.5 : 1.2;
    final inset = strokeW / 2;
    final rect = Rect.fromLTWH(
        inset, inset, size.width - strokeW, size.height - strokeW);
    final rrect =
        RRect.fromRectAndRadius(rect, Radius.circular(radius - inset));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    if (showRainbow) {
      paint.shader = SweepGradient(
        transform: GradientRotation(rainbowProgress * math.pi * 2),
        colors: rainbowColors,
      ).createShader(rect);
    } else {
      paint.color = solidColor;
    }

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_BorderPainter old) =>
      old.rainbowProgress != rainbowProgress ||
      old.showRainbow != showRainbow ||
      old.solidColor != solidColor;
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _LabelText extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color titleColor;
  final Color subtitleColor;
  final Color iconColor;
  final DateTime? birthDate;

  const _LabelText({
    super.key,
    required this.title,
    this.subtitle,
    required this.titleColor,
    required this.subtitleColor,
    required this.iconColor,
    this.birthDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: titleColor,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            if (birthDate != null && subtitle != null) ...[
              const SizedBox(width: 4),
              Icon(
                ZodiacUtils.getZodiacIcon(ZodiacUtils.getZodiacSign(birthDate)),
                size: 13,
                color: iconColor,
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: subtitleColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final VoidCallback onTap;

  const _CircleBtn({
    required this.icon,
    required this.color,
    required this.size,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.38), width: 1.1),
        ),
        child: Icon(icon, size: iconSize, color: color),
      ),
    );
  }
}
