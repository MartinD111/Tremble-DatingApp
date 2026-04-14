import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class StatusStep extends StatelessWidget {
  const StatusStep({
    super.key,
    required this.status,
    required this.onStatusSelect,
    required this.occupationController,
    required this.onBack,
    required this.onNext,
    required this.tr,
  });

  final String? status;
  final ValueChanged<String> onStatusSelect;
  final TextEditingController occupationController;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final String Function(String) tr;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? Colors.white60 : Colors.black54;
    final borderColor = isDark ? Colors.white30 : Colors.black26;
    final borderFocusColor = isDark ? Colors.white : Colors.black;
    final textColor = isDark ? Colors.white : Colors.black87;

    return ScrollableFormPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                StepHeader(tr('status')),
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
          const SizedBox(height: 32),
          OptionPill(
            label: tr('student'),
            selected: status == 'student',
            onTap: () => onStatusSelect('student'),
          ),
          OptionPill(
            label: tr('employed'),
            selected: status == 'employed',
            onTap: () => onStatusSelect('employed'),
          ),
          if (status == 'student' || status == 'employed') ...[
            const SizedBox(height: 16),
            TextField(
              controller: occupationController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: status == 'student'
                    ? 'Course of Study (Optional)'
                    : 'Job Title (Optional)',
                labelStyle: GoogleFonts.instrumentSans(color: hintColor),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide(color: borderFocusColor, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ContinueButton(
            enabled: status != null,
            onTap: onNext,
            label: tr('continue_btn'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
