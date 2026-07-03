# Audit Step 4 — History / Recaps
**Date:** 2026-06-06  
**Auditor:** Antigravity AI  
**Claim domain:** C-HISTORY-01 → C-HISTORY-09  
**Instruction:** Report MATCH / MISMATCH / CANNOT VERIFY. Cite exact file:line. Do NOT edit anything.

---

## Item 1 — Matches Tab: Free vs Premium Card Gating

**Claim:** Strategy implies Premium shows full card; Free is locked/limited when they receive a wave but haven't responded.

**Finding: MATCH (partial)**

The gating logic lives in `matches_screen.dart:671`:

```dart
// Lock samo za Recap: nekdo TI je poslal wave, ti nisi odgovoril
final isRecapLock = !isPremium && theyWaved && !iWaved;
```

- `isRecapLock = true` only when: Free user + the other person waved at them + they did not wave back.
- When `isRecapLock` is true: card renders with `Opacity(0.6)`, hidden profile image (replaced with a generic `LucideIcons.user` placeholder), the name shows as `t('someone_sent_you_wave', lang)`, details hidden, and an "Upgrade to see" pill shown. (`matches_screen.dart:671,732,735,776-898`)
- When `isRecapLock` is false (Premium, or Free who already waved): full card renders with name, age, zodiac, matchType badge.
- **Gap vs strategy claim:** The strategy speaks of a general "limited vs full card" tier difference on the Matches tab. The actual implementation is more nuanced: Free users DO see full cards for profiles where they were the wave sender or for mutual matches. The "limited card" only applies to the incoming-wave-not-yet-responded case. This is architecturally sound but the claim description is imprecise.

---

## Item 2 — Recap Greyscale Gate

**Claim C-HISTORY-01:** "Recaps tab Free: Foto + ime + starost, sivina, brez akcije"  
**Claim C-HISTORY-07:** "Post-run recap Free: foto + ime + starost, sivina, brez akcije"

**Finding: MATCH**

In `run_recap_screen.dart:644-652`:

```dart
if (widget.isPremium) return contentWithError;

return ColorFiltered(
  colorFilter: const ColorFilter.mode(
    Colors.grey,
    BlendMode.saturation,
  ),
  child: contentWithError,
);
```

- Free users: `ColorFiltered(BlendMode.saturation)` applied → full desaturation (greyscale). ✅
- Free users: the wave button (`showWaveButton`) is only rendered when `shouldTrackTTL && !effectiveIWaved && !isExpired && widget.onWave != null`.  
  `shouldTrackTTL = widget.isPremium && widget.isActive && !widget.isHistory` → **false for Free** → wave button never renders. ✅
- Free users: card is `isReadOnly = true` (non-tappable). ✅
- Name, age are still rendered in the content (just desaturated). ✅

---

## Item 3 — Recap Greyscale: No Card-Open for Free

**Claim:** Free recap cards have "brez akcije" (no action).

**Finding: MATCH**

In `run_recap_screen.dart:505-511`:

```dart
onTap: isReadOnly
    ? null
    : () => context.push('/profile', extra: ...),
```

`isReadOnly = !widget.isPremium || widget.isHistory || isExpired`

- For Free users: `!widget.isPremium = true` → `isReadOnly = true` → `onTap = null` → card is not tappable. ✅

---

## Item 4 — Premium Recap: Colour + 10-min TTL Wave

**Claim C-HISTORY-02 / C-HISTORY-08:** "Premium: barvno, kartica + 10 min TTL za val"

**Finding: MATCH**

- Premium recap renders `contentWithError` directly without `ColorFiltered`. (`run_recap_screen.dart:644`) ✅
- TTL tracking starts only for Premium + active + not history: `_startTTLIfNeeded()` checks `widget.isPremium && widget.isActive && !widget.isHistory`. (`run_recap_screen.dart:432-440`) ✅
- TTL countdown rendered as `_formatRemaining(ttlState.remainingSeconds)` when `shouldTrackTTL`. (`run_recap_screen.dart:547-561`) ✅
- Wave button shown within TTL window: `showWaveButton = shouldTrackTTL && !effectiveIWaved && !isExpired && widget.onWave != null`. (`run_recap_screen.dart:499-502`) ✅
- Firestore TTL on `proximity_events` is `10 * 60 * 1000` ms = **600 seconds = 10 minutes**. (`proximity.functions.ts:715`) ✅

---

## Item 5 — Recap Archive: Free Not Persisted After Close

**Claim:** Free recaps are NOT persisted after close.

**Finding: MATCH (with nuance)**

