import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Bundled brand typefaces
//
// First launch used to await an HTTP download of every brand font. On a slow
// connection that stalled startup; on a bad one it threw "Failed to load font
// with url" in production. The fonts now ship in assets/fonts/ and runtime
// fetching is off.
//
// google_fonts matches an asset whose filename ends with its API prefix
// ("<Family>-<Variant>"), and with allowRuntimeFetching = false a miss throws
// rather than silently reaching for the network — which is what makes the
// load assertions below real rather than decorative.
// ---------------------------------------------------------------------------

/// The AGENTS.md typography contract (line 292).
const _contractFamilies = {
  'instrumentSans',
  'playfairDisplay',
  'lora',
  'jetBrainsMono',
};

/// Every variant google_fonts knows for the four contract families.
///
/// The full set is bundled rather than only the weights called today: a
/// requested weight resolves to the family's CLOSEST AVAILABLE variant, and the
/// TrembleTheme.displayFont / bodyFont / uiFont helpers take an arbitrary
/// FontWeight, so no static audit of call sites can stay correct. Pinning the
/// list here fails fast and readably if a file is dropped or renamed — the
/// load assertions above would otherwise stall instead.
///
/// Regenerate with tool/fetch_fonts.py.
const _bundledFonts = <String>[
  'InstrumentSans-Bold.ttf',
  'InstrumentSans-BoldItalic.ttf',
  'InstrumentSans-Italic.ttf',
  'InstrumentSans-Medium.ttf',
  'InstrumentSans-MediumItalic.ttf',
  'InstrumentSans-Regular.ttf',
  'InstrumentSans-SemiBold.ttf',
  'InstrumentSans-SemiBoldItalic.ttf',
  'JetBrainsMono-Bold.ttf',
  'JetBrainsMono-BoldItalic.ttf',
  'JetBrainsMono-ExtraBold.ttf',
  'JetBrainsMono-ExtraBoldItalic.ttf',
  'JetBrainsMono-ExtraLight.ttf',
  'JetBrainsMono-ExtraLightItalic.ttf',
  'JetBrainsMono-Italic.ttf',
  'JetBrainsMono-Light.ttf',
  'JetBrainsMono-LightItalic.ttf',
  'JetBrainsMono-Medium.ttf',
  'JetBrainsMono-MediumItalic.ttf',
  'JetBrainsMono-Regular.ttf',
  'JetBrainsMono-SemiBold.ttf',
  'JetBrainsMono-SemiBoldItalic.ttf',
  'JetBrainsMono-Thin.ttf',
  'JetBrainsMono-ThinItalic.ttf',
  'Lora-Bold.ttf',
  'Lora-BoldItalic.ttf',
  'Lora-Italic.ttf',
  'Lora-Medium.ttf',
  'Lora-MediumItalic.ttf',
  'Lora-Regular.ttf',
  'Lora-SemiBold.ttf',
  'Lora-SemiBoldItalic.ttf',
  'PlayfairDisplay-Black.ttf',
  'PlayfairDisplay-BlackItalic.ttf',
  'PlayfairDisplay-Bold.ttf',
  'PlayfairDisplay-BoldItalic.ttf',
  'PlayfairDisplay-ExtraBold.ttf',
  'PlayfairDisplay-ExtraBoldItalic.ttf',
  'PlayfairDisplay-Italic.ttf',
  'PlayfairDisplay-Medium.ttf',
  'PlayfairDisplay-MediumItalic.ttf',
  'PlayfairDisplay-Regular.ttf',
  'PlayfairDisplay-SemiBold.ttf',
  'PlayfairDisplay-SemiBoldItalic.ttf',
];

void main() {
  group('brand fonts resolve offline', () {
    setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
    tearDown(() => GoogleFonts.config.allowRuntimeFetching = true);

    testWidgets('every weight of every brand family loads from assets',
        (tester) async {
      // Requesting a weight a family does not ship resolves to its closest
      // available variant, so sweeping all nine proves the whole matrix.
      final styles = <TextStyle>[
        for (final weight in FontWeight.values) ...[
          GoogleFonts.instrumentSans(fontWeight: weight),
          GoogleFonts.playfairDisplay(fontWeight: weight),
          GoogleFonts.lora(fontWeight: weight),
          GoogleFonts.jetBrainsMono(fontWeight: weight),
        ],
      ];

      await expectLater(GoogleFonts.pendingFonts(styles), completes);
    });

    testWidgets('italic variants load from assets', (tester) async {
      final styles = <TextStyle>[
        for (final weight in FontWeight.values) ...[
          GoogleFonts.instrumentSans(
              fontWeight: weight, fontStyle: FontStyle.italic),
          GoogleFonts.playfairDisplay(
              fontWeight: weight, fontStyle: FontStyle.italic),
          GoogleFonts.lora(fontWeight: weight, fontStyle: FontStyle.italic),
          GoogleFonts.jetBrainsMono(
              fontWeight: weight, fontStyle: FontStyle.italic),
        ],
      ];

      await expectLater(GoogleFonts.pendingFonts(styles), completes);
    });
  });

  group('font bundle wiring', () {
    test('startup disables runtime fetching before any font is requested', () {
      final main = File('lib/main.dart').readAsStringSync();

      expect(main, contains('GoogleFonts.config.allowRuntimeFetching = false'));

      final configAt =
          main.indexOf('GoogleFonts.config.allowRuntimeFetching = false');
      final firstFontAt = main.indexOf('GoogleFonts.pendingFonts');
      expect(
        configAt,
        lessThan(firstFontAt),
        reason: 'a font requested before the config lands can still fetch',
      );
    });

    test('pubspec ships the font directory', () {
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('assets/fonts/'),
      );
    });

    test('every variant of every contract family is on disk', () {
      final present = Directory('assets/fonts')
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.endsWith('.ttf'))
          .toSet();

      expect(
        _bundledFonts.toSet().difference(present),
        isEmpty,
        reason: 'a missing variant silently renders in a fallback typeface',
      );
      expect(
        present.difference(_bundledFonts.toSet()),
        isEmpty,
        reason: 'unexpected font file — update the pin or remove the file',
      );
    });

    test('every bundled family carries its OFL licence text', () {
      for (final family in const [
        'instrumentsans',
        'playfairdisplay',
        'lora',
        'jetbrainsmono',
      ]) {
        final licence = File('assets/fonts/OFL-$family.txt');
        expect(licence.existsSync(), isTrue, reason: 'missing OFL for $family');
        expect(licence.readAsStringSync(), contains('SIL OPEN FONT LICENSE'));
      }
    });

    test('startup registers the font licences', () {
      expect(
        File('lib/main.dart').readAsStringSync(),
        contains('LicenseRegistry.addLicense'),
      );
    });

    test('no font family outside the AGENTS.md contract is used', () {
      final used = <String>{};
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        for (final m in RegExp(r'GoogleFonts\.([a-zA-Z]+)\(')
            .allMatches(entity.readAsStringSync())) {
          final name = m.group(1)!;
          // Not families — package-level API.
          if (name == 'pendingFonts' || name == 'config') continue;
          used.add(name);
        }
      }

      expect(
        used.difference(_contractFamilies),
        isEmpty,
        reason: 'unbundled family would hit the network at runtime and '
            'violates the AGENTS.md typography contract',
      );
    });
  });
}
