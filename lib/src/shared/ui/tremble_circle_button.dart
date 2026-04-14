import 'dart:ui';
import 'package:flutter/material.dart';

class TrembleCircleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final double size;
  final Color? color;

  const TrembleCircleButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = 48.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // One UI 8.5 glass look
    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.06);
    final borderColorValue = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);
    final iconColor = color ?? (isDark ? Colors.white : Colors.black87);

    return GestureDetector(
      onTap: onPressed,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: glassColor,
              border: Border.all(color: borderColorValue, width: 0.5),
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: size * 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