In `run_recap_screen.dart:100-122`, `_markViewedRecapsOnClose()`:

```dart
if (user == null || ref.read(effectiveIsPremiumProvider)) return;  // only runs for Free
...
ref.read(viewedRecapsRepositoryProvider).markViewedRecapsOnClose(...)
```

- When a Free user closes the RunRecapScreen, all currently active recap IDs are written to `users/{uid}/viewedRecaps/{recapId}`. (`viewed_recaps_repository.dart:46-58`)
- The history section then filters out docs where `viewedRecapIds.contains(doc.id)`. (`run_recap_screen.dart:318`)
- **Effect:** Once a Free user dismisses the recap screen, the viewed recaps disappear from both active and history view. This is the "not persisted" mechanism — they're not truly deleted but hidden by client-side exclusion. The Firestore `proximity_events` doc itself expires via TTL (10 min). ✅
- **Premium:** `effectiveIsPremiumProvider` returns true → `_markViewedRecapsOnClose()` returns immediately → Premium recaps remain visible in history section (read-only archive). ✅

---

## Item 6 — "To ni več naključje" — 2nd Encounter Notification

**Claim C-HISTORY-06:** "Ob 2. srečanju z isto osebo: forced notif 'To ni več naključje'"

**Finding: CANNOT VERIFY — Feature NOT implemented**

- Searched all Cloud Functions for: `naklju`, `coincidence`, `secondEncounter`, `second_encounter`, `encounterCount`, `seenBefore`, `repeatProximity`, `twice`.
- **Zero matches** in any `.ts` file.
- Searched Flutter client for same terms. Zero matches.
- The `scanProximityPairs` CF (`proximity.functions.ts:609-826`) uses a **30-minute Redis cooldown per pair** (`proximityCooldownKey`). After cooldown expires, the same pair would trigger again — but there is no counter tracking "how many times this pair has been notified" and no special message for the 2nd encounter.
- The `proximity_events` Firestore write also contains no encounter count field.

**Verdict: MISMATCH** — The claim specifies a "forced notif" on the 2nd encounter with the same person. No such logic exists in the codebase. This is an **unimplemented feature**.

---

## Item 7 — Near-Miss History Tab Visibility (CRITICAL CHECK)

**Claim C-HISTORY-03:** "Near-Miss History Free: Tab ni viden"

**Finding: MISMATCH — ⚠️ PARTIAL CRITICAL**

The Near-Miss (Activity) tab **IS visible to Free users** in the Matches screen.

Evidence in `matches_screen.dart:94-98`:

```dart
static const _tabs = <(String, String?)>[
  ('match_tab_all', null),
  ('match_tab_event', 'event'),
  ('match_tab_activity', 'activity'),   // ← Tab 3: Activity/Near-Miss
  ('match_tab_gym', 'gym'),
];
```

The `_tabs` list is fixed. All 4 tabs render for ALL users unconditionally at line `585`:

```dart
tabs: _tabs.map((tab) => Tab(text: t(tab.$1, lang))).toList(),
```

No `isPremium` check gates the `'match_tab_activity'` tab from the tab bar.

**What IS gated for Free users in the Activity tab:**
- Near-Miss profiles (`matchType == 'activity'`) are individually locked: `isNearMissLocked = isNearMiss && !isPremium` (`matches_screen.dart:730`)
- When `isNearMissLocked`, the profile image is blurred, name shows "Someone nearby", card is non-tappable (redirects to paywall).
- A `_NearMissUpsellCard` appears at the end of the activity list showing count with a paywall CTA. (`matches_screen.dart:713-723`)

**Strategy says the tab should be fully hidden for Free users. Current implementation shows the tab but locks individual cards.**

This is a **MISMATCH** against the literal claim. However, it is arguable whether the intent is "hide tab" or "hide content within tab." The current UX (tab visible, content locked) serves as an upsell vector. Flagging for founder decision.

**Severity: MEDIUM** — Not a data leak. Free users see no PII (names/photos blurred). But the tab is visible when strategy says it should not be.

---

## Item 8 — Near-Miss Monthly Push (FREE users, count only)

**Claim C-HISTORY-04:** "Near-Miss History Free: 1×/mesec agregirano push notifikacijo (samo število)"

**Finding: CANNOT VERIFY — Feature NOT implemented**

- Searched all Cloud Functions for: `nearMiss`, `near_miss`, `monthly`, `aggregat`, `count.*push`, `cron`, `1.*month`.
- No scheduled CF exists that sends a monthly Near-Miss aggregate push notification.
- The exported functions in `index.ts` include no Near-Miss monthly notification scheduler.
- The only scheduled notifications are: `expireGymSessions` (hourly), `expireRunModes` (hourly), `expireEventModes` (hourly), `scanProximityPairs` (every 1 min).

