import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefKey = 'has_seen_tutorial';

/// Shows a first-launch tutorial overlay on the dashboard.
/// Skipped automatically if [SharedPreferences] flag [_prefKey] is true.
/// On first wave gesture (long-press on 👋), marks flag and dismisses.
class WaveSimulationOverlay extends StatefulWidget {
  const WaveSimulationOverlay({
    super.key,
    required this.tr,
    required this.onDismiss,
  });

  final String Function(String) tr;
  final VoidCallback onDismiss;

  @override
  State<WaveSimulationOverlay> createState() => _WaveSimulationOverlayState();
}

class _WaveSimulationOverlayState extends State<WaveSimulationOverlay>
    with SingleTickerProviderStateMixin {
  bool _showMatchCard = false;
  bool _waving = false;
  late final AnimationController _notifController;
  late final Animation<Offset> _notifSlide;

  @override
  void initState() {
    super.initState();
    _notifController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _notifSlide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _notifController, curve: Curves.easeOut));

    // Delay notification banner entry for dramatic effect
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _notifController.forward();
    });
  }

  @override
  void dispose() {
    _notifController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    if (mounted) widget.onDismiss();
  }

  void _onNotificationTap() {
    setState(() => _showMatchCard = true);
  }

  Future<void> _onWaveLongPress() async {
    HapticFeedback.mediumImpact();
    setState(() => _waving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    await _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        // Blurred barrier
        Positioned.fill(
          child: GestureDetector(
            onTap: () {}, // absorb taps outside controls
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),

        // Simulated system notification
        if (!_showMatchCard)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: SlideTransition(
              position: _notifSlide,
              child: GestureDetector(
                onTap: _onNotificationTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.radio, color: primary, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.tr('sim_someone_nearby'),
                          style: GoogleFonts.instrumentSans(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(LucideIcons.chevronRight,
                          size: 16,
                          color: isDark ? Colors.white38 : Colors.black38),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Tutorial match card
        if (_showMatchCard)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: primary.withValues(alpha: 0.15),
                          child:
                              Icon(LucideIcons.user, color: primary, size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '~20 m away',
                          style: GoogleFonts.instrumentSans(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.tr('sim_instruction'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.instrumentSans(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Wave long-press button
                        GestureDetector(
                          onLongPress: _onWaveLongPress,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: _waving
                                  ? primary
                                  : primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: primary, width: 1.5),
                            ),
                            child: Text(
                              '👋',
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Skip button
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 32,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _dismiss,
              child: Text(
                'Preskoči',
                style: GoogleFonts.instrumentSans(
                  color: Colors.white54,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white38,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Checks [SharedPreferences] and returns [true] if the tutorial has
/// already been seen. Call before deciding whether to show the overlay.
Future<bool> hasSeenTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_prefKey) ?? false;
}
