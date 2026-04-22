import 'package:flutter/material.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import '../../../../../core/utils/icon_utils.dart';
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
      {
        'key': 'short_term_fun',
        'label': tr('short_term_fun'),
        'icon': IconUtils.getLookingForIcon('short_term_fun')
      },
      {
        'key': 'long_term_partner',
        'label': tr('long_term_partner'),
        'icon': IconUtils.getLookingForIcon('long_term_partner')
      },
      {
        'key': 'short_open_long',
        'label': tr('short_open_long'),
        'icon': IconUtils.getLookingForIcon('short_open_long')
      },
      {
        'key': 'long_open_short',
        'label': tr('long_open_short'),
        'icon': IconUtils.getLookingForIcon('long_open_short')
      },
    ];

    return ScrollableFormPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TrembleBackButton(onPressed: onBack, label: tr('back')),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          StepHeader(tr('who_looking_for')),
          const SizedBox(height: 24),
          ...opts.map((o) => OptionPill(
                label: o['label'] as String,
                icon: o['icon'] as IconData?,
                selected: datingPreference == o['key'],
                onTap: () => onPreferenceChanged(o['key'] as String),
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
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor:
                isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${ageRangePref.start.round()}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                Text(
                  '—',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                Text(
                  '${ageRangePref.end.round()}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
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
