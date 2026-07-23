# Session 63 → Lane 2 Handoff — BUG-HAPTICS-PERSIST (2026-07-23)

Ready-to-paste prompt for a fresh chat. Planning-free: root cause is code-traced
(Rule #87), files/lines named, fix specced, TDD + MPC gates baked in. This
supersedes PROMPT 2 in `2026-07-23-session62-fix-prompts.md` — it adds the
post-#92 evidence (lane 1 shipped patterns lane 2 must reuse, not fight).

---

## CONTEXT CARRIED FROM SESSION 63 (evidence — do not re-derive)

**Lane 1 (BUG-RADAR-OFF-DISCOVERABLE) is DONE and on main.** PR #92 merged
(`3657ab4`), `sendWave` deployed to prod (`am---dating-app`, `--project prod`).
This matters for lane 2 because lane 1 introduced the radar-intent plumbing you
should REUSE:

- `lib/src/core/background_service.dart` now exports `radarIntentPrefsKey`
  (`'radar_active'`) and `persistRadarIntent(bool)`. The UI radar toggle, the
  native tile/widget listener, and the mode-switch stop all call
  `persistRadarIntent(...)`. **Lane 2's STEP 3 (radar-off must stop the sonar +
  finder controllers) fires from the SAME toggle branches** — see
  `home_screen.dart` around the `newState`/`else` branch (~:1101 on-edge,
  ~:1169 off-edge) and the native listener (~:110). Radar-off already
  persists intent and calls `BleService().stop()` + service stop; lane 2 adds
  the controller-signalling that lane 1 explicitly left out of scope.
- **DO NOT** touch the `sendWave` radar gate, `GeoService.stop()` retry, or
  `reconcileColdStartRadarIntent()` — those are lane 1, shipped.

**Uncommitted control-plane docs are in the working tree** (post-#92 status
updates to `tasks/context.md`, `tasks/blockers.md`, `tasks/plan.md`, and the
iPhone-15 diagnosis). Stage them into lane 2's first commit (they describe
already-merged work, so they belong on the next PR). Verify with `git status`
before branching; do a Rule #83 `git log`/`gh pr list` check first.

---

## PROMPT (paste below into a fresh chat)

