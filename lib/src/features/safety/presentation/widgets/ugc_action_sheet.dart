import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/safety_repository.dart';
import '../../../../core/translations.dart';

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
        color: Color(0xFF1A1A18),
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
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(LucideIcons.flag, color: Colors.red),
              title: Text(
                t('report_user', lang).replaceAll('{name}', targetName),
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context); // Close action sheet
                _showReportDialog(context, ref, lang);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(LucideIcons.ban, color: Colors.red),
              title: Text(
                t('block_user', lang).replaceAll('{name}', targetName),
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context); // Close action sheet
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
        title: Text(t('block_user', lang).replaceAll('{name}', targetName)),
        content: Text(
            t('block_confirm_desc', lang).replaceAll('{name}', targetName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel', lang)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // Calls WaveRepository.sendWave() → local write, mutual match detection is server-side
              Navigator.pop(ctx);
              try {
                await ref.read(safetyRepositoryProvider).blockUser(targetUid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(t('block_success', lang)
                            .replaceAll('{name}', targetName))),
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
            child: Text(t('block_user', lang).replaceAll(' {name}', ''),
                style: const TextStyle(color: Colors.white)),
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
              content: Text(t('report_success', lang)
                  .replaceAll('{name}', widget.targetName))),
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

    return AlertDialog(
      title:
          Text(t('report_user', lang).replaceAll('{name}', widget.targetName)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('report_reasons_desc', lang),
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              ..._availableReasons.map((reason) {
                return CheckboxListTile(
                  title: Text(reason),
                  value: _selectedReasons.contains(reason),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (val) {
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
                decoration: InputDecoration(
                  labelText: t('report_explanation', lang),
                  hintText: t('report_explanation_hint', lang),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Text(
                t('report_auto_block_warning', lang),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(t('cancel', lang)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: (_isSubmitting || _selectedReasons.isEmpty)
              ? null
              : () => _submitReport(lang),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(t('submit', lang),
                  style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
