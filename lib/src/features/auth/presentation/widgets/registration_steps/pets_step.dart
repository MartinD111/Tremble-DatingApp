import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class PetsStep extends StatelessWidget {
  const PetsStep({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.customPetController,
    required this.onBack,
    required this.onContinueTap,
    required this.tr,
  });

  final String? selected;
  final ValueChanged<String> onSelect;
  final TextEditingController customPetController;
  final VoidCallback onBack;

  /// Called when Continue is tapped. Parent is responsible for showing
  /// the partner-preference modal and then advancing the page.
  final VoidCallback onContinueTap;
  final String Function(String) tr;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScrollableFormPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                StepHeader(tr('pets')),
                Positioned(
                  left: 0,
                  top: 0,
                  child: TrembleBackButton(
                    onPressed: onBack,
                    label: tr('back'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OptionPill(
            label: tr('dog_person'),
            selected: selected == 'dog',
            onTap: () => onSelect('dog'),
          ),
          OptionPill(
            label: tr('cat_person'),
            selected: selected == 'cat',
            onTap: () => onSelect('cat'),
          ),
          OptionPill(
            label: tr('something_else'),
            selected: selected == 'something_else',
            onTap: () => onSelect('something_else'),
          ),
          if (selected == 'something_else')
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: customPetController,
                style: GoogleFonts.instrumentSans(
                    color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: tr('write_answer'),
                  hintStyle: GoogleFonts.instrumentSans(
                      color: isDark ? Colors.white30 : Colors.black38),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: BorderSide(
                        color: isDark ? Colors.white30 : Colors.black26),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: BorderSide(
                        color: isDark ? Colors.white : Colors.black, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ),
          OptionPill(
            label: tr('nothing'),
            selected: selected == 'nothing',
            onTap: () => onSelect('nothing'),
          ),
          const SizedBox(height: 24),
          ContinueButton(
            enabled: selected != null,
            label: tr('continue_btn'),
            onTap: onContinueTap,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
