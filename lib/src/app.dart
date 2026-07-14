import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/motion_bridge.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/theme_provider.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/backfill_consent_modal.dart';
import 'features/subscriptions/application/revenuecat_subscription.dart';
import 'shared/ui/dismiss_keyboard.dart';

// Watches only the two fields that affect theme colours. TrembleApp rebuilds
// when gender or isGenderBasedColor changes without touching routerProvider
// (which must never be invalidated by raw auth state events).
final _themeKeyProvider = Provider<(String?, bool)>((ref) {
  final u = ref.watch(authStateProvider);
  return (u?.gender, u?.isGenderBasedColor ?? false);
});

class TrembleApp extends ConsumerWidget {
  const TrembleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    ref.watch(
        _themeKeyProvider); // rebuilds theme when gender/colour pref changes
    final router = ref.watch(routerProvider);
    final user = ref.read(authStateProvider);
    ref.watch(revenueCatSubscriptionProvider);

    // One-time sync: when user first logs in on a new device, apply their
    // Firestore isDarkMode preference if it differs from the local default.
    //
    // Also drives the MotionBridge lifecycle — motion monitoring must run on
    // the main isolate because the native channel is registered there
    // (TrembleNativePlugin in AppDelegate.swift). The background isolate then
    // consumes forwarded state via service.on('motionStateChanged') for
    // Run-Club auto-activation. See lib/src/core/motion_bridge.dart.
    ref.listen<AuthUser?>(authStateProvider, (previous, next) {
      if (previous == null && next != null) {
        final desired = next.isDarkMode ? ThemeMode.dark : ThemeMode.light;
        if (ref.read(themeModeProvider) != desired) {
          ref.read(themeModeProvider.notifier).setThemeMode(desired);
        }
        unawaited(MotionBridge.start());
      }
      if (previous != null && next == null) {
        unawaited(MotionBridge.stop());
      }
      unawaited(
        ref.read(revenueCatSubscriptionProvider.notifier).syncAppUserId(
              next?.id,
            ),
      );
    });

    ref.listen<RevenueCatSubscriptionState>(
      revenueCatSubscriptionProvider,
      (previous, next) {
        if (next.status != RevenueCatSubscriptionStatus.ready) return;
        unawaited(
          ref.read(revenueCatSubscriptionProvider.notifier).syncAppUserId(
                ref.read(authStateProvider)?.id,
              ),
        );
      },
    );

    final theme = TrembleTheme.lightTheme(user);
    final darkTheme = TrembleTheme.darkTheme(user);

    return MaterialApp.router(
      title: 'Tremble',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => DismissKeyboard(
        child: BackfillConsentGate(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
