import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class PoliticalAffiliationStep extends StatelessWidget {
  const PoliticalAffiliationStep({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onBack,
    required this.onContinueTap,
    required this.tr,
  });

  /// 1–5 = Left→Right spectrum. 0 = "don't care". -1 = undisclosed.
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback onBack;

  /// Called when Continue is tapped. Parent is responsible for showing
  /// the partner-range modal and then advancing the page.
  final VoidCallback onContinueTap;
  final String Function(String) tr;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white70 : Colors.black54;
    final labels = [
      tr('politics_left'),
      tr('politics_center_left'),
      tr('politics_center'),
      tr('politics_center_right'),
      tr('politics_right'),
    ];
    final idx = value.toInt();
    final isSpecial = value == 0 || value == -1;

    return ScrollableFormPage(
      child: Column(
        children: [
          TrembleBackButton(label: tr('back'), onPressed: onBack),
          const SizedBox(height: 40),
          StepHeader(tr('political_affiliation')),
          const SizedBox(height: 48),
          Row(
            children: List.generate(labels.length, (i) {
              final isActive = !isSpecial && idx - 1 == i;
              return Expanded(
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.instrumentSans(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : labelColor,
                    fontSize: 11,
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: isSpecial
                  ? const RoundSliderThumbShape(enabledThumbRadius: 0)
                  : const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: isSpecial ? 3.0 : value.clamp(1.0, 5.0),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: isSpecial ? null : (v) => onChanged(v),
              activeColor: Theme.of(context).colorScheme.primary,
              inactiveColor: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
          const SizedBox(height: 32),
          OptionPill(
            label: tr('politics_dont_care'),
            selected: value == 0,
            onTap: () => onChanged(0),
          ),
          OptionPill(
            label: tr('politics_undisclosed'),
            selected: value == -1,
            onTap: () => onChanged(-1),
          ),
          const SizedBox(height: 24),
          ContinueButton(
            enabled: true,
            label: tr('continue_btn'),
            onTap: onContinueTap,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
