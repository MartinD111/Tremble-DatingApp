import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/auth/data/auth_repository.dart';

class TrembleTheme {
  // Base Colors
  static const backgroundColor = Color(0xFFFAFAF7); // warm cream
  static const textColor = Color(0xFF1A1A18); // deep graphite

  // Brand Colors
  static const rose = Color(0xFFF4436C); // Tremble Rose — primary
  static const roseLight = Color(0xFFF9839E); // Rose Light
  static const roseDark = Color(0xFFC02048); // Rose Dark
  static const azure = Color(0xFF007AFF); // Tremble Blue — primary for male
  static const azureDark = Color(0xFF005BB5); // Azure Dark
  static const accentYellow =
      Color(0xFFF5C842); // Signal Yellow — accents, live indicators
  static const successGreen =
      Color(0xFF2D9B6F); // Confirm Green — success states, GDPR
  static const warmGray = Color(0xFF6B6B63); // Warm Gray — secondary text
  static const border = Color(0xFFE2E2DC); // Border color

  // Removed Gendered Colors — Brand Identity v1.0 standardizes Tremble Rose as primary, unless Gender-Based Color is enabled.

  // Pride Colors (Soft Pastel Ambient)
  static const List<Color> prideGradient = [
    Color(0xFFFFB3BA), // pastel red
    Color(0xFFFFDFBA), // pastel orange
    Color(0xFFFFFFBA), // pastel yellow
    Color(0xFFBAFFC9), // pastel green
    Color(0xFFBAE1FF), // pastel blue
    Color(0xFFD3BFFF), // pastel purple
  ];

  // Border Radii Rules
  static const BorderRadius inputRadius =
      BorderRadius.all(Radius.circular(100));
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius modalRadius = BorderRadius.all(Radius.circular(24));
  static const BorderRadius buttonRadius =
      BorderRadius.all(Radius.circular(100)); // pill shape

  static List<Color> getGradient({
    required bool isDarkMode,
    required bool isPrideMode,
    required String? gender,
    bool isGenderBasedColor = false,
  }) {
    if (isPrideMode) {
      if (isDarkMode) {
        return prideGradient.map((c) => c.withValues(alpha: 0.5)).toList();
      }
      return prideGradient;
    }

    if (isGenderBasedColor) {
      // Male → deep navy/blue tones
      if (gender == 'male') {
        return isDarkMode
            ? [const Color(0xFF001B36), const Color(0xFF003366)]
            : [const Color(0xFFF0F7FF), const Color(0xFFD6E9FF)];
      }
      // Female / non-binary / unset → warm rose tones
      return isDarkMode
          ? [const Color(0xFF2A0A12), const Color(0xFF3D1520)]
          : [const Color(0xFFFFF0F3), const Color(0xFFFFD6DF)];
    }

    // Default: deep graphite gradient — consistent with onboarding and sign-in.
    if (isDarkMode) {
      return [const Color(0xFF1A1A18), const Color(0xFF2A2A2E)];
    }
    return [const Color(0xFFF0F4F8), const Color(0xFFD9E2EC)];
  }

  static Color getPillColor({
    required bool isDark,
    required bool isGenderBased,
    required String? gender,
  }) {
    if (isGenderBased) {
      final isMale = gender == 'male';
      if (isDark) {
        return isMale ? const Color(0xFF003366) : const Color(0xFF3D1520);
      } else {
        return isMale ? const Color(0xFFD6E9FF) : const Color(0xFFFFD6DF);
      }
    }
    return isDark ? const Color(0xFF2A2A2E) : const Color(0xFFE8ECF0);
  }

