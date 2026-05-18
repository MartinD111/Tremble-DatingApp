import 'package:flutter/animation.dart';

class TrembleMotion {
  const TrembleMotion._();

  /// Stoic Entrance - fast start, exceptionally soft landing.
  /// Use for card and modal entrances.
  static const Curve stoicEntrance = Cubic(0.16, 1.0, 0.3, 1.0);

  /// Snappy Feedback - immediate micro-interactions.
  /// Use for button and touch feedback.
  static const Curve snappyFeedback = Cubic(0.2, 0.8, 0.2, 1.0);

  /// Theatrical Reveal - long reveal with suspense and a slow close.
  /// Use only for Match Reveal and full-profile reveal transitions.
  static const Curve theatricalReveal = Cubic(0.86, 0.0, 0.07, 1.0);

  static const Duration instant = Duration(milliseconds: 150);
  static const Duration feedback = Duration(milliseconds: 200);
  static const Duration entrance = Duration(milliseconds: 400);
  static const Duration theatrical = Duration(milliseconds: 900);
}
