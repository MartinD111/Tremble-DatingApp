import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../shared/ui/glass_card.dart';

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
  final PillState pillState;
  final VoidCallback onWave;
  final VoidCallback onIgnore;

  const MatchNotificationPill({
    super.key,
    required this.name,
    required this.age,
    required this.imageUrl,
    required this.pillState,
    required this.onWave,
    required this.onIgnore,
  });

  @override
  Widget build(BuildContext context) {
    const primaryRose = Color(0xFFF4436C);
    const warmCream = Color(0xFFFAFAF7);

    return GlassCard(
      borderRadius: 60,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile avatar — common across all states.
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: warmCream.withValues(alpha: 0.25), width: 1.5),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage(imageUrl),
            ),
          ),
          const SizedBox(width: 14),
          // Dynamic label — keyed so AnimatedSwitcher cross-fades on state change.
          // Flexible so long names don't push the action buttons offscreen.
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
          const SizedBox(width: 14),
          _buildActions(primaryRose: primaryRose, warmCream: warmCream),
        ],
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
        return Text(
          '$name, $age',
          key: key,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: GoogleFonts.instrumentSans(
            color: warmCream,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
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
