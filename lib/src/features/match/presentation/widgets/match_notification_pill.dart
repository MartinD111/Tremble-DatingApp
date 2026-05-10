import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../shared/ui/glass_card.dart';
import '../../../../core/utils/icon_utils.dart';

// Visual state of the notification pill. Maps 1:1 to DevSimPhase pill-visible
// values (waitingForAction / waveSent / waveReceived).
enum PillState {
  waitingForAction, // "Sarah, 24" + [Wave][Ignore]
  waveSent, // "Wave sent…" pending, no actions
  waveReceived, // "Sarah sent you a wave!" expanded vertically + [Wave Back][Ignore]
}

class MatchNotificationPill extends StatefulWidget {
  final String name;
  final int age;
  final String imageUrl;
  final DateTime? birthDate;
  final PillState pillState;
  final VoidCallback onWave;
  final VoidCallback onIgnore;
  // Tap on the pill body (avatar + label area). Routes to profile/paywall
  // depending on premium state — owned by the parent so this widget stays pure.
  final VoidCallback? onTap;

  const MatchNotificationPill({
    super.key,
    required this.name,
    required this.age,
    required this.imageUrl,
    this.birthDate,
    required this.pillState,
    required this.onWave,
    required this.onIgnore,
    this.onTap,
  });

  @override
  State<MatchNotificationPill> createState() => _MatchNotificationPillState();
}

