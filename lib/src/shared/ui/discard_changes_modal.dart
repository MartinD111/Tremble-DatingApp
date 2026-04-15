import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/translations.dart';
import '../../features/auth/data/auth_repository.dart';

Future<String?> showDiscardChangesModal(
    BuildContext context, WidgetRef ref) async {
  final colorScheme = Theme.of(context).colorScheme;
  final user = ref.read(authStateProvider);
  final lang = user?.appLanguage ?? 'en';

  String discardTitle = t('discard_unsaved_changes', lang);
  if (discardTitle.isEmpty || discardTitle == 'discard_unsaved_changes') {
    discardTitle = 'Discard unsaved changes';
  }

  String saveText = t('save', lang);
  if (saveText.isEmpty || saveText == 'save') saveText = 'Save';

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Icon(LucideIcons.alertTriangle, color: colorScheme.primary, size: 48),
          const SizedBox(height: 20),
          Text(
            'Discard changes?',
            style: GoogleFonts.instrumentSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You have unsaved changes. Are you sure you want to discard them?',
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, 'discard'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: colorScheme.onSurface.withValues(alpha: 0.12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Discard',
                    style: GoogleFonts.instrumentSans(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, 'save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return result;
}
