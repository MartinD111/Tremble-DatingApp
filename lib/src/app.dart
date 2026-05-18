import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/theme_provider.dart';
import 'features/auth/data/auth_repository.dart';

class TrembleApp extends ConsumerWidget {
  const TrembleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    // routerProvider must never be invalidated by auth state changes — the
    // _RouterNotifier it owns caches auth state internally. Watching
    // authStateProvider here caused the entire router (and its notifier) to
    // be recreated on every auth event, resetting _cachedAuthUser to null and
    // breaking the redirect logic. Theme colours are stable enough to rebuild
    // only when themeMode changes; the gender-based colour updates on next
    // cold start which is acceptable.
    final router = ref.watch(routerProvider);
    final user = ref.read(authStateProvider);

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
