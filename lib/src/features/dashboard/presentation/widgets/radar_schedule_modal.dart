import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme.dart';
import '../../../../core/translations.dart';
import '../../../auth/data/auth_repository.dart';
import '../../application/radar_schedule_controller.dart';

/// Bottom-sheet modal for configuring the weekly radar auto-activation schedule.
///
/// Visual contract follows `preference_edit_modal.dart` (Lifestyle edit) — solid
/// surface, pill-shaped option rows, OutlinedButton + ElevatedButton footer.
///
/// Mon–Fri are shown by default. Sat/Sun are added/removed on demand via the
/// pill-shaped "+ Add …" rows at the bottom.
Future<void> showRadarScheduleModal(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => const _RadarScheduleSheet(),
  );
}

class _RadarScheduleSheet extends ConsumerStatefulWidget {
  const _RadarScheduleSheet();

  @override
  ConsumerState<_RadarScheduleSheet> createState() =>
      _RadarScheduleSheetState();
}

class _RadarScheduleSheetState extends ConsumerState<_RadarScheduleSheet> {
  late RadarSchedule _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(radarScheduleProvider);
  }

  String _t(String key) {
    final lang = ref.read(authStateProvider)?.appLanguage ?? 'en';
    return t(key, lang);
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return _t('monday');
      case DateTime.tuesday:
        return _t('tuesday');
      case DateTime.wednesday:
        return _t('wednesday');
      case DateTime.thursday:
        return _t('thursday');
      case DateTime.friday:
        return _t('friday');
      case DateTime.saturday:
        return _t('saturday');
      case DateTime.sunday:
        return _t('sunday');
      default:
        return '?';
    }
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: TrembleTheme.rose,
                  onPrimary: Colors.white,
                  surface: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  void _updateEntry(RadarScheduleEntry next) {
    setState(() {
      _draft = _draft.copyWithEntry(next);
    });
  }

  void _addWeekday(int weekday) {
    setState(() {
      _draft = _draft.withWeekday(weekday);
    });
  }

  void _removeWeekday(int weekday) {
    setState(() {
      _draft = _draft.withoutWeekday(weekday);
    });
  }

  Future<void> _save() async {
    await ref.read(radarScheduleProvider.notifier).replaceAll(_draft);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final brandRose = Theme.of(context).colorScheme.primary;
    final lang = ref.watch(authStateProvider)?.appLanguage ?? 'en';

    final sortedWeekdays = _draft.entries.keys.toList()..sort();
    final weekendMissing = <int>[
      if (!_draft.entries.containsKey(DateTime.saturday)) DateTime.saturday,
      if (!_draft.entries.containsKey(DateTime.sunday)) DateTime.sunday,
    ];

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
            _t('schedule_radar'),
            style: GoogleFonts.instrumentSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _t('schedule_radar_sub'),
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSans(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Day pills (scrollable when overflowing)
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final wd in sortedWeekdays)
                    _DayPill(
                      key: ValueKey('day-$wd'),
                      label: _weekdayLabel(wd),
                      entry: _draft.entries[wd]!,
                      isDark: isDark,
                      textColor: textColor,
                      brandRose: brandRose,
                      formatTime: _formatTime,
                      onToggle: (val) => _updateEntry(
                          _draft.entries[wd]!.copyWith(enabled: val)),
                      onPickStart: () async {
                        final picked =
                            await _pickTime(_draft.entries[wd]!.startTime);
                        if (picked != null) {
                          _updateEntry(_draft.entries[wd]!
                              .copyWith(startTime: picked));
                        }
                      },
                      onPickEnd: () async {
                        final picked =
                            await _pickTime(_draft.entries[wd]!.endTime);
                        if (picked != null) {
                          _updateEntry(
                              _draft.entries[wd]!.copyWith(endTime: picked));
                        }
                      },
                      onRemove: (wd == DateTime.saturday ||
                              wd == DateTime.sunday)
                          ? () => _removeWeekday(wd)
                          : null,
                    ),
                  // "+ Add Saturday" / "+ Add Sunday" pills
                  for (final wd in weekendMissing)
                    _AddDayPill(
                      key: ValueKey('add-$wd'),
                      label: _weekdayLabel(wd),
                      isDark: isDark,
                      textColor: textColor,
                      onTap: () => _addWeekday(wd),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Save / Cancel — same as Lifestyle modal
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
                  onPressed: _save,
                  child: Text(t('save', lang),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pill-shaped row for one weekday. Collapsed when disabled (just label +
/// switch). Expanded when enabled — adds two inline tappable time chips.
class _DayPill extends StatelessWidget {
  final String label;
  final RadarScheduleEntry entry;
  final bool isDark;
  final Color textColor;
  final Color brandRose;
  final String Function(TimeOfDay) formatTime;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback? onRemove;

  const _DayPill({
    super.key,
    required this.label,
    required this.entry,
    required this.isDark,
    required this.textColor,
    required this.brandRose,
    required this.formatTime,
    required this.onToggle,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = entry.enabled;
    final bgColor = isSelected
        ? brandRose.withValues(alpha: 0.15)
        : (isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.04));
    final borderColor = isSelected
        ? brandRose
        : (isDark ? Colors.white24 : Colors.black12);
    final labelColor = isSelected ? brandRose : textColor;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        // Pill shape — matches Lifestyle option rows.
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Label
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.instrumentSans(
                color: labelColor,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          // Time chips — only when enabled
          if (isSelected) ...[
            _TimeChip(
              value: formatTime(entry.startTime),
              brandRose: brandRose,
              onTap: onPickStart,
            ),
            const SizedBox(width: 6),
            Icon(LucideIcons.arrowRight,
                size: 14,
                color: brandRose.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            _TimeChip(
              value: formatTime(entry.endTime),
              brandRose: brandRose,
              onTap: onPickEnd,
            ),
            const SizedBox(width: 8),
          ],
          // Remove (X) — only for Sat/Sun
          if (onRemove != null) ...[
            InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(LucideIcons.x,
                    size: 16,
                    color: isDark ? Colors.white54 : Colors.black45),
              ),
            ),
            const SizedBox(width: 4),
          ],
          // Toggle
          SizedBox(
            height: 28,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Switch(
                value: entry.enabled,
                activeThumbColor: Colors.white,
                activeTrackColor: brandRose,
                inactiveTrackColor:
                    isDark ? Colors.white24 : Colors.black12,
                onChanged: onToggle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable time value displayed as a small inline pill inside a day row.
class _TimeChip extends StatelessWidget {
  final String value;
  final Color brandRose;
  final VoidCallback onTap;

  const _TimeChip({
    required this.value,
    required this.brandRose,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: brandRose.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: brandRose.withValues(alpha: 0.5)),
        ),
        child: Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: brandRose,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped "+ Add Saturday/Sunday" row. Same shape language as day pills,
/// but muted styling so it reads as a secondary action.
class _AddDayPill extends StatelessWidget {
  final String label;
  final bool isDark;
  final Color textColor;
  final VoidCallback onTap;

  const _AddDayPill({
    super.key,
    required this.label,
    required this.isDark,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.plus,
                size: 18,
                color: isDark ? Colors.white54 : Colors.black45),
            const SizedBox(width: 12),
            Text(
              'Add $label',
              style: GoogleFonts.instrumentSans(
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
