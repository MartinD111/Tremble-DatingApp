// Widget + source contract for the Google Play Prominent Disclosure screen.
//
// The screen exists to satisfy Play policy for ACCESS_BACKGROUND_LOCATION:
// a standalone screen, distinct from the standard consent screen, that
// appears BEFORE the OS background-location prompt.
//
// These tests pin four things reviewers actually look for:
//  1. Exact spec copy renders in EN and SL.
//  2. Primary CTA returns `true` so the caller knows to fire the OS prompt.
//  3. Secondary CTA returns `false` so the caller must NOT fire the OS prompt.
//  4. The widget itself never touches permission_handler — only the caller does.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tremble/src/core/translations.dart';
import 'package:tremble/src/features/auth/presentation/prominent_disclosure_screen.dart';

// Bypass the auth-state listen in the real AppLanguageNotifier — that would
// pull authStateProvider and its FirebaseAuth dependency into the test.
class _StaticLanguageNotifier extends AppLanguageNotifier {
  _StaticLanguageNotifier(this._lang) : super();
  final String _lang;
  @override
  String build() => _lang;
}

Widget _launcher({required String lang, required Widget onPushComplete}) {
  return ProviderScope(
    overrides: [
      appLanguageProvider.overrideWith(() => _StaticLanguageNotifier(lang)),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const ProminentDisclosureScreen(),
                  ),
                );
                // Store the result on the launcher scaffold so tests can read.
                _lastResult = result;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

bool? _lastResult;

void main() {
  setUp(() => _lastResult = null);

  group('ProminentDisclosureScreen — EN copy', () {
    testWidgets('renders exact spec headline, body, and CTAs', (tester) async {
      await tester.pumpWidget(
        _launcher(lang: 'en', onPushComplete: const SizedBox.shrink()),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.text('Radar works while you live your life.'),
        findsOneWidget,
        reason: 'EN headline is spec-locked',
      );
      expect(
        find.textContaining('approximate location'),
        findsOneWidget,
        reason: 'EN body must mention approximate location (Play policy)',
      );
      expect(
        find.textContaining('in the background'),
        findsOneWidget,
        reason: 'EN body must state collection happens in background '
            '(Play policy)',
      );
      expect(
        find.textContaining('signals nearby'),
        findsOneWidget,
        reason: 'EN body uses brand-voice lexicon "signals" (Rule #3 '
            'Wave-based mechanic), not the generic dating-app word "matches"',
      );
      expect(
        find.textContaining('cleared within hours'),
        findsOneWidget,
        reason: 'EN body says data is "cleared" not "deleted" — brand-voice '
            'softens the legalese for the consent surface',
      );
      expect(
        find.text('Allow background location'),
        findsOneWidget,
        reason: 'EN primary CTA is spec-locked (Play policy)',
      );
      expect(
        find.text('Not now'),
        findsOneWidget,
        reason: 'EN secondary CTA is spec-locked',
      );
    });
  });

  group('ProminentDisclosureScreen — SL copy', () {
    testWidgets('renders exact spec headline, body, and CTAs', (tester) async {
      await tester.pumpWidget(
        _launcher(lang: 'sl', onPushComplete: const SizedBox.shrink()),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.text('Radar deluje, tudi ko ne gledaš.'),
        findsOneWidget,
        reason: 'SL headline is spec-locked',
      );
      expect(
        find.textContaining('približno lokacijo'),
        findsOneWidget,
        reason: 'SL body must mention approximate location (Play policy)',
      );
      expect(
        find.textContaining('aplikacija v ozadju'),
        findsOneWidget,
        reason: 'SL body must state collection happens in background '
            '(Play policy)',
      );
      expect(
        find.textContaining('signale v tvoji bližini'),
        findsOneWidget,
        reason: 'SL body uses brand-voice lexicon "signale" (Rule #3 '
            'Wave-based mechanic), not the generic dating-app word '
            '"ujemanja"',
      );
      expect(
        find.text('Dovoli lokacijo v ozadju'),
        findsOneWidget,
        reason: 'SL primary CTA is spec-locked (Play policy)',
      );
      expect(
        find.text('Ne zdaj'),
        findsOneWidget,
        reason: 'SL secondary CTA is spec-locked',
      );
    });
  });

  group('ProminentDisclosureScreen — CTA return contract', () {
    testWidgets('primary CTA pops with true', (tester) async {
      await tester.pumpWidget(
        _launcher(lang: 'en', onPushComplete: const SizedBox.shrink()),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Allow background location'));
      await tester.pumpAndSettle();

      expect(_lastResult, isTrue,
          reason:
              'Caller keys the OS background-location request off this true '
              'return value. Anything else risks skipping the prompt.');
    });

    testWidgets('secondary CTA pops with false', (tester) async {
      await tester.pumpWidget(
        _launcher(lang: 'en', onPushComplete: const SizedBox.shrink()),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(_lastResult, isFalse,
          reason: 'Caller MUST NOT fire the OS prompt when the user declines. '
              'This is the Play-mandated "not now" path.');
    });
  });

  group('ProminentDisclosureScreen — no permission handler leakage', () {
    test('widget source never imports permission_handler', () {
      const path =
          'lib/src/features/auth/presentation/prominent_disclosure_screen.dart';
      final source = File(path).readAsStringSync();
      // Look for the actual import — not the string appearing in a docstring —
      // so this test proves the widget code cannot call the permission APIs.
      final importPattern = RegExp(
          r'''^import\s+['"]package:permission_handler''',
          multiLine: true);
      expect(
        importPattern.hasMatch(source),
        isFalse,
        reason:
            'Disclosure must be pure UI. Only the caller fires the OS prompt, '
            'so a future refactor cannot "helpfully" combine disclosure + '
            'request into a single tap.',
      );
      expect(
        source.contains('Permission.location'),
        isFalse,
        reason: 'Disclosure widget must not reference Permission APIs',
      );
    });
  });
}
