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
  final IconData? icon;
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
  final ValueChanged<RangeValues>? onChanged;
  final VoidCallback? onEdit;
  final bool isPremium;

  const PreferenceRangeSlider({
    super.key,
    this.icon,
    required this.label,
    required this.valueLabel,
    required this.min,
    required this.max,
    required this.start,
    required this.end,
    this.onChanged,
    this.divisions,
    this.startLabel,
    this.endLabel,
    this.labelMapper,
    this.onEdit,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final brandRose = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white : const Color(0xFF1A1A18);
    final valueColor =
        isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black54;
    final endLabelColor =
        isDark ? Colors.white.withValues(alpha: 0.38) : Colors.black38;
    final sliderInactive =
        isDark ? Colors.white.withValues(alpha: 0.24) : Colors.black12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: label + value + edit icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon,
                            size: 18, color: labelColor.withValues(alpha: 0.6)),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: labelColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: EdgeInsets.only(left: icon != null ? 28 : 0),
                    child: Text(
                      valueLabel,
                      style: TextStyle(
                        color: valueColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF2A2A2E)
                      : const Color(0xFFE8ECF0),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2A2A2E).withValues(alpha: 0.6)
                        : const Color(0xFFE8ECF0).withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  LucideIcons.pencil,
                  size: 16,
                  color: brandRose,
                ),
              ),
            ),
          ],
        ),
        AbsorbPointer(
          absorbing: onChanged == null,
          child: RangeSlider(
            values: RangeValues(start, end),
            min: min,
            max: max,
            divisions: divisions,
            activeColor: brandRose,
            inactiveColor: sliderInactive,
            labels: RangeLabels(
              labelMapper != null
                  ? labelMapper!(start)
                  : start.round().toString(),
              labelMapper != null ? labelMapper!(end) : end.round().toString(),
            ),
            onChanged: onChanged ?? (_) {},
          ),
        ),
        if (startLabel != null || endLabel != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(startLabel ?? '',
                    style: TextStyle(color: endLabelColor, fontSize: 11)),
                Text(endLabel ?? '',
                    style: TextStyle(color: endLabelColor, fontSize: 11)),
              ],
            ),
          ),
      ],
    );
  }
}
