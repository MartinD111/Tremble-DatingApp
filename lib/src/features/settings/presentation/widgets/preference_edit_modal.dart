import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/ui/discard_changes_modal.dart';
import '../../../../shared/ui/center_notification.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../../core/translations.dart';
import '../../../../core/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// showPreferenceEditModal — unified bottom-sheet modal for single-select
// preferences. Stateful: tap highlights pending selection, explicit Save/Cancel
// buttons confirm or discard. Includes "Vseeno mi je" (clear to null) and
// optional "Po meri" (custom multi-select) rows.
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showPreferenceEditModal({
  required BuildContext context,
  required String title,
  required List<Map<String, dynamic>> options,
  required String? currentValue,
  required ValueChanged<String?> onUpdate,
  required AuthUser user,
  IconData? rowIcon,
  List<Map<String, dynamic>>? allOptions,
  ValueChanged<String>? onCustom,
  bool allowOther = false,
  String? otherValue,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _PreferenceEditSheet(
      title: title,
      options: options,
      currentValue: currentValue,
      outerContext: context,
      rowIcon: rowIcon,
      allOptions: allOptions,
      onUpdate: onUpdate,
      onCustom: onCustom,
      allowOther: allowOther,
      otherValue: otherValue,
      user: user,
      isGenderBased: user.isGenderBasedColor,
      gender: user.gender,
    ),
  );
}

class _PreferenceEditSheet extends ConsumerStatefulWidget {
  final String title;
  final List<Map<String, dynamic>> options;
  final String? currentValue;
  final BuildContext outerContext;
  final IconData? rowIcon;
  final List<Map<String, dynamic>>? allOptions;
  final ValueChanged<String?> onUpdate;
  final ValueChanged<String>? onCustom;
  final bool allowOther;
  final String? otherValue;
  final AuthUser user;
  final bool isGenderBased;
  final String? gender;

  const _PreferenceEditSheet({
    required this.title,
    required this.options,
    required this.currentValue,
    required this.outerContext,
    required this.onUpdate,
    required this.user,
    this.rowIcon,
    this.allOptions,
    this.onCustom,
    this.allowOther = false,
    this.otherValue,
    this.isGenderBased = false,
    this.gender,
  });

  @override
  ConsumerState<_PreferenceEditSheet> createState() =>
      _PreferenceEditSheetState();
}

class _PreferenceEditSheetState extends ConsumerState<_PreferenceEditSheet> {
  static const _none = '__none__';
  static const _somethingElse = 'something_else';
  String? _pending;
  late TextEditingController _otherController;