class _MatchNotificationPillState extends State<MatchNotificationPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _swipeController;
  late Animation<double> _swipeOpacity;
  late Animation<Offset> _swipeSlide;
  bool _isDismissing = false;
  double _swipeDirection = 1.0; // +1 = right, -1 = left

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _swipeOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeInOutCubic),
    );
    _swipeSlide = _buildSwipeSlide();
  }

  Animation<Offset> _buildSwipeSlide() {
    return Tween<Offset>(
      begin: Offset.zero,
      end: Offset(_swipeDirection * 1.5, 0),
    ).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeInCubic),
    );
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  void _onSwipeDismiss({double direction = 1.0}) {
    if (_isDismissing) return;
    _isDismissing = true;
    setState(() {
      _swipeDirection = direction;
      _swipeSlide = _buildSwipeSlide();
    });
    _swipeController.forward().then((_) {
      widget.onIgnore();
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryRose = Color(0xFFF4436C);
    const warmCream = Color(0xFFFAFAF7);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // waveReceived expands vertically — rounder top corners, pill-like bottom.
    final bool isExpanded = widget.pillState == PillState.waveReceived;
    final double radius = isExpanded ? 28 : 60;

    return GestureDetector(
      // Swipe left or right to dismiss (same as tapping Ignore).
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity!.abs() > 200) {
          _onSwipeDismiss(
            direction: (details.primaryVelocity! < 0) ? -1.0 : 1.0,
          );
        }
      },
      child: SlideTransition(
        position: _swipeSlide,
        child: FadeTransition(
          opacity: _swipeOpacity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.fastOutSlowIn,
              child: GlassCard(
                opacity: 0.35,
                borderRadius: radius,
                useGlassEffect: !isDark,
                solidDarkBg: const Color(0xFF2A2A2E),
                padding: EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: isExpanded ? 16 : 12,
                ),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.fastOutSlowIn,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 700),
                    reverseDuration: const Duration(milliseconds: 600),
                    switchInCurve: Curves.fastOutSlowIn,
                    switchOutCurve: Curves.fastOutSlowIn,
                    layoutBuilder:
                        (Widget? currentChild, List<Widget> previousChildren) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.05),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: isExpanded
                        ? _ExpandedLayout(
                            key: const ValueKey('expanded_layout'),
                            name: widget.name,
                            age: widget.age,
                            imageUrl: widget.imageUrl,
                            birthDate: widget.birthDate,
                            onTap: widget.onTap,
                            onWave: widget.onWave,
                            onIgnore: _onSwipeDismiss,
                            warmCream: warmCream,
                            primaryRose: primaryRose,
                          )
                        : _CompactLayout(
                            key: const ValueKey('compact_layout'),
                            name: widget.name,
                            age: widget.age,
                            imageUrl: widget.imageUrl,
                            birthDate: widget.birthDate,
                            pillState: widget.pillState,
                            onTap: widget.onTap,
                            onWave: widget.onWave,
                            onIgnore: _onSwipeDismiss,
                            warmCream: warmCream,
                            primaryRose: primaryRose,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Compact layout: waitingForAction & waveSent ─────────────────────────────
class _CompactLayout extends StatelessWidget {
  final String name;
  final int age;
  final String imageUrl;
  final DateTime? birthDate;
  final PillState pillState;
  final VoidCallback? onTap;
  final VoidCallback onWave;
  final VoidCallback onIgnore;
  final Color warmCream;
  final Color primaryRose;

  const _CompactLayout({
    super.key,
    required this.name,
    required this.age,
    required this.imageUrl,
    required this.birthDate,
    required this.pillState,
    required this.onTap,
    required this.onWave,
    required this.onIgnore,
    required this.warmCream,
    required this.primaryRose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Avatar(imageUrl: imageUrl, warmCream: warmCream),
                const SizedBox(width: 14),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOutQuart,
                    switchOutCurve: Curves.easeInQuart,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.15),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _CompactLabel(
                      key: ValueKey(pillState),
                      pillState: pillState,
                      name: name,
                      age: age,
                      birthDate: birthDate,
                      warmCream: warmCream,
                      primaryRose: primaryRose,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        if (pillState != PillState.waveSent)
          _ActionRow(
            onWave: onWave,
            onIgnore: onIgnore,
            primaryRose: primaryRose,
            warmCream: warmCream,
          ),
      ],
    );
  }
}

// ── Expanded layout: waveReceived ───────────────────────────────────────────
// Avatar + name on top row, action buttons in a second row below.
class _ExpandedLayout extends StatelessWidget {
  final String name;
  final int age;
  final String imageUrl;
  final DateTime? birthDate;
  final VoidCallback? onTap;
  final VoidCallback onWave;
  final VoidCallback onIgnore;
  final Color warmCream;
  final Color primaryRose;

  const _ExpandedLayout({
    super.key,
    required this.name,
    required this.age,
    required this.imageUrl,
    required this.birthDate,
    required this.onTap,
    required this.onWave,
    required this.onIgnore,
    required this.warmCream,
    required this.primaryRose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top row: avatar + "Nika sent you a wave!"
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Row(
            children: [
              _Avatar(imageUrl: imageUrl, warmCream: warmCream),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '$name sent you a wave!',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: GoogleFonts.instrumentSans(
                    color: warmCream,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
                      duration: 2000.ms,
                      begin: 0.6,
                      end: 1.0,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Bottom row: full-width Wave Back + Ignore buttons
        Row(
          children: [
            Expanded(
              child: _FullWidthActionButton(
                icon: LucideIcons.hand,
                label: 'Wave back',
                color: primaryRose,
                onTap: onWave,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FullWidthActionButton(
                icon: LucideIcons.x,
                label: 'Ignore',
                color: warmCream.withValues(alpha: 0.35),
                onTap: onIgnore,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Shared sub-widgets ───────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String imageUrl;
  final Color warmCream;
  const _Avatar({required this.imageUrl, required this.warmCream});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: warmCream.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: CircleAvatar(
        radius: 26,
        backgroundImage: NetworkImage(imageUrl),
      ),
    );
  }
}

class _CompactLabel extends StatelessWidget {
  final PillState pillState;
  final String name;
  final int age;
  final DateTime? birthDate;
  final Color warmCream;
  final Color primaryRose;

  const _CompactLabel({
    super.key,
    required this.pillState,
    required this.name,
    required this.age,
    required this.birthDate,
    required this.warmCream,
    required this.primaryRose,
  });

  @override
  Widget build(BuildContext context) {
    switch (pillState) {
      case PillState.waitingForAction:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$name, $age',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: GoogleFonts.instrumentSans(
                color: warmCream,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            if (birthDate != null) ...[
              const SizedBox(width: 8),
              Icon(
                ZodiacUtils.getZodiacIcon(ZodiacUtils.getZodiacSign(birthDate)),
                size: 16,
                color: warmCream.withValues(alpha: 0.5),
              ),
            ],
          ],
        );
      case PillState.waveSent:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                valueColor: AlwaysStoppedAnimation(primaryRose),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Wave sent…',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: GoogleFonts.instrumentSans(
                  color: warmCream.withValues(alpha: 0.9),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        );
      case PillState.waveReceived:
        // Rendered in _ExpandedLayout, not here.
        return const SizedBox.shrink();
    }
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onWave;
  final VoidCallback onIgnore;
  final Color primaryRose;
  final Color warmCream;

  const _ActionRow({
    required this.onWave,
    required this.onIgnore,
    required this.primaryRose,
    required this.warmCream,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: LucideIcons.hand,
          color: primaryRose,
          onTap: onWave,
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: LucideIcons.x,
          color: warmCream.withValues(alpha: 0.3),
          onTap: onIgnore,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.25),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
        ),
        child: Icon(
          icon,
          size: 22,
          color: color,
        ),
      ),
    );
  }
}

// Full-width pill button used in the expanded waveReceived layout.
class _FullWidthActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FullWidthActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.instrumentSans(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