**Verdict: MISMATCH** — The monthly aggregate push to Free users for Near-Miss count does not exist in the backend. **Unimplemented feature.**

---

## Item 9 — Near-Miss History Premium: Full Profile Card

**Claim C-HISTORY-05:** "Near-Miss History Premium: Odpreš kadarkoli, celoten profil kartica"

**Finding: MATCH**

In `matches_screen.dart:729-731`:

```dart
final isNearMiss = isNearMissProfile(profile);
final isNearMissLocked = isNearMiss && !isPremium;
final isNearMissReadOnly = isNearMiss && isPremium;
```

For Premium users:
- `isNearMissLocked = false` → not blurred, real name shown. ✅
- Card tap opens profile: `onTap = () => _openProfile(profile)`. (`matches_screen.dart:760-764`) ✅
- `disableTrailingActions = isLocked || isNearMissLocked || isNearMissReadOnly` → trailing actions (report/remove) disabled for Near-Miss even for Premium, which makes sense for read-only. ✅

---

## Item 10 — Compatibility Score: Never Stored (CRITICAL CHECK)

**Claim (audit requirement):** Compatibility score must NEVER be stored in Firestore.

**Finding: MATCH — CLEAN**

The `compatibility_calculator.ts` file has explicit comments at lines 6-7:

```typescript
// - Score je INTERNI signal, nikoli se ne shrani v Firestore
// - Score se nikoli ne pošlje v UI response (ne kot polje na nearbyUsers)
```

And in `proximity.functions.ts:361-362`:

```typescript
// Compatibility score — interni signal, nikoli se ne shrani ali vrne v UI
// KRITIČNO: nearbyUsers.push() spodaj ne sme vsebovati score polja
```

The `nearbyUsers.push()` at line 414-418 contains ONLY `{ userId, distanceM }`. The `score` variable is used ONLY for the threshold comparison (`if (score >= threshold)`) and is then discarded.

Zero Firestore writes of the `score` value. Zero score fields in the nearbyUsers response. ✅

---

## Summary Table

| Claim ID | Claim | Verdict | Severity |
|---|---|---|---|
| C-HISTORY-01 | Free recap: greyscale + no action | **MATCH** | — |
| C-HISTORY-02 | Premium recap: color + 10-min TTL wave | **MATCH** | — |
| C-HISTORY-03 | Near-Miss tab hidden for Free | **MISMATCH** | MEDIUM |
| C-HISTORY-04 | Free: monthly aggregate Near-Miss push (count only) | **MISMATCH (NOT IMPLEMENTED)** | LOW |
| C-HISTORY-05 | Premium Near-Miss: full profile card | **MATCH** | — |
| C-HISTORY-06 | 2nd encounter → "To ni več naključje" forced notif | **MISMATCH (NOT IMPLEMENTED)** | LOW |
| C-HISTORY-07 | Free run recap: greyscale + no action | **MATCH** | — |
| C-HISTORY-08 | Premium run recap: color + 10-min TTL | **MATCH** | — |
| C-HISTORY-09 | Run encounter 10-min TTL | **MATCH** | — |
| (audit extra) | Compatibility score never stored | **MATCH** | — |
| (audit extra) | Free Matches tab: limited card for incoming wave | **MATCH** | — |

---

## Issues Requiring Founder Decision

### ISSUE-H1 (MEDIUM): Near-Miss Tab Visible to Free Users
- **Strategy says:** Tab hidden for Free
- **Reality:** Tab visible, individual cards locked/blurred with paywall CTA
- **Current UX** acts as an upsell funnel — Free user sees the tab, sees locked cards with count, taps → paywall
- **Decision:** Keep current (upsell funnel) or hide tab entirely per strategy literal
- **Files to change if hidden:** `matches_screen.dart` — conditionally render `_tabs` based on `isPremium`

### ISSUE-H2 (LOW): "To ni več naključje" — 2nd Encounter Notification Not Built
- Missing in both backend and client
- Would require: encounter counter per pair in Redis or Firestore, increment on each proximity event, trigger special FCM payload on count == 2
- **Impact:** Minor UX feature gap; no security or data issue

### ISSUE-H3 (LOW): Near-Miss Monthly Aggregate Push Not Built
- Missing CF scheduler
- **Impact:** Free users do not receive the monthly count notification described in strategy
- Low priority; requires a `onSchedule('every month')` CF + Firestore query of Free user activity counts
