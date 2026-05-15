import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/radar_integration_service.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

/// Android-only registration step that appears immediately before ConsentStep.
///
/// On iOS [Platform.isAndroid] is false and this widget must never be rendered
/// — the registration flow skips it entirely via a platform guard.
///
/// Shows two opt-in toggles (both default true) for:
///   1. Quick Settings tile
///   2. Home / lock-screen widget
/// On "Continue" it fires the OS request dialogs if the user left the toggles
/// enabled, then calls [onContinue].
class AndroidSystemIntegrationStep extends StatefulWidget {
  const AndroidSystemIntegrationStep({
    super.key,
    required this.onBack,
    required this.onContinue,
  });

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  State<AndroidSystemIntegrationStep> createState() =>
      _AndroidSystemIntegrationStepState();
}

class _AndroidSystemIntegrationStepState
    extends State<AndroidSystemIntegrationStep> {
  bool _addQsTile = true;
  bool _addWidget = true;
  bool _loading = false;

  Future<void> _onContinue() async {
    setState(() => _loading = true);
    try {
      final svc = RadarIntegrationService.instance;
      if (_addQsTile) await svc.requestAddQsTile();
      if (_addWidget) await svc.requestPinWidget();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fixed header ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            child: Row(
              children: [
                TrembleBackButton(onPressed: widget.onBack, label: 'Back'),
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Scrollable content ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero icon
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.04),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                      child: Icon(
                        Icons.radar_rounded,
                        size: 36,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title & subtitle
                  StepHeader(
                    'Always within reach',
                    subtitle:
                        'Tremble integrates with your phone so you can toggle your Radar '
                        'instantly — no need to open the app.',
                  ),
                  const SizedBox(height: 32),

                  // Feature cards
                  _IntegrationToggle(
                    icon: Icons.grid_view_rounded,
                    title: 'Quick Settings tile',
                    subtitle: 'A one-tap toggle in your notification panel. '
                        'Drag it wherever feels natural.',
                    value: _addQsTile,
                    onChanged: (v) => setState(() => _addQsTile = v),
                  ),
                  const SizedBox(height: 12),
                  _IntegrationToggle(
                    icon: Icons.widgets_rounded,
                    title: 'Home screen widget',
                    subtitle:
                        'Pin a small radar indicator to your home or lock screen '
                        'for instant access.',
                    value: _addWidget,
                    onChanged: (v) => setState(() => _addWidget = v),
                  ),
                  const SizedBox(height: 20),

                  // Privacy note
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: isDark ? Colors.white38 : Colors.black38,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You can always remove these from your phone settings. '
                            'Neither integration accesses your data — they only '
                            'control whether Radar is scanning.',
                            style: GoogleFonts.instrumentSans(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.45)
                                  : Colors.black.withValues(alpha: 0.45),
                              fontSize: 12,
                              height: 1.5,
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

          // ── Pinned bottom: skip + continue ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
            child: Center(
              child: GestureDetector(
                onTap: widget.onContinue,
                child: Text(
                  'Skip for now',
                  style: GoogleFonts.instrumentSans(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ContinueButton(
              enabled: !_loading,
              onTap: _onContinue,
              label: _loading ? 'Setting up…' : 'Continue',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE: single feature row with switch
// ─────────────────────────────────────────────────────────────────────────────
class _IntegrationToggle extends StatelessWidget {
  const _IntegrationToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value
              ? primary.withValues(alpha: 0.10)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value
                ? primary.withValues(alpha: 0.5)
                : (isDark ? Colors.white12 : Colors.black12),
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: value
                    ? primary.withValues(alpha: 0.18)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: value
                    ? primary
                    : (isDark ? Colors.white38 : Colors.black38),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: primary,
              activeTrackColor: primary.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
