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
