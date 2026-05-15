import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class IntroSlideStep extends StatelessWidget {
  const IntroSlideStep({
    super.key,
    required this.index,
    required this.onNext,
    required this.onBack,
    this.onLogout,
    required this.tr,
  });

  final int index;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onLogout;
  final String Function(String) tr;

  void _showCancelConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final bodyColor = isDark ? Colors.white60 : Colors.black54;
    final borderColor = isDark ? Colors.white12 : Colors.black12;
    final handleColor = isDark ? Colors.white24 : Colors.black26;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          decoration: BoxDecoration(
            color: sheetBg.withValues(alpha: 0.9),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              tr('cancel_registration'),
              style: GoogleFonts.instrumentSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You will be sent back to the landing page.',
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSans(
                color: bodyColor,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                onLogout?.call();
              },
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    'YES, CANCEL',
                    style: GoogleFonts.instrumentSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'NO, GO BACK',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  letterSpacing: 1.2,
                  fontSize: 13,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      tr('calib0_title'),
      tr('calib1_title'),
      tr('calib2_title'),
      tr('calib3_title'),
    ];
    final bodies = [
      tr('calib0_body'),
      tr('calib1_body'),
      tr('calib2_body'),
      tr('calib3_body'),
    ];
    final icons = [
      LucideIcons.activity,
      LucideIcons.radio,
      LucideIcons.shieldCheck,
      LucideIcons.radar,
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final bodyColor = isDark ? Colors.white70 : Colors.black54;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fixed header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            child: TrembleBackButton(
              label: tr('back'),
              onPressed: () {
                if (index == 0) {
                  _showCancelConfirmation(context);
                } else {
                  onBack();
                }
              },
            ),
          ),

          // ── Content (top-aligned with top padding) ───────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.22),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(icons[index],
                        size: 44,
                        color: Theme.of(context).colorScheme.primary),
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
                ],
              ),
            ),
          ),

          // ── Pinned Continue button ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ContinueButton(
              enabled: true,
              onTap: onNext,
              label: tr('continue_btn'),
            ),
          ),
        ],
      ),
    );
  }
}
