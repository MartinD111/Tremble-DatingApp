# Session 62 — Build-35 Device-Pass Fix Prompts (2026-07-23)

Ready-to-paste prompts for fresh chat instances. Each is planning-free: root cause is
already code-traced (Rule #87), files/lines named, fix specced, TDD + MPC gates baked in.
Run order: 1 → 2 → 3 → 4 → 5. Source audit: `tasks/context.md` Session 62 +
`tasks/blockers.md` SESSION 62 section.

---

## PROMPT 1 — BUG-RADAR-OFF-DISCOVERABLE (P0, HIGH)

```
TREMBLE — fix BUG-RADAR-OFF-DISCOVERABLE (P0). Radar OFF must mean invisible, unnotifiable, unmatchable.

BOOTSTRAP (read, no re-investigation needed — root cause is code-traced):
- tasks/blockers.md → SESSION 62 → BUG-RADAR-OFF-DISCOVERABLE
- tasks/lessons.md → Rule #105 (this bug), #101 (--project prod), #84/#85 (release rules)
- Verify vs git per Rule #83 that no fix landed since 2026-07-23.

Plan ID: 20260723-radar-off-invisible · Risk: HIGH (CF + FCM handler + presence semantics) → founder approval before merge/deploy · Branch: fix/radar-off-discoverable off main.

CONFIRMED ROOT CAUSE (3 defects, do not re-derive):
1. lib/src/core/geo_service.dart:90-98 — GeoService.stop() wraps the isActive:false revocation write in `catch (_) {}`. Failed/skipped write → user stays discoverable up to the 24h TTL. Unclean stop (force-kill, FGS death) never writes it.
2. lib/src/core/notification_service.dart:24-48 — firebaseMessagingBackgroundHandler refreshes proximity/{uid}.updatedAt on silent CROSSING_PATHS/SECOND_ENCOUNTER wakes with NO radar-intent check → self-sustaining freshness loop against scanProximityPairs' 2-min cutoff (proximity.functions.ts:632-638: isActive==true && updatedAt>=now-2min).
3. functions: sendWave / onWaveCreated never check the target's radar state → stale doc = fully wave-able/matchable.

FIX (TDD, one atomic commit per step):
STEP 1 (client): gate the background refresh on user intent. `processBackgroundNotificationData` (notification_service.dart:50, already @visibleForTesting with injected refreshProximity) gains an injected `Future<bool> Function() isRadarActive` that reads SharedPreferences key 'radar_active' (the source of truth — see background_service.dart:72). Skip refreshProximity when false. RED tests: refresh skipped when intent false; still runs when true; unrelated types untouched.
STEP 2 (client): make the revocation write reliable. GeoService.stop(): retry the isActive:false write up to 3× with short backoff; on final failure `Sentry.captureException` non-fatal (never rethrow — stop() must not crash callers). Test with a failing-then-succeeding fake Firestore.
STEP 3 (client): cold-start reconcile. On first auth-ready after app start (NOT in main() — auth isn't restored yet; hook where authStateProvider first yields a signed-in user, e.g. home bootstrap), if SharedPreferences 'radar_active' != true → merge-write {isActive:false, radarActive:false, updatedAt: serverTimestamp} to proximity/{uid}. Idempotent, fire-and-forget with error swallow ONLY after one Sentry breadcrumb. Widget/unit test with fake prefs + fake repo.
STEP 4 (server): defense-in-depth in sendWave (functions/src/modules/waves — locate exact file via grep "sendWave"). Before creating a wave: read proximity/{targetUid}; unless radarActive===true AND updatedAt >= now-2min → throw HttpsError('failed-precondition', …, {reason:'target_radar_off'}). Applies to wave-backs too (radar off ⇒ unmatchable, founder invariant). Jest RED tests: rejects stale doc, rejects radarActive:false, accepts fresh+active, error carries reason. Client: map the new error to a friendly message in the wave send paths (wave_controller.dart / pill onWave) — "They're not on the radar right now."
STEP 5: deploy. cd functions && npm run build (no predeploy hook — Rule #101) && firebase deploy --only functions:sendWave --project prod. NEVER a bare deploy (ambient project is tremble-dev).

INVARIANTS (must survive): scanProximityPairs pair/bearing/cooldown logic untouched; proximity doc schema unchanged; blocked-user eval-without-notify unchanged; safe-zone write path (geo_service.dart:235) unchanged; finder invariants (coords only in matches/{id}/finder/{uid}; callable returns only {partnerSharing, bearing?, distanceM?, reason?}).

VERIFY: flutter analyze clean · flutter test --dart-define-from-file=.env.json (all green, baseline 487) · functions: tsc + eslint clean, jest green (baseline 240) · flutter build apk --debug --flavor dev --dart-define-from-file=.env.json --dart-define=FLAVOR=dev.
PR: title "[PLAN-ID: 20260723-radar-off-invisible] fix(proximity): radar off means invisible + unmatchable". Body MUST contain "Verification checklist" with "unit tests / integration tests / security scan" lines (Metadata gate greps these; no admin bypass). Pre-flight the 4 checks from memory before gh pr create. Founder approval BEFORE merge (HIGH). Post-merge founder device check: Martin radar-off scenario no longer notifies/matches.
```

---

## PROMPT 2 — BUG-HAPTICS-PERSIST (P1, MEDIUM)

```
TREMBLE — fix BUG-HAPTICS-PERSIST. Sonar vibrations must stop the moment the trembling window ends AND the moment radar is toggled off. Cross-platform repro on build 35.

BOOTSTRAP: tasks/blockers.md → SESSION 62 → BUG-HAPTICS-PERSIST; tasks/lessons.md → Rule #104 (this bug), #102 (same controllers — do NOT reintroduce doc-churn), #99 (autoDispose/keep-alive test traps). Rule #83 git check first.

Plan ID: 20260723-haptics-stop · Risk: MEDIUM (client-only Riverpod lifecycle; no CF, no rules, no deploy) · Branch: fix/haptics-persist off main.

CONFIRMED ROOT CAUSE (3 defects):
1. lib/src/features/match/application/match_service.dart:22-32 — currentSearch checks the 30-min expiry against DateTime.now() only when a Firestore snapshot arrives. No re-evaluation at the expiry instant → expired match returned indefinitely → SonarPingController (proximity_ping_controller.dart) never rebuilds to its null branch; BLE sub + haptic loop stay live.
2. lib/src/features/dashboard/application/proximity_ping_controller.dart — _pingStep (:245-271) is a self-recursing async loop; its ONLY in-place stopper is the `searching` branch of _tickFreshness (:186-197). The precise-finder early-return (:160-170) bypasses that branch → while _preciseDistanceM != null the loop can NEVER stop in place, even with BLE dead.
3. home_screen.dart:1169-1188 — radar toggle OFF stops BleService + background service but signals neither SonarPingController nor PreciseFinderController.

FIX (TDD, atomic commits):
STEP 1: expiry tick in currentSearch. When a pending match is selected, schedule Timer(expiry − now, () => ref.invalidateSelf()); cancel via ref.onDispose; reschedule on rebuild. After invalidation the where-filter drops the expired match → controllers rebuild to null → _reset() stops the loop. RED test with fake_async: provider returns match before expiry, null after the timer fires with NO new snapshot.
STEP 2: haptic loop must be BLE-freshness-gated even during a precise session. In _tickFreshness, compute signalStateFor(sinceLastSample) FIRST; if searching → _stopPingLoop() unconditionally, THEN handle the precise-dot early-return (dot may stay precise-driven; haptics must not). RED test: finder active (hasPreciseData) + no BLE sample for >6s → no further Vibration calls (inject/spy the haptic; see existing sonar_ping_controller_test.dart patterns).
STEP 3: radar-off stops the session. In the toggle's else-branch (home_screen.dart:1173 after BleService().stop()): unawaited(ref.read(preciseFinderControllerProvider.notifier).stop()); ref.invalidate(sonarPingControllerProvider); — rebuild with dead BLE arms nothing until fresh RSSI. Widget test: toggle off → finder stop called + ping loop not looping.
STEP 4 (micro, same lane): caption precedence in radar_search_overlay.dart — when the finder fallback copy ("They're close — look around") is shown, suppress the sonar "SEARCHING…" caption (screenshot showed both stacked). One caption at a time; widget test.

INVARIANTS: do NOT add writes to matches/{id} (Rule #102); do NOT change SonarPing math, preciseRadius, or dotAngle; PreciseFinderController's existing stop semantics (found/expiry/background revoke; `inactive` ≠ paused) unchanged; keep-alive ref.watch in _RadarSection stays.

VERIFY: dart format stable · flutter analyze clean · flutter test --dart-define-from-file=.env.json all green (baseline 487 + new) · debug APK builds (--flavor dev --dart-define=FLAVOR=dev).
PR: "[PLAN-ID: 20260723-haptics-stop] fix(radar): stop sonar haptics at window end and radar off". Body: Verification checklist (unit tests / integration tests / security scan). 4-check pre-flight before gh pr create. MEDIUM → no founder-approval gate, but device re-check owed: vibrations stop at countdown end AND at radar-off, without navigating away.
```

---

## PROMPT 3 — BUG-WAVEPILL-TAP-PROFILE (P2, MEDIUM)

```
TREMBLE — fix BUG-WAVEPILL-TAP-PROFILE. Tapping the photo/name on the "is nearby" / "sent you a wave" pill must open the premium-gated profile card, with ZERO wave side-effect.

BOOTSTRAP: tasks/blockers.md → SESSION 62 → BUG-WAVEPILL-TAP-PROFILE (+ FEATURE-POSTMATCH-NOTIFTAP — this lane partially covers it); Rule #83 git check.

Plan ID: 20260723-wavepill-tap-profile · Risk: MEDIUM (client nav only) · Branch: fix/wavepill-tap-profile off main.

CONFIRMED ROOT CAUSE: MatchNotificationPill already exposes onTap for avatar+label ("open profile or paywall", match_notification_pill.dart:58-59; tap targets :526-571, separate from the wave button at :602). The single production call site — WavePillService.show inside presentWavePill (lib/src/core/router.dart:560-571) — never passes onTap → photo tap does nothing.

FIX (TDD):
STEP 1: in presentWavePill, pass onTap to WavePillService.show. Behavior (mirror the PR #73/#75 gating exactly — see _openTremblingPartner in home_screen.dart and BasicMatchProfileScreen usage):
  - free (effectiveIsPremiumProvider false) → BasicMatchProfileScreen (photo + name/age + hobbies if available + "See full profile · Premium" CTA → paywall). NEVER PremiumPaywallBottomSheet directly (empty-offerings red overlay, CONFIG-REVENUECAT-OFFERINGS).
  - premium → push '/profile' with a MatchProfile extra.
  Profile source: try ref.read(getMatchByUserIdProvider(targetUid)) for a real MatchProfile; when absent (pre-match "is nearby" — no match doc yet) build a minimal MatchProfile from WavePillData (name, age, imageUrl, targetUid — payload fields already carried by the push). No getPublicProfile call (client direct-read history: BLOCKER-POSTMATCH-PHOTO).
STEP 2: tapping avatar/label must NOT send a wave and must dismiss the pill (WavePillService dismissal exists — dismissForTarget/removeEntry patterns from PR #78). Wave stays exclusively on the wave button.
STEP 3: navigation from an overlay — use rootNavigatorKey.currentState context per Rule #86 (overlay.context for sheets). Cold-launch tap path already polls readiness (presentWavePill attempt loop) — onTap inherits it for free; don't touch that loop.
RED tests: widget test pill-with-onTap → tap avatar → callback fired, no onWave call; router-level test free→Basic, premium→/profile; pill dismissed on tap.

VERIFY: analyze clean · flutter test --dart-define-from-file=.env.json green · debug APK builds.
PR: "[PLAN-ID: 20260723-wavepill-tap-profile] fix(pill): avatar tap opens gated profile card". Body: Verification checklist (unit tests / integration tests / security scan). 4-check pre-flight. Update blockers.md: mark this bug shipped; note FEATURE-POSTMATCH-NOTIFTAP remaining scope (OS-notification tap → card) if not fully covered.
```

---

## PROMPT 4 — BUG-ONBOARDING-RITUAL-SKIPPED (P2, MEDIUM-HIGH)

```
TREMBLE — fix BUG-ONBOARDING-RITUAL-SKIPPED. The RitualStep "SIGNAL LOCKED" success animation must actually play after registration completes.

BOOTSTRAP: tasks/blockers.md → SESSION 62 → BUG-ONBOARDING-RITUAL-SKIPPED; Rule #83 git check. Touches auth/registration flow → treat as HIGH-adjacent: founder approval before merge.

Plan ID: 20260723-onboarding-ritual · Branch: fix/onboarding-ritual-order off main.

CONFIRMED ROOT CAUSE (race, code-traced): completeRegistration (lib/src/features/auth/presentation/registration_flow.dart:1868-1899) awaits authNotifier.completeOnboarding(user) → auth-state emit flips isOnboarded → GoRouter redirect (lib/src/core/router.dart:98-149; refreshListenable on auth) yanks /onboarding → /permission-gate (gdpr consent was just reset at :1888) → RegistrationFlow is DISPOSED during its own 2500ms hard-lock delay (:1891-1898) → `if (mounted)` guards silently skip _goToPage(RitualStep). The comment at :1868-1870 documents the disposal race; navigation loses every time on prod (in debug the bypass path masks it). RitualStep = registration_steps/ritual_step.dart (7.5s haptic choreography).

FIX (TDD) — reorder so the router-visible flip happens AFTER the ritual:
STEP 1: split the notifier method. In authStateProvider notifier add completeOnboardingRemote(user) → performs the CF call + everything completeOnboarding does EXCEPT emitting isOnboarded=true locally; and commitOnboarded() → the local emit only. Keep the old completeOnboarding delegating to both (other callers unbroken — grep first; adjust tests).
STEP 2: completeRegistration new order: (1) await completeOnboardingRemote (server truth saved; on failure → existing error path, no ritual); (2) hard-lock + _goToPage(RitualStep) — widget stays mounted because nothing emitted; (3) on ritual completion callback (see ritual_step.dart's completion hook; add one if missing) → await commitOnboarded() + gdprNotifier.resetConsent() → router redirects to /permission-gate exactly once, after the animation. Move resetConsent to step 3 (it currently runs before the delay at :1888 — consent reset must not precede the ritual either).
STEP 3: guard: if the user backgrounds/kills mid-ritual, next launch must not strand them — completeOnboardingRemote already persisted server-side; router's needsOnboarding uses profile status (router.dart:97-100), so verify a killed-mid-ritual relaunch lands correctly (profile isOnboarded true server-side → straight to permission gate; acceptable) and note it in the PR.
RED tests: notifier split (remote does not emit; commit emits); flow test with faked notifier — ritual page reached post-completion, commit called only after ritual completion; failure of remote → error UI, no ritual, no emit.

INVARIANTS: dev-mode kDebugMode bypass branch (:1900-1928) gets the same ordering; page indices (Platform.isAndroid ? 30 : 29) unchanged; do NOT touch the router redirect chain itself; prod-env test suite has 1 known dev-coupled failure (photo_upload_registration_test under .env.prod.json — memory) — run tests with .env.json.

VERIFY: analyze clean · flutter test --dart-define-from-file=.env.json green · debug APK · manual dev-flavor registration run-through: ritual plays, then permission gate.
PR: "[PLAN-ID: 20260723-onboarding-ritual] fix(auth): play SIGNAL LOCKED ritual before onboarded flip". Body: Verification checklist (unit tests / integration tests / security scan). 4-check pre-flight. Founder approval before merge.
```

---

## PROMPT 5 — FEATURE-INTERCEPT-RECEIVE-PILL (cluster 3, MEDIUM-HIGH)

```
TREMBLE — build FEATURE-INTERCEPT-RECEIVE-PILL: the receive side of Pulse Intercept (Send Photo / Send Phone) inside the trembling window, as side-anchored pop-up pills.

BOOTSTRAP: tasks/blockers.md → SESSION 62 → FEATURE-INTERCEPT-RECEIVE-PILL + FEATURE-POSTMATCH-TREMBLING-REDESIGN (Session-52 spec: view-once photo, 10-min/1-view destroy) + FEATURE-POSTMATCH-INTERCEPT (cluster-3 leftovers: notification image never viewable, 2× duplicate). Read functions/src/modules/matches/intercept.functions.ts IN FULL (payload shape, :108 PULSE_INTERCEPT push) and lib/src/features/matches/data/match_repository.dart:210-230 + :409-425 (getPulseIntercept exists, one passthrough consumer, NO UI). Rule #83 git check.

Plan ID: 20260723-intercept-receive · Risk: MEDIUM-HIGH (notifications + ephemeral media; no rules/schema change expected — flag for founder if one becomes needed) · Branch: feat/intercept-receive-pill off main.

CURRENT STATE (audited): send side shipped (PulseInterceptBar in RadarSearchOverlay, requestPulseIntercept callable). Server pushes type:"PULSE_INTERCEPT". Receive side is ENTIRELY unbuilt — no foreground handler branch surfaces it, no widget renders it.

FOUNDER SPEC (Session 62, layout refs = build-35 screenshots):
- During an active window, partner sends photo/phone → recipient sees an in-window pop-up pill anchored next to the partner name (top area, under "Name, age"), horizontally aligned to the matching action: photo-pill toward the LEFT (Send Photo button side), phone-pill toward the RIGHT (Send Phone side). Both may coexist (photo left + phone right), never overlapping.
- Tap photo-pill → view-once photo viewer (full-screen, destroy after one view or 10 min — translations send_photo_subtitle already promise this). Tap phone-pill → partner's number + call action (url_launcher tel:). Dismiss on window end / match found.
- ALSO fix cluster-3: (a) intercept push's image not viewable — inspect the FCM payload in intercept.functions.ts; route the tap through the same in-app viewer instead of relying on notification-image rendering; (b) 2× duplicate delivery — dedupe by intercept id on the client (same pattern as the wave-pill dedup work, PR #78).

BUILD (TDD, atomic commits): 1) foreground FCM branch for PULSE_INTERCEPT (notification_service → callback into router/overlay layer, mirroring onForegroundWave wiring in router.dart:594-617); 2) InterceptReceiveController (fetch via MatchRepository.getPulseIntercept, hold {type, payload, interceptId}, dedupe, expire with window); 3) InterceptPill widget in RadarSearchOverlay (side-anchored per type, entrance animation consistent with MatchNotificationPill, Material ancestor per Rule #93, overlay via rootNavigatorKey.currentState.overlay per Rule #86 if presented as overlay); 4) ViewOncePhotoScreen (single view → mark viewed via repo if server supports, local destroy timer 10 min); 5) phone sheet with call action; 6) background-tap path: notification tap on PULSE_INTERCEPT routes into the same surfaces (reuse handleNotificationNavigation).
Tests: controller unit (dedupe, expiry), widget (both pills placed on correct sides, no overlap), view-once lifecycle (fake clock), notification-branch routing test.

INVARIANTS: no client Firestore direct-reads of other users (callables only); no coords/PII beyond what getPulseIntercept returns; free/premium — intercept is available in-window per current product (do not add gating this lane); do not touch finder/sonar controllers.

VERIFY: analyze clean · flutter test --dart-define-from-file=.env.json green · debug APK · dev two-sim/device check if feasible.
PR: "[PLAN-ID: 20260723-intercept-receive] feat(intercept): receive-side pills + view-once photo + call action". Body: Verification checklist (unit tests / integration tests / security scan). 4-check pre-flight. If ANY server change becomes necessary (payload field, new callable): STOP, flag founder (HIGH lane, deploy with --project prod per Rule #101).
```

---

## FOUNDER CHECKLIST (not a chat prompt)

- **DIAG-IPHONE15-FINDER re-test order (revised 2026-07-23 — founder confirmed Precise Location ON + Always, toggle hypothesis dead; new hypothesis: non-Pro iPhone 15 has no dual-frequency GNSS → real accuracy intermittently >30m → `poor_accuracy` short-circuit, see blockers.md):** (1) open-sky spot; compare Maps blue-dot accuracy circle on both phones — 15's circle visibly larger = confirmed; (2) Low Power Mode off; (3) remove MagSafe/magnetic case; (4) both phones tap "Help us find each other" in the same window; (5) still wrong → dev build B0 overlay + report exact symptom (fallback vs wrong arrow). Note for the next finder code lane: `updateFinderLocation` never logs rejection reasons — add one structured log line so this is remotely diagnosable.
- ~~**Play Console:** upload `release-symbols/b35/app-prod-release.aab`~~ — DONE (founder 2026-07-23; Martin's device got b35 via Play Console).
- Roadmap items parked until the above lanes clear: photo/camera fix, map fix, gym/run-club/event mode verification, event geofencing.
