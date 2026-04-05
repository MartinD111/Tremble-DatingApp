import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TrembleTheme {
  // Base Colors
  static const backgroundColor = Color(0xFFFAFAF7); // warm cream
  static const textColor = Color(0xFF1A1A18); // deep graphite
  
  // Brand Colors
  static const rose = Color(0xFFF4436C); // Tremble Rose — primary
  static const roseLight = Color(0xFFF9839E); // Rose Light
  static const roseDark = Color(0xFFC02048); // Rose Dark
  static const accentYellow = Color(0xFFF5C842); // Signal Yellow — accents, live indicators
  static const successGreen = Color(0xFF2D9B6F); // Confirm Green — success states, GDPR
  static const warmGray = Color(0xFF6B6B63); // Warm Gray — secondary text
  static const border = Color(0xFFE2E2DC); // Border color

  // Female Theme Colors (Rose)
  static const femalePrimary = Color(0xFFF4436C); // rose
  static const femaleDarkPrimary = Color(0xFFC2185B); // dark rose variant

  // Male Theme Colors (Light Blue)
  static const malePrimary = Color(0xFF64B5F6); // light blue
  static const maleDarkPrimary = Color(0xFF1976D2); // royal blue variant

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
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(100));
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius modalRadius = BorderRadius.all(Radius.circular(24));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(100)); // pill shape

  static List<Color> getGradient({
    required bool isDarkMode,
    required bool isPrideMode,
    required String? gender,
  }) {
    if (isPrideMode) {
      if (isDarkMode) {
        return prideGradient.map((c) => c.withValues(alpha: 0.5)).toList();
      }
      return prideGradient;
    }

    if (gender == 'Moški' || gender == 'Male') {
      if (isDarkMode) {
        return [maleDarkPrimary, malePrimary.withValues(alpha: 0.8)];
      }
      return [malePrimary, malePrimary.withValues(alpha: 0.8)];
    }

    // Default (Female/Other)
    if (isDarkMode) {
      return [femaleDarkPrimary, femalePrimary.withValues(alpha: 0.8)];
    }
    return [femalePrimary, femalePrimary.withValues(alpha: 0.8)];
  }

  static TextTheme _buildTextTheme(Color baseTextColor) {
    return TextTheme(
      // Display & Headlines — Playfair Display (serif, impactful)
      displayLarge: GoogleFonts.playfairDisplay(color: baseTextColor, fontWeight: FontWeight.w900, letterSpacing: -0.04 * 96),
      displayMedium: GoogleFonts.playfairDisplay(color: baseTextColor, fontWeight: FontWeight.w900, letterSpacing: -0.03 * 56),
      displaySmall: GoogleFonts.playfairDisplay(color: baseTextColor, fontWeight: FontWeight.w700, letterSpacing: -0.02 * 44),
      headlineLarge: GoogleFonts.playfairDisplay(color: baseTextColor, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.playfairDisplay(color: baseTextColor, fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.playfairDisplay(color: baseTextColor, fontWeight: FontWeight.w700),
      // Titles & Labels — Instrument Sans (clean UI font)
      titleLarge: GoogleFonts.instrumentSans(color: baseTextColor, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.instrumentSans(color: baseTextColor, fontWeight: FontWeight.w500),
      titleSmall: GoogleFonts.instrumentSans(color: baseTextColor, fontWeight: FontWeight.w500),
      labelLarge: GoogleFonts.instrumentSans(color: baseTextColor, fontWeight: FontWeight.w700, letterSpacing: 0.01 * 14),
      labelMedium: GoogleFonts.instrumentSans(color: baseTextColor, fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.instrumentSans(color: baseTextColor, fontWeight: FontWeight.w500),
      // Body — Lora (readable serif)
      bodyLarge: GoogleFonts.lora(color: baseTextColor, fontWeight: FontWeight.normal),
      bodyMedium: GoogleFonts.lora(color: baseTextColor, fontWeight: FontWeight.normal),
      bodySmall: GoogleFonts.lora(color: baseTextColor, fontWeight: FontWeight.normal),
    );
  }

  // Helper for telemetry/technical UI (JetBrains Mono)
  static TextStyle telemetryTextStyle(BuildContext context, {Color? color}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: 12,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: femalePrimary, // Default
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: backgroundColor,
        primary: femalePrimary,
        secondary: backgroundColor,
        surface: backgroundColor,
        onSurface: textColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 0, // Minimal/no shadow
        ),
      ),
      cardTheme: CardThemeData(
        shape: const RoundedRectangleBorder(borderRadius: cardRadius),
        elevation: 0, // Minimal depth
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: inputRadius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: inputRadius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: inputRadius, borderSide: const BorderSide(color: femalePrimary)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      textTheme: _buildTextTheme(textColor),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: femaleDarkPrimary,
      scaffoldBackgroundColor: const Color(0xFF1A1A18),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A1A18),
        primary: femaleDarkPrimary,
        secondary: const Color(0xFF1E1E1E),
        surface: const Color(0xFF1E1E2E),
        onSurface: const Color(0xFFE0E0E0),
        brightness: Brightness.dark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        shape: const RoundedRectangleBorder(borderRadius: cardRadius),
        elevation: 0,
        color: const Color(0xFF1E1E2E),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: inputRadius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: inputRadius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: inputRadius, borderSide: const BorderSide(color: femaleDarkPrimary)),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
      ),
      textTheme: _buildTextTheme(const Color(0xFFE0E0E0)),
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
