import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'sub_screen_step.dart';

class SleepStep extends StatelessWidget {
  const SleepStep({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onBack,
    required this.onNext,
    required this.onSavePartner,
    required this.tr,
  });

  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final ValueChanged<List<String>?> onSavePartner;
  final String Function(String) tr;

  @override
  Widget build(BuildContext context) {
    return SubScreenStep(
      title: tr('sleep'),
      options: [
        {
          'key': 'night_owl',
          'label': tr('night_owl'),
          'icon': LucideIcons.moon,
        },
        {
          'key': 'early_bird',
          'label': tr('early_bird'),
          'icon': LucideIcons.sun,
        },
      ],
      selected: selected,
      onSelect: onSelect,
      onBack: onBack,
      onNext: onNext,
      showCustomPartnerPref: false,
      onSavePartner: onSavePartner,
      tr: tr,
    );
  }
}
