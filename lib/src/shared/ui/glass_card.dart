import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final bool useGlassEffect;
  final Color? solidDarkBg;

  const GlassCard({
    super.key,
    required this.child,
    this.opacity = 0.2,
    this.borderRadius = 28.0,
    this.padding = const EdgeInsets.all(20),
    this.borderColor,
    this.useGlassEffect = true,
    this.solidDarkBg,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark
        ? Colors.white.withValues(alpha: opacity)
        : Colors.black.withValues(alpha: opacity * 0.5);
    final borderColorValue = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.15));

    // For dark mode with solid background, use the provided color or default
    final bgColor = useGlassEffect
        ? glassColor
        : (isDark
            ? (solidDarkBg ?? const Color(0xFF2A2A2E))
            : Colors.white);

    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColorValue),
      ),
      child: child,
    );

    // Only apply glass effect (backdrop blur) when useGlassEffect is true
    if (!useGlassEffect) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: container,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: container,
      ),
    );
  }
}
