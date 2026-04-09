import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'sub_screen_step.dart';

class DrinkingStep extends StatelessWidget {
  const DrinkingStep({
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
      title: tr('do_you_drink'),
      options: [
        {
          'key': 'socially',
          'label': tr('drink_socially'),
          'icon': LucideIcons.users
        },
        {'key': 'never', 'label': tr('drink_never'), 'icon': LucideIcons.ban},
        {
          'key': 'frequently',
          'label': tr('drink_frequently'),
          'icon': LucideIcons.trendingUp
        },
      ],
      selected: selected,
      onSelect: onSelect,
      onBack: onBack,
      onNext: onNext,
      onSavePartner: onSavePartner,
      tr: tr,
    );
  }
}
