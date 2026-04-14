import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'step_shared.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PRIMARY: Single-select partner preference modal
// ─────────────────────────────────────────────────────────────────────────────
void showPartnerPreferenceModal(
  BuildContext context, {
  required String title,
  required List<Map<String, Object>> options,
  required String userSelection,
  required ValueChanged<List<String>?> onSave,
  required VoidCallback onNext,
  bool showCustom = true,
}) {
  String? tempSelection;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
              top: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: Text(
                'Ali želiš, da ima tvoj partner enake preference?',
                textAlign: TextAlign.center,
                style: GoogleFonts.instrumentSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E1E2E),
                ),
              ),
            ),
            const SizedBox(height: 24),
            OptionPill(
              label: 'Enako kot jaz',
              selected: tempSelection == 'same',
              onTap: () => setModalState(() => tempSelection = 'same'),
            ),
            OptionPill(
              label: 'Vseeno mi je',
              selected: tempSelection == 'idc',
              onTap: () => setModalState(() => tempSelection = 'idc'),
            ),
            if (showCustom)
              OptionPill(
                label: 'Po meri',
                selected: tempSelection == 'custom',
                onTap: () => setModalState(() => tempSelection = 'custom'),
              ),
            const SizedBox(height: 24),
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
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Nazaj',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tempSelection != null
                          ? Theme.of(context).colorScheme.primary
                          : (isDark ? Colors.white12 : Colors.black12),
                      foregroundColor: tempSelection != null
                          ? Colors.black
                          : (isDark ? Colors.white38 : Colors.black38),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                      elevation: tempSelection != null ? 2 : 0,
                    ),
                    onPressed: tempSelection == null
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            if (tempSelection == 'same') {
                              onSave([userSelection]);
                              onNext();
                            } else if (tempSelection == 'idc') {
                              onSave(null);
                              onNext();
                            } else if (tempSelection == 'custom') {
                              showCustomPartnerPreferenceModal(
                                context,
                                title: title,
                                options: options,
                                onSave: onSave,
                                onNext: onNext,
                              );
                            }
                          },
                    child: const Text(
                      'Nadaljuj',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECONDARY: Multi-select custom partner preference modal
// ─────────────────────────────────────────────────────────────────────────────
void showCustomPartnerPreferenceModal(
  BuildContext context, {
  required String title,
  required List<Map<String, Object>> options,
  required ValueChanged<List<String>?> onSave,
  required VoidCallback onNext,
}) {
  List<String> tempSelected = [];
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => SafeArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1A1A2E) : Colors.white)
                    .withValues(alpha: 0.8),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                    top: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black26,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    title,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E1E2E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: options.map((o) {
                        final val = o['key'] as String;
                        final isSelected = tempSelected.contains(val);
                        return OptionPill(
                          label: o['label'] as String,
                          selected: isSelected,
                          icon: o['icon'] as IconData?,
                          onTap: () => setModalState(() {
                            if (isSelected) {
                              tempSelected.remove(val);
                            } else {
                              tempSelected.add(val);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color:
                                    isDark ? Colors.white38 : Colors.black26),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Nazaj',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ContinueButton(
                          enabled: tempSelected.isNotEmpty,
                          onTap: () {
                            Navigator.pop(ctx);
                            onSave(tempSelected);
                            onNext();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
