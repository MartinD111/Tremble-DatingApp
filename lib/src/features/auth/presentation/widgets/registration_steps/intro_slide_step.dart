import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../shared/ui/tremble_logo.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class IntroSlideStep extends StatelessWidget {
  const IntroSlideStep({
    super.key,
    required this.index,
    required this.onNext,
    required this.onBack,
    required this.tr,
  });

  final int index;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final String Function(String) tr;

  @override
  Widget build(BuildContext context) {
    final titles = [
      tr('onb1_title'),
      tr('onb2_title'),
      tr('onb3_title'),
      tr('onb4_title'),
    ];
    final bodies = [
      tr('onb1_body'),
      tr('onb2_body'),
      tr('onb3_body'),
      tr('onb4_body'),
    ];
    final icons = [
      LucideIcons.heartPulse,
      LucideIcons.activity,
      LucideIcons.map,
      LucideIcons.user,
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final bodyColor = isDark ? Colors.white70 : Colors.black54;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (index > 0) ...[
              Align(
                alignment: Alignment.topLeft,
                child: TrembleBackButton(
                  label: tr('back'),
                  onPressed: onBack,
                ),
              ),
              const SizedBox(height: 12),
            ] else
              const SizedBox(height: 60),
            const TrembleLogo(size: 56),
            const SizedBox(height: 40),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(icons[index], size: 44, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 40),
            Text(
              titles[index],
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSans(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              bodies[index],
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSans(
                fontSize: 16,
                color: bodyColor,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final isActive = i == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : (isDark ? Colors.white30 : Colors.black26),
                    borderRadius: BorderRadius.circular(100),
                  ),
                );
              }),
            ),
            const Spacer(),
            ContinueButton(
              enabled: true,
              onTap: onNext,
              label: tr('continue_btn'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
