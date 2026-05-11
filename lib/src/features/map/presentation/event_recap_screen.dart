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

/// Mock profile for event recap. Replace with real Firestore data when
/// the backend event-crossing pipeline (F2) is wired.
class _RecapProfile {
  final String id;
  final String name;
  final int age;
  final String photoUrl;

  const _RecapProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.photoUrl,
  });
}

// ── Mock data ────────────────────────────────────────────────────────────────

const List<_RecapProfile> _mockProfiles = [
  _RecapProfile(
    id: 'p1',
    name: 'Maja',
    age: 24,
    photoUrl: '',
  ),
  _RecapProfile(
    id: 'p2',
    name: 'Luka',
    age: 27,
    photoUrl: '',
  ),
  _RecapProfile(
    id: 'p3',
    name: 'Sara',
    age: 22,
    photoUrl: '',
  ),
  _RecapProfile(
    id: 'p4',
    name: 'Blaž',
    age: 29,
    photoUrl: '',
  ),
];

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
  final Set<String> _pulseSent = {};
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
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: _mockProfiles.length,
                itemBuilder: (_, i) => _ProfileCard(
                  profile: _mockProfiles[i],
                  effectivePremium: effectivePremium,
                  pulseSent: _pulseSent.contains(_mockProfiles[i].id),
                  pulseExpired: countdown == 0,
                  isDark: isDark,
                  lang: lang,
                  onPulse: effectivePremium && countdown > 0
                      ? () =>
                          setState(() => _pulseSent.add(_mockProfiles[i].id))
                      : null,
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

class _ProfileCard extends StatelessWidget {
  final _RecapProfile profile;
  final bool effectivePremium;
  final bool pulseSent;
  final bool pulseExpired;
  final bool isDark;
  final String lang;
  final VoidCallback? onPulse;

  const _ProfileCard({
    required this.profile,
    required this.effectivePremium,
    required this.pulseSent,
    required this.pulseExpired,
    required this.isDark,
    required this.lang,
    required this.onPulse,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Photo ──────────────────────────────────────────────────
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: _PhotoSlot(
                effectivePremium: effectivePremium,
                isDark: isDark,
              ),
            ),
          ),

          // ── Name + age ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: effectivePremium
                ? Text(
                    '${profile.name}, ${profile.age}',
                    style: TrembleTheme.uiFont(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : TrembleTheme.textColor,
                    ),
                  )
                : _BlurredName(isDark: isDark),
          ),

          // ── Pulse button ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
            child: _PulseButton(
              effectivePremium: effectivePremium,
              pulseSent: pulseSent,
              pulseExpired: pulseExpired,
              isDark: isDark,
              lang: lang,
              onTap: onPulse,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  final bool effectivePremium;
  final bool isDark;

  const _PhotoSlot({required this.effectivePremium, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Placeholder gradient simulates a profile photo.
    // Replace with CachedNetworkImage when real photos are available.
    final photo = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: effectivePremium
              ? [const Color(0xFFF4436C), const Color(0xFFFF8C42)]
              : [const Color(0xFF888888), const Color(0xFF555555)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.person_rounded, color: Colors.white54, size: 48),
      ),
    );

    if (effectivePremium) return photo;

    // Free tier: desaturate via ColorFilter
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.2126, 0.7152, 0.0722, 0, 0, // R
        0.2126, 0.7152, 0.0722, 0, 0, // G
        0.2126, 0.7152, 0.0722, 0, 0, // B
        0, 0, 0, 1, 0, // A
      ]),
      child: photo,
    );
  }
}

class _BlurredName extends StatelessWidget {
  final bool isDark;
  const _BlurredName({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      width: 80,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _PulseButton extends StatelessWidget {
  final bool effectivePremium;
  final bool pulseSent;
  final bool pulseExpired;
  final bool isDark;
  final String lang;
  final VoidCallback? onTap;

  const _PulseButton({
    required this.effectivePremium,
    required this.pulseSent,
    required this.pulseExpired,
    required this.isDark,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!effectivePremium) {
      // Free: locked button → shows paywall on tap (BLOCKER-003 placeholder)
      return GestureDetector(
        onTap: () {
          // TODO(paywall): wire to RevenueCat paywall when BLOCKER-003 resolves
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded,
                  size: 14, color: isDark ? Colors.white38 : Colors.black38),
              const SizedBox(width: 4),
              Text(
                'Pulse',
                style: TrembleTheme.uiFont(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (pulseSent) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: TrembleTheme.rose.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            t('pulse_sent', lang),
            style: TrembleTheme.uiFont(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: TrembleTheme.rose,
            ),
          ),
        ),
      );
    }

    if (pulseExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            t('pulse_expired', lang),
            style: TrembleTheme.uiFont(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
      );
    }

    // Pro: active send button
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: TrembleTheme.rose,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            t('send_last_pulse', lang),
            style: TrembleTheme.uiFont(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
