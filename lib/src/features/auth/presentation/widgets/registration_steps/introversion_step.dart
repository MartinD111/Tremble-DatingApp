import 'package:flutter/material.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class IntroversionStep extends StatelessWidget {
  const IntroversionStep({
    super.key,
    required this.values,
    required this.onChanged,
    required this.onBack,
    required this.onContinueTap,
    required this.tr,
  });

  /// Range from 0.0 (full introvert) to 1.0 (full extrovert).
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;
  final VoidCallback onBack;

  /// Called when Continue is tapped. Parent is responsible for showing
  /// the partner-range modal and then advancing the page.
  final VoidCallback onContinueTap;
  final String Function(String) tr;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TrembleBackButton(onPressed: onBack, label: tr('back')),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                StepHeader(tr('introversion')),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr('introvert'),
                        style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54),
                      ),
                      Text(
                        tr('extrovert'),
                        style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: values,
                    onChanged: onChanged,
                    divisions: 20,
                    activeColor: Theme.of(context).colorScheme.primary,
                    inactiveColor: isDark
                        ? Colors.white12
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      () {
                        final startPct = (values.start * 100).toInt();
                        final endPct = (values.end * 100).toInt();
                        final avg = (startPct + endPct) / 2;
                        String label = 'Ambivert';
                        if (avg <= 40) label = tr('introvert');
                        if (avg >= 60) label = tr('extrovert');
                        return '$startPct% – $endPct% $label';
                      }(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ContinueButton(
              enabled: true,
              label: tr('continue_btn'),
              onTap: onContinueTap,
            ),
          ),
        ],
      ),
    );
  }
}
