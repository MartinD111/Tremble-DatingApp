# AUDIT — Tier Matrix Feature Parity (2026-07-13)

**Purpose:** KORAK 3.7b deliverable per `tasks/plans/PLAN_03_APP_CODE.md`.
For every row in ADR-007 (`tasks/decisions/ADR-007-tier-matrix.md`),
compare the ADR-declared behaviour against the actual code and
produce a prioritised fix list that feeds sub-KORAK-i 3.7c-3.7n.

**Method:** grep-driven, main-branch snapshot after PR #25 merge
(commit `0cd8b4c`). No code changed. Each row is verdict-tagged:

- ✅ **OK** — gate matches ADR-007 exactly, no fix needed.
- ⚠️ **PARTIAL** — mechanism exists but is incomplete, inconsistent
  server↔client, or lacks the pair-of-tests ADR-007 §4 requires.
- ❌ **MISSING** — gate does not exist; ADR-007 promise is aspirational.
- 🟦 **N/A** — row applies to both tiers with no gate needed.

**Source-of-truth summary:**
- Server tier truth: `isPremium` computed inside every Cloud Function
  from the requester's Firestore `users/{uid}` doc (RevenueCat entitlement
  or grandfathered flag). Client MUST NOT be trusted for gate decisions.
- Client tier truth: `effectiveIsPremiumProvider` (Riverpod). Persisted
  to SharedPreferences (`geo_effective_is_premium`) so background BLE /
  radar services can read it without a Riverpod scope.

---

## RADAR

### Radius — Free 100 m / Premium 250 m
**Verdict:** ✅ OK

**Server (`functions/src/modules/proximity/proximity.functions.ts`):**
- `RADIUS_FREE_M = 100`, `RADIUS_PRO_M = 250` (lines 40–41).
- `findNearby` computes `radiusTier = isPremium ? "pro" : "free"` (line 239)
  and returns `radiusM` accordingly (line 376).
- `getProximityMatchCandidates` mirrors the same logic (lines 433, 426).

**Client (`lib/src/core/geo_service.dart`):**
- Comment header pins the same pair (lines 20–21).
- `radiusTier` field written into the proximity doc based on `_isPremium`
  (see comment at line 255).

**Missing:** none. Pair-of-tests requirement — a Free-user 250 m regression
test would be worth adding as part of 3.7z but is not blocking.

### RSSI threshold — Free −75 dBm / Premium −85 dBm
**Verdict:** ⚠️ PARTIAL

**Server:** the threshold is only documented in the `proximity.functions.ts`
header comment (lines 38–39). No runtime enforcement — server does not
filter BLE encounters by RSSI at all (BLE encounters are client-side).

**Client:** the threshold is documented in the `geo_service.dart` header
comment (lines 20–21) but not applied anywhere — the BLE stack is still
mocked (per ADR-001; `background_service.dart` uses a mock timer, not
`flutter_blue_plus`). RSSI enforcement is genuinely blocked by ADR-001.

**Fix action:** deferred until ADR-001 (BLE) is lifted. Track as
`3.7c-rssi-threshold-tier` but keep it dormant behind ADR-001. Do NOT
include in the imminent 3.7c-3.7n fix wave.

