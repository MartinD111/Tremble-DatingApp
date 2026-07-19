import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tremble/src/core/translations.dart';
import 'package:tremble/src/features/safety/data/safety_repository.dart';
import 'package:tremble/src/features/safety/presentation/widgets/ugc_action_sheet.dart';

class _FakeLang extends AppLanguageNotifier {
  @override
  String build() => 'en';
}

/// Records calls so we can assert the safety action reached the repository.
///
/// Regression for TREMBLE-FUNCTIONS-10 (block popped via a dismissed-sheet
/// context) AND TREMBLE-FUNCTIONS-12 (Material widgets inside a
/// CupertinoAlertDialog → `Material.of` null) AND the CI "ListTile ink splashes
/// may be invisible" assertion (ListTiles under a bare DecoratedBox with no
/// Material ancestor). All three collapse once block + report are themed
/// bottom sheets rather than platform-branched dialogs, so these tests exercise
/// the real flow on every platform.
class _FakeSafetyRepository implements SafetyRepository {
  int blockCalls = 0;
  int reportCalls = 0;
  List<String>? lastReasons;

  @override
  Future<void> blockUser(String targetUid) async {
    blockCalls++;
  }

  @override
  Future<void> unblockUser(String targetUid) async {}

  @override
  Future<void> reportUser(
      String reportedUid, List<String> reasons, String explanation) async {
    reportCalls++;
    lastReasons = reasons;
  }
}

Future<void> _pumpAndOpen(
    WidgetTester tester, _FakeSafetyRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        safetyRepositoryProvider.overrideWithValue(repo),
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
}

void main() {
  testWidgets('action sheet renders both options without ink/Material asserts',
      (tester) async {
    final repo = _FakeSafetyRepository();
    await _pumpAndOpen(tester, repo);

    expect(find.byIcon(LucideIcons.flag), findsOneWidget);
    expect(find.byIcon(LucideIcons.ban), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling the block sheet does not crash', (tester) async {
    final repo = _FakeSafetyRepository();
    await _pumpAndOpen(tester, repo);

    await tester.tap(find.byKey(const Key('ugc_block_tile')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ugc_block_cancel_button')));
    await tester.pumpAndSettle();

    expect(repo.blockCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirming the block sheet calls blockUser once',
      (tester) async {
    final repo = _FakeSafetyRepository();
    await _pumpAndOpen(tester, repo);

    await tester.tap(find.byKey(const Key('ugc_block_tile')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ugc_block_confirm_button')));
    await tester.pumpAndSettle();

    expect(repo.blockCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('report sheet submits selected reasons without crashing',
      (tester) async {
    final repo = _FakeSafetyRepository();
    await _pumpAndOpen(tester, repo);

    await tester.tap(find.byKey(const Key('ugc_report_tile')));
    await tester.pumpAndSettle();

    // Report sheet is a scrollable Material bottom sheet (no CupertinoAlertDialog).
    expect(find.byType(CheckboxListTile), findsWidgets);

    // Select the first reason, then submit.
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();

    // Submit sits at the bottom of a scrollable sheet; bring it into the
    // small test viewport before tapping.
    final submit = find.byKey(const Key('ugc_report_submit_button'));
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(repo.reportCalls, 1);
    expect(repo.lastReasons, isNotNull);
    expect(repo.lastReasons, isNotEmpty);
    expect(tester.takeException(), isNull);
  });
}
