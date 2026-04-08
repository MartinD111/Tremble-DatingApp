import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/consent_service.dart';
import '../../../shared/ui/glass_card.dart';
import '../../../shared/ui/primary_button.dart';

class PermissionGateScreen extends ConsumerStatefulWidget {
  const PermissionGateScreen({super.key});

  @override
  ConsumerState<PermissionGateScreen> createState() =>
      _PermissionGateScreenState();
}

class _PermissionGateScreenState extends ConsumerState<PermissionGateScreen> {
  bool _showDeclined = false;
  bool _isRequesting = false;

  Future<void> _onAccept() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);

    await ConsentService.requestLocation();
    await ConsentService.requestBluetooth();

    if (mounted) {
      await ref.read(gdprConsentProvider.notifier).grantConsent();
      // Router redirect fires automatically once consent state updates.
    }
  }

  void _onDecline() {
    setState(() => _showDeclined = true);
  }

  void _onTryAgain() {
    setState(() => _showDeclined = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF12001F),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _showDeclined
                ? _DeclinedView(onTryAgain: _onTryAgain)
                : _ConsentView(
                    isLoading: _isRequesting,
                    onAccept: _onAccept,
                    onDecline: _onDecline,
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Consent prompt ────────────────────────────────────────────────────────

class _ConsentView extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _ConsentView({
    required this.isLoading,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),

        // Headline
        Text(
          'Before we find\nyour people',
          style: textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(
            begin: 0.15, end: 0, duration: 500.ms, curve: Curves.easeOut),

        const SizedBox(height: 12),

        Text(
          'Tremble needs access to two features on your device to detect nearby users. Here is exactly what we use and why.',
          style: textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 500.ms),

        const SizedBox(height: 32),

        // Bluetooth card
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.bluetooth,
                  color: Color(0xFFB57BFF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bluetooth',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Detects other Tremble users physically nearby. No messages or data are sent over Bluetooth — only an anonymous signal.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white60,
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(
            begin: 0.1, end: 0, duration: 450.ms, curve: Curves.easeOut),

        const SizedBox(height: 12),

        // Location card
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.mapPin,
                  color: Color(0xFF67D5FF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Used as a fallback for proximity when Bluetooth is unavailable. Your precise coordinates are never stored or shared.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white60,
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(
            begin: 0.1, end: 0, duration: 450.ms, curve: Curves.easeOut),

        const SizedBox(height: 16),

        // GDPR footnote
        Text(
          'You can withdraw this consent at any time in Settings. Your data is processed under GDPR Article 6(1)(a) — consent.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white38,
                height: 1.5,
              ),
        ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

        const Spacer(),

        // Actions
        PrimaryButton(
          text: isLoading ? 'Enabling...' : 'Allow Access',
          onPressed: isLoading ? () {} : onAccept,
        ).animate().fadeIn(delay: 450.ms, duration: 400.ms).slideY(
            begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),

        const SizedBox(height: 12),

        PrimaryButton(
          text: 'Not Now',
          isSecondary: true,
          onPressed: isLoading ? () {} : onDecline,
        ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── Declined explanation ──────────────────────────────────────────────────

class _DeclinedView extends StatelessWidget {
  final VoidCallback onTryAgain;

  const _DeclinedView({required this.onTryAgain});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 80),
        Icon(
          LucideIcons.scanLine,
          color: Color(0xFF7C3AED),
          size: 48,
        ).animate().fadeIn(duration: 400.ms).scale(
            begin: const Offset(0.8, 0.8),
            duration: 400.ms,
            curve: Curves.easeOut),
        const SizedBox(height: 28),
        Text(
          'Radar needs\nyour permission',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Without Bluetooth and Location access, Tremble cannot detect anyone nearby. The core feature — finding people around you — will not work.\n\nNo other part of the app uses these permissions. You can change your mind at any time in Settings.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.6,
                ),
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
        const Spacer(),
        PrimaryButton(
          text: 'Try Again',
          onPressed: onTryAgain,
        ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
        const SizedBox(height: 32),
      ],
    );
  }
}
