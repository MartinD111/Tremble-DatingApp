import 'package:flutter/material.dart';
import 'sub_screen_step.dart';

class EthnicityStep extends StatelessWidget {
  const EthnicityStep({
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
      title: tr('ethnicity'),
      options: [
        {'key': 'white', 'label': tr('ethnicity_white')},
        {'key': 'black', 'label': tr('ethnicity_black')},
        {'key': 'mixed', 'label': tr('ethnicity_mixed')},
        {'key': 'asian', 'label': tr('ethnicity_asian')},
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