  @override
  void initState() {
    super.initState();
    final isKnown =
        widget.options.any((o) => o['value'] == widget.currentValue) ||
            widget.currentValue == null ||
            widget.currentValue == _none;

    if (widget.allowOther && !isKnown && widget.currentValue != null) {
      _pending = _somethingElse;
      _otherController = TextEditingController(text: widget.currentValue);
    } else {
      _pending = widget.currentValue;
      _otherController = TextEditingController(text: widget.otherValue);
    }
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  /// Splits a comma-joined custom value back into a list for multi-select.
  List<String> get _currentAsMulti {
    final v = widget.currentValue;
    if (v == null || v.isEmpty) return [];
    return v.split(',');
  }

  void _openCustom() {
    final outer = widget.outerContext;
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (outer.mounted) {
        showMultiSelectModal(
          context: outer,
          title: widget.title,
          options: widget.allOptions!,
          currentValues: _currentAsMulti,
          onSave: (vals) => widget.onCustom?.call(vals.join(',')),
        );
      }
    });
  }

  Widget _optionPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isMuted = false,
    bool showArrow = false,
    bool isRoseLabel = false,
    required bool isDark,
    required Color textColor,
    IconData? icon,
    Color? iconColor,
  }) {
    final brandRose = Theme.of(context).colorScheme.primary;
    final pillBg = TrembleTheme.getPillColor(
      isDark: isDark,
      isGenderBased: widget.isGenderBased,
      gender: widget.gender,
    );
    final labelColor = isRoseLabel
        ? brandRose
        : isSelected
            ? brandRose
            : isMuted
                ? (isDark ? Colors.white54 : Colors.black45)
                : textColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? brandRose.withValues(alpha: 0.15) : pillBg,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? brandRose
                : (isDark ? const Color(0xFF3A3A3E) : const Color(0xFFD8DCE0)),
          ),
        ),
        child: Row(
          children: [
            // Icon — shown when provided (rowIcon from the row, or per-option)
            if (icon != null) ...[
              Icon(icon,
                  size: 20,
                  color: isSelected
                      ? brandRose
                      : (iconColor ??
                          (isDark ? Colors.white : Colors.black87))),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.instrumentSans(
                  color: labelColor,
                  fontWeight: isSelected || isRoseLabel
                      ? FontWeight.bold
                      : isMuted
                          ? FontWeight.w400
                          : FontWeight.w500,
                  // Never italic — removed per design spec
                  fontStyle: FontStyle.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.checkCircle, color: brandRose, size: 20),
            if (showArrow)
              Icon(LucideIcons.chevronRight,
                  color: isDark ? Colors.white38 : Colors.black26, size: 18),
          ],
        ),
      ),
    );
  }

  bool _hasChanges() {
    final baseChanged = _pending != widget.currentValue;
    if (_pending == _somethingElse) {
      return _otherController.text != widget.currentValue;
    }
    return baseChanged;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final brandRose = Theme.of(context).colorScheme.primary;
    final lang = ref.watch(authStateProvider)?.appLanguage ?? 'en';

    final bgColor = isDark ? const Color(0xFF2A2A2E) : Colors.white;

    final hasChanges = _hasChanges();
    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final res = await showDiscardChangesModal(context, ref);
        if (res == 'save') {
          final changedValue = _pending == _none
              ? null
              : (_pending == _somethingElse ? _otherController.text : _pending);
          widget.onUpdate(changedValue);
          final lang = ref.read(authStateProvider)?.appLanguage ?? 'en';
          CenterNotification.show(
            context: context,
            message: t('Profile updated', lang),
          );
          if (context.mounted) Navigator.pop(context);
        } else if (res == 'discard') {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Container(
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, 40 + MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: bgColor,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.rowIcon != null) ...[
                    Icon(widget.rowIcon,
                        size: 20, color: textColor.withValues(alpha: 0.7)),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.title,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Regular options — full-width list
              ...widget.options.map((opt) => _optionPill(
                    label: opt['label'] as String,
                    isSelected: opt['value'] == _pending,
                    onTap: () =>
                        setState(() => _pending = opt['value'] as String?),
                    isDark: isDark,
                    textColor: textColor,
                    icon: opt['icon'] as IconData? ?? widget.rowIcon,
                    iconColor: opt['iconColor'] as Color?,
                  )),
              // "Vseeno mi je" — clears the preference
              _optionPill(
                label: t('partner_pref_idc', lang),
                isSelected: _pending == _none,
                onTap: () => setState(() => _pending = _none),
                isMuted: true,
                isDark: isDark,
                textColor: textColor,
              ),
              // "Other" — custom text input
              if (widget.allowOther) ...[
                _optionPill(
                  label: t('something_else', lang),
                  isSelected: _pending == _somethingElse,
                  onTap: () => setState(() => _pending = _somethingElse),
                  isMuted: true,
                  isDark: isDark,
                  textColor: textColor,
                ),
                if (_pending == _somethingElse)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: TextField(
                      controller: _otherController,
                      autofocus: true,
                      style: GoogleFonts.instrumentSans(color: textColor),
                      decoration: InputDecoration(
                        hintText: t('write_answer', lang),
                        hintStyle: TextStyle(
                            color: isDark ? Colors.white30 : Colors.black38),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(
                              color: isDark ? Colors.white12 : Colors.black12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: brandRose, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
              ],
              // "Po meri" — opens multi-select (only when allOptions provided)
              if (widget.allOptions != null)
                _optionPill(
                  label: t('partner_pref_custom', lang),
                  isSelected: false,
                  onTap: _openCustom,
                  isMuted: true,
                  showArrow: true,
                  isRoseLabel: true,
                  isDark: isDark,
                  textColor: textColor,
                ),
              const SizedBox(height: 8),
              // Save / Cancel
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
                        t('cancel', lang),
                        style: GoogleFonts.instrumentSans(
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
                      onPressed: () {
                        final finalVal = _pending == _none
                            ? null
                            : (_pending == _somethingElse
                                ? _otherController.text
                                : _pending);
                        widget.onUpdate(finalVal);
                        CenterNotification.show(
                          context: context,
                          message: t('Profile updated', lang),
                        );
                        Navigator.pop(context);
                      },
                      child: Text(t('save', lang),
                          style: GoogleFonts.instrumentSans(
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          )),
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
  String? unit,
  bool isGenderBased = false,
  String? gender,
  IconData? rowIcon,
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
      unit: unit,
      isGenderBased: isGenderBased,
      gender: gender,
      rowIcon: rowIcon,
      onSave: (v) {
        onSave(v);
        Navigator.pop(ctx);
      },
    ),
  );
}

class _SliderEditSheet extends ConsumerStatefulWidget {
  final String title;
  final double min;
  final double max;
  final RangeValues current;
  final int? divisions;
  final String? startLabel;
  final String? endLabel;
  final String Function(double)? labelMapper;
  final String? unit;
  final ValueChanged<RangeValues> onSave;
  final bool isGenderBased;
  final String? gender;
  final IconData? rowIcon;

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
    this.unit,
    this.isGenderBased = false,
    this.gender,
    this.rowIcon,
  });

  @override
  ConsumerState<_SliderEditSheet> createState() => _SliderEditSheetState();
}

class _SliderEditSheetState extends ConsumerState<_SliderEditSheet> {
  late RangeValues _values;

  @override
  void initState() {
    super.initState();
    _values = widget.current;
  }

  String _label(double v) => widget.labelMapper != null
      ? widget.labelMapper!(v)
      : v.round().toString();

  bool _hasChanges() => _values != widget.current;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final brandRose = Theme.of(context).colorScheme.primary;
    final lang = ref.watch(authStateProvider)?.appLanguage ?? 'en';

    final hasChanges = _hasChanges();
    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final res = await showDiscardChangesModal(context, ref);
        if (res == 'save') {
          widget.onSave(_values);
          final lang = ref.read(authStateProvider)?.appLanguage ?? 'en';
          CenterNotification.show(
            context: context,
            message: t('Profile updated', lang),
          );
          if (context.mounted) Navigator.pop(context);
        } else if (res == 'discard') {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Container(
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, 40 + MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2E) : Colors.white,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.rowIcon != null) ...[
                    Icon(widget.rowIcon,
                        size: 20, color: textColor.withValues(alpha: 0.7)),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.title,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Live range display
              Text(
                '${_label(_values.start)} – ${_label(_values.end)}${widget.unit ?? ''}',
                style: GoogleFonts.instrumentSans(
                  fontSize: 16,
                  color: brandRose,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
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
                        t('cancel', lang),
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
                      child: Text(t('save', lang),
                          style: GoogleFonts.instrumentSans(
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          )),
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
  required List<Map<String, dynamic>> options,
  required List<String> currentValues,
  required ValueChanged<List<String>> onSave,
  IconData? rowIcon,
  bool isGenderBased = false,
  String? gender,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _MultiSelectSheet(
      title: title,
      options: options,
      currentValues: currentValues,
      rowIcon: rowIcon,
      isGenderBased: isGenderBased,
      gender: gender,
      onSave: (v) {
        onSave(v);
        Navigator.pop(ctx);
      },
    ),
  );
}

class _MultiSelectSheet extends ConsumerStatefulWidget {
  final String title;
  final List<Map<String, dynamic>> options;
  final List<String> currentValues;
  final ValueChanged<List<String>> onSave;
  final IconData? rowIcon;
  final bool isGenderBased;
  final String? gender;

  const _MultiSelectSheet({
    required this.title,
    required this.options,
    required this.currentValues,
    required this.onSave,
    this.rowIcon,
    this.isGenderBased = false,
    this.gender,
  });

  @override
  ConsumerState<_MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends ConsumerState<_MultiSelectSheet> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.currentValues);
  }

  bool _hasChanges() {
    if (_selected.length != widget.currentValues.length) return true;
    return !_selected.every((v) => widget.currentValues.contains(v));
  }

  Widget _optionPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
    IconData? icon,
    Color? iconColor,
  }) {
    final brandRose = Theme.of(context).colorScheme.primary;
    final pillBg = TrembleTheme.getPillColor(
      isDark: isDark,
      isGenderBased: widget.isGenderBased,
      gender: widget.gender,
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? brandRose.withValues(alpha: 0.15) : pillBg,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? brandRose
                : (isDark ? const Color(0xFF3A3A3E) : const Color(0xFFD8DCE0)),
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? brandRose
                    : (iconColor ?? (isDark ? Colors.white : Colors.black87)),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              label,
              style: GoogleFonts.instrumentSans(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(LucideIcons.checkCircle, color: brandRose, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final brandRose = Theme.of(context).colorScheme.primary;
    final lang = ref.watch(authStateProvider)?.appLanguage ?? 'en';

    final bgColor = isDark ? const Color(0xFF2A2A2E) : Colors.white;

    final hasChanges = _hasChanges();

    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final res = await showDiscardChangesModal(context, ref);
        if (res == 'save') {
          widget.onSave(_selected);
          if (context.mounted) Navigator.pop(context);
        } else if (res == 'discard') {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(
            24, 12, 24, 40 + MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: bgColor,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.rowIcon != null) ...[
                  Icon(widget.rowIcon,
                      size: 20, color: textColor.withValues(alpha: 0.7)),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.title,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Options
            ...widget.options.map((opt) {
              final value = opt['value']!;
              final isSelected = _selected.contains(value);
              return _optionPill(
                label: opt['label']!,
                icon: opt['icon'] as IconData?,
                iconColor: opt['iconColor'] as Color?,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selected.remove(value);
                    } else {
                      _selected.add(value);
                    }
                  });
                },
                isDark: isDark,
                textColor: textColor,
              );
            }),
            const SizedBox(height: 16),
            // Save / Cancel
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
                      t('cancel', lang),
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
                    onPressed: () => widget.onSave(_selected),
                    child: Text(t('save', lang),
                        style: GoogleFonts.instrumentSans(
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// showLanguageEditModal — single-select bottom-sheet with explicit Save/Cancel.
// Language is NOT applied until the user taps Save. Cancel dismisses with no
// side effects. This matches the spec requirement for an explicit confirm step.
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showLanguageEditModal({
  required BuildContext context,
  required String title,
  required List<Map<String, String>> options,
  required String? currentValue,
  required ValueChanged<String> onSave,
  bool isGenderBased = false,
  String? gender,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _LanguageEditSheet(
      title: title,
      options: options,
      currentValue: currentValue,
      isGenderBased: isGenderBased,
      gender: gender,
      onSave: (val) {
        onSave(val);
        Navigator.pop(ctx);
      },
      onCancel: () => Navigator.pop(ctx),
    ),
  );
}

class _LanguageEditSheet extends ConsumerStatefulWidget {
  final String title;
  final List<Map<String, String>> options;
  final String? currentValue;
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;
  final bool isGenderBased;
  final String? gender;

  const _LanguageEditSheet({
    required this.title,
    required this.options,
    required this.currentValue,
    required this.onSave,
    required this.onCancel,
    this.isGenderBased = false,
    this.gender,
  });

  @override
  ConsumerState<_LanguageEditSheet> createState() => _LanguageEditSheetState();
}

class _LanguageEditSheetState extends ConsumerState<_LanguageEditSheet> {
  late String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentValue;
  }

  bool _hasChanges() => _selected != widget.currentValue && _selected != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final brandRose = Theme.of(context).colorScheme.primary;
    final lang = ref.watch(authStateProvider)?.appLanguage ?? 'en';

    final bgColor = isDark ? const Color(0xFF2A2A2E) : Colors.white;

    final hasChanges = _hasChanges();
    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final res = await showDiscardChangesModal(context, ref);
        if (res == 'save') {
          widget.onSave(_selected!);
          final lang = ref.read(authStateProvider)?.appLanguage ?? 'en';
          CenterNotification.show(
            context: context,
            message: t('Profile updated', lang),
          );
          if (context.mounted) Navigator.pop(context);
        } else if (res == 'discard') {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Container(
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, 40 + MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: GoogleFonts.instrumentSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),
              // Options — tap selects as pending; does NOT apply until Save
              ...widget.options.map((opt) {
                final isSelected = opt['value'] == _selected;
                final pillBg = TrembleTheme.getPillColor(
                  isDark: isDark,
                  isGenderBased: widget.isGenderBased,
                  gender: widget.gender,
                );
                return GestureDetector(
                  onTap: () => setState(() => _selected = opt['value']),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? brandRose.withValues(alpha: 0.15)
                          : pillBg,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected
                            ? brandRose
                            : (isDark
                                ? const Color(0xFF3A3A3E)
                                : const Color(0xFFD8DCE0)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          opt['label']!,
                          style: GoogleFonts.instrumentSans(
                            color: textColor,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(LucideIcons.checkCircle,
                              color: brandRose, size: 20),
                      ],
                    ),
                  ),
                );
              }),
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
                      onPressed: widget.onCancel,
                      child: Text(
                        t('cancel', lang),
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
                      onPressed: _selected != null
                          ? () => widget.onSave(_selected!)
                          : null,
                      child: Text(t('save', lang),
                          style: GoogleFonts.instrumentSans(
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// showSelectedItemsModal — "View only" summary for multi-select fields (Item 13)
// ─────────────────────────────────────────────────────────────────────────────
Future<void> showSelectedItemsModal({
  required BuildContext context,
  required String title,
  required List<String> items,
  required String Function(String) formatter,
  required VoidCallback onEdit,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? Colors.white : Colors.black87;
  final brandRose = Theme.of(context).colorScheme.primary;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, 40 + MediaQuery.of(context).viewInsets.bottom),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: BoxDecoration(
        color: isDark
            ? TrembleTheme.getPillColor(
                isDark: true, isGenderBased: false, gender: null)
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onEdit();
                },
                child: Text(
                  'Edit',
                  style: GoogleFonts.instrumentSans(
                    color: brandRose,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No items selected.',
                      style: GoogleFonts.instrumentSans(
                          color: isDark ? Colors.white54 : Colors.black45),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final itemBg = isDark
                          ? const Color(0xFF2A2A2E)
                          : const Color(0xFFE8ECF0);
                      final itemBorder =
                          itemBg.withValues(alpha: isDark ? 0.6 : 0.4);
                      final itemTextColor =
                          isDark ? Colors.white : Colors.black87;

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: itemBg,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: itemBorder),
                        ),
                        child: Text(
                          formatter(items[index]),
                          style: GoogleFonts.instrumentSans(
                            color: itemTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}
