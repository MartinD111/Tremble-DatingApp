import 'package:flutter/material.dart';
import 'sub_screen_step.dart';

class ReligionStep extends StatelessWidget {
  const ReligionStep({
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
      title: tr('religion'),
      options: [
        {'key': 'christianity', 'label': tr('christianity')},
        {'key': 'islam', 'label': tr('islam')},
        {'key': 'hinduism', 'label': tr('hinduism')},
        {'key': 'buddhism', 'label': tr('buddhism')},
        {'key': 'judaism', 'label': tr('judaism')},
        {'key': 'agnostic', 'label': tr('agnostic')},
        {'key': 'atheist', 'label': tr('atheist')},
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
