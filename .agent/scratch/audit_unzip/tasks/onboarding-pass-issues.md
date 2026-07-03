# Post-onboarding issues — triage and proposed fixes

**Status:** App reaches Home (`/safe-zones`, `/anonymous-mode`, `/` builder shows `name=Aleksandar`). Onboarding chain (App Check, iOS TLS via cupertino_http, R2 upload, `completeOnboarding`, draft writes to `drafts/{uid}`) is fully working. The issues below are pre-existing app-layer bugs surfaced by the first end-to-end run.

---

## 1. Language flips Slovenian → English on Google sign-in

**Symptom:** App launches with Slovenian UI (per saved preference). Tap "Sign in with Google" → UI flips to English.

**Root cause:** Two competing sources of truth for UI language.

- `appLanguageProvider` (the correct one) — backed by SharedPreferences, set in `main.dart`. UI source of truth for new code.
- `user.appLanguage` (from `AuthUser`) — read from Firestore via `_fetchUser`. Defaults to `'en'` when the Firestore doc has no `appLanguage` field yet (`lib/src/features/auth/data/auth_repository.dart:407`).

After Google sign-in, `signInWithGoogle()` → `_fetchUser()` → emits an `AuthUser` with `appLanguage='en'`. Several widgets render with `user.appLanguage` instead of `appLanguageProvider`, including settings/premium screens (e.g. `lib/src/features/settings/presentation/premium_screen.dart:444-477`, `lib/src/features/settings/presentation/settings_screen.dart:896`). So the UI flips even though SharedPreferences still says `sl`.

**Fix (preferred):** Make `appLanguageProvider` the only source. Replace `user.appLanguage` reads in widget code with `ref.watch(appLanguageProvider)`. Keep `user.appLanguage` solely as the persisted server-side field — written, never read by UI.

**Smaller alternative:** When `AuthUserNotifier` first sets a user post-sign-in, mirror `appLanguageProvider`'s current value back into `user.appLanguage` (don't let server default `'en'` overwrite the local preference). Persist to Firestore on next profile write.

**Files to touch:**
- `lib/src/features/auth/data/auth_repository.dart` (line ~1143 `signInWithGoogle` notifier path)
- Settings/premium screens that read `user.appLanguage`

---

## 2. Hidden nav bar leaves screen un-tappable on swipe

**Symptom:** Toggle "Hide Navigation bar" → swipe to Map zone → nav bar invisible AND screen is dead (taps do nothing).

**Suspect:** `lib/src/features/dashboard/presentation/home_screen.dart:643-686`. The outer `GestureDetector` uses `HitTestBehavior.translucent` covering the whole `Positioned.fill`, wrapping a `NotificationListener<ScrollNotification>`, wrapping the `AnimatedSwitcher` with the active screen.

When `hideNavBarPref` is on AND the page being shown (Map zone) has no scrollable that fires `ScrollNotification`, `isNavBarVisible` stays whatever it was (likely `false`). Two failure modes:
- The outer `GestureDetector.onHorizontalDragEnd` swallows taps because of `behavior: translucent` combined with empty horizontal velocity not bubbling.
- The hidden nav bar `IgnorePointer`/`AbsorbPointer` (whichever wraps it) may still be intercepting taps in its hidden position.

**Investigation steps before fix:**
1. Grep `IgnorePointer\|AbsorbPointer` around the nav-bar render block (after line 709).
2. Try `behavior: HitTestBehavior.deferToChild` instead of `translucent` on line 644 and confirm scroll detection still works.
3. Verify tap on Map content fires when `hideNavBarPref=false` (control case).

**Fix (most likely):** When nav bar is hidden, ensure the *hidden* widget has `IgnorePointer(ignoring: true)` so its (possibly off-screen but still hit-testable) bounds don't block content. Also: when switching tabs via swipe in hide mode, force `isNavBarVisibleProvider = true` for a couple seconds to give the user a target — or auto-show on any tap.

---

## 3. Can't add a Safe Zone

**Symptom:** Plus button in `/safe-zones` does nothing visible.

