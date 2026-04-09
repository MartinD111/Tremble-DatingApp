import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'sub_screen_step.dart';

class ExerciseStep extends StatelessWidget {
  const ExerciseStep({
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
      title: tr('do_you_exercise'),
      options: [
        {
          'key': 'active',
          'label': tr('exercise_active'),
          'icon': LucideIcons.zap
        },
        {
          'key': 'sometimes',
          'label': tr('exercise_sometimes'),
          'icon': LucideIcons.activity
        },
        {
          'key': 'almost_never',
          'label': tr('almost_never'),
          'icon': LucideIcons.moon
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
