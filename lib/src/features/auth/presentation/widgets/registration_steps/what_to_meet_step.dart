import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class WhatToMeetStep extends StatelessWidget {
  const WhatToMeetStep({
    super.key,
    required this.wantToMeet,
    required this.onToggle,
    required this.onBack,
    required this.onContinue,
    required this.tr,
  });

  final List<String> wantToMeet;
  final void Function(String key) onToggle;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final String Function(String) tr;

  @override
  Widget build(BuildContext context) {
    final opts = <Map<String, Object>>[
      {'key': 'male', 'label': tr('gender_male'), 'icon': Icons.male},
      {'key': 'female', 'label': tr('gender_female'), 'icon': Icons.female},
      {
        'key': 'non_binary',
        'label': tr('non_binary'),
        'icon': LucideIcons.userX
      },
    ];

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
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
                StepHeader(tr('what_to_meet_title')),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...opts.map((o) {
                    final k = o['key'] as String;
                    final sel = wantToMeet.contains(k);
                    return OptionPill(
                      label: o['label'] as String,
                      selected: sel,
                      icon: o['icon'] as IconData,
                      onTap: () => onToggle(k),
                    );
                  }),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ContinueButton(
              enabled: wantToMeet.isNotEmpty,
              onTap: onContinue,
              label: tr('continue_btn'),
            ),
          ),
        ],
      ),
    );
  }
}
