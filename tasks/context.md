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
    1. Visual and interaction verification on physical device/emulator. Run the app with: `flutter run --flavor dev --dart-define=FLAVOR=dev`

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
  1. Run the mobile app (`flutter run --flavor dev --dart-define=FLAVOR=dev`) on a device/simulator to visually inspect the premium dark map styling.



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
