import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/slider_normalizer.dart';

void main() {
  group('SliderNormalizer', () {
    group('isLegacyFormat', () {
      test('returns true for double in 0–1 range', () {
        expect(SliderNormalizer.isLegacyFormat(0.0), true);
        expect(SliderNormalizer.isLegacyFormat(0.5), true);
        expect(SliderNormalizer.isLegacyFormat(1.0), true);
      });

      test('returns false for int (new format)', () {
        expect(SliderNormalizer.isLegacyFormat(0), false);
        expect(SliderNormalizer.isLegacyFormat(50), false);
        expect(SliderNormalizer.isLegacyFormat(100), false);
      });

      test('returns false for null', () {
        expect(SliderNormalizer.isLegacyFormat(null), false);
      });

      test('returns false for double > 1.0 (new format)', () {
        expect(SliderNormalizer.isLegacyFormat(50.0), false);
        expect(SliderNormalizer.isLegacyFormat(100.0), false);
      });
    });

    group('toNewFormat', () {
      test('converts legacy 0–1 to new 0–100', () {
        expect(SliderNormalizer.toNewFormat(0.0), 0);
        expect(SliderNormalizer.toNewFormat(0.5), 50);
        expect(SliderNormalizer.toNewFormat(1.0), 100);
        expect(SliderNormalizer.toNewFormat(0.25), 25);
        expect(SliderNormalizer.toNewFormat(0.75), 75);
      });

      test('returns unchanged value for new format int', () {
        expect(SliderNormalizer.toNewFormat(0), 0);
        expect(SliderNormalizer.toNewFormat(50), 50);
        expect(SliderNormalizer.toNewFormat(100), 100);
      });

      test('returns null for null input', () {
        expect(SliderNormalizer.toNewFormat(null), null);
      });

      test('handles edge case of double > 1.0', () {
        expect(SliderNormalizer.toNewFormat(50.5), 50);
        expect(SliderNormalizer.toNewFormat(100.0), 100);
      });
    });

    group('toLegacyFormat', () {
      test('converts new 0–100 to legacy 0–1', () {
        expect(SliderNormalizer.toLegacyFormat(0), 0.0);
        expect(SliderNormalizer.toLegacyFormat(50), 0.5);
        expect(SliderNormalizer.toLegacyFormat(100), 1.0);
        expect(SliderNormalizer.toLegacyFormat(25), 0.25);
      });

      test('returns unchanged value for legacy format double', () {
        expect(SliderNormalizer.toLegacyFormat(0.0), 0.0);
        expect(SliderNormalizer.toLegacyFormat(0.5), 0.5);
        expect(SliderNormalizer.toLegacyFormat(1.0), 1.0);
      });

      test('returns null for null input', () {
        expect(SliderNormalizer.toLegacyFormat(null), null);
      });

      test('clamps values to 0–1 range', () {
        // If somehow a value > 100 comes in, clamp it
        expect(SliderNormalizer.toLegacyFormat(150), 1.0);
        expect(SliderNormalizer.toLegacyFormat(-10), 0.0);
      });
    });

    group('labelForIntroversion', () {
      test('returns correct labels for 0–100 scale', () {
        expect(SliderNormalizer.labelForIntroversion(0), 'Introvert');
        expect(SliderNormalizer.labelForIntroversion(12), 'Introvert');
        expect(SliderNormalizer.labelForIntroversion(25), 'Center-Left');
        expect(SliderNormalizer.labelForIntroversion(37), 'Center-Left');
        expect(SliderNormalizer.labelForIntroversion(50), 'Ambivert');
        expect(SliderNormalizer.labelForIntroversion(62), 'Ambivert');
        expect(SliderNormalizer.labelForIntroversion(75), 'Center-Right');
        expect(SliderNormalizer.labelForIntroversion(87), 'Center-Right');
        expect(SliderNormalizer.labelForIntroversion(100), 'Extrovert');
      });

      test('clamps values outside 0–100 range', () {
        expect(SliderNormalizer.labelForIntroversion(-10), 'Introvert');
        expect(SliderNormalizer.labelForIntroversion(150), 'Extrovert');
      });
    });

    group('labelForPolitical', () {
      test('returns correct labels for 1–5 scale', () {
        expect(SliderNormalizer.labelForPolitical(1), 'Left');
        expect(SliderNormalizer.labelForPolitical(2), 'Center-Left');
        expect(SliderNormalizer.labelForPolitical(3), 'Center');
        expect(SliderNormalizer.labelForPolitical(4), 'Center-Right');
        expect(SliderNormalizer.labelForPolitical(5), 'Right');
      });

      test('clamps values outside 1–5 range', () {
        expect(SliderNormalizer.labelForPolitical(0), 'Left'); // Clamps to 1
        expect(SliderNormalizer.labelForPolitical(6), 'Right'); // Clamps to 5
        expect(SliderNormalizer.labelForPolitical(-1), 'Left'); // Clamps to 1
      });
    });
  });
}
