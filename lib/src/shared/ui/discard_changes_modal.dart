import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/translations.dart';
import '../../features/auth/data/auth_repository.dart';
import 'tremble_alert_dialog.dart';

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

  final result = await showPlatformDialog<String>(
    context: context,
    backgroundColor: colorScheme.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    title: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.alertTriangle, color: colorScheme.primary, size: 48),
        const SizedBox(height: 12),
        Text(
          discardTitle,
          style: GoogleFonts.instrumentSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    ),
    content: Text(
      'You have unsaved changes. Are you sure you want to discard them?',
      textAlign: TextAlign.center,
      style: GoogleFonts.lora(
        fontSize: 16,
        color: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    ),
    actions: [
      TrembleDialogAction(
        isDestructive: true,
        onPressed: () => Navigator.pop(context, 'discard'),
        child: Text(discardTitle),
      ),
      TrembleDialogAction(
        onPressed: () => Navigator.pop(context, 'save'),
        child: Text(saveText),
      ),
    ],
  );
  return result;
}
