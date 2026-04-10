import 'package:flutter/material.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class DatingPreferencesStep extends StatelessWidget {
  const DatingPreferencesStep({
    super.key,
    required this.datingPreference,
    required this.ageRangePref,
    required this.onPreferenceChanged,
    required this.onAgeRangeChanged,
    required this.onBack,
    required this.onContinue,
    required this.tr,
  });

  final String? datingPreference;
  final RangeValues ageRangePref;
  final void Function(String? val) onPreferenceChanged;
  final ValueChanged<RangeValues> onAgeRangeChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final String Function(String) tr;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final opts = [
      {'key': 'short_term_fun', 'label': tr('short_term_fun')},
      {'key': 'long_term_partner', 'label': tr('long_term_partner')},
      {'key': 'short_open_long', 'label': tr('short_open_long')},
      {'key': 'long_open_short', 'label': tr('long_open_short')},
      {'key': 'undecided', 'label': tr('undecided')},
    ];

    return ScrollableFormPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrembleBackButton(label: tr('back'), onPressed: onBack),
          const SizedBox(height: 24),
          StepHeader(tr('who_looking_for')),
          const SizedBox(height: 24),
          ...opts.map((o) => OptionPill(
                label: o['label']!,
                selected: datingPreference == o['key'],
                onTap: () => onPreferenceChanged(o['key']),
              )),
          const SizedBox(height: 32),
          StepHeader(tr('age_range')),
          const SizedBox(height: 16),
          RangeSlider(
            values: ageRangePref,
            min: 18,
            max: 65,
            divisions: 47,
            labels: RangeLabels(
              '${ageRangePref.start.round()}',
              '${ageRangePref.end.round()}',
            ),
            onChanged: onAgeRangeChanged,
            activeColor: kBrandRose,
            inactiveColor:
                isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 24),
          ContinueButton(
            enabled: datingPreference != null,
            onTap: onContinue,
            label: tr('continue_btn'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
