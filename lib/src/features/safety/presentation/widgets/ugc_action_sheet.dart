import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/ui/primary_button.dart';
import '../../data/safety_repository.dart';
import '../../../../core/translations.dart';
import '../../../../core/theme.dart';

// Stable keys for testability (copy-independent finders).
const _reportTileKey = Key('ugc_report_tile');
const _blockTileKey = Key('ugc_block_tile');
const _blockConfirmButtonKey = Key('ugc_block_confirm_button');
const _blockCancelButtonKey = Key('ugc_block_cancel_button');
const _reportSubmitButtonKey = Key('ugc_report_submit_button');

const _sheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
);

Widget _grabber() => Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(2),
      ),
    );

/// A generic bottom sheet that offers "Report User" and "Block User" options.
///
/// All surfaces here are [Material]-backed bottom sheets (never
/// `CupertinoAlertDialog`) so that Material children — ListTile, CheckboxListTile,
/// TextField, TextButton — always resolve a Material ancestor. Hosting Material
/// widgets inside a CupertinoAlertDialog crashed on iOS with `Material.of` null
/// (TREMBLE-FUNCTIONS-12) and could not be caught in widget tests because the
/// branch keyed off `Platform.isIOS` (dart:io). Bottom sheets are
/// platform-independent and testable.
class UgcActionSheet extends ConsumerWidget {
  final String targetUid;
  final String targetName;

  const UgcActionSheet({
    super.key,
    required this.targetUid,
    required this.targetName,
  });

  static void show(BuildContext context,
      {required String targetUid, required String targetName}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          UgcActionSheet(targetUid: targetUid, targetName: targetName),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);

    return Material(
      color: TrembleTheme.textColor,
      shape: _sheetShape,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _grabber(),
            const SizedBox(height: 16),
            ListTile(
              key: _reportTileKey,
              leading: const Icon(LucideIcons.flag, color: TrembleTheme.rose),
              title: Text(
                t('report_user', lang).replaceAll('{name}', targetName),
                style: GoogleFonts.instrumentSans(
                  color: TrembleTheme.rose,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                // Capture the NavigatorState (stable across the sheet pop), close
                // this sheet, then present the report sheet from a live context.
                // Popping first then reusing THIS sheet's context is the
                // dead-context crash (TREMBLE-FUNCTIONS-10).
                final navigator = Navigator.of(context);
                navigator.pop();
                _showReportSheet(navigator.context);
              },
            ),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              key: _blockTileKey,
              leading: const Icon(LucideIcons.ban, color: TrembleTheme.rose),
              title: Text(
                t('block_user', lang).replaceAll('{name}', targetName),
                style: GoogleFonts.instrumentSans(
                  color: TrembleTheme.rose,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                _showBlockSheet(navigator.context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showBlockSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BlockConfirmSheet(
        targetUid: targetUid,
        targetName: targetName,
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ReportSheet(
        targetUid: targetUid,
        targetName: targetName,
      ),
    );
  }
}

/// Compact confirm sheet for blocking a user.
class _BlockConfirmSheet extends ConsumerWidget {
  final String targetUid;
  final String targetName;

  const _BlockConfirmSheet({
    required this.targetUid,
    required this.targetName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);

    return Material(
      color: TrembleTheme.textColor,
      shape: _sheetShape,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _grabber()),
              const SizedBox(height: 20),
              Text(
                t('block_user', lang).replaceAll('{name}', targetName),
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t('block_confirm_desc', lang).replaceAll('{name}', targetName),
                textAlign: TextAlign.center,
                style: GoogleFonts.instrumentSans(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                key: _blockConfirmButtonKey,
                text: t('block_user', lang).replaceAll(' {name}', ''),
                onPressed: () => _confirmBlock(context, ref, lang),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: _blockCancelButtonKey,
                onPressed: () => Navigator.pop(context),
                child: Text(
                  t('cancel', lang),
                  style: GoogleFonts.instrumentSans(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmBlock(
      BuildContext context, WidgetRef ref, String lang) async {
    // Capture the messenger before pop — the sheet context is defunct after.
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    try {
      await ref.read(safetyRepositoryProvider).blockUser(targetUid);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            t('block_success', lang).replaceAll('{name}', targetName),
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Uporabnika ni bilo mogoče blokirati. Povezava ali dovoljenje ni uspelo. Poskusi znova.',
          ),
        ),
      );
    }
  }
}

/// Scrollable report sheet: reason checkboxes, free-text note, submit.
class _ReportSheet extends ConsumerStatefulWidget {
  final String targetUid;
  final String targetName;

  const _ReportSheet({
    required this.targetUid,
    required this.targetName,
  });

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final Set<String> _selectedReasons = {};
  final TextEditingController _explanationCtrl = TextEditingController();
  bool _isSubmitting = false;

  List<String> _getReasons(String lang) => [
        t('report_reason_spam', lang),
        t('report_reason_violence', lang),
        t('report_reason_nudity', lang),
        t('report_reason_fake', lang),
        t('report_reason_behaviour', lang),
      ];

  @override
  void dispose() {
    _explanationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReport(String lang) async {
    if (_selectedReasons.isEmpty || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(safetyRepositoryProvider).reportUser(
            widget.targetUid,
            _selectedReasons.toList(),
            _explanationCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(t('report_success', ref.read(appLanguageProvider))
              .replaceAll('{name}', widget.targetName)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Prijave ni bilo mogoče poslati. Povezava ali dovoljenje ni uspelo. Poskusi znova.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final canSubmit = _selectedReasons.isNotEmpty && !_isSubmitting;

    return Padding(
      // Lift above the keyboard when the note field is focused.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: TrembleTheme.textColor,
        shape: _sheetShape,
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: _grabber()),
                  const SizedBox(height: 16),
                  Text(
                    t('report_user', lang)
                        .replaceAll('{name}', widget.targetName),
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t('report_reasons_desc', lang),
                    style: GoogleFonts.instrumentSans(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  ..._getReasons(lang).map((reason) {
                    return CheckboxListTile(
                      title: Text(
                        reason,
                        style: GoogleFonts.instrumentSans(color: Colors.white),
                      ),
                      value: _selectedReasons.contains(reason),
                      activeColor: TrembleTheme.rose,
                      checkColor: Colors.white,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: _isSubmitting
                          ? null
                          : (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedReasons.add(reason);
                                } else {
                                  _selectedReasons.remove(reason);
                                }
                              });
                            },
                    );
                  }),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _explanationCtrl,
                    style: GoogleFonts.instrumentSans(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: t('report_explanation', lang),
                      labelStyle:
                          GoogleFonts.instrumentSans(color: Colors.white54),
                      hintText: t('report_explanation_hint', lang),
                      hintStyle:
                          GoogleFonts.instrumentSans(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t('report_auto_block_warning', lang),
                    style: GoogleFonts.instrumentSans(
                      fontWeight: FontWeight.bold,
                      color: TrembleTheme.rose,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _isSubmitting ? null : () => Navigator.pop(context),
                        child: Text(
                          t('cancel', lang),
                          style:
                              GoogleFonts.instrumentSans(color: Colors.white54),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Opacity(
                        opacity: canSubmit ? 1.0 : 0.45,
                        child: AbsorbPointer(
                          absorbing: !canSubmit,
                          child: PrimaryButton(
                            key: _reportSubmitButtonKey,
                            text: t('submit', lang),
                            onPressed: () => _submitReport(lang),
                            isLoading: _isSubmitting,
                            width: 120,
                            height: 44,
                          ),
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
    );
  }
}
