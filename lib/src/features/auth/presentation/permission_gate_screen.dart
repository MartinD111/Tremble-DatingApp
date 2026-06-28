import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/consent_service.dart';
import '../../../core/theme.dart';
import '../../../core/theme_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../../shared/ui/glass_card.dart';
import '../../../shared/ui/primary_button.dart';

class PermissionGateScreen extends ConsumerStatefulWidget {
  const PermissionGateScreen({super.key});

  @override
  ConsumerState<PermissionGateScreen> createState() =>
      _PermissionGateScreenState();
}

class _PermissionGateScreenState extends ConsumerState<PermissionGateScreen>
    with WidgetsBindingObserver {
  bool _showDeclined = false;
  bool _isRequesting = false;
  bool _showSettingsPrompt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _showSettingsPrompt) {
      _recheckLocationOnResume();
    }
  }

  Future<void> _recheckLocationOnResume() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted || status.isLimited) {
      if (mounted) {
        setState(() => _showSettingsPrompt = false);
        await ref.read(gdprConsentProvider.notifier).grantConsent();
      }
    }
  }

  Future<void> _onAccept() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);

    await ConsentService.requestBluetooth();
    await ConsentService.requestNotification();
    await ConsentService.requestLocation();

    final locationStatus = await Permission.locationWhenInUse.status;

    if (!mounted) return;

    if (locationStatus.isGranted || locationStatus.isLimited) {
      await ref.read(gdprConsentProvider.notifier).grantConsent();
      // Router redirect fires automatically once consent state updates.
    } else {
      // iOS denied or permanently denied — must go to Settings.
      // Do NOT call grantConsent(); show inline Settings prompt instead.
      setState(() {
        _isRequesting = false;
        _showSettingsPrompt = true;
      });
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
    final user = ref.watch(authStateProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    final gradient = TrembleTheme.getGradient(
      isDarkMode: isDark,
      isPrideMode: user?.isPrideMode ?? false,
      gender: user?.gender,
      isGenderBasedColor: user?.isGenderBasedColor ?? false,
    );

    return Scaffold(
      backgroundColor: gradient.first,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _showSettingsPrompt
                ? _SettingsRequiredView(
                    onOpenSettings: () => openAppSettings(),
                    user: user,
                    isDark: isDark,
                  )
                : _showDeclined
                    ? _DeclinedView(
                        onTryAgain: _onTryAgain,
                        user: user,
                        isDark: isDark,
                      )
                    : _ConsentView(
                        isLoading: _isRequesting,
                        onAccept: _onAccept,
                        onDecline: _onDecline,
                        user: user,
                        isDark: isDark,
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
  final AuthUser? user;
  final bool isDark;

  const _ConsentView({
    required this.isLoading,
    required this.onAccept,
    required this.onDecline,
    required this.user,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 80),

          // Headline
          Text(
            'Before we find\nyour people',
            style: textTheme.displaySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(
              begin: 0.15, end: 0, duration: 500.ms, curve: Curves.easeOut),

          const SizedBox(height: 12),

          Text(
            'Tremble requests access to these features on your device to detect nearby users and set up your profile. Here is exactly what we use and why.',
            style: textTheme.bodyLarge?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
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
                    color: TrembleTheme.getPillColor(
                      isDark: isDark,
                      isGenderBased: user?.isGenderBasedColor ?? false,
                      gender: user?.gender,
                    ).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.bluetooth,
                    color: user != null &&
                            user!.isGenderBasedColor &&
                            user!.gender == 'male'
                        ? TrembleTheme.azure
                        : TrembleTheme.rose,
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
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Used to detect nearby users passively. No messages or data are sent over Bluetooth — only an anonymous signal.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
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
                    color: TrembleTheme.getPillColor(
                      isDark: isDark,
                      isGenderBased: user?.isGenderBasedColor ?? false,
                      gender: user?.gender,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.mapPin,
                    color: Color(0xFF0EA5E9),
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
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Used alongside Bluetooth to establish proximity. Your precise coordinates are never stored or shared.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
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

          const SizedBox(height: 12),

          // Notifications card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TrembleTheme.getPillColor(
                      isDark: isDark,
                      isGenderBased: user?.isGenderBasedColor ?? false,
                      gender: user?.gender,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.bell,
                    color: Color(0xFFF5C842),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Used to send you alerts for incoming waves and nearby proximity matches.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                              height: 1.45,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(
              begin: 0.1, end: 0, duration: 450.ms, curve: Curves.easeOut),

          const SizedBox(height: 12),

          // Camera card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TrembleTheme.getPillColor(
                      isDark: isDark,
                      isGenderBased: user?.isGenderBasedColor ?? false,
                      gender: user?.gender,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.camera,
                    color: TrembleTheme.successGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Camera',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Used only to capture your profile photo during onboarding or editing.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                              height: 1.45,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 500.ms).slideY(
              begin: 0.1, end: 0, duration: 450.ms, curve: Curves.easeOut),

          const SizedBox(height: 16),

          // GDPR footnote
          Text(
            'You can withdraw this consent at any time in Settings. Your data is processed under GDPR Article 6(1)(a) — consent.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                  height: 1.5,
                ),
          ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

          const SizedBox(height: 48),

          // Actions
          PrimaryButton(
            text: isLoading ? 'Enabling...' : 'Allow Access',
            onPressed: isLoading ? () {} : onAccept,
          ).animate().fadeIn(delay: 650.ms, duration: 400.ms).slideY(
              begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),

          const SizedBox(height: 12),

          PrimaryButton(
            text: 'Not Now',
            isSecondary: true,
            onPressed: isLoading ? () {} : onDecline,
          ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Declined explanation ──────────────────────────────────────────────────

class _DeclinedView extends StatelessWidget {
  final VoidCallback onTryAgain;
  final AuthUser? user;
  final bool isDark;

  const _DeclinedView({
    required this.onTryAgain,
    required this.user,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 80),
          Icon(
            LucideIcons.scanLine,
            color: Theme.of(context).colorScheme.primary,
            size: 48,
          ).animate().fadeIn(duration: 400.ms).scale(
              begin: const Offset(0.8, 0.8),
              duration: 400.ms,
              curve: Curves.easeOut),
          const SizedBox(height: 28),
          Text(
            'Radar needs\nyour permission',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                    height: 1.6,
                  ),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 48),
          PrimaryButton(
            text: 'Try Again',
            onPressed: onTryAgain,
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: 12),
          PrimaryButton(
            text: 'Open Settings',
            isSecondary: true,
            onPressed: () {
              openAppSettings();
            },
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Settings-required prompt (iOS denied location) ────────────────────────
// Shown after _onAccept() detects Permission.locationWhenInUse is not granted.
// The screen does NOT route away — the user opens iOS Settings, grants
// location, and didChangeAppLifecycleState picks up the change on resume,
// auto-completing the consent flow.

class _SettingsRequiredView extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final AuthUser? user;
  final bool isDark;

  const _SettingsRequiredView({
    required this.onOpenSettings,
    required this.user,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 80),
          Icon(
            LucideIcons.mapPin,
            color: Theme.of(context).colorScheme.primary,
            size: 48,
          ).animate().fadeIn(duration: 400.ms).scale(
              begin: const Offset(0.8, 0.8),
              duration: 400.ms,
              curve: Curves.easeOut),
          const SizedBox(height: 28),
          Text(
            'Location access\nis required for radar',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Text(
              "Open iOS Settings → Privacy & Security → Location Services → find this app → set to 'While Using'.\n\nReturn to Tremble and the radar will unlock automatically.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                    height: 1.6,
                  ),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 48),
          PrimaryButton(
            text: 'Open Settings',
            onPressed: onOpenSettings,
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
