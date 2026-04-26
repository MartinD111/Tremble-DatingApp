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
  waveSent,         // "Wave sent…" pending, no actions
  waveReceived,     // "Sarah sent you a wave!" + [Wave Back][Ignore]
}

class MatchNotificationPill extends StatelessWidget {
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
  Widget build(BuildContext context) {
    const primaryRose = Color(0xFFF4436C);
    const warmCream = Color(0xFFFAFAF7);

    // Horizontal margin guarantees breathing room from screen edges on wide
    // devices (e.g. S25 Ultra) and prevents edge-bleed on tablets.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        borderRadius: 60,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          // Grow in height (via text wrap), never overflow horizontally.
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tap target covers avatar + label so the action buttons remain
            // independently tappable. Transparent hit area keeps the visual
            // identical when onTap is null.
            Flexible(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
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
                    ),
                    const SizedBox(width: 14),
                    // Flexible so long names wrap to a second line rather than
                    // pushing the action buttons off-screen.
                    Flexible(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _buildLabel(
                          key: ValueKey(pillState),
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
            _buildActions(primaryRose: primaryRose, warmCream: warmCream),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel({
    required Key key,
    required Color warmCream,
    required Color primaryRose,
  }) {
    switch (pillState) {
      case PillState.waitingForAction:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$name, $age',
              key: key,
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
          key: key,
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
        return Text(
          '$name sent you a wave!',
          key: key,
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
              duration: 1100.ms,
              begin: 0.7,
              end: 1.0,
            );
    }
  }

  Widget _buildActions({
    required Color primaryRose,
    required Color warmCream,
  }) {
    if (pillState == PillState.waveSent) {
      // Pending state — no actions, just whitespace for visual balance.
      return const SizedBox.shrink();
    }
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
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
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
