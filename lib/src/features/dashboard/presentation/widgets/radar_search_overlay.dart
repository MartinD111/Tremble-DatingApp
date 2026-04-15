import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:tremble/src/shared/ui/glass_card.dart';
import 'package:tremble/src/features/auth/data/auth_repository.dart';
import 'package:tremble/src/features/match/data/wave_repository.dart';
import 'package:tremble/src/features/match/domain/match.dart' as wave_match;

class RadarSearchOverlay extends ConsumerStatefulWidget {
  final wave_match.Match match;
  final String partnerName;

  const RadarSearchOverlay({
    super.key,
    required this.match,
    required this.partnerName,
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
      setState(() {
        _calculateRemaining();
      });
      if (_remaining.inSeconds <= 0) {
        _timer.cancel();
        // Optionally trigger expiry logic here or let the stream handle it
      }
    });
  }

  void _calculateRemaining() {
    final expiry = widget.match.createdAt.add(const Duration(minutes: 30));
    _remaining = expiry.difference(DateTime.now());
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
    final user = ref.watch(authStateProvider);

    final bool isPremium = user?.isPremium ?? false;
    final lastFound = user?.lastWaveFoundAt;
    final now = DateTime.now();
    final bool isOnCooldown = !isPremium &&
        lastFound != null &&
        now.difference(lastFound).inMinutes < 30;

    final int cooldownMinutesRemaining =
        lastFound != null ? 30 - now.difference(lastFound).inMinutes : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassCard(
            opacity: 0.15,
            borderRadius: 24,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.search, size: 20, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text(
                      'IŠČEM OSEBO', // "Searching for person"
                      style: GoogleFonts.instrumentSans(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.partnerName,
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.clock, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(_remaining),
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: isOnCooldown
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Kot brezplačni uporabnik lahko najdeš le eno osebo vsakih 30 minut. Še $cooldownMinutesRemaining min.'),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                  }
                : () {
                    ref
                        .read(waveRepositoryProvider)
                        .markMatchAsFound(widget.match.id);
                  },
            child: Container(
              height: 64,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOnCooldown
                      ? [Colors.grey.shade700, Colors.grey.shade800]
                      : [
                          colorScheme.primary,
                          colorScheme.secondary,
                        ],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: isOnCooldown
                    ? []
                    : [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isOnCooldown) ...[
                    const Icon(LucideIcons.lock, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    isOnCooldown ? 'ZAKLENJENO ($cooldownMinutesRemaining min)' : 'NAŠLI SMO SE!',
                    style: GoogleFonts.instrumentSans(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isOnCooldown)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Nadgradi v Premium za neomejeno iskanje',
                style: GoogleFonts.instrumentSans(
                  color: colorScheme.primary.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
