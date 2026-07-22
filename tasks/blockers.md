# Blockers & Investigation Findings

---

## POST-MATCH FLOW REPAIR (Session 50-51 — branch `fix/post-match-flow-repair`, PR #69)

> Full detail + priority order in `context.md` Session 51. Batch 2 shipped in build 29.

### BLOCKER-POSTMATCH-CI — PR #69 CI red (blocked merge)
**Status:** ✅ RESOLVED (Session 51, `a9ba5eb`). **The Session-50 root-cause guess was wrong.** The CI failure was NOT TREMBLE-FUNCTIONS-12 — it was a Flutter framework assert *"ListTile background color or ink splashes may be invisible"* (×2), fired because `UgcActionSheet` wrapped its `ListTile`s in an opaque `Container`/`DecoratedBox` with no `Material` between. It only reproduces on CI's newer `stable` Flutter (local is pinned 3.41.4 → passes locally). Fixed structurally: the sheet surface is now a `Material(color:)`. See lesson #93.

### BLOCKER-POSTMATCH-DIALOGS — iOS block + report broken (crash TREMBLE-FUNCTIONS-12)
**Status:** ✅ RESOLVED (Session 51, `a9ba5eb`). Block + report rebuilt as themed **Material bottom sheets**; dropped `CupertinoAlertDialog`/`TrembleAlertDialog` for these two. No more `Platform.isIOS` branch → no `Material.of` null, testable on all platforms, dark-themed (#9), report scrolls with a Submit (#10), block works (#8). `ugc_action_sheet.dart` rebuilt (`_BlockConfirmSheet` + `_ReportSheet`). NOTE: `tremble_alert_dialog.dart` still used by settings/edit-profile/discard/safe-zones/email-location — those are Text-only confirms (no Material-in-Cupertino), left as-is. **Needs iOS device verification on build 29.**

### BLOCKER-POSTMATCH-PHOTO — reveal "?" (email gate)
**Status:** 🔧 FIX SHIPPED TO BRANCH + DIAGNOSTIC DEPLOYED (Session 52, `e87f73c` + `fc737e6`), awaiting build-30 device confirm.

**Session-52 resolution (two-track, per founder decision):**
- **Root-cause instrumentation (deployed to prod):** `getPublicProfile` now logs which branch nulls the reveal (`target-doc-missing | caller-in-blockedBy | no-match-doc | OK`) — `functions/src/modules/users/users.functions.ts`. Redeployed to `am---dating-app`/europe-west1 (`fc737e6`). Because the current source already carries `requireAuth` (`dbbc7b7`), this redeploy ALSO tests the "stale email-gate deploy" hypothesis — if that was the cause, the reveal recovers on build 29 immediately. **Next device tap writes the decisive log line** (Firebase console → Functions → getPublicProfile logs, `[USERS getPublicProfile]`).
- **Preferred fix (client, `e87f73c`):** reveal + trembling window re-sourced from `getMatches`/`MatchProfile` via new `partnerMatchProfileProvider` — the proven People-tab path — so partner photo/name/age no longer depend on `getPublicProfile`. Also added the always-visible `TremblingPartnerCard` (FEATURE-POSTMATCH-TREMBLING-REDESIGN step 2). run-club `LiveRunCard` (home_screen:2464) stays on `getPublicProfile` (pre-match strangers, not in getMatches). 380/380 Flutter + 163 CF green, analyze clean.
- **REMAINING:** build 30 → device: (a) reveal + trembling window show real identity; (b) partner card tap → profile (premium) / paywall (free); (c) read the CF log to confirm the original cause and decide if the diagnostic can be removed / whether recap needs the same re-source.

**Prior (Session 52 investigation) —** The `requireVerifiedEmail`→`requireAuth` deploy (`dbbc7b7`) did NOT fix it — build 29 STILL shows "?" on the match page AND no partner identity in the trembling window. `publicProfileProvider(partnerId)` → `getPublicProfile` returns null/throws and is **silently swallowed** (reveal `.whenOrNull(data:)`; `ProfileRepository.getPublicProfile` throws on `profile==null`) — zero Sentry events for `release:…@1.0.0+29`. RULED OUT: match-ID mismatch (creation `matches.functions.ts:593` + CF lookup both sorted `uidA_uidB`) and match-doc schema (`matches.functions.ts:682` has userA/userB/userIds). Cause UNKNOWN. **P0. Next:** (a) surface the swallowed error — temporary `Sentry.captureException` in the client repo catch OR per-branch logging in the CF + redeploy — to learn permission vs App-Check vs match-gate; (b) PREFERRED FIX: re-source the reveal + profile card + history from `getMatches`/`MatchProfile` (`matches.functions.ts:964`, `match_repository.dart:126/189`), which already returns name/age/photoUrls/hobbies via Admin SDK and works for the matches list — one proven path, sidesteps getPublicProfile.

### FEATURE-POSTMATCH-TREMBLING-REDESIGN — always-visible profile card + full intercept flow (Session 52 founder spec)
**Status:** OPEN (design locked, see context.md Session 52 target spec). Trembling window top→bottom: (1) partner profile card — circle photo + name/age under it, ALWAYS visible, tap → free/premium full card; (2) radar (spinning, partner dot past the circle edge); (3) pulse intercept — Send Photo opens camera (Snapchat-style) → send → recipient notification/pill → tap opens photo; Send Phone → recipient notification → tap → dialer/call; + timer + working Stop. History → free-user basic card (not greyscale). `RadarSearchOverlay` already carries `partnerUid`; extend to show the card (source from `MatchProfile`).

### FEATURE-POSTMATCH-INTERCEPT — move Pulse Intercept into the trembling window
**Status:** ✅ RESOLVED (Session 51, `095b50c`). New `PulseInterceptBar` widget (`match/presentation/widgets/`); rendered in `RadarSearchOverlay` (the trembling window) above the countdown when `session.partnerUid != null` (prod passes computed `partnerId`, dev-sim `profile.id`). Removed from `match_reveal_screen` (reveal = photo+age+3 hobbies). **Needs device verification of placement.** Still OPEN (uninvestigated, cluster 3): pulse-intercept notification image never viewable + duplicate 2× on the send/receive side.

### UI-POSTMATCH-PILLS — in-app pills too high
**Status:** ✅ PARTIAL (Session 51, `e094a5d`). `WavePillService` pill moved `topPad+14 → topPad+80` (matches `_MatchNotificationPillOverlay`), clears the mode + schedule control bar. **STILL OPEN:** iOS "wave sent" shows 2× overlapping "is nearby" — presentation dedup between the local pill and the APNs pill (cluster 2). Needs device repro.

### FEATURE-POSTMATCH-NOTIFTAP — notification tap opens profile card
**Status:** OPEN (Step 4, NOT done). Tapping a "nearby" / "wave" notification must open the partner's profile card (free vs premium view differs). Deferred: needs notification-tap handler wiring (`router.dart` / `notification_service` / `wave_pill_service`) + the free/premium card + device verification.

---

## SESSION 53 — NEW DEVICE FINDINGS (build 30, 2026-07-20)

### BUG-BLOCKED-USERS-LIST — Blocked Users screen fails to load whenever ≥1 user is blocked
**Date:** 2026-07-20
**Status:** ✅ RESOLVED (Session 53) — PR #72 merged to main (`f11c30c`); `getBlockedUsers` callable **DEPLOYED to prod** (`am---dating-app`/europe-west1, created 2026-07-20). Ships in **build 31**. Device-verify: block a user → Settings → Blocked Users renders them (name + photo); unblock works.
**(root cause, for reference)** CONFIRMED by static analysis (not a guess)
**Symptom (device, build 30):** Opening Settings → Blocked Users shows the red error "Blokiranih uporabnikov ni bilo mogoče naložiti. Preveri povezavo in poskusi znova." An empty blocklist renders the "Nobody blocked" empty state fine; after blocking Martin (toast "Martin has been blocked" confirms the write succeeded), the list errors.
**Root cause:** `blockedUsersProvider` (`lib/src/features/safety/presentation/blocked_users_screen.dart:28-30`) does a **direct** `FirebaseFirestore.instance.collection('users').doc(id).get()` for each blocked UID. Firestore rules `firestore.rules:141` — `match /users/{userId} { allow read: if isSelf(userId); }` — permit reading **only your own** doc. Every blocked user's doc is a non-self read → `PERMISSION_DENIED` → `Future.wait` throws → the provider's `error:` branch. The empty case works only because it returns `[]` early (line 26) before any cross-user read. **This is the same bug class as the reveal "?" (BLOCKER-POSTMATCH-PHOTO): a client reading arbitrary `/users/{id}` docs directly instead of via a Cloud Function.** The block/unblock writes themselves are fine — they route through the `blockUser`/`unblockUser` callables (`safety_repository.dart:16-22`).
**Fix (proposed, MEDIUM):** add a `getBlockedUsers` callable (Admin SDK, returns `{id, name, imageUrl}` for the caller's `blockedUserIds`) and re-source the provider from it — mirrors the batch-3 `getMatches` re-source pattern. Do NOT loosen `firestore.rules:141`. TDD lane, own branch/PR.

### BUG-HISTORY-CARD-TAP — history tile tap must open the gated profile card
**Date:** 2026-07-20
**Status:** ✅ RESOLVED (Session 53) — PR #73 merged to main (`ffcf6b3`). Free + mutual tap → `BasicMatchProfileScreen` (photo + name/age + 3 hobbies + "See full profile · Premium" CTA → paywall); Premium → full card. Client-only, ships in **build 31** (no deploy). ADR-007 §1 Amendment + LEGAL-005 note recorded. Device-verify: Free mutual tap → basic card + CTA→paywall; Premium mutual tap → full card.
**Spec:** In Your Matches / history, a mutually-matched tile currently shows name + age + photo + hobbies (read-only). Tapping it must open the full profile card the **same way Settings opens the own-profile card** — gated by the viewer's package: **Free** sees name + age + photo + 3 hobbies; **Premium** sees the entire profile card (as if viewing their own). This is the `TremblingPartnerCard` tap→`/profile`(premium)/paywall(free) gate applied to history tiles too. Reuse `MatchProfile` + `effectiveIsPremiumProvider` — no new direct reads. TDD lane; pairs naturally with the build-31 notif-tap card (both open the same gated card).

### CONFIG-REVENUECAT-OFFERINGS — RevenueCat "offerings empty" debug banner
**Date:** 2026-07-20
**Status:** OPEN — **configuration, NOT a code bug** (founder/dashboard lane)
**Symptom (device, build 30):** A red RevenueCat debug overlay: "You have configured the SDK with an App Store API key, but there are no App Store products registered in the RevenueCat dashboard for your offerings … https://rev.cat/why-are-offerings-empty". Appears app-wide (seen behind the Matches screen), unrelated to the block flow it was captured next to.
**Cause:** RevenueCat SDK is initialised with the Apple API key, but the Offerings in the RevenueCat dashboard have no App Store Connect products attached (products/offerings not yet configured for `tremble.dating.app`). Client code is not at fault.
**Action (founder):** In App Store Connect create the IAP/subscription products (Premium, Weekend Getaway) and attach them to the RevenueCat offering; verify the offering returns products. Until then the paywall has nothing to sell. Ties into BLOCKER-LEGAL-004 (weekend package) + LEGAL-005 (paywall bullets). Not an assistant code lane; no rotation/secret involved.

---

## SESSION 54 — BUILD 31 DEVICE FINDINGS (2026-07-20)

> Build 31 tested on device (iPhone + Samsung SM-S916B). iOS on TestFlight (UUID `db31765d-8d5a-450b-a628-659e9e2eb847`), Android on Play (versionCode 31). Each item below = its own TDD lane / branch / PR next session. Fixes are proposals, not yet implemented.

### BUG-MATCH-PAGE-LAYOUT — reveal photo overlaps the hobby pills
**Date:** 2026-07-20 · **Status:** SHIPPED (Session 55, PR #76) — single centered scroll-safe column; geometric no-overlap test. Device-review vertical rhythm. · **Risk:** MEDIUM (visual)
**Symptom:** On the match reveal + "We have a match" page, the circular partner photo is drawn **over** the hobby pills (e.g. "Pohodništ…" / "Plavanje" clipped behind the photo). Layout/z-order bug — hobbies should sit fully above the photo.
**Where:** `match_reveal_screen` (hobby row + circular avatar stacking). **Fix:** restructure the column so the hobby pill row has its own vertical band above the avatar (no `Stack` overlap / fix ordering + spacing). Golden/widget test for no-overlap. NOTE: the profile card itself is "bad but doable for MVP" — do NOT redesign the card this lane; only fix the overlap.

### BUG-IS-NEARBY-PERSISTS — "is nearby" pill never dismisses
**Date:** 2026-07-20 · **Status:** SHIPPED (Session 55, PR #78) — `WavePillService.dismissForTarget(uid)` from `WaveController.handleWave` on success + `dismiss()` in `MatchRevealScreen.initState`. Cluster-2 iOS 2× dedup still deferred. · **Risk:** MEDIUM
**Symptom:** The "{name} is nearby" pill stays on screen after (a) you wave to that person, and (b) you navigate into the match page. It should clear in both cases.
**Where:** `WavePillService` / `_MatchNotificationPillOverlay` (same surfaces as UI-POSTMATCH-PILLS). **Fix:** dismiss the pill for a given partner uid when a wave is sent to that uid AND on match-page/trembling-window entry; add lifecycle test. Pairs with cluster-2 (iOS 2× pill dedup) — consider one pill-lifecycle lane.

### BUG-RADAR-DOT → RECLASSIFIED **FEATURE-RADAR-SONAR** — privacy-by-design search-and-rescue sonar
**Date:** 2026-07-20 · **Status:** **DEVICE PASS RUN 2026-07-22 (Session 62) — PRECISE FINDER VALIDATED ON iOS.** iPhone 15 Pro Max: first successful real-world precision find — solid arrow + live "NN m" (12/25/39/75 m observed), distance counts down while walking, dot tracks as the phone turns, movement reflected live. Screenshots + prod CF logs confirm the full loop (mutual wave → 3s `updateFinderLocation` cadence both platforms → `markMatchFound` purge → block/unblock eval-without-notify all clean). **Feature stays OPEN for:** (a) iPhone 15 (non-Pro) misbehaved — founder to re-test with the DIAG-IPHONE15-FINDER checklist below; (b) Android + cross-platform pass; (c) two spun-out bugs found during the pass: BUG-HAPTICS-PERSIST (HIGH) + BUG-RADAR-OFF-DISCOVERABLE (CRITICAL) — see SESSION 62 section. · **Risk:** HIGH (core feature + sensors + BLE + prod CF + precise location, device-only) · **(cluster 4)**

> **Session-61 (2026-07-22) — PRECISE TURN-TO-FIND SHIPPED.** ADR-010 reverses "honest degrade": inside an active mutual window, per-window RECIPROCAL one-tap opt-in ("Help us find each other" pill in `RadarSearchOverlay`) shares precise location **server-side only** — `updateFinderLocation` callable stores raw coords in rules-locked `matches/{id}/finder/{uid}` (deny-all client rules, 16/16 emulator tests; ~2-min TTL **ACTIVE** on `finder.expireAt`; atomic purge on `markMatchFound`) and returns ONLY `{partnerSharing, bearing?, distanceM?, reason?}`, window-token-bound (`notificationOwnerWaveId`). Client: `PreciseFinderController` (3s cadence, foreground-only — backgrounding revokes; `inactive` interruptions like a call banner do NOT), precise bearing feeds the dot through `SonarPingController` at compass framerate (`preciseRadius`, 75m full scale), "NN m" live distance label, coarse-arrow fallback gated by `bearingIsMeaningful` ('~150m'/'far' only). Free for everyone; opt-in resets every window (lives on the match doc, no per-user migration). **Deployed to `am---dating-app`/europe-west1:** rules + `updateFinderLocation` + `markMatchFound`. Pre-release bug hunt caught + fixed the finderOptIn poll-churn dot flicker (Rule #102, `5c033a5`, redeployed). **Build 35 (`1.0.0+35`) on TestFlight** — Delivery UUID `7b6785b1-7819-4dd0-8e90-5d159c3adb41`; AAB at `release-symbols/b35/app-prod-release.aab` (founder → Play Console, versionCode 35). **OWED — two-phone device pass on build 35:** both opt in → arrow points true + distance counts down walking 60→10m; one declines → other stays on fallback copy ("They're close — look around"), never a precise arrow; background one phone → its sharing stops (partner falls back within ~10s); "We found each other" → coords purged. If the arrow misbehaves, the B0 kDebugMode diagnostic overlay still reads RSSI/bearing/heading. Accepted risk (ADR-010 addendum): a consented partner could feed fake coords to triangulate within the window — inherent to arrow+distance, bounded by reciprocity + revocability + TTL.

> **Session-58/59 — PHASE B MERGED + DEPLOYED + BUILD 33.** Turn-to-find shipped: B0 dev-only diagnostic overlay (`kDebugMode`) · B1 `flutter_compass_v2 ^1.0.3`/**ADR-009** · B2 pure `computeBearing`/`distanceBucket` (`bearing.ts`) + `updateActiveMatchBearing` writer on active match, **DEPLOYED to `am---dating-app`/europe-west1 (`--project prod`)** · B3 `compassHeadingProvider`/`dotAngle`/`smoothHeading`/`Match.bearingFor` · B4 controller integration (`dotAngle(bearing−heading)`, orbit fallback, `bucketToRadius`). analyze clean, Flutter 438/438, jest 182/182, tsc clean. Painter angle convention reconciled (0 = right, not top — Rule #101). **OWED — combined two-phone device pass on build 33:** dot from ~150m via server bearing → swings with compass → BLE warmth in final meters. If blank/wrong on-device, open the **B0 diagnostic overlay** (kDebugMode build): `RSSI —`=production writer not firing / `bearing —`=server bearing not written (check match doc + scanProximityPairs prod logs) / `heading —`=compass unavailable. Everything below is the Session-54/55/56 build-up (superseded by the shipped implementation).

> **Session-56 progress — PHASE A DONE (client-only, no new dep):** Root cause held exactly (missing production writer, not render). Built TDD on `feature/radar-sonar`: `SonarPing` + `rssiToRadius` + signal-state machine + `orbitAngle` (pure, unit-tested); `SonarPingController` (evolved the orphaned `ProximityPingController`) emits `SonarPing` from real `ble.proximityStream` RSSI; production writer arm at `home_screen.dart:445` feeds `pingDistance/Angle` during a live mutual wave (+ keep-alive `ref.watch` in `_RadarSection`); "Searching…" caption (EN/SL/HR) on signal loss. Full suite green (~413 tests). **Design+plan: `docs/superpowers/specs|plans/2026-07-21-radar-sonar-turn-to-find*`.**
> **Direction model DECIDED (hybrid, Phase B):** geohash-7 bearing (reuse `geo_service.dart` publish + `decodeGeohash` in `proximity.functions.ts`) for the 250m approach + BLE warmth for final ~30m. Compass (`flutter_compass_v2`, needs **ADR-008 + founder approval**) supplies heading; `dotAngle = wrap(bearing − heading)`. The noisy RSSI-peak inference is OFF the critical path. **Device pass owed before Phase B.**
> **Session-55 update:** root cause CONFIRMED — the dot painter is fully wired (`radar_painter.dart:115` draws when `pingDistance != null`); the only writer of `pingDistance/pingAngleProvider` is the dev-sim bridge (`home_screen.dart:445`), so real mutual waves never feed a dot. NOT a render bug — a missing production data source. Founder's real ask is a **sonar/search-and-rescue radar**: stop-sweep, dot pulses every 1–2s (closer/further), turn-to-find via the device compass, NO fixed location (privacy is the point). BLE has no bearing → direction must be inferred from **RSSI×compass-heading**. Needs compass wiring + estimator + redesigned pulse overlay; device-only to validate. Do brainstorm→plan→approval next session. Full vision: memory `radar-sonar-search-feature`. Original Session-54 lead below (superseded).
>
> **Technical starting points (Session 55 scout — factual base for the plan):**
> - **Distance signal EXISTS:** `ble_service.dart:67` `Stream<Map<String,int>> get proximityStream` emits `rssiMap[deviceId] = result.rssi` per scan (`ble_service.dart:184`). Per-partner RSSI is already consumed in `warmth_controller.dart:49-57` (partnerId → RSSI → warmer/colder). Map raw RSSI → `pingDistance` 0..1 here.
> - **Direction signal MISSING — needs a NEW dependency.** pubspec has NO compass/magnetometer package (only `geolocator: ^14.0.2`). Turn-to-find requires `flutter_compass` or `sensors_plus` (magnetometer heading). Adding it is a `dependencies.md` lane → **ADR + founder approval** (MPC HIGH). This is the gating decision for the whole feature.
> - **Render layer (reuse, don't rebuild):** `radar_painter.dart` already plots a dot from `pingDistance`/`pingAngle` (`:115-138`); `radar_animation.dart` drives the sweep tween; `radar_search_overlay.dart` is the trembling-window overlay (currently shows warmth text only). The sonar = stop the sweep tween, feed `pingDistance` from RSSI, feed `pingAngle` from (partner-heading − currentHeading), pulse the dot on a 1–2s timer.
> - **Wire-in point:** replace the dev-sim-only bridge at `home_screen.dart:445-453` with a production writer that feeds `pingDistanceProvider`/`pingAngleProvider` from RSSI + compass while `currentSearchProvider` (mutual wave) is active.
> - **Estimator (the hard/uncertain part — spike first):** RSSI has no bearing, so infer direction by sampling RSSI as the user rotates (heading where RSSI peaks ≈ partner direction). Accuracy is unknown → **spike on-device before committing to the full plan**; have a graceful fallback (e.g. pulsing dot at RSSI distance with a slowly-searching angle) if peak-finding proves too noisy.
**Symptom:** Trembling window is ~90% visually complete, but the radar doesn't work — critically **the partner's dot never appears on the radar**. Founder's hard requirement: the dot MUST show up (past the inner circle edge = other user's relative location), **whether or not the sweep animation is spinning**. Decouple "dot present" from "sweep animating".
**Where + LEAD (Session 54, code-traced):** the radar canvas is `_buildRadarView` (`home_screen.dart:822`) which **already receives `double? pingDistance` + `double? pingAngle`** — so a bearing/distance signal for a dot DOES exist in the plumbing (this is NOT a "no data" wall). `RadarSearchOverlay` (the overlay drawn on top, `radar_search_overlay.dart`) renders only a **warmth indicator** (warmer/colder text via `WarmthDirection`), NO positioned dot. So the dot is plottable from `pingAngle`/`pingDistance`; the likely root cause is that during the trembling/mutual-wave window those values are null / not fed, or the ping-dot painter isn't invoked in that state. **Next-session first step (systematic-debugging):** trace where `pingDistance`/`pingAngle` are computed and whether they're populated once a match is active — confirm null-vs-not-rendered BEFORE writing dot code. Then render a persistent dot decoupled from the sweep tween (dot present even if sweep isn't animating — founder's explicit ask). TDD the dot-placement math. Last blocker to "trembling window done".

### BUG-TREMBLE-PROFILE-TAP — tapping partner card in trembling window throws RevenueCat error
**Date:** 2026-07-20 · **Status:** SHIPPED (Session 55, PR #75) — Free tap opens `BasicMatchProfileScreen` (no RevenueCat); premium unchanged. Real cure for empty offerings is still CONFIG-REVENUECAT-OFFERINGS (founder). · **Risk:** HIGH (change is client-only nav; declared MEDIUM in PR)
**Symptom:** In the trembling window, tapping the partner profile surfaces the RevenueCat "You have configured the SDK with an App Store API key, but there are no App Store products registered … offerings empty" red overlay (see image) instead of opening the profile card. The paywall/offerings failure is bleeding into the trembling window.
**ROOT CAUSE — CONFIRMED (Session 54, code-traced):** `_openTremblingPartner` (`home_screen.dart:814-820`) sends **free** users straight to the paywall:
```dart
void _openTremblingPartner(BuildContext context, MatchProfile partner) {
  if (!ref.read(effectiveIsPremiumProvider)) {
    PremiumPaywallBottomSheet.show(context);   // free → paywall → RevenueCat offerings (EMPTY) → red debug overlay
    return;
  }
  context.push('/profile', extra: partner);     // premium → full profile
}
```
`PremiumPaywallBottomSheet` pulls RevenueCat **offerings**, which are empty (`CONFIG-REVENUECAT-OFFERINGS`), so the SDK renders the "offerings empty" debug overlay. History (PR #73) does NOT do this — its free tap opens `BasicMatchProfileScreen` first and only reaches the paywall via the "See full profile" CTA. So the trembling window and history diverge on the free path.
**Fix (precise):** change `_openTremblingPartner` so the **free** branch opens `BasicMatchProfileScreen(partner)` (the PR #73 basic card), NOT `PremiumPaywallBottomSheet.show`. Premium branch unchanged (`/profile`). This (a) matches the founder requirement (open the basic card gated by package, same as history) and (b) insulates the trembling window — the basic-card path never touches RevenueCat offerings, so empty offerings can't bleed in. Secondary hardening (separate/optional): make the paywall sheet degrade gracefully when offerings are empty (no debug overlay) — but the primary fix removes the offerings call from this tap entirely. TDD: free tap → basic card (no paywall, no RevenueCat); premium tap → `/profile`; prove no offerings query on the free path.

### BUG-SENTRY-TILE-CANCELLED-NOISE — `fL: Cancelled` map-tile spam in prod Sentry
**Date:** 2026-07-20 · **Status:** SHIPPED (Session 55, PR #77) — `options.beforeSend` drops tile-pipeline `Cancelled`/network events via shared `CrashFilter` predicate. Verify TREMBLE-FUNCTIONS-13/14/15 rate → ~0 after build 32. · **Risk:** LOW (noise, not a crash) · **Sentry:** TREMBLE-FUNCTIONS-13/14/15, dist 31
**Symptom:** Repeated `fL: Cancelled` errors in prod Sentry, stacktrace `TileLoader._renderTile`/`_renderJob` in `tile_loader.dart` (vector_map_tiles / flutter_map). These are **benign** — in-flight map tile render jobs cancelled when the map/radar is disposed or navigated away. They flood the prod issue stream as `error` level.
**Fix:** add a `beforeSend` filter in Sentry init to drop tile-loader cancellation exceptions (match on type `Cancelled` originating from `tile_loader.dart`), or cancel the tile futures cleanly on dispose. Verify prod issue rate drops. See lesson #96.

### WATCH — TREMBLE-FUNCTIONS-12 (`Material.of` null) still in Sentry but dist 28
**Date:** 2026-07-20 · **Status:** WATCH (likely stale) · The `TypeError: Null check operator used on a null value` (`Material.of` → InkWell without a Material ancestor) event is dated Jul 19 on **dist 28** (old build), iOS. Rule #90/#93 structural fixes (Material bottom sheets) shipped after 28. Confirm it does NOT recur on **dist 31** before spending a lane on it; if it does, hunt the remaining InkWell-without-Material (candidate: a tappable in the profile/partner card path).

---

## SESSION 62 — BUILD 35 DEVICE-PASS FINDINGS (2026-07-22, audited 2026-07-23)

> Two-phone pass on build 35 (iPhone 15 Pro Max + iPhone 15 + Android/Martin). Precise finder WORKS on 15 Pro Max (see FEATURE-RADAR-SONAR status). Root causes below are CODE-TRACED (Rule #87), not guesses. Each = its own TDD lane/branch/PR; ready-to-paste execution prompts saved at `docs/superpowers/prompts/2026-07-23-session62-fix-prompts.md`.

### BUG-RADAR-OFF-DISCOVERABLE — user with radar OFF still evaluated, notified, waved at, and matched
**Date:** 2026-07-22 · **Status:** **FIX BUILT 2026-07-23 (branch `fix/radar-off-discoverable`, Plan ID `20260723-radar-off-invisible`) — awaiting founder review/merge + `sendWave` prod deploy.** All 4 steps TDD-committed: (1) FCM background handler now checks the Flutter-prefs `radar_active` intent mirror before refreshing presence — kills the self-sustaining freshness loop; (2) `GeoService.stop()` retries the `isActive:false` revocation write 3× + Sentry on final failure (no longer swallowed); (3) cold-start reconcile at first auth-ready writes the doc inactive when local intent is off (covers force-kill/FGS death that never runs stop()); (4) `sendWave` re-verifies the target is `radarActive:true` + fresh (<2min) else `failed-precondition {reason:'target_radar_off'}`, client maps to "They're not on the radar right now." Verify: flutter analyze clean, flutter 507/507, functions tsc+eslint clean + jest 244/244, debug APK built. **Founder owns:** merge (HIGH gate) + `firebase deploy --only functions:sendWave --project prod` (Rule #101). · **Risk:** HIGH (Cloud Functions + FCM handler + presence semantics)
**Original triage (kept for reference):** Status was OPEN — **P0, privacy-adjacent**
**Symptom (device):** Martin never enabled radar, yet: appeared in `scanProximityPairs` active set, received a visible "someone is nearby" CROSSING_PATHS push, was wave-able, and completed a mutual match. Radar OFF must mean invisible AND unnotifiable AND unmatchable.
**Root cause (3 compounding defects, code-traced):**
1. `GeoService.stop()` (`lib/src/core/geo_service.dart:90-98`) — the `isActive:false` revocation write is wrapped in `catch (_) {} // Non-critical — silently fail`. It IS critical: a failed/skipped write leaves `isActive:true` for up to the 24h geo TTL. Unclean termination (force-kill, FGS death, crash) never writes it at all.
2. `firebaseMessagingBackgroundHandler` (`lib/src/core/notification_service.dart:24-48`) refreshes `proximity/{uid}.updatedAt` on every silent `CROSSING_PATHS`/`SECOND_ENCOUNTER` wake with NO radar-intent check → **self-sustaining freshness loop**: scan sees stale `isActive:true` + fresh `updatedAt` → notifies → receipt refreshes `updatedAt` → fresh for the next 1-min scan, forever. The comment says "Message receipt is not user intent" — but the refresh makes it exactly that.
3. No server-side defense-in-depth: `scanProximityPairs` trusts `isActive`+`updatedAt` alone; `sendWave` / `onWaveCreated` never check the target's radar state → even a correctly-inactive user is still wave-able/matchable via a stale pill or direct call.
**Fix lane (client + CF, HIGH gate):** (a) client: gate the background refresh on local radar intent (SharedPreferences `radar_active`); retry/ensure the stop() revocation write; cold-start reconcile (if local `radar_active` is false, write `isActive:false`); (b) server: `sendWave` rejects when target's proximity doc is not `radarActive:true` + fresh (new `reason: "target_radar_off"`). Full spec in the Session-62 prompt file.

### BUG-HAPTICS-PERSIST — sonar vibrations continue after the trembling window ends AND after radar off (cross-platform)
**Date:** 2026-07-22 · **Status:** OPEN — P1, hits the feature's showcase moment · **Risk:** MEDIUM (client-only, Riverpod lifecycle)
**Symptom (device, both platforms):** After the 30-min window expires — and separately after toggling radar OFF — the proximity ping vibration keeps firing until the user navigates away (e.g. history tab), which incidentally rebuilds/disposes the controller.
**Root cause (3 compounding defects, code-traced):**
1. `currentSearch` (`lib/src/features/match/application/match_service.dart:22-32`) evaluates the 30-min expiry against `DateTime.now()` **only when a Firestore snapshot arrives**. No timer re-evaluates at the expiry instant → after countdown end the provider keeps returning the expired match indefinitely → `SonarPingController` never rebuilds to the null branch, BLE sub + haptic loop stay live. (Server never writes the match doc at expiry either — status stays `pending`.)
2. `SonarPingController._pingStep` (`proximity_ping_controller.dart:245-271`) is a self-perpetuating async recursion whose ONLY in-place stopper is the `searching` branch of `_tickFreshness` — and the precise-finder early-return (`:160-170`) **bypasses that branch entirely**: while `_preciseDistanceM != null` the loop can never stop in place, even with BLE dead.
3. Radar toggle OFF (`home_screen.dart:1169-1188`) stops BLE + the background service but signals neither `SonarPingController` nor `PreciseFinderController` — no path tells the haptic loop the session is over.
**Fix lane (client, MEDIUM gate):** expiry timer in `currentSearch` (re-eval at `expiry - now`), `_pingStep` re-checks window validity each iteration, radar-off stops finder session + sonar loop, `_updatePrecise` clearing precise data must let `_tickFreshness` fall through to the stopper. Full spec in the prompt file.

### BUG-ONBOARDING-RITUAL-SKIPPED — "SIGNAL LOCKED" success animation never plays after registration
**Date:** 2026-07-22 · **Status:** OPEN — P2 · **Risk:** MEDIUM (registration flow + router redirect)
**Root cause (code-traced):** `completeRegistration` (`registration_flow.dart:1877-1899`) awaits `completeOnboarding` → auth-state emit flips `isOnboarded` → GoRouter redirect (`router.dart:98-149`) immediately pulls `/onboarding` → `/permission-gate` (consent was just reset at `:1888`), disposing `RegistrationFlow` during its own 2500ms hard-lock delay; the `mounted` guards then silently skip `_goToPage(RitualStep)`. The code comment at `:1868-1870` documents the disposal race but the navigation still loses. **Fix lane:** play the ritual BEFORE flipping the router-visible onboarded state (or hold the redirect until the ritual completes). Spec in the prompt file.

### BUG-WAVEPILL-TAP-PROFILE — tapping the pill photo must open the gated profile card, side-effect-free
**Date:** 2026-07-22 · **Status:** OPEN — P2 (pairs with FEATURE-POSTMATCH-NOTIFTAP) · **Risk:** MEDIUM (client nav only)
**Root cause:** `MatchNotificationPill` already exposes `onTap` ("open profile or paywall", `match_notification_pill.dart:58-59`, avatar + label tap targets at `:526-571`) — but the single production call site `WavePillService.show` in `router.dart:560-571` **never passes `onTap`** → tapping the photo does nothing. **Fix lane:** wire `onTap` → free opens `BasicMatchProfileScreen` (PR #73/#75 pattern), premium opens `/profile`; tap must NOT wave (wave stays on the explicit wave button only). Spec in the prompt file.

### FEATURE-INTERCEPT-RECEIVE-PILL — incoming Send Photo / Send Phone pop-up pill, side-anchored (cluster 3)
**Date:** 2026-07-22 · **Status:** OPEN — founder spec refinement of FEATURE-POSTMATCH-TREMBLING-REDESIGN/cluster-3 · **Risk:** MEDIUM-HIGH (notification + view-once photo flow)
**Spec (founder, Session 62):** When the partner sends a Pulse Intercept during the window, the recipient gets an in-window pop-up pill anchored next to the partner name, on the side matching the action: photo-share pill above/toward the **Send Photo** (left) button, phone-share pill toward **Send Phone** (right). Tap photo-pill → view-once photo; tap phone-pill → number with call action. Server already pushes `type: "PULSE_INTERCEPT"` (`intercept.functions.ts:108`) and `MatchRepository.getPulseIntercept` exists (`match_repository.dart:224`) — **the entire receive-side UI is unbuilt** (only known consumer is a controller passthrough at `:424`; no widget renders it). Also still open from cluster 3: intercept notification image never viewable + 2× duplicate. Spec in the prompt file.

### DIAG-IPHONE15-FINDER — precise finder misbehaved on iPhone 15 (non-Pro); works on 15 Pro Max
**Date:** 2026-07-22 · **Status:** OPEN — founder answered 2026-07-23: Precise Location was **ON** + permission **Always** on the misbehaving phone → the toggle hypothesis is DEAD. New leading hypothesis below; still needs device re-test to confirm (do NOT guess-fix).
**Leading hypothesis (2026-07-23, code-read not device-confirmed): GNSS hardware asymmetry vs the 30m server cutoff.** The Precise Location toggle only *permits* precise fixes — it does not guarantee accuracy ≤30m. `updateFinderLocation` hard-rejects any sample with `accuracy > MAX_ACCURACY_METERS = 30` (`finder.functions.ts:13,104-107`), and the caller-side rejection **short-circuits before reading the partner** and deletes the caller's own finder doc. iPhone 15 **Pro/Pro Max have precision dual-frequency GNSS (L1+L5); the non-Pro iPhone 15 does not** — on a street between buildings the non-Pro can genuinely sit above 30m while the Pro Max stays under. Net effect exactly matches the pass: identically-configured phones, the non-Pro stuck in fallback ("They're close — look around" — the stacked-caption screenshot is the fallback state) while the Pro Max gets live distance whenever the non-Pro's samples happen to pass. Corollary: if the 15 was the Pro Max's partner in the successful find, its *upload* path is proven good at those moments — the failure is intermittent accuracy, not opt-in/window binding.
**Symptom→cause map for the re-test:** stuck fallback / no "NN m" → accuracy story above; distance fine but arrow wrong → compass/magnetometer story (MagSafe or magnetic case skews heading on non-Pro; remove case + figure-8 calibrate).
**Diagnostic gap (feed into the next finder lane, server micro-change):** rejection `reason` is returned to the client but **never logged server-side** and never surfaced in UI — prod logs from 2026-07-22 cannot tell which reason the 15 got. One structured log line on the `poor_accuracy`/`partner_stale` returns in `updateFinderLocation` (+ optionally show `reason` in the B0 dev overlay) makes this diagnosable remotely.
**Re-test checklist (revised):** (1) same spot, open sky (park/parking lot away from buildings); compare the Maps blue-dot accuracy circle on both phones first — if the 15's circle is visibly larger, hypothesis confirmed cheaply; (2) Low Power Mode OFF on the 15; (3) remove any MagSafe/magnetic case; (4) both phones tap "Help us find each other" in the SAME window; (5) still wrong → dev build B0 overlay + report exact symptom (fallback vs wrong arrow vs frozen distance). Related cosmetic finding (screenshot): fallback state renders BOTH "They're close — look around" AND "SEARCHING…" captions stacked — decide one-caption precedence in the finder-fallback state (fold into BUG-HAPTICS-PERSIST lane's overlay test or a micro-lane).

### ✅ VERIFIED WORKING (Session 62 pass — no action)
- Blocked users: still evaluated in cloud, NOT notified (`[SAFETY] User XHXl6Voy... blocked user xgvcX328...` + `pairsEvaluated:1, pairsNotified:0` while blocked). Unblock restores. Unblock-notification behavior intentionally parked for Alpha store version.
- `markMatchFound` atomic purge + `updateFinderLocation` 3s cadence + Rule-#102 flicker fix — clean in prod logs, both platforms (iOS UA + okhttp).
- Precise finder end-to-end on iPhone 15 Pro Max (arrow, distance countdown, turn tracking, movement).

---

## CRITICAL — Store Blockers (Pred Submissionom)

### BLOCKER-STORE-001 — iOS Privacy Manifest & Encryption Declaration
**Date:** 2026-07-06
**Status:** RESOLVED 2026-07-14 — verified via Rule #82 3-surface audit (KORAK 3.9-2)
**Impact:** App Store will automatically reject the build starting from iOS 17.4 without a privacy manifest. Missing encryption declaration will cause App Store Connect rejection.
**Resolution (audit evidence, 2026-07-14):**
- `ios/Runner/PrivacyInfo.xcprivacy` present and `plutil -lint` clean.
- **NSPrivacyAccessedAPITypes** — all 4 Required Reasons API categories declared: UserDefaults (CA92.1), FileTimestamp (C617.1), SystemBootTime (35F9.1), DiskSpace (E174.1).
- **NSPrivacyCollectedDataTypes** — 10 categories declared covering CoarseLocation, PhotosorVideos, Name, EmailAddress, PhoneNumber, UserID, PurchaseHistory, CrashData, OtherDiagnosticData, and Contacts (Linked=false per ADR-004 hash-only transmission).
- **`Info.plist` encryption declaration** — `ITSAppUsesNonExemptEncryption = false` present (Info.plist line verified via grep).
- **Rule #82 surface (a) master↔localized divergence** — 7 present keys byte-identical between master `Info.plist` and `en.lproj/InfoPlist.strings`.
- **Rule #82 surface (b) duplicate-key sweep** — every `NS*UsageDescription` key counts exactly 1 in master Info.plist.
**Follow-up (non-blocker, LOW):** `sl.lproj/InfoPlist.strings` and `hr.lproj/InfoPlist.strings` do NOT localize NSCameraUsageDescription, NSPhotoLibraryUsageDescription, NSPhotoLibraryAddUsageDescription — iOS falls back to the English master string for those 3 prompts on Slovenian/Croatian device locales. Not a submission blocker (no lie, no divergence) but a UX gap worth a future translation sprint. (Task 6h3grHhjVXFhMRJP, 6h3grHqC22mCcccP)

### BLOCKER-STORE-002 — iOS Info.plist Contacts Contradiction
**Date:** 2026-07-06
**Status:** RESOLVED 2026-07-16 — code and live policy reconciled
**Impact:** `Info.plist` stated contacts are not accessed, but Privacy Policy §2.5 says they are. Apple 5.1.1 rejection risk.
**Resolution (PR fix/info-plist-contacts-reconcile, KORAK 3.8-1):**
- Master `NSContactsUsageDescription` rewritten to match localized `en.lproj/InfoPlist.strings` verbatim (describes Anonymity Mode / ADR-004).
- Three duplicate permission keys removed from Info.plist (NSCameraUsageDescription, NSPhotoLibraryUsageDescription, NSPhotoLibraryAddUsageDescription). Founder decision 2026-07-13: kept the L46/L48 wording that covers Pulse Intercept (v1 feature); L50-51 replaced with the Apple-preferred explicit-consent NSPhotoLibraryAdd variant.
- `PrivacyInfo.xcprivacy` now declares `NSPrivacyCollectedDataTypeContacts` (Linked=false per ADR-004 hash-only transmission; Tracking=false; Purpose=AppFunctionality).
**Live-policy verification (2026-07-16):** `trembledating.com/privacy` §2.5 now describes the on-device SHA-256 Anonymity Mode flow and states that hashes are not stored. The previously owed web-copy correction is complete.
(Task 6h3p8gWpxpq7rWXw)

### BLOCKER-STORE-003 — Android Background Location Declaration
**Date:** 2026-07-06 (updated 2026-07-07)
**Status:** OPEN — code side done, Play Console side pending
**Impact:** Requires Prominent Disclosure, a demo video, and a special declaration in Google Play Console. This review process takes 2-4 weeks and blocks Android launch.
**Progress (2026-07-14 update, PR pending, KORAK 3.9-4):**
- ✅ Standalone Prominent Disclosure screen added at `lib/src/features/auth/presentation/prominent_disclosure_screen.dart` — shown between foreground grant and OS background prompt on both Android and iOS. (PR #7 / commit a3f793b, 2026-07-07)
- ✅ Consent flow refactored so the OS `ACCESS_BACKGROUND_LOCATION` prompt only fires after the disclosure's primary CTA is tapped. "Not now" completes onboarding with foreground-only location.
- ✅ Android is now a first-class background-location caller (previously the manifest permission was silently dormant).
- ✅ **Brand-voice pass (2026-07-14, KORAK 3.9-4):** EN + SL body copy swaps generic "matches / ujemanja" for Tremble's radar lexicon "signals / signale" to reinforce Rule #3 (Wave-based mechanic, no chat). EN also swaps "deleted" → "cleared" to soften legalese without diluting the disclosure. Play-policy phrases ("approximate location / približno lokacijo", "in the background / v ozadju", "Allow background location / Dovoli lokacijo v ozadju") preserved verbatim. Test `prominent_disclosure_screen_test.dart` now pins the brand-voice keywords so a future refactor can't silently regress.
- ⏳ EN + SL screenshots of the new screen must be captured on an emulator/device for the Play submission package.
- ⏳ Play Console declaration + demo video still need to be submitted.
**Action:** Capture EN + SL screenshots, record demo video, submit Play declaration. Copy review DONE. (Task 6h3p8gWG7WHWV7JP)

### BLOCKER-STORE-004 — Android Foreground Services Declaration
**Date:** 2026-07-06
**Status:** OPEN
**Impact:** FGS types (`location`, `connectedDevice`) require Google Play declaration. `dataSync` was removed from the app manifest/runtime mask in branch `fix/android-fgs-timeout` because radar is BLE scanning + GPS, not a long-running data-transfer operation; do not declare `dataSync` in Play after that PR lands.
**Action:** Submit FGS declaration to Google Play for `location` + `connectedDevice` only after the HIGH-risk native fix is approved/merged. (Task 6h3p8gc78572RF9P)

### BLOCKER-STORE-005 — Production APNs Credential Verification
**Date:** 2026-07-16
**Status:** OPEN — code-side repair deployed; Firebase/Apple credential gate pending
**Impact:** Production iOS FCM delivery previously returned the invalid-APNs-credential error class. Bundle ID `tremble.dating.app`, Firebase iOS App ID `1:343655004163:ios:5eea92b9656fc3b8fc3636`, Team ID `LB6LS532CV`, production entitlement, and build-22 signing metadata align, leaving the APNs credential stored under the Firebase Apple app as the strongest unresolved cause. App Store submission must not be declared push-ready until a controlled device send succeeds.
**Progress:**
- ✅ `scanProximityPairs` and `onWaveCreated` identity/delivery/retry fixes deployed to `am---dating-app` in `europe-west1` on 2026-07-16.
- ✅ APNs delivery CONFIRMED working: 2026-07-18 08:48:03 prod scan sent two visible CROSSING_PATHS (`pairsNotified:2`, `notification_sent`) to both test accounts — the credential class error is resolved in practice. Delivery is no longer the blocker.
- ✅ **Wave pill render bug fixed (build 26)** — `presentWavePill` read the overlay from `Overlay.maybeOf(currentContext)` (always null), so the pill never showed foreground OR tap. Fixed to `currentState.overlay` (PR #65) + bounded readiness retry + Sentry give-up (PR #62). See Rule #86. This was the actual cause of "nothing showed", NOT APNs.
- ✅ **Freeze fix (PR #60) shipped in build 25**; build 26 carries it too. Both platforms of build 26 are up (TestFlight Delivery UUID `2024e76c-bed2-4b21-a6f2-f0f57c4b6835`; AAB at `release-symbols/b26/`).
- ⏳ **Device verification of build 26 is the only remaining gate**, using `send_test_push.ts` (Rule #88): (a) foreground → pill, no freeze; (b) background tap → pill; (c) killed tap → cold-launch pill; (d) airplane map → offline card. If a pill drops, Sentry (`tremble-functions`, dist 26) logs `wave pill dropped: auth-null|no-overlay`.
**Action:** Founder runs the build-26 device matrix (Rule #88). On green, STORE-005 closes and the freeze fix is proven in the same pass. APNs credential inspection is no longer required — delivery is confirmed.

---

## Security Follow-ups (Not Submission Blockers)

### FOLLOWUP-SEC-002 — Production Runtime Values Printed in a Local Tool Transcript
**Date:** 2026-07-16
**Status:** OPEN — security-hygiene follow-up; no public or source-control exposure found
**Impact:** A globally enabled shell `DEBUG` variable caused Firebase CLI diagnostics to print runtime configuration into the local authenticated tool transcript. This was not a public chat, no value entered Git history, and committed-diff scans passed. A local transcript has a wider retention surface than the terminal, so true server-side credentials should still be rotated as prudent hygiene, but this is not evidence of public compromise and does not block App Store submission.
**Scope:** Rotate only actual server secrets (for example R2, Resend, and Upstash credentials). Do not classify public client identifiers such as a RevenueCat SDK key or Sentry DSN as secrets. Provider-restricted client keys should be reviewed against their platform restrictions before deciding whether rotation adds value.
**Action:** Remove or scope the global `DEBUG` variable, rotate genuine server secrets in a separate approved production-config lane, validate each replacement before revoking the old value, and never paste credential values into issues, commits, or chat.

**2026-07-19 — second exposure (Session 52).** During the getPublicProfile diagnostic redeploy, a Cloud Run revision spec (full `env` block) was pasted into the assistant chat transcript, printing plaintext values of three genuine server secrets. Rotate these in the approved config lane, validating each new value before revoking the old:
- `R2_SECRET_ACCESS_KEY` (+ its `R2_ACCESS_KEY_ID`)
- `RESEND_API_KEY`
- `UPSTASH_REDIS_REST_TOKEN`

Public/client identifiers in the same block (`SENTRY_DSN`, `REVENUECAT_APPLE_API_KEY`) are NOT secrets; `PLACES_KEY_PROD` is a provider-restricted client key — review its API restrictions rather than rotate. To read function logs without dumping env, use Logs Explorer filtered to `resource.labels.service_name` + a `textPayload:` term, not the revision spec. Not an App Store submission blocker.

---

## CRITICAL — Legal Blockers (Pred Submissionom)

### BLOCKER-LEGAL-001 — DPIA False Claims
**Date:** 2026-07-06
**Status:** OPEN
**Impact:** DPIA falsely claims `getPublicProfile` doesn't leak sensitive data, and lists incorrect TTLs (24h vs 2h). Evidence of discrepancy during an audit is an aggravating factor.
**Action:** Fix DPIA to match codebase reality. (Task 6h3jFhxVHpRmph9P)

### BLOCKER-LEGAL-002 — Cannabis Legal Classification
**Date:** 2026-07-06
**Status:** RESOLVED 2026-07-14 — cannabis removed from product entirely (stronger than the original "separate into own field" action)
**Impact:** `nicotineUse` bundled cannabis with vape. In some jurisdictions, cannabis data is "criminal offense data" (Art. 10 GDPR), meaning consent cannot legitimize it.
**Resolution (audit evidence, 2026-07-14):**

Cannabis is unreachable across every surface of the product:

| Surface | Evidence | Verified |
|---|---|---|
| Registration UI | `lib/src/features/auth/presentation/widgets/registration_steps/nicotine_step.dart:15-19` — only 5 options offered: `cigarettes`, `vape`, `iqos`, `zyn`, `shisha`. No cannabis chip. | ✅ |
| Server API (Zod) | `functions/src/modules/users/users.schema.ts:17-23` — `nicotineUseValueSchema = z.enum(["cigarettes", "vape", "iqos", "zyn", "shisha"])`. Any request that sends `"cannabis"` is rejected with 400 at the API boundary. | ✅ |
| Edit-profile display | `lib/src/features/profile/presentation/edit_profile_screen.dart:124` — `..addAll(user.nicotineUse.where((v) => v != 'cannabis'))` defensively filters legacy Firestore entries out of the render. | ✅ |
| Legacy Firestore data | `functions/src/scripts/remove_cannabis.ts` migration ran against **prod (`am---dating-app`)**. Founder confirmed 2026-07-14. `FieldValue.arrayRemove("cannabis")` is idempotent — subsequent user writes cannot re-introduce it. | ✅ |

**Why stronger than the original action:** the blocker's original ask was to "separate cannabis into its own field pending legal review." The founder chose to *remove* cannabis entirely instead. No collection → no consent needed → no Art. 10 exposure at all. This closes the risk without waiting for a per-jurisdiction legal opinion.

**Related:** PLAN_00 §Deluje records "Kanabis + politična pripadnost: odstranjena iz kode (grep = 0 zadetkov v main)" — verifies the code-side removal. This closeout adds the schema-boundary + display-filter + prod-migration evidence. (Task 6h3jHjr7Hf58G8pw)

### BLOCKER-LEGAL-003 — Sexual Orientation (GDPR Art. 9) Missing Consent
**Date:** 2026-07-06
**Status:** RESOLVED 2026-07-14 — PR #41 merged into `main` @ cce1f1c. Cloud Functions deployed to prod (`am---dating-app`, europe-west1) same day; `withdrawArt9Consent` created, `updateProfile` + `completeOnboarding` updated with the enforcement.
**Impact:** The combination of `gender` + `lookingFor` implicitly reveals sexual orientation. As an Art. 9 category, processing without explicit consent is a massive GDPR violation (Grindr fined NOK 65M for this).
**Resolution (branch pending merge, Plan-ID 20260714-legal-003-art9-consent-hardening):**
- Server write-time enforcement in `updateProfile` — Art. 9 field writes (gender / lookingFor / religion / ethnicity) rejected unless the effective consent for that category is `=== true`. Same-request grants honoured; same-request withdrawals rejected.
- New `withdrawArt9Consent` callable that writes consent=false + version + timestamp AND `FieldValue.delete()`s the corresponding sensitive field(s) (orientation withdrawal deletes both gender + lookingFor).
- `completeOnboarding` drops religion + ethnicity to `null` when the paired consent flag isn't true so nothing lands in Firestore that the scorer would then read behind the bilateral gate.
- Bilateral fail-closed orientation gate in `compatibility_calculator.ts` on the `lookingFor` hard filter, mirroring the existing religion + ethnicity pattern.
- All three Art. 9 consent tiles rewritten with narrow-purpose text (v1) + PP anchor deep-link. Select-all no longer flips Art. 9 optionals — Art. 9(2)(a) "specific" consent requirement. EN + SL + HR translations.
- Settings-screen withdrawal UI (`privacy_consents_section.dart`) with confirmation dialog + destructive server call.
- App-launch backfill modal (`backfill_consent_modal.dart`) for pre-migration users with `sexualOrientationConsent == null`; PopScope-locked, accept/decline both server-first (not optimistic) so a network failure keeps the modal open.
- Server stamps `{category}ConsentVersion = "v1"` + `{category}ConsentAt = serverTimestamp()` on every grant OR withdrawal so future consent-text bumps can re-prompt v1 users through the same backfill machinery.
- Test coverage: 10 new CF assertions in `users.test.ts`, 4 new pair-of-tests in `compatibility_calculator.test.ts`, 7 widget assertions in `backfill_consent_modal_test.dart`, 3 in `privacy_consents_section_test.dart`, updated `consent_step_test.dart` (17 assertions after Step 3+4). 134/134 CF + 275/275 Flutter tests green.
**Action:** DONE (PR merged, prod deployed). Downstream lanes now unblocked: BLOCKER-LEGAL-001 (DPIA rewrite), PLAN_04 KORAK 4.2 (pisno mnenje to counsel — send with the two mandatory questions now that shipped code exists to reference), PLAN_04 KORAK 4.3 (Privacy Policy §art9-* anchors). (Task 6h3j9q65vh3mG64P — mark done)

### BLOCKER-LEGAL-004 — Weekend Window ToS Mismatch + user-local timezone
**Date:** 2026-07-06 (rescoped 2026-07-14)
**Status:** OPEN — scope escalated from LOW (ToS edit only) to HIGH (code + ToS)
**Impact:** Two-layer problem.
- **Layer 1 (original):** ToS §7 promises an "automatic weekend window (Fri 19h - Sun 19h)" but the actual product model is a PAID Premium mini-package (Weekend Getaway) with flat pricing, three purchase-timing branches (queued if bought pre-Fri 19:00 → activates at Fri 19:00 same week; instant if bought Fri 19:00 - Sun 19:00; queued for next weekend if bought post-Sun 19:00), NOT an automatic free unlock. Unfair business practice / consumer deception risk.
- **Layer 2 (discovered 2026-07-14):** `getNextWeekendWindow` computes against hardcoded `Europe/Ljubljana`. A California user buying Weekend Getaway on Friday morning PST would see it activate at Thu 10:00 AM PST (Fri 19:00 CET) and expire Sun 10:00 AM PST — wrong product. The window must be computed in the **user's local timezone** (founder confirmed 2026-07-14).
**Rescoped action:** No longer a 5-min ToS edit. The lane now requires (a) `timezone: string` (IANA) field on user document + backfill for existing SI/HR users, (b) `getNextWeekendWindow(userTimezone)` refactor + all callers, (c) traveler decision (snapshot at purchase vs re-evaluate at activation), (d) DST edge-case handling for Fri-19:00 transition weekends, THEN (e) ToS §7 rewrite describing the paid weekend package in user-local time. Sequenced AFTER LEGAL-003 ships. See memory `weekend-pass-user-local-timezone.md` for the durable decision record. (Task 6h332RFRW946QWXw)

### BLOCKER-LEGAL-005 — Paywall False Advertising
**Date:** 2026-07-06
**Status:** RESOLVED 2026-07-14 — verified via bullet↔gate audit (KORAK 3.9-3)
**Impact:** Paywall advertised features that didn't exist in code ("unlimited geofence pings") and hid features that were actually gated ("see who waved"). Apple 3.1.2 rejection risk + consumer protection.
**Resolution (audit evidence, 2026-07-14):**

The KORAK 3.7 series (2026-07-13) already rewrote `premium_screen.dart` against the ADR-007 tier matrix. Every current Premium bullet maps to a real, implemented code gate:

| Bullet key | Backend / client gate | Evidence |
|---|---|---|
| `premium_feature_radar_extended` | 250 m + −85 dBm (vs Free 100 m + −75 dBm) | `lib/src/core/geo_service.dart:20-21` + `functions/src/modules/proximity/` |
| `premium_feature_mutual_waves_20` | Monthly cap 20 (vs Free 5), `Europe/Ljubljana` counter | `functions/src/modules/matches/matches.functions.ts:38-56` |
| `premium_feature_open_profile_cards` | Compound gate `isPremium && hasMutualWave` — three-state render | `lib/src/features/matches/presentation/matches_screen.dart:143` + `MatchProfile.hasMutualWave` field (`match_repository.dart:70`) |
| `premium_feature_recap_full` | Recap TTL 10-min + `isReadOnly = !isPremium \|\| isHistory \|\| isExpired` gates wave button and profile tap | `lib/src/features/recap/providers/recap_ttl_provider.dart` + `run_recap_screen.dart:498-503` |
| `premium_feature_near_miss_history` | Tab visible only when `isPremium`; Free shows upsell banner | `matches_screen.dart:40,54` |
| `premium_feature_hard_filters` | Soft-labelled "coming soon" in 8 locales per ADR-007 Amendment §2/§6 | `premium_screen_test.dart:99-153` locks localisation |
| `premium_feature_event_insights` | `effectiveIsPremium` gates participant count + heatmap chip | `lib/src/features/map/presentation/event_pin_sheet.dart:138,154,171` |

**Retired keys (LEGAL-005's original complaints) are gone AND test-locked as gone** in `test/features/settings/premium_screen_test.dart:75-97`: `premium_feature_unlimited_geofence`, `premium_feature_wider_radar`, `premium_feature_custom_themes`, `premium_feature_advanced_filters`, `premium_free_gym_mode`, `premium_free_local_radar`, `premium_free_wave_limit`, `premium_feature_distance_100`, `premium_free_distance_50`.

**Copy-rule enforcement** via `premium_screen_test.dart:155-189` scans user-facing strings for banned phrases (`revolutionary`, `seamless`, `game-changing`, `find love today`, `find your person`, `swipe`, `match queue`, `chat`) per ADR-007 §3.

**Follow-up (non-blocker, deferred):** ADR-007 §4 mandate — one *pair* of consistency tests per gate (Free hits gate / Premium doesn't). Partial coverage exists in `test/features/matches/matches_three_state_test.dart`, `test/features/subscriptions/revenuecat_subscription_test.dart`, and the `test/features/recap/` suite, but not systematically per-bullet. Not gating LEGAL-005 closure because the copy↔gate mapping is verified above; captured as a MEDIUM test-hardening lane in `tasks/plan.md` §3. (Task 6h3pmrF84Cf6JVQP)

**Deferred pair-of-tests lane — RESOLVED 2026-07-14 (Plan-ID `20260714-adr007-pair-of-tests-hardening`, branch `test/adr007-pair-of-tests-hardening`).** Coverage matrix across the 7 Premium bullets found 4 gates already well-covered (open_profile_cards, recap_full, near_miss_history, event_insights), 1 gate excluded by ADR-007 Amendment §2 (hard_filters — soft-labelled "coming soon", no behavioural gate), and 2 gaps to fill:

| Gate | Before | Added this lane |
|---|---|---|
| `premium_feature_radar_extended` | No test — the `_isPremium ? 'pro' : 'free'` tier ternary at `geo_service.dart:257` sits behind a Firebase-auth + `SharedPreferences` singleton, so a behavioural render is uneconomic. | New `test/core/geo_service_radar_tier_test.dart` — source-scan pair pinning the Free tuple (100 m + −75 dBm), the Premium tuple (250 m + −85 dBm), the shared ternary that writes both branches, and the `updatePremiumTier` runtime hook. Pattern mirrors `test/features/recap/recap_ui_wiring_test.dart` + `test/features/match/near_miss_locked_state_test.dart:146`. |
| `premium_feature_mutual_waves_20` (server) | Helper `mutualWaveLimitForUser` values pinned at `functions/src/__tests__/matches.test.ts:397` (Free=5, Premium=20). Client-side `hasReachedWaveLimit` already has an exhaustive threshold pair in `test/features/auth/auth_user_wave_limit_test.dart`. No server-side "at threshold, `count >= limit` is true" pair. | Two additional assertions in the existing `describe("mutual wave monthly counters")` block. Verifies that Free at count=5 satisfies the rejection predicate, Premium at count=5 does NOT, and Premium at count=20 does — mirrors the client-side threshold coverage at the server contract. |

All other gates have real widget or behavioural pairs; those files stay untouched. This close-out captures the deferred-lane execution referenced in the "Follow-up (non-blocker, deferred)" note above.

**Session-53 amendment (2026-07-20) — `premium_feature_open_profile_cards` gate boundary.** BUG-HISTORY-CARD-TAP changed the Free + mutual tap from a bare paywall to a read-only **basic card** (`BasicMatchProfileScreen`: photo + name/age + 3 hobbies) with a subtle "See full profile · Premium" CTA → paywall. The paywall bullet stays truthful because the **full** profile card (`ProfileDetailScreen`) remains Premium-only (`isPremium && hasMutualWave`, route `/profile`; Free routes to `/profile?...&basic=true`) and the CTA explicitly advertises it. See ADR-007 §1 Amendment (Session 53). No paywall-copy change required.

---

## ARCHIVED BLOCKERS (Resolved)

> **B001 / ADR-001** (iOS BLE Background State) ✅ RESOLVED 2026-04-29
> **B002 / D-37** (3-State Map Toggle) ✅ RESOLVED 2026-04-29
> **B003** (Company Setup / RevenueCat) ✅ RESOLVED 2026-05-07
> **B004 / F5** (Strava/Health Integration) ✅ REMOVED 2026-04-30
> **B005** (iOS Dev Provisioning for com.pulse) ✅ RESOLVED
> **B006** (Photo Upload / Onboarding E2E) ✅ RESOLVED
> **B007** (Legal Web Pages Live) ✅ RESOLVED 2026-05-26
