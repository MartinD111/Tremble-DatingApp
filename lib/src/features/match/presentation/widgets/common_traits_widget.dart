// lib/src/features/match/presentation/widgets/common_traits_widget.dart
//
// Tremble Common Traits Widget
// Prikaže do 3 skupne lastnosti po mutual wave — brez % in brez score-a.
// Uporablja se samo na MatchRevealScreen za FREE in PRO userje enako.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/common_traits_calculator.dart';
import '../../../matches/data/match_repository.dart';

class CommonTraitsWidget extends StatelessWidget {
  final MatchProfile myProfile;
  final MatchProfile partnerProfile;

  static const Color _cream = Color(0xFFFAFAF7);

  const CommonTraitsWidget({
    super.key,
    required this.myProfile,
    required this.partnerProfile,
  });

  @override
  Widget build(BuildContext context) {
    final traits = CommonTraitsCalculator.getTop3(myProfile, partnerProfile);

    if (traits.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'YOU HAVE IN COMMON',
          style: GoogleFonts.instrumentSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _cream.withValues(alpha: 0.3),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: traits
              .asMap()
              .entries
              .map((entry) => _TraitChip(trait: entry.value)
                  .animate(delay: Duration(milliseconds: 100 * entry.key))
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOut))
              .toList(),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }
}

class _TraitChip extends StatelessWidget {
  final CommonTrait trait;

  static const Color _rose = Color(0xFFF4436C);
  static const Color _cream = Color(0xFFFAFAF7);

  const _TraitChip({required this.trait});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(100),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trait.icon,
            size: 13,
            color: _rose,
          ),
          const SizedBox(width: 7),
          Text(
            trait.label,
            style: GoogleFonts.instrumentSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _cream.withValues(alpha: 0.85),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
