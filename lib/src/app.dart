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
    final user = ref.watch(authStateProvider);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

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
