import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme.dart';
import '../../../core/translations.dart';
import '../../auth/data/auth_repository.dart';
import '../../safety/screen_protection_service.dart';

// (Countdown is managed as local state in _EventRecapScreenState — simpler
//  and avoids provider initialisation ordering issues.)

// ── Screen ───────────────────────────────────────────────────────────────────

class EventRecapScreen extends ConsumerStatefulWidget {
  final String eventName;
  final String eventId;

  /// Seconds remaining in the last-pulse window. Null for Free users or when
  /// the window has already expired.
  final int? pulseSecondsRemaining;

  const EventRecapScreen({
    super.key,
    required this.eventName,
    required this.eventId,
    this.pulseSecondsRemaining,
  });

  @override
  ConsumerState<EventRecapScreen> createState() => _EventRecapScreenState();
}

class _EventRecapScreenState extends ConsumerState<EventRecapScreen> {
  late int _countdown;
  Timer? _timer;
  // User safety — ne GDPR. Screenshot protection prevents profile redistribution.
  bool _isRecording = false;
  late final void Function(bool) _recordingListener;

  @override
  void initState() {
    super.initState();
    _recordingListener = (isRecording) {
      if (mounted) setState(() => _isRecording = isRecording);
    };
    ScreenProtectionService.enable();
    ScreenProtectionService.addRecordingListener(_recordingListener);
    // Default to 10 min if caller does not provide remaining seconds.
    _countdown = widget.pulseSecondsRemaining ?? 600;
    if (_countdown > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          if (_countdown > 0) _countdown--;
        });
        if (_countdown == 0) _timer?.cancel();
      });
    }
  }

  @override
  void dispose() {
    ScreenProtectionService.removeRecordingListener();
    ScreenProtectionService.disable();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isRecording) return const RecordingShield();

    final user = ref.watch(authStateProvider);
    final lang = user?.appLanguage ?? 'sl';
    final effectivePremium = ref.watch(effectiveIsPremiumProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countdown = _countdown;

    final textPrimary = isDark ? Colors.white : TrembleTheme.textColor;
    final surfaceBg =
        isDark ? const Color(0xFF1A1A18) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: surfaceBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(
                      LucideIcons.arrowLeft,
                      size: 22,
                      color: textPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    t('event_recap', lang).toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      color: TrembleTheme.rose,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.eventName,
                    style: TrembleTheme.displayFont(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t('you_were_here', lang),
                    style: TrembleTheme.uiFont(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: textPrimary.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Pro TTL countdown (Pro only) ─────────────────────────────
            if (effectivePremium && countdown > 0)
              _PulseCountdownBanner(
                secondsLeft: countdown,
                isDark: isDark,
                lang: lang,
              ),

            // ── Free upgrade nudge ───────────────────────────────────────
            if (!effectivePremium)
              _FreeUpgradeBanner(isDark: isDark, lang: lang),

            const SizedBox(height: 16),

            // ── Profile grid ─────────────────────────────────────────────
            Expanded(
              child: SizedBox.expand(
                child: Center(
                  child: Text(
                    'Ni srečanj za ta event.',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 15,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _PulseCountdownBanner extends StatelessWidget {
  final int secondsLeft;
  final bool isDark;
  final String lang;

  const _PulseCountdownBanner({
    required this.secondsLeft,
    required this.isDark,
    required this.lang,
  });

  String _format(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF4436C), Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t('pulse_expires_in', lang)
                  .replaceAll('{time}', _format(secondsLeft)),
              style: TrembleTheme.uiFont(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeUpgradeBanner extends StatelessWidget {
  final bool isDark;
  final String lang;

  const _FreeUpgradeBanner({required this.isDark, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TrembleTheme.accentYellow.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: TrembleTheme.accentYellow.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: TrembleTheme.accentYellow, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t('event_recap_free_hint', lang),
              style: TrembleTheme.uiFont(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: TrembleTheme.accentYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
