import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Brand-consistent pill-shaped back button.
/// Positioned top-right by default. Shows arrow + "Nazaj" label.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = color ?? (isDark ? Colors.white70 : Colors.black54);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: fgColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.arrowLeft, color: fgColor, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.instrumentSans(
                color: fgColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
