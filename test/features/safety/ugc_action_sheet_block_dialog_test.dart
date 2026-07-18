import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tremble/src/core/translations.dart';
import 'package:tremble/src/features/safety/data/safety_repository.dart';
import 'package:tremble/src/features/safety/presentation/widgets/ugc_action_sheet.dart';
import 'package:tremble/src/shared/ui/tremble_alert_dialog.dart';

class _FakeLang extends AppLanguageNotifier {
  @override
  String build() => 'en';
}

/// Regression for TREMBLE-FUNCTIONS-10: the block dialog's actions popped via
/// the UgcActionSheet's own context, which is defunct once the sheet is
/// dismissed — so tapping Cancel (or Block) threw
/// `Null check operator used on a null value` in Navigator.pop. The fix pops
/// via the dialog's own builder context.
class _FakeSafetyRepository implements SafetyRepository {
  @override
  Future<void> blockUser(String targetUid) async {}
  @override
  Future<void> unblockUser(String targetUid) async {}
  @override
  Future<void> reportUser(
      String reportedUid, List<String> reasons, String explanation) async {}
}

void main() {
  testWidgets(
      'cancelling the block dialog does not crash on the dismissed sheet context',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          safetyRepositoryProvider.overrideWithValue(_FakeSafetyRepository()),
          appLanguageProvider.overrideWith(() => _FakeLang()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => UgcActionSheet.show(
                  context,
                  targetUid: 'u1',
                  targetName: 'Test',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Open the block dialog from the action sheet (this dismisses the sheet).
    final blockTile = find.ancestor(
      of: find.byIcon(LucideIcons.ban),
      matching: find.byType(ListTile),
    );
    expect(blockTile, findsOneWidget);
    await tester.tap(blockTile);
    await tester.pumpAndSettle();

    // Cancel is the first dialog action. On the buggy build this threw.
    expect(find.byType(TrembleDialogAction), findsWidgets);
    await tester.tap(find.byType(TrembleDialogAction).first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
