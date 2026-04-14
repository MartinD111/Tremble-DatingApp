/// Slider Normalization Utility
///
/// Handles backward compatibility between old (0–1) and new (0–100) slider scales.
/// This was introduced to support multi-device preference sliders with percentage display.
///
/// **Migration Path:**
/// Old format: introvertScale: 0.0 (introvert) → 1.0 (extrovert)
/// New format: introvertScale: 0 (introvert) → 100 (extrovert)
///
/// This utility detects the old format at runtime and normalizes it,
/// ensuring no data loss for existing profiles.

class SliderNormalizer {
  /// Detects if a value is in the legacy 0–1 format.
  ///
  /// Returns `true` if the value should be treated as a legacy scale.
  /// Returns `false` if it's already in the new 0–100 format.
  ///
  /// **Logic:**
  /// - If value is `null`: treat as new format (not set)
  /// - If value <= 1.0 and value is a `double`: treat as legacy (0–1)
  /// - If value >= 0 and value is an `int`: treat as new (0–100)
  static bool isLegacyFormat(dynamic value) {
    if (value == null) return false;

    if (value is double) {
      // Double in 0–1 range → legacy format
      return value >= 0.0 && value <= 1.0;
    }

    if (value is int) {
      // Int in 0–100 range → new format
      return false;
    }

    // Unknown type → assume new format
    return false;
  }

  /// Converts a legacy 0–1 value to the new 0–100 format.
  ///
  /// If the value is already in the new format (≥ 1 or is an int),
  /// returns it unchanged.
  ///
  /// **Examples:**
  /// ```dart
  /// SliderNormalizer.toNewFormat(0.5)   // → 50
  /// SliderNormalizer.toNewFormat(0.0)   // → 0
  /// SliderNormalizer.toNewFormat(1.0)   // → 100
  /// SliderNormalizer.toNewFormat(50)    // → 50 (already new format)
  /// SliderNormalizer.toNewFormat(null)  // → null
  /// ```
  static int? toNewFormat(dynamic value) {
    if (value == null) return null;

    if (isLegacyFormat(value)) {
      // Legacy format (0–1) → multiply by 100
      return ((value as double) * 100).round();
    }

    if (value is int) {
      // Already in new format
      return value;
    }

    if (value is double && value > 1.0) {
      // Edge case: a very large double (>100) → treat as new format
      return value.toInt();
    }

    // Fallback: return as int if possible
    return (value as num).toInt();
  }

  /// Converts a new 0–100 value to the legacy 0–1 format.
  ///
  /// Used when a legacy API or display requires the old format.
  ///
  /// **Examples:**
  /// ```dart
  /// SliderNormalizer.toLegacyFormat(50)   // → 0.5
  /// SliderNormalizer.toLegacyFormat(0)    // → 0.0
  /// SliderNormalizer.toLegacyFormat(100)  // → 1.0
  /// SliderNormalizer.toLegacyFormat(null) // → null
  /// ```
  static double? toLegacyFormat(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return (value / 100.0).clamp(0.0, 1.0);
    }

    if (value is double) {
      if (value > 1.0) {
        // Assume new format → convert to legacy
        return (value / 100.0).clamp(0.0, 1.0);
      }
      // Already in legacy format
      return value;
    }

    // Fallback
    return ((value as num) / 100.0).clamp(0.0, 1.0);
  }

  /// Converts a normalized 0–100 value to a descriptive label.
  ///
  /// **Examples:**
  /// ```dart
  /// SliderNormalizer.labelForIntroversion(0)   // → "Introvert"
  /// SliderNormalizer.labelForIntroversion(25)  // → "Center-Left"
  /// SliderNormalizer.labelForIntroversion(50)  // → "Ambivert"
  /// SliderNormalizer.labelForIntroversion(75)  // → "Center-Right"
  /// SliderNormalizer.labelForIntroversion(100) // → "Extrovert"
  /// ```
  static String labelForIntroversion(int value) {
    value = value.clamp(0, 100);

    if (value <= 12) return 'Introvert';
    if (value <= 37) return 'Center-Left';
    if (value <= 62) return 'Ambivert';
    if (value <= 87) return 'Center-Right';
    return 'Extrovert';
  }

  /// Converts a 1–5 political affiliation scale to a label.
  ///
  /// Used for both own and partner preferences.
  ///
  /// **Examples:**
  /// ```dart
  /// SliderNormalizer.labelForPolitical(1) // → "Left"
  /// SliderNormalizer.labelForPolitical(2) // → "Center-Left"
  /// SliderNormalizer.labelForPolitical(3) // → "Center"
  /// SliderNormalizer.labelForPolitical(4) // → "Center-Right"
  /// SliderNormalizer.labelForPolitical(5) // → "Right"
  /// ```
  static String labelForPolitical(int value) {
    value = value.clamp(1, 5);

    switch (value) {
      case 1:
        return 'Left';
      case 2:
        return 'Center-Left';
      case 3:
        return 'Center';
      case 4:
        return 'Center-Right';
      case 5:
        return 'Right';
      default:
        return 'Center';
    }
  }
}
