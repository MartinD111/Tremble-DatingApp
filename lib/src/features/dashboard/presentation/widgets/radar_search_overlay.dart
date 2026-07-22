import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:tremble/src/features/dashboard/application/precise_finder_controller.dart';
import 'package:tremble/src/features/dashboard/application/warmth_controller.dart';
import 'package:tremble/src/features/dashboard/application/proximity_ping_controller.dart';
import 'package:tremble/src/features/dashboard/domain/warmth_direction.dart';
import 'package:tremble/src/features/dashboard/domain/sonar_ping.dart';
import 'package:tremble/src/features/dashboard/application/radar_search_session.dart';
import 'package:tremble/src/shared/ui/glass_card.dart';
import 'package:tremble/src/features/match/presentation/widgets/pulse_intercept_bar.dart';
import '../../../../core/translations.dart';
import '../../../../core/theme.dart';

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
final currentTimeProvider = Provider<DateTime Function()>(
  (ref) => () => DateTime.now(),
);

class RadarSearchOverlay extends ConsumerStatefulWidget {
  final RadarSearchSession session;

  const RadarSearchOverlay({
    super.key,
    required this.session,
  });

  @override
  ConsumerState<RadarSearchOverlay> createState() => _RadarSearchOverlayState();
}

class _RadarSearchOverlayState extends ConsumerState<RadarSearchOverlay>
    with WidgetsBindingObserver {
  late Timer _timer;
  late Duration _remaining;

  /// True while the backend `markMatchFound` round-trip (via [onStop]) is in
  /// flight — drives the Stop button's spinner and prevents double-taps.
  bool _stopping = false;

  /// Awaits [onStop] with visible progress. On success the match stream removes
  /// this session and disposes the overlay. On failure the button re-enables
  /// and a retry snackbar is shown, so Stop never fails silently.
  Future<void> _handleStop() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    try {
      await widget.session.onStop();
      if (mounted) setState(() => _stopping = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _stopping = false);
      final lang = ref.read(appLanguageProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('try_again', lang))),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_calculateRemaining);
      if (_remaining.inSeconds <= 0) _timer.cancel();
    });
  }

  /// Precise finding is strictly foreground-only (ADR-010): leaving the app
  /// revokes sharing immediately so no coordinate outlives the user's
  /// attention. Re-opting in on return is one tap.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    if (widget.session.matchId == null) return;
    unawaited(ref.read(preciseFinderControllerProvider.notifier).stop());
  }

  void _calculateRemaining() {
    _remaining =
        widget.session.expiresAt.difference(ref.read(currentTimeProvider)());
    if (_remaining.isNegative) _remaining = Duration.zero;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    final isUrgent = _remaining.inMinutes < 5 && _remaining.inSeconds > 0;
    final timerColor = isUrgent ? colorScheme.primary : colorScheme.onSurface;
    final warmth = ref.watch(warmthControllerProvider);
    final sonar = ref.watch(sonarPingControllerProvider);
    final lang = ref.watch(appLanguageProvider);

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
            onTap: _stopping ? null : _handleStop,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _stopping
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onSurface,
                          ),
                        )
                      : Icon(LucideIcons.square,
                          size: 14, color: colorScheme.onSurface),
                  const SizedBox(width: 6),
                  Text(
                    t('stop', lang).toUpperCase(),
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

    final partnerUid = widget.session.partnerUid;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.session.showMutualFlash)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MutualWaveFlash(
              primary: colorScheme.primary,
              lang: lang,
            ),
          ),
        // Pulse Intercept — meetup assistance (Send Phone / Send Photo) shown
        // DURING the trembling window, not on the match reveal. Constrained so
        // the buttons stay compact above the timer and the radar stays visible.
        if (partnerUid != null) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: PulseInterceptBar(targetUid: partnerUid),
          ),
          const SizedBox(height: 10),
        ],
        // Precise turn-to-find (ADR-010) — per-window reciprocal opt-in.
        // Only offered for a real match window; the dev simulation has none.
        if (widget.session.matchId != null)
          _finderSection(widget.session.matchId!, colorScheme, lang),
        // Warmth Indicator (Hot/Cold Navigation) — replaced by a "Searching…"
        // caption when the partner signal is lost (warmer/colder is meaningless
        // with no fresh RSSI). Mirrors the dot fading on the radar.
        if (sonar.signalState == SonarSignalState.searching)
          _searchingIndicator(colorScheme)
        else
          _warmthIndicator(warmth, colorScheme),
        isUrgent
            ? pill
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fade(duration: 1200.ms, begin: 0.55, end: 1.0)
            : pill,
      ],
    );

    return content;
  }

  /// One row per finder state: idle/stopped → opt-in CTA; waiting → partner
  /// microcopy; active → live distance; fallback → honest look-around copy.
  Widget _finderSection(
    String matchId,
    ColorScheme colorScheme,
    String lang,
  ) {
    final finder = ref.watch(preciseFinderControllerProvider);
    final muted = colorScheme.onSurface.withValues(alpha: 0.5);

    Widget caption(String text, {IconData? icon, Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: color ?? muted),
                const SizedBox(width: 6),
              ],
              Text(
                text,
                style: GoogleFonts.instrumentSans(
                  color: color ?? muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        );

    switch (finder.status) {
      case FinderStatus.idle:
      case FinderStatus.stopped:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => unawaited(
              ref
                  .read(preciseFinderControllerProvider.notifier)
                  .optInAndStart(matchId),
            ),
            behavior: HitTestBehavior.opaque,
            child: GlassCard(
              opacity: 0.18,
              borderRadius: 100,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.locateFixed,
                      size: 14, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    t('finder_cta', lang),
                    style: GoogleFonts.instrumentSans(
                      color: colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      case FinderStatus.waiting:
        return caption(
          t('finder_waiting', lang)
              .replaceAll('{name}', widget.session.partnerName),
          icon: LucideIcons.hourglass,
        );
      case FinderStatus.active:
        final distanceM = finder.reading?.distanceM;
        if (distanceM == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.navigation,
                  size: 13, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '${distanceM.round()} m',
                style: GoogleFonts.jetBrainsMono(
                  color: colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        );
      case FinderStatus.fallback:
        return caption(
          t('finder_look_around', lang),
          icon: LucideIcons.eye,
        );
    }
  }

  Widget _searchingIndicator(ColorScheme colorScheme) {
    final lang = ref.watch(appLanguageProvider);
    final color = colorScheme.onSurface.withValues(alpha: 0.5);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.radar, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            t('searching', lang),
            style: GoogleFonts.instrumentSans(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    ).animate(key: const ValueKey('searching')).fadeIn(duration: 300.ms);
  }

  Widget _warmthIndicator(WarmthDirection direction, ColorScheme colorScheme) {
    if (direction == WarmthDirection.neutral) return const SizedBox.shrink();

    final isWarmer = direction == WarmthDirection.warmer;
    final lang = ref.watch(appLanguageProvider);
    final label = isWarmer ? t('getting_closer', lang) : t('moving_away', lang);
    final color = isWarmer
        ? TrembleTheme.rose
        : colorScheme.onSurface.withValues(alpha: 0.5);
    final icon = isWarmer ? LucideIcons.trendingUp : LucideIcons.trendingDown;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.instrumentSans(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    )
        .animate(key: ValueKey(direction))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }
}

class _MutualWaveFlash extends StatelessWidget {
  final Color primary;
  final String lang;

  const _MutualWaveFlash({
    required this.primary,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withValues(alpha: 0.95), TrembleTheme.accentYellow],
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
            t('mutual_wave_find', lang),
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
