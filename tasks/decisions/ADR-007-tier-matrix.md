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
| **HISTORY — MATCHES** | Prikaz matched profila | Omejen (foto + ime + starost + 3 skupni hobiji/interesi) | Celoten profil card v Trembling Window IN v history — SAMO če je mutual wave |
| | Odpiranje profil kartice | ✗ | ✓ (samo pri mutual wave — glej Amendment §1) |
| **HISTORY — RECAPS** | Foto + ime + starost | ✓ (sivina) | ✓ (barvno) |
| | Odpiranje profil kartice | ✗ | ✓ |
| | 10-min TTL val iz recapa | ✗ | ✓ |
| | Arhiv po izteku TTL | ✗ | ✓ (read-only) |
| **NEAR-MISS HISTORY** | Tab viden | ✗ | ✓ |
| | Odpiranje profil kartice | ✗ | ✓ (read-only) |
| | Upsell banner (nearMissCount) | ✓ | ✗ |
| **FILTRI** | Osnovno (spol, starost) | ✓ | ✓ |
| | Nicotine exclusion filter | ✓ | ✓ |
| | Ostali hard filtri | ✗ | ✓ (**POST-LAUNCH — glej Amendment §2**) |
| **MAP** | Event pini na mapi | ✓ (lokacija + share link) | ✓ (+ število udeležencev + potential matches) |
| | Število udeležencev na eventu | ✗ | ✓ |
| | Heatmap indikator na event pinu | ✗ | ✓ |
| | Heatmap krogi | ✓ (samo obris, brez števila) | ✓ (število uporabnikov + filter po tipu → potential matches count) |
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

## Amendments 2026-07-13 (post-audit clarifications)

The KORAK 3.7b audit (`tasks/AUDIT_TIER_MATRIX_20260713.md`) flagged
three rows as ambiguous. Founder clarified 2026-07-13; these
amendments override the corresponding rows above.

### §1 — Matches shape and the mutual-wave predicate

Split the History → Matches "Prikaz matched profila" row into an
explicit Free shape and an explicit Premium shape, both gated on the
mutual-wave predicate:

- **Free tier — always sees:** profile photo, name, age, and **3
  shared hobbies or interests** (top-3 by compatibility calculator).
  Nothing more, regardless of tier of the OTHER user.
- **Premium tier — sees FULL profile card** in two contexts:
  1. During the Trembling Window (real-time surface).
  2. In History with the matched person.
  ...**but ONLY when a mutual wave exists** (both users have waved at
  each other). Without a mutual wave, Premium sees the same Free
  shape (photo + name + age + 3 shared items).
- **Asymmetric-wave case (A waved, B did not):** BOTH users still
  appear in each other's History (this preserves ADR-007's
  "prikaz omejen" row for Free), but each user sees according to
  their OWN tier. Free B sees Free-shape of A; Premium A sees
  Premium-shape of B if mutual — otherwise Free-shape of B.

This means the "Odpiranje profil kartice ✗ / ✓" row is really a
compound gate: `isPremium && hasMutualWave(viewer, viewed)`. A
Premium-only gate on card-open is NOT sufficient — the mutual-wave
check must land in the same predicate.

### §2 — Hard filters PAUSED until post-launch

The "Ostali hard filtri" row (Free ✗ / Premium ✓) is deferred to
post-launch. Paywall copy already advertises it (via
`premium_feature_hard_filters` shipped in KORAK 3.7a), but the
underlying filter surface + gate will not be built in the current
KORAK 3.7 wave. When the feature ships, its own KORAK will re-open
this row with a concrete filter list.

**Impact on 3.7 sub-KORAK-i:** the audit's Priority 1 item 3.7c-2
(hard-filters scope) is removed from the fix list. The paywall bullet
remains truthful as a "coming soon" claim in the sense that ADR-007
still declares the intent; verify with founder whether the bullet
should be soft-labelled ("coming soon") or left as-is.

### §3 — Heatmap and event tiers

The Map section is expanded to reflect what the Free / Premium user
actually sees on the map:

- **Free tier:**
  - Heatmap circles: sees the **circle outline** only. No user count,
    no color intensity that reveals density, no "X users here" chip.
  - Event pins: sees the **location + share link**. Cannot see the
    participant count.
- **Premium tier:**
  - Heatmap circles: sees the **user count inside the circle** AND
    can **filter by their own preference type** (e.g. filter the
    circle from "150 users nearby" down to "35 potential matches"
    per their filter settings).
  - Event pins: sees the participant count AND **potential matches
    count** (subset of participants that fit their filters).

**Impact on 3.7 sub-KORAK-i:** the audit's Priority 1 items 3.7c-3
(event pin sheet gate trace) and 3.7c-4 (heatmap scope) are now
scoped:
- 3.7c-3 becomes concrete: verify existing gates for participant count
  + heatmap indicator; add if missing.
- 3.7c-4 splits into 3.7c-4a (heatmap-count chip on circles — Premium
  only) and 3.7c-4b (per-filter subset count — Premium only). Both
  require a Firestore aggregate or CF endpoint that returns a
  filtered count, not just a total. Design pending.

### §4 — Ordered fix list revision (post-Amendment)

Applying §1-§3 to the audit's Priority 1-3 list:

| Priority | Sub-KORAK | Status |
|---|---|---|
| P1 | 3.7c-1 (matches shape + mutual-wave gate) | RESOLVED — implement compound gate `isPremium && hasMutualWave` on match card open and "full card" render |
| P1 | 3.7c-2 (hard filters) | REMOVED — paused until post-launch |
| P1 | 3.7c-4 (heatmap scope) | RESOLVED — splits into 3.7c-4a (count chip) + 3.7c-4b (filter subset count) |
| P2 | 3.7c-5 (distance slider bounds) | UNCHANGED — next executable slice |
| P2 | 3.7c-3 (event pin gate trace) | UNCHANGED — scoped per §3 |
| P3 | 3.7c-6 through 3.7c-11 (pair-of-tests) | UNCHANGED |
| P4 | RSSI threshold | UNCHANGED — blocked on ADR-001 |

Next executable slice after this Amendment merges: **3.7c-5**
(distance slider bounds) — LOW risk, small diff, no scope dependency.

## Related documents

- `tasks/plans/PLAN_03_APP_CODE.md` §3.7 — implementation delta
  breakdown.
- `lib/src/features/subscriptions/application/revenuecat_subscription.dart`
  — entitlement plumbing already in place.
- `lib/src/core/geo_service.dart` — reference implementation of the
  server-first tier resolution pattern.
