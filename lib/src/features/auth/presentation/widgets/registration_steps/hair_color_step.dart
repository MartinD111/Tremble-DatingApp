import 'package:flutter/material.dart';
import '../../../../../core/utils/icon_utils.dart';
import 'sub_screen_step.dart';

class HairColorStep extends StatelessWidget {
  const HairColorStep({
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
      title: tr('hair_color'),
      options: [
        {'key': 'blonde', 'label': tr('hair_blonde'), 'icon': Icons.circle, 'iconColor': IconUtils.getHairColor('blonde')},
        {'key': 'brunette', 'label': tr('hair_brunette'), 'icon': Icons.circle, 'iconColor': IconUtils.getHairColor('brunette')},
        {'key': 'black', 'label': tr('hair_black'), 'icon': Icons.circle, 'iconColor': IconUtils.getHairColor('black')},
        {'key': 'red', 'label': tr('hair_red'), 'icon': Icons.circle, 'iconColor': IconUtils.getHairColor('red')},
        {'key': 'gray_white', 'label': tr('hair_gray_white'), 'icon': Icons.circle, 'iconColor': IconUtils.getHairColor('gray_white')},
        {'key': 'other', 'label': tr('hair_other'), 'icon': Icons.circle, 'iconColor': IconUtils.getHairColor('other')},
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
