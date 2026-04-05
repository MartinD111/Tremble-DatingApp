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
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Sync theme with user's Firestore preference on auth state changes.
    ref.listen<AuthUser?>(authStateProvider, (prev, next) {
      if (next != null && prev?.isDarkMode != next.isDarkMode) {
        ref.read(themeModeProvider.notifier).setThemeMode(
              next.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            );
      }
    });

    return MaterialApp.router(
      title: 'Tremble',
      debugShowCheckedModeBanner: false,
      theme: TrembleTheme.lightTheme,
      darkTheme: TrembleTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
