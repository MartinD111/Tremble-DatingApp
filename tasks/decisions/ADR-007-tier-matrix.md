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
| **HISTORY — MATCHES** | Prikaz matched profila (mutual wave) | Foto + ime + starost + 3 skupni hobiji/interesi | Celoten profil card v Trembling Window IN v history |
| | Prikaz matched profila (BREZ mutual wave) | **Greyscaled** — foto + ime + starost, brez interakcij | **Greyscaled** — foto + ime + starost, brez interakcij (fallback na Free-shape) |
| | Odpiranje profil kartice | ✗ | ✓ (samo pri mutual wave — compound gate `isPremium && hasMutualWave`) |
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
| ~~**NASTAVITVE**~~ | ~~Max distance slider~~ | ~~do 50 km~~ | ~~do 100 km~~ (**REMOVED — glej Amendment §5**) |

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

Split the History → Matches "Prikaz matched profila" row into two
explicit shapes gated on the mutual-wave predicate. Founder clarified
2026-07-13 (post first-cut wording revision):

- **When a MUTUAL wave exists** (both users have waved at each
  other):
  - **Free tier:** sees photo + name + age + **3 shared hobbies /
    interests** (top-3 by compatibility calculator). Card is
    tappable but the tap leads to the Free shape only — no full
    profile card open.
  - **Premium tier:** sees the **full profile card** in the
    Trembling Window AND in History. Tap opens the full card.

- **When NO mutual wave exists** (A waved to B, B did not reply):
  - **Both users** see the other in their History **greyed out /
    greyscaled** (photo desaturated).
  - **Both users** see ONLY photo + name + age (no shared hobbies,
    no card open, no interactions). This holds regardless of tier —
    Premium falls back to this same greyed shape.
  - Card is NOT tappable (or the tap is a no-op with an upsell /
    "wave back to unlock" affordance — copy TBD).

This means "Odpiranje profil kartice" is really a **compound gate**:
`isPremium && hasMutualWave(viewer, viewed)`. Neither condition alone
opens the card. Without mutual wave, both tiers see the greyscaled
minimal shape; without Premium, mutual wave only unlocks the
non-greyed Free-shape (photo + name + age + 3 shared hobbies).

**Implementation contract:**
- Client-side `MatchProfile` DTO gains a `hasMutualWave: bool` field
  populated from the server-side mutual-wave counter.
- Widget render layer applies three states in order: (a) no mutual
  wave → greyscale + minimal, (b) mutual wave + Free → colour +
  Free-shape, (c) mutual wave + Premium → colour + full card.
- Card-open (FULL card) tap gate: `isPremium && hasMutualWave`.
- Greyscale is achieved via `ColorFilter.matrix(_greyscaleMatrix)`
  wrapping the photo widget when `!hasMutualWave`.

**§1 Amendment — Session 53 (2026-07-20), founder-approved.** The Free +
mutual tap now opens the **basic card** (its own read-only screen
`BasicMatchProfileScreen`: photo + name/age + up to 3 shared-first
hobbies) instead of jumping straight to the paywall. The card carries a
subtle **"See full profile" CTA** (`t('see_full_profile')`) that opens
`PremiumPaywallBottomSheet` — so the conversion point is preserved while
honouring §1's original "tap leads to the Free shape" intent. The
compound gate is unchanged: only `isPremium && hasMutualWave` opens the
**full** `ProfileDetailScreen` (route `/profile`); Free routes to
`/profile?...&basic=true`. This keeps the `premium_feature_open_profile_cards`
paywall bullet truthful (the *full* card remains Premium-only, and the
CTA explicitly advertises it) — see LEGAL-005.

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

### §5 — Max distance slider row REMOVED

Founder clarified 2026-07-13: the "Max distance slider — Free 50 km /
Premium 100 km" row was a **mistake**. There is no distance-slider
widget wired to any meaningful distance value in the app (grep confirms
`PreferenceRangeSlider` is used for age + height only). Radar radius
is already tiered by ADR-007's first row (100 / 250 m via
`geo_service.dart` + `proximity.functions.ts`), which is the ONLY
distance concept the product needs.

