import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PURE HELPERS
// ─────────────────────────────────────────────────────────────────────────────
int calcAge(DateTime d) {
  final now = DateTime.now();
  int age = now.year - d.year;
  if (now.month < d.month || (now.month == d.month && now.day < d.day)) {
    age--;
  }
  return age;
}

String zodiacSign(DateTime d) {
  final m = d.month;
  final day = d.day;
  if ((m == 1 && day >= 20) || (m == 2 && day <= 18)) return 'Aquarius';
  if ((m == 2 && day >= 19) || (m == 3 && day <= 20)) return 'Pisces';
  if ((m == 3 && day >= 21) || (m == 4 && day <= 19)) return 'Aries';
  if ((m == 4 && day >= 20) || (m == 5 && day <= 20)) return 'Taurus';
  if ((m == 5 && day >= 21) || (m == 6 && day <= 20)) return 'Gemini';
  if ((m == 6 && day >= 21) || (m == 7 && day <= 22)) return 'Cancer';
  if ((m == 7 && day >= 23) || (m == 8 && day <= 22)) return 'Leo';
  if ((m == 8 && day >= 23) || (m == 9 && day <= 22)) return 'Virgo';
  if ((m == 9 && day >= 23) || (m == 10 && day <= 22)) return 'Libra';
  if ((m == 10 && day >= 23) || (m == 11 && day <= 21)) return 'Scorpio';
  if ((m == 11 && day >= 22) || (m == 12 && day <= 21)) return 'Sagittarius';
  return 'Capricorn';
}

// ─────────────────────────────────────────────────────────────────────────────
// BIRTHDAY STEP (p4)
// ─────────────────────────────────────────────────────────────────────────────
class BirthdayStep extends StatelessWidget {
  const BirthdayStep({
    super.key,
    required this.pickerMonth,
    required this.pickerDay,
    required this.pickerYear,
    required this.onMonthChanged,
    required this.onDayChanged,
    required this.onYearChanged,
    required this.onConfirm,
    required this.onBack,
    required this.tr,
  });

  /// 1-based month (1 = January).
  final int pickerMonth;
  final int pickerDay;
  final int pickerYear;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onDayChanged;
  final ValueChanged<int> onYearChanged;

  /// Called only after the user confirms their birthday in the bottom sheet.
  /// Receives the confirmed [DateTime]. Parent sets [_birthDate] and advances.
  final void Function(DateTime date) onConfirm;
  final VoidCallback onBack;
  final String Function(String) tr;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // ── Age / zodiac helpers ──────────────────────────────────────────────────

  DateTime _currentDate() {
    final maxDays = DateTime(pickerYear, pickerMonth + 1, 0).day;
    final validDay = pickerDay > maxDays ? maxDays : pickerDay;
    return DateTime(pickerYear, pickerMonth, validDay);
  }

  // ── Confirmation sheet ────────────────────────────────────────────────────

  void _showConfirmation(BuildContext context) {
    final d = _currentDate();
    final age = calcAge(d);
    final dateStr = DateFormat('MMMM d, yyyy').format(d);
    final brandRose = Theme.of(context).colorScheme.primary;
    const red = Color(0xFFFF4C4C);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final bodyColor = isDark ? Colors.white60 : Colors.black54;
    final borderColor = isDark ? Colors.white12 : Colors.black12;
    final handleColor = isDark ? Colors.white24 : Colors.black26;
    final buttonBg =
        isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05);

