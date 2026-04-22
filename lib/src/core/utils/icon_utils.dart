import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class IconUtils {
  static IconData getReligionIcon(String key) {
    switch (key) {
      case 'christianity':
        return Icons.church;
      case 'islam':
        return LucideIcons.moon;
      case 'hinduism':
        return Icons.temple_hindu;
      case 'buddhism':
        return Icons.self_improvement;
      case 'judaism':
        return Icons.synagogue;
      case 'agnostic':
        return LucideIcons.helpCircle;
      case 'atheist':
        return LucideIcons.ban;
      default:
        return LucideIcons.heart;
    }
  }

  static Color getHairColor(String key) {
    switch (key) {
      case 'blonde':
      case 'hair_blonde':
        return Colors.yellow.shade600;
      case 'brunette':
      case 'hair_brunette':
        return Colors.brown.shade700;
      case 'black':
      case 'hair_black':
        return Colors.black;
      case 'red':
      case 'hair_red':
        return Colors.red.shade700;
      case 'gray_white':
      case 'hair_gray_white':
        return Colors.grey.shade400;
      case 'other':
      case 'hair_other':
        return Colors.purple.shade400;
      default:
        return Colors.grey;
    }
  }

  static IconData getLookingForIcon(String key) {
    switch (key) {
      case 'short_term_fun':
        return LucideIcons.flame;
      case 'long_term_partner':
        return LucideIcons.heart;
      case 'short_open_long':
        return LucideIcons.zap;
      case 'long_open_short':
        return LucideIcons.gem;
      default:
        return LucideIcons.heart;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ZodiacUtils — derive zodiac sign emoji from a birthday
// ─────────────────────────────────────────────────────────────────────────────
class ZodiacUtils {
  /// Returns the zodiac emoji for a given [birthDate], or null if date is null.
  static String? getZodiacEmoji(DateTime? birthDate) {
    if (birthDate == null) return null;
    final m = birthDate.month;
    final d = birthDate.day;
    if ((m == 3 && d >= 21) || (m == 4 && d <= 19)) return '♈'; // Aries
    if ((m == 4 && d >= 20) || (m == 5 && d <= 20)) return '♉'; // Taurus
    if ((m == 5 && d >= 21) || (m == 6 && d <= 20)) return '♊'; // Gemini
    if ((m == 6 && d >= 21) || (m == 7 && d <= 22)) return '♋'; // Cancer
    if ((m == 7 && d >= 23) || (m == 8 && d <= 22)) return '♌'; // Leo
    if ((m == 8 && d >= 23) || (m == 9 && d <= 22)) return '♍'; // Virgo
    if ((m == 9 && d >= 23) || (m == 10 && d <= 22)) return '♎'; // Libra
    if ((m == 10 && d >= 23) || (m == 11 && d <= 21)) return '♏'; // Scorpio
    if ((m == 11 && d >= 22) || (m == 12 && d <= 21)) return '♐'; // Sagittarius
    if ((m == 12 && d >= 22) || (m == 1 && d <= 19)) return '♑'; // Capricorn
    if ((m == 1 && d >= 20) || (m == 2 && d <= 18)) return '♒'; // Aquarius
    return '♓'; // Pisces (Feb 19 – Mar 20)
  }

  /// Returns the zodiac sign name for a given [birthDate], or null if date is null.
  static String? getZodiacSign(DateTime? date) {
    if (date == null) return null;
    final m = date.month;
    final d = date.day;
    if ((m == 3 && d >= 21) || (m == 4 && d <= 19)) return 'aries';
    if ((m == 4 && d >= 20) || (m == 5 && d <= 20)) return 'taurus';
    if ((m == 5 && d >= 21) || (m == 6 && d <= 20)) return 'gemini';
    if ((m == 6 && d >= 21) || (m == 7 && d <= 22)) return 'cancer';
    if ((m == 7 && d >= 23) || (m == 8 && d <= 22)) return 'leo';
    if ((m == 8 && d >= 23) || (m == 9 && d <= 22)) return 'virgo';
    if ((m == 9 && d >= 23) || (m == 10 && d <= 22)) return 'libra';
    if ((m == 10 && d >= 23) || (m == 11 && d <= 21)) return 'scorpio';
    if ((m == 11 && d >= 22) || (m == 12 && d <= 21)) return 'sagittarius';
    if ((m == 12 && d >= 22) || (m == 1 && d <= 19)) return 'capricorn';
    if ((m == 1 && d >= 20) || (m == 2 && d <= 18)) return 'aquarius';
    return 'pisces';
  }

  /// Calculates age from birthDate.
  static int calcAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
