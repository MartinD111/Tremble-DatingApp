import 'package:flutter/material.dart';
import '../../../../../core/utils/icon_utils.dart';
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
        {'key': 'christianity', 'label': tr('christianity'), 'icon': IconUtils.getReligionIcon('christianity')},
        {'key': 'islam', 'label': tr('islam'), 'icon': IconUtils.getReligionIcon('islam')},
        {'key': 'hinduism', 'label': tr('hinduism'), 'icon': IconUtils.getReligionIcon('hinduism')},
        {'key': 'buddhism', 'label': tr('buddhism'), 'icon': IconUtils.getReligionIcon('buddhism')},
        {'key': 'judaism', 'label': tr('judaism'), 'icon': IconUtils.getReligionIcon('judaism')},
        {'key': 'agnostic', 'label': tr('agnostic'), 'icon': IconUtils.getReligionIcon('agnostic')},
        {'key': 'atheist', 'label': tr('atheist'), 'icon': IconUtils.getReligionIcon('atheist')},
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
