import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'tremble_circle_button.dart';

/// Brand-consistent back button (One UI 8.5 circle style).
/// The label is kept for API compatibility but is no longer displayed.
class TrembleBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final Color? color;

  const TrembleBackButton({
    super.key,
    required this.onPressed,
    this.label = 'Nazaj',
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TrembleCircleButton(
      onPressed: onPressed,
      icon: LucideIcons.chevronLeft,
      color: color,
    );
  }
}
