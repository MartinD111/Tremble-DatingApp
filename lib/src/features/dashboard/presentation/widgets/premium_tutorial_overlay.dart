import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    final targetRects = ref.watch(tutorialTargetRectsProvider);

    final tutorialStep = _TutorialStep.forIndex(
      state.currentStep,
      MediaQuery.of(context),
      lang,
      targetRects[state.currentStep],
    );

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: _SpotlightHitTestGate(
              center: tutorialStep.spotlightCenter,
              radius: tutorialStep.spotlightRadius,
              child: CustomPaint(
                painter: SpotlightPainter(
                  center: tutorialStep.spotlightCenter,
                  radius: tutorialStep.spotlightRadius,
                ),
              ),
            ),
          ),
          if (!state.isPopupActive)
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
              child: Material(
                color: Colors.transparent,
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
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StepDots(currentStep: state.currentStep),
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
    int step,
    MediaQueryData mediaQuery,
    String lang,
    Rect? targetRect,
  ) {
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    final localRect = targetRect;

    final center = localRect?.center;
    final radius = localRect == null
        ? null
        : (localRect.longestSide / 2).clamp(44.0, 140.0).toDouble();

    switch (step) {
      case 1:
        return _TutorialStep(
          spotlightCenter: center ??
              Offset(
                screenWidth - 46,
                70,
              ),
          spotlightRadius: radius ?? 45,
          title: t('tutorial_step1_title', lang),
          description: t('tutorial_step1_desc', lang),
          showCardAtTop: true,
        );
      case 2:
        return _TutorialStep(
          spotlightCenter: center ??
              Offset(
                screenWidth * 0.38,
                screenHeight - 65 - mediaQuery.padding.bottom - mediaQuery.padding.top,
              ),
          spotlightRadius: radius ?? 45,
          title: t('tutorial_step2_title', lang),
          description: t('tutorial_step2_desc', lang),
          showCardAtTop: true,
        );
      case 3:
        return _TutorialStep(
          spotlightCenter: center ??
              Offset(
                screenWidth * 0.62,
                screenHeight - 65 - mediaQuery.padding.bottom - mediaQuery.padding.top,
              ),
          spotlightRadius: radius ?? 45,
          title: t('tutorial_step3_title', lang),
          description: t('tutorial_step3_desc', lang),
          showCardAtTop: true,
        );
      case 4:
        return _TutorialStep(
          spotlightCenter: center ??
              Offset(
                screenWidth * 0.86,
                screenHeight - 65 - mediaQuery.padding.bottom - mediaQuery.padding.top,
              ),
          spotlightRadius: radius ?? 45,
          title: t('tutorial_step4_title', lang),
          description: t('tutorial_step4_desc', lang),
          showCardAtTop: true,
        );
      case 5:
        return _TutorialStep(
          spotlightCenter:
              center ?? Offset(screenWidth / 2, (screenHeight * 0.44) - mediaQuery.padding.top),
          spotlightRadius: radius ?? 140,
          title: t('tutorial_step5_title', lang),
          description: t('tutorial_step5_desc', lang),
          showCardAtTop: false,
        );
      default:
        return _TutorialStep(
          spotlightCenter: center ??
              Offset(
                46,
                70,
              ),
          spotlightRadius: radius ?? 45,
          title: t('tutorial_step0_title', lang),
          description: t('tutorial_step0_desc', lang),
          showCardAtTop: true,
        );
    }
  }
}

class _SpotlightHitTestGate extends SingleChildRenderObjectWidget {
  const _SpotlightHitTestGate({
    required this.center,
    required this.radius,
    required super.child,
  });

  final Offset center;
  final double radius;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSpotlightHitTestGate(center: center, radius: radius);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderSpotlightHitTestGate renderObject,
  ) {
    renderObject
      ..center = center
      ..radius = radius;
  }
}

class _RenderSpotlightHitTestGate extends RenderProxyBox {
  _RenderSpotlightHitTestGate({
    required Offset center,
    required double radius,
  })  : _center = center,
        _radius = radius;

  Offset _center;
  double _radius;

  set center(Offset value) {
    if (_center == value) return;
    _center = value;
    markNeedsPaint();
  }

  set radius(double value) {
    if (_radius == value) return;
    _radius = value;
    markNeedsPaint();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if ((position - _center).distance <= _radius) {
      return false;
    }
    result.add(BoxHitTestEntry(this, position));
    return true;
  }
}
