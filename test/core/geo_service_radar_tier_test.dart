// ADR-007 §4 pair-of-tests — Radar-extended (100 m / -75 dBm vs
// 250 m / -85 dBm). `GeoService` is a Firebase-Auth + Battery +
// Geolocator singleton driven by a server-first premium resolution
// (`geo_effective_is_premium` SharedPref, ADR-007 §Cross-cutting-rule-1).
// A behavioural render pair would need Firestore + Geolocator +
// Battery mocking that dwarfs the assertion signal, so this file uses
// the source-scan wiring pattern already used by
// `test/features/recap/recap_ui_wiring_test.dart` and
// `test/features/match/near_miss_locked_state_test.dart:146`. The
// pair verifies that both the Free-tier and Premium-tier tuples are
// declared in the file and are wired through the same conditional so
// a future refactor cannot silently break either half of the gate.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/src/core/geo_service.dart').readAsStringSync();

  group(
      'ADR-007 §4 — radar_extended tier gate (paywall '
      'premium_feature_radar_extended)', () {
    test(
        'Free tier — 100 m + -75 dBm tuple is declared and '
        '`radiusTier` resolves to `free` when `_isPremium` is false', () {
      // The documented Free-tier tuple is present in the file. Both
      // legs of the tuple must appear together — dropping either one
      // silently regresses the paywall claim.
      expect(source, contains('Free    — GPS geohash pre-filter 100m'));
      expect(source, contains('RSSI threshold ≥ −75 dBm'));

      // The `_isPremium ? 'pro' : 'free'` ternary is the sole write
      // site for `radiusTier` per the Cross-cutting rule that the
      // server is the source of tier truth. The `false` branch MUST
      // resolve to `'free'` — that is what CFs read to apply the
      // Free-tier radius/RSSI. Pinning the exact literal prevents a
      // typo (`'free '`, `'Free'`, etc.) from silently reverting the
      // gate.
      expect(
        source,
        contains("final radiusTier = _isPremium ? 'pro' : 'free';"),
        reason: 'Free branch of the tier ternary must resolve to '
            "'free' — CFs read this to apply 100 m + -75 dBm",
      );

      // The tier is uploaded as `radiusTier` on the proximity doc.
      // The CF (proximity.functions.ts) branches on this value, so
      // the field name is the contract boundary.
      expect(source, contains("'radiusTier': radiusTier"));
    });

    test(
        'Premium tier — 250 m + -85 dBm tuple is declared and the '
        'same `radiusTier` ternary resolves to `pro` when '
        '`_isPremium` is true', () {
      // The documented Premium-tier tuple is present in the file.
      expect(source, contains('Premium — GPS geohash pre-filter 250m'));
      expect(source, contains('RSSI threshold ≥ −85 dBm'));

      // The `_isPremium ? 'pro' : 'free'` ternary — same site pinned
      // in the Free-tier test above — MUST have the `true` branch
      // resolve to `'pro'`. CFs read `'pro'` to apply 250 m + -85
      // dBm. Any drift here silently reverts Premium to Free reach.
      expect(
        source,
        contains("final radiusTier = _isPremium ? 'pro' : 'free';"),
        reason: 'Premium branch of the tier ternary must resolve to '
            "'pro' — CFs read this to apply 250 m + -85 dBm",
      );

      // `updatePremiumTier` is the runtime hook that flips
      // `_isPremium` after the server-first premium resolution
      // completes. If this method disappears the tier is frozen at
      // whatever `start()` was called with — Premium users would
      // stay stuck on Free reach until the next radar restart.
      expect(
        source,
        contains('void updatePremiumTier({required bool isPremium})'),
        reason: 'The runtime tier-flip must exist so RevenueCat '
            'premium unlocks the extended radar mid-session',
      );
    });
  });
}
