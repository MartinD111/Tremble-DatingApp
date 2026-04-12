import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ─────────────────────────────────────────────────────────────────────────────
// showPreferenceEditModal — unified bottom-sheet modal for single-select
// preferences. Matches onboarding pill style (pill-shaped options, rose accent,
// checkmark on selected, brand typography).
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showPreferenceEditModal({
  required BuildContext context,
  required String title,
  required List<Map<String, String>> options,
  required String? currentValue,
  required ValueChanged<String> onUpdate,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _PreferenceEditSheet(
      title: title,
      options: options,
      currentValue: currentValue,
      onUpdate: (val) {
        onUpdate(val);
        Navigator.pop(ctx);
      },
    ),
  );
}

class _PreferenceEditSheet extends StatelessWidget {
  final String title;
  final List<Map<String, String>> options;
  final String? currentValue;
  final ValueChanged<String> onUpdate;

  const _PreferenceEditSheet({
    required this.title,
    required this.options,
    required this.currentValue,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, 40 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            title,
            style: GoogleFonts.instrumentSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          // Options
          ...options.map((opt) {
            final isSelected = opt['value'] == currentValue;
            return GestureDetector(
              onTap: () => onUpdate(opt['value']!),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFF4436C).withValues(alpha: 0.15)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFF4436C)
                        : (isDark ? Colors.white24 : Colors.black12),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      opt['label']!,
                      style: GoogleFonts.instrumentSans(
                        color: textColor,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(
                        LucideIcons.checkCircle,
                        color: Color(0xFFF4436C),
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// showSliderEditModal — bottom-sheet modal with a dual-point RangeSlider.
// Matches the onboarding partner-preference modal visual style.
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showSliderEditModal({
  required BuildContext context,
  required String title,
  required double min,
  required double max,
  required RangeValues current,
  required ValueChanged<RangeValues> onSave,
  int? divisions,
  String? startLabel,
  String? endLabel,
  String Function(double)? labelMapper,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _SliderEditSheet(
      title: title,
      min: min,
      max: max,
      current: current,
      divisions: divisions,
      startLabel: startLabel,
      endLabel: endLabel,
      labelMapper: labelMapper,
      onSave: (v) {
        onSave(v);
        Navigator.pop(ctx);
      },
    ),
  );
}

class _SliderEditSheet extends StatefulWidget {
  final String title;
  final double min;
  final double max;
  final RangeValues current;
  final int? divisions;
  final String? startLabel;
  final String? endLabel;
  final String Function(double)? labelMapper;
  final ValueChanged<RangeValues> onSave;

  const _SliderEditSheet({
    required this.title,
    required this.min,
    required this.max,
    required this.current,
    required this.onSave,
    this.divisions,
    this.startLabel,
    this.endLabel,
    this.labelMapper,
  });

  @override
  State<_SliderEditSheet> createState() => _SliderEditSheetState();
}

class _SliderEditSheetState extends State<_SliderEditSheet> {
  late RangeValues _values;

  @override
  void initState() {
    super.initState();
    _values = widget.current;
  }

  String _label(double v) =>
      widget.labelMapper != null ? widget.labelMapper!(v) : v.round().toString();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    const brandRose = Color(0xFFF4436C);

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, 40 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.title,
            style: GoogleFonts.instrumentSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          if (widget.startLabel != null || widget.endLabel != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.startLabel ?? '',
                      style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontSize: 12)),
                  Text(widget.endLabel ?? '',
                      style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontSize: 12)),
                ],
              ),
            ),
          RangeSlider(
            values: _values,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            activeColor: brandRose,
            inactiveColor: isDark ? Colors.white12 : Colors.black12,
            labels: RangeLabels(_label(_values.start), _label(_values.end)),
            onChanged: (v) => setState(() => _values = v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: isDark ? Colors.white38 : Colors.black26),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRose,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () => widget.onSave(_values),
                  child: const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// showMultiSelectModal — bottom-sheet modal for multi-value selection.
// Shows all options as pill rows with checkmarks. Edit button in top-right.
// Returns the updated selection via [onSave].
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showMultiSelectModal({
  required BuildContext context,
  required String title,
  required List<Map<String, String>> options,
  required List<String> currentValues,
  required ValueChanged<List<String>> onSave,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _MultiSelectSheet(
      title: title,
      options: options,
      currentValues: currentValues,
      onSave: (v) {
        onSave(v);
        Navigator.pop(ctx);
      },
    ),
  );
}

class _MultiSelectSheet extends StatefulWidget {
  final String title;
  final List<Map<String, String>> options;
  final List<String> currentValues;
  final ValueChanged<List<String>> onSave;

  const _MultiSelectSheet({
    required this.title,
    required this.options,
    required this.currentValues,
    required this.onSave,
  });

  @override
  State<_MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends State<_MultiSelectSheet> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.currentValues);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    const brandRose = Color(0xFFF4436C);

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, 40 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Title row with Edit (Save) button top-right
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => widget.onSave(_selected),
                child: Text(
                  'Save',
                  style: GoogleFonts.instrumentSans(
                    color: brandRose,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Options
          ...widget.options.map((opt) {
            final value = opt['value']!;
            final isSelected = _selected.contains(value);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selected.remove(value);
                  } else {
                    _selected.add(value);
                  }
                });
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? brandRose.withValues(alpha: 0.15)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected
                        ? brandRose
                        : (isDark ? Colors.white24 : Colors.black12),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      opt['label']!,
                      style: GoogleFonts.instrumentSans(
                        color: textColor,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(LucideIcons.checkCircle,
                          color: Color(0xFFF4436C), size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
