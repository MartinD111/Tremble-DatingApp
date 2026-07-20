## Session State — 2026-07-20 (Session 53) — 2 BUG LANES SHIPPED → BUILD 31

- **main @ ffcf6b3** (PRs #72 + #73 merged; branches deleted). Build 31 (`1.0.0+31`) built + uploaded this session via `chore/build-31` (`8ab9060`) — `scripts/release/build_prod.sh all` (iOS TestFlight + Android AAB, Sentry symbols for `tremble.dating.app@1.0.0+31`). **Founder: check `/tmp/build31.log` for the TestFlight Delivery UUID + AAB path; upload AAB to Play.**
- **Shipped (both TDD, merged):**
  1. **BUG-BLOCKED-USERS-LIST** (PR #72) — Blocked Users screen errored whenever ≥1 user blocked: it did direct `/users/{id}` reads (rules = self-only). New `getBlockedUsers` Admin-SDK callable; provider re-sourced off it. **Callable DEPLOYED to prod** (`am---dating-app`, created 2026-07-20). Same bug class as the reveal "?".
  2. **BUG-HISTORY-CARD-TAP** (PR #73) — Free mutual-tile tap → new `BasicMatchProfileScreen` (photo+name/age+3 hobbies + "See full profile · Premium" CTA→paywall); Premium → full card. ADR-007 §1 Amendment + LEGAL-005 note. Client-only.
- **Also:** labeled CONFIG-REVENUECAT-OFFERINGS (red banner = no App Store products attached to the RevenueCat offering — founder/dashboard, not code). Added reusable `test/support/network_image_mock.dart`.
- **Secret rotation (FOLLOWUP-SEC-002): founder de-prioritized ("ignore the leak"). Off the active list.**

### DEVICE TEST MATRIX — build 31 (founder)
1. **Blocked Users:** block a user → Settings → Blocked Users shows them (name+photo), no red error; unblock removes them. (needs the deployed callable — done.)
2. **History card tap:** Free acct → tap a mutual match → **basic card** (photo+name/age+3 hobbies) + "See full profile" → paywall. Premium acct → tap mutual match → **full** profile card.
3. **Carry-over from build 30 (still unverified):** reveal + trembling window show real photo/name/age; partner-card tap → profile(premium)/paywall(free); Stop → spinner→close, failure→toast; history in colour with hobbies (a NEW match + backfilled Nikolina/Martin).
4. **getPublicProfile "?" root cause:** open a **recap** on build 31 (recap is the last caller after batch-3 re-sourced the reveal) → then read `[USERS getPublicProfile]` prod log → confirm cause → remove temp diagnostic.

### STILL OPEN → next session (build 31+ lanes)
- **Step 4** notif-tap → partner profile card (reuse the new `BasicMatchProfileScreen` gate + `effectiveIsPremiumProvider`; wire `router.dart`/`notification_service`/`wave_pill_service`).
- **Step 5** Pulse Intercept full flow (Send Photo→camera→upload→recipient pill→tap opens photo; Send Phone→recipient notif→dialer/call). cluster 3.
- cluster 2 (iOS pill 2× dedup), cluster 4 (radar not spinning / partner not plotted).
- getPublicProfile diagnostic removal (after the recap log read).

---

## Session State — 2026-07-20 (Session 52 cont.) — BATCH 3 SHIPPED → BUILD 30 ON TESTFLIGHT + PR #70 MERGEABLE

### PR #70 conflicts resolved + gates green (do the merge when ready)
- **PR #69 was squash-merged into `main` (`e937fd9`).** The branch kept batch 1 as individual commits + batch 2/3 → PR #70 conflicted on 6 files. Resolved by merging `origin/main` and taking `--ours` (branch is a strict superset); verified 387 Flutter + 164 functions green, analyze clean, no markers (`aa89ce8`). Branch now **0 behind / 27 ahead**. See lesson #94.
- **PR #70 title+body set** for the MPC gate: `[PLAN-ID: 20260719-post-match-flow-repair]` + Verification checklist (unit/integration/security) + `ADR-007` (required because pubspec.yaml is touched). **Required gates ①–⑧ all green**; ⑦ Founder Approval **skips** (body declares low/medium risk — the prod deploys already had live founder approval). Merge state `UNSTABLE` = mergeable; only the **non-required** "Build Dev APK" was still building. **Founder: squash-merge PR #70 when ready** (not merged by assistant).

### (below) BATCH 3 shipped → BUILD 30

- **Branch:** `fix/post-match-flow-repair`, PR #69 (do NOT merge yet). **Build 30 live on TestFlight** — Delivery UUID `a136a10b-ac5d-4c68-af98-c8cfed277048`; AAB + dSYMs at `release-symbols/b30/` (versionCode 30, founder uploads AAB to Play); Sentry symbols uploaded for `tremble.dating.app@1.0.0+30`. pubspec `1.0.0+30`.
- **Shipped this batch (all TDD, 387/387 Flutter + 34 matches CF green, analyze clean):**
  1. **P0 "?" KILLED** (`e87f73c`) — reveal + trembling window re-sourced from `getMatches`/`MatchProfile` via new `partnerMatchProfileProvider` (not `getPublicProfile`). New always-visible `TremblingPartnerCard` at top of radar (circle photo + name/age; tap → `/profile` premium / paywall free).
  2. **Stop button** (`a645730`) — `onStop` now `Future<void>`; overlay shows a spinner while `markMatchFound` round-trips and surfaces a retry snackbar on failure (no more silent hang).
  3. **History greyscale fixed** — `onWaveCreated` + `onRunCrossUpdated` now seed `gestures{uidA,uidB}=true` at match creation (`c3d9514`, **DEPLOYED to prod**) so genuine matches are `hasMutualWave` → colour. `sharedFirstHobbyNames` adds up to 3 hobbies to mutual tiles (`3727b54`). Legacy prod matches backfilled via `functions/src/scripts/backfill_match_gestures.ts` (`0c85358`) — **applied to prod: 2 docs seeded, idempotent re-run = 0**.
- **Prod deploys this session (am---dating-app, europe-west1):** `getPublicProfile` (requireAuth + TEMP per-branch diagnostic, `fc737e6`), `onWaveCreated`, `onRunCrossUpdated`.
- **STILL OPEN / on founder:**
  - 🔴 **Secret rotation** — R2_SECRET_ACCESS_KEY, RESEND_API_KEY, UPSTASH_REDIS_REST_TOKEN exposed in a pasted Cloud Run revision spec (FOLLOWUP-SEC-002 updated). Rotate in the config lane.
  - **getPublicProfile root cause** — still unconfirmed; read the `[USERS getPublicProfile]` log line (Logs Explorer, service_name=getpublicprofile) after a device tap. Client no longer depends on it, but **recap still does** (`run_recap_screen.dart:476`). Remove the temp diagnostic once known.
  - **Device-verify build 30:** reveal/window identity, partner card + tap gate, Stop spinner/close + failure toast, history in colour with hobbies (new match AND the 2 backfilled).
- **Deferred to build 31:** #3 notif-tap → card; #5 Pulse Intercept camera/dialer flow (own TDD lanes).

---

## Session State — 2026-07-19 (Session 52) — BUILD 29 TESTED → REDESIGN THE TREMBLING WINDOW

- **Branch:** `fix/post-match-flow-repair`, PR #69 GREEN, build 29 on TestFlight. Build 29 device test done — results below.
- **WORKS on build 29 (device-confirmed):** Pulse Intercept (Send Photo / Send Phone) now renders in the trembling window above the timer/stop (Step 3 ✅). Timer counts down.

### Build 29 device findings (NEW)
1. **P0 — match reveal STILL "?"** (no photo/name/age/hobbies), AND the trembling-window partner shows no identity either. So `publicProfileProvider(partnerId)` → `getPublicProfile` returns null/throws in BOTH places, DESPITE the `requireAuth` deploy. **It is silently swallowed:** the reveal uses `.whenOrNull(data:)`, and `ProfileRepository.getPublicProfile` throws on `profile==null` — no Sentry event exists for build 29 (checked errors dataset, `release:…@1.0.0+29` = 0). Static analysis this session RULED OUT: match-ID mismatch (both creation `matches.functions.ts:593` and CF lookup use sorted `uidA_uidB`) and schema (match doc has userA/userB/userIds/status; `matches.functions.ts:682`). Cause is still unknown — need to surface the swallowed error.
2. **No always-visible partner profile card** in the trembling window — founder wants the matched user's card always accessible (tap → free/premium view) so you can re-check who you matched with.
3. **Stop button** — unclear if it works or is delayed. Needs verification (`markMatchAsFound` callable via `onStop`).
4. **History still greyscale** — shows past matches (Nikolina, Martin) greyscaled; should be a free-user basic card (5d).

### FOUNDER TARGET SPEC (locked — this is the redesign)
**Flow:** send wave OR receive one → mutual → **match page** → home/trembling window.
- **Match page:** partner photo, name, age, 3 hobbies (shared first), Start radar. (Current "?" is the P0 bug.)
- **Trembling window / home (top → bottom):**
  1. **Partner profile card** — circle photo + **name/age shown under the photo**, ALWAYS visible. Tap → opens the full profile card gated by the viewer's package (free vs premium view differs).
  2. **Radar** — spinning; a dot appears past the circle edge = the other user's location.
  3. **Pulse Intercept** (already here): **Send Photo opens the camera to take/choose a photo (Snapchat-style) then send**; **Send Phone** sends the number. Receiver gets a notification/pill → tapping it opens the photo, or for a phone number **opens the dialer / starts calling**. Plus the **timer + Stop** (Stop must actually work).
- **History:** free-user basic card (photo + name/age + 3 hobbies), not greyscale.

### KEY DIRECTION for the fix (found this session)
`getMatches` (CF `matches.functions.ts:964-988`) ALREADY returns partner `name/age/photoUrls/hobbies/hasMutualWave` via Admin SDK and is proven working for the matches list. Client side: `MatchProfile.fromApi` + `getMatches()` in `match_repository.dart:126/189`. **Recommend sourcing the reveal card + the always-visible trembling-window profile card + history from `getMatches`/`MatchProfile` instead of `getPublicProfile`** — one proven data path, sidesteps whatever gate is nulling `getPublicProfile`, and directly enables the profile card + history card. (Still worth root-causing WHY getPublicProfile returns null — add a temporary `Sentry.captureException` in `ProfileRepository.getPublicProfile` catch, or per-branch logging in the CF + redeploy, to learn if it's permission/App-Check/match-gate.)

### PRIORITY ORDER (Session 52)
1. **P0 — kill the "?"**: surface the swallowed getPublicProfile error to learn the cause; then either fix the CF or (preferred) re-source the partner card from `getMatches`/`MatchProfile`. Verify on match page + trembling window.
2. **Always-visible partner profile card** above the radar (circle photo + name/age under it), tap → free/premium full card. New widget in `RadarSearchOverlay` (has `partnerUid` now; add name/age/photo — pull from `MatchProfile`).
3. **Step 4** — notification tap → partner profile card (free/premium). Ties into #2's card.
4. **Stop button** — verify/fix (`onStop` → `markMatchAsFound`); check for delay.
5. **Pulse Intercept full flow** — Send Photo → camera picker → upload → recipient notification/pill → tap opens photo; Send Phone → recipient notification → tap → dialer/call. (cluster 3: image never viewable + 2×.)
6. **History** free-user basic card (5d), drop greyscale.
7. iOS pill 2× dedup (cluster 2); radar-not-spinning/partner-not-plotted (cluster 4).
- Build 30 after a meaningful batch (bump pubspec, `build_prod.sh all` — load SENTRY token via zsh first, see below).

## Session State — 2026-07-19 (Session 51) — POST-MATCH FLOW REPAIR (BATCH 2 SHIPPED)

- **Branch:** `fix/post-match-flow-repair`, **PR #69 OPEN + CI GREEN** (the Session-50 CI-red is fixed). pubspec `1.0.0+29`.
- **Build 29 shipped:** iOS TestFlight (Delivery UUID `6d2cbef2-aaf2-4cea-b0ca-9bff4453a6f2`, 71 dSYMs), Android AAB `release-symbols/b29/app-prod-release.aab` (versionCode 29, founder uploads to Play). **Sentry symbols UPLOADED** — release `tremble.dating.app@1.0.0+29` created+finalized in `tremble-functions` (iOS dSYMs + Dart maps + Android arm64/arm/x64), so build-29 crashes symbolicate. NOTE: `SENTRY_AUTH_TOKEN` lives in `~/.zshrc` (interactive-only) — a non-interactive Bash shell can't see it; load it with `export SENTRY_AUTH_TOKEN="$(zsh -ic 'printf %s "$SENTRY_AUTH_TOKEN"')"` before any `build_prod.sh` upload.
- **Prod deploy this session:** `getPublicProfile` (relaxed to `requireAuth`) — additive/validated, fixes reveal photo on build 28 too.

### DONE + committed on the branch (all CI-green)
- **Step 1 — Safety sheets (`a9ba5eb`):** block + report rebuilt as themed **Material bottom sheets** (dropped `CupertinoAlertDialog`). Fixes the iOS `Material.of` crash (TREMBLE-FUNCTIONS-12), #8 can't-block, #9 too-light popup, #10 broken report, AND the CI-red test. **Corrected root cause (see lesson #93):** the CI failure was NOT #12 — it was a `ListTile`-under-opaque-`DecoratedBox` assert that only fires on CI's newer Flutter stable (local is pinned 3.41.4). Two distinct Material-ancestor bugs, both fixed structurally.
- **Step 2 — Photo gate (`dbbc7b7`, DEPLOYED):** `getPublicProfile` → `requireAuth` (already match-gated). Fixes reveal photo/name/age/hobbies "?" (#1,#3,#7).
- **Step 5 — Pills (`e094a5d`):** foreground wave pill moved `topPad+14 → topPad+80`, clears the gym/run/event + schedule control bar. (iOS 2× dedup NOT addressed — still open, needs device.)
- **Step 3 — Pulse Intercept move (`095b50c`):** Send Phone/Send Photo extracted to new `PulseInterceptBar` widget, now rendered in the **trembling window** (`RadarSearchOverlay`, above the countdown) when `partnerUid != null`; removed from `match_reveal_screen` (reveal = photo+age+3 hobbies only). `RadarSearchSession` gained `partnerUid`.

### OPEN — Session 51 handoff (priority order)
1. **Device-verify build 29** (founder): reveal photo loads; block/report work + readable on iOS; report scrolls with a Submit; pill sits below the control bar; Send Phone/Photo appears in the trembling window (radar search), NOT the reveal.
2. **Step 4 (NOT DONE)** — tapping a "nearby"/"wave" notification must open the partner's **profile card** (free vs premium view differs). Deferred: needs the notification-tap handler wiring + the free/premium card, plus device verification. Investigate `router.dart` notification-tap path + `wave_pill_service`/`notification_service`.
3. **iOS pill dedup (cluster 2)** — "wave sent" shows 2× overlapping "is nearby". Local pill (`_MatchNotificationPillOverlay`, +80) vs APNs pill (`WavePillService`, now +80) presentation dedup. Needs device repro.
4. **Cluster 4** — radar not spinning / partner not plotted during window (uninvestigated).
5. **5d** — history greyscale → free-user basic card.
6. **Merge PR #69** once device-verified (CI green; "MPC — Founder Approval" + "Quality Gate" show as *skipped*, not failing).
- IGNORE: TREMBLE-FUNCTIONS-11 (CancellationException, benign backgrounding).

## Session State — 2026-07-19 (Session 50) — POST-MATCH FLOW REPAIR (IN PROGRESS)

- **Branch:** `fix/post-match-flow-repair` (6 commits, NOT merged). **PR #69 OPEN + CI RED.**
- **Build 28 shipped:** iOS TestFlight (Delivery UUID `597d5be8-99f8-4fea-903c-2d02da4e6f50`), Android AAB at `release-symbols/b28/app-prod-release.aab` (Play internal upload = manual, founder-side). pubspec `1.0.0+28`.
- **Prod deploys this session (am---dating-app, europe-west1):** `markMatchFound`, `sendMatchGesture` (new callables), `onWaveCreated` (reveal fix). All additive/validated.

### DONE + committed on the branch
- **Cluster 6** (`5e86d89`) — block dialog crash (TREMBLE-FUNCTIONS-10): dialog popped via dismissed-sheet dead context. Rebuilt with `showDialog` + builder ctx. ⚠️ **Its own test FAILS in CI (passes locally) — see BLOCKER-POSTMATCH-CI.**
- **Cluster 1** (`770b949`) — symmetric reveal + window restart in `onWaveCreated`. `seenBy:[]` (was `[fromUid]` → wave-back completer never saw reveal); re-wave on a positively-over window restarts it. **DEPLOYED + DEVICE-VALIDATED (both users get the match page).**
- **Cluster 5a** (`acb7691`) — reveal read partner `/users` doc directly (denied) → "?". Routed through `getPublicProfile` CF. ⚠️ **STILL "?" on device — CF has a SECOND gate `requireVerifiedEmail` (authGuard.ts:34); test accounts unverified. DECISION: relax to `requireAuth` (match-gated is enough).**
- **Cluster 5b/5c** (`3acaa3a`) — explicit `_StartRadarButton` (replaced invisible tap-anywhere) + shared-hobby chips on reveal. Button works on device; chips/photo blocked by the same email gate as 5a.

### OPEN — Session 50 test findings (build 28), PRIORITY ORDER
See BLOCKER-POSTMATCH-* in blockers.md. Founder-locked decisions:
- **Photo gate:** relax `getPublicProfile` to `requireAuth` (HIGH-risk CF + deploy).
- **Next priority:** (1) fix CI red on PR #69 + squash TREMBLE-FUNCTIONS-12 crash + rebuild block/report iOS dialogs → merge; (2) photo gate; (3) rest.

1. **CI RED (blocks PR #69 merge)** — `test/features/safety/ugc_action_sheet_block_dialog_test.dart` fails in CI, passes locally (macOS). "Multiple exceptions" = the crash still fires in the CI (Linux) env. Cluster-6 fix incomplete/env-sensitive.
2. **TREMBLE-FUNCTIONS-12** (iOS, dist 28, fatal, unhandled) — `Material.of` null → `_InkState._build` → `WidgetStateProperty`. Material widgets inside a `CupertinoAlertDialog` (no Material ancestor). = the **Report dialog** (#10) + block dialog on iOS.
3. **Photo/hobbies still "?"** (#1,#3,#7) — relax email gate (above). Alt considered: feed reveal from getMatches data.
4. **Safety flow iOS** (#8 can't block, #9 block popup too light/white-text-invisible, #10 report TOTALLY broken — endless scroll, 0 buttons) → **rebuild block+report as themed bottom sheets, not CupertinoAlertDialog.** One lane; fixes crash #2 too.
5. **#6 ARCHITECTURE** — move Send Phone/Send Photo (Pulse Intercept) OUT of match reveal (`match_reveal_screen.dart` `_buildPulseInterceptActions`) INTO the **trembling window** (radar search phase). It's *assistance during the meetup*, NOT matching. Match page keeps: photo + age + 3 hobbies only.
6. **#4 NEW FEATURE** — tapping a "nearby"/"wave" notification must open the partner's **profile card** (free vs premium view differs).
7. **#5 UI** — in-app pills render TOO HIGH; cover the radar-mode buttons (gym/run/event) + the schedule-radar button (top-right). Move pills lower. (This is also cluster 2 territory: iOS shows "wave sent" 2× overlapping "is nearby" — iOS-only presentation dedup.)
8. **Cluster 4** — radar not spinning during window / partner not plotted (uninvestigated).
9. **5d** — history greyscale → free-user basic card (photo+age+3 hobbies).
10. **TREMBLE-FUNCTIONS-11** — CancellationException "Cancelled", handled, benign (cancelled future on backgrounding). IGNORE.

### Control-plane refactor note
Session-49 lessons #86-88 were cherry-picked onto this branch (`20254ab`) after `chore/context-session-49` was deleted; they land in main when PR #69 merges.

## Session State — 2026-07-18 (Session 49)
- Active Task: Root-caused + fixed the wave pill never rendering; shipped build 26 to TestFlight.
- Environment: local + GitHub; one prod build → TestFlight (founder-approved). No prod backend/rules/config mutation.
- System Status: `main` clean; pubspec `1.0.0+26`; build 26 live on TestFlight (Delivery UUID `2024e76c-bed2-4b21-a6f2-f0f57c4b6835`). Sentry dist-26 dSYMs + Dart symbol maps uploaded/finalized. Artifacts in `release-symbols/b26/`.
- Android AAB (versionCode 26, signed prod) at `release-symbols/b26/app-prod-release.aab` — ready for a Play Console **internal testing** upload to cross-check the pill on Android (NOT production: Play prod is gated on STORE-003/004). Not yet uploaded.
- Open PRs at handoff: **#67** (this Session 49 docs record). PRs #62/#63/#64/#65/#66 all merged.

### ROOT CAUSE FOUND — wave pill never rendered (foreground AND tap)
Device evidence (build 25, 2026-07-18 08:48:03): scanProximityPairs sent TWO visible
CROSSING_PATHS (`pairsNotified:2`, `mode:"visible"`) while the app was foreground →
nothing shown. `presentWavePill` read the overlay via
`Overlay.maybeOf(rootNavigatorKey.currentContext)`, which is ALWAYS null — the root
Navigator's Overlay is a DESCENDANT of that context, not an ancestor, so maybeOf (walks
ancestors) never finds it. The pill could never insert, foreground or tap. Fix:
`rootNavigatorKey.currentState.overlay`. Proven by `test/core/root_overlay_resolution_test.dart`.
The handoff's PR #60-forwarding suspicion was REFUTED against real Flutter engine source
(e4b8dca): didReceiveNotificationResponse forwards to firebase_messaging fine. See memory
`crossing-paths-tap-pill-root-cause`.

### Merged this session
- **PR #62** — presentWavePill bounded readiness retry (20×250ms) + `Sentry.captureMessage('wave pill dropped: auth-null|no-overlay')` on give-up + path breadcrumbs (background vs cold-launch).
- **PR #63** — `functions/src/scripts/send_test_push.ts`: deterministic on-demand FCM trigger (CROSSING_PATHS / INCOMING_WAVE, by uid or --token, prod payloads reused). Unblocks device verification without the scan/cooldown.
- **PR #64** — map cold-offline card: `MapOfflineCard` + retry via `ref.invalidate(mapInitProvider)`; replaces raw `Failed host lookup` red text. i18n added to all 8 locales (+ hr `try_again`).
- **PR #65** — THE overlay render fix (above).
- **PR #66** — release 1.0.0+26 → TestFlight.

### OPEN — next session
1. **On-device verification (FOUNDER, build 26)** — the payoff of all the above, still unproven. Use `send_test_push.ts`. Matrix: (a) app FOREGROUND + push → pill, no freeze; (b) BACKGROUND + tap → pill; (c) KILLED + tap → cold-launch pill; (d) airplane mode on map → offline card. If a pill still drops, Sentry (tremble-functions, dist 26) logs which precondition. Closes STORE-005 + proves the freeze fix (PR #60) in one pass.
2. **STORE-003 Android bg-location Play Console declaration** — the 2–4 WEEK longest pole. Code done; remaining = EN+SL screenshots of the prominent-disclosure screen, demo video, Play Console declaration submission (mostly founder-side; declaration copy can be prepped).
3. **Wave pill 5-min TTL** — HIGH (Cloud Functions + prod deploy, founder approval). Add `sentAt` to both FCM payloads (matches + proximity), client validates 5 min, fall back to full window when absent.
4. **LEGAL-001 DPIA false claims**, **LEGAL-004 weekend timezone (HIGH)** — remaining launch gates.

## Session State — 2026-07-17 (Session 48)
- Active Task: Root-caused and fixed the 1.0.0+23 iOS freeze. Three follow-ups open.
- Environment: local + GitHub. No production mutation this session.
- System Status: `main` @ `38be73b`, clean tree, no open PRs. PRs #56 and #57 merged.
  `pubspec.yaml` is still `1.0.0+23` — **build 24 does not exist**.

## ROOT CAUSE FOUND (proven, not inferred)

The app was killed by its own crash reporter. Symbolicated device stack:

    Crashed: com.apple.main-thread
    FIRCLSProcessRecordAllThreads <- FIRCLSHandler
    <- FIRCLSExceptionRecordOnDemand
    <- -[FLTFirebaseCrashlyticsPlugin recordError:withMethodCallResult:]

Chain: `maps.trembledating.com` unresolvable offline → every vector tile throws
continuously → `CrashFilter` missed them **in release only** (it matched
`vector_map_tiles`, but AOT strips package URIs; real frames are
`tile_loader.dart`, `vector_tile_loading_cache.dart`, `caches_tile_provider.dart`,
`isolate_executor.dart`, `concurrency_executor.dart`, `pool_executor.dart`) →
each hit `recordFlutterFatalError` on the main thread → Crashlytics walks every
thread per report (dozens of DartWorkers + ~15 gRPC threads) → main thread
stalls → 2s AppHang → stack overflow inside the reporter.

Explains: the ~70KB/5s firelog uploads from launch, the os_log/syslog frames at
the stack base, and Sentry TREMBLE-FUNCTIONS-Q + -S.

Why it survived review: the old `crash_filter_test.dart` asserted an *assumed*
AOT stack (`future_tile_provider.dart`) that happened to match, so it passed
while production burned. Lesson: assert against real device frames.

## Merged this session

- **PR #57** `fix/crash-reporter-storm` — the root-cause fix. CrashFilter matches
  real AOT frames + network failures (tile pipeline only); new
  `CrashReportThrottle` caps every reporting path at 8/min; `recordFlutterError`
  not `recordFlutterFatalError`; suppressed-path `presentError` debug-only;
  MapController guarded via `onMapReady`. 343/343 tests, analyzer clean.
- **PR #56** `fix/ble-scan-write-storm` — `ScanCycleDedupe`: one `proximity_events`
  write per device per scan. `FlutterBluePlus.scanResults` re-emits the cumulative
  list per advertisement packet, so writes were unbounded. NOTE: this was NOT the
  freeze cause (my hypothesis was wrong), but it is a real defect — the monthly
  recap's near-miss count (`notifications.functions.ts:50` `count()` over
  `proximity_events`) was inflated by orders of magnitude. Also fixed
  `ios/Profile.xcconfig` (broken since April; Profile builds were impossible).

## OPEN — next session

1. **Map offline UX** — map still surfaces a raw
   `ClientException with SocketException: Failed host lookup:
   'maps.trembledating.com'` in airplane mode. No longer crashes; still ugly.
   Needs a real offline/error state.
2. **Wave pill 5-min TTL** — `wave_pill_service.dart:62`
   `defaultAutoDismissAfter = Duration(minutes: 3)`, a blind timer. Requirement:
   5 minutes validated against the wave's `createdAt`, so a pill surfaced late
   (or after resume) expires correctly rather than getting a fresh 3 min.
3. **Build 24 + device verification** — bump `pubspec.yaml` to `1.0.0+24`, build
   with `--dart-define-from-file=.env.prod.json` (MANDATORY), upload via
   `xcrun altool`. Then verify: (a) airplane mode on map no longer hangs,
   (b) two-phone proximity freeze is gone, (c) Wave Back via iOS notification action.
4. **Optional but high value** — wire `sentry-cli upload-dif` into the release so
   crashes symbolicate. This session cost ~5h because they didn't.

## Fonts — DONE, do not re-do

ADR-008 / PR #54 bundled all 44 variants with `allowRuntimeFetching = false`
(`main.dart:52`). The Sentry gstatic font error is `release: 1.0.0+22`, Android
OnePlus8Pro — it predates the fix. Verified 2026-07-17.

## Session State — 2026-07-16 09:32 CEST (Session 47)
- Active Task: Consolidate verified repair lanes and establish a truthful, clean launch baseline
- Environment: Local/GitHub release management; no additional production mutation
- Modified Files:
    - `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`
    - `tasks/blockers.md`, `tasks/context.md`, `tasks/plan.md`, `tasks/todo.md`
- Open Problems:
    - Production APNs credentials still require Firebase Console/Apple Developer inspection and a successful build-22 physical-iPhone foreground/background/killed plus explicit Wave Back test.
    - DPIA reconciliation, Weekend Getaway timezone/ToS alignment, `/sl/tos`, `/dsa-contact`, and App Store/Play Console configuration remain open release gates.
    - Runtime values printed into a local authenticated transcript are a security-hygiene follow-up, not evidence of public/source-control exposure and not an App Store submission blocker.
- System Status: PRs #48, #49, and #50 are merged through protected `main` with CI green. The signed, App Store-validated build-22 IPA is preserved under ignored `release-symbols/`; the repository has one clean worktree and no retained topic branches.

## Session Handoff
- Completed:
    - Merged the canonical identity, reliable notification delivery, retry/deduplication, and explicit iOS notification-action repair as PR #48 (`eef99c0`).
    - Merged the permanent 15-case Firestore emulator regression suite for production FCM-token recovery as PR #49 (`1cf5446`).
    - Verified 293 Flutter tests, Flutter analyzer, 149 Functions tests, backend lint/build, security gates, and flavored dev APK builds through local hooks and protected CI.
    - Preserved production IPA `1.0.0+22` outside disposable worktrees and verified its SHA-256 locally (`e8ba81e7c136…`).
    - Reconciled stale Apple membership, RevenueCat, App Check, Privacy Policy, blocker, roadmap, and checklist records with verified repository/live evidence.
    - Reclassified local transcript exposure accurately: rotate genuine server credentials as prudent hygiene; do not treat public SDK identifiers as secrets or block submission without evidence of external exposure.
    - Removed a stale focused Jest runner from the merged iOS worktree after it had consumed a CPU core for nearly ten hours; a clean Flutter build cache restored deterministic hook completion.
- Completed the launch-state reconciliation as PR #50 and removed all merged worktrees plus local/remote topic branches.
- In Progress: None.
- Blocked: None for repository cleanup.
- Next Action: Start the dedicated APNs credential/device-verification lane from clean `main`, then complete legal and store-console gates as separate scoped work.

## Session State — 2026-07-16 00:17 CEST (Session 46)
- Active Task: Repair production CROSSING_PATHS/INCOMING_WAVE identity, delivery reliability, and explicit iOS Wave action handling
- Environment: Production (`am---dating-app`) + isolated branch `fix/crossing-paths-ios-delivery`
- Modified Files:
    - Production source commit `6cbec74` in `/Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app-crossing-paths-ios-delivery`
    - `tasks/context.md` (this handoff; preserves the existing uncommitted Session 45 handoff)
    - `tasks/blockers.md` (BLOCKER-STORE-005 APNs credential/device gate)
- Open Problems:
    - FOLLOWUP-SEC-002: Firebase CLI inherited a global `DEBUG` variable and printed runtime configuration into a local authenticated tool transcript. No value entered source control or a public channel. Rotate genuine server secrets as a separate hygiene lane; this is not an App Store submission blocker.
    - Firebase/Apple console access is still required to inspect or replace the APNs credential stored for Firebase iOS app `1:343655004163:ios:5eea92b9656fc3b8fc3636` and verify a controlled production iOS send. The CLI exposes app registration metadata but not the stored APNs Key ID/certificate state.
    - Build 22 must be installed on a physical iPhone to verify background/killed notification display and the real `UNNotificationResponse.actionIdentifier` Wave Back path exactly once.
    - App Store Connect upload/store-side product configuration remains outside this code/deploy lane.
- System Status: `scanProximityPairs` and `onWaveCreated` deployed successfully to production in `europe-west1`; build 22 App Store IPA exported successfully; code, tests, analyzer, backend lint/build, Android dev build, and iOS archive/export are green.

## Session Handoff
- Completed:
    - Replaced legacy notification identity reads with canonical `name`, numeric `age`, `birthDate` fallback, and first `photoUrls` entry. New tests use neutral `User Alpha` / `User Beta` fixtures; no fake production accounts or data were created.
    - Made `INCOMING_WAVE` OS-visible, added bounded retry with processing/delivered Redis state, inspected all mutual-delivery results, and added privacy-safe structured delivery logging.
    - Removed receipt-triggered reciprocal Wave creation. Only a real iOS `WAVE_BACK_ACTION` notification response can invoke the existing callable `sendWave` path; cold-start actions are queued, acknowledged, and deduplicated.
    - Consolidated notification initialization/listener ownership in the router and removed HomeScreen duplication.
    - Deployed only `scanProximityPairs` and `onWaveCreated` to production `am---dating-app`; both updates completed successfully and are active v2 Node 22 Functions in `europe-west1`.
    - Verified Functions build/lint and all 149 tests; Flutter analyzer clean and all 293 tests; flavored dev APK build; signed production build-22 archive and App Store IPA export (`tremble.dating.app`, `1.0.0+22`).
    - Fixed the repository pre-commit hook's Git-environment leak so Flutter SDK version detection works inside hooks. The hook independently repeated format/analyze/293 Flutter tests/backend lint/build/149 tests before commit `6cbec74`.
- In Progress: APNs credential inspection/replacement and controlled physical-iPhone verification. Genuine server-secret rotation remains a separate security-hygiene follow-up.
- Blocked: Firebase Cloud Messaging and Apple Developer credential screens are not available through the authenticated CLI or current in-app browser session. No post-deploy delivery attempt has occurred yet, so the prior APNs authentication failure cannot be declared resolved.
- Next Action:
    1. Open Firebase Console → `am---dating-app` → Project settings → Cloud Messaging → Apple app `…5eea92…`; record credential type, Key ID, Team ID, and certificate expiry if applicable.
    2. Verify the Key ID under Apple Team `LB6LS532CV`; upload/replace the valid APNs `.p8` if missing/revoked/wrong, retaining the prior key until a send succeeds.
    3. Install build 22 on a physical iPhone and run the approved foreground/background/killed + explicit Wave Back procedure with dedicated production test accounts.
    4. After a successful controlled send, upload the preserved build-22 IPA to App Store Connect and complete the remaining store-side product configuration.
    5. Execute FOLLOWUP-SEC-002 as a separate approved production-configuration hygiene lane; revoke old server credentials only after each replacement works.

## Session State — 2026-07-15 19:52 CEST (Session 45)
- Active Task: Restore production FCM token persistence for CROSSING_PATHS delivery
- Environment: Production (`am---dating-app`) + isolated local branch `fix/session44-fcm-rules-recovery`
- Modified Files:
    - `tasks/context.md` (session handoff)
    - `firestore_rules_tests/` in sibling worktree (staged; commit hook blocked by local Flutter SDK resolution)
- Open Problems:
    - Scheduled `scanProximityPairs` still does not forward `sexualOrientationConsent` into `calculateCompatibilityScore`; complete this as a separate GDPR/scanner lane after the controlled device test.
    - Scanner exit observability and the unrelated `updateProfile` HTTP 400 reproduction remain open.
- System Status: Production Firestore release now points to token-only recovery ruleset `projects/am---dating-app/rulesets/dabebbe6-db3e-45a8-9e44-36e6cafc1702` with locally verified SHA-256 prefix `7fe210212350…`.

## Session Handoff
- Completed:
    - Rejected the broad affected-key production candidate because it would have reopened arbitrary and consent-field mutations on legacy profiles.
    - Added a byte-pinned production baseline, a narrowly scoped `fcmToken`-only candidate, and a permanent Node Firestore emulator suite in the isolated worktree.
    - Proved the stale baseline failure RED and the candidate/local core behavior GREEN; emulator suite passes 15/15, including owner/auth boundaries, type/size limits, protected fields, deletion, and combined-write denials.
    - Security review returned GO with no findings.
    - Verified `flutter analyze` clean, Flutter tests 281/281, Cloud Functions tests 134/134, Android dev APK build successful, and npm audit for the new rules package found zero vulnerabilities.
    - Created immutable production ruleset `dabebbe6-db3e-45a8-9e44-36e6cafc1702`, repointed only `cloud.firestore`, and verified the active release and fetched source hash. Previous ruleset `4d10e919-6ded-4b35-9255-1ad5e336edeb` remains the rollback target.
- In Progress: Controlled build-21 device verification by Aleksandar and Martin.
- Blocked: None for the matching test. Local commit is blocked by the pre-commit environment resolving Flutter as `0.0.0-unknown`, despite direct analyzer/test/build commands passing with Flutter 3.41.4.
- Next Action:
    1. Force-close and reopen build 21 on both Android and iOS, sign in, and reach the dashboard so `NotificationService.saveToken()` runs.
    2. Confirm both production user documents gain a string `fcmToken`.
    3. With the earlier 30-minute cooldown expired, activate radar/proximity on both devices and wait for the next scheduled scan; verify two visible `notification_sent` events and the CROSSING_PATHS pill/notification on both devices.
    4. After Martin's test, implement the separate consent-pass-through and scanner-observability lane.

## Session State — 2026-07-15 17:32 CEST (Session 44)
- Active Task: Diagnose production proximity pair detected but no CROSSING_PATHS match surfaced on either device
- Environment: Production read-only investigation (`am---dating-app`) + local `main`
- Modified Files:
    - `tasks/context.md` (session handoff only)
- Open Problems:
    - Production Firestore is still running ruleset `projects/am---dating-app/rulesets/4d10e919-6ded-4b35-9255-1ad5e336edeb`, created `2026-05-30T21:00:00Z`. Its user-update validation requires `lookingFor` to be a string and validates the full merged document, while current onboarding stores `lookingFor` as a list. This rejects otherwise isolated client writes such as `{fcmToken: ...}`.
    - Both newly registered production user documents lack `fcmToken`; `scanProximityPairs` silently returns `skipped: "no_token"` for both recipients, so no CROSSING_PATHS notification/pill is delivered.
    - `scanProximityPairs` does not forward `sexualOrientationConsent` into `calculateCompatibilityScore`; the LEGAL-003 bilateral `lookingFor` consent gate is therefore skipped in scheduled scans. This did not cause this pair's failure but is a GDPR/matching consistency defect.
    - Two production `updateProfile` calls returned HTTP 400. Auth and App Check were valid, but the function does not log the Zod/consent error and the release client suppresses the exception outside debug mode, so the exact offending payload field remains unknown.
    - Scanner completion logs expose only aggregate `pairsEvaluated` / `pairsNotified`; cooldown, `no_token`, filter, score, throttle, and send-error exits are not summarized, making successful matching look like rejection.
- System Status: Root cause confirmed. No source, Firebase, Redis, or production data changes performed. Exact profile replay scored `0.76` against the production scanner payload, above the normal `0.70` threshold.

## Session Handoff
- Completed:
    - Traced the scheduled scanner from geohash grouping through distance, Redis cooldown, block/flag, mutual gender, mutual age, nicotine, compatibility, encounter creation, and FCM delivery.
    - Confirmed the first relevant scan at `2026-07-15T14:38:02Z` evaluated one pair, wrote the supplied `proximity_events` document, and completed with `pairsNotified: 0`. Because the event write occurs only after the `0.70` threshold gate, the compatibility path succeeded.
    - Replayed the supplied Aleksandar/Martin profile attributes through `calculateCompatibilityScore`; score was `0.76` both with the scanner's current payload and with bilateral orientation consent included.
    - Confirmed the later `pairsEvaluated: 1, pairsNotified: 0` scans were inside the pair's 30-minute Redis cooldown. `pairsEvaluated` increments before the cooldown check, so these entries do not indicate repeated compatibility failures.
    - Confirmed both supplied user documents have no `fcmToken`, and `sendCrossingPaths()` returns `no_token` without a structured log entry.
    - Read the active production Firestore rules through the Firebase Rules API. The deployed May 30 ruleset is stale and rejects token-only updates on current list-shaped `lookingFor` documents.
    - Confirmed local `firestore.rules` already contains affected-field-only update validation and list-shaped `lookingFor` support, but the full local-vs-production rules diff must be audited before any production deploy; do not blindly deploy the entire file.
    - Confirmed deployed `updateProfile` is active at revision `updateprofile-00019-diz`, updated `2026-07-14T22:25:25Z`, with Firebase Functions hash `3a5c73e17c31a5fb094f0a0662d04dfdf8455a57`.
- Decisions:
    - Treat the incident primarily as a stale production Firestore-rules / FCM-token persistence failure, not a compatibility-score regression.
    - Keep remediation in separate lanes: (1) production rules recovery and device verification; (2) GDPR consent pass-through plus scanner observability; (3) targeted `updateProfile` 400 reproduction. Do not combine unrelated fixes in one commit or deploy.
- In Progress: None; investigation is complete and ready for a fresh implementation session.
- Blocked:
    - Any production Firestore rules deployment is HIGH risk and requires founder approval after an explicit active-prod-vs-local diff review and emulator verification.
    - Exact `updateProfile` 400 diagnosis requires the client-side `FirebaseFunctionsException.code/message/details` or a controlled reproduction with redacted structured validation logging.
- Next Action:
    1. Read `tasks/context.md`, `tasks/blockers.md`, `tasks/lessons.md`, `tasks/plan.md`, `firestore.rules`, `lib/src/core/notification_service.dart`, `lib/src/features/dashboard/presentation/home_screen.dart`, `functions/src/modules/proximity/proximity.functions.ts`, and `functions/src/modules/compatibility/compatibility_calculator.ts`.
    2. Prepare a 5-step HIGH-risk plan that fetches the active prod rules, audits the complete diff against local, adds/executes Firestore emulator regression tests for token-only updates on current onboarding documents, and stops for founder approval before deployment.
    3. After approved rules deployment, force-close/reopen both apps, confirm each `users/{uid}` document gains `fcmToken`, wait for the 30-minute pair cooldown (or obtain explicit approval before clearing only that pair key), then verify a new encounter emits two visible `notification_sent` events and `pairsNotified: 2`.
    4. In a separate TDD change, forward `sexualOrientationConsent` for both users into scheduled compatibility scoring and add privacy-safe per-exit counters/logs, especially `cooldown`, `no_token`, `below_threshold`, `throttled`, and `send_error`.
    5. Reproduce one `updateProfile` 400 with the exact outgoing payload and capture the typed callable error before proposing a schema or client fix.

## Session State — 2026-07-15 14:40 CEST (Session 43)
- Active Task: Sentry Issue Audit and Resolutions (5 bugs fixed)
- Environment: Dev/local Flutter
- Modified Files:
    - `lib/src/features/auth/data/auth_repository.dart`
    - `lib/src/features/auth/presentation/login_screen.dart`
    - `lib/src/core/ble_restore_service.dart`
    - `lib/src/core/map_provider.dart`
    - `lib/src/features/gym/application/gym_mode_controller.dart`
    - `lib/src/features/dashboard/presentation/home_screen.dart`
    - `tasks/lessons.md`
- Open Problems: None from this audit.
- System Status: `flutter analyze` clean (0 issues). `flutter test --dart-define-from-file=.env.json` 281/281 passing.

## Session Handoff
- Completed:
    - Fixed Firebase Permission Denied error (Issue 1) by removing `isPremium` and `isAdmin` from `AuthRepository.registerWithEmail` to comply with `firestore.rules` `validCreateKeys`, and used `.set(..., SetOptions(merge: true))` for `updateSelectedGyms`.
    - Added Rule #38 to `tasks/lessons.md` documenting the client-side restricted fields limitation.
    - Fixed Android `StackOverflowError` in `onRequestPermissionsResult` (Issue 2) by adding boolean locks (`_isRequestingPermission`) around `Geolocator.requestPermission()` in `gym_mode_controller.dart` and `home_screen.dart`.
    - Fixed `Null check operator used on a null value` (Issue 3) in `login_screen.dart` by changing `if (context.mounted)` to `if (mounted)` inside the `State` class.
    - Fixed `MissingPluginException` for `app.tremble/ble/restore/events` (Issue 4) by wrapping `EventChannel` initialization with `Platform.isIOS` in `ble_restore_service.dart`.
    - Fixed `ClientException` from unhandled HTTP fetch of PMTiles (Issue 5) by introducing `SafePmTilesVectorTileProvider` in `map_provider.dart` to return an empty tile instead of crashing the app.
- In Progress: None.
- Blocked: None.
- Next Action: Review and commit changes.
- Note on session hygiene: `git reset --hard origin/main` was used to drop a redundant local merge commit; it also wiped uncommitted on-disk changes to `tasks/TREMBLE_IMPLEMENTATION_PLAN.md` (recovered by user via IDE), `coverage/lcov.info` (regeneratable), and `.claude/settings.local.json`. Lesson: use `git reset --keep` for future divergent-merge cleanups.

## Session State — 2026-07-06 22:30 CEST (Session 41)
- Active Task: Project Documentation & Compliance Cleanup
- Environment: Dev/local
- Modified Files:
    - `tasks/blockers.md`
    - `tasks/todo.md`
    - `tasks/lessons.md`
    - `README.md`
    - `BOOTSTRAP.md`
    - `Tremble MPC Workflow.md` [DELETED]
    - `STRATEGY_CLAIMS.md` [DELETED]
    - `CLAUDE.md` [DELETED]
    - `tasks/decisions/ADR-003-brand-alignment.md` [DELETED]
    - `tasks/decisions/ADR-007-motion-and-emotional-arc.md` [DELETED]
- Open Problems:
    - Transitioning to compliance-driven development to address critical GDPR, App Store, and Play Store blockers identified in the July 2026 report.
- System Status: Documentation synced with Compliance Report.

## Session Handoff
- Completed:
    - Deleted outdated files: `Tremble MPC Workflow.md`, `STRATEGY_CLAIMS.md`, `CLAUDE.md`, `ADR-003-brand-alignment.md`, and `ADR-007-motion-and-emotional-arc.md`.
    - Updated `tasks/blockers.md` to move old blockers to archive and insert critical store and legal blockers from the compliance report.
    - Updated `tasks/todo.md` to map directly to the Compliance Launch Checklist.
    - Added new permanent rules to `tasks/lessons.md` (Rules #75 to #78) regarding GDPR consent, Play Console requirements, Paywall accuracy, and avoiding AI hallucinations in documentation.
    - Updated `README.md` and `BOOTSTRAP.md` to refer to the new compliance phase and `AGENTS.md` as the single source of truth.
- In Progress: None.
- Blocked: None.
- Next Action: Proceed with implementing fixes for critical blockers (e.g., iOS Privacy Manifest, Android location declarations, GDPR consent logic).

## Session State — 2026-07-05 10:40 CEST (Session 40)
- Active Task: Fix main branch CI failures and refine compatibility scoring logic
- Environment: Dev/local
- Modified Files:
    - `.github/workflows/ci.yml`
    - `functions/jest.config.js`
    - `functions/jest.setup.js` [NEW]
    - `functions/src/__tests__/auth.test.ts`
    - `functions/src/__tests__/compatibility_calculator.test.ts` [NEW]
    - `functions/src/__tests__/uploads_proximity.test.ts`
    - `functions/src/__tests__/users.test.ts`
    - `functions/src/modules/compatibility/compatibility_calculator.ts`
    - `functions/src/modules/proximity/proximity.functions.ts`
    - `test/features/subscriptions/revenuecat_subscription_test.dart`
- Open Problems:
    - Existing blockers remain (B005 iOS provisioning, B006 photo upload E2E unverified).
- System Status: `npm run lint` clean. `npm test` 58/58 passing. `flutter analyze` clean. `flutter test` 200/200 passing. Code pushed to `fix/ci-tests-and-compatibility`.

## Session Handoff
- Completed:
    - Fixed CI backend test runner by injecting `TREMBLE_ENV: test` globally via Github Actions and locally via `jest.setup.js`.
    - Fixed empty API key test assertion in `revenuecat_subscription_test.dart` to check for `REVENUECAT_APPLE_API_KEY`.
    - Updated `users.test.ts` and `auth.test.ts` inputs to use array `["vaping"]` for `nicotineUse` to comply with the updated schema, updating expected payloads and mocked functions.
    - Updated `passesHardFilters` to drop nicotine checks as they are now fully handled by the `nicotineCompatible` pre-filter before scoring.
    - Refined religion and ethnicity calculations in `calculateLifestyleScore` to properly use and validate directional preferences (`prefer_same` instead of deprecated `same_only`).
    - Added regression tests in `compatibility_calculator.test.ts` proving proper score retention when prefer_same directions do or do not match.
    - Corrected broken test mock data (`uploads_proximity.test.ts`) that passed objects instead of strings for hobbies array, ensuring accurate category scoring.
    - Verified all test suites in Flutter and Cloud Functions are green.
    - Committed changes and pushed to `fix/ci-tests-and-compatibility` remote branch.
- In Progress: None.
- Blocked: None.
- Next Action: Review PR.

## Session State — 2026-07-02 00:51 CEST (Session 39)
- Active Task: Wire PlatformDispatcher.instance.onError + Isolate.current.addErrorListener for async crash reporting
- Environment: Dev (local Flutter only)
- Modified Files:
    - `lib/main.dart`
- Open Problems:
    - Existing blockers remain (B005 iOS provisioning, B006 photo upload E2E unverified).
- System Status: `flutter analyze` clean (0 issues). `flutter test` 200/200 passing.

## Session Handoff
- Completed:
    - Diagnosed blind spot: `FlutterError.onError` only catches synchronous Flutter framework errors. Async errors (e.g. `StateError: Cannot use ref after the widget was disposed` from background callbacks) escape all zones and were invisible to both Sentry and Crashlytics in prod.
    - Added `PlatformDispatcher.instance.onError` handler (main.dart:94–98) forwarding to Crashlytics + Sentry.
    - Added `Isolate.current.addErrorListener` handler (main.dart:102–116) forwarding to Crashlytics + Sentry for low-level isolate crashes.
    - Added imports: `dart:isolate`, `dart:ui show PlatformDispatcher`.
    - Verified `SENTRY_DSN` dart-define key matches in both `.env.json` and `.env.prod.json` — same key name `SENTRY_DSN`, read via `const String.fromEnvironment('SENTRY_DSN')` at main.dart:129.
    - Verified `flutter analyze --no-fatal-infos`: No issues found.
    - Verified `flutter test --dart-define-from-file=.env.json`: 200/200 tests pass.
- In Progress: None.
- Blocked: None.
- Next Action: Commit `lib/main.dart`, then rebuild prod IPA with `--dart-define-from-file=.env.prod.json` and confirm Sentry tremble-app project receives events from background walk tests.

## Session State — 2026-06-30 00:07 CEST (Session 38)
- Active Task: Fix updateProfile HTTP 400 for phoneNumber/gymNotificationsEnabled
- Environment: Dev (tremble-dev)
- Modified Files: None (schema already correct — deploy gap only)
- Open Problems:
    - Existing blockers remain (B005 iOS provisioning, B006 photo upload E2E unverified).
- System Status: `npx tsc --noEmit` clean. `npm test` 52/52 passing. `updateProfile(europe-west1)` deployed to tremble-dev.

## Session Handoff
- Completed:
    - Diagnosed updateProfile HTTP 400 "Unrecognized key(s): phoneNumber, gymNotificationsEnabled" as a deploy gap — not a schema bug.
    - Verified `users.schema.ts` already contains `phoneNumber: z.string().max(30).nullish()` (line 90) and `gymNotificationsEnabled: z.boolean().nullish()` (line 89).
    - Confirmed compiled `lib/modules/users/users.schema.js` also contains both fields.
    - Confirmed ONE input schema path: `users.functions.ts:33` → `updateProfileSchema` from `users.schema.ts:23` with `.strict()` at line 92. No downstream Firestore write validator.
    - Verified `npx tsc --noEmit`: clean.
    - Verified `npm test -- --runInBand`: 52/52 tests pass (7 suites).
    - Deployed: `firebase deploy --only functions:updateProfile --project tremble-dev` → `✔ functions[updateProfile(europe-west1)] Successful update operation.` → `✔ Deploy complete!`
- In Progress: None.
- Blocked: None.
- Next Action: Test from device to confirm updateProfile now accepts phoneNumber and gymNotificationsEnabled payloads without 400.

## Session State — 2026-06-28 19:40 CEST (Session 37)
- Active Task: Resolve main.dart analyzer unused import & verify formatting
- Environment: Dev
- Modified Files:
    - `lib/main.dart`
- Open Problems:
    - Existing blockers remain (B005 iOS provisioning, B006 photo upload E2E unverified).
- System Status: `dart format` clean. `flutter analyze` clean (0 warnings).

## Session Handoff
- Completed:
    - Removed unused `package:google_fonts/google_fonts.dart` import from `lib/main.dart` which was causing the pre-commit analyze check to fail.
    - Verified all 212 files are formatted via `dart format .`.
    - Confirmed `flutter analyze --no-fatal-infos` passes successfully with zero issues.
- In Progress: None.
- Blocked: None.
- Next Action: Ready to commit.

## Session State — 2026-06-22 12:26 CEST
- Active Task: H4 — Implement iOS BLE Background State Restoration
- Environment: Dev/local Flutter only, `main`
- Modified Files:
    - `ios/Runner/BleRestoreBridge.swift` [NEW]
    - `ios/Runner/AppDelegate.swift`
    - `ios/Runner.xcodeproj/project.pbxproj`
    - `lib/src/core/ble_restore_service.dart` [NEW]
    - `lib/src/features/dashboard/presentation/home_screen.dart`
    - `lib/src/core/notification_service.dart`
- Open Problems:
    - Existing blockers remain: B005 iOS provisioning, B006 photo upload E2E unverified.
- System Status: Build passing. `flutter analyze` clean. All 197 Flutter tests passing. Cloud Functions `tsc` clean.

## Session Handoff
- Completed:
    - Implemented `BleRestoreBridge.swift` to initialize a background `CBCentralManager` with restoration ID `app.tremble.ble.central`.
    - Wired iOS EventChannel and MethodChannel in `AppDelegate.swift`.
    - Added `BleRestoreBridge.swift` to Xcode `project.pbxproj`.
    - Created `BleRestoreService` in Dart to listen to restoration events and write `rssi` and `uuid` to `proximity_events` in Firestore.
    - Updated `HomeScreen.initState` to initialize `BleRestoreService`.
    - Updated `notification_service.dart` to handle `CROSSING_PATHS` and `SECOND_ENCOUNTER` silent push pings by keeping `proximity/{uid}.updatedAt` fresh.
    - Fixed a test failure by making `FirebaseAuth.instance` and `FirebaseFirestore.instance` initialization lazy inside `BleRestoreService._onNativeEvent`.
- In Progress: None.
- Blocked: None.
- Next Action: Proceed with other tasks in the roadmap.

## Session State — 2026-06-22 08:40 CEST
- Active Task: Add ITMS-90683 NSUsageDescription lesson (build 5 post-mortem)
- Environment: Dev/local Flutter only, `main`
- Modified Files:
    - `tasks/lessons.md`
- Open Problems:
    - Existing blockers remain: B005 iOS provisioning, B006 photo upload E2E unverified.
- System Status: Build passing.
## Session Handoff
- Completed:
    - Added the `ITMS-90683: Missing NSUsageDescription keys` lesson under a new `## iOS Build & App Store` section in `tasks/lessons.md`.
    - Committed the changes with message: `"docs: add ITMS-90683 NSUsageDescription lesson (build 5 post-mortem)"`.
- In Progress: None.
- Blocked: None.
- Next Action: Proceed with other tasks in the roadmap.

## Session State — 2026-06-21 23:41 CEST
- Active Task: H9 — Places API uses bare http.* on iOS
- Environment: Dev/local Flutter only, `main`
- Modified Files:
    - `lib/src/core/places_service.dart`
    - `test/core/places_service_cupertino_client_test.dart` [NEW]
- Open Problems:
    - Existing blockers remain: B005 iOS provisioning, B006 photo upload E2E unverified.
    - Physical device E2E for Places TLS still gated on B005.
    - No deploy performed.
- System Status: Scoped analyze (places_service.dart): No issues. Full suite: running.
 
## Session Handoff
- Completed:
    - Added `_buildHttpClient()` top-level helper: returns `CupertinoClient.fromSessionConfiguration(config)` on iOS, `http.Client()` elsewhere.
    - Added `final http.Client _client = _buildHttpClient()` instance field on `PlacesService`.
    - Replaced all 3 bare calls: `http.post(...)` → `_client.post(...)` in `autocomplete()` and `gymAutocomplete()`; `http.get(...)` → `_client.get(...)` in `getPlaceDetails()`.
    - Added `void dispose() => _client.close()` on `PlacesService`.
    - Wired `ref.onDispose(service.dispose)` in `placesServiceProvider` (was a one-liner, now properly cleans up).
    - Added `dart:io` Platform and `cupertino_http` imports.
    - Added 13 regression tests in `test/core/places_service_cupertino_client_test.dart` — 13/13 GREEN.
    - `flutter analyze lib/src/core/places_service.dart`: No issues.
    - Full flutter test: running (pending).
- In Progress: None.
- Blocked: B005. Physical device Places API TLS verification pending.
- Next Action: Full test suite result. If clean, commit this batch. Then H7 — matchesStreamProvider.autoDispose.autoDispose.

## Session State — 2026-06-21 23:29 CEST

- Active Task: H6 — profileStatusProvider non-autoDispose leak fix
- Environment: Dev/local Flutter only, `main`
- Modified Files:
    - `lib/src/features/auth/data/auth_repository.dart` (line 731 — one-word change)
    - `test/features/auth/profile_status_provider_auto_dispose_test.dart` [NEW]
- Open Problems:
    - Existing blockers remain: B005 iOS provisioning, B006 photo upload E2E unverified.
    - Pre-existing `home_screen.dart` analyzer error (`_MatchNotificationPillOverlay` creation_with_non_type + 2 warnings) in dirty worktree — NOT introduced by this session.
    - No deploy performed.
- System Status: Scoped analyze (changed files only): No issues. Full-suite flutter test: running.

## Session Handoff
- Completed:
    - Changed `StreamProvider<ProfileStatus>` → `StreamProvider.autoDispose<ProfileStatus>` at `auth_repository.dart:731`.
    - Audited all consumers: `router.dart` uses `_ref.listen` (keeps alive via router's own Provider lifetime) and `_ref.read` (snapshot read, not a subscription). `profileExistsProvider` uses `ref.watch(profileStatusProvider.future)` — deprecated, no keepAlive. No consumer requires persistent subscription beyond the router.
    - Added 5 regression tests in `test/features/auth/profile_status_provider_auto_dispose_test.dart` (all GREEN).
    - `flutter analyze` on changed files: No issues.
    - `flutter test` full suite: pending (running).
- In Progress: None.
- Blocked: B005 iOS provisioning. Pre-existing home_screen.dart errors are unrelated to this session.
- Next Action: H7 — matchesStreamProvider non-autoDispose (same pattern, match_repository.dart:342).

## Session State — 2026-06-21 23:26 CEST

- Active Task: H2 — Location "Always" tier never requested
- Environment: Dev/local Flutter only, `main`
- Modified Files:
    - `lib/src/core/consent_service.dart`
    - `test/core/consent_service_location_always_test.dart` [NEW]
- Open Problems:
    - Existing blockers remain: B005 iOS provisioning, B006 photo upload E2E unverified on physical device.
    - The `NSLocationAlwaysAndWhenInUseUsageDescription` key in Info.plist must be verified — if missing, iOS will silently drop the second permission dialog (FOUNDER ACTION: check Info.plist).
    - No deploy performed.
- System Status: flutter analyze clean. 179/179 tests passing (8 new H2 regression tests). Build untested (not run this session).

## Session Handoff
- Completed:
    - Diagnosed: `ConsentService.requestLocation()` was a one-liner calling only `Permission.locationWhenInUse.request()`. Background BLE geohash updates on iOS require the "Always" location tier, which must be explicitly requested at runtime in a separate second call.
    - Fixed: Expanded `requestLocation()` to an async two-step escalation — (1) `locationWhenInUse.request()`, (2) if `.isGranted` AND `Platform.isIOS`, then `locationAlways.request()`. Android is unaffected (uses manifest-level `ACCESS_BACKGROUND_LOCATION`).
    - Added `dart:io` Platform import; kept all existing imports and methods untouched.
    - Added 8 regression tests in `test/core/consent_service_location_always_test.dart` (source-text contract pins).
    - Verified `flutter analyze --no-fatal-infos`: No issues found.
    - Verified `flutter test --dart-define-from-file=.env.json`: 179/179 all pass.
- In Progress: None.
- Blocked: Physical device verification gated on B005. `NSLocationAlwaysAndWhenInUseUsageDescription` in Info.plist needs FOUNDER verification.
- Next Action: FOUNDER — verify `NSLocationAlwaysAndWhenInUseUsageDescription` is present in `ios/Runner/Info.plist`. Without it, the second iOS dialog will not appear even though the Dart call is now in place.

## Session State — 2026-06-18 00:04 CEST

- Active Task: Pin App Check debug token in main.dart for dev iOS flavor
- Environment: Dev/local Flutter only, `main`
- Modified Files:
    - `lib/main.dart`
- Open Problems:
    - Existing blockers remain: B005 iOS provisioning and B006 photo upload/onboarding E2E unverified.
    - Physical device verification still gated on B005.
    - No deploy performed.
- System Status: Build passing. Flutter analyze clean. Flutter 170/170 tests passing.

## Session Handoff
- Completed:
    - Identified root cause: AppleDebugProvider() without debugToken generates a random token on every run — never matches the token registered in Firebase console, so App Check rejects all CF calls on iOS dev.
    - Fixed: Added debugToken: '26697195-D797-4FFE-ADEA-9631258A1C88' to AppleDebugProvider in main.dart line 60.
    - Prod path (AppleDeviceCheckProvider) untouched.
    - Token is dev-only and revocable — safe to commit.
    - Verified flutter analyze --no-fatal-infos: No issues.
    - Tests in progress.
- In Progress: flutter test running.
- Blocked: B005 iOS provisioning. B006 photo upload E2E on physical device.
- Next Action: Commit lib/main.dart, then run with physical iPhone to confirm App Check debug token bypass works end-to-end.

## Session State — 2026-06-17 23:16 CEST
- Active Task: Fix R2 photo upload TLS failure on iOS (SSLV3_ALERT_HANDSHAKE_FAILURE)
- Environment: Dev/local Flutter only, `main`
- Modified Files:
    - `lib/src/core/upload_service.dart`
    - `test/core/upload_service_ios_tls_test.dart` [NEW]
- Open Problems:
    - Existing blockers remain: B005 iOS provisioning and B006 photo upload/onboarding E2E unverified.
    - Physical device verification still gated on B005.
    - No deploy performed.
- System Status: Build passing. Flutter analyze clean. Flutter 170/170 tests passing.

## Session Handoff
- Completed:
    - Root cause: upload_service.dart used dart:io HttpClient for the presigned R2 PUT. dart:io uses Dart's own TLS stack which triggers SSLV3_ALERT_HANDSHAKE_FAILURE on iOS against Cloudflare R2's S3 endpoint. Android works because Android's TLS stack handles Cloudflare's cipher requirements.
    - Fix: Replaced dart:io HttpClient with package:http http.put(). package:http delegates to NSURLSession on iOS (Apple's Network.framework) which handles Cloudflare R2 TLS correctly.
    - package:http ^1.2.2 was already in pubspec.yaml — no pubspec changes needed.
    - Progress callback preserved: fires once at 100% on completion (bytes fully buffered before upload, so streaming progress was cosmetic only).
    - Added test/core/upload_service_ios_tls_test.dart with 3 regression tests pinning: (1) package:http imported, (2) HttpClient() not used, (3) http.put() used.
    - Verified flutter analyze --no-fatal-infos: No issues found.
    - Verified flutter test --dart-define-from-file=.env.json: 170/170 tests pass.
    - Added Rule #73 to tasks/lessons.md.
- In Progress: None.
- Blocked: B005 iOS provisioning. B006 photo upload E2E unverified on physical device.
- Next Action: After B005 resolves, test onboarding photo upload on physical iPhone to confirm TLS fix works end-to-end.

## Session State — 2026-06-17 23:13 CEST
- Active Task: Fix Places API radius error — cap at 50,000 m
- Environment: Dev/local Flutter only, `main`
- Modified Files:
    - `lib/src/core/places_service.dart`
    - `test/core/places_service_radius_test.dart` [NEW]
- Open Problems:
    - Existing blockers remain: B005 iOS provisioning and B006 photo upload/onboarding E2E unverified.
    - No deploy performed.
- System Status: Build passing. Flutter analyze clean. Flutter 167/167 tests passing.

## Session Handoff
- Completed:
    - Diagnosed two `'radius': 2000000.0` literals (2,000 km) in places_service.dart that exceed the Google Places API (New) hard cap of 50,000 m causing "Invalid circle.radius" 400 errors.
    - Fixed autocomplete() city-search fallback: line 122 → 50000.0.
    - Fixed gymAutocomplete() no-location fallback: line 179 → 50000.0.
    - The user-location gym path (line 173) was already 50000.0 — left unchanged.
    - Added test/core/places_service_radius_test.dart with 3 regression tests (source-text scan, cap assertion, exact-value pin).
    - Verified flutter analyze --no-fatal-infos: No issues found.
    - Verified flutter test --dart-define-from-file=.env.json: 167/167 tests pass.
- In Progress: None.
- Blocked: B005 iOS provisioning. B006 photo upload E2E unverified.
- Next Action: No further code changes needed. Deploy CF / Flutter only after explicit founder approval.

## Session State — 2026-06-17 23:10 CEST
- Active Task: CODEX audit — verify nicotineUse serialization in toApiPayload()
- Environment: Dev/local Flutter only, `main`
- Modified Files: None (no changes required — fix already applied)
- Open Problems:
    - Existing blockers remain: B005 iOS provisioning and B006 photo upload/onboarding E2E unverified.
    - APK build in progress (awaiting gradle completion).
- System Status: Build passing. Flutter analyze clean. Flutter 164/164 tests passing. Dev APK built.

## Session Handoff
- Completed:
    - CODEX prompt claimed nicotineUse sends List<String> but CF schema expects a single string.
    - Audit confirmed the previous session (2026-06-14 23:47) already resolved this: CF schemas (auth.schema.ts + users.schema.ts) were updated to accept z.union([z.array(z.string()), z.string()]) — both arrays and strings pass validation.
    - toApiPayload() at line 245 correctly sends the full List<String> for nicotineUse (multi-select preserved).
    - api_payload_contract_test.dart pins the List<String> serialization as the expected format.
    - Verified flutter test --dart-define-from-file=.env.json: 164/164 tests pass.
    - Verified flutter analyze --no-fatal-infos: No issues found.
    - Verified flutter build apk --debug --flavor dev: ✓ Built build/app/outputs/flutter-apk/app-dev-debug.apk.
- In Progress: None.
- Blocked: B005 iOS provisioning. B006 photo upload E2E unverified.
- Next Action: After build confirms green, no further changes needed for this CODEX task. Physical device E2E still gated on B005.

## Session State — 2026-06-14 23:51 CEST
- Active Task: Chunk GDPR `deleteUserAccount` block-reference cleanup batches
- Environment: Dev/local Functions only, `main`
- Modified Files:
    - `functions/src/modules/gdpr/gdpr.functions.ts`
    - `functions/src/__tests__/gdpr.test.ts`
    - `tasks/lessons.md`
    - `tasks/context.md`
- Open Problems:
    - Existing blockers remain: B005 iOS provisioning and B006 photo upload/onboarding E2E unverified.
    - Pre-existing unrelated dirty worktree changes remain in Functions, Flutter, tests, and `tasks/context.md`.
    - `tasks/plan.md` is missing, so current phase was read from project roadmap instead.
    - No deploy performed.
- System Status: Functions TypeScript compile and Jest suite passing.

## Session Handoff
- Completed:
    - Added Rule #72 to `tasks/lessons.md` documenting the Firestore 500-write cap risk for GDPR block-reference cleanup.
    - Added RED/GREEN regression coverage proving 501 users blocking the deleted UID are cleaned through two update batches of 499 and 2 writes.
    - Changed `deleteUserAccount` step 5b to split `blockersOf.docs` into 499-document chunks and commit each cleanup batch sequentially.
    - Verified RED before implementation with `npm test -- gdpr.test.ts --runInBand`.
    - Verified GREEN after implementation with `npm test -- gdpr.test.ts --runInBand`.
    - Verified `npx tsc --noEmit` exits 0 from `functions/`.
    - Verified `npm test` exits 0 from `functions/` with 39 passing tests.
- In Progress: None.
- Blocked: None for this local code change.
- Next Action: Review and commit the scoped GDPR diff when ready; do not deploy unless explicitly approved.

## Session State — 2026-06-14 23:47 CEST
- Active Task: Preserve multi-select `nicotineUse` through onboarding/profile writes
- Environment: Dev/local Functions + Flutter only, `main`
- Modified Files:
    - `functions/src/modules/users/users.schema.ts`
    - `functions/src/modules/users/users.functions.ts`
    - `functions/src/modules/auth/auth.schema.ts`
    - `functions/src/modules/auth/auth.functions.ts`
    - `functions/src/__tests__/users.test.ts`
    - `functions/src/__tests__/auth.test.ts`
    - `lib/src/features/auth/data/auth_repository.dart`
    - `test/features/auth/api_payload_contract_test.dart`
    - `test/features/auth/auth_user_wave_limit_test.dart`
    - `tasks/context.md`
- Open Problems:
    - Exact `flutter run --flavor dev --dart-define-from-file=.env.json --dart-define=FLAVOR=dev` cannot start because Flutter detects both `macos` and `chrome` and requires `-d`.
    - Firestore device verification (`cigarettes` + `vape` + `shisha` through real onboarding) was not run because no device target/deploy was available in this session.
    - Pre-existing/parallel worktree changes remain from R2 upload, contact service, gym search, and partner preference modal tasks.
    - Existing blockers remain: B005 iOS provisioning and B006 photo upload/onboarding E2E unverified.
    - No deploy to `am---dating-app`, nicotine UI, AndroidManifest.xml, Info.plist, google-services.json, Firestore rules, or Firebase config changes performed.
- System Status: Functions lint/build/tests passing, Flutter tests passing, Flutter analyze clean, dev debug APK build passing.

## Session Handoff
- Completed:
    - Updated Flutter `AuthUser.toApiPayload()` to send the full `List<String>` for `nicotineUse` instead of `nicotineUse.first`.
    - Updated Flutter `AuthUser.fromFirestore()` to parse both new array values and legacy single-string `nicotineUse` values.
    - Updated `updateProfileSchema` and actual `completeOnboardingSchema` to accept `nicotineUse` as either `string[]` or legacy `string`.
    - Normalized `nicotineUse` inside `updateProfile` and `completeOnboarding` so Firestore writes always store an array.
    - Added RED/GREEN Flutter contract coverage for full multi-select payloads and legacy Firestore string parsing.
    - Added RED/GREEN Functions schema and handler coverage proving arrays are accepted and written as arrays.
    - Verified `cd functions && npm run lint`, `npm run build`, and `npm run test` pass. Active Functions suite is now 38/38 due added tests.
    - Verified `flutter test` passes all 164 active Flutter tests.
    - Verified `flutter analyze --no-fatal-infos` reports no issues.
    - Verified `flutter build apk --debug --flavor dev --dart-define-from-file=.env.json --dart-define=FLAVOR=dev` builds `build/app/outputs/flutter-apk/app-dev-debug.apk`.
- In Progress: None.
- Blocked: Real Firestore confirmation requires a dev deploy plus mobile run with `-d <deviceId>`.
- Next Action: After explicit founder approval, deploy only the relevant dev Functions and run onboarding on a real dev target selecting Cigarettes + Vape + Shisha; confirm `users/{uid}.nicotineUse == ['cigarettes','vape','shisha']`.

## Session State — 2026-06-14 23:38 CEST
- Active Task: Route `onContactAnonymityCheck` through `TrembleApiClient`
- Environment: Dev/local Flutter only, `main`
- Modified Files:
    - `lib/src/core/contact_service.dart`
    - `test/core/contact_service_wiring_test.dart`
    - `test/features/gym/gym_search_widget_test.dart`
    - `tasks/context.md`
- Open Problems:
    - Exact `grep -rn 'httpsCallable' lib/` still reports the intentional central caller in `lib/src/core/api_client.dart:46`; `lib/src/core/contact_service.dart` has no `httpsCallable` matches.
    - Existing blockers remain: B005 iOS provisioning and B006 photo upload/onboarding E2E unverified.
    - Pre-existing local changes remain in Functions/upload/auth/gym files outside this scoped task.
    - No deploy, AndroidManifest.xml, Info.plist, google-services.json, Firestore rules, or Firebase config edits performed.
- System Status: Flutter analyze clean, full Flutter test suite passing.

## Session Handoff
- Completed:
    - Added a focused RED/GREEN regression proving `ContactService` routes `onContactAnonymityCheck` through `TrembleApiClient`.
    - Removed the raw `FirebaseFunctions.instance.httpsCallable('onContactAnonymityCheck')` path from `contact_service.dart`.
    - Preserved the 120-second callable timeout through `TrembleApiClient.call(...)`.
    - Let central Firebase Functions error mapping flow through `TrembleApiClient` and specialized the contact-check rate-limit message to `Too many contact checks. Please wait a moment.`
    - Removed one unused import from `test/features/gym/gym_search_widget_test.dart` to restore analyzer-clean status.
    - Verified `flutter analyze --no-fatal-infos` is clean.
    - Verified `flutter test --dart-define-from-file=.env.json` passes all 163 Flutter tests.
    - Verified `grep -rn 'httpsCallable' lib/src/core/contact_service.dart` returns no matches.
- In Progress: None.
- Blocked: Exact repo-wide `grep -rn 'httpsCallable' lib/` returns the central API client by design.
- Next Action: Review and commit the scoped Flutter diff when ready; do not deploy.

## Session State — 2026-06-14 23:40 CEST
- Active Task: Improve gym search error visibility for Places autocomplete failures
- Environment: Dev/local Flutter only, `main`
- Modified Files:
    - `lib/src/core/places_service.dart`
    - `lib/src/features/gym/presentation/gym_search_widget.dart`
    - `test/features/gym/gym_search_widget_test.dart`
    - `lib/src/core/contact_service.dart` (pre-existing raw-call bypass worktree change; only call-line formatting adjusted so active source guard passes)
    - `tasks/context.md`
- Open Problems:
    - Exact `flutter run --flavor dev --dart-define-from-file=.env.json --dart-define=FLAVOR=dev` still cannot start because Flutter detects both `macos` and `chrome` and requires `-d`.
    - Pre-existing/parallel worktree changes remain in R2 upload files, `partner_preference_modal.dart`, and untracked `test/core/contact_service_wiring_test.dart`.
    - Existing blockers remain: B005 iOS provisioning and B006 photo upload/onboarding E2E unverified.
    - No Places endpoint/request body, API key hardcoding, AndroidManifest.xml, Info.plist, google-services.json, Firestore rules, or deploy changes performed.
- System Status: Flutter tests passing, Flutter analyze clean, dev debug APK build passing.

## Session Handoff
- Completed:
    - Added full response-body logging for non-200 gym autocomplete responses in `PlacesService`.
    - Added debug-only 403 guidance for gym search covering `PLACES_KEY_DEV`, Android key restrictions, and Places API (New).
    - Replaced the gym autocomplete empty-key log with the explicit `PLACES_KEY_DEV` `--dart-define` guidance.
    - Added `_searchError` state to `GymSearchWidget`, reset it on new/empty searches, and set it when `_gymAutocomplete` throws.
    - Updated submitted-search snackbar copy so genuine empty results show `No gyms found nearby. Try another gym name.` and thrown search failures show `Gym search unavailable. Check connection.`
    - Added a focused widget regression proving thrown gym autocomplete failures show the unavailable snackbar instead of the empty-result snackbar.
    - Verified RED for the new widget test before production changes, then verified GREEN after the fix.
    - Verified `flutter test` passes all 163 active tests.
    - Verified `flutter analyze --no-fatal-infos` reports no issues.
    - Verified `flutter build apk --debug --flavor dev --dart-define-from-file=.env.json --dart-define=FLAVOR=dev` builds `build/app/outputs/flutter-apk/app-dev-debug.apk`.
- In Progress: None.
- Blocked: Device-specific `flutter run` remains blocked until a target is specified, e.g. an Android/iOS device ID.
- Next Action: Run gym search on a real dev mobile target with `-d <deviceId>` and confirm 403/body diagnostics appear in debug logs when the API rejects the request.

## Session State — 2026-06-14 23:28 CEST
- Active Task: Fix R2 presigned URL 403 during onboarding photo upload
- Environment: Dev/local Functions + Flutter only, `main`
- Modified Files:
    - `functions/src/modules/uploads/uploads.functions.ts`
    - `lib/src/core/upload_service.dart`
    - `lib/src/features/auth/presentation/registration_flow.dart`
    - `tasks/context.md`
- Open Problems:
    - Exact `flutter run --flavor dev --dart-define-from-file=.env.json --dart-define=FLAVOR=dev` could not start because Flutter detected both `macos` and `chrome` and required `-d`.
    - `flutter run -d macos --flavor dev --dart-define-from-file=.env.json --dart-define=FLAVOR=dev` also could not run because the macOS Xcode project has only `Flutter Assemble` and `Runner` schemes, not a `dev` scheme.
    - Existing blockers remain: B005 iOS provisioning and B006 photo upload/onboarding E2E unverified.
    - No deploy, uploads Zod schema, AndroidManifest.xml, Info.plist, google-services.json, Firestore rules, or Firebase config edits performed.
- System Status: Functions tests passing, Flutter tests passing, Flutter analyze clean, dev debug APK build passing.

## Session Handoff
- Completed:
    - Removed `ContentLength` and `Metadata` from the R2 `PutObjectCommand` used by `generateUploadUrl` so those values no longer become required signed headers for the Flutter PUT request.
    - Removed manual `request.contentLength = fileSize` assignment from `UploadService.uploadPhoto` while keeping the existing chunked upload progress logic unchanged.
    - Added debug-only upload failure logging in the `completeRegistration()` catch path where `user == null`, without changing retry/bypass logic.
    - Verified `cd functions && npm run test` passes all 33 Cloud Functions tests.
    - Verified `flutter test` passes all 161 Flutter tests.
    - Verified `flutter analyze --no-fatal-infos` is clean.
    - Verified `flutter build apk --debug --flavor dev --dart-define-from-file=.env.json --dart-define=FLAVOR=dev` builds `build/app/outputs/flutter-apk/app-dev-debug.apk`.
- In Progress: None.
- Blocked: Physical onboarding photo upload E2E remains blocked/unverified until a real mobile target/dev setup is available.
- Next Action: Deploy `generateUploadUrl` only to `tremble-dev` after explicit founder approval, then run authenticated picker -> R2 PUT -> `photoUrls` -> `completeOnboarding` E2E.

## Session State — 2026-06-14 08:37 CEST
- Active Task: Align Functions rate limit TTL field with prod Firestore TTL policy
- Environment: Dev/local Functions only, `main`
- Modified Files:
    - `functions/src/middleware/rateLimit.ts`
    - `functions/src/__tests__/rateLimit.test.ts`
    - `tasks/context.md`
- Open Problems:
    - Existing blockers remain: B005 iOS provisioning and B006 photo upload/onboarding E2E unverified.
    - Pre-existing local changes remain: `coverage/lcov.info` and prior `tasks/context.md` entries.
    - No deploy, Flutter code, Firestore rules, native config, or Firebase config edits performed.
- System Status: Functions TypeScript compile and Jest suite passing.

## Session Handoff
- Completed:
    - Confirmed `functions/src/middleware/rateLimit.ts` wrote `expiresAt` for both new `rateLimits/{uid}:{endpoint}` documents and expired-window resets.
    - Took Option A: changed both Firestore rate limit document writes from `expiresAt` to `ttl` to match the existing prod TTL policy on `am---dating-app`.
    - Added focused regression coverage proving rate limit creation and reset writes include `ttl` and omit `expiresAt`.
    - Verified RED failure before the implementation change showed received `expiresAt` instead of expected `ttl`.
    - Verified `npm test -- rateLimit.test.ts --runInBand`, `npx tsc --noEmit`, and `npm test -- --runInBand` from `functions/`.
- In Progress: None.
- Blocked: None for this local code change.
- Next Action: Review and commit the scoped Functions diff; deploy only after explicit founder approval.

## Session State — 2026-06-14 00:48 CEST
- Active Task: Deploy updated `getMatches` Cloud Function to production
- Environment: Prod Firebase Functions, project `am---dating-app`, `main`
- Modified Files:
    - `tasks/context.md`
- Open Problems:
    - Full `firebase deploy --only functions --project am---dating-app` aborted before deploying because prod has functions not present in local source: `migrateMatchTypes`, `onBleProximity`, `onRunEncounter`, `updateLocation`.
    - Existing blockers remain: B005 iOS provisioning and B006 photo upload/onboarding E2E unverified.
    - `coverage/lcov.info` remains a pre-existing local unstaged test-output change.
- System Status: Targeted `getMatches(europe-west1)` production deploy completed successfully.

## Session Handoff
- Completed:
    - Confirmed current branch is `main`, `.firebaserc` maps prod to `am---dating-app`, and local commit `9a91e6d` contains the `getMatches` batching change.
    - Ran `firebase deploy --only functions --project am---dating-app`; Firebase uploaded source but aborted deletion checks in non-interactive mode before function updates.
    - Avoided forcing deletion of unrelated deployed prod functions.
    - Ran safe targeted deploy: `firebase deploy --only functions:getMatches --project am---dating-app`.
    - Verified Firebase CLI reported `functions[getMatches(europe-west1)] Successful update operation` and `Deploy complete`.
- In Progress: None.
- Blocked: Full all-functions deploy still needs an explicit cleanup/deletion decision for stale deployed functions before it can run non-interactively.
- Next Action: If full Functions deploy is required later, decide whether stale prod functions should be retained, deleted, or reintroduced locally before using `--force`.

## Session State — 2026-06-14 00:36 CEST
- Active Task: Replace hardcoded Slovenian gym enable label with i18n
- Environment: Dev/local Flutter only, `main`
- Modified Files:
    - `lib/src/core/translations.dart`
    - `lib/src/features/gym/presentation/gym_mode_sheet.dart`
    - `test/features/gym/gym_mode_sheet_i18n_test.dart`
    - `tasks/context.md`
- Open Problems:
    - Existing blockers remain: B005 iOS provisioning and B006 photo upload/onboarding E2E unverified.
    - Pre-existing uncommitted Functions changes and `tasks/context.md` handoff entries were preserved.
    - No deploy, native config, Firestore rules, or Firebase config edits performed.
- System Status: Flutter analyze clean. Flutter full test suite passing (161/161).

## Session Handoff
- Completed:
    - Added `enable` translations for English (`Enable`) and Slovenian (`Omogoči`).
    - Replaced the approved hardcoded `Text('Omogoči')` in `gym_mode_sheet.dart` with `Text(t('enable', lang))`.
    - Added focused regression coverage for the gym enable translation and source wiring.
    - Grepped `lib/src/features/gym` and `lib/src/features/dashboard` for hardcoded `Text()` labels matching the requested Slovenian word list; no additional matches remained after the fix.
    - Left `Zavrni` untouched per explicit scope.
    - Verified `flutter analyze --no-fatal-infos` and `flutter test --dart-define-from-file=.env.json`.
- In Progress: None.
- Blocked: None for this code change.
- Next Action: Review and commit the scoped Flutter i18n diff when ready.

## Session State — 2026-06-14 00:29 CEST
- Active Task: Batch partner profile reads in Cloud Functions `getMatches`
- Environment: Dev/local Functions only, `main`
- Modified Files:
    - `functions/src/modules/matches/matches.functions.ts`
    - `functions/src/__tests__/matches.test.ts`
    - `tasks/context.md`
- Open Problems:
    - Existing blockers remain: B005 iOS provisioning and B006 photo upload/onboarding E2E unverified.
    - Pre-existing `tasks/context.md` uncommitted handoff entry was preserved.
    - No deploy, Flutter code, Firestore rules, native config, or Firebase config edits performed.
- System Status: Functions TypeScript compile and Jest suite passing (31/31).

## Session Handoff
- Completed:
    - Added RED/GREEN regression coverage proving `getMatches` batches partner profile reads with one `db.getAll(...)` call.
    - Replaced per-partner `db.collection("users").doc(partnerId).get()` reads inside the match map with ordered `db.getAll(...partnerRefs)` over unblocked partner refs.
    - Preserved the block filter, missing profile skip, and returned match field set exactly.
    - Verified `npm test -- matches.test.ts --runInBand`, `npx tsc --noEmit`, and `npm test` from `functions/`.
- In Progress: None.
- Blocked: None for this code change.
- Next Action: Review and commit the scoped Functions diff when ready; deploy only after explicit founder approval.

## Session State — 2026-06-14 00:30 CEST
- Active Task: Resolve IDE-reported JDK path mismatch error (Supplied javaHome is not a valid folder)
- Environment: Dev
- Modified Files: `android/local.properties` (gitignored path configuration)
- Open Problems: None for this task.
- System Status: Flutter analyze clean, Flutter tests passing (160/160), dev debug APK build passing.

## Session Handoff
- Completed:
    - Diagnosed that Homebrew updated `openjdk@17` from `17.0.18` to `17.0.19`, breaking the hardcached/cached path in the IDE/Gradle daemon.
    - Deleted the incorrect temporary symlink `/opt/homebrew/Cellar/openjdk@17/17.0.18`.
    - Appended the correct `org.gradle.java.home=/opt/homebrew/Cellar/openjdk@17/17.0.19/libexec/openjdk.jdk/Contents/Home` path configuration to the gitignored `android/local.properties` file.
    - Stopped stale Gradle daemons to force path re-evaluation.
    - Verified environment sanity: `flutter analyze` clean, full test suite (160/160) passing, and successful dev debug APK build.
- In Progress: None.
- Blocked: None.
- Next Action: Proceed with features or testing.

## Session State — 2026-06-13 08:51 CEST
- Active Task: Fix failing pre-commit/CI checks, commit, and sync `main`
- Environment: Dev/local Functions + Flutter, `main`
- Modified Files:
    - `functions/src/modules/proximity/proximity.functions.ts`
    - `android/build.gradle.kts`
    - Existing staged Functions, Flutter, Sentry, dependency, and generated plugin files from prior work
    - `tasks/context.md`
- Open Problems:
    - Existing blockers remain: B005 iOS dev provisioning and B006 photo upload/onboarding E2E unverified.
    - `coverage/lcov.info` changed from local test output and was intentionally left unstaged.
    - No deploy, Firestore rules, AndroidManifest.xml, Info.plist, google-services.json, or Firebase config file edits performed in this session.
- System Status: Functions lint/build/tests passing. Flutter analyze/tests passing. Dev debug APK build passing.

## Session Handoff
- Completed:
    - Reproduced the failing Functions regression: `uploads_proximity.test.ts` failed because `scanProximityPairs` threw `Sentry CF connectivity test — delete after confirming`.
    - Removed the temporary Sentry connectivity throw from `scanProximityPairs`.
    - Verified the focused Functions test now passes and the scheduled function reaches its normal completion path.
    - Fixed the Android debug build failure introduced by `sentry_flutter-8.14.2` forcing Kotlin `languageVersion = "1.6"` under the project Kotlin 2.x toolchain by overriding Kotlin compile language/API level to 2.0 for Android subprojects.
    - Verified `dart format .` made no changes.
    - Verified `npm test -- uploads_proximity.test.ts --runInBand`, `npm run lint`, `npm run build`, and `npm test -- --runInBand` from `functions/`.
    - Verified `flutter analyze --no-fatal-infos`, `flutter test --dart-define=FLAVOR=dev`, and `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev`.
- In Progress: Commit and push to `origin/main`.
- Blocked: None for this task.
- Next Action: Commit staged work with a conventional commit and push `main`.

## Session State — 2026-06-13 00:24 CEST
- Active Task: Route `WaveRepository.sendWave` through `TrembleApiClient` and surface generic block-safe wave errors
- Environment: Dev/local Flutter only, `main`
- Modified Files:
    - `lib/src/features/match/data/wave_repository.dart`
    - `lib/src/features/match/presentation/wave_controller.dart`
    - `lib/src/features/matches/presentation/match_dialog.dart`
    - `test/features/match/wave_limit_guard_wiring_test.dart`
    - `tasks/context.md`
- Open Problems:
    - Existing blockers remain: B005 iOS dev provisioning and B006 photo upload/onboarding E2E unverified.
    - `lib/src/core/contact_service.dart` still uses raw `FirebaseFunctions.instance.httpsCallable('onContactAnonymityCheck')`; noted as a separate-scope raw bypass and left unchanged.
    - Pre-existing unrelated Functions, Flutter/native, pubspec, and macOS Podfile worktree changes remain untouched.
    - No deploy, Firestore rules, AndroidManifest.xml, Info.plist, google-services.json, or native config edits performed for this task.
- System Status: Flutter analyze clean. Flutter full test suite passing (160/160).

## Session Handoff
- Completed:
    - Added RED/GREEN regression coverage proving `WaveRepository.sendWave` is routed through `TrembleApiClient` instead of raw `httpsCallable('sendWave')`.
    - Added RED/GREEN regression coverage proving `WaveController` surfaces a typed permission-denied API message inline.
    - Replaced the raw `FirebaseFunctions.instanceFor(...).httpsCallable('sendWave')` path with `_api.call('sendWave', data: {'targetUid': targetUid})`.
    - Preserved account-suspended routing and mapped non-suspension `permission-denied` from `sendWave` to the generic copy: `"You can't wave at this person right now."`
    - Updated `WaveController` and `MatchDialog` to display `TrembleApiException.message` while retaining existing fallback copy for unknown errors.
    - Verified `flutter test test/features/match/wave_limit_guard_wiring_test.dart --dart-define-from-file=.env.json` passes all 6 focused tests.
    - Verified `flutter analyze --no-fatal-infos` reports no issues.
    - Verified `flutter test --dart-define-from-file=.env.json` passes all 160 tests.
- In Progress: None.
- Blocked: None for this code change.
- Next Action: Review and commit the scoped Flutter diff when ready; handle `contact_service.dart` raw bypass in a separate task if desired.

## Session State — 2026-06-13 00:17 CEST
- Active Task: Convert `verifyGoogleToken` raw callable errors to `HttpsError`
- Environment: Dev/local Functions only, `main`
- Modified Files:
    - `functions/src/modules/auth/auth.functions.ts`
    - `functions/src/__tests__/auth.test.ts`
    - `tasks/context.md`
- Open Problems:
    - Existing blockers remain: B005 iOS dev provisioning and B006 photo upload/onboarding E2E unverified.
    - Pre-existing unrelated Flutter/native/pubspec worktree changes remain untouched.
    - No deploy, Flutter code, Firestore rules, Redis error handling, or native config edits performed for this task.
- System Status: Functions TypeScript compile and Jest suite passing (30/30).

## Session Handoff
- Completed:
    - Added a RED/GREEN Jest regression for invalid Google tokens proving `verifyGoogleToken` now throws Firebase `HttpsError` with `code: "unauthenticated"` and message `"Invalid Google token"`.
    - Replaced raw `Error("Server configuration error")` with `HttpsError("internal", "Server configuration error")`.
    - Replaced raw `Error("Invalid token payload")` with `HttpsError("unauthenticated", "Invalid token payload")`.
    - Replaced raw invalid-token wrapping with `HttpsError("unauthenticated", "Invalid Google token")` while preserving already-classified `HttpsError` instances thrown inside the try block.
    - Verified `mutualWaveCounterField()` in `matches.functions.ts` is only used from the `onWaveCreated` Firestore trigger path and left its helper `Error("Failed to compute mutual wave counter month")` unchanged.
    - Verified `npx tsc --noEmit` exits 0 from `functions/`.
    - Verified `npm test -- --runInBand` passes all 30 tests across 6 suites from `functions/`.
- In Progress: None.
- Blocked: None for this code change.
- Next Action: Review and commit the scoped Functions diff when ready; deploy only after explicit founder approval.

## Session State — 2026-06-11 19:28 CEST
- Active Task: Delete dead `checkIdempotency` function from `functions/src/middleware/rateLimit.ts`
- Environment: Dev/local Functions only, `main`
- Modified Files:
    - `functions/src/middleware/rateLimit.ts`
    - `tasks/context.md`
    - Prior prompt changes remain uncommitted in the same worktree.
- Open Problems:
    - Existing blockers remain: iOS provisioning (B005) and photo upload/onboarding E2E (B006).
    - No deploy, Flutter code, Firestore rules, or native config edits performed for this task.
- System Status: Functions TypeScript compile and Jest suite passing (29/29).

## Session Handoff
- Completed:
    - Confirmed `grep -rn 'checkIdempotency' functions/src/` returned only the definition at `rateLimit.ts:95` — zero call sites.
    - Deleted the entire `checkIdempotency` function (JSDoc + implementation) from `functions/src/middleware/rateLimit.ts`.
    - Verified `grep -rn 'checkIdempotency' functions/src/` returns zero results.
    - Verified `npx tsc --noEmit` exits 0.
    - Verified `npm test -- --runInBand` passes all 29 tests across 6 suites.
- In Progress: None.
- Blocked: None for this code change.
- Next Action: Review and commit the accumulated prompt batch before any deploy; deploy only after explicit founder approval.

## Session State — 2026-06-11 19:22 CEST
- Active Task: Lower read endpoint rate limits for `getPublicProfile` and `getMatches`
- Environment: Dev/local Functions only, `main`
- Modified Files:
    - `functions/src/modules/users/users.functions.ts`
    - `functions/src/modules/matches/matches.functions.ts`
    - `functions/src/__tests__/users.test.ts`
    - `functions/src/__tests__/matches.test.ts`
    - `tasks/context.md`
    - Prior prompt changes remain uncommitted in the same worktree.
- Open Problems:
    - Existing blockers remain: iOS provisioning (B005) and photo upload/onboarding E2E (B006).
    - No deploy, Flutter code, Firestore rules, or native config edits performed for this task.
- System Status: Functions TypeScript compile and Jest suite passing.

## Session Handoff
- Completed:
    - Added RED/GREEN regression coverage asserting `getPublicProfile` uses `{ maxRequests: 20, windowMs: 60000 }`.
    - Added RED/GREEN regression coverage asserting `getMatches` uses `{ maxRequests: 30, windowMs: 60000 }`.
    - Lowered `getPublicProfile` from 60/min to 20/min.
    - Lowered `getMatches` from 60/min to 30/min.
    - Verified the targeted tests failed before the code change with received `maxRequests: 60`.
    - Verified `npm test -- users.test.ts matches.test.ts --runInBand`, `npx tsc --noEmit`, `npm test -- --runInBand`, and `git diff --check`.
- In Progress: None.
- Blocked: None for this code change.
- Next Action: Review and commit the accumulated prompt batch before any deploy; deploy only after explicit founder approval.

## Session State — 2026-06-11 19:18 CEST
- Active Task: City-level enum for profile `location` field
- Environment: Dev/local Functions + Flutter, `main`
- Modified Files:
    - `functions/src/modules/users/users.schema.ts`
    - `functions/src/modules/auth/auth.schema.ts`
    - `functions/src/__tests__/auth.test.ts`
    - `functions/src/__tests__/users.test.ts`
    - `lib/src/features/auth/presentation/widgets/registration_steps/step_shared.dart`
    - `lib/src/features/auth/presentation/widgets/registration_steps/email_location_step.dart`
    - `lib/src/features/profile/presentation/edit_profile_screen.dart`
    - `test/features/auth/registration_flow_test.dart`
    - `tasks/context.md`
    - Prior prompt changes remain uncommitted in the same worktree.
- Open Problems:
    - Existing blockers remain: iOS provisioning (B005) and photo upload/onboarding E2E (B006).
    - `settings_screen.dart` only displays location/profile preview; the actual editable settings/profile write path is `/edit-profile`, implemented in `edit_profile_screen.dart`.
    - No deploy, push, Firestore rules, or native config edits performed.
- System Status: Functions compile/lint/tests passing. Flutter analyze and full test suite passing.

## Session Handoff
- Completed:
    - Replaced backend onboarding/update profile `location` validation with `z.enum(["Ljubljana", "Koper", "Zagreb", "Other"]).optional()`.
    - Added Functions schema coverage that accepts enum city values and rejects precise free-text street-address style locations.
    - Added shared Flutter `profileLocationOptions` with the four allowed values.
    - Replaced registration Places autocomplete/free-text location input with existing `OptionPill` selector pattern.
    - Replaced the actual profile edit free-text/autocomplete location field with the same four-option selector and normalized legacy non-enum values to `Other` on edit load.
    - Added Flutter source regression coverage that pins the enum schema shape and ensures registration/edit-profile no longer use `PlacesService` for profile location.
    - Verified `npx tsc --noEmit`, `npm test -- --runInBand`, `npm run lint`, `flutter analyze --no-fatal-infos`, and `flutter test --dart-define-from-file=.env.json`.
- In Progress: None.
- Blocked: None for this code change.
- Next Action: Review and commit the accumulated prompt batch before any deploy; deploy only after explicit founder approval.

## Session State — 2026-06-11 19:06 CEST
- Active Task: Remove dead `updateLocation` Cloud Function export
- Environment: Dev/local Functions only, `main`
- Modified Files:
    - `functions/src/index.ts`
    - `functions/src/modules/proximity/proximity.functions.ts`
    - `functions/src/__tests__/uploads_proximity.test.ts`
    - `functions/src/middleware/validate.ts` (prior prompt, still uncommitted)
    - `functions/src/__tests__/validate.test.ts` (prior prompt, still uncommitted)
    - `test/features/auth/api_payload_contract_test.dart` (prior prompt, still uncommitted)
    - `lib/src/features/auth/presentation/registration_flow.dart` (prior prompt, still uncommitted)
    - `test/features/auth/registration_flow_test.dart` (prior prompt, still uncommitted)
    - `lib/src/features/dashboard/presentation/home_screen.dart` (prior prompt, still uncommitted)
    - `lib/src/features/dashboard/application/dev_simulation_controller.dart` (prior prompt, still uncommitted)
    - `functions/src/modules/users/users.functions.ts` (prior prompt, still uncommitted)
    - `functions/src/__tests__/users.test.ts` (prior prompt, still uncommitted)
    - `functions/src/modules/matches/matches.functions.ts` (prior prompt, still uncommitted)
    - `functions/src/__tests__/matches.test.ts` (prior prompt, still uncommitted)
    - `tasks/context.md`
- Open Problems:
    - Existing blockers remain: iOS provisioning (B005) and photo upload/onboarding E2E (B006).
    - No deploy, Flutter code, Firestore rules, or native config edits performed for this task.
- System Status: Functions TypeScript compile, lint, and Jest suite passing.

## Session Handoff
- Completed:
    - Removed `updateLocation` from the proximity export block in `functions/src/index.ts`.
    - Deleted the `updateLocationSchema` and entire `updateLocation` callable from `proximity.functions.ts`.
    - Renamed stale proximity schema test text/local variable so `grep -rn 'updateLocation' functions/src/` returns zero results.
    - Verified `grep -rn 'updateLocation' functions/src/` returned no output.
    - Verified `npx tsc --noEmit`, `npm test -- --runInBand`, and `npm run lint` from `functions/`.
- In Progress: None.
- Blocked: None for this code change.
- Next Action: Deploy Cloud Functions only after explicit founder approval.

## Session State — 2026-06-11 19:03 CEST
- Active Task: Cloud Functions `assertValidDocumentId` length and character validation
- Environment: Dev/local Functions only, `main`
- Modified Files:
    - `functions/src/middleware/validate.ts`
    - `functions/src/__tests__/validate.test.ts`
    - `test/features/auth/api_payload_contract_test.dart` (prior prompt, still uncommitted)
    - `lib/src/features/auth/presentation/registration_flow.dart` (prior prompt, still uncommitted)
    - `test/features/auth/registration_flow_test.dart` (prior prompt, still uncommitted)
    - `lib/src/features/dashboard/presentation/home_screen.dart` (prior prompt, still uncommitted)
    - `lib/src/features/dashboard/application/dev_simulation_controller.dart` (prior prompt, still uncommitted)
    - `functions/src/modules/users/users.functions.ts` (prior prompt, still uncommitted)
    - `functions/src/__tests__/users.test.ts` (prior prompt, still uncommitted)
    - `functions/src/modules/matches/matches.functions.ts` (prior prompt, still uncommitted)
    - `functions/src/__tests__/matches.test.ts` (prior prompt, still uncommitted)
    - `tasks/context.md`
- Open Problems:
    - Existing blockers remain: iOS provisioning (B005) and photo upload/onboarding E2E (B006).
    - No deploy, Firestore rules, Flutter code, or native config edits performed for this task.
- System Status: Functions TypeScript compile, lint, and Jest suite passing.

## Session Handoff
- Completed:
    - Added validator coverage for accepted 128-character `[a-zA-Z0-9_-]` document IDs.
    - Verified the RED state: IDs over 128 chars and dotted IDs did not throw before the middleware fix.
    - Replaced `assertValidDocumentId` body with the requested empty/string/slash/length/regex guard.
    - Added rejection coverage for strings over 128 characters and IDs containing disallowed punctuation/spaces.
    - Verified `npm test -- validate.test.ts --runInBand`, `npx tsc --noEmit`, `npm test -- --runInBand`, and `npm run lint` from `functions/`.
- In Progress: None.
- Blocked: None for this code change.
- Next Action: Deploy Cloud Functions only after explicit founder approval.

## Session State — 2026-06-11 18:57 CEST
- Active Task: AuthUser `toApiPayload()` contract regression tests
- Environment: Dev/local Flutter only, `main`
- Modified Files:
    - `test/features/auth/api_payload_contract_test.dart`
    - `lib/src/features/auth/presentation/registration_flow.dart` (prior prompt, still uncommitted)
    - `test/features/auth/registration_flow_test.dart` (prior prompt, still uncommitted)
    - `lib/src/features/dashboard/presentation/home_screen.dart` (prior prompt, still uncommitted)
    - `lib/src/features/dashboard/application/dev_simulation_controller.dart` (prior prompt, still uncommitted)
    - `functions/src/modules/users/users.functions.ts` (prior prompt, still uncommitted)
    - `functions/src/__tests__/users.test.ts` (prior prompt, still uncommitted)
    - `functions/src/modules/matches/matches.functions.ts` (prior prompt, still uncommitted)
    - `functions/src/__tests__/matches.test.ts` (prior prompt, still uncommitted)
    - `tasks/context.md`
- Open Problems:
    - Existing blockers remain: iOS provisioning (B005) and photo upload/onboarding E2E (B006).
    - No production code, push, deploy, or native config edits performed for this task.
- System Status: Flutter analyze clean. Flutter test suite passing.

## Session Handoff
- Completed:
    - Created `test/features/auth/api_payload_contract_test.dart`.
    - Pinned `AuthUser.toApiPayload()` hobbies serialization as `List<String>` IDs, not maps.
    - Pinned `nicotineUse` serialization as a single string or null, never a list.
    - Pinned null `nicotineFilter` as absent from the payload.
    - Pinned `lookingFor` as `List<String>`.
    - Pinned server-managed `isPremium` and `isAdmin` as absent from the payload even when true in local `AuthUser`.
    - Added a file-level comment documenting that failures should trigger a separate serialization fix task.
    - Verified `flutter test test/features/auth/api_payload_contract_test.dart --dart-define-from-file=.env.json`, `dart format`, `flutter analyze --no-fatal-infos`, and `flutter test --dart-define-from-file=.env.json`.
- In Progress: None.
- Blocked: None for this test task.
- Next Action: Run B006 device/simulator E2E when provisioning/App Check setup is available.

## Session State — 2026-06-11 18:51 CEST
- Active Task: Registration `isPremium` dev override flavor guard
- Environment: Dev/local Flutter only, `main`
- Modified Files:
    - `lib/src/features/auth/presentation/registration_flow.dart`
    - `test/features/auth/registration_flow_test.dart`
    - `lib/src/features/dashboard/presentation/home_screen.dart` (prior prompt, still uncommitted)
    - `lib/src/features/dashboard/application/dev_simulation_controller.dart` (prior prompt, still uncommitted)
    - `functions/src/modules/users/users.functions.ts` (prior prompt, still uncommitted)
    - `functions/src/__tests__/users.test.ts` (prior prompt, still uncommitted)
    - `functions/src/modules/matches/matches.functions.ts` (prior prompt, still uncommitted)
    - `functions/src/__tests__/matches.test.ts` (prior prompt, still uncommitted)
    - `tasks/context.md`
- Open Problems:
    - Existing blockers remain: iOS provisioning (B005) and photo upload/onboarding E2E (B006).
    - No push, deploy, or native config edits performed.
- System Status: Flutter analyze clean. Flutter test suite passing.

## Session Handoff
- Completed:
    - Replaced registration `isPremium: true` with `isPremium: const String.fromEnvironment('FLAVOR') == 'dev'`.
    - Preserved dev behavior because `.env.json` defines `FLAVOR=dev`.
    - Added regression coverage in `test/features/auth/registration_flow_test.dart` ensuring the hardcoded `isPremium: true` source is absent, the FLAVOR guard is present, and non-dev compiled FLAVOR resolves the local completeOnboarding premium flag to false.
    - Verified the focused regression failed before the production change due to the hardcoded `isPremium: true`.
    - Verified focused non-dev test with `flutter test test/features/auth/registration_flow_test.dart --name "completeOnboarding premium flag is false outside dev flavor"` (without dart defines).
    - Verified `dart format`, `flutter analyze --no-fatal-infos`, and `flutter test --dart-define-from-file=.env.json`.
- In Progress: None.
- Blocked: None for this code change.
- Next Action: Run B006 device/simulator E2E when provisioning/App Check setup is available.

## Session State — 2026-06-11 18:47 CEST
- Active Task: Flutter silent catch instrumentation
- Environment: Dev/local Flutter only, `main`
- Modified Files:
    - `lib/src/features/auth/presentation/registration_flow.dart`
    - `lib/src/features/dashboard/presentation/home_screen.dart`
    - `lib/src/features/dashboard/application/dev_simulation_controller.dart`
    - `functions/src/modules/users/users.functions.ts` (prior prompt, still uncommitted)
    - `functions/src/__tests__/users.test.ts` (prior prompt, still uncommitted)
    - `functions/src/modules/matches/matches.functions.ts` (prior prompt, still uncommitted)
    - `functions/src/__tests__/matches.test.ts` (prior prompt, still uncommitted)
    - `tasks/context.md`
- Open Problems:
    - Existing blockers remain: iOS provisioning (B005) and photo upload/onboarding E2E (B006).
    - No push, deploy, or native config edits performed.
- System Status: Flutter analyze clean. Flutter test suite passing.

## Session Handoff
- Completed:
    - Replaced the silent resend-verification catch in `RegistrationFlow` with `debugPrint('[RegistrationFlow] caught: $e\n$st')`.
    - Replaced the silent location lookup catch in `HomeScreen` event activation flow with `debugPrint('[HomeScreen] caught: $e\n$st')`.
    - Replaced the silent dev heads-up notification cancel catch in `DevSimulationController` with `debugPrint('[DevSimController] caught: $e\n$st')`.
    - Verified the exact `catch (_) {}` pattern is gone from the three requested files.
    - Ran `dart format` on the three touched Dart files; no formatting changes were needed.
    - Verified `flutter analyze --no-fatal-infos` and `flutter test --dart-define-from-file=.env.json`.
- In Progress: None.
- Blocked: None for this code change.
- Next Action: Run B006 device/simulator E2E when provisioning/App Check setup is available.

## Session State — 2026-06-11 18:42 CEST
- Active Task: Cloud Functions `getPublicProfile` authz and block filter
- Environment: Dev/local Functions only, `main`
- Modified Files:
    - `functions/src/modules/users/users.functions.ts`
    - `functions/src/__tests__/users.test.ts`
    - `functions/src/modules/matches/matches.functions.ts` (prior prompt, still uncommitted)
    - `functions/src/__tests__/matches.test.ts` (prior prompt, still uncommitted)
    - `tasks/context.md`
- Open Problems:
    - No deploy performed. Deploy to `tremble-dev` or `am---dating-app` still requires explicit approval.
    - Existing blockers remain: iOS provisioning (B005) and photo upload/onboarding E2E (B006).
- System Status: Functions TypeScript compile, lint, and Jest suite passing.

## Session Handoff
- Completed:
    - Added `getPublicProfile` target-side block filter immediately after target user fetch.
    - Added deterministic match relationship gate using `[uid, userId].sort().join("_")`.
    - Normalized no-profile, target-blocked, and no-match responses to `{ profile: null }`.
    - Added regression tests for unrelated callers and callers blocked by the target.
    - Verified the focused RED state before implementation: both new tests initially returned special-category profile fields.
    - Verified `npm test -- users.test.ts --runInBand`, `npx tsc --noEmit`, `npm run lint`, and `npm test -- --runInBand` from `functions/`.
- In Progress: None.
- Blocked: None for this code change.
- Next Action: Deploy Cloud Functions only after explicit founder approval.

## Session State — 2026-06-11 18:38 CEST
- Active Task: Cloud Functions `sendWave` target block check
- Environment: Dev/local Functions only, `main`
- Modified Files:
    - `functions/src/modules/matches/matches.functions.ts`
    - `functions/src/__tests__/matches.test.ts`
    - `tasks/context.md`
- Open Problems:
    - No deploy performed. Deploy to `tremble-dev` or `am---dating-app` still requires explicit approval.
    - Existing blockers remain: iOS provisioning (B005) and photo upload/onboarding E2E (B006).
- System Status: Functions TypeScript compile, lint, and Jest suite passing.

## Session Handoff
- Completed:
    - Added a `sendWave` target user read after sender ban validation.
    - Rejects missing target users with `not-found`.
    - Applies `assertNotBanned` to the target user before wave creation.
    - Rejects waves with generic `permission-denied` when `target.blockedUserIds` contains the sender UID.
    - Truncated touched `sendWave` log UID fields via `uid.substring(0, 8) + '...'`.
    - Added a Jest regression test proving blocked senders do not create wave documents or consume the soft DoS rate limit.
    - Verified `npm test -- matches.test.ts --runInBand`, `npx tsc --noEmit`, `npm test -- --runInBand`, and `npm run lint` from `functions/`.
- In Progress: None.
- Blocked: None for this code change.
- Next Action: Deploy Cloud Functions only after explicit founder approval.

## Session State — 2026-06-07 23:10 CEST
- Active Task: Onboarding photo compression before R2 upload
- Environment: Dev, `main`
- Modified Files:
    - `pubspec.yaml`
    - `pubspec.lock`
    - `lib/src/features/auth/presentation/registration_flow.dart`
    - `test/features/auth/photo_upload_registration_test.dart`
    - `tasks/context.md`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (BLOCKER-005) blocks physical iPhone deploy.
    - Photo upload/onboarding E2E still needs real device or simulator verification against `tremble-dev`.
- System Status: Focused photo upload tests passing. `flutter analyze --no-fatal-infos` clean.

## Session Handoff
- Completed:
    - Added `flutter_image_compress` because it was not present in `pubspec.yaml`.
    - Added registration photo upload preparation that skips files under 200KB.
    - Compresses larger onboarding photos to JPEG quality 85 with the longest side capped at 1200px.
    - Writes compressed files into `getTemporaryDirectory()` before passing paths to R2 upload.
    - Kept picker UI unchanged.
    - Added regression tests for skip/compress behavior and updated existing upload widget tests to use real temp files.
- In Progress: None.
- Blocked: None for code path; E2E remains blocked by existing provisioning/App Check setup constraints.
- Next Action: Run a real onboarding photo upload against `tremble-dev` when device/simulator setup is available.

## Session State — 2026-06-07 22:55 CEST
- Active Task: Onboarding completeOnboarding serialization contract fix
- Environment: Dev, `main`
- Modified Files:
    - `lib/src/features/auth/data/auth_repository.dart`
    - `test/features/auth/auth_user_wave_limit_test.dart`
    - `tasks/context.md`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (BLOCKER-005) blocks physical iPhone deploy.
    - Photo picker/upload E2E still unverified; code trace shows dev builds can continue from PhotosStep with zero selected photos.
- System Status: Focused AuthUser payload test passing. `flutter analyze --no-fatal-infos` clean.

## Session Handoff
- Completed:
    - Normalized `AuthUser.toApiPayload()` hobbies to a `List<String>` instead of sending hobby maps.
    - Normalized `nicotineUse` to the first selected string or null instead of sending a list.
    - Omitted `nicotineFilter` from the payload when it is null.
    - Added a regression test for the completeOnboarding payload contract.
    - Traced photo picker to upload path and identified why `RegistrationFlow` can upload 0 photos in dev builds.
- In Progress: None.
- Blocked: Photo upload itself not fixed by request; physical/E2E verification remains BLOCKER-006.
- Next Action: Decide whether dev builds should keep bypassing the photo requirement, then verify picker -> upload -> photoUrls on-device/simulator.

## Session State — 2026-06-07 17:38 CEST
- Active Task: Extract edit profile sections through `_HobbiesSection`
- Environment: Dev, `main`
- Modified Files:
    - `lib/src/features/profile/presentation/edit_profile_screen.dart`
    - `lib/src/features/dashboard/presentation/radar_animation.dart`
    - `coverage/lcov.info`
    - `.env.json` (untracked local file; fixed missing comma so test defines parse)
    - `tasks/context.md`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (BLOCKER-005) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (BLOCKER-006) still needs device verification.
- System Status: `flutter analyze --no-fatal-infos` clean. `flutter test --dart-define-from-file=.env.json` passed 148/148.

## Session Handoff
- Completed:
    - Replaced the inline Identity block in `EditProfileScreen.build()` with `_IdentitySection(...)`.
    - Replaced the inline Lifestyle block in `EditProfileScreen.build()` with `_LifestyleSection(...)`.
    - Replaced the inline Metrics block in `EditProfileScreen.build()` with `_MetricsSection(...)`.
    - Replaced the inline Looking For/Languages block in `EditProfileScreen.build()` with `_PreferencesSection(...)`.
    - Replaced the inline Hobbies block in `EditProfileScreen.build()` with `_HobbiesSection(...)`.
    - Added private `_IdentitySection` at the bottom of `edit_profile_screen.dart`.
    - Added private `_LifestyleSection` at the bottom of `edit_profile_screen.dart`.
    - Added private `_MetricsSection` at the bottom of `edit_profile_screen.dart`.
    - Added private `_PreferencesSection` at the bottom of `edit_profile_screen.dart`.
    - Added private `_HobbiesSection` at the bottom of `edit_profile_screen.dart`.
    - Removed dead state-level identity helper methods flagged by analysis.
    - Removed dead state-level nicotine/children helper methods after Lifestyle extraction.
    - Removed dead state-level slider and section-label helper methods after Metrics extraction.
    - Removed dead state-level `_multiPill` helper after Preferences extraction.
    - Removed dead state-level Hobbies helper methods after Hobbies extraction.
    - Preserved the extracted Basic Info name-field helper shape required by the existing source-text regression test.
- In Progress: None.
- Blocked: None for this task.
- Next Action: Android Studio device-to-device verification using dev flavor/config.

## Session State — 2026-06-07 15:46 CEST
- Active Task: Activity recap silent FCM pushes after expired Gym/Run/Event sessions
- Environment: Dev, `main`
- Modified Files:
    - `functions/src/modules/events/events.functions.ts`
    - `functions/src/modules/gym/gym.functions.ts`
    - `tasks/context.md`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (BLOCKER-005) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (BLOCKER-006) still needs device verification.
- System Status: `dart format .` completed with 0 changed files. Backend lint clean. TypeScript compile clean.

## Session Handoff
- Completed:
    - Added data-only silent recap FCM pushes after `expireGymSessions`, `expireRunModes`, and `expireEventModes` clear expired mode fields.
    - Reused already-read user document data for `fcmToken`; no additional Firestore reads were added.
    - Wrapped each `messaging.send()` in `try/catch` so push failure does not abort expiry processing.
    - Verified `npm run lint` and `npx tsc --noEmit` from `functions/`.
- In Progress: Commit and sync to remote `main`.
- Blocked: None for this task.
- Next Action: Deploy Cloud Functions only after explicit founder approval.

## Session State — 2026-06-07 01:53 CEST
- Active Task: Weekend Pass backend activation, scheduled processing, and client premium gating
- Environment: Dev, `main`
- Modified Files:
    - `functions/package.json`
    - `functions/package-lock.json`
    - `functions/src/utils/weekend-window.ts`
    - `functions/src/modules/subscriptions/subscriptions.functions.ts`
    - `functions/src/index.ts`
    - `lib/src/features/auth/data/auth_repository.dart`
    - `firestore.indexes.json`
    - `lib/src/features/settings/presentation/premium_screen.dart` (format-only pre-existing change)
    - `coverage/lcov.info` (regenerated by test run)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (BLOCKER-005) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (BLOCKER-006) still needs device verification.
- System Status: Backend lint clean. TypeScript compile clean. Backend Jest suite passing 19/19. Flutter analyze clean. Flutter test suite passing 148/148.

## Session Handoff
- Completed:
    - Added `luxon` and `@types/luxon` to Cloud Functions dependencies.
    - Created timezone-aware Weekend Pass window utility using Luxon.
    - Added `activateWeekendPass` callable and `processWeekendPasses` hourly scheduler in the subscriptions module.
    - Exported the new Cloud Functions from `functions/src/index.ts`.
    - Added active Weekend Pass resolution into the shared effective premium provider.
    - Added Firestore composite indexes for pending activation and active expiration queries.
    - Ran `dart format lib test`; no Dart formatting changes were needed.
    - Verified `npm run lint`, `npx tsc --noEmit`, `npm test -- --runInBand`, `flutter analyze --no-fatal-infos`, and `flutter test --dart-define-from-file=.env.json`.
- In Progress: Commit and sync to `main`.
- Blocked: None for this task.
- Next Action: Push commit to remote `main`; deploy only after explicit founder approval.

## Session State — 2026-06-07 01:31 CEST
- Active Task: Update premium screen weekend getaway translations across 8 languages
- Environment: Dev, `main`
- Modified Files:
    - `lib/src/features/settings/presentation/premium_screen.dart`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (BLOCKER-005) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (BLOCKER-006) still needs device verification.
- System Status: Static analysis compiles clean with zero issues. Flutter test suite runs and passes cleanly (148/148 tests).

## Session Handoff
- Completed:
    - Updated translation mappings for English and Slovenian for the weekend getaway cards.
    - Added translation maps for German, Croatian, Italian, Spanish, French, and Portuguese for weekend getaway keys.
    - Refactored `_t` string resolution function to dynamically resolve any code defined in `_localTranslations`.
    - Confirmed zero analyzer issues and 148/148 tests passing.
- In Progress: None.
- Blocked: None.
- Next Action: Ready for testing on dev environment.

## Session State — 2026-06-07 01:25 CEST
- Active Task: Implement 2nd-Encounter notification flow in proximity scanner
- Environment: Dev, `main`
- Modified Files:
    - `functions/src/modules/proximity/proximity.functions.ts`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (BLOCKER-005) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (BLOCKER-006) still needs device verification.
- System Status: TypeScript compiler clean. Backend ESLint clean. Backend Jest suite passing 19/19.

## Session Handoff
- Completed:
    - Implemented Redis-based encounter count incrementation and gating in `functions/src/modules/proximity/proximity.functions.ts` within `scanProximityPairs`.
    - Added a 90-day TTL (7776000 seconds) on first encounter.
    - Triggered a normal FCM push notification on exactly the second encounter using translation keys `notify_second_encounter_title` and `notify_second_encounter_body`.
    - Verified compilation (`npx tsc --noEmit`) and linter check (`npm run lint`) pass with no issues.
    - Verified the Jest test suite (19/19) passes cleanly.
- In Progress: None.
- Blocked: None.
- Next Action: Deploy Cloud Functions to dev environment only after explicit founder approval.

## Session State — 2026-06-07 01:20 CEST
- Active Task: Near-Miss monthly recap push scheduled Cloud Function
- Environment: Dev, `main`
- Modified Files:
    - `functions/src/modules/notifications.functions.ts`
    - `firestore.indexes.json`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (BLOCKER-005) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (BLOCKER-006) still needs device verification.
- System Status: TypeScript compiler clean. Backend ESLint clean. Backend Jest suite passing 19/19.

## Session Handoff
- Completed:
    - Created the scheduled Cloud Function `monthlyNearMissRecap` in a new file `functions/src/modules/notifications.functions.ts`.
    - Added the two composite indexes to `firestore.indexes.json` for `proximity_events` (`fromUid` ASC + `timestamp` ASC, and `toUid` ASC + `timestamp` ASC).
    - Verified compilation (`npx tsc --noEmit`) and ESLint (`npm run lint`) pass with no errors or warnings.
    - Verified existing backend Jest tests (19/19) pass successfully.
- In Progress: None.
- Blocked: None.
- Next Action: Add function export to `index.ts` and deploy Cloud Functions only after explicit founder approval.

## Session State — 2026-06-07 01:08 CEST
- Active Task: active_run_crosses creation fix & app.dart Crashlytics Sync
- Environment: Dev, `main`
- Modified Files:
    - `functions/src/modules/proximity/proximity.functions.ts`
    - `lib/src/app.dart`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (BLOCKER-005) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (BLOCKER-006) still needs device verification.
- System Status: TypeScript compiler clean. Backend ESLint clean. Backend Jest suite passing 19/19. `flutter analyze` clean. `flutter test` passed 148/148.

## Session Handoff
- Completed:
    - Added `bothRunMode` detection inside `scanProximityPairs` in `proximity.functions.ts`.
    - Implemented logic to check for existing active run crosses with `"pending"` status, sorting candidate UIDs, and creating a new `active_run_crosses` document when both users are in active Run Mode.
    - Wrapped the RevenueCat `isPremium` Firestore update sync call in `lib/src/app.dart` in a try/catch, logging failures using `FirebaseCrashlytics.instance.recordError(e, stack, reason: 'RevenueCat isPremium sync failed')`.
    - Verified backend types (`tsc --noEmit`) and backend linter (`eslint`) pass cleanly.
    - Verified backend tests (`jest`) pass successfully (19/19 tests).
    - Verified static analysis (`flutter analyze --no-fatal-infos`) and Flutter test suite pass successfully (148/148 tests).
- In Progress: None.
- Blocked: None.
- Next Action: None (ready for manual testing on-device).

## Session State — 2026-06-07 00:56 CEST
- Active Task: Proximity Circles Gating & Filter Toggle on Map
- Environment: Dev, `main`
- Modified Files:
    - `lib/src/features/map/presentation/tremble_map_screen.dart`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (BLOCKER-005) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (BLOCKER-006) still needs device verification.
- System Status: `flutter analyze` clean. `flutter test` passed 148/148.

## Session Handoff
- Completed:
    - Adjusted `_buildProximityCircles` to render identical circles for both Free and Premium users.
    - Implemented `_buildProximityCountBadges` returning a list of `Marker` widgets with count badges for Premium users.
    - Wrapped the map screen's `FlutterMap` in a `Stack` and overlayed a premium-only filter toggle (`CircleAvatar` containing `Icon(Icons.filter_list)`).
    - Verified static analysis compiles with no warnings and the 148-test suite runs successfully.
- In Progress: None.
- Blocked: None.
- Next Action: None.

## Session State — 2026-06-07 00:33 CEST
- Active Task: Dynamic Onboarding Age Range Selection Mapping
- Environment: Dev, `main`
- Modified Files:
    - `lib/src/features/auth/presentation/registration_flow.dart`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (BLOCKER-005) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (BLOCKER-006) still needs device verification.
- System Status: `dart format` completed. `flutter analyze` clean. `flutter test` passed 148/148.

## Session Handoff
- Completed:
    - Replaced the hardcoded onboarding age preferences (`18`, `45`) inside the `completeOnboarding` registration flow call with dynamic user values (`_ageRangePref.start.round()`, `_ageRangePref.end.round()`).
    - Verified compile clean via `flutter analyze`.
    - Verified test suite passes cleanly with all 148 tests passing.
- In Progress: None.
- Blocked: None.
- Next Action: None (onboarding flow alignment complete).

## Session State — 2026-06-07 00:29 CEST
- Active Task: Conditionally Silent FCM Notifications on Activity Modes & Read Optimization
- Environment: Dev, `main`
- Modified Files:
    - `functions/src/modules/proximity/proximity.functions.ts`
    - `functions/src/modules/matches/matches.functions.ts`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (BLOCKER-005) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (BLOCKER-006) still needs device verification.
- System Status: TypeScript compile clean. Backend ESLint clean.

## Session Handoff
- Completed:
    - Implemented a dynamic check for the recipient's activity modes (`isRunModeActive`, `activeGymId`, `activeEventId`) before sending FCM push notifications.
    - For both `CROSSING_PATHS` (proximity engine) and `INCOMING_WAVE` (individual wave), formatted notifications to be data-only and silent (root `notification` key absent and APNS `contentAvailable: true` set) when any active mode is found.
    - Reused the already-fetched Firestore document data in both modules instead of initiating redundant Firestore gets, optimizing database read costs and latency.
    - Kept the `MUTUAL_WAVE` branch completely unchanged.
    - Validated types using `tsc --noEmit` and code cleanliness using `npm run lint`.
- In Progress: None.
- Blocked: None.
- Next Action: None (ready for testing/verification against emulator suite).

## Session State — 2026-06-07 00:22 CEST
- Active Task: Refactor Brand Colors to use TrembleTheme Tokens
- Environment: Dev, `main`
- Modified Files:
    - `lib/src/features/profile/presentation/profile_card_preview.dart`
    - `lib/src/features/profile/presentation/profile_detail_screen.dart`
    - `lib/src/features/profile/presentation/edit_profile_screen.dart`
    - `lib/src/features/gym/presentation/my_gyms_screen.dart`
    - `lib/src/shared/ui/premium_paywall.dart`
    - `lib/src/shared/ui/gradient_scaffold.dart`
    - `lib/src/shared/ui/tremble_outage_screen.dart`
    - `lib/src/shared/ui/skeleton.dart`
    - `lib/src/shared/widgets/radar_painter.dart`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (BLOCKER-005) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (BLOCKER-006) still needs device verification.
- System Status: `dart format` completed. `flutter analyze` clean. `flutter test` passed 148/148.

## Session Handoff
- Completed:
    - Replaced hardcoded brand colors with `TrembleTheme` tokens across the remaining 9 UI files (for a total of 39 files in this refactoring milestone).
    - Verified clean static analysis and passing test suite with all 148 tests passing.
- In Progress: None.
- Blocked: None.
- Next Action: None (milestone completed).

## Session State — 2026-06-06 23:17 CEST
- Active Task: Remove deprecated no-op proximity exports from Cloud Functions index
- Environment: Dev, `main`
- Modified Files:
    - `functions/src/index.ts`
    - `tasks/context.md`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (BLOCKER-005) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (BLOCKER-006) still needs device verification.
- System Status: Backend TypeScript compile clean. Backend Jest suite passing 19/19.

## Session Handoff
- Completed:
    - Removed `onBleProximity` and `onRunEncounter` from the Cloud Functions export surface in `functions/src/index.ts`.
    - Left the deprecated no-op implementations in `proximity.functions.ts` untouched.
- In Progress: None.
- Blocked: None for this task.
- Next Action: Deploy Cloud Functions only after explicit founder approval.

## Session State — 2026-06-06 23:16 CEST
- Active Task: Fix GDPR deletion for proximity_events fromUid/toUid fields
- Environment: Dev, `main`
- Modified Files:
    - `functions/src/modules/gdpr/gdpr.functions.ts`
    - `functions/src/__tests__/gdpr.test.ts`
    - `tasks/context.md`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (BLOCKER-005) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (BLOCKER-006) still needs device verification.
- System Status: Backend TypeScript compile clean. Backend Jest suite passing 19/19.

## Session Handoff
- Completed:
    - Changed GDPR proximity event deletion from legacy `from` to `fromUid`.
    - Added `toUid` deletion coverage for received proximity events.
    - Added regression coverage asserting both proximity event query directions.
    - Verified RED before the production fix and GREEN after the fix.
- In Progress: None.
- Blocked: None for this task.
- Next Action: Deploy Cloud Functions only after explicit founder approval.

## Session State — 2026-06-06 23:13 CEST
- Active Task: Add both-premium nicotine hard filter to scheduled proximity scan
- Environment: Dev, `main`
- Modified Files:
    - `functions/src/modules/proximity/proximity.functions.ts`
    - `functions/src/__tests__/uploads_proximity.test.ts`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (BLOCKER-005) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (BLOCKER-006) still needs device verification.
- System Status: Backend TypeScript compile clean. Backend Jest suite passing 19/19.

## Session Handoff
- Completed:
    - Inserted both-premium nicotine compatibility hard filter after block/flag checks in `scanProximityPairs`.
    - Added regression coverage for incompatible both-premium nicotine filters in `uploads_proximity.test.ts`.
    - Verified targeted RED before the production fix and GREEN after the fix.
- In Progress: None.
- Blocked: None for this task.
- Next Action: Deploy Cloud Functions only after explicit founder approval.

## Session State — 2026-06-06 12:29 CEST
- Active Task: Add Pulse Intercept actions to MatchRevealScreen
- Environment: Dev, `main`
- Modified Files:
    - `lib/src/features/match/presentation/match_reveal_screen.dart`
    - `test/features/match/trembling_window_test.dart`
    - `tasks/context.md`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (BLOCKER-005) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (BLOCKER-006) still needs device verification.
- System Status: `dart format` completed. `flutter analyze` clean. `flutter test --dart-define-from-file=.env.json` passed 147/147.

## Session Handoff
- Completed:
    - Added Send Phone and Send Photo actions inside the match reveal Trembling Window UI.
    - Production path calls `requestPulseIntercept` through `TrembleApiClient` with `targetUid` and `type` set to `phone` or `photo`.
    - Kept Pulse Intercept available identically to Free and Premium users; no premium gate and no text input were added.
    - Added per-action loading, sent confirmation labels, and inline API error rendering.
    - Added widget coverage for phone/photo request payloads and inline error display.
- In Progress: None.
- Blocked: None for this task.
- Next Action: Verify Pulse Intercept end-to-end against deployed backend on an authenticated dev app session when device/provisioning constraints allow.

## Session State — 2026-06-06 11:10 CEST
- Active Task: Strategy Compliance Audit — Step 4 (History / Recaps)
- Environment: Dev, `main` — READ ONLY (no code changes)
- Modified Files:
    - `tasks/audit_step4_history.md` (created — audit results)
- Open Problems:
    - ISSUE-H1 (MEDIUM): Near-Miss tab IS visible to Free users (strategy says hidden). Founder decision needed.
    - ISSUE-H2 (LOW): "To ni več naključje" 2nd-encounter notification not implemented.
    - ISSUE-H3 (LOW): Near-Miss monthly aggregate push for Free not implemented.
    - iOS dev provisioning for `com.pulse` (BLOCKER-005) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (BLOCKER-006) still needs device verification.
- System Status: Build untouched — still 145/145 passing from prior session.

## Session Handoff
- Completed:
    - Full audit of C-HISTORY-01 through C-HISTORY-09 + compatibility score check.
    - 7 MATCH, 2 MISMATCH (not implemented), 1 MISMATCH (tab visibility design gap).
    - Findings saved to `tasks/audit_step4_history.md`.
- In Progress: None.
- Blocked: Founder decision required on ISSUE-H1 (Near-Miss tab visibility for Free).
- Next Action: Founder to review ISSUE-H1 and decide: (a) keep current upsell-tab UX or (b) hide tab for Free per strategy literal. After decision, proceed to implement ISSUE-H2 and ISSUE-H3 if desired, or move to next audit domain.

## Session State — 2026-06-06 10:25 CEST
- Active Task: Implement, test, and verify wave limit properties and photo upload registration flow
- Environment: Dev, `main`
- Modified Files:
    - `lib/src/features/auth/data/auth_repository.dart`
    - `lib/src/features/auth/presentation/registration_flow.dart`
    - `lib/src/features/dashboard/presentation/widgets/radar_search_overlay.dart`
    - `test/features/auth/auth_user_wave_limit_test.dart`
    - `test/features/auth/photo_upload_registration_test.dart`
    - `test/features/match/trembling_window_test.dart`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: Flutter tests passing cleanly (143/143). Static analysis (flutter analyze) clean with zero warnings.

## Session Handoff
- Completed:
    - Added `hasReachedProWaveLimit` and `hasReachedWaveLimit` getters on `AuthUser` in `auth_repository.dart`.
    - Added unit tests for new wave limit getters in `auth_user_wave_limit_test.dart`.
    - Refactored `registration_flow.dart` and `radar_search_overlay.dart` to support mocking/testing (swapped direct `FirebaseAuth.instance` calls, exposed `mapUploadError`, and parameterized clock using a Riverpod provider).
    - Created comprehensive unit and widget tests for the trembling window (expiration, ticking timer, mutual wave UI) and the photo upload flow (progress overlays, upload errors, retry).
    - Added the missing `package:flutter/material.dart` import in `photo_upload_registration_test.dart` and verified that the entire mobile test suite compiles and runs cleanly.
- In Progress: None.
- Blocked: None.
- Next Action: Proceed with on-device testing/provisioning or App Store / Play Console deployment preparation.

## Session State — 2026-06-06 09:15 CEST
- Active Task: Remove unused migrateMatchTypes function export
- Environment: Dev, `main`
- Modified Files:
    - `functions/src/index.ts` (removed migrateMatchTypes export)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: TS build and lint verification clean. Jest backend tests passing. Pre-commit hooks for the commit executed successfully.

## Session Handoff
- Completed:
    - Removed the unused `migrateMatchTypes` export and its associated imports/references inside `functions/src/index.ts`.
    - Confirmed that the backend builds (`tsc`) and lints (`eslint`) successfully.
    - Ran all backend Jest tests and confirmed they pass successfully.
- In Progress: None.
- Blocked: None.
- Next Action: Ready for deploy or further mobile/backend tasks.

## Session State — 2026-06-06 00:30 CEST
- Active Task: Update app store metadata and play console data safety declarations, audit permission gate strings
- Environment: Dev, `main`
- Modified Files:
    - `lib/src/features/auth/presentation/permission_gate_screen.dart` (updated Bluetooth copy and added Notifications + Camera explanation cards)
    - `tasks/appstore_metadata.md` (added Privacy Nutrition Labels, URLs, and checked off Support URL)
    - `tasks/play_console_data_safety.md` (NEW — created Google Play Console Data Safety questionnaire answers)
    - `tasks/context.md` (updated session state)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `dart format` completed. `flutter analyze --no-fatal-infos` clean. `flutter test --dart-define-from-file=.env.json` passed 131/131. Pre-commit hooks for all commits executed successfully.

## Session Handoff
- Completed:
    - Audited and updated the permission gate screen (`permission_gate_screen.dart`) to have accurate, specific, and privacy-forward permission descriptions for Location, Bluetooth, Notifications, and Camera.
    - Updated App Store Metadata (`appstore_metadata.md`) to select a subtitle option, specify support/marketing/privacy URLs, include App Store privacy nutrition labels, and complete checklist items.
    - Created Google Play Console Data Safety declarations (`play_console_data_safety.md`) detailing data collection, data sharing sub-processors, security practices, and deletion policies in Q&A format.
    - Verified all commits successfully compile, format, analyze cleanly, and pass all 131 unit and integration tests.
- In Progress: None.
- Blocked: None.
- Next Action: Proceed with on-device testing and provisioning once blockers B005/B006 are resolved by the founder.

## Session State — 2026-06-05 23:59 CEST
- Active Task: Audit and reword location/GPS/BLE privacy claims for architectural accuracy
- Environment: Dev, `main`
- Modified Files:
    - `lib/src/core/translations.dart` (reworded location privacy calib2_body strings in DE, IT, FR, HR, SR, HU)
    - `lib/src/features/auth/presentation/permission_gate_screen.dart` (reworded fallback description to alongside Bluetooth)
    - `lib/src/features/safety/presentation/safe_zones_screen.dart` (updated geohash block size and coordinates processing description)
    - `tasks/context.md` (updated session log)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `dart format` completed. `flutter analyze --no-fatal-infos` passed. `flutter test --dart-define-from-file=.env.json` 131/131 passed.

## Session Handoff
- Completed:
    - Audited all user-facing strings in `lib/src/core/translations.dart` and hardcoded UI files for location/BLE/GPS claims.
    - Updated `calib2_body` descriptions in German, Italian, French, Croatian, Serbian, and Hungarian to correctly state that coarse geohash grid cells (~150m) are stored on the server and no precise coordinates are saved.
    - Rewrote the fallback location claim in `permission_gate_screen.dart` to clarify that GPS location is used alongside Bluetooth, not as a fallback.
    - Corrected the geohash block size and device-exclusive coordinates storage claims in `safe_zones_screen.dart`.
- In Progress: None.
- Blocked: None.
- Next Action: Commit and sync the staged changes.

## Session State — 2026-06-05 23:43 CEST
- Active Task: Update dev run command docs and fix PlacesService Dart define lookup
- Environment: Dev, `main`
- Modified Files:
    - `lib/src/core/places_service.dart` (replaced nested `String.fromEnvironment` with separate dev/prod/flavor constants and getter)
    - `AGENTS.md`, `CLAUDE.md`, `README.md`, `GEMINI-app.md`, `BOOTSTRAP.md`, `TREMBLE_BACKEND_EXECUTION_GUIDE.md`, `Tremble MPC Workflow.md`, `tasks/decisions/ADR-003-brand-alignment.md` (updated current dev `flutter run` guidance)
    - `tasks/lessons.md` (aligned Rule #1 with `.env.json` dev runs)
    - `tasks/context.md` (updated active run guidance and session handoff)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `dart format lib/src/core/places_service.dart` completed with 0 changes after edit. `flutter analyze --no-fatal-infos` passed. `flutter test --dart-define-from-file=.env.json` passed 131/131.

## Session Handoff
- Completed:
    - Replaced the nested PlacesService API-key `String.fromEnvironment` lookup with explicit `PLACES_KEY_DEV`, `PLACES_KEY_PROD`, and `FLAVOR` constants plus an `_apiKey` getter.
    - Updated current dev run documentation to `flutter run --dart-define-from-file=.env.json`.
    - Left historical blocker evidence and archived plan run commands unchanged.
    - Ran requested formatting, analysis, and test verification.
- In Progress: None.
- Blocked: None for this task.
- Next Action: Commit the accumulated map-style, PlacesService, and command-documentation changes when ready.

## Session State — 2026-06-05 23:31 CEST
- Active Task: Map style boundary zoom, capital labels, and water source-layer verification
- Environment: Dev, `main`
- Modified Files:
    - `assets/map/tremble_dark_style.json` (updated boundaries maxzoom/opacity; inserted `place_capital`; water layers verified unchanged)
    - `tasks/context.md` (session handoff)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `python3 -c "import json; json.load(open('assets/map/tremble_dark_style.json'))"` passed.

## Session Handoff
- Completed:
    - Changed `boundaries.maxzoom` from 9 to 14.
    - Changed `boundaries.paint.line-opacity` from 0.3 to 0.55.
    - Inserted `place_capital` immediately before `place_city`.
    - Confirmed `water` and `water_lines` both already use `"source-layer": "water"` and left them unchanged.
    - Verified `assets/map/tremble_dark_style.json` parses as valid JSON.
- In Progress: None.
- Blocked: None for this task.
- Next Action: Review the map visually on-device or in the map surface when convenient.

## Session State — 2026-06-05 18:45 CEST
- Active Task: Translate photo upload errors and replace hardcoded Slovenian strings
- Environment: Dev, `main`
- Modified Files:
    - `lib/src/core/translations.dart` (added photo_upload_error_* translation keys for all 8 languages)
    - `lib/src/features/auth/presentation/registration_flow.dart` (replaced hardcoded strings with translation keys)
    - `tasks/context.md` (updated session handoff)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `dart format` successfully completed and staged. `flutter analyze --no-fatal-infos` clean. `flutter test --dart-define=FLAVOR=dev` 131/131 passed.

## Session Handoff
- Completed:
    - Added translation keys `photo_upload_error_format`, `photo_upload_error_interrupted`, `photo_upload_error_network`, and `photo_upload_error_generic` in EN, SL, DE, IT, FR, HR, SR, HU.
    - Replaced hardcoded Slovenian strings in `_mapUploadError` within `registration_flow.dart` with localized lookups using the selected app language.
    - Verified that no hardcoded strings remain via `grep`.
    - Ran all local quality checks (formatting, analysis, tests) cleanly.
- In Progress: None.
- Blocked: None for this task.
- Next Action: Commit and push the staged changes.

## Session State — 2026-06-05 18:00 CEST
- Active Task: Skeleton screens for matches and run recap loading states
- Environment: Dev, `main`
- Modified Files:
    - `lib/src/shared/ui/skeleton.dart` (NEW — SkeletonBox + DelayedChild reusable widgets)
    - `lib/src/features/matches/presentation/matches_screen.dart` (replaced spinner with _MatchCardSkeleton × 3)
    - `lib/src/features/dashboard/presentation/run_recap_screen.dart` (replaced history spinner with _RecapItemSkeleton × 2)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `flutter analyze --no-fatal-infos` passed (0 issues). `flutter test --dart-define=FLAVOR=dev` 131/131 passed.

## Session Handoff
- Completed:
    - Created `lib/src/shared/ui/skeleton.dart` with `SkeletonBox` (pulsing shimmer, 1.2s oscillation, dark/light theme-aware) and `DelayedChild` (300ms gate).
    - Replaced matches_screen spinner with 3 `_MatchCardSkeleton` pill cards (64×64 circle + 2 text lines) inside a `DelayedChild`.
    - Replaced run_recap_screen history spinner with 2 `_RecapItemSkeleton` cards (34×34 circle + name line + timestamp) inside a `DelayedChild`.
    - Active section loading in run_recap_screen kept as `SizedBox.shrink()` — was not a spinner.
- In Progress: None.
- Blocked: None for this task.
- Next Action: Continue launch-polish work when founder provides the next task.

## Session State — 2026-06-05 17:30 CEST
- Active Task: Loading states — BLE init + photo upload (Lesson #7)
- Environment: Dev, `main`
- Modified Files:
    - `lib/src/core/translations.dart` (updated loading_scanning/connecting/signals for all 8 languages)
    - `lib/src/core/upload_service.dart` (added onProgress callback via chunked HttpClient)
    - `lib/src/features/auth/presentation/registration_flow.dart` (upload progress overlay)
    - `lib/src/features/dashboard/presentation/home_screen.dart` (spinner duration 2s)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `flutter analyze --no-fatal-infos` passed (0 issues).

## Session Handoff
- Completed:
    - Updated all 8 language translations for `loading_scanning`, `loading_connecting`, `loading_signals` to match the BLE initialization sequence: "Starting radar → Searching nearby → Radar active" (SL: 'Zaganjam radar.' / 'Iskanje v blizini.' / 'Radar je aktiven.').
    - Changed radar match-overlay spinner interval from 2500ms to 2000ms.
    - Rewrote `UploadService.uploadPhoto()` to stream bytes in 64 KB chunks using raw `HttpClient`, exposing an optional `onProgress(bytes, total)` callback. `IOClient` dependency removed (same error types retained).
    - Added `_isUploadingPhotos`, `_uploadProgress`, `_uploadLongRunning` state vars to `_RegistrationFlowState`.
    - During `completeRegistration()`, per-photo byte progress is aggregated and fed to a full-screen overlay (`_buildUploadOverlay`) shown above the PageView.
    - Overlay: `LinearProgressIndicator` (Rose #F4436C fill, 0–1 value), 'Nalaganje slike...' label, 'Še traja, ne zapri aplikacije.' appears if upload exceeds 10 seconds. `_isHardLocking` overlay still fires afterward as before.
- In Progress: None.
- Blocked: None for this task.
- Next Action: Continue launch-polish work when founder provides the next task.

## Session State — 2026-06-05 16:24 CEST
- Active Task: Error placement for BLE/GPS denied states, Wave write failures, and raw Firebase UI strings
- Environment: Dev, `main`
- Modified Files:
    - `lib/src/core/router.dart`
    - `lib/src/features/auth/presentation/forgot_password_screen.dart`
    - `lib/src/features/auth/presentation/registration_flow.dart`
    - `lib/src/features/dashboard/presentation/home_screen.dart`
    - `lib/src/features/dashboard/presentation/run_recap_screen.dart`
    - `lib/src/features/dashboard/presentation/widgets/live_run_card.dart`
    - `lib/src/features/match/presentation/widgets/match_notification_pill.dart`
    - `lib/src/features/matches/presentation/match_dialog.dart`
    - `lib/src/features/profile/presentation/edit_profile_screen.dart`
    - `lib/src/features/safety/presentation/anonymous_mode_screen.dart`
    - `lib/src/features/safety/presentation/blocked_users_screen.dart`
    - `lib/src/features/safety/presentation/safe_zones_screen.dart`
    - `lib/src/features/safety/presentation/widgets/ugc_action_sheet.dart`
    - `lib/src/features/settings/presentation/settings_screen.dart`
    - `lib/src/shared/ui/wave_pill_service.dart`
    - `test/features/auth/registration_flow_test.dart`
    - `test/features/dashboard/run_recap_defensive_paths_test.dart`
    - `test/features/match/near_miss_locked_state_test.dart`
    - `test/features/match/wave_limit_guard_wiring_test.dart`
    - `tasks/context.md` (session handoff)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `dart format` completed; focused error-placement tests passed; `flutter analyze --no-fatal-infos` passed; full `flutter test --dart-define=FLAVOR=dev` passed; `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` passed.

## Session Handoff
- Completed:
    - Confirmed radar BLE denied/off state is already rendered inline through `RadarBleIssueMessage`; blocking permission-gate UI was left unchanged.
    - Moved Wave write failures out of SnackBars for foreground wave pill, live run card, run recap, and match dialog surfaces.
    - Added local optimistic/rollback state where needed so failed Wave writes show `Ni uspelo. Poskusi znova.` inline next to the Wave action.
    - Returned/awaited existing Wave write futures from foreground pill call sites so the pill can catch failures without changing repository write logic.
    - Replaced user-visible raw exception strings with action-specific, user-friendly copy in forgot password, profile upload, account deletion, and safety flows.
    - Added regression coverage for inline Wave failure placement and filtered reset-password errors.
- In Progress: None.
- Blocked: None for this task.
- Next Action: Continue launch-polish work when founder provides the next task.

## Session State — 2026-06-05 16:02 CEST
- Active Task: Wave optimistic UI with rollback
- Environment: Dev, `main`
- Modified Files:
    - `lib/src/features/match/presentation/wave_controller.dart`
    - `lib/src/features/match/presentation/wave_controller.g.dart`
    - `lib/src/features/profile/presentation/profile_detail_screen.dart`
    - `test/features/match/wave_limit_guard_wiring_test.dart`
    - `tasks/context.md` (session handoff)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: focused Wave tests passed; `flutter analyze --no-fatal-infos` passed; full `flutter test --dart-define=FLAVOR=dev` passed; `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` passed.

## Session Handoff
- Completed:
    - Added `WaveSendState` to `WaveController` so wave taps set `AsyncData(optimisticValue)` before awaiting the existing write.
    - Preserved existing write logic in `ProfileDetailScreen`: `sendGesture(matchDoc.id)` when a match doc exists, otherwise `matchController.greet()`.
    - Fired the write via `unawaited(...)` from the Wave button path so UI updates immediately and the network write runs in the background.
    - On exception or timeout, rolled back the optimistic sent state and exposed the inline error: `Wave ni bil poslan. Poskusi znova.`
    - Removed the profile Wave button double-submit path by making sent state derive from Firestore/optimistic Riverpod state instead of calling `onTap` twice.
- In Progress: None.
- Blocked: None for this task.
- Next Action: Continue launch-polish work when founder provides the next task.

## Session State — 2026-06-05 15:53 CEST
- Active Task: Privacy consent encryption copy correction
- Environment: Dev, `main`
- Modified Files:
    - `lib/src/features/auth/presentation/widgets/registration_steps/consent_step.dart`
    - `test/features/auth/registration_flow_test.dart`
    - `tasks/context.md` (session handoff)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: focused registration flow test passed; targeted `flutter analyze --no-fatal-infos lib/src/features/auth/presentation/widgets/registration_steps/consent_step.dart` passed.

## Session Handoff
- Completed:
    - Found the current consent step at `lib/src/features/auth/presentation/widgets/registration_steps/consent_step.dart`; the requested `features/registration/...` path does not exist.
    - Replaced the inaccurate "this data is encrypted" claim with "protected by Google Cloud infrastructure-level encryption at rest" while preserving the surrounding sentence.
    - Added focused regression coverage to prevent the app-level encryption overclaim from returning.
- In Progress: None.
- Blocked: None for this task.
- Next Action: Continue launch-polish work when founder provides the next task.

## Session State — 2026-06-05 15:51 CEST
- Active Task: Password field live checklist alignment
- Environment: Dev, `main`
- Modified Files:
    - `lib/src/features/auth/presentation/widgets/registration_steps/email_location_step.dart`
    - `test/features/auth/registration_flow_test.dart`
    - `tasks/context.md` (session handoff)
- Open Problems:
    - Firebase Console password policy is not represented locally; app-side registration currently enforces 8+ chars, uppercase, digit, and special char before calling Firebase Auth.
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `dart format` completed; focused registration flow test passed; `flutter analyze --no-fatal-infos` passed; `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` passed.

## Session Handoff
- Completed:
    - Confirmed password validation source in `email_location_step.dart`: min length, uppercase, digit, and special character are required before the next button enables.
    - Updated the live password checklist to use `TrembleTheme.successGreen` (`#2D9B6F`) for met items and grey styling for unmet items.
    - Kept the next button disabled until local password requirements and confirm-password match pass; it updates from existing `onChanged` state changes without an extra tap.
    - Added focused regression coverage for the enforced checklist requirements and styling contract.
- In Progress: None.
- Blocked: None for this task.
- Next Action: Continue launch-polish work when founder provides the next task.

## Session State — 2026-06-05 15:46 CEST
- Active Task: Bio field character counter investigation
- Environment: Dev, `main`
- Modified Files:
    - `tasks/context.md` (session handoff)
- Open Problems:
    - Requested onboarding bio input does not exist in the current flow. `registration_flow.dart` has `// Prompt (Removed)` and sends `prompts: const {}`.
    - `firestore.rules` allows `bio` up to 500 chars, but `completeOnboardingSchema` and `updateProfileSchema` are strict and do not accept `bio`.
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: Investigation only; no Dart files changed for this task.

## Session Handoff
- Completed:
    - Read `tasks/lessons.md` before implementation.
    - Verified the direct Firestore `bio` size limit is 500 characters.
    - Confirmed no current onboarding bio/prompt text input exists to patch narrowly.
- In Progress: None.
- Blocked:
    - Adding the requested counter requires first restoring/creating a bio or prompt input and wiring it through strict Cloud Function schemas, which is outside a narrow "do not change anything else" patch.
- Next Action: Founder to confirm whether to restore/create a bio/prompt onboarding step despite the zero-writing onboarding rule.

## Session State — 2026-06-05 15:40 CEST
- Active Task: Radar empty-state translation key coverage
- Environment: Dev, `main`
- Modified Files:
    - `lib/src/core/translations.dart` (added missing `radar_empty_title` / `radar_empty_sub` keys for DE, IT, FR, SR, HU)
    - `tasks/context.md` (session handoff)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: focused translation-key presence check passed; `flutter analyze --no-fatal-infos lib/src/core/translations.dart` passed.

## Session Handoff
- Completed:
    - Verified `radar_empty_title` and `radar_empty_sub` across EN, SL, DE, IT, FR, SR, HU, HR.
    - Added the missing keys only for DE, IT, FR, SR, and HU.
- In Progress: None.
- Blocked: None for this task.
- Next Action: Continue launch-polish work when founder provides the next task.

## Session State — 2026-06-04 — Splash white-plate removal
- Active Task: Splash showed rose icon on a white square plate; want main logo centred on dark, no plate
- Environment: Dev, `main`
- Root cause: `flutter_native_splash.yaml` image was `Logo/tremble_splash_source.png`, which bakes a WHITE square behind the icon (transparent corners but white plate). Composited over `color:#1A1A18` → white plate visible.
- Fix: switched splash `image` + `android_12.image` to `Logo/Tremble Icon Logo.png` (rose logo on alpha=0 transparent bg), re-ran `dart run flutter_native_splash:create` (android only this pass; ios flag restored to true but iOS assets NOT regenerated — gated on B005).
- Modified Files: `flutter_native_splash.yaml`; regenerated `res/drawable*/splash.png`, `android12splash.png`, `background.png`, `launch_background.xml` (drawable + v21), `values{,-night}{,-v31}/styles.xml`; web splash also regenerated (side effect).
- Verified: splash.png corner alpha=0 + rose centre; background.png solid #1A1A18; values-v31 splash bg #1A1A18. APK rebuilt + installed OK. On-device visual blocked by device lock screen (needs founder PIN).
- NOT mine / left untouched: `lib/.../home_screen.dart`, `lib/.../running_stickman.dart` showed modified at this point — not edited by me.

## Session State — 2026-06-03 — Android icon polish + radar FGS crash fix
- Active Task: Themed launcher icon, zoom-out foreground heart, fix radar startForeground crash
- Environment: Dev, `main`, verified on physical Samsung SM-S938B (Android 16 / API 36)
- Modified Files:
    - `android/.../mipmap-anydpi-v26/launcher_icon.xml` (added `<monochrome>` → `@drawable/ic_launcher_foreground`)
    - `android/.../res/drawable/ic_launcher_foreground.xml` (NEW — vector heart scaled 0.29 ≈ 44dp/108 for padding; serves foreground + monochrome)
    - `android/.../res/drawable-{h,m,xh,xxh,xxxh}dpi/ic_launcher_foreground.png` (DELETED 5 — replaced by vector)
    - `android/.../res/drawable/ic_tremble_qs_tile.xml` (NEW vector heart, no plate) + deleted `drawable-xxxhdpi/ic_tremble_qs_tile.png`
    - `android/.../AndroidManifest.xml` (RadarTileService `android:icon` → `@drawable/ic_tremble_qs_tile`)
    - `android/.../radar/RadarForegroundService.kt` (permission-aware FGS type mask + try/catch guard; new `allowedFgsTypes()`/`hasPermission()` helpers)
- System Status: `flutter build apk --debug --flavor dev` ✅. On-device: app no longer crashes on launch in ANY of 3 perm states (no-loc / while-in-use / all-the-time). App icon shows heart with padding in App-info render.

## Session Handoff
- Completed:
    - **Radar crash fixed (the reported "app keeps closing, can't turn it off").** Root cause was NOT the icon work — `RadarForegroundService.kt:86` called `startForeground(..., TYPE_LOCATION|...)`; on Android 14+ that throws `SecurityException` when location perm absent and `ForegroundServiceStartNotAllowedException` when started from background. Persisted radar-active made it a crash loop. Fixed: assert only granted FGS types, wrap in try/catch, force radar OFF on failure. See Rule #9.
    - Themed app icon: monochrome layer added (was missing → blue-blob fallback).
    - Foreground heart zoomed out via scaled vector (≈61% of visible safe zone), monochrome stays aligned.
    - QS/quick-access tile left as the approved vector (per founder: "don't touch it").
- In Progress: None.
- Blocked: None. Note: downstream `flutter_background_service` plugin logs a non-fatal `SecurityException` for its own location-typed FGS when all-the-time location isn't effectively granted — pre-existing, not a crash, out of scope.
- Next Action: Founder to confirm on home screen: (1) themed icon shows heart, (2) heart zoom matches brand reference. Adjust `scaleX/Y` in `ic_launcher_foreground.xml` if more/less padding wanted.

## Session State — 2026-06-02 16:50 CEST
- Active Task: Remove unused `greetings` Firestore composite indexes
- Environment: Dev config cleanup on `main`
- Modified Files:
    - `firestore.indexes.json` (removed three unused `greetings` collectionGroup indexes)
    - `tasks/context.md` (session handoff)
- Open Problems:
    - Step 2.2 device E2E remains pending.
    - Mobile still reads legacy `rateLimits/{uid}:wave_monthly.count` for `wavesThisMonth`; needs migration to `users/{uid}.mutualWaves_YYYY_MM`.
    - Background Firestore trigger limit errors are not directly surfaced to the original `sendWave` callable response.
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `jq empty firestore.indexes.json` passed. `rg "greetings" firestore.indexes.json` returned no matches. No deploy run.

## Session Handoff
- Completed:
    - Removed the three stale `greetings` composite indexes after audit confirmed no TS/Dart runtime code reads or writes the `greetings` collection.
    - Verified JSON validity and absence of `greetings` in `firestore.indexes.json`.
- In Progress: None.
- Blocked: None for this cleanup.
- Next Action: Deploy indexes only when intentionally running the next Firebase index/rules deploy step.

## Session State — 2026-06-02 16:40 CEST
- Active Task: Mark completed backend execution steps and verified strategy claims
- Environment: Dev documentation update on `main`
- Modified Files:
    - `TREMBLE_BACKEND_EXECUTION_GUIDE.md` (marked 1.1, 1.2, 2.1, 2.3 done; 2.2 pending)
    - `STRATEGY_CLAIMS.md` (marked C-WAVE-01 and C-WAVE-02 verified/deployed to dev)
    - `tasks/context.md` (session handoff)
- Open Problems:
    - Step 2.2 device E2E remains pending.
    - Mobile still reads legacy `rateLimits/{uid}:wave_monthly.count` for `wavesThisMonth`; needs migration to `users/{uid}.mutualWaves_YYYY_MM`.
    - Background Firestore trigger limit errors are not directly surfaced to the original `sendWave` callable response.
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: Documentation-only update; verified with `rg` that completion/verification markers are present.

## Session Handoff
- Completed:
    - Marked backend guide Korak 1.1, 1.2, 2.1, and 2.3 as done with 2026-06-02 status notes.
    - Marked Korak 2.2 as pending because the device E2E test cannot be run yet.
    - Updated strategy claims status to partially verified and marked C-WAVE-01/C-WAVE-02 as verified against `matches.functions.ts` and deployed to dev.
- In Progress: None.
- Blocked: Step 2.2 device E2E cannot run yet.
- Next Action: Run Korak 2.2 device E2E when both phones are available.

## Session State — 2026-06-02 16:25 CEST
- Active Task: Backend guide Korak 1.2 — deploy wave limit fix na dev
- Environment: Dev backend deploy (`tremble-dev`) on `main`
- Modified Files:
    - `tasks/context.md` (session handoff)
- Open Problems:
    - Mobile still reads legacy `rateLimits/{uid}:wave_monthly.count` for `wavesThisMonth`; needs migration to `users/{uid}.mutualWaves_YYYY_MM`.
    - Background Firestore trigger limit errors are not directly surfaced to the original `sendWave` callable response.
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `dart format lib/src/features/auth/data/auth_repository.dart` ran with 0 changes. `firebase deploy --only functions:sendWave,functions:onWaveCreated --project tremble-dev` completed successfully. Recent function logs show both functions ACTIVE; only Node `punycode` deprecation warnings, no function errors observed.

## Session Handoff
- Completed:
    - Confirmed current branch is `main`; no feature branch was created.
    - Ran Dart format on the touched Dart auth repository file.
    - Deployed `sendWave` and `onWaveCreated` only to `tremble-dev`.
    - Checked recent Firebase Functions logs for both functions after deploy.
- In Progress: None.
- Blocked: None for Korak 1.2.
- Next Action: Proceed to Backend Execution Guide Faza 2 only when founder is ready for dev validation/device testing.

## Session State — 2026-06-02 16:05 CEST
- Active Task: Mutual wave monthly entitlement migration audit + implementation
- Environment: Dev backend code only; no deploy
- Modified Files:
    - `functions/src/modules/matches/matches.functions.ts` (sent-wave soft DoS guard, mutual-wave calendar-month transaction counters)
    - `functions/src/__tests__/matches.test.ts` (counter helper regression tests)
    - `lib/src/features/auth/data/auth_repository.dart` (TODO markers for legacy wave count display/guard migration)
    - `tasks/context.md` (session handoff)
- Open Problems:
    - Mobile still reads legacy `rateLimits/{uid}:wave_monthly.count` for `wavesThisMonth`; needs migration to `users/{uid}.mutualWaves_YYYY_MM`.
    - Background Firestore trigger limit errors are not directly surfaced to the original `sendWave` callable response.
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: Functions focused Jest test passed; `npx tsc --noEmit` in `functions/` passed; not deployed.

## Session Handoff
- Completed:
    - Replaced `sendWave` product limiter (`wave_monthly`, 5/20 per rolling 30 days) with a soft DoS guard (`sendWave_dos`, 100/day).
    - Added calendar-month mutual wave counter helpers using `users/{uid}.mutualWaves_YYYY_MM`.
    - Moved mutual match creation into a Firestore transaction that checks both users' counters before creating a match, then increments both counters and deletes both wave docs atomically.
    - Added TODO comments at the legacy Flutter wave count guard/read sites without changing mobile behavior.
    - Added focused Jest coverage for the counter field and free/premium limits.
- In Progress: None.
- Blocked: None for backend code. Mobile wave count display/guards remain a documented TODO.
- Next Action: Migrate Flutter `wavesThisMonth` display/guard source from `rateLimits/{uid}:wave_monthly` to `users/{uid}.mutualWaves_YYYY_MM`.

## Session State — 2026-05-31 21:18 CEST
- Active Task: visual updates on home screen (freeze stickman on stop, premium events popup dialog)
- Environment: Dev mobile flavor on `main`
- Modified Files:
    - `lib/src/shared/widgets/running_stickman.dart` (removed reset from pause path)
    - `lib/src/features/dashboard/presentation/home_screen.dart` (premium centered dialog for events.isEmpty)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `flutter analyze` clean, all 125 unit/widget tests passing successfully.

## Session Handoff
- Completed:
    - Modified `running_stickman.dart` to freeze the stickman exactly where he stopped instead of resetting to stride 0.
    - Modified `home_screen.dart` to replace the simple SnackBar notification for "No events nearby" with a stunning premium center-aligned modal that matches the look of other modals (`showModeInfoDialog`).
    - Verified compile/static analyze clean and all 125 tests passed.
- In Progress: None.
- Blocked: None.
- Next Action: Deliver updates to founder for physical device testing.

## Session State — 2026-05-31 21:30 CEST
- Active Task: Foldable / flip-phone form-factor optimization (compact "Now bar" style nav, expanded centering, cutout-safe layout)
- Environment: Dev mobile flavor on `feature/foldable-flip-support`
- Modified Files:
    - `lib/src/shared/ui/form_factor.dart` [NEW]
    - `lib/src/shared/ui/liquid_nav_bar.dart` (added `CompactNavBar`)
    - `lib/src/features/dashboard/presentation/home_screen.dart` (form-factor selection, cutout-safe nav offset, expanded max-width centering)
    - `test/shared/ui/form_factor_test.dart` [NEW]
    - `test/shared/ui/compact_nav_bar_test.dart` [NEW]
- Open Problems:
    - Physical Z Flip cover-screen / Z Fold inner-screen smoke test still pending (no foldable device; iOS device gated by `BLOCKER-005`).
- System Status: `flutter analyze --no-fatal-infos` 0 issues, `flutter test --dart-define=FLAVOR=dev` 125/125 passed, `flutter build apk --debug --flavor dev` ✓.

## Session Handoff
- Completed:
    - Added `FormFactor { compact, standard, expanded }` classifier in `form_factor.dart`. STANDARD phones (incl. iPhone SE 320x568) are explicitly unchanged; only small near-square cover screens → compact, and shortestSide ≥ 600 → expanded. Pure `classifyFormFactor(Size)` is unit-tested against real device metrics; `hasFoldingHinge` reads `displayFeatures` for unfolded Folds.
    - Added `CompactNavBar` — a two-item "Now bar" style nav showing the selected destination + one neighbor (right normally, left when on the last/Settings item). Tapping the neighbor selects it and the bar re-centers; existing swipe-to-switch wrapper retained.
    - Wired `home_screen.dart`: compact surfaces render `CompactNavBar` (else unchanged `LiquidNavBar`); nav bottom offset adds `viewPadding.bottom` on foldables (camera-cutout/gesture-bar safe), standard phones keep the original 30px; expanded surfaces center content within `kExpandedContentMaxWidth` (560).
    - Verified: full analyze clean, 125/125 tests (12 new), dev debug APK built.
- In Progress: None.
- Blocked: None (code). Physical foldable smoke test outstanding.
- Next Action:
    1. Smoke test on a physical Z Flip (cover screen → compact nav) and Z Fold (inner screen → centered content); tune breakpoints in `form_factor.dart` if real metrics differ.
    2. Per-screen compact-overflow tuning for Map/People/Settings on the tiny cover screen is deferred (debt noted in plan).

## Session State — 2026-05-31 21:10 CEST
- Active Task: Upgrade screen gradient theme background match
- Environment: Dev mobile flavor on `main`
- Modified Files:
    - `lib/src/features/settings/presentation/premium_screen.dart` (dynamic background gradient matching other screens via TrembleTheme)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `flutter analyze` 0 issues, 125/125 tests passing.

## Session Handoff
- Completed:
    - Integrated standard `TrembleTheme.getGradient(...)` dynamic background gradient matching on the Upgrade screen (`PremiumUpgradeScreen`).
    - The screen now reactively adapts to gender selection (male/female), pride mode, and light/dark theme modes, aligning perfectly with other application views (like the map or main dashboard).
    - Wrapped the entire viewport inside a custom `Container` with the corresponding linear gradient and set the `Scaffold`'s background to `Colors.transparent`.
    - Automatically synced OS status and system navigation bar coloring (`systemNavigationBarColor`) to match the bottom end of the custom theme gradient.
    - Verified static analysis compiles with zero warnings and all 125 tests passing cleanly.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Await next developer tasks.

## Session State — 2026-05-31 15:30 CEST
- Active Task: Event Mode center-button: nearby event picker or "No events nearby" notification
- Environment: Dev mobile flavor on `main`
- Modified Files:
    - `lib/src/features/gym/data/gym_repository.dart` (TrembleEvent model, getActiveEvents, activateEventMode lat/lng)
    - `lib/src/features/gym/application/gym_mode_controller.dart` (EventModeController.activate lat/lng)
    - `lib/src/features/dashboard/presentation/home_screen.dart` (showEventActivationFlow, _showEventSelectionSheetFor, geolocator import)
    - `lib/src/features/matches/presentation/matches_screen.dart` (showEventActivationFlow call, dart:async import)
    - `lib/src/core/translations.dart` (event_choose_title, event_no_nearby, event_live_now, event_starts_at in 8 languages)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `flutter analyze` 0 issues, 113/113 tests passing.

## Session Handoff
- Completed:
    - Tapping the center button in Event Mode now queries Firestore `events` (active + not-yet-ended) instead of hardcoding `eventId: 'default'`.
    - If no events found → floating SnackBar "No events nearby" (translated in all 8 languages).
    - If events found → branded bottom sheet lists top 3 sorted by distance (nearest first) or by `startsAt` if location unavailable. Each row shows event name, live/upcoming status with green dot, and distance label.
    - Tapping a row closes the sheet and calls `onEventModeActivate` with the real event ID and current device coordinates; backend geo-validation still applies.
    - Same flow wired in `matches_screen.dart` (previously crashed with missing lat/lng params).
    - Fixed `activateEventMode` API call to send `latitude`/`longitude` as required by the backend Cloud Function.
    - `flutter analyze` 0 issues, 113/113 tests passing.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Device smoke test: select Event Mode on radar, tap center button — verify picker sheet or "No events nearby" snack depending on Firestore data.

## Session State — 2026-05-31 14:41 CEST
- Active Task: Refactor Radar selector double highlights, fix bottom sheet overflows, and enable persistent spinning active animation
- Environment: Dev mobile flavor on `main`
- Modified Files:
    - `lib/src/features/dashboard/presentation/home_screen.dart`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `flutter analyze` clean, all 113 unit/widget tests passing successfully, `flutter build apk` succeeds.

## Session Handoff
- Completed:
    - Unified standard "Tremble Radar Mode" as a first-class selection (`RadarModeKind.radar`), removing prepended code and fixing all double highlight checkmark visual issues.
    - Wrapped the bottom sheet mode selector items inside a `SingleChildScrollView`, completely resolving the 15px layout overflow.
    - Simplified the top-left mode icon `_PulseIcon` gestures: removed long-press and mapped `onTap` to directly trigger the mode selector bottom sheet.
    - Swapped center circular button icon/color dynamically on selection (e.g. dumbbell and yellow when Gym Mode is selected, but not yet active). Tapping the center button in this state now successfully activates the mode.
    - Kept the radar animation spinning persistently when any specialized mode (Gym, Run, Event) is activated.
    - Fully verified with `flutter analyze` (0 issues), `flutter test` (113/113 passed), and Gradle APK build (Dev Debug succeeded).
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Deliver to founder for physical device smoke testing.

## Session State — 2026-05-31 13:04 CEST
- Active Task: Color and highlight Gym, Run, and Event modes when they are active
- Environment: Dev mobile flavor on `main`
- Modified Files:
    - `lib/src/features/dashboard/presentation/home_screen.dart` (color active modes inside `_showModeSelector`)
    - `lib/src/features/matches/presentation/matches_screen.dart` (align circular border concentrically, color active indicator dots next to screen title, color active modes in `_SectionPickerSheet`)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `flutter analyze` clean, all 113 unit/widget tests passing successfully.

## Session Handoff
- Completed:
    - Integrated dynamic highlight coloring for active Gym, Run, and Event modes inside `_showModeSelector` on the Radar screen.
    - Added concentric stack alignment to the concentric circles of `_ModeIconButton` on the Matches page.
    - Added dynamic indicator dots next to the section title on the Matches screen to show if the active section's mode is enabled.
    - Highlighted active modes with their designated theme colors inside the Matches screen's `_SectionPickerSheet`.
    - Verified static analysis (0 warnings) and all 113 tests passing successfully.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Await next user instructions.

## Session State — 2026-05-31 12:58 CEST
- Active Task: Integrate light/dark themes, pride, and gender color schemes into Tremble Map background and controls
- Environment: Dev mobile flavor on `main`
- Modified Files:
    - `lib/src/features/map/presentation/tremble_map_screen.dart` (dynamic background gradient, text, zoom toggle, and pill colors)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `flutter analyze` clean, all 113 unit/widget tests passing successfully.

## Session Handoff
- Completed:
    - Wired reactive `Theme.of(context).brightness` inside `TrembleMapScreen` and its sub-widgets (`_MapZoomToggle` and `_MapPill`).
    - Configured screen background gradient to pull dynamically from `TrembleTheme.getGradient(...)` respecting pride mode, dark mode, gender mode, and custom colors.
    - Re-styled `_MapZoomToggle`, `_MapPill`, and the map container boundaries with theme-compliant borders, colors, and shadows for maximum visual polish in both themes.
    - Switched hardcoded material blue in the zoom toggle active state to dynamic `Theme.of(context).primaryColor`.
    - Verified static analysis (0 warnings) and complete test suite (113/113 passed).
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Await next user instructions.

## Session State — 2026-05-30 23:45 CEST
- Active Task: Configure correct production Firestore TTL policies and deploy Firestore security rules
- Environment: Prod Firestore (`am---dating-app`)
- Modified Files:
    - `tasks/context.md` (documented TTL policy update and rules deploy)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: TTL policies for `proximity_events` and `run_encounters` enabled on `expiresAt` field in `am---dating-app`. Firestore security rules successfully deployed to production.

## Session Handoff
- Completed:
    - Enabled correct Firestore TTL policies on the `expiresAt` field for both the `proximity_events` and `run_encounters` collection groups in the `am---dating-app` project via `gcloud firestore fields ttls update`.
    - Verified that `gcloud firestore fields ttls list` returns `expiresAt` with `state: ACTIVE` for both collection groups.
    - Switched Firebase CLI active project to `am---dating-app` and successfully deployed `firestore.rules` using `firebase deploy --only firestore:rules`.
    - Marked TTL policy setup and `B008` (active_run_crosses rules check) as successfully finalized in production.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Await next user instructions.

## Session State — 2026-05-30 23:25 CEST
- Active Task: Disable incorrect production Firestore TTL policy on `ttl` field
- Environment: Prod Firestore (`am---dating-app`)
- Modified Files:
    - `tasks/context.md` (documented TTL policy update)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: TTL policy on `ttl` field successfully disabled in `am---dating-app`.

## Session Handoff
- Completed:
    - Disabled the incorrect Firestore TTL policy targeting the `ttl` field on `proximity_events` collection group in the `am---dating-app` project via `gcloud firestore fields ttls update`.
    - Confirmed that `gcloud firestore fields ttls list` now returns 0 items for `proximity_events`.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Await next user instructions.

## Session State — 2026-05-30 23:05 CEST
- Active Task: Resolve tech-debt items (README section, main.dart comments/AppCheck, localbroadcastmanager removal)
- Environment: Dev and Prod mobile flavor on `main`
- Modified Files:
    - `README.md` (added Local Setup section)
    - `lib/main.dart` (removed stale comment, consolidated AppCheck calls)
    - `android/app/build.gradle.kts` (removed localbroadcastmanager dependency)
    - `android/app/src/main/kotlin/tremble/dating/app/MainApplication.kt` (removed LocalBroadcastManager and receiver, wired direct Kotlin callback)
    - `android/app/src/main/kotlin/tremble/dating/app/radar/RadarStateBridge.kt` (removed LocalBroadcastManager and wired callback trigger)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `flutter analyze` 0 issues, `flutter test` 113/113 passed, `flutter build apk --flavor dev` ✓, `flutter build ios --flavor dev --no-codesign` ✓.

## Session Handoff
- Completed:
    - Added a "Local Setup — Required Files" section to the `README.md` document documenting the gitignored configuration files required for setup.
    - Removed the stale "temporarily commented out" comment from `lib/main.dart` imports.
    - Consolidated double `FirebaseAppCheck.instance.activate()` calls into a single call in `lib/main.dart`.
    - Completely replaced the deprecated `androidx.localbroadcastmanager` pattern in Android Kotlin code with a clean, in-process, type-safe Kotlin callback trigger in `RadarStateBridge.kt` and `MainApplication.kt`.
    - Removed the localbroadcastmanager implementation dependency from `android/app/build.gradle.kts`.
    - Verified compile and runtime success with static analysis, tests, and build APK.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Await next user instructions.

## Session State — 2026-05-30 22:50 CEST
- Active Task: Correct TTL policy field comment in `proximity.functions.ts`
- Environment: Dev/Prod Cloud Functions on `main`
- Modified Files:
    - `functions/src/modules/proximity/proximity.functions.ts` (updated TTL comment)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `npm run build` SUCCESS.

## Session Handoff
- Completed:
    - Updated comment at line ~590 in `proximity.functions.ts` to correctly note that the Firestore TTL policy targets `expiresAt` rather than `ttl`.
    - Verified compilation of TypeScript Cloud Functions.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Await next user instructions.

## Session State — 2026-05-30 22:45 CEST
- Active Task: Fix BLE bugs (UID truncation & silent empty catch) in `ble_service.dart`
- Environment: Dev and Prod mobile flavor on `main`
- Modified Files:
    - `lib/src/core/ble_service.dart` (imported Crashlytics, increased UID take to 28, resolved silent empty catch block)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `flutter analyze` 0 issues, `flutter test` 113/113 passed, `flutter build apk --flavor dev` ✓.

## Session Handoff
- Completed:
    - Extended maximum UID length byte-take from 20 to 28 to prevent Firebase UID truncation in BLE advertising packets (BUG 1).
    - Added TODO comment indicating future removal of the UID payload once Faza 3.1 is completed.
    - Replaced the silent catch-all in Firestore proximity writes with debug logging and `FirebaseCrashlytics.instance.recordError` logging to report write issues without crashing (BUG 2).
    - Imported `package:firebase_crashlytics/firebase_crashlytics.dart` in `ble_service.dart`.
    - Verified with `flutter analyze`, `flutter test`, and Gradle build APK.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Await next user instructions.

## Session State — 2026-05-30 22:30 CEST
- Active Task: Hide active people count pill in production builds
- Environment: Dev and Prod mobile flavor on `main`
- Modified Files:
    - `lib/src/features/map/presentation/tremble_map_screen.dart` (imported foundation, wrapped active people count pill with condition)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `flutter analyze` 0 issues, `flutter test` 113/113 passed, `flutter build apk --flavor dev` ✓.

## Session Handoff
- Completed:
    - Added `import 'package:flutter/foundation.dart' show kDebugMode;` to `tremble_map_screen.dart`.
    - Wrapped the `_MapPill` displaying the "active people count" along with its spacing `SizedBox` with `if (kDebugMode || const String.fromEnvironment('FLAVOR') == 'dev')`.
    - Verified static analysis (0 issues), all 113 unit/widget tests passing, and the dev flavor APK built successfully.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Await next user instructions.

## Session State — 2026-05-30 22:15 CEST
- Active Task: Persistent on-disk tile cache for PmTiles map
- Environment: Dev mobile flavor on `main`
- Modified Files:
    - `pubspec.yaml` (added path_provider ^2.1.0)
    - `lib/src/core/map_provider.dart` (cacheDir + constants)
    - `lib/src/features/map/presentation/tremble_map_screen.dart` (VectorTileLayer cache params)
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `flutter analyze` 0 issues, `flutter test` 113/113 passed, `flutter build apk --flavor dev` ✓ Built app-dev-release.apk (79.2 MB).

## Session Handoff
- Completed:
    - Added `path_provider: ^2.1.0` to `pubspec.yaml`.
    - Inspected `vector_map_tiles 8.0.0` pub cache source to confirm the correct on-disk cache API: `VectorTileLayer` takes `cacheFolder` (`Future<Directory> Function()`), `fileCacheTtl` (`Duration`), and `fileCacheMaximumSizeInBytes` (`int`) — **not** a separate class like `FileTileStorage`.
    - Extended `MapInitData` with a `cacheDir` field (`Directory`); resolved once at app start via `getApplicationDocumentsDirectory()` pointing to `<docs>/map_cache`.
    - Exported `mapCacheMaxBytes` (200 MB) and `mapCacheTtl` (30 days) constants from `map_provider.dart`.
    - Wired `cacheFolder`, `fileCacheTtl`, and `fileCacheMaximumSizeInBytes` onto `VectorTileLayer` in `tremble_map_screen.dart` — all other layers and UI config unchanged.
    - Verified: `flutter analyze` clean, 113/113 tests pass, `flutter build apk --flavor dev` ✓.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Await next user instructions.

## Session State — 2026-05-30 22:10 CEST
- Active Task: Map init Riverpod refactor (PmTiles global FutureProvider)
- Environment: Dev mobile flavor on `main`
- Modified Files:
    - `lib/src/core/map_provider.dart` [NEW]
    - `lib/src/features/map/presentation/tremble_map_screen.dart`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `flutter analyze` 0 issues, `flutter test` 113/113 passed, dev APK built successfully.

## Session Handoff
- Completed:
    - Created `lib/src/core/map_provider.dart` — global `FutureProvider<MapInitData>` (`mapInitProvider`) using `rootBundle.loadString` for the style JSON and `PmTilesVectorTileProvider.fromSource` for the tile provider. Runs once per app session, cached by Riverpod.
    - Removed `_MapInitData`, `_mapInitFuture`, `_initializeMap()`, and the local imports for `dart:convert`, `vector_map_tiles_pmtiles`, and `vector_tile_renderer` from `tremble_map_screen.dart`.
    - Replaced the per-screen `FutureBuilder` with `ref.watch(mapInitProvider).when(loading/error/data)` — identical UI, zero regressions.
    - Retained `vector_map_tiles` import in the screen (needed for `VectorTileLayer` and `TileProviders`).
    - Verified: `flutter analyze` clean, 113/113 tests pass, `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` ✓.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Await next user instructions.

## Session State — 2026-05-30 21:42 CEST
- Active Task: Fix dead consent links & correct location privacy claims
- Environment: Dev and Prod mobile flavor on `main`
- Modified Files:
    - `pubspec.yaml`
    - `lib/src/features/auth/presentation/widgets/registration_steps/consent_step.dart`
    - `lib/src/core/translations.dart`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `flutter analyze` and `flutter test` SUCCESS (113/113 tests passed), dev build succeeded.

## Session Handoff
- Completed:
    - Installed `url_launcher` dependency.
    - Imported `package:url_launcher/url_launcher.dart` and wired `launchUrl` for Terms of Service and Privacy Policy in the registration `consent_step.dart`.
    - Corrected false location privacy claims ("Zero location stored" / "Brez shranjevanja lokacije") in both English and Slovenian keys under `lib/src/core/translations.dart` to accurately describe the ~150m grid geohash storage.
    - Ran the full verification protocol: static analyze clean, all 113 unit/widget tests passing, and Gradle `assembleDevDebug` build successful.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Await next user instructions.

## Session State — 2026-05-29 11:25 CEST
- Active Task: Restore missing Firebase option and credential files
- Environment: Dev and Prod mobile flavor on `main`
- Modified Files:
    - `lib/src/core/firebase_options_dev.dart`
    - `lib/src/core/firebase_options_prod.dart`
    - `android/app/src/dev/google-services.json`
    - `android/app/src/prod/google-services.json`
    - `ios/Runner/Firebase/Dev/GoogleService-Info.plist`
    - `ios/Runner/Firebase/Prod/GoogleService-Info.plist`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `flutter analyze` and `flutter test` SUCCESS (113/113 tests passed).

## Session Handoff
- Completed:
    - Restored `firebase_options_dev.dart` and `firebase_options_prod.dart` configurations from git history.
    - Reconstructed all flavor-specific `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) credential files by querying `firebase-tools` for dev and prod active projects.
    - Verified all configurations are perfectly ignored by git, protecting credentials from commits.
    - Executed flavored verification protocol: all 113/113 unit and widget tests successfully passed, and `flutter analyze` returned zero errors or warnings.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Run `flutter run --dart-define-from-file=.env.json` to verify the application launch on a simulator/device.

## Session State — 2026-05-29 11:25 CEST (Updated)
## Session State — 2026-05-28 13:20 CEST
- Active Task: Silent wave error handling and TTL expiry notification
- Environment: Dev mobile flavor on `main`
- Modified Files:
    - `lib/src/core/translations.dart`
    - `lib/src/features/dashboard/presentation/home_screen.dart`
    - `lib/src/features/dashboard/presentation/run_recap_screen.dart`
    - `test/features/dashboard/run_recap_defensive_paths_test.dart`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `flutter analyze` and `flutter test` SUCCESS (110/110 tests passed).

## Session Handoff
- Completed:
    - Implemented FIX 1 and FIX 2 for silent wave sending errors in `home_screen.dart`.
    - Added `wave_failed` translation keys in all 8 supported languages.
    - Implemented a transition listener using `ref.listen` on `recapTTLProvider` in `run_recap_screen.dart` to trigger a one-time SnackBar with `pulse_expired` i18n translation at the exact moment of recap expiry.
    - Replaced the hardcoded `'Wave failed. Try again.'` string in `run_recap_screen.dart`'s `_handleWaveTap` error handling with the existing `wave_failed` translation key.
    - Updated `run_recap_defensive_paths_test.dart` to expect `wave_failed` instead of the literal hardcoded string in the source scan.
    - Verified static analysis and all unit/widget tests.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Await next user instructions or continue production stabilization.

## Session State — 2026-05-28 13:00 CEST
- Active Task: Paywall GlassCard -> solid brand card fix
- Environment: Dev mobile flavor on `main`
- Modified Files:
    - `lib/src/features/settings/presentation/premium_screen.dart`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `flutter analyze` and `flutter test` SUCCESS (110/110 tests passed).

## Session Handoff
- Completed:
    - Replaced premium paywall card glassmorphic styling with solid Deep Graphite (`#1A1A18`) backgrounds.
    - Configured cards to use `1px` solid borders matching plan-specific accent colors.
    - Switched price typography to Playfair Display and card title/labels to Instrument Sans.
    - Switched all opacity-based card text colors to solid brand colors (`#FAFAF7`, `#A0A09A`, `#6B6B63`).
    - Changed tag and savings badge backgrounds to transparent with solid borders.
    - Preserved circular outline design rings inside the card layout as they do not use blurs.
    - Verified static analysis and all unit/widget tests.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Verify screen layout and card colors on a running simulator or device.

## Session State — 2026-05-28 12:36 CEST
- Active Task: Wire WavePillService to HomeScreen FCM notifications
- Environment: Dev backend/mobile flavors on `main`
- Modified Files:
    - `functions/src/modules/matches/matches.functions.ts`
    - `functions/src/modules/proximity/proximity.functions.ts`
    - `lib/src/features/dashboard/presentation/home_screen.dart`
    - `tasks/context.md`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `npm run build` SUCCESS. `npm run lint` SUCCESS. `npm test` SUCCESS (14/14 tests passed). `flutter analyze` and `flutter test` SUCCESS (110/110 tests passed).

## Session Handoff
- Completed:
    - Integrated foreground FCM notification listener in `HomeScreen.initState` post-frame callback.
    - Resolved naming matches and properties mismatches inside `INCOMING_WAVE` and `CROSSING_PATHS` push notification payloads.
    - Added age computation and sender photo values in the backend payloads.
    - Ran backend compilation/linting/tests successfully.
    - Ran Flutter analyze and full unit/widget tests successfully.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Deploy backend changes to dev and test on real devices to verify foreground pill display.

## Session State — 2026-05-28 12:20 CEST
- Active Task: Add rate limiting to 13 Cloud Functions
- Environment: Dev backend flavor on `main`
- Modified Files:
    - `functions/src/modules/matches/intercept.functions.ts`
    - `functions/src/modules/matches/matches.functions.ts`
    - `functions/src/modules/events/events.functions.ts`
    - `functions/src/modules/gym/gym.functions.ts`
    - `functions/src/modules/proximity/proximity.functions.ts`
    - `functions/src/modules/users/users.functions.ts`
    - `tasks/context.md`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `npm run build` SUCCESS. `npm run lint` SUCCESS. `npm test` SUCCESS (14/14 tests passed). `flutter analyze` and `flutter test` SUCCESS (110/110 tests passed).

## Session Handoff
- Completed:
    - Added rate limiting using Firestore TTL `checkRateLimit` middleware immediately after authentication checks on 13 targeted Cloud Functions.
    - Category limits configured:
      - Priority 1 (stricter limit): 5 req/min (e.g. `requestPulseIntercept`, `getPulseIntercept`, `onEventModeActivate`, `onEventModeDeactivate`, `onGymModeActivate`, `onGymModeDeactivate`, `onRunModeActivate`, `onRunModeDeactivate`, `migrateMatchTypes`).
      - Background switcher limit: 15 req/min (`setInactive`).
      - Priority 2 (looser limit): 60 req/min (e.g. `getProfile`, `getPublicProfile`, `getMatches`).
    - Verified compilation, clean lint status, and Jest tests.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Deploy updated functions to dev environment for client-side regression verification.

## Session State — 2026-05-28 11:51 CEST
- Active Task: Update firestore.rules whitelists and type checks
- Environment: Dev mobile flavor on `main`
- Modified Files:
    - `firestore.rules`
    - `tasks/blockers.md`
    - `tasks/todo.md`
    - `tasks/MASTER_PLAN.md`
    - `tasks/context.md`
- Open Problems:
    - iOS dev provisioning for `com.pulse` (`BLOCKER-005`) blocks physical iPhone deploy.
    - Real photo upload / onboarding E2E (`BLOCKER-006`) still needs device verification.
- System Status: `firebase_validate_security_rules` SUCCESS. `flutter analyze` and `flutter test` are passing (110/110).

## Session Handoff
- Completed:
    - Updated `todo.md`, checking off `BLOCKER-003` (Legal/Company Setup) and `BLOCKER-007` (Legal web pages live).
    - Updated `blockers.md` marking `BLOCKER-003` as resolved (AMS Solutions d.o.o. registered 2026-05-07).
    - Updated `MASTER_PLAN.md` to reflect that F8 (Paywall) code is complete and F7 (Valentine Promo) is on hold.
    - Updated `firestore.rules` to update `proximity/{userId}` write rule with `hasOnly()` whitelist including `isLowPowerMode` and `geoHashExpiresAt` (removing `expiresAt`), and added type validation for `isLowPowerMode` (bool), `updatedAt` (timestamp), and `geoHashExpiresAt` (timestamp). Verified syntax with `firebase_validate_security_rules`.
- In Progress: None.
- Blocked:
    - iOS physical device verification / App Store Connect testing remains blocked by `BLOCKER-005`.
- Next Action:
    1. Await Apple Developer Account approval to resolve `BLOCKER-005` provisioning and enable full device smoke testing of photo upload E2E and RevenueCat.

## Session State — 2026-05-27 23:13 CEST
- Active Task: RevenueCat SDK integration for Premium entitlement/paywall
- Environment: Dev mobile flavor on `main`; no deploys; no Firestore/webhook sync
- Modified Files:
    - `android/app/src/main/AndroidManifest.xml`
    - `lib/src/app.dart`
    - `lib/src/features/auth/data/auth_repository.dart`
    - `lib/src/features/settings/presentation/premium_screen.dart`
    - `lib/src/features/subscriptions/application/revenuecat_subscription.dart`
    - `lib/src/shared/ui/premium_paywall.dart`
    - `macos/Flutter/GeneratedPluginRegistrant.swift`
    - `pubspec.yaml`
    - `pubspec.lock`
    - `test/features/settings/premium_screen_test.dart`
    - `test/features/subscriptions/revenuecat_subscription_test.dart`
    - `tasks/context.md`
- Open Problems:
    - RevenueCat webhooks / Firestore `isPremium` sync intentionally not wired; separate task after Apple Developer account approval.
    - Store-side products/offering/paywall must exist in RevenueCat/App Store Connect/Play Console for real purchases to work on device.
- System Status: `dart format` SUCCESS on changed Dart files. `flutter analyze --no-fatal-infos` SUCCESS. `flutter test --dart-define=FLAVOR=dev` SUCCESS (110/110). No deploy performed.

## Session Handoff
- Completed:
    - Installed `purchases_flutter` and `purchases_ui_flutter` via Pub.
    - Added Android billing permission only: `com.android.vending.BILLING`.
    - Added a testable RevenueCat subscription controller with `premium` entitlement, `default` offering, exact product IDs `monthly`, `yearly`, `lifetime`, and `weekly`.
    - Configured SDK startup through `--dart-define=REVENUECAT_API_KEY`; the dev key was not committed to source.
    - Wired Firebase auth user IDs to RevenueCat `logIn` / `logOut` without syncing Firestore `isPremium`.
    - Wired RevenueCat CustomerInfo entitlement status into `effectiveIsPremiumProvider`.
    - Replaced the shared mock paywall bottom sheet with RevenueCat Paywall presentation.
    - Replaced Premium screen simulated purchases with RevenueCat package purchase, restore purchases, and Customer Center entry for subscription management.
    - Added regression tests for identifiers, disabled missing-key behavior, purchase/restore premium state, and premium card product mapping.
- In Progress: None.
- Blocked:
    - Real purchase/device validation remains blocked by store-side product readiness and existing Apple Developer provisioning blocker.
- Next Action:
    1. Run the app with `flutter run --dart-define-from-file=.env.json` on a device/simulator after RevenueCat offering/paywall/products are configured.

## Session State — 2026-05-26 23:53 CEST
- Active Task: History empty states for Matches, Recaps, and Near-Miss
- Environment: Dev mobile flavor on `main`; no Firebase/backend/native config changes
- Modified Files:
    - `lib/src/features/matches/presentation/matches_screen.dart`
    - `lib/src/features/dashboard/presentation/run_recap_screen.dart`
    - `lib/src/core/translations.dart`
    - `test/features/recap/viewed_recaps_wiring_test.dart`
    - `tasks/context.md`
- Open Problems:
    - Existing unrelated dirty files remain in the worktree and were not reverted.
- System Status: `dart format` SUCCESS. Focused history empty-state tests SUCCESS. `flutter analyze --no-fatal-infos` SUCCESS. `flutter test --dart-define=FLAVOR=dev` SUCCESS (105/105). `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` SUCCESS.

## Session Handoff
- Completed:
    - Reused the existing `WarmthEmptyState` pattern instead of adding a new empty-state widget.
    - Added exact English History empty copy for Matches, Recaps, and Pro Near-Miss states.
    - Routed empty Matches screen content through `historyEmptyTitleKey(...)` so empty copy changes by active History section/filter.
    - Updated Run Recap history empty state to use the Recaps copy with no subtitle.
    - Added regression coverage for section-specific empty-state copy and wiring.
- In Progress: None.
- Blocked: None for this task.
- Next Action:
    1. Device-smoke the History sections as free and pro users to confirm the copy appears in the expected section picker/tab combinations.

## Session State — 2026-05-26 23:44 CEST
- Active Task: Run/Gym/Event defensive crash fixes
- Environment: Dev mobile flavor on `main`; no Firebase/backend/native config changes
- Modified Files:
    - `lib/src/features/dashboard/presentation/run_recap_screen.dart`
    - `lib/src/features/map/presentation/event_recap_screen.dart`
    - `lib/src/features/gym/presentation/gym_mode_sheet.dart`
    - `test/features/dashboard/run_recap_defensive_paths_test.dart`
    - `tasks/context.md`
- Open Problems:
    - Existing unrelated dirty files remain in the worktree and were not reverted.
- System Status: `dart format` SUCCESS. Focused defensive-path test SUCCESS. `flutter analyze --no-fatal-infos` SUCCESS. `flutter test --dart-define=FLAVOR=dev` SUCCESS (104/104). `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` SUCCESS.

## Session Handoff
- Completed:
    - Guarded malformed or missing run recap `userIds` data with `safeRecapUserIdsFromData(...)` so build does not throw on bad Firestore shape.
    - Replaced silent run recap provider error states with logged, centered "Something went wrong." fallback copy.
    - Wrapped run recap wave sending with async error handling and a retry snackbar.
    - Added `.catchError(...)` logging to run and event viewedRecaps close writes.
    - Made gym notification preference saving null-safe when auth disappears mid-dialog.
    - Added focused regression coverage for the defensive paths.
- In Progress: None.
- Blocked: None for this task.
- Next Action:
    1. Have Martin retry Run Club, Gym Mode, and Event Mode taps on the device/build that produced the dark screen.

## Session State — 2026-05-26 23:25 CEST
- Active Task: Near-Miss locked state in Matches
- Environment: Dev mobile flavor on `main`; no Firebase/backend/native config changes
- Modified Files:
    - `lib/src/features/matches/presentation/matches_screen.dart`
    - `lib/src/core/translations.dart`
    - `test/features/match/near_miss_locked_state_test.dart`
    - `tasks/context.md`
- Open Problems:
    - Existing unrelated dirty files remain in the worktree and were not reverted.
- System Status: `dart format` SUCCESS. Focused near-miss test SUCCESS. `flutter analyze --no-fatal-infos` SUCCESS. `flutter test --dart-define=FLAVOR=dev` SUCCESS (101/101). `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` SUCCESS.

## Session Handoff
- Completed:
    - Read `matches_screen.dart` fully and reported how `matchType`, list building, translations, premium state, and `PrimaryButton` import were currently handled.
    - Added test coverage for near-miss activity counting, run upsell gating, EN/SL/HR upsell copy, CTA translations, and source-level UI wiring.
    - Implemented free-user activity near-miss locked cards: blurred avatar, centered lock overlay, `someone_nearby` name, hidden age/zodiac/details, hidden menu/removal actions, and paywall on card tap.
    - Implemented pro-user activity cards as full unblurred cards with trailing menu/removal actions hidden.
    - Added `_NearMissUpsellCard` as the final run-section list item for free users, using the current visible activity-profile count and opening `PremiumPaywallBottomSheet.show(context)`.
    - Added EN/SL/HR `near_miss_upsell_body` and `near_miss_upsell_cta` translations.
- In Progress: None.
- Blocked: None for this task.
- Next Action:
    1. Device-smoke the Run/Near-Miss section as free and pro users to confirm the locked-card tap target and upsell placement feel correct.

## Session State — 2026-05-26 23:18 CEST
- Active Task: MPC v5 prompt replacement
- Environment: Dev / docs on `main`
- Modified Files:
    - `AGENTS.md`
    - `CLAUDE.md`
    - `tasks/context.md`
- Open Problems:
    - None for this task.
- System Status: Documentation-only change; Flutter gates not run.

## Session Handoff
- Completed:
    - Replaced root MPC prompt content in `AGENTS.md` with the provided MPC v5 document exactly.
    - Replaced matching root MPC prompt content in `CLAUDE.md` with the same provided MPC v5 document so both prompt entrypoints remain synchronized.
    - Verified `AGENTS.md` and `CLAUDE.md` have no diff after replacement.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Review and commit the prompt update when ready.

## Session State — 2026-05-26 23:12 CEST
- Active Task: App Store metadata rewrite and checklist updates
- Environment: Dev / Prod docs on `main`
- Modified Files:
    - `tasks/appstore_metadata.md`
    - `tasks/context.md`
- Open Problems:
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Real photo upload/onboarding E2E still needs device verification.
- System Status: `appstore_metadata.md` updated with revised English and Slovenian descriptions. Web page checklist items (Privacy Policy, Terms, Data Erasure) marked as completed/live.

## Session Handoff
- Completed:
    - Replaced English and Slovenian Full Descriptions in `tasks/appstore_metadata.md` with brand-compliant copy.
    - Marked Privacy Policy URL, Terms URL, and Account Erasure URL checklist items in `tasks/appstore_metadata.md` as done (`[x]`).
- In Progress: None.
- Blocked: None for this task.
- Next Action:
    1. Resolve remaining items on the App Store pre-flight checklist.

## Session State — 2026-05-26 15:38 CEST
- Active Task: Radar BLE off / Bluetooth permission denied UI states
- Environment: Dev mobile flavor on `main`; no Firebase/backend/native config changes
- Modified Files:
    - `lib/src/core/ble_service.dart`
    - `lib/src/features/dashboard/presentation/home_screen.dart`
    - `test/core/ble_service_radar_state_test.dart`
    - `test/features/dashboard/radar_ble_issue_message_test.dart`
    - `tasks/context.md`
- Open Problems:
    - Device smoke still needed: toggle Bluetooth off and deny Bluetooth permission on a real Android/iOS device to confirm OS-specific permission/status reporting.
    - Existing unrelated dirty files from previous recap/wave/rules work remain in the worktree and were not reverted.
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Real photo upload/onboarding E2E still needs device verification.
    - BLOCKER-007: Legal web pages not confirmed live.
- System Status: `dart format` SUCCESS. Focused Radar BLE tests SUCCESS. `flutter analyze --no-fatal-infos` SUCCESS. `flutter test --dart-define=FLAVOR=dev` SUCCESS (98/98). `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` SUCCESS.

## Session Handoff
- Completed:
    - Verified `permission_handler` is already present in `pubspec.yaml`.
    - Confirmed Bluetooth adapter state was only checked inside `BleService._runScan()` and not exposed to Radar UI.
    - Added `RadarBleIssue`, `resolveRadarBleIssue(...)`, `bluetoothAdapterStateProvider`, `bluetoothPermissionStatusProvider`, and `radarBleIssueProvider`.
    - Wired Radar to show a centered non-dismissible message when Bluetooth is off: "Bluetooth is off. Tremble needs it to detect people nearby." with "Open Settings" calling `openAppSettings()`.
    - Wired Radar to show a distinct permission state: "Bluetooth permission required." with "Grant Permission" calling `ConsentService.requestBluetooth()`.
    - Ensured these blocker states suppress the normal radar pulse/search UI path and do not render a loading spinner.
    - Added focused resolver and widget tests for both states.
- In Progress: None.
- Blocked:
    - No code blocker. Physical device verification is still required for OS-level Bluetooth/permission behavior.
- Next Action:
    1. Device-smoke Radar with Bluetooth off and Bluetooth permission denied, then confirm the settings/request actions recover when the OS state changes.

## Session State — 2026-05-26 15:27 CEST
- Active Task: Gone Forever free recap viewed flag
- Environment: Dev mobile flavor on `main`; Firestore rules edited locally, not deployed
- Modified Files:
    - `firestore.rules`
    - `lib/src/features/recap/data/viewed_recaps_repository.dart`
    - `lib/src/features/dashboard/presentation/run_recap_screen.dart`
    - `lib/src/features/map/presentation/event_recap_screen.dart`
    - `lib/src/features/matches/presentation/matches_screen.dart`
    - `test/features/recap/viewed_recaps_test.dart`
    - `test/features/recap/viewed_recaps_wiring_test.dart`
    - `tasks/context.md`
- Open Problems:
    - Firestore viewedRecaps rule is local only; it still needs deploy to `tremble-dev` and `am---dating-app` before clients can use it outside permissive/dev contexts.
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Real photo upload/onboarding E2E still needs device verification.
    - BLOCKER-007: Legal web pages not confirmed live.
- System Status: `dart format` SUCCESS. `flutter analyze --no-fatal-infos` SUCCESS. `flutter test --dart-define=FLAVOR=dev` SUCCESS (93/93).

## Session Handoff
- Completed:
    - Read the existing Run Recap history query in `run_club_repository.dart`: `run_encounters/{uid}/encounters`, ordered by `timestamp`, limited to 20.
    - Read the Matches history flow: `matchesStreamProvider` listens to `matches`, hydrates through `getMatches`, and `filteredMatchesProvider` applies `MatchRepository.filterMatches(...)` in memory.
    - Added `ViewedRecapsRepository`, `viewedRecapIdsProvider`, and `shouldHideViewedMatchRecap(...)`.
    - Free users now write `users/{uid}/viewedRecaps/{recapId}` on Run Recap and Event Recap close with `closedAt: FieldValue.serverTimestamp()` and `type: 'run'` or `'event'`; Pro users skip writes.
    - Free users now filter Run Recap history by `doc.id` and Matches history by match/profile/context recap IDs; Pro users use an empty viewed set and see full history.
    - Added Firestore owner-only read/write rule for `users/{uid}/viewedRecaps/{recapId}`.
    - Added focused tests for filtering, wiring, and rules.
- In Progress: None.
- Blocked:
    - Rules deploy was not requested in this task; owner-only viewedRecaps access is not live until deployed.
- Next Action:
    1. Deploy `firestore.rules` to dev/prod when ready, then device-smoke free-user close → viewedRecaps write → history hidden.

## Session State — 2026-05-26 15:15 CEST
- Active Task: Recap TTL provider and premium Run Recap gating
- Environment: Dev mobile flavor on `main`; no backend/Firebase deploy changes
- Modified Files:
    - `lib/src/features/recap/providers/recap_ttl_provider.dart`
    - `lib/src/features/dashboard/presentation/run_recap_screen.dart`
    - `lib/src/features/matches/presentation/matches_screen.dart`
    - `test/features/recap/recap_ttl_provider_test.dart`
    - `test/features/recap/recap_ui_wiring_test.dart`
    - `tasks/context.md`
- Open Problems:
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Real photo upload/onboarding E2E still needs device verification.
    - BLOCKER-007: Legal web pages not confirmed live.
- System Status: `dart format` SUCCESS. `flutter analyze --no-fatal-infos` SUCCESS. `flutter test --dart-define=FLAVOR=dev` SUCCESS (87/87).

## Session Handoff
- Completed:
    - Added `recapTTLProvider`, `RecapTTLState`, and `RecapTTLNotifier` with manual `start()`, one-second countdown, expiry state, and timer disposal.
    - Wired Run Recap to `effectiveIsPremiumProvider`.
    - Made active premium run recap cards start/watch TTL by `partnerId`, show remaining `m:ss`, hide wave action after expiry, and become read-only.
    - Made free run recap cards read-only with grey saturation filter and no wave action.
    - Kept history recap cards read-only with no TTL and full color for premium users.
    - Replaced the locked Matches recap paywall TODO with `PremiumPaywallBottomSheet.show(context)`.
    - Added focused tests for TTL behavior and recap/paywall UI wiring.
- In Progress: None.
- Blocked: None for this task.
- Next Action:
    1. Device smoke test Run Recap active/free/history cards to confirm the visual treatment and countdown feel right in the real UI.

## Session State — 2026-05-26 15:03 CEST
- Active Task: Allow owner reads for Firestore rate limit counters
- Environment: Dev + Prod Firestore rules deploy (`tremble-dev`, `am---dating-app`)
- Modified Files:
    - `firestore.rules`
    - `tasks/context.md`
- Open Problems:
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Real photo upload/onboarding E2E still needs device verification.
    - BLOCKER-007: Legal web pages not confirmed live.
- System Status: Firestore rules deployed successfully to `tremble-dev` and `am---dating-app`. `flutter analyze --no-fatal-infos` SUCCESS.

## Session Handoff
- Completed:
    - Read existing `rateLimits` rule block before editing.
    - Replaced the deny-all read/write rule with owner-only reads for docs whose ID starts with `request.auth.uid + ':'`; writes remain denied.
    - Deployed `firestore.rules` to dev project `tremble-dev`.
    - Deployed `firestore.rules` to prod project `am---dating-app`.
    - Verified Flutter analyzer gate.
- In Progress: None.
- Blocked: None for rate-limit owner-read rules.
- Next Action:
    1. Device/app smoke test signed-in client read of `rateLimits/{uid}:wave_monthly.count` and confirm free paywall guard triggers at count `>= 5`.

## Session State — 2026-05-26 15:00 CEST
- Active Task: Source `AuthUser.wavesThisMonth` from rate limit counter
- Environment: Dev mobile flavor on `main`; no Cloud Functions/backend code changes
- Modified Files:
    - `lib/src/features/auth/data/auth_repository.dart`
    - `test/features/auth/auth_user_wave_limit_test.dart`
    - `tasks/context.md`
- Open Problems:
    - `firestore.rules` currently denies all reads to `rateLimits/{doc}` (`allow read, write: if false`). The client-side read of `rateLimits/{uid}:wave_monthly.count` will return `0` until rules explicitly allow the signed-in owner to read their own wave-monthly rate-limit document.
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Real photo upload/onboarding E2E still needs device verification.
    - BLOCKER-007: Legal web pages not confirmed live.
- System Status: `dart format` SUCCESS. `flutter analyze --no-fatal-infos` SUCCESS. `flutter test --dart-define=FLAVOR=dev` SUCCESS (83/83).

## Session Handoff
- Completed:
    - Verified backend format: `sendWave` calls `checkRateLimit(uid, "wave_monthly", ...)`, and `checkRateLimit` writes document ID `${uid}:${endpoint}` in `rateLimits`, so the literal client document ID is `{uid}:wave_monthly`.
    - Read current auth hydration: `authStateChanges()` calls `_fetchUser(firebaseUser)`, which previously read only `users/{uid}` and passed that data into `AuthUser.fromFirestore(...)`.
    - Added `waveMonthlyRateLimitDocId(uid)` and `waveCountFromRateLimitData(...)`.
    - Updated `_fetchUser` to read `rateLimits/{uid}:wave_monthly` and pass its `count` to `AuthUser.fromFirestore(..., wavesThisMonth: count)`.
    - Updated tests so `users/{uid}.wavesThisMonth` is ignored and `rateLimits/{uid}:wave_monthly.count` is the source for `AuthUser.wavesThisMonth`.
- In Progress: None.
- Blocked:
    - Client read is blocked by current Firestore rules unless a follow-up rules change is approved and deployed.
- Next Action:
    1. Decide whether to update Firestore rules to allow `request.auth.uid + ":wave_monthly"` owner reads under `rateLimits`.

## Session State — 2026-05-26 14:45 CEST
- Active Task: Client-side free Wave limit paywall guard
- Environment: Dev mobile flavor on `main`; no backend/Firebase deploy changes
- Modified Files:
    - `lib/src/features/auth/data/auth_repository.dart`
    - `lib/src/features/profile/presentation/profile_detail_screen.dart`
    - `lib/src/features/matches/presentation/match_dialog.dart`
    - `lib/src/core/router.dart`
    - `test/features/auth/auth_user_wave_limit_test.dart`
    - `test/features/match/wave_limit_guard_wiring_test.dart`
    - `tasks/context.md`
- Open Problems:
    - `AuthUser.wavesThisMonth` now reads `users/{uid}.wavesThisMonth`; client-side UX depends on that field being present/fresh in Firestore. Server-side `sendWave` remains authoritative and unchanged.
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Real photo upload/onboarding E2E still needs device verification.
    - BLOCKER-007: Legal web pages not confirmed live.
- System Status: `dart format` SUCCESS. `flutter analyze --no-fatal-infos` SUCCESS. `flutter test --dart-define=FLAVOR=dev` SUCCESS (82/82).

## Session Handoff
- Completed:
    - Confirmed branch is `main`.
    - Read `AuthUser` model exposure for `isPremium`; confirmed `wavesThisMonth` was not previously exposed.
    - Read `PremiumPaywallBottomSheet.show(BuildContext context)` and existing `PremiumPaywallBottomSheet.show(context)` call site.
    - Added `AuthUser.wavesThisMonth`, default `0`, Firestore parsing, copyWith support, and `hasReachedFreeWaveLimit`.
    - Added client-side pre-checks before `sendWave` paths in Profile Detail, Match Dialog, and foreground Wave Pill callback. Free users with `wavesThisMonth >= 5` see `PremiumPaywallBottomSheet.show(context)` and do not call `sendWave`.
    - Added targeted tests for AuthUser wave-limit behavior and Wave UI guard wiring.
- In Progress: None.
- Blocked: None for this client-side UX guard.
- Next Action:
    1. Confirm Firestore user documents maintain a fresh `wavesThisMonth` value; otherwise this guard will only work when that field is populated client-side.

## Session State — 2026-05-26 14:31 CEST
- Active Task: B009 — Wire foreground FCM waves to WavePillService
- Environment: Dev mobile flavor on `main`; no Firebase/backend/deploy changes
- Modified Files:
    - `lib/src/core/router.dart`
    - `test/core/router_foreground_wave_wiring_test.dart`
    - `tasks/context.md`
- Open Problems:
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Real photo upload/onboarding E2E still needs device verification.
    - BLOCKER-007: Legal web pages not confirmed live.
- System Status: `dart format` SUCCESS. `flutter analyze --no-fatal-infos` SUCCESS. `flutter test --dart-define=FLAVOR=dev` SUCCESS (78/78).

## Session Handoff
- Completed:
    - Confirmed current git branch is `main`.
    - Read `WavePillService.show`, `WavePillData`, `NotificationService.initialize` callback signatures, and the current `NotificationService.initialize(...)` call before editing.
    - Added `onForegroundWave` to `NotificationService.initialize(...)` in `router.dart`.
    - Callback now gets `rootNavigatorKey.currentContext`, resolves `Overlay.of(context)`, calls `WavePillService.show(...)` with `WavePillData`, and wires `onWave` to `ref.read(waveRepositoryProvider).sendWave(uid)`.
    - Added regression coverage for the router foreground wave wiring.
- In Progress: None.
- Blocked: None for B009.
- Next Action:
    1. Device smoke test foreground `INCOMING_WAVE` / `CROSSING_PATHS` FCM payloads and confirm the pill appears above the active route.

## Session State — 2026-05-26 14:26 CEST
- Active Task: B008 — Verify production Firestore rules
- Environment: Prod verification (`am---dating-app`), read-only Firebase Rules API; no deploy
- Modified Files:
    - `tasks/context.md`
- Open Problems:
    - Requested `firebase firestore:rules:get --project am---dating-app` is not supported by installed `firebase-tools` 15.18.0.
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Real photo upload/onboarding E2E still needs device verification.
    - BLOCKER-007: Legal web pages not confirmed live.
- System Status: Prod Firestore rules verified read-only via Firebase Rules API. Active release `projects/am---dating-app/releases/cloud.firestore` points to ruleset `projects/am---dating-app/rulesets/61ff6999-670d-4d71-9c66-db6816a7d94f`, updated `2026-05-24T21:43:51.433801Z`.

## Session Handoff
- Completed:
    - Confirmed current git branch is `main`.
    - Ran the exact requested Firebase CLI command and captured its failure output: the installed CLI does not include `firestore:rules:get`.
    - Fetched the active production Firestore rules release and active ruleset via Firebase Rules API.
    - Confirmed the deployed `/active_run_crosses/{docId}` block is present and matches local `firestore.rules` lines 120-124 exactly.
- In Progress: None.
- Blocked: None for B008 verification.
- Next Action:
    1. Continue with the next planned stabilization item on `main`.

## Session State — 2026-05-26 14:20 CEST
- Active Task: Fix recap profile navigation route extra
- Environment: Dev mobile flavor; no Firebase/backend/runtime deploy changes
- Modified Files:
    - `lib/src/features/dashboard/presentation/run_recap_screen.dart`
    - `test/features/dashboard/run_recap_navigation_test.dart`
- Open Problems:
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Real photo upload/onboarding E2E still needs device verification.
    - BLOCKER-007: Legal web pages not confirmed live.
- System Status: `dart format` SUCCESS. `flutter analyze --no-fatal-infos` SUCCESS. `flutter test --dart-define=FLAVOR=dev` SUCCESS (77/77).

## Session Handoff
- Completed:
    - Read `lib/src/core/router.dart` before editing and confirmed `/profile` expects `state.extra as MatchProfile?`.
    - Checked `event_recap_screen.dart`; no broken `/profile/:id` navigation call exists there.
    - Replaced run recap `/profile/${partnerId}` navigation with `/profile` plus a `MatchProfile` extra converted from the loaded `PublicProfile`.
    - Added regression coverage for the `PublicProfile` to `MatchProfile` route-extra conversion.
- In Progress: None.
- Blocked: None for this navigation fix.
- Next Action:
    1. Commit the navigation fix after review, or run device smoke verification by tapping a Run Recap partner card.

## Session State — 2026-05-25 01:22 CEST
- Active Task: Control-plane documentation synchronization
- Environment: Dev/docs only; no Firebase or app runtime changes
- Modified Files:
    - `AGENTS.md`
    - `BOOTSTRAP.md`
    - `CLAUDE.md`
    - `GEMINI-app.md`
    - `README.md`
    - `Tremble MPC Workflow.md`
    - `tasks/MASTER_PLAN.md`
    - `tasks/todo.md`
    - `tasks/system_map.md`
    - `tasks/appstore_metadata.md`
    - `tasks/debt.md`
    - `tasks/decisions/ADR-001-ble-proximity-engine.md`
    - `tasks/decisions/ADR-006-node-22-migration.md`
    - `tasks/lessons.md`
    - `tasks/context.md`
- Open Problems:
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Real photo upload/onboarding E2E still needs device verification.
    - BLOCKER-007: Legal web pages not confirmed live.
    - Firebase Console follow-up remains: verify expected newly-created prod functions from the latest deploy.
- System Status: Documentation-only changes. No Flutter/backend tests run for this docs sync. Previous pre-commit dry-run on 2026-05-25 passed all Flutter and backend gates.

## Session Handoff
- Completed:
    - Added and verified local `.git/hooks/pre-commit` dry-run before this docs sync.
    - Updated root agent/bootstrap docs with current blockers, Node 22 backend setup, dev-flavor commands, and local pre-commit gate.
    - Updated `tasks/MASTER_PLAN.md`, `tasks/todo.md`, `tasks/system_map.md`, `tasks/appstore_metadata.md`, `tasks/debt.md`, and relevant ADRs to remove stale ADR-001/App Check/Node 20/map-in-progress references.
    - Added lessons for bundled map-style ownership, light frosted overlays on light basemaps, and map-style color literal validation.
- In Progress: None.
- Blocked: None for documentation sync.
- Next Action:
    1. Verify in Firebase Console that expected newly-created prod functions are intentional.
    2. Resolve or schedule BLOCKER-006 real photo upload/onboarding E2E verification on `tremble-dev`.

## Session State — 2026-05-25 00:25 CEST
- Active Task: Gate `migrateMatchTypes` callable behind admin auth
- Environment: Prod backend deploy (`am---dating-app`), functions only
- Modified Files:
    - `functions/src/modules/matches/matches.functions.ts`
- Open Problems:
    - No migration tracking flag or commit evidence was found proving `migrateMatchTypes` already ran in prod.
    - `firebase deploy --only functions --project prod --non-interactive` created several functions that were exported in code but apparently not yet present in prod; deploy completed successfully.
- System Status: `npm run build` SUCCESS. `npm run lint` SUCCESS. `npm test -- --runInBand` SUCCESS (14/14). Functions deploy SUCCESS to `am---dating-app`. Firestore rules were not deployed.

## Session Handoff
- Completed:
    - Checked git history, codebase references, and function comments for evidence that `migrateMatchTypes` had already been executed or tracked; no reliable evidence found.
    - Treated the migration as potentially still needed and added `requireAdmin(request)` at the top of `migrateMatchTypes`.
    - Deployed functions only to prod with `firebase deploy --only functions --project prod --non-interactive`.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Verify in Firebase Console that expected newly-created prod functions are intentional and remove any stale exports if not needed.

## Session State — 2026-05-24 23:05 CEST
- Active Task: Firebase Functions and Firestore security audit implementation
- Environment: Dev backend audit (`tremble-dev` context), no deploy
- Modified Files:
    - `firestore.rules`
    - `functions/src/middleware/validate.ts`
    - `functions/src/modules/events/events.functions.ts`
    - `functions/src/modules/gym/gym.functions.ts`
    - `functions/src/modules/matches/intercept.functions.ts`
    - `functions/src/modules/matches/matches.functions.ts`
    - `functions/src/modules/proximity/proximity.functions.ts`
    - `functions/src/modules/safety/safety.schema.ts`
    - `functions/src/modules/users/users.functions.ts`
- Open Problems:
    - `npm audit fix` reduced backend audit findings to 9 moderate vulnerabilities. Remaining npm recommendation is `npm audit fix --force`, which would downgrade `firebase-admin` to `10.3.0` and `firebase-functions` to `4.9.0`; not applied because it is a breaking downgrade path.
    - `verifyGoogleToken` intentionally remains unauthenticated because it is called during login before the user has a Firebase auth token.
    - None blocking deploy; Firebase CLI update check still exits nonzero on `firebase --version` because `/Users/aleksandarbojic/.config` ownership blocks update-check metadata.
- System Status: `npm run build` SUCCESS. `npm run lint` SUCCESS. `npm test -- --runInBand` SUCCESS (14/14). `npm audit --json` reports 0 critical, 0 high, 9 moderate. `firebase deploy --only firestore:rules --project prod --non-interactive` SUCCESS: rules released to `am---dating-app`.

## Session Handoff
- Completed:
    - Ran `npm audit --json` and `npm audit fix --dry-run --json` from `functions/`.
    - Added shared `assertValidDocumentId()` guard and applied CRITICAL path validation fixes for request-supplied Firestore document IDs.
    - Rewrote `firestore.rules` to enforce own-user reads, deny client proximity reads, restrict waves/sessions, and preserve default deny.
    - Added structured JSON logging to high-priority proximity, wave, match, and Pulse Intercept flows without logging GPS coordinates, profiles, tokens, or emails.
    - Upgraded `firebase-admin` to `13.10.0`, `firebase-functions` to `7.2.5`, then ran `npm audit fix`.
    - Verified TypeScript build, ESLint, and Jest.
    - Updated Firebase CLI to `15.18.0` and deployed Firestore rules to production project `am---dating-app`.
- In Progress: None.
- Blocked:
    - None.
- Next Action:
    1. Review remaining 9 moderate npm audit findings; avoid `npm audit fix --force` unless intentionally downgrading Firebase SDK major versions.

## Session State — 2026-05-23 01:35 CEST
- Active Task: Premium loading states and outage/error handling overhaul
- Environment: Dev mobile flavor on `main`
- Modified Files:
    - `lib/main.dart`
    - `lib/src/shared/ui/tremble_loading_spinner.dart`
    - `lib/src/shared/ui/tremble_outage_screen.dart`
    - `lib/src/shared/ui/primary_button.dart`
    - `lib/src/features/dashboard/presentation/home_screen.dart`
    - `lib/src/features/settings/presentation/settings_screen.dart`
    - `lib/src/features/match/presentation/match_reveal_screen.dart`
    - `lib/src/core/translations.dart`
    - `test/shared/ui/tremble_loading_spinner_test.dart`
    - `test/shared/ui/tremble_outage_screen_test.dart`
- Open Problems:
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Real photo upload/onboarding E2E still needs device verification.
    - BLOCKER-007: Legal web pages not confirmed live.
- System Status: `dart format --set-exit-if-changed .` SUCCESS. `flutter analyze --no-fatal-warnings` SUCCESS. `flutter analyze --no-fatal-infos` SUCCESS. `flutter test --dart-define=FLAVOR=dev` SUCCESS (75/75). `flutter test --coverage` SUCCESS (75/75). `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` SUCCESS. `flutter build apk --flavor dev --dart-define=FLAVOR=dev` SUCCESS. Backend lint/build/tests SUCCESS.

## Session Handoff
- Completed:
    - Enabled global Firestore offline persistence with unlimited local cache after Firebase initialization.
    - Added `TrembleLoadingSpinner` with simple/dynamic modes, animated message cycling, and a >10s linear fallback.
    - Added `TrembleOutageScreen` with component status rows, retry countdown, haptic retry cues, manual retry, and settings actions via existing `openAppSettings()`.
    - Updated `PrimaryButton` quick loading behavior to disable and fade instead of showing a spinner.
    - Replaced radar partner-profile, match reveal, and delete-account modal loaders with Tremble loading components.
    - Added timeout protection to delete-account backend call.
    - Added loading/outage translation keys across all 8 supported languages.
    - Added widget tests for loading spinner and outage screen behavior.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Manual UX verification on device: simulate network loss and denied permissions to validate outage copy, haptics, and settings deep-link behavior.

## Session State — 2026-05-23 00:45 CEST
- Active Task: CI/CD release build cleanup and main sync
- Environment: Dev mobile flavor on `main`
- Modified Files:
    - `.github/workflows/deploy.yml`
    - `android/build.gradle.kts`
    - `android/settings.gradle.kts`
- Open Problems:
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Real photo upload/onboarding E2E still needs device verification.
    - BLOCKER-007: Legal web pages not confirmed live.
- System Status: `dart format --set-exit-if-changed .` SUCCESS. `flutter analyze --no-fatal-warnings` SUCCESS. `flutter analyze --no-fatal-infos` SUCCESS. `flutter test --dart-define=FLAVOR=dev` SUCCESS (71/71). `flutter test --coverage` SUCCESS (71/71). `flutter build apk --flavor dev --dart-define=FLAVOR=dev` SUCCESS. Backend lint/build/tests SUCCESS.

## Session Handoff
- Completed:
    - Fixed Android release dev APK build failure by upgrading the Google Services Gradle plugin declarations from `4.3.15` to `4.4.1`, satisfying Crashlytics Gradle plugin 3 requirements.
    - Fixed manual deploy APK build to pass the required Flutter flavor and upload the correct flavored release artifact path.
    - Verified local equivalents of PR and push CI gates before syncing.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Watch GitHub Actions after push and confirm remote CI completes.

## Session State — 2026-05-22 16:25 CEST
- Active Task: Bottom Nav highlight on Premium Map, Panning lock & Copywriting updates
- Environment: Dev mobile flavor on `main`
- Modified Files:
    - `lib/src/shared/ui/liquid_nav_bar.dart`
    - `lib/src/features/dashboard/presentation/home_screen.dart`
    - `lib/src/core/translations.dart`
- Open Problems:
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Real photo upload/onboarding E2E still needs device verification.
    - BLOCKER-007: Legal web pages not confirmed live.
- System Status: `flutter analyze` SUCCESS (0 issues). `flutter test` SUCCESS (71/71).

## Session Handoff
- Completed:
    - Added modular `itemWrapper` builder callback inside `LiquidNavBar` to wrap navigation bar icons.
    - Mapped premium navigation items for Map, Recap/Near-Miss, and Settings tabs dynamically to spotlight tutorial targets inside `HomeScreen`.
    - Protected active Premium Map view from horizontal swipe tab transitions by disabling page drag-switching gestures when Map view is active, freeing map panning gestures.
    - Updated `tutorial_step2_desc` translation strings in English, Slovenian, and Croatian.
    - Fixed step 3 premium tutorial title to `"Your Matches"` / `"Tvoja Ujemanja"` / `"Tvoji Spoji"` and rewrote the description copywriting to introduce past matches, gyms, events, and runs.
    - Ran static code checks (`flutter analyze`) and full widget/integration tests (`71/71 tests passed`) with zero issues.
- In Progress: None.
- Blocked: None.
- Next Action:
    1. Visual and interaction verification on physical device/emulator. Run the app with: `flutter run --dart-define-from-file=.env.json`

## Session State — 2026-05-21 22:00 CEST
- Active Task: Foreground wave pill — animation overhaul + OverlayEntry service
- Environment: Dev mobile flavor on `main`
- Modified Files:
    - `lib/src/features/match/presentation/widgets/match_notification_pill.dart` (full rewrite)
    - `lib/src/shared/ui/wave_pill_service.dart` (new)
    - `lib/src/core/notification_service.dart` (onForegroundWave callback)
    - `tasks/context.md`
- Open Problems:
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Real photo upload/onboarding E2E still needs device verification.
    - BLOCKER-007: Legal web pages not confirmed live.
- System Status: `flutter analyze` SUCCESS (0 issues). `flutter test` SUCCESS (71/71).

## Session Handoff
- Completed:
    - Full rewrite of `MatchNotificationPill`: drop-then-expand entrance, shake+haptic on wave tap, rainbow SweepGradient border on success, auto-dismiss after 3s, slide-up on ignore. Solid dark colors (no glassmorphism).
    - New `WavePillService`: static `show()` / `dismiss()` managing a global `OverlayEntry`. Replaces any active pill before inserting a new one.
    - `NotificationService.initialize()` gains `onForegroundWave` callback; INCOMING_WAVE and CROSSING_PATHS foreground messages now route to the pill (suppressing the OS banner) when the callback is wired.
- In Progress: None.
- Blocked: FCM → pill wiring in `home_screen.dart` is not yet done (see Next Action).
- Next Action:
    1. In `HomeScreen.initState`, pass `onForegroundWave` to `NotificationService.initialize()` and call `WavePillService.show(Overlay.of(context), ...)`. Cloud Functions must also emit `senderName`, `senderAge`, `senderPhotoUrl` in FCM data payloads for the pill to receive them.
- Open Problems:
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Real photo upload/onboarding E2E still needs device verification after App Check debug token is registered.
    - BLOCKER-007: Legal web pages not confirmed live.
- System Status: `dart format` SUCCESS. `flutter analyze` SUCCESS. `flutter test` SUCCESS (71/71). `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` SUCCESS.

## Session Handoff
- Completed:
  - Located and mapped the match notification codebase across both backend Cloud Functions and the Flutter app client.
- In Progress: None.
- Blocked: None.
- Next Action:
  1. Answer the user's question regarding the location of the match notification code.

## Session State — 2026-05-21 09:19 CEST
- Active Task: Premium card redesign
- Environment: Dev mobile flavor on `main`
- Modified Files:
    - `lib/src/features/settings/presentation/premium_screen.dart`
    - `test/features/settings/premium_screen_test.dart`
    - `tasks/context.md`
- Open Problems:
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Real photo upload/onboarding E2E still needs device verification after App Check debug token is registered.
    - BLOCKER-007: Legal web pages not confirmed live.
- System Status: `dart format` SUCCESS. `flutter analyze` SUCCESS. `flutter test` SUCCESS (71/71). `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` SUCCESS.

## Session Handoff
- Completed:
  - Split the old Duration Matrix card into separate Yearly Access and Lifetime Access cards; carousel now has 5 cards.
  - Added `perMonthPrice`, `billedAs`, and `savingsBadge` fields to `PremiumPlanCard`.
  - Updated Yearly display to lead with `5,00 € / mesec`, show billed-as copy, and render a savings badge.
  - Added the deep amber Lifetime card and 5-card CTA color/index handling.
  - Preserved the jitter fix: no `setState` in `PageController` listener, carousel/dots stay inside `AnimatedBuilder`, and animated cards keep `RepaintBoundary`.
  - Updated premium card ordering/pricing regression test.
- In Progress: None.
- Blocked:
  - Visual confirmation still needs the new dev APK installed and swiped on a physical Samsung device.
- Next Action:
  1. Install `build/app/outputs/flutter-apk/app-dev-debug.apk` and verify the 5-card premium carousel visually on device.

## Session State — 2026-05-21 09:06 CEST
- Active Task: Premium carousel jitter remediation
- Environment: Dev mobile flavor on `main`
- Modified Files:
    - `lib/src/features/settings/presentation/premium_screen.dart`
    - `tasks/context.md`
- Open Problems:
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Real photo upload/onboarding E2E still needs device verification after App Check debug token is registered.
    - BLOCKER-007: Legal web pages not confirmed live.
- System Status: `dart format` SUCCESS. `flutter analyze` SUCCESS. `flutter test` SUCCESS (71/71). `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` SUCCESS.

## Session Handoff
- Completed:
  - Removed per-scroll-frame `setState` from `PremiumUpgradeScreen`; the page listener now only updates selected CTA state and haptics when the snapped page changes.
  - Moved carousel animation and dots into `_PremiumCarousel` with an `AnimatedBuilder`, keeping header, subtitle, dialog copy, and CTA outside per-frame rebuilds.
  - Added `RepaintBoundary` around each animated card and kept the `PageView` as a lightweight gesture target.
  - Cached premium screen `GoogleFonts` text styles as `late final` fields.
- In Progress: None.
- Blocked:
  - Visual/performance confirmation still needs the new dev APK installed and swiped on the Samsung test device.
- Next Action:
  1. Install the new dev APK on Samsung and verify Premium carousel swipe smoothness plus Crashlytics silence.

## Session State — 2026-05-21 08:58 CEST
- Active Task: BLOCKER-006 backend contract fix + Crashlytics triage
- Environment: Dev backend (`tremble-dev`) + dev mobile flavor
- Modified Files:
    - `functions/src/modules/auth/auth.schema.ts`
    - `functions/src/modules/users/users.schema.ts`
    - `functions/src/__tests__/auth.test.ts`
    - `functions/src/__tests__/users.test.ts`
    - `lib/main.dart`
    - `lib/src/core/crash_filter.dart`
    - `lib/src/features/settings/presentation/premium_screen.dart`
    - `test/core/crash_filter_test.dart`
    - `tasks/blockers.md`
    - `tasks/context.md`
- Open Problems:
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Real photo upload/onboarding E2E still needs device/simulator verification after App Check debug token is registered.
    - BLOCKER-007: Legal web pages not confirmed live.
- System Status: `dart format` SUCCESS. `flutter analyze` SUCCESS. `flutter test` SUCCESS (71/71). `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` SUCCESS. `npm test -- --runInBand` SUCCESS (14/14). `npm run build` SUCCESS. `completeOnboarding` and `updateProfile` deployed to `tremble-dev`.

## Session Handoff
- Completed:
  - Added regression tests proving real Flutter `interestedIn: List<String>` payloads are accepted by onboarding and profile-update schemas.
  - Fixed backend `interestedIn` schema normalization for both `completeOnboardingSchema` and `updateProfileSchema`; legacy `"both"` now normalizes to `["male", "female"]`.
  - Deployed fixed `completeOnboarding` and `updateProfile` Cloud Functions to `tremble-dev`.
  - Added `CrashFilter` and wired `FlutterError.onError` to suppress benign `vector_map_tiles` cancellation errors instead of recording them as fatal Crashlytics events.
  - Hardened `PremiumUpgradeScreen` by making `_pageController` nullable, guarding listener/build/dispose paths, and preventing `LateInitializationError` from becoming fatal.
- In Progress: None.
- Blocked:
  - Photo upload E2E still requires a real authenticated app run with App Check debug token registered in Firebase Console.
- Next Action:
  1. Register the Android App Check debug token from Logcat, then run full registration with a real image and verify R2 `publicUrl` lands in `/users/{uid}.photoUrls`.
  2. Build/distribute a new dev APK so Crashlytics cancellation filtering and premium lifecycle hardening reach the Samsung device.

## Session State — 2026-05-21 08:47 CEST
- Active Task: Production-readiness triage — photo upload E2E, settings debounce, prod rules, launch blockers
- Environment: Dev + Prod rules (`tremble-dev`, `am---dating-app`)
- Modified Files:
    - `tasks/blockers.md`
    - `tasks/context.md`
- Open Problems:
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - BLOCKER-006: Photo upload / onboarding E2E not verified; backend schema mismatch found.
    - BLOCKER-007: Legal web pages not confirmed live.
- System Status: `firebase functions:list --project tremble-dev` confirms `generateUploadUrl` is deployed. `firebase deploy --only firestore:rules --project am---dating-app` SUCCESS. `npm test -- --runInBand` in `functions/` SUCCESS (12/12), but current tests do not cover Flutter's real `interestedIn` list payload.

## Session Handoff
- Completed:
  - Deployed `active_run_crosses` Firestore rules to production project `am---dating-app`.
  - Confirmed `generateUploadUrl` exists on `tremble-dev` as a v2 callable in `europe-west1`.
  - Verified Settings debounce test only proves `SettingsController.updateIntrovertScale()` debounces when called; current visible Settings range rows use modal Save and do not call that method on drag.
  - Found onboarding schema mismatch: Flutter sends `interestedIn` as `List<String>` via `AuthUser.toApiPayload()`, while backend `completeOnboardingSchema` expects `z.enum(...)`.
  - Checked HR translation parity: HR has 606 keys vs EN 685 in a quick key-count script; missing vs EN reported as 80 keys, not 13, so translation coverage needs a proper audited fix.
  - Confirmed local website sources include privacy and erasure pages, but live `trembledating.com` publication was not verified in this session.
- In Progress: None.
- Blocked:
  - Photo upload E2E remains unverified until schema mismatch is fixed and a real authenticated app flow is run.
  - App Check debug token still requires Firebase Console entry from Logcat before dev Cloud Function calls can be fully trusted from device.
- Next Action:
  1. Approve implementation plan for BLOCKER-006: add failing backend schema test for Flutter payload, fix `completeOnboardingSchema` / `updateProfileSchema` interestedIn handling, run functions + Flutter tests, deploy functions to `tremble-dev`, then run real photo registration E2E.

## Session State — 2026-05-21 08:21 CEST
- Active Task: PR #153 blocker cleanup — CI isolation, active run crosses rules, registration/settings slider safeguards
- Environment: Dev (`tremble-dev`, mobile flavor `com.pulse`)
- Modified Files:
    - `firestore.rules`
    - `lib/src/features/auth/data/auth_repository.dart`
    - `lib/src/features/settings/presentation/settings_controller.dart`
    - `test/features/auth/registration_flow_test.dart`
    - `test/features/dashboard/navigation_bounds_test.dart`
    - `tasks/context.md`
- Open Problems:
    - BLOCKER-003: RevenueCat/legal remains open.
    - BLOCKER-005: iOS dev provisioning for `com.pulse` remains open.
    - App Check debug token still requires manual Firebase Console entry from device Logcat.
- System Status: `dart format` SUCCESS. `flutter analyze` SUCCESS. `flutter test` SUCCESS (69/69). `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` SUCCESS. Firestore rules deployed to `tremble-dev`.

## Session Handoff
- Completed:
  - Added isolated `navIndexProvider` overrides to all `navigation_bounds_test.dart` ProviderContainers.
  - Added Firestore rules for `active_run_crosses`: authenticated reads only for users in `resource.data.userIds`; all client writes denied.
  - Deployed updated Firestore rules to dev project `tremble-dev`.
  - Verified `android/app/src/dev/google-services.json` exists.
  - Preserved and verified existing local slider changes: `AuthUser.fromFirestore()` uses `SliderNormalizer.toNewFormat(...)`; Settings introvert updates debounce the backend write after 800 ms.
- In Progress: None.
- Blocked:
  - App Check debug token must still be added manually in Firebase Console from Logcat output.
  - Production rules were not deployed; only `tremble-dev` was updated to avoid implicit prod changes.
- Next Action:
  1. Add the Android App Check debug token in Firebase Console for the dev app.
  2. If production `active_run_crosses` is currently broken, explicitly approve a prod Firestore rules deploy to `am---dating-app`.

## Session State — 2026-05-20 15:00 CEST (Session 46)
- Active Task: Deploy Cloudflare Worker & map validation
- Environment: Dev (mobile: com.pulse)
- Modified Files:
    - `cloudflare-maps-worker/src/index.ts` (R2 type guard + R2GetOptions)
    - `tasks/lessons.md` (full rewrite: deduped rules, removed stale section, added Rule #67)
    - `tasks/todo.md` (updated to V4 with check marks on completed map tasks)
    - `tasks/context.md`
- Open Problems: BLOCKER-003 (RevenueCat/legal), BLOCKER-005 (iOS dev provisioning).
- System Status: `flutter analyze` SUCCESS. `flutter test` SUCCESS (68/68). `npx tsc` SUCCESS. `npm run biome-check` SUCCESS. Worker deployed successfully.

## Session Handoff
- Completed:
  - Fixed Cloudflare Worker TS error: `R2ObjectBody | R2Object` type narrowed with `"body" in resp` guard.
  - Fixed `options: any` → `options: R2GetOptions` to satisfy Biome linter.
  - Ran `biome check --apply-unsafe` to clean up STYLE_JSON key formatting.
  - Deployed `tremble-maps-worker` live to Cloudflare: `https://tremble-maps-worker.ams-solutions-d-o-o.workers.dev`.
  - Added and verified custom domain `maps.trembledating.com`, serving custom styles and PMTiles live.
  - Verified `tremble_dark_style.json` is served correctly with custom theme styling.
  - Confirmed `planet.pmtiles` database is uploaded by Martin.
  - Cleaned up the `tasks/` folder: archived completed plans, deleted duplicate plan, and rewrote `tasks/lessons.md`.
- In Progress: None.
- Blocked:
  - BLOCKER-003: RevenueCat/legal (company registration required).
  - BLOCKER-005: iOS provisioning for `com.pulse`.
- Next Action:
  1. Run the mobile app (`flutter run --dart-define-from-file=.env.json`) on a device/simulator to visually inspect the premium dark map styling.



## Session State — 2026-05-19 CEST (Session 44)
- Active Task: Protomaps Apple Maps styling & edge worker deployment roadmap
- Environment: Dev (website: tremble-website & mobile: com.pulse)
- Modified Files: tasks/context.md
- Open Problems: BLOCKER-003 (RevenueCat/legal), BLOCKER-005 (iOS dev provisioning).
- System Status: Dev server is running. Web sandbox verified. CORS configs correct.

## Session Handoff
- Completed:
  - Formulated the comprehensive 5-step roadmap for Tremble dark map engine deployment.
  - Explained the futureproofing and scalability of the hybrid vector-raster approach.
  - Documented where the style JSON must be placed (Website public dir and Cloudflare Worker setting).
- In Progress: Waiting for founder review of the styling deployment roadmap.
- Blocked:
  - BLOCKER-003: RevenueCat/legal.
  - BLOCKER-005: iOS provisioning for `com.pulse`.
- Next Action:
  1. Founder updates the Cloudflare Worker with `tremble_dark_style.json`.
  2. Sync Flutter client map settings to point to the production map style in both dev and prod if desired.

## Session State — 2026-05-19 00:33 CEST (Session 41)
- Active Task: ADR-007 TrembleMotion implementation — completed locally
- Environment: Dev
- Modified Files:
    - `lib/src/core/motion.dart`
    - `lib/src/features/match/presentation/match_reveal_screen.dart`
    - `test/core/motion_test.dart`
    - `tasks/context.md`
- Open Problems: BLOCKER-003 (RevenueCat/legal), BLOCKER-005 (iOS dev provisioning).
- System Status: `dart format` SUCCESS. `flutter analyze` SUCCESS. `flutter test` SUCCESS (68/68).

## Session Handoff
- Completed:
  - Added `TrembleMotion` in `lib/src/core/motion.dart` with ADR-007 curves and standard durations.
  - Applied `TrembleMotion.theatricalReveal` and `TrembleMotion.theatrical` to the Match Reveal content entrance.
  - Added focused tests covering the motion curves and durations.
- In Progress: None.
- Blocked:
  - BLOCKER-003: Real purchase flow and subscription persistence remain blocked by RevenueCat/legal setup.
  - BLOCKER-005: Physical iOS verification remains blocked by provisioning for `com.pulse`.
- Next Action:
  1. Visually verify the Match Reveal entrance timing on a physical Android device; iPhone verification remains blocked until provisioning is fixed.

## Session State — 2026-05-18 23:50 CEST (Session 40)
- Active Task: Loader and error color cleanup — completed locally
- Environment: Dev
- Modified Files:
    - `lib/src/core/theme.dart`
    - `lib/src/features/dashboard/presentation/run_recap_screen.dart`
    - `lib/src/features/match/presentation/match_reveal_screen.dart`
    - `lib/src/features/safety/presentation/blocked_users_screen.dart`
    - `tasks/context.md`
- Open Problems: BLOCKER-003 (RevenueCat/legal), BLOCKER-005 (iOS dev provisioning).
- System Status: `dart format` SUCCESS. `flutter analyze` SUCCESS. `flutter test` SUCCESS (66/66).

## Session Handoff
- Completed:
  - Added a neutral `progressIndicatorTheme` so default loaders use white30 in dark mode and black26 in light mode.
  - Removed explicit Rose loader colors from Blocked Users, Run Recap, and Match Reveal loading states.
  - Replaced the Match Reveal profile error icon color with `TrembleTheme.roseDark`.
  - Neutralized the Match Reveal image loading spinner from signal yellow to white30.
- In Progress: None.
- Blocked:
  - BLOCKER-003: Real purchase flow and subscription persistence remain blocked by RevenueCat/legal setup.
  - BLOCKER-005: Physical iOS verification remains blocked by provisioning for `com.pulse`.
- Next Action:
  1. Visually verify neutral loaders in Blocked Users, Run Recap, and Match Reveal on a dark-theme device.

## Session State — 2026-05-18 23:38 CEST (Session 39)
- Active Task: Exclusive Playfair Match Reveal typography — completed locally
- Environment: Dev
- Modified Files:
    - `lib/src/features/match/presentation/match_reveal_screen.dart`
    - `tasks/context.md`
- Open Problems: BLOCKER-003 (RevenueCat/legal), BLOCKER-005 (iOS dev provisioning).
- System Status: `dart format` SUCCESS. `flutter analyze` SUCCESS. `flutter test` SUCCESS (66/66).

## Session Handoff
- Completed:
  - Replaced the uppercase partner name and separate age label on Match Reveal with a single natural-case `Name, age` line.
  - Switched the reveal typography to Playfair Display italic, `fontSize: 32`, `FontWeight.w600`, and no letter spacing.
- In Progress: None.
- Blocked:
  - BLOCKER-003: Real purchase flow and subscription persistence remain blocked by RevenueCat/legal setup.
  - BLOCKER-005: Physical iOS verification remains blocked by provisioning for `com.pulse`.
- Next Action:
  1. Visually verify Match Reveal with short and long names on device/simulator.

## Session State — 2026-05-18 23:22 CEST (Session 38)
- Active Task: Emotional haptics and 400 ms match reveal pause — completed locally
- Environment: Dev
- Modified Files:
    - `lib/src/features/dashboard/presentation/home_screen.dart`
    - `lib/src/features/dashboard/presentation/run_recap_screen.dart`
    - `lib/src/features/match/presentation/match_reveal_screen.dart`
    - `lib/src/features/match/presentation/wave_controller.dart`
    - `lib/src/features/matches/presentation/match_dialog.dart`
    - `lib/src/features/profile/presentation/profile_detail_screen.dart`
    - `tasks/context.md`
- Open Problems: BLOCKER-003 (RevenueCat/legal), BLOCKER-005 (iOS dev provisioning).
- System Status: `dart format` SUCCESS. `flutter analyze` SUCCESS. `flutter test` SUCCESS (66/66).

## Session Handoff
- Completed:
  - Added light haptic punctuation to real wave-send paths: dev match pill, LiveRunCard, Run Recap, WaveController, MatchDialog, and ProfileDetail.
  - Added a two-pulse medium-impact heartbeat when `MatchRevealScreen` opens.
  - Added a 400 ms delay between marking a foreground unseen match as seen and navigating to `match_reveal`.
- In Progress: None.
- Blocked:
  - BLOCKER-003: Real purchase flow and subscription persistence remain blocked by RevenueCat/legal setup.
  - BLOCKER-005: Physical iOS verification remains blocked by provisioning for `com.pulse`.
- Next Action:
  1. Manually verify haptic feel and reveal timing on a physical Android device; iPhone physical verification remains blocked until provisioning is fixed.

## Session State — 2026-05-18 23:03 CEST (Session 37)
- Active Task: Warmth Empty States — contextual Tremble microcopy — completed locally
- Environment: Dev
- Modified Files:
    - `lib/src/shared/ui/warmth_empty_state.dart`
    - `lib/src/core/translations.dart`
    - `lib/src/features/dashboard/presentation/home_screen.dart`
    - `lib/src/features/dashboard/presentation/run_recap_screen.dart`
    - `lib/src/features/matches/presentation/matches_screen.dart`
    - `lib/src/features/safety/presentation/blocked_users_screen.dart`
    - `tasks/context.md`
- Open Problems: BLOCKER-003 (RevenueCat/legal), BLOCKER-005 (iOS dev provisioning).
- System Status: `dart format` SUCCESS. `flutter analyze` SUCCESS. `flutter test` SUCCESS (66/66).

## Session Handoff
- Completed:
  - Added shared `WarmthEmptyState` glass-card empty-state treatment with Tremble rose signal mark, Playfair Display title, and Lora subtitle.
  - Added English and Slovenian warmth microcopy for radar empty, near-miss empty, run active empty, run history empty, matches empty, and blocked users empty states.
  - Replaced silent/generic empty branches in Home radar, Home near-miss, Run Recap active/history, Matches, and Blocked Users.
- In Progress: None.
- Blocked:
  - BLOCKER-003: Real purchase flow and subscription persistence remain blocked by RevenueCat/legal setup.
  - BLOCKER-005: Physical iOS verification remains blocked by provisioning for `com.pulse`.
- Next Action:
  1. Visually review the new empty cards on a compact and large phone viewport to confirm spacing around the radar button, run recap sections, and blocked users header.

## Session State — 2026-05-18 15:20 CEST (Session 36)
- Active Task: HomeScreen dynamic layout RangeError & Navigation Bounds stabilization — completed

## Session State — 2026-05-17 (Session 28)
- Active Task: Gym Search UX & Premium Spotlight Tutorial Remediation — completed locally
- Environment: Dev
- Modified Files:
    - `lib/src/core/places_service.dart`
    - `lib/src/features/gym/presentation/gym_search_widget.dart`
    - `lib/src/features/dashboard/application/tutorial_notifier.dart`
    - `lib/src/features/dashboard/presentation/widgets/premium_tutorial_overlay.dart`
    - `lib/src/core/translations.dart`
    - `tasks/context.md`
    - `tasks/archive/PLAN_compatibility_visibility_v1.1.md`
    - `tasks/archive/PLAN_premium_tutorial_flow.md`
    - `tasks/archive/TREMBLE_STABILIZATION_OSM_PLAN.md`
- Open Problems: BLOCKER-003 (RevenueCat), BLOCKER-005 (iOS dev provisioning for `com.pulse`)
- System Status: `dart format` SUCCESS. `flutter analyze` SUCCESS. `flutter test` SUCCESS (59/59). `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` SUCCESS.

## Session Handoff
- Completed:
  - **Gym Search API Bias:** Added Slovenia-centered `locationBias` to `gymAutocomplete` so real Places API searches prioritize local gym results in dev.
  - **Gym Search Dynamic Bias:** Refined gym autocomplete to use cached device location with a 50km Places bias when location permission is granted, falling back to the Slovenia-wide national bias otherwise.
  - **Gym Search UX:** Added keyboard search submission, a suffix search button, immediate search execution, keyboard unfocus, loading state handling, and rose empty-result feedback.
  - **Premium Tutorial Expansion:** Expanded the Premium Spotlight tutorial from 3 to 6 steps, adding Traveler Mode, Recap vs. Near Miss, and Set-and-Forget walkthrough copy plus dynamic spotlight coordinates.
  - **Task Archiving:** Moved completed plan files into `tasks/archive/`.
- In Progress: None.
- Blocked:
  - BLOCKER-003 (RevenueCat/Legal)
  - BLOCKER-005 (Physical iPhone deploy cannot sign `com.pulse`; no matching development provisioning profile)
- Next Action:
  1. Run the app on a simulator/physical device and visually verify tutorial spotlight placement across small and large viewports.
  2. Test gym search with a real `PLACES_KEY_DEV` against Slovenian gym names.

## Session State — 2026-05-17 (Session 27)
- Active Task: iOS Permission Prompt Localization — completed locally
- Environment: Dev
- Modified Files:
    - `lib/src/features/dashboard/presentation/home_screen.dart`
    - `test/features/dashboard/navigation_bounds_test.dart`
    - `lib/src/core/background_service.dart`
    - `lib/src/core/router.dart`
    - `tasks/PLAN_navigation_bounds_fix.md`
    - `tasks/context.md`
- Open Problems: BLOCKER-003 (RevenueCat/legal), BLOCKER-005 (iOS dev provisioning).
- System Status: `flutter analyze` SUCCESS. `flutter test` SUCCESS (66/66). `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` SUCCESS. Tracked secret/API pattern scan found no live secrets. All files successfully formatted via pre-commit dart format.

## Session Handoff
- Completed:
  - **Defensive Index Clamping:** Added `final int safeNavIndex = navIndex.clamp(0, screens.length - 1);` in `home_screen.dart` to prevent list out-of-bounds `RangeError` under fast state transitions or initialization.
  - **Reactive Premium Remapping:** Implemented an active state-notifier listener (`ref.listen<bool>`) watching `authStateProvider` premium status inside the `build()` method to dynamically map tab indices during Upgrade/Downgrade events.
  - **Unit Test Parity:** Created `test/features/dashboard/navigation_bounds_test.dart` asserting correct index transition mapping (both downgrade Settings and Map redirections, and upgrade Settings expansion) and defensive clamping behavior.
  - **Verification Loop:** Cleaned the static analyzer (`flutter analyze` - 0 issues found) and executed the complete test suite successfully (all 66/66 tests passing!).
- In Progress: None.
- Blocked:
  - BLOCKER-003: Subscriptions/real paywall purchases are blocked by team's legal/company registration.
  - BLOCKER-005: On-device deployment to physical iPhone remains blocked by Apple Team Provisioning profile limits.
- Next Action:
  1. Founder does an on-device run to visually confirm that switching states/roles never stutters, freezes, or produces a blank screen on physical Android/iOS targets.

## Session State — 2026-05-18 00:07 CEST (Session 35)
- Active Task: Premium Upgrade Flow 3D Card Shuffle implementation — completed locally
- Environment: Dev
- Modified Files:
    - `lib/src/core/router.dart`
    - `lib/src/core/translations.dart`
    - `lib/src/features/settings/presentation/settings_screen.dart`
    - `lib/src/features/settings/presentation/premium_screen.dart`
    - `test/features/settings/premium_screen_test.dart`
    - `tasks/PLAN_premium_upgrade_flow.md`
    - `tasks/context.md`
- Open Problems: BLOCKER-003 (RevenueCat/legal), BLOCKER-005 (iOS dev provisioning).
- System Status: `dart format` SUCCESS. `flutter analyze` SUCCESS. `flutter test` SUCCESS (62/62). `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` SUCCESS.

## Session Handoff
- Completed:
  - Added the Settings profile-section Premium CTA for basic users and active-plan/change-plan status block for premium users.
  - Registered the `/premium` route with `GradientScaffold(child: PremiumUpgradeScreen())`.
  - Implemented the 3D credit-card shuffle carousel using `PageView.builder`, Y-axis tilt, scale contraction, translation stacking, opacity depth, and `ImageFiltered` blur.
  - Mapped the four approved cards and pricing: Premium 7,99 €, Weekend Getaway 2,99 € Friday 19:00 to Sunday 19:00, Choices monthly/yearly/lifetime, and Free Tier.
  - Kept upgrade/downgrade behavior simulated locally only; no real billing, RevenueCat, StoreKit, API keys, or client-side Firestore `isPremium` writes were added.
  - Added a focused premium card order/pricing test.
- In Progress: None.
- Blocked:
  - BLOCKER-003: Real purchase flow and subscription persistence remain blocked by RevenueCat/legal setup.
  - BLOCKER-005: Physical iOS verification remains blocked by provisioning.
- Next Action:
  1. Manually open Settings -> Premium on a simulator/device and visually inspect the carousel on compact and large phones.
  2. When RevenueCat/legal is unblocked, replace the local simulation layer with real entitlement-backed purchase state.
