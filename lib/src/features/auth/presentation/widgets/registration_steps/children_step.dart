import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'sub_screen_step.dart';

class ChildrenStep extends StatelessWidget {
  const ChildrenStep({
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
      title: tr('do_you_want_children'),
      options: [
        {
          'key': 'want_someday',
          'label': tr('children_want_someday'),
          'icon': LucideIcons.heart,
        },
        {
          'key': 'dont_want',
          'label': tr('children_dont_want'),
          'icon': LucideIcons.ban,
        },
        {
          'key': 'have_and_want_more',
          'label': tr('children_have_and_want_more'),
          'icon': LucideIcons.users,
        },
        {
          'key': 'have_and_dont_want_more',
          'label': tr('children_have_and_dont_want_more'),
          'icon': LucideIcons.userCheck,
        },
        {
          'key': 'not_sure',
          'label': tr('children_not_sure'),
          'icon': LucideIcons.helpCircle,
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