```
TREMBLE — fix BUG-HAPTICS-PERSIST (lane 2 of 5). Sonar vibrations must stop the moment the trembling window ends AND the moment radar is toggled off, WITHOUT navigating away. Cross-platform repro on build 35.

BOOTSTRAP (read; root cause is code-traced, no re-investigation):
- tasks/blockers.md → BUG-HAPTICS-PERSIST (line ~137)
- tasks/lessons.md → Rule #104 (this bug), #102 (SAME controllers, opposite failure — do NOT reintroduce matches/{id} doc-churn), #99 (autoDispose/keep-alive test traps), #83 (git check first)
- docs/superpowers/prompts/2026-07-23-session63-lane2-haptics-handoff.md (this file — carries lane-1 context)
- Rule #83: git log / gh pr list confirm no haptics fix landed since 2026-07-23. Lane 1 (#92, radar-off) IS merged — build on top of it, reuse persistRadarIntent/radarIntentPrefsKey from background_service.dart.

Plan ID: 20260723-haptics-stop · Risk: MEDIUM (client-only Riverpod lifecycle; NO Cloud Functions, NO rules, NO deploy) · Branch: fix/haptics-persist off main. Stage the uncommitted post-#92 control-plane docs into the first commit.

CONFIRMED ROOT CAUSE (3 defects, code-traced 2026-07-23):
1. lib/src/features/match/application/match_service.dart:22-32 — `currentSearch` computes the 30-min expiry (m.createdAt + 30min) against DateTime.now() ONLY when an activeMatchesStream snapshot arrives. Nothing re-evaluates at the expiry instant → after countdown end the where-filter still returns the (now-expired) pending match indefinitely → SonarPingController never rebuilds to its null branch; BLE sub + haptic loop stay live. (Server never writes the match doc at expiry — status stays 'pending'.)
2. lib/src/features/dashboard/application/proximity_ping_controller.dart — `_tickFreshness` (:160-199) early-returns on a live precise fix (`_preciseDistanceM != null`, :161-170) BEFORE reaching the `searching` branch whose `_stopPingLoop()` (:187) is the loop's ONLY in-place stopper. `_pingStep` (:245-271) is a self-recursing async loop (re-invokes itself at :268-269). So while a precise finder fix is present the haptic loop can NEVER stop in place, even with BLE dead.
3. home_screen.dart radar-toggle OFF branch (~:1169) + native listener (~:127) stop BleService + the background service but signal neither SonarPingController nor PreciseFinderController — no path tells the haptic loop the session is over. (Lane 1 added persistRadarIntent(false) here; lane 2 adds controller stop.)

FIX (TDD, atomic commits — RED test first each step):
STEP 1: expiry tick in currentSearch. When a pending match is selected, schedule Timer(expiry − now, () => ref.invalidateSelf()); cancel via ref.onDispose; reschedule on rebuild. After invalidation the where-filter drops the expired match → controllers rebuild to null → _reset() stops the loop. RED test with fake_async: provider returns the match before expiry, null after the timer fires WITH NO new snapshot. Watch Rule #99 — currentSearch is a synchronous @riverpod; keep it non-autoDispose-broken (use ref.onDispose for the timer).
STEP 2: haptic loop must be BLE-freshness-gated even during a precise session. In _tickFreshness, compute signalStateFor(sinceLastSample) FIRST; if it is `searching`, call _stopPingLoop() UNCONDITIONALLY, THEN handle the precise-dot rendering. The dot may stay precise-driven (radius = preciseRadius, keep the visual); only the HAPTIC loop must die when BLE RSSI is stale. RED test: precise fix present (_preciseDistanceM != null) + no BLE sample for >6s (searching threshold) → _isLooping false / no further _triggerPing calls. Inject/spy the haptic — see existing proximity_ping_controller test patterns (test/features/dashboard/ or test/shared/). Do NOT change SonarPing math, preciseRadius, dotAngle, or reintroduce a matches/{id} write (Rule #102).
STEP 3: radar-off stops the session. In the toggle's OFF branch (home_screen.dart, right after BleService().stop() — both the button handler ~:1169 and the native listener ~:127, plus the mode-switch stop ~:1671) add: unawaited(ref.read(preciseFinderControllerProvider.notifier).stop()); ref.invalidate(sonarPingControllerProvider); — rebuild with dead BLE arms nothing until fresh RSSI. Reuse the persistRadarIntent(false) call sites lane 1 already added (same branches). Widget test: toggle off → finder .stop() called + ping loop not looping.
STEP 4 (micro, same lane): caption precedence. When the finder-fallback copy ("They're close — look around") shows, suppress the sonar "SEARCHING…" caption (build-35 screenshot showed both stacked). One caption at a time. Locate the overlay (radar_search_overlay.dart or the finder fallback widget); widget test asserting only one of the two strings renders in the fallback state.

INVARIANTS (must survive): NO writes to matches/{id} (Rule #102 — that path caused the dot-flicker regression); NO change to SonarPing math / preciseRadius / dotAngle / bucketToRadius; PreciseFinderController's existing stop semantics unchanged (found/expiry/background revoke; `inactive` ≠ paused — foreground-only lifecycle); keep-alive ref.watch in the radar section stays; do NOT touch lane-1's sendWave gate, GeoService.stop() retry, or reconcileColdStartRadarIntent.

VERIFY: dart format stable · flutter analyze --no-fatal-infos clean · flutter test --dart-define-from-file=.env.json all green (baseline 507 + new) · flutter build apk --debug --flavor dev --dart-define-from-file=.env.json --dart-define=FLAVOR=dev.
PR: title "[PLAN-ID: 20260723-haptics-stop] fix(radar): stop sonar haptics at window end and radar off". Body MUST contain a "## Verification checklist" section literally naming "unit tests", "integration tests", "security scan" (CI ① MPC Metadata greps these; no admin bypass). Add plan.md line-2 Plan-ID = 20260723-haptics-stop first (pre-flight check 1). Run the 4-check MPC pre-flight before gh pr create; gh pr view after to confirm the title landed. MEDIUM risk → mark risk_level accordingly; no founder-approval gate needed, but device re-check owed post-merge: vibrations stop at countdown end AND at radar-off, without navigating away.
```

---

## AFTER LANE 2 — remaining lanes (same prompt file, run in order)

3. **BUG-WAVEPILL-TAP-PROFILE** (P2, MEDIUM) — PROMPT 3. Wire `onTap` on the
   wave pill → gated profile card (free→BasicMatchProfileScreen, premium→/profile),
   no wave side-effect. Partially covers FEATURE-POSTMATCH-NOTIFTAP.
4. **BUG-ONBOARDING-RITUAL-SKIPPED** (P2, MEDIUM-HIGH, founder approval) —
   PROMPT 4. Reorder so the "SIGNAL LOCKED" ritual plays before the
   router-visible isOnboarded flip.
5. **FEATURE-INTERCEPT-RECEIVE-PILL** (cluster 3, MEDIUM-HIGH) — PROMPT 5.
   Build the receive side of Pulse Intercept (side-anchored pills, view-once
   photo, call action). Flag founder if any server change becomes necessary.
