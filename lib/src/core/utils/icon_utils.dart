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
        return Colors.yellow.shade600;
      case 'brunette':
        return Colors.brown.shade700;
      case 'black':
        return Colors.black;
      case 'red':
        return Colors.red.shade700;
      case 'gray_white':
        return Colors.grey.shade400;
      case 'other':
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
