import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RadarSearchSession — thin view-model consumed by RadarSearchOverlay.
//
// Both the production path (real Match + BLE proximity) and the dev-mode
// simulation produce one of these. The overlay reads only this object, which
// keeps it agnostic of the underlying source and prevents code drift between
// the two flows.
// ─────────────────────────────────────────────────────────────────────────────
@immutable
class RadarSearchSession {
  final String partnerName;
  final DateTime expiresAt;
  final bool showMutualFlash;

  /// The matched partner's uid. Drives the Pulse Intercept (Send Phone / Send
  /// Photo) meetup-assist buttons in the overlay. Null when unavailable (e.g. a
  /// dev simulation with no real partner uid) → the intercept is hidden.
  final String? partnerUid;

  /// The live match's id. Drives the precise turn-to-find opt-in (ADR-010).
  /// Null when there is no real match window (dev simulation) → the finder
  /// opt-in is hidden.
  final String? matchId;

  /// Caller invokes this when the user wants to terminate the search
  /// successfully — "Found each other" or "Stop Search".
  ///
  /// Returns a [Future] so the overlay can show progress while the backend
  /// `markMatchFound` round-trip completes and surface an error (rather than
  /// silently swallowing it and leaving the window open) if it fails.
  final Future<void> Function() onStop;

  const RadarSearchSession({
    required this.partnerName,
    required this.expiresAt,
    required this.onStop,
    this.partnerUid,
    this.matchId,
    this.showMutualFlash = false,
  });
}
