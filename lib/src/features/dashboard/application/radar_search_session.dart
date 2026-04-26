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

  /// Caller invokes this when the user wants to terminate the search
  /// successfully — "Found each other" or "Stop Search".
  final VoidCallback onStop;

  const RadarSearchSession({
    required this.partnerName,
    required this.expiresAt,
    required this.onStop,
    this.showMutualFlash = false,
  });
}
