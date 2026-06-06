import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/theme_provider.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/subscriptions/application/revenuecat_subscription.dart';

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
    ref.listen<AuthUser?>(authStateProvider, (previous, next) {
      if (previous == null && next != null) {
        final desired = next.isDarkMode ? ThemeMode.dark : ThemeMode.light;
        if (ref.read(themeModeProvider) != desired) {
          ref.read(themeModeProvider.notifier).setThemeMode(desired);
        }
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
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;

        final isPremium = next.customerInfo?.activeEntitlements
                .contains(revenueCatEntitlementPremium) ??
            false;
        unawaited(
          FirebaseFirestore.instance.collection('users').doc(uid).update(
            {'isPremium': isPremium},
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
    );
  }
}
