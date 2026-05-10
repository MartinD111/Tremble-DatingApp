import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import '../../../../../features/gym/domain/selected_gym.dart';
import '../../../../../features/gym/presentation/gym_search_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GymStep — onboarding step where users can add up to 3 personal gyms.
//
// The step is optional: the "Skip" action on the top-right calls [onContinue]
// directly. The "Continue" CTA at the bottom also calls [onContinue].
// ─────────────────────────────────────────────────────────────────────────────

class GymStep extends ConsumerWidget {
  const GymStep({
    super.key,
    required this.selectedGyms,
    required this.onAdd,
    required this.onRemove,
    required this.onContinue,
    this.onBack,
    required this.tr,
  });

  final List<SelectedGym> selectedGyms;
  final Future<bool> Function(SelectedGym gym) onAdd;
  final void Function(String placeId) onRemove;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final String Function(String) tr;

  static const _brandRose = Color(0xFFF4436C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.white70 : Colors.black54;

    return SafeArea(
      child: Column(
        children: [
          // ── Top bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                if (onBack != null) TrembleBackButton(onPressed: onBack!),
                const Spacer(),
                TextButton(
                  onPressed: onContinue,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.white54 : Colors.black38,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _brandRose.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      LucideIcons.dumbbell,
                      color: _brandRose,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'Your Gyms',
                    style: GoogleFonts.playfairDisplay(
                      color: textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    'Add up to 3 gyms for Gym Mode proximity detection.',
                    style: GoogleFonts.instrumentSans(
                      color: subColor,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Gym count indicator
                  Row(
                    children: List.generate(3, (i) {
                      final filled = i < selectedGyms.length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Container(
                          width: 24,
                          height: 4,
                          decoration: BoxDecoration(
                            color: filled
                                ? _brandRose
                                : (isDark ? Colors.white12 : Colors.black12),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Search widget
                  GymSearchWidget(
                    selectedGyms: selectedGyms,
                    onAdd: onAdd,
                    onRemove: onRemove,
                  ),
                ],
              ),
            ),
          ),

          // ── Continue CTA ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: GestureDetector(
              onTap: onContinue,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: _brandRose,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: _brandRose.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    selectedGyms.isEmpty ? 'Skip for now' : 'Continue',
                    style: GoogleFonts.instrumentSans(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
