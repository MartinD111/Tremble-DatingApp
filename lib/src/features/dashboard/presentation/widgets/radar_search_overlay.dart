import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:tremble/src/features/dashboard/application/radar_search_session.dart';
import 'package:tremble/src/shared/ui/glass_card.dart';

/// Compact bottom-anchored search controller for an active mutual-wave session.
///
/// Layout philosophy: the radar canvas + ping must remain 100% unobstructed.
/// Everything in this widget is laid out as a slim horizontal pill so the user
/// sees the partner ping moving across the radar at all times. The widget is
/// expected to be placed at the bottom of the radar area
/// (Align.bottomCenter or similar in the parent stack).
///
/// Stop action is direct — no confirmation dialog. The mutual-wave window is
/// short (30 min) and the user explicitly tapped Stop; surfacing a modal here
/// would obstruct the radar (the very thing we just optimised to expose).
class RadarSearchOverlay extends ConsumerStatefulWidget {
  final RadarSearchSession session;

  const RadarSearchOverlay({
    super.key,
    required this.session,
  });

  @override
  ConsumerState<RadarSearchOverlay> createState() => _RadarSearchOverlayState();
}

class _RadarSearchOverlayState extends ConsumerState<RadarSearchOverlay> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_calculateRemaining);
      if (_remaining.inSeconds <= 0) _timer.cancel();
    });
  }

  void _calculateRemaining() {
    _remaining = widget.session.expiresAt.difference(DateTime.now());
    if (_remaining.isNegative) _remaining = Duration.zero;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUrgent = _remaining.inMinutes < 5;
    final timerColor = isUrgent ? colorScheme.primary : colorScheme.onSurface;

    final pill = GlassCard(
      opacity: 0.18,
      borderRadius: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live timer
          Icon(LucideIcons.clock, size: 16, color: timerColor),
          const SizedBox(width: 8),
          Text(
            _formatDuration(_remaining),
            style: GoogleFonts.jetBrainsMono(
              color: timerColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 14),
          // Vertical divider
          Container(
            width: 1,
            height: 22,
            color: colorScheme.onSurface.withValues(alpha: 0.18),
          ),
          const SizedBox(width: 14),
          // Compact stop button
          GestureDetector(
            onTap: widget.session.onStop,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.square,
                      size: 14, color: colorScheme.onSurface),
                  const SizedBox(width: 6),
                  Text(
                    'STOP',
                    style: GoogleFonts.instrumentSans(
                      color: colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.session.showMutualFlash)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MutualWaveFlash(primary: colorScheme.primary),
          ),
        isUrgent
            ? pill
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fade(duration: 1200.ms, begin: 0.55, end: 1.0)
            : pill,
      ],
    );

    return content;
  }
}

class _MutualWaveFlash extends StatelessWidget {
  final Color primary;

  const _MutualWaveFlash({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withValues(alpha: 0.95), const Color(0xFFF5C842)],
        ),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.5),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.sparkles, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            'Mutual Wave! Find them.',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    )
        .animate()
        .scale(duration: 350.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 250.ms);
  }
}
