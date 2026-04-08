import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'themeMode';

  /// Default constructor — starts with light mode and async-loads persisted value.
  /// Only used as fallback; [withInitial] is preferred to avoid flash.
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadThemeMode();
  }

  /// Named constructor — starts with a pre-loaded [initial] value so there is
  /// no async gap between app start and the correct theme being applied.
  /// Use this via a ProviderScope override in main() after reading SharedPreferences.
  ThemeModeNotifier.withInitial(ThemeMode initial) : super(initial);

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key);
    if (isDark != null && mounted) {
      state = isDark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, mode == ThemeMode.dark);
  }
}
