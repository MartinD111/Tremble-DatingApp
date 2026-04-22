import 'package:flutter/material.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class HeightStep extends StatelessWidget {
  const HeightStep({
    super.key,
    required this.heightCm,
    required this.isMetric,
    required this.onHeightChanged,
    required this.onMetricToggle,
    required this.onContinueTap,
    required this.onBack,
    required this.tr,
  });

  /// Current height in centimetres (always stored as cm internally).
  final int heightCm;

  /// Whether the UI shows cm (true) or ft/in (false).
  final bool isMetric;

  /// Called with new height in cm whenever the picker scrolls.
  final ValueChanged<int> onHeightChanged;

  /// Called with the new metric flag when the cm/ft toggle changes.
  final ValueChanged<bool> onMetricToggle;

  /// Called when Continue is tapped — parent shows partner-height modal.
  final VoidCallback onContinueTap;
  final VoidCallback onBack;
  final String Function(String) tr;

  // ── ft/in item list ──────────────────────────────────────────────────────
  static List<String> _buildFtInItems() {
    final items = <String>[];
    for (int f = 4; f <= 8; f++) {
      for (int i = 0; i < 12; i++) {
        if (f == 8 && i > 2) break; // max ~8'2"
        items.add('$f\'$i"');
      }
    }
    return items;
  }

  // ── cm → ft/in index ─────────────────────────────────────────────────────
  static int _ftInIndex(int cm, List<String> ftInItems) {
    int ft = (cm / 30.48).floor();
    int inc = ((cm / 2.54) - (ft * 12)).round();
    if (inc == 12) {
      ft++;
      inc = 0;
    }
    final idx = ftInItems.indexOf('$ft\'$inc"');
    return idx == -1 ? ftInItems.indexOf('5\'7"') : idx;
  }

  @override
  Widget build(BuildContext context) {
    final cmItems = List.generate(121, (i) => '${130 + i}');
    final ftInItems = _buildFtInItems();

    int cmIndex = cmItems.indexOf('$heightCm');
    if (cmIndex == -1) cmIndex = cmItems.indexOf('170');

    final ftInIndex = _ftInIndex(heightCm, ftInItems);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final toggleBgColor =
        isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05);

    return ScrollableFormPage(
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
          StepHeader(tr('whats_your_height')),
          const SizedBox(height: 48),

          // ── cm / ft toggle ─────────────────────────────────────────────
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: toggleBgColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ToggleButton(
                    label: tr('height_cm'),
                    active: isMetric,
                    isDark: isDark,
                    onTap: () => onMetricToggle(true),
                  ),
                  _ToggleButton(
                    label: tr('height_ft_in'),
                    active: !isMetric,
                    isDark: isDark,
                    onTap: () => onMetricToggle(false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),

          // ── drum picker ────────────────────────────────────────────────
          SizedBox(
            height: 200,
            child: Center(
              child: isMetric
                  ? DrumPicker(
                      items: cmItems,
                      selectedIndex: cmIndex,
                      onChanged: (i) => onHeightChanged(int.parse(cmItems[i])),
                    )
                  : DrumPicker(
                      items: ftInItems,
                      selectedIndex: ftInIndex,
                      onChanged: (i) {
                        final str = ftInItems[i];
                        final parts = str.split('\'');
                        final feet = int.parse(parts[0]);
                        final inches = int.parse(parts[1].replaceAll('"', ''));
                        onHeightChanged(((feet * 12 + inches) * 2.54).round());
                      },
                    ),
            ),
          ),
          ContinueButton(
            enabled: true,
            label: tr('continue_btn'),
            onTap: onContinueTap,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOGGLE BUTTON — cm / ft pill switch
// ─────────────────────────────────────────────────────────────────────────────
class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active
                ? Colors.black
                : (isDark ? Colors.white70 : Colors.black54),
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
