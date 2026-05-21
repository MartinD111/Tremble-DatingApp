import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import '../../../../../features/gym/domain/selected_gym.dart';
import '../../../../../features/gym/presentation/gym_search_widget.dart';
import 'step_shared.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GymStep — onboarding step where users can add up to 3 personal gyms.
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

  void _openAddGymSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _GymAddSheet(
        isDark: isDark,
        onAdd: (gym) async {
          final added = await onAdd(gym);
          if (added && sheetCtx.mounted) Navigator.pop(sheetCtx);
          return added;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                if (onBack != null) TrembleBackButton(onPressed: onBack!),
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

                  // Selected gym tiles — inline display, no search field here
                  if (selectedGyms.isNotEmpty) ...[
                    ...selectedGyms.map((gym) => _GymTile(
                          gym: gym,
                          onRemove: () => onRemove(gym.placeId),
                          isDark: isDark,
                        )),
                  ],

                  // Add gym button — only shown when under 3 gyms
                  if (selectedGyms.length < 3) ...[
                    if (selectedGyms.isNotEmpty) const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _openAddGymSheet(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: _brandRose.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: _brandRose.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.plus, size: 20, color: _brandRose),
                            const SizedBox(width: 10),
                            Text(
                              'Add gym',
                              style: GoogleFonts.instrumentSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _brandRose,
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
              onTap: onContinue,
              label: 'Continue',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selected-gym display tile (mirrors the one in gym_search_widget.dart).
// ─────────────────────────────────────────────────────────────────────────────

class _GymTile extends StatelessWidget {
  const _GymTile({
    required this.gym,
    required this.onRemove,
    required this.isDark,
  });

  final SelectedGym gym;
  final VoidCallback onRemove;
  final bool isDark;

  static const _brandRose = Color(0xFFF4436C);

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.white54 : Colors.black54;
    final surfaceColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.04);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _brandRose.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _brandRose.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(LucideIcons.dumbbell, color: _brandRose, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gym.name,
                  style: GoogleFonts.instrumentSans(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (gym.address.isNotEmpty)
                  Text(
                    gym.address,
                    style: GoogleFonts.instrumentSans(
                        color: subColor, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                LucideIcons.x,
                color: isDark ? Colors.white38 : Colors.black38,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet — search-only, auto-closes when a gym is added.
// ─────────────────────────────────────────────────────────────────────────────

class _GymAddSheet extends StatelessWidget {
  const _GymAddSheet({required this.isDark, required this.onAdd});

  final bool isDark;
  final Future<bool> Function(SelectedGym) onAdd;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF1A1A2E) : Colors.white)
                .withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Find Your Gym',
                style: GoogleFonts.playfairDisplay(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Search by gym name or address',
                style: GoogleFonts.instrumentSans(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              GymSearchWidget(
                selectedGyms: const [],
                onAdd: onAdd,
                onRemove: (_) {},
                showSelectedGyms: false,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