  static TextTheme _buildTextTheme(Color baseTextColor) {
    return TextTheme(
      // Display & Headlines — Playfair Display (serif, impactful)
      displayLarge: GoogleFonts.playfairDisplay(
          color: baseTextColor,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.04 * 96),
      displayMedium: GoogleFonts.playfairDisplay(
          color: baseTextColor,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.03 * 56),
      displaySmall: GoogleFonts.playfairDisplay(
          color: baseTextColor,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02 * 44),
      headlineLarge: GoogleFonts.playfairDisplay(
          color: baseTextColor, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.playfairDisplay(
          color: baseTextColor, fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.playfairDisplay(
          color: baseTextColor, fontWeight: FontWeight.w700),
      // Titles & Labels — Instrument Sans (clean UI font)
      titleLarge: GoogleFonts.instrumentSans(
          color: baseTextColor, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.instrumentSans(
          color: baseTextColor, fontWeight: FontWeight.w500),
      titleSmall: GoogleFonts.instrumentSans(
          color: baseTextColor, fontWeight: FontWeight.w500),
      labelLarge: GoogleFonts.instrumentSans(
          color: baseTextColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.01 * 14),
      labelMedium: GoogleFonts.instrumentSans(
          color: baseTextColor, fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.instrumentSans(
          color: baseTextColor, fontWeight: FontWeight.w500),
      // Body — Lora (readable serif)
      bodyLarge:
          GoogleFonts.lora(color: baseTextColor, fontWeight: FontWeight.normal),
      bodyMedium:
          GoogleFonts.lora(color: baseTextColor, fontWeight: FontWeight.normal),
      bodySmall:
          GoogleFonts.lora(color: baseTextColor, fontWeight: FontWeight.normal),
    );
  }

  // Helper for telemetry/technical UI (JetBrains Mono)
  static TextStyle telemetryTextStyle(BuildContext context, {Color? color}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: 12,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  /// Builds a complete ThemeData with brand fonts applied to every Material
  /// component that renders text (buttons, chips, list tiles, dialogs, etc.).
  static ThemeData _buildThemeData({
    required Brightness brightness,
    required Color primaryColor,
    required Color scaffoldBg,
    required ColorScheme colorScheme,
    required Color onSurface,
    required Color inputFill,
    required Color cardColor,
  }) {
    final ui = GoogleFonts.instrumentSans(color: onSurface);
    final hintColor = onSurface.withValues(alpha: 0.5);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: colorScheme,
      // ── Buttons ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: GoogleFonts.instrumentSans(
              fontSize: 16, fontWeight: FontWeight.w700),
          shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.instrumentSans(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: GoogleFonts.instrumentSans(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      // ── Cards ──
      cardTheme: CardThemeData(
        shape: const RoundedRectangleBorder(borderRadius: cardRadius),
        elevation: 0,
        color: cardColor,
      ),
      // ── Input fields ──
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
            borderRadius: inputRadius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: inputRadius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: inputRadius,
            borderSide: BorderSide(color: primaryColor)),
        filled: true,
        fillColor: inputFill,
        labelStyle: GoogleFonts.instrumentSans(color: hintColor),
        hintStyle: GoogleFonts.instrumentSans(color: hintColor),
      ),
      // ── List tiles (used by SwitchListTile, CheckboxListTile, etc.) ──
      listTileTheme: ListTileThemeData(
        titleTextStyle: ui.copyWith(fontSize: 16),
        subtitleTextStyle: ui.copyWith(fontSize: 12, color: hintColor),
        leadingAndTrailingTextStyle: ui.copyWith(fontSize: 14),
      ),
      // ── Dialogs ──
      dialogTheme: DialogThemeData(
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.lora(color: onSurface, fontSize: 15),
      ),
      // ── Chips ──
      chipTheme: ChipThemeData(
        labelStyle: ui.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: ui.copyWith(fontSize: 14),
      ),
      // ── Bottom sheet ──
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      // ── AppBar ──
      appBarTheme: AppBarTheme(
        titleTextStyle: GoogleFonts.instrumentSans(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      // ── TabBar ──
      tabBarTheme: TabBarThemeData(
        labelStyle: ui.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: ui.copyWith(fontSize: 14),
      ),
      // ── Text theme ──
      textTheme: _buildTextTheme(onSurface),
    );
  }

  static ThemeData lightTheme(AuthUser? user) {
    Color primary = rose;
    if (user != null && user.isGenderBasedColor && user.gender == 'male') {
      primary = azure;
    }

    return _buildThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBg: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: backgroundColor,
        primary: primary,
        secondary: backgroundColor,
        surface: backgroundColor,
        onSurface: textColor,
      ),
      onSurface: textColor,
      inputFill: const Color(0xFFEEEEEE),
      cardColor: Colors.white,
    );
  }

  static ThemeData darkTheme(AuthUser? user) {
    Color primary = roseDark;
    if (user != null && user.isGenderBasedColor && user.gender == 'male') {
      primary = azure;
    }

    const darkOnSurface = Color(0xFFE0E0E0);
    return _buildThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBg: const Color(0xFF1A1A18),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A1A18),
        primary: primary,
        secondary: const Color(0xFF1E1E1E),
        surface: const Color(0xFF1E1E2E),
        onSurface: darkOnSurface,
        brightness: Brightness.dark,
      ),
      onSurface: darkOnSurface,
      inputFill: const Color(0xFF2C2C2C),
      cardColor: const Color(0xFF1E1E2E),
    );
  }

  // ─── Brand Font Helpers ───
  // Use these for direct styling outside the theme text styles.

  /// Display/Headlines — Playfair Display (serif, high impact)
  static TextStyle displayFont({
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w900,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? -0.03 * fontSize,
      height: height,
    );
  }

  /// Body text — Lora (readable serif)
  static TextStyle bodyFont({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.lora(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  /// UI elements — Instrument Sans (buttons, labels, nav, forms)
  static TextStyle uiFont({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.instrumentSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}
