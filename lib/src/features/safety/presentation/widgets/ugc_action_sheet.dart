import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../shared/ui/primary_button.dart';
import '../../data/safety_repository.dart';
import '../../../../core/translations.dart';

const _kDeepGraphite = Color(0xFF1A1A18);
const _kPrimaryRose = Color(0xFFF4436C);

/// A generic bottom sheet that offers "Report User" and "Block User" options.
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          UgcActionSheet(targetUid: targetUid, targetName: targetName),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);

    return Container(
      decoration: const BoxDecoration(
        color: _kDeepGraphite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(LucideIcons.flag, color: _kPrimaryRose),
              title: Text(
                t('report_user', lang).replaceAll('{name}', targetName),
                style: GoogleFonts.instrumentSans(
                  color: _kPrimaryRose,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(context, ref, lang);
              },
            ),
            Divider(color: Colors.white12, height: 1),
            ListTile(
              leading: const Icon(LucideIcons.ban, color: _kPrimaryRose),
              title: Text(
                t('block_user', lang).replaceAll('{name}', targetName),
                style: GoogleFonts.instrumentSans(
                  color: _kPrimaryRose,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showBlockDialog(context, ref, lang);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog(BuildContext context, WidgetRef ref, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kDeepGraphite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t('block_user', lang).replaceAll('{name}', targetName),
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          t('block_confirm_desc', lang).replaceAll('{name}', targetName),
          style: GoogleFonts.instrumentSans(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              t('cancel', lang),
              style: GoogleFonts.instrumentSans(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(safetyRepositoryProvider).blockUser(targetUid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t('block_success', lang)
                          .replaceAll('{name}', targetName)),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: Text(
              t('block_user', lang).replaceAll(' {name}', ''),
              style: GoogleFonts.instrumentSans(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, WidgetRef ref, String lang) {
    showDialog(
      context: context,
      builder: (ctx) =>
          ReportDialog(targetUid: targetUid, targetName: targetName),
    );
  }
}

class ReportDialog extends ConsumerStatefulWidget {
  final String targetUid;
  final String targetName;

  const ReportDialog({
    super.key,
    required this.targetUid,
    required this.targetName,
  });

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  final Set<String> _selectedReasons = {};
  final TextEditingController _explanationCtrl = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _availableReasons = [
    'Spam ali prevara',
    'Nasilje in grožnje',
    'Neprimerna golota ali seksualna vsebina',
    'Lažen profil',
    'Neprimerno obnašanje',
  ];

  @override
  void dispose() {
    _explanationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReport(String lang) async {
    if (_selectedReasons.isEmpty) return;
    setState(() => _isSubmitting = true);

    try {
      await ref.read(safetyRepositoryProvider).reportUser(
            widget.targetUid,
            _selectedReasons.toList(),
            _explanationCtrl.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('report_success', ref.read(appLanguageProvider))
                .replaceAll('{name}', widget.targetName)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final canSubmit = _selectedReasons.isNotEmpty && !_isSubmitting;

    return AlertDialog(
      backgroundColor: _kDeepGraphite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      title: Text(
        t('report_user', lang).replaceAll('{name}', widget.targetName),
        style: GoogleFonts.playfairDisplay(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('report_reasons_desc', lang),
                style: GoogleFonts.instrumentSans(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              ..._availableReasons.map((reason) {
                return CheckboxListTile(
                  title: Text(
                    reason,
                    style: GoogleFonts.instrumentSans(color: Colors.white),
                  ),
                  value: _selectedReasons.contains(reason),
                  activeColor: _kPrimaryRose,
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
                  labelStyle: GoogleFonts.instrumentSans(color: Colors.white54),
                  hintText: t('report_explanation_hint', lang),
                  hintStyle: GoogleFonts.instrumentSans(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t('report_auto_block_warning', lang),
                style: GoogleFonts.instrumentSans(
                  fontWeight: FontWeight.bold,
                  color: _kPrimaryRose,
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
                      style: GoogleFonts.instrumentSans(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Opacity(
                    opacity: canSubmit ? 1.0 : 0.45,
                    child: AbsorbPointer(
                      absorbing: !canSubmit,
                      child: PrimaryButton(
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
    );
  }
}
