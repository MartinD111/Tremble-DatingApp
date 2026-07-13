# ADR-007 — Tremble Tier Matrix (Free vs Premium)

**Status:** ACCEPTED
**Date:** 2026-07-13
**Deciders:** Aleksandar Bojić (founder)
**Supersedes:** all prior ad-hoc gating decisions embedded in
`premium_screen.dart`, individual feature files, and the compliance
report's Part V observations. Any conflict between this document and
existing code is a bug against this ADR.

---

## Context

`premium_screen.dart` advertises features that were never gated in
code (e.g. "unlimited geofence pings", "advanced filtering matrix"),
while other implemented gates (see-who-waved, near-miss recap
visibility) are not surfaced anywhere on the paywall. The compliance
report (Part V) called this out during KORAK 3.7 prep.

Rather than paper over the mismatch with copy edits, the founder
locked the full Free-vs-Premium matrix as the source of truth. The
matrix describes the shipping product, not an aspirational spec — any
deviation in code is a bug to fix.

Pulse Intercept — one of the recurring paywall debates — is
**Free in BOTH variants (Send Phone AND Send Photo)** because it is a
core-mechanic promise ("no chat, just essentials"). Monetisation
comes from richer history + wider radar surface area.

## Decision — Tier Matrix (source of truth)

| Group | Feature | Free | Premium |
|---|---|---|---|
| **RADAR** | Radius | 100 m | 250 m |
| | RSSI threshold | −75 dBm | −85 dBm |
| | Proximity detekcija | ✓ | ✓ |
| | Proximity notifikacija | ✓ | ✓ |
| **WAVE** | Pošiljanje vala | ✓ | ✓ |
| | Prejemanje vala | ✓ | ✓ |
| | Mutual waves / mesec | 5 | 20 |
| **TREMBLING WINDOW** | 30-min active radar | ✓ | ✓ |
| | Pulse Intercept — Send Phone | ✓ | ✓ |
| | Pulse Intercept — Send Photo | ✓ | ✓ |
| **HISTORY — MATCHES** | Prikaz matched profila | Omejen | Celoten |
| | Odpiranje profil kartice | ✗ | ✓ |
| **HISTORY — RECAPS** | Foto + ime + starost | ✓ (sivina) | ✓ (barvno) |
| | Odpiranje profil kartice | ✗ | ✓ |
| | 10-min TTL val iz recapa | ✗ | ✓ |
| | Arhiv po izteku TTL | ✗ | ✓ (read-only) |
| **NEAR-MISS HISTORY** | Tab viden | ✗ | ✓ |
| | Odpiranje profil kartice | ✗ | ✓ (read-only) |
| | Upsell banner (nearMissCount) | ✓ | ✗ |
| **FILTRI** | Osnovno (spol, starost) | ✓ | ✓ |
| | Nicotine exclusion filter | ✓ | ✓ |
| | Ostali hard filtri | ✗ | ✓ |
| **MAP** | Event pini na mapi | ✓ | ✓ |
| | Število udeležencev na eventu | ✗ | ✓ |
| | Heatmap indikator na event pinu | ✗ | ✓ |
| | Heatmap krogi | ✓ (brez podatkov) | ✓ (s podatki) |
| **NASTAVITVE** | Max distance slider | do 50 km | do 100 km |

## Cross-cutting rules

1. **Server is the source of tier truth.** Every gate MUST be enforced
   in Cloud Functions before it is enforced in Flutter. The client
   MUST NOT read local premium flags without server confirmation for
   any gate that affects data visibility. `geo_service.dart` already
   follows this pattern (`geo_effective_is_premium` SharedPref written
   only after server round-trip) — reuse it.
2. **Legacy display-side gates that don't match the matrix are bugs.**
   No grandfathering, no dark-launch flags — align both surfaces (CF +
   Flutter) in the same PR per gate.
3. **Copy rules (paywall + upsell surfaces):** EN + SL together, no
   forbidden phrases (revolutionary, seamless, game-changing, find
   love today, find your person, swipe, match queue, chat), no emoji
   in headlines, describe mechanics not emotions. Pricing may appear.
4. **Consistency assertion tests:** for every gated feature, add a
   pair of tests: (a) Free user hits gate → correct behavior (limit /
   locked / grey / hidden); (b) Premium user does not hit gate →
   correct behavior. This closes the "advertised but not gated" and
   "gated but not advertised" holes in one motion.
5. **RevenueCat entitlement key stays `premium`** (already in
   `revenuecat_subscription.dart:10`).

## Consequences

- KORAK 3.7 in PLAN_03 is no longer "paywall copy fix"; it is now the
  umbrella for a multi-PR effort to bring code in line with this
  matrix. See PLAN_03 §3.7 for the ordered sub-KORAK breakdown.
- Existing gate code that already matches this matrix (radar radius
  100/250 m, geo_service premium resolution) stays as-is and is
  reused, not rewritten.
- Existing UI copy in `premium_screen.dart` (`premium_feature_wider_
  radar`, `premium_feature_unlimited_geofence`, `premium_feature_
  custom_themes`, `premium_feature_advanced_filters`) is replaced
  wholesale — the matrix is the copy source.

## Non-goals of this ADR

- Pricing tiers, weekend-pass semantics, and yearly/lifetime plan
  economics are unchanged.
- RevenueCat product IDs and receipt validation flow are unchanged.
- Server-side matchmaking algorithm and BLE proximity engine are
  unchanged.

## Related documents

- `tasks/plans/PLAN_03_APP_CODE.md` §3.7 — implementation delta
  breakdown.
- `lib/src/features/subscriptions/application/revenuecat_subscription.dart`
  — entitlement plumbing already in place.
- `lib/src/core/geo_service.dart` — reference implementation of the
  server-first tier resolution pattern.
