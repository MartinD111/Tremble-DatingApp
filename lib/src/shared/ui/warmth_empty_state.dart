import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import 'glass_card.dart';

class WarmthEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  const WarmthEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
    this.maxWidth = 340,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GlassCard(
          opacity: 0.12,
          borderRadius: 24,
          padding: padding,
          borderColor: Colors.white.withValues(alpha: 0.12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '◎',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: TrembleTheme.rose.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  height: 1.08,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    fontSize: 13,
                    height: 1.35,
                    color: colorScheme.onSurface.withValues(alpha: 0.58),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
