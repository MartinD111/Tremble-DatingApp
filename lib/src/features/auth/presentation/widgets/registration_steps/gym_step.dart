import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import '../../../../../features/gym/domain/selected_gym.dart';
import '../../../../../features/gym/presentation/gym_search_widget.dart';
import 'step_shared.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GymStep — onboarding step where users can add up to 3 personal gyms.
// ─────────────────────────────────────────────────────────────────────────────

class GymStep extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<GymStep> createState() => _GymStepState();
}

class _GymStepState extends ConsumerState<GymStep> {
  static const _brandRose = Color(0xFFF4436C);
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.white70 : Colors.black54;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fixed header ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            child: Row(
              children: [
                if (widget.onBack != null)
                  TrembleBackButton(onPressed: widget.onBack!),
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Scrollable content ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Center(
                    child: Text(
                      'Your Gyms',
                      style: GoogleFonts.playfairDisplay(
                        color: textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Center(
                    child: Text(
                      'Add up to 3 gyms for Gym Mode proximity detection.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.instrumentSans(
                        color: subColor,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Gym count indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final filled = i < widget.selectedGyms.length;
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

                  // Search widget (always rendered so focus works)
                  GymSearchWidget(
                    selectedGyms: widget.selectedGyms,
                    onAdd: widget.onAdd,
                    onRemove: widget.onRemove,
                    focusNode: _searchFocus,
                  ),

                  // Add gym button — only shown when under 3 gyms
                  if (widget.selectedGyms.length < 3) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _searchFocus.requestFocus(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isDark
                                ? Colors.white24
                                : Colors.black.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.plus,
                              size: 20,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Add gym',
                              style: GoogleFonts.instrumentSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Pinned bottom: Continue ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ContinueButton(
              enabled: true,
              onTap: widget.onContinue,
              label: 'Continue',
            ),
          ),
        ],
      ),
    );
  }
}
