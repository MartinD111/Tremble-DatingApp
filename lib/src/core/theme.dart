import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TrembleTheme {
  // Base Colors - Premium Cyan & Indigo
  static const primaryColor = Color(0xFF00E5CC); // Electric Cyan
  static const secondaryColor = Color(0xFF1A237E); // Deep Indigo

  // Male Theme Colors - Deep Emerald
  static const malePrimaryColor = Color(0xFF004D40); // Deep Teal
  static const maleSecondaryColor = Color(0xFF00796B); // Teal

  // Dark Mode Colors - Midnight & Deep Forest
  static const darkPrimaryColor = Color(0xFF080B12); // Midnight
  static const darkSecondaryColor = Color(0xFF00242C); // Dark Petrol
  static const darkMalePrimaryColor = Color(0xFF001A1A); // Almost Black Green
  static const darkMaleSecondaryColor = Color(0xFF003838); // Deep Forest

  // Pride Colors
  static const List<Color> prideGradient = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
  ];

  static List<Color> getGradient({
    required bool isDarkMode,
    required bool isPrideMode,
    required String? gender,
  }) {
    if (isPrideMode) {
      if (isDarkMode) {
        return prideGradient.map((c) => c.withValues(alpha: 0.7)).toList();
      }
      return prideGradient;
    }

    if (gender == 'Moški' || gender == 'Male') {
      if (isDarkMode) {
        return [darkMaleSecondaryColor, darkMalePrimaryColor];
      }
      return [maleSecondaryColor, malePrimaryColor];
    }

    // Default (Female/Other)
    if (isDarkMode) {
      return [darkSecondaryColor, darkPrimaryColor];
    }
    return [secondaryColor, primaryColor];
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: secondaryColor,
        secondary: primaryColor,
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: darkPrimaryColor,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkSecondaryColor,
        secondary: darkPrimaryColor,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: Colors.white70,
        displayColor: Colors.white,
      ),
    );
  }
}