    // ── ZVOP-2 čl. 14 / GDPR čl. 8 — HARD STOP FOR UNDER 18 ──────────────
    if (age < 18) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
              decoration: BoxDecoration(
                color: sheetBg.withValues(alpha: 0.8),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _handle(handleColor),
                const SizedBox(height: 28),
                const Icon(Icons.block_rounded, color: red, size: 56),
                const SizedBox(height: 20),
                Text(
                  'Tremble is 18+ only',
                  style: GoogleFonts.instrumentSans(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: titleColor),
                ),
                const SizedBox(height: 12),
                Text(
                  'You must be at least 18 years old to use Tremble. '
                  'We are unable to create an account for you at this time.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.instrumentSans(
                      color: bodyColor, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 28),
                _sheetButton(
                  label: 'Go back',
                  color: buttonBg,
                  textColor: isDark ? Colors.white70 : Colors.black87,
                  onTap: () => Navigator.pop(ctx),
                ),
              ]),
            ),
          ),
        ),
      );
      return;
    }
    // ──────────────────────────────────────────────────────────────────────

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            decoration: BoxDecoration(
              color: sheetBg.withValues(alpha: 0.8),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _handle(handleColor),
              const SizedBox(height: 28),
              Text(
                tr('youre_age').replaceAll('{age}', '$age'),
                style: GoogleFonts.instrumentSans(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: titleColor),
              ),
              const SizedBox(height: 12),
              Text(
                tr('is_birthday_correct').replaceAll('{date}', dateStr),
                textAlign: TextAlign.center,
                style: GoogleFonts.instrumentSans(
                    color: bodyColor, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 28),
              _sheetButton(
                label: tr('confirm_btn').toUpperCase(),
                color: brandRose,
                textColor: Colors.black,
                hasShadow: true,
                onTap: () {
                  onConfirm(d);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  tr('edit_btn').toUpperCase(),
                  style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      letterSpacing: 1.2,
                      fontSize: 13),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Private UI helpers ────────────────────────────────────────────────────

  Widget _handle(Color color) => Container(
        width: 40,
        height: 4,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      );

  Widget _sheetButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
    bool hasShadow = false,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
            boxShadow: hasShadow
                ? [
                    BoxShadow(
                        color: color.withValues(alpha: 0.4), blurRadius: 16)
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.instrumentSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: textColor,
                  letterSpacing: 1.2),
            ),
          ),
        ),
      );

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final maxYear = now.year - 18;
    final minYear = now.year - 100;
    final maxDays = DateTime(pickerYear, pickerMonth + 1, 0).day;
    final validDay = pickerDay > maxDays ? maxDays : pickerDay;
    final d = DateTime(pickerYear, pickerMonth, validDay);
    final age = calcAge(d);
    final zodiac = zodiacSign(d);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          StepHeader(
            tr('whats_your_birthday'),
            subtitle: tr('birthday_subtitle'),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: Row(children: [
              Expanded(
                child: DrumPicker(
                  items: _months,
                  selectedIndex: pickerMonth - 1,
                  looping: true,
                  onChanged: (i) => onMonthChanged(i + 1),
                ),
              ),
              SizedBox(
                width: 65,
                child: DrumPicker(
                  items: List.generate(maxDays, (i) => '${i + 1}'),
                  selectedIndex: validDay - 1,
                  looping: true,
                  onChanged: (i) =>
                      onDayChanged(i + 1 > maxDays ? maxDays : i + 1),
                ),
              ),
              SizedBox(
                width: 90,
                child: DrumPicker(
                  items: List.generate(
                      maxYear - minYear + 1, (i) => '${maxYear - i}'),
                  selectedIndex: maxYear - pickerYear,
                  looping: false,
                  onChanged: (i) => onYearChanged(maxYear - i),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            _BirthdayChip(
              label: '$age',
              icon: LucideIcons.cake,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _BirthdayChip(
              label: zodiac,
              icon: LucideIcons.star,
              isDark: isDark,
            ),
          ]),
          const SizedBox(height: 24),
          ContinueButton(
            enabled: true,
            label: tr('continue_btn'),
            onTap: () => _showConfirmation(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BIRTHDAY CHIP — age & zodiac badge
// ─────────────────────────────────────────────────────────────────────────────
class _BirthdayChip extends StatelessWidget {
  const _BirthdayChip({
    required this.label,
    required this.icon,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white38 : Colors.black26),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
