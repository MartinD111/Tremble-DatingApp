import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PreferenceRangeSlider — unified two-way RangeSlider with label + edit icon.
//
// - label: section label text
// - valueLabel: formatted current range string (e.g. "30 – 45")
// - min/max/divisions: slider bounds
// - start/end: current range values
// - startLabel/endLabel: printed below the slider at each end
// - labelMapper: optional fn mapping a raw value → tooltip text (e.g. introvert)
// - onChanged: called on every drag (fires updateProfile)
// - onEdit: called when the pencil icon is tapped (opens modal editor)
// - isPremium: shows lock icon; if true caller must guard interaction
// ─────────────────────────────────────────────────────────────────────────────

class PreferenceRangeSlider extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double min;
  final double max;
  final int? divisions;
  final double start;
  final double end;
  final String? startLabel;
  final String? endLabel;
  final String Function(double)? labelMapper;
  final ValueChanged<RangeValues> onChanged;
  final VoidCallback? onEdit;
  final bool isPremium;

  const PreferenceRangeSlider({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.min,
    required this.max,
    required this.start,
    required this.end,
    required this.onChanged,
    this.divisions,
    this.startLabel,
    this.endLabel,
    this.labelMapper,
    this.onEdit,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    const brandRose = Color(0xFFF4436C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: label + value + edit icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.white)),
                if (isPremium) ...[
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.lock,
                      size: 14, color: Colors.amber),
                ],
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(valueLabel,
                    style:
                        const TextStyle(color: Colors.white70)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: const Icon(LucideIcons.pencil,
                        size: 14, color: Colors.white54),
                  ),
                ),
              ],
            ),
          ],
        ),
        RangeSlider(
          values: RangeValues(start, end),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: brandRose,
          inactiveColor: Colors.white24,
          labels: RangeLabels(
            labelMapper != null
                ? labelMapper!(start)
                : start.round().toString(),
            labelMapper != null
                ? labelMapper!(end)
                : end.round().toString(),
          ),
          onChanged: onChanged,
        ),
        if (startLabel != null || endLabel != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  startLabel ?? '',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                ),
                Text(
                  endLabel ?? '',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
