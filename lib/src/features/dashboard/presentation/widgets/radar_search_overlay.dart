import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tremble/src/shared/ui/glass_card.dart';
import 'package:tremble/src/features/match/data/wave_repository.dart';
import 'package:tremble/src/features/match/domain/match.dart' as wave_match;
import 'package:tremble/src/features/dashboard/application/proximity_ping_controller.dart';
import 'package:tremble/src/core/translations.dart';

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

class _RadarSearchOverlayState extends ConsumerState<RadarSearchOverlay> with TickerProviderStateMixin {
  late Timer _timer;
  late Duration _remaining;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _calculateRemaining();
        });
      }
      if (_remaining.inSeconds <= 0) {
        _timer.cancel();
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
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showStopSearchDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Končaj iskanje', // "End search"
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Ali sta se uspela najti?', // "Did you manage to find each other?"
          style: GoogleFonts.instrumentSans(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(waveRepositoryProvider).markMatchAsExpired(widget.match.id);
            },
            child: Text(
              'NISMO SE NAŠLI', // "Couldn't find"
              style: GoogleFonts.instrumentSans(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(waveRepositoryProvider).markMatchAsFound(widget.match.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'NAŠLI SMO SE!', // "Found each other"
              style: GoogleFonts.instrumentSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lang = ref.watch(appLanguageProvider);
    
    // Listen to pings for visual feedback
    ref.listen(proximityPingControllerProvider, (_, __) {
      if (mounted && widget.match.isMutual) {
        _pulseController.forward(from: 0);
      }
    });

    final isMutual = widget.match.isMutual;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Visual Pulse Ring (Only if mutual)
              if (isMutual)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 200 + (100 * _pulseController.value),
                      height: 100 + (50 * _pulseController.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.primary.withValues(
                            alpha: (1.0 - _pulseController.value).clamp(0.0, 1.0),
                          ),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
              GlassCard(
                opacity: 0.15,
                borderRadius: 24,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isMutual ? LucideIcons.search : LucideIcons.clock, 
                             size: 20, color: Colors.white70)
                            .animate(onPlay: (c) => c.repeat())
                            .shimmer(duration: 2.seconds),
                        const SizedBox(width: 8),
                        Text(
                          isMutual ? t('radar_lock_active', lang) : t('waiting_for_acceptance', lang),
                          style: GoogleFonts.instrumentSans(
                            color: isMutual ? colorScheme.primary : Colors.white70,
                            fontSize: 10,
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
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _showStopSearchDialog,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white24),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'USTAVI', // "Stop"
                      style: GoogleFonts.instrumentSans(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    ref.read(waveRepositoryProvider).markMatchAsFound(widget.match.id);
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'NAŠLI SMO SE!', 
                      style: GoogleFonts.instrumentSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