### Proximity detekcija / Proximity notifikacija (Free)
**Verdict:** ✅ OK — both flow through `sendCrossingPaths` (proximity
functions) and the client radar without any `isPremium` gate. Verified by
KORAK 3.1 (PR #17, notification visibility) and confirmed here.

---

## WAVE

### Pošiljanje vala / Prejemanje vala (Free)
**Verdict:** ✅ OK — no `isPremium` guard in wave send/receive paths
(`functions/src/modules/matches/matches.functions.ts` handleWaveSubmission).

### Mutual waves per month — Free 5 / Premium 20
**Verdict:** ✅ OK

- `MUTUAL_WAVE_FREE_LIMIT = 5`, `MUTUAL_WAVE_PREMIUM_LIMIT = 20` (`matches.functions.ts:38-39`).
- Counter field `mutualWaves_YYYY_MM` (Europe/Ljubljana) written by both
  Flutter (`lib/src/features/auth/data/auth_repository.dart:26`) and CF
  (`matches.functions.ts:56`) — single source of truth.
- Enforcement in `matches.functions.ts:251-252` reads
  `mutualWaveCountForUser(userAData, counterField)` per user before
  granting the mutual-wave slot.

**Missing:** pair-of-tests. `matches.test.ts` has a general
`mutualWaveCountForUser` test but no dedicated "Free hits 5-cap /
Premium hits 20-cap" pair. Not blocking; add in 3.7z.

---

## TREMBLING WINDOW

### 30-min active radar (Free)
**Verdict:** ✅ OK — Trembling Window activation not gated by
`isPremium` in `home_screen.dart` / `dashboard/application/`. Confirmed
by KORAK 3.3 (Gym Mode gate removal) and the existing free-tier radar path.

### Pulse Intercept — Send Phone + Send Photo (Free)
**Verdict:** ✅ OK

**Server (`functions/src/modules/matches/intercept.functions.ts`):**
- `requestPulseIntercept` (line 37) does NOT read `isPremium` anywhere
  (grep = 0). The gate is a mutual-match check + rate limit + TTL, not a
  tier check.
- Send Phone and Send Photo variants share the same code path — both
  are Free by construction.

**Client:** the Pulse Intercept UI in the Trembling Window sheet
(`run_recap_screen.dart`) shows both actions to all users without any
`isPremium` clause.

**Missing:** pair-of-tests that would REGRESS if a future gate is
accidentally added. Add in 3.7z (a "Free user can request Pulse
Intercept" positive test).

---

## HISTORY — MATCHES

### Prikaz matched profila — Free omejen / Premium celoten
**Verdict:** ⚠️ PARTIAL

**Client (`matches_screen.dart`):**
- `isPremium = ref.watch(effectiveIsPremiumProvider)` (line 399).
- Recap-lock overlay: `isRecapLock = !isPremium && theyWaved && !iWaved`
  (line 671) — controls whether a Free user sees a locked overlay on
  the profile card thumbnail.
- Match section: full profile card open path in `_MatchGridCard`
  (line 700) uses `isPremium` but the "limited vs full" split is not
  formally defined anywhere — it appears to hinge on the recap lock,
  which is a related but different gate.

**Ambiguity:** ADR-007 says "Prikaz matched profila: Free omejen /
Premium celoten" but the code exposes a `theyWaved && !iWaved` variant
that toggles the lock. Founder must clarify:
- Does "Free omejen" mean **only the thumbnail (name + age + first photo)**
  is shown until the user waves back? — OR —
- Does "Free omejen" mean **the profile is visible but interactions are
  locked** (no card open, per the row below)?

**Fix action:** clarify with founder in 3.7c-1 (LOW risk), then align
UI copy. If clarification lands as "thumbnail-only until reciprocation",
the current recap-lock code already implements it — just needs the
matching contract test.

### Odpiranje profil kartice — Free ✗ / Premium ✓
**Verdict:** ✅ OK — `matches_screen.dart` gates the card-open tap via
`isPremium` in the `_MatchGridCard`/`_RecapCard` tap handlers (verified
by presence of `isPremium` in the tap-callback branches at lines 657,
689, 700).

**Missing:** pair-of-tests. Add in 3.7z.

---

## HISTORY — RECAPS

### Foto + ime + starost — Free sivina / Premium barvno
**Verdict:** ✅ OK

`run_recap_screen.dart` uses `widget.isPremium` to control image opacity:
- Line 530: `.withValues(alpha: widget.isPremium ? 1.0 : 0.4)`
- Line 544: same pattern.

Visual regression for the sivina/barvno split relies on golden tests
(`test/features/recap/`) — verify presence in 3.7z.

### Odpiranje profil kartice iz recapa — Free ✗ / Premium ✓
**Verdict:** ✅ OK — `run_recap_screen.dart:645` short-circuits to the
error-inclusive content only when `widget.isPremium` is true; the tap-to-
open handler is guarded upstream.

### 10-min TTL val iz recapa — Free ✗ / Premium ✓
**Verdict:** ✅ OK — `run_recap_screen.dart:479` computes
`isTtlActive = widget.isPremium && widget.isActive && !widget.isHistory`.
The wave-from-recap button is only shown when `isTtlActive` is true.

### Arhiv po izteku TTL (read-only za Premium) — Free ✗ / Premium ✓
**Verdict:** ✅ OK — `run_recap_screen.dart:498` computes
`isReadOnly = !widget.isPremium || widget.isHistory || isExpired`.
Free users see the fully-locked variant; expired-Premium sees read-only.
`viewed_recaps_repository.dart:67` early-returns `false` for Premium
users when computing "is this recap unread?" (Premium always sees full
recap history without the "new" badge).

---

## NEAR-MISS HISTORY

### Tab viden — Free ✗ / Premium ✓
**Verdict:** ✅ OK — `matches_screen.dart:54` predicate
`if (isPremium && isNearMissSection) { ... }` controls tab visibility.
`isNearMissProfile(profile) => profile.matchType == 'activity'` (line
29) identifies near-miss rows.

### Odpiranje profil kartice (read-only) — Free ✗ / Premium ✓ read-only
**Verdict:** ✅ OK — `matches_screen.dart:730-731`:
- `isNearMissLocked = isNearMiss && !isPremium`
- `isNearMissReadOnly = isNearMiss && isPremium`

The pair fully encodes ADR-007: Free = locked (no open), Premium =
read-only open.

### Upsell banner (nearMissCount) — Free ✓ / Premium ✗
**Verdict:** ✅ OK — `matches_screen.dart:40`:
`return activeSection == MatchSection.run && !isPremium && nearMissCount > 0;`

Matches ADR-007 exactly.

---

## FILTRI

### Osnovno (spol, starost) — Free ✓ / Premium ✓
**Verdict:** 🟦 N/A — no gate, both tiers use the same filter path.

### Nicotine exclusion filter — Free ✓ / Premium ✓
**Verdict:** 🟦 N/A — implemented in `nicotine_step.dart` +
`compatibility_calculator.ts`, no `isPremium` guard.

### Ostali hard filtri — Free ✗ / Premium ✓
**Verdict:** ❌ MISSING (or **PARTIAL — spec ambiguity**)

The paywall now advertises "Additional hard filters beyond gender, age
and nicotine" (`premium_screen.dart:312`), but:
- Grep across `lib/src/features/settings/` returns **no** `isPremium`
  guard on any filter widget except the nicotine one (which is free).
- No CF-level filter that reads `isPremium` before applying it
  (compatibility calculator applies all filters uniformly).

**Two possible interpretations:**
1. **Feature does not exist yet.** ADR-007 declares an intent; the
   corresponding gate + additional filter fields must be built.
2. **Feature exists but is unlabeled.** There may be hidden filter
   surfaces (religion / ethnicity / lifestyle) already implemented in
   the settings screen but not tier-gated. Grep of the settings screen
   suggests otherwise but is not exhaustive.

**Fix action:** highest-priority ambiguity to resolve with founder before
3.7c-3.7n begin. If interpretation (1): scope is potentially large (new
filter surface + Firestore query changes + CF gate). If (2): scope is a
one-file gate addition. Track as **3.7c-2 — Hard filters gate scoping**.

---

## MAP

### Event pini na mapi — Free ✓ / Premium ✓
**Verdict:** 🟦 N/A — post KORAK 3.5, event pins are read from Firestore
`events` collection for all tiers.

### Število udeležencev na eventu — Free ✗ / Premium ✓
**Verdict:** ⚠️ PARTIAL

**Client (`event_pin_sheet.dart`):** header comment at line 30 says
"Pro tier / Taste of Premium: all of the above + people count + heatmap
indicator" — so the intent is documented. Grep for `isPremium` in
`event_pin_sheet.dart` returns only comment matches, not an actual gate
in the participants-count render path.

**Fix action:** verify with a full read of `event_pin_sheet.dart` in
sub-KORAK 3.7c-3. If gate missing, add per ADR-007. Server side is a
non-issue (participants count is a Firestore aggregate read; the gate is
a client-only render decision).

### Heatmap indikator na event pinu — Free ✗ / Premium ✓
**Verdict:** ✅ OK (locked-state string) / ⚠️ PARTIAL (gate flow)

- `event_pin_sheet.dart:155-158`: ternary between `_HeatmapActiveRow`
  (Premium) and a locked variant with `t('heatmap_locked', lang)` label.
- The `heatmap_locked` string exists in every locale (`translations.dart`
  8 hits).

**Ambiguity:** the ternary condition needs to be verified — grep did
not surface an explicit `isPremium` at line 155. Trace in 3.7c-3.

### Heatmap krogi — Free ✓ (brez podatkov) / Premium ✓ (s podatki)
**Verdict:** ❌ MISSING

Grep across `lib/src/features/map/presentation/` shows no dedicated
heatmap-circle layer that differentiates "empty" from "with data". This
appears to be an aspirational ADR-007 row for now. The paywall bullet
`premium_free_event_pins` mentions "empty heatmap circles" but the map
layer that renders them may not exist.

**Fix action:** verify with a full read of `tremble_map_screen.dart`
around the heatmap layer. If missing, this is a new-feature build
(bigger than a gate flip). Founder may want to defer to
**KORAK 3.8 subtask 3** (heatmap real geohash aggregation, currently
tagged POST-LAUNCH). Track as **3.7c-4 — Heatmap tier layer scoping**.

---

## NASTAVITVE

### Max distance slider — Free do 50 km / Premium do 100 km
**Verdict:** ⚠️ PARTIAL

**Widget (`preference_range_slider.dart`):**
- Accepts `isPremium` param (line 33).
- Header comment says: `if true caller must guard interaction` (line 16)
  — meaning the widget itself does NOT enforce the tier bound; the
  caller must clamp.

**Caller:** grep for the slider caller in `settings_screen.dart` returns
no `isPremium` clamp. The bound (50 km / 100 km) is not enforced anywhere
in the codebase per today's grep pass.

**Fix action:** highest-value **quick win** — add an `isPremium`-aware
`sliderMax` prop or clamp in the settings screen. Track as
**3.7c-5 — Distance slider tier bounds** (LOW risk, small diff).

---

## Ordered fix list (feeds 3.7c-3.7n)

Ordered by **impact / risk / effort** balance. Founder can re-prioritise
at any time — priority here reflects the audit's read of user visibility
and business value.

### Priority 1 — Ambiguity resolution (no code)
These must be founder-clarified before any code lands, because the
scope of the corresponding 3.7c-* PR depends on the answer.

1. **3.7c-1 — Matches "Prikaz matched profila" spec clarification.**
   ADR-007 says "Free omejen / Premium celoten" but the code exposes a
   related-but-different recap-lock gate. Get a one-sentence definition
   of "omejen" from founder.
2. **3.7c-2 — Hard filters scope clarification.** ADR-007 promises a
   Premium-only hard-filter set but grep finds none in code. Founder to
   decide: build new (bigger) or expose existing settings surfaces (smaller).
3. **3.7c-4 — Heatmap krogi scope clarification.** ADR-007 promises
   Free = empty circles, Premium = data circles, but no such layer is
   in code. Founder to decide: defer to post-launch (KORAK 3.8-3) or
   build now.

### Priority 2 — Quick, unambiguous gate additions
These are small diffs (single-file or two-file) with clear ADR-007-
matching behaviour and no scope ambiguity.

4. **3.7c-5 — Distance slider tier bounds.** Add `isPremium`-aware max
   to the caller of `PreferenceRangeSlider` in `settings_screen.dart`.
   ~15 LoC + widget test.
5. **3.7c-3 — Event pin sheet participants count + heatmap indicator
   gate verification.** Trace the `isPremium` flow through
   `event_pin_sheet.dart`; if any of the three rows (participants
   count / heatmap indicator / locked-state) lacks a real gate, add
   it. ~30 LoC + widget test.

### Priority 3 — Consistency test coverage (blocking 3.7z)
No behaviour change; adds the pair-of-tests requirement from
ADR-007 §4 to gates that already work.

6. **3.7c-6 — Radar radius pair-of-tests.** Free-user hits 100 m,
   Premium hits 250 m — server-side test in `proximity.test.ts`.
7. **3.7c-7 — Mutual waves cap pair-of-tests.** Free-user 5-cap /
   Premium 20-cap — server-side test in `matches.test.ts`.
8. **3.7c-8 — Pulse Intercept Free-visibility positive test.** Regression
   guard against a future accidental gate.
9. **3.7c-9 — Match card open tap-gate pair-of-tests.** Free = tap does
   not open, Premium = tap opens. Client widget test.
10. **3.7c-10 — Recap gates full pair-of-tests suite.** Sivina/barvno,
    open, TTL wave, archive read-only — one test per row.
11. **3.7c-11 — Near-Miss tab + card + upsell pair-of-tests.** Three
    ADR-007 rows, one client widget test each.

### Priority 4 — Deferred (blocked on ADR-001)
12. **3.7c-rssi-threshold-tier.** Do not touch until ADR-001 (BLE)
    ships. RSSI thresholding is meaningless while the BLE stack is a
    mock timer.

### 3.7z — Integration test suite (LAST)
After 3.7c-3.7n merge, roll up the pair-of-tests into a single
integration matrix (one row per ADR-007 line) so future regressions
show up as one predictable failure per broken gate.

---

## Assumptions and blind spots

- Grep-only audit. No runtime tracing, no debugger, no actual RevenueCat
  entitlement toggling. A gate that reads `isPremium` under a name I
  did not grep for (`isPro`, `hasEntitlement`, etc.) would be invisible
  to this audit. Reasonable confidence given the codebase's consistency
  in the `isPremium` naming.
- KORAK 3.5 (Event Mode Firestore) is assumed to have landed the
  `event_pin_sheet.dart` header comment describing the Pro/Free split,
  not an actual gate. Verify in 3.7c-3.
- The audit did not read `viewed_recaps_repository.dart` in full — only
  confirmed the top-level `isPremium` guard exists at line 67.
- No golden-test coverage check for the recap sivina/barvno gate.
- ADR-001 (BLE) is treated as still-active per prior sessions; if it
  has silently shipped since, RSSI enforcement can be added in the
  imminent 3.7c-3.7n wave rather than deferred.