**Code path:** `lib/src/features/safety/presentation/safe_zones_screen.dart:562` → `_addZone()` at line 61 → eventually `addSafeZone(zone)` at line 318 → `safe_zone_repository.dart`.

**Investigation steps before fix:**
1. Read `_addZone()` body (line 61 onward) — does it open a map picker, request location permission, or just stub?
2. Check if `SafeZoneRepository.addSafeZone` writes to Firestore — and if Rules permit it. Current rules (`firestore.rules`) don't show a `safeZones` collection rule; under the default-deny on line 228 it'd fail silently.
3. Look for swallowed errors in `_addZone` — `try/catch` with a silent log is plausible.

**Likely fix:** Two layers — (a) add Firestore Rules for `safeZones/{userId}/zones/{zoneId}` allowing the owner to read/write, or move to `users/{uid}/safeZones/{id}` subcollection (subcollections aren't inherited from the parent rule and would still need their own block). (b) Surface the error to the UI (snackbar) instead of swallowing it so future failures are visible.

---

## 4. Can't dismiss the keyboard in chat

**Symptom:** Tap a text field → keyboard opens → no way to close it.

**Hypothesis:** The chat screen lacks a `GestureDetector` wrapping its body that calls `FocusScope.of(context).unfocus()` on tap. iOS doesn't auto-dismiss; you must explicitly handle it.

**Investigation:** Find chat screen (likely `lib/src/features/chat/...` or wherever the text input lives), confirm absence of unfocus-on-tap.

**Fix:** Wrap chat scaffold body with:
```dart
GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: () => FocusScope.of(context).unfocus(),
  child: ...,
)
```
Or set `TextField(textInputAction: TextInputAction.done)` and handle `onSubmitted`. Don't forget a "Done" button in the keyboard accessory toolbar if iOS-style is desired.

---

## 5. Map heatmap is mocked and doesn't subdivide on zoom

**Code:** `lib/src/features/map/presentation/tremble_map_screen.dart:50-72`. Comment on line 50 says it loud:
```dart
// Dev mock proximity circles (replace with Firestore stream in prod).
late final List<LatLng> _proximityPoints;
```
Seeded `Random(42)`, 22-32 points scattered around Ljubljana center. They render as fixed 120m radius `CircleMarker`s regardless of zoom (line 109-123). There's no clustering at all.

**Two separate fixes:**

**5a — Wire real data.** Replace `_generateProximityPoints()` with a stream from `proximity/` (or a dedicated aggregated `proximity_aggregates/` collection — the live `proximity` collection has per-user docs and isn't suited for client-side reads, since rules at `firestore.rules:164` say `allow read: if false`). Likely needs a new Cloud Function that bins active users by geohash prefix and writes aggregated counts to a client-readable collection.

**5b — Implement geohash bin clustering.** Convert points to geohash precision based on zoom:
- Zoom < 7 → geohash precision 3 (national bins)
- Zoom 7-9 → precision 4 (regional)
- Zoom 9-11 → precision 5 (city)
- Zoom > 11 → precision 6+ (neighborhood)

Render one circle per occupied bin with radius scaled to the bin's bounding box, and a count badge. Marker sizes shrink as user zooms in, exposing finer bins — which is what the user described as "should split based on heatmap count".

This is a multi-day feature, not a session-end fix.

---

## 6. English mode still shows Slovenian in tutorial offer

**Symptom:** In Settings (with English selected): `Spoznaj Tremble ponovno`, `Ponovni ogled kratkega interaktivnega vodiča`.

**Found:** `lib/src/features/settings/presentation/settings_screen.dart:1002,1006` — hardcoded Slovenian strings. No `t(...)` lookup.

**Fix:** Add translation keys to `lib/src/core/translations.dart`, e.g. `tutorial_replay_title`, `tutorial_replay_subtitle`, with `en`/`sl` entries. Replace the two hardcoded lines:
```dart
// Before
'Spoznaj Tremble ponovno',
'Ponovni ogled kratkega interaktivnega vodiča',

// After
t('tutorial_replay_title', lang),
t('tutorial_replay_subtitle', lang),
```
Also audit `'Hide Navigation bar'` and `'Auto-hide on scroll'` on lines 984-985 — those are *English* hardcoded strings that won't switch when user is in Slovenian mode (the mirror bug).

**Project-wide audit:** `grep -rn "Text('[A-Z]" lib/src/features/settings` and similar — likely many other static-string regressions.

---

## 7. Bonus — `updateProfile` Cloud Function failing with `invalid-argument`

**Surfaced in logs but not user-reported.** Visible at request time `2026-06-18T22:03:11`:

```
[API] Error in updateProfile: invalid-argument - Validation failed:
  nicotineUse: Expected string, received array;
  hasChildren: Expected boolean, received null;
  partnerDrinkingHabit: Expected string, received null;
  (...many more null fields)
  Unrecognized key(s) in object: 'selfIntrovertMin', 'lookingForNewJob',
  'selfIntrovertMax', 'graduatedUniversity', 'gymNotificationsEnabled',
  'onboardingCheckpoint'
```

Two separate problems:

**7a — Deployed `updateProfile` is stale.** Source schema (`functions/src/modules/users/users.schema.ts:17`) already uses the union `z.array | z.string` for `nicotineUse`. The deployed function still rejects arrays. We only redeployed `completeOnboarding` earlier. Run:
```bash
cd functions && firebase deploy --only functions:updateProfile
```

**7b — Client sends fields the server schema doesn't know.** `updateProfileSchema` is `.strict()` (line 85) — unknown keys are rejected. The Dart client's `AuthUser.toApiPayload()` includes `selfIntrovertMin`, `lookingForNewJob`, `selfIntrovertMax`, `graduatedUniversity`, `gymNotificationsEnabled`, `onboardingCheckpoint` which aren't in the schema. Either:
- Add those fields to `updateProfileSchema`, OR
- Strip them from `toApiPayload()` if they're client-only state.

Decide per field:
- `onboardingCheckpoint` — sounds client-only (resume mid-flow). Remove from payload.
- `gymNotificationsEnabled` — looks legitimate. Add to schema.
- `selfIntrovertMin/Max`, `lookingForNewJob`, `graduatedUniversity` — depends on whether these are real product fields. Check with PM/yourself.

**7c — Null-vs-omitted.** Many fields fail "Expected string, received null". Either the schema should be `z.string().nullable().optional()`, or the client should omit the key entirely when null instead of sending `null`. Latter is cleaner.

---

## Suggested fix order (cheapest → highest value)

| Order | Fix | Effort | Risk |
|---|---|---|---|
| 1 | Redeploy `updateProfile` (7a) | 1 min | low — pure deploy |
| 2 | Translation keys for hardcoded strings (6) | 30 min | low |
| 3 | Unfocus-on-tap in chat (4) | 15 min | low |
| 4 | Language source-of-truth fix (1) | 1-2 h | medium — touches many widgets |
| 5 | Strip unknown keys / extend schema (7b, 7c) | 1-2 h | medium |
| 6 | Safe-zone add (3) — diagnose first | 1-2 h | medium |
| 7 | Hidden nav bar dead-tap (2) | 1-3 h | medium |
| 8 | Real heatmap data + clustering (5a, 5b) | multi-day | high — new CF aggregator |

## Out of scope / separate work

- RevenueCat `isPremium` sync hitting Firestore Rules (`firestore.rules:21` deny-list) — client should never write `isPremium`; that's a RevenueCat webhook → Cloud Function flow. Remove the client write in `lib/src/app.dart:68`.
- `Target native_assets required define SdkRoot but it was not provided` warning at flutter run — Flutter tool noise on Xcode 26, not actionable in app code.

## Reference — what's confirmed working as of this run

- Firebase App Check (debug token bypass active on iOS)
- iOS TLS to Cloudflare R2 via `cupertino_http` `CupertinoClient`
- R2 presigned PUT (200, real bucket host)
- `completeOnboarding` (200, accepts `nicotineUse` array)
- `drafts/{uid}` writes — no more `permission-denied` flapping, no bounce off `/permission-gate`
- Reach Home screen, `/safe-zones`, `/anonymous-mode` routes