**Impact:**
- Nastavitve row in the matrix table is struck through above.
- Paywall bullets `premium_feature_distance_100` and
  `premium_free_distance_50` (shipped in KORAK 3.7a) must be
  **removed wholesale** from `premium_screen.dart`. This is a
  correction of KORAK 3.7a, not new scope.
- Contract test in `premium_screen_test.dart` moves from 8 → 7
  Premium bullets and 7 → 6 Free bullets. Order preserved for the
  remaining rows.
- No CF or gate change — nothing was ever gated. Nothing to remove
  in production behaviour.

**Sub-KORAK impact:**
- 3.7c-5 (originally "distance slider tier bounds") is replaced by
  **3.7c-5R — Distance slider row removal** (code PR that retires
  the two paywall bullets + updates tests).

### §6 — Hard filters "coming soon" copy in all locales

Founder clarified 2026-07-13: keep the `premium_feature_hard_filters`
paywall bullet, but soft-label with "coming soon" until Amendment §2's
post-launch scope actually ships. Add the localised label to **all 8
locale blocks** in `premium_screen.dart._localTranslations` (en, sl,
de, hr, it, es, fr, pt) — not just EN + SL fallback.

Suggested phrasing per locale:
- en: "Additional hard filters beyond gender, age and nicotine (coming soon)"
- sl: "Dodatni hard filtri poleg spola, starosti in nikotina (kmalu)"
- de: "Weitere Hard-Filter neben Geschlecht, Alter und Nikotin (bald verfügbar)"
- hr: "Dodatni hard filtri osim spola, dobi i nikotina (uskoro)"
- it: "Filtri hard aggiuntivi oltre a genere, età e nicotina (in arrivo)"
- es: "Filtros adicionales además de género, edad y nicotina (próximamente)"
- fr: "Filtres avancés supplémentaires au-delà du genre, âge et nicotine (bientôt disponible)"
- pt: "Filtros adicionais além de género, idade e nicotina (em breve)"

The other feature bullets remain EN-only fallback for now (that is
existing behaviour, unchanged). Adding a full non-EN feature-bullet
translation pass is a separate translation task.

**Sub-KORAK impact:**
- 3.7c-2 (paused per §2) gets a satellite copy PR
  **3.7c-2C — Hard filters "coming soon" localisation** covering the
  8-locale label update.

### §4 — Ordered fix list revision (post-Amendment)

Applying §1-§3 to the audit's Priority 1-3 list:

| Priority | Sub-KORAK | Status |
|---|---|---|
| P1 | 3.7c-1 (matches shape + mutual-wave gate) | RESOLVED — implement compound gate `isPremium && hasMutualWave` on match card open and "full card" render |
| P1 | 3.7c-2 (hard filters) | REMOVED — paused until post-launch |
| P1 | 3.7c-4 (heatmap scope) | RESOLVED — splits into 3.7c-4a (count chip) + 3.7c-4b (filter subset count) |
| P2 | 3.7c-5R (distance row REMOVED) | REPLACES 3.7c-5 — retire paywall bullets, update tests |
| P2 | 3.7c-2C (hard filters "coming soon" localisation) | NEW — 8-locale label per §6 |
| P2 | 3.7c-3 (event pin gate trace) | UNCHANGED — scoped per §3 |
| P3 | 3.7c-6 through 3.7c-11 (pair-of-tests) | UNCHANGED |
| P4 | RSSI threshold | UNCHANGED — blocked on ADR-001 |

Next executable slice after this Amendment merges: **combined
3.7c-5R + 3.7c-2C** — both are `premium_screen.dart` + test edits,
LOW risk, single PR to save a round-trip. ~40 LoC total.

## Related documents

- `tasks/plans/PLAN_03_APP_CODE.md` §3.7 — implementation delta
  breakdown.
- `lib/src/features/subscriptions/application/revenuecat_subscription.dart`
  — entitlement plumbing already in place.
- `lib/src/core/geo_service.dart` — reference implementation of the
  server-first tier resolution pattern.
