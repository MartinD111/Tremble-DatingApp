import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// Regression guard — Google Places API (New) rejects any circle.radius above
// 50,000 m with:
//   "Invalid circle.radius. Radius must be between 0 and 50,000 meters."
//
// This test reads places_service.dart as source text and asserts that no
// numeric literal above 50,000 appears as a radius value.
// A source-level check is intentional — it catches the value before it ever
// reaches the wire, without requiring HTTP mocks.
//
// If this test fails, fix the offending radius in
// lib/src/core/places_service.dart — do NOT relax the assertion here.
void main() {
  const double _maxRadius = 50000.0;
  const String _sourcePath = 'lib/src/core/places_service.dart';
  final _radiusRe = RegExp(r"'radius'\s*:\s*([\d.]+)");

  group('PlacesService — Places API radius cap (max 50,000 m)', () {
    late String source;

    setUpAll(() {
      // `flutter test` sets cwd to project root, so this resolves correctly.
      source = File(_sourcePath).readAsStringSync();
    });

    test('at least one radius literal exists in source', () {
      expect(
        _radiusRe.hasMatch(source),
        isTrue,
        reason: 'Expected radius literals in $_sourcePath',
      );
    });

    test('no radius literal exceeds 50,000 m (API hard cap)', () {
      final matches = _radiusRe.allMatches(source).toList();

      for (final m in matches) {
        final value = double.parse(m.group(1)!);
        expect(
          value,
          lessThanOrEqualTo(_maxRadius),
          reason: "Found 'radius': $value in $_sourcePath — "
              "exceeds Google Places API (New) maximum of ${_maxRadius.toInt()} m. "
              "Cap it at 50000.0.",
        );
      }
    });

    test('all radius literals equal exactly 50,000 m after fix', () {
      final values = _radiusRe
          .allMatches(source)
          .map((m) => double.parse(m.group(1)!))
          .toList();

      expect(
        values,
        everyElement(equals(_maxRadius)),
        reason: 'All three radius literals in places_service.dart should be '
            '50000.0 — the gym (with location), gym (fallback), and city search.',
      );
    });
  });
}
