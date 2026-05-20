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
