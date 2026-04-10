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

    return ScrollableFormPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrembleBackButton(label: tr('back'), onPressed: onBack),
          const SizedBox(height: 24),
          StepHeader(tr('what_to_meet_title')),
          const SizedBox(height: 36),
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
          const SizedBox(height: 24),
          ContinueButton(
            enabled: wantToMeet.isNotEmpty,
            onTap: onContinue,
            label: tr('continue_btn'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
