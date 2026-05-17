import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/ui/glass_card.dart';
import '../../../../core/translations.dart';
import '../../application/tutorial_notifier.dart';
import 'spotlight_painter.dart';

class PremiumTutorialOverlay extends ConsumerWidget {
  const PremiumTutorialOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tutorialProvider);
    if (!state.isActive) return const SizedBox.shrink();
    final lang = ref.watch(appLanguageProvider);

    final tutorialStep = _TutorialStep.forIndex(
      state.currentStep,
      MediaQuery.of(context),
      lang,
    );

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: CustomPaint(
                  painter: SpotlightPainter(
                    center: tutorialStep.spotlightCenter,
                    radius: tutorialStep.spotlightRadius,
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              left: 20,
              right: 20,
              top: tutorialStep.showCardAtTop
                  ? 100 + MediaQuery.of(context).padding.top
                  : null,
              bottom: tutorialStep.showCardAtTop
                  ? null
                  : 120 + MediaQuery.of(context).padding.bottom,
              child: GlassCard(
                borderRadius: 24,
                borderColor: const Color(0xFFF4436C).withValues(alpha: 0.28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      tutorialStep.title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tutorialStep.description,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StepDots(currentStep: state.currentStep),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => ref
                                  .read(tutorialProvider.notifier)
                                  .completeTutorial(),
                              child: Text(
                                t('tutorial_skip', lang),
                                style: GoogleFonts.instrumentSans(
                                  color: Colors.white.withValues(alpha: 0.52),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF4436C),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () => ref
                                  .read(tutorialProvider.notifier)
                                  .nextStep(),
                              child: Text(
                                state.currentStep == TutorialNotifier.lastStep
                                    ? t('tutorial_finish', lang)
                                    : t('tutorial_next', lang),
                                style: GoogleFonts.instrumentSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  final int currentStep;

  const _StepDots({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(TutorialNotifier.lastStep + 1, (index) {
        final isCurrent = index == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 4,
          width: isCurrent ? 16 : 8,
          decoration: BoxDecoration(
            color: isCurrent
                ? const Color(0xFFF4436C)
                : Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

class _TutorialStep {
  final Offset spotlightCenter;
  final double spotlightRadius;
  final String title;
  final String description;
  final bool showCardAtTop;

  const _TutorialStep({
    required this.spotlightCenter,
    required this.spotlightRadius,
    required this.title,
    required this.description,
    required this.showCardAtTop,
  });

  factory _TutorialStep.forIndex(
      int step, MediaQueryData mediaQuery, String lang) {
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    switch (step) {
      case 1:
        return _TutorialStep(
          spotlightCenter: Offset(
            screenWidth / 2,
            screenHeight - 65 - mediaQuery.padding.bottom,
          ),
          spotlightRadius: 45,
          title: t('tutorial_step1_title', lang),
          description: t('tutorial_step1_desc', lang),
          showCardAtTop: true,
        );
      case 2:
        return _TutorialStep(
          spotlightCenter: Offset(
            screenWidth / 2,
            70 + mediaQuery.padding.top,
          ),
          spotlightRadius: 75,
          title: t('tutorial_step2_title', lang),
          description: t('tutorial_step2_desc', lang),
          showCardAtTop: false,
        );
      case 3:
        return _TutorialStep(
          spotlightCenter: Offset(
            screenWidth * 0.88,
            screenHeight - 45 - mediaQuery.padding.bottom,
          ),
          spotlightRadius: 45,
          title: t('tutorial_step3_title', lang),
          description: t('tutorial_step3_desc', lang),
          showCardAtTop: true,
        );
      case 4:
        return _TutorialStep(
          spotlightCenter: Offset(
            screenWidth * 0.62,
            screenHeight - 45 - mediaQuery.padding.bottom,
          ),
          spotlightRadius: 45,
          title: t('tutorial_step4_title', lang),
          description: t('tutorial_step4_desc', lang),
          showCardAtTop: true,
        );
      case 5:
        return _TutorialStep(
          spotlightCenter: Offset(screenWidth / 2, screenHeight * 0.44),
          spotlightRadius: 140,
          title: t('tutorial_step5_title', lang),
          description: t('tutorial_step5_desc', lang),
          showCardAtTop: false,
        );
      default:
        return _TutorialStep(
          spotlightCenter: Offset(screenWidth / 2, screenHeight * 0.44),
          spotlightRadius: 135,
          title: t('tutorial_step0_title', lang),
          description: t('tutorial_step0_desc', lang),
          showCardAtTop: false,
        );
    }
  }
}
