## Session State — 2026-05-17 21:09 CEST (Session 30)
- Active Task: On-device bug fixes — completed locally
- Environment: Dev
- Modified Files:
    - `ios/Runner.xcodeproj/project.pbxproj`
    - `lib/main.dart`
    - `lib/src/features/auth/presentation/login_screen.dart`
    - `lib/src/features/auth/presentation/radar_background.dart`
    - `lib/src/features/auth/presentation/widgets/registration_steps/intro_slide_step.dart`
    - `lib/src/features/dashboard/presentation/home_screen.dart`
    - `tasks/context.md`
    - `tasks/lessons.md`
    - `tasks/PLAN_device_bug_fixes.md`
- Open Problems: BLOCKER-003 (RevenueCat), BLOCKER-005 (iOS dev provisioning for physical-device deploy)
- System Status: `dart format` SUCCESS. `flutter analyze` SUCCESS. `flutter test` SUCCESS (60/60). `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` SUCCESS. `plutil -lint` SUCCESS. `flutter build ios --debug --flavor dev --dart-define=FLAVOR=dev --no-codesign` SUCCESS.

## Session Handoff
- Completed:
  - Fixed tutorial opt-in modal crash by capturing Riverpod notifiers before opening the bottom sheet/dialog and avoiding disposed `ref` access after modal callbacks.
  - Updated the iOS Firebase plist copy script so `tremble.dating.app.dev` selects the Dev `GoogleService-Info.plist`.
  - Added safe-area-aware bottom padding on the intro slide continue button and login scroll view to prevent iPhone home-indicator cutoff/overflow.
  - Locked the login radar background to Tremble graphite for the affected screen and removed the odd 15px password-field gap.
  - Preloaded Playfair Display, Lora, and Instrument Sans before `runApp()` to reduce first-frame font fallback on cold boot.
  - Added Rule #59 documenting the Riverpod modal lifecycle pattern.
- In Progress: None.
- Blocked:
  - BLOCKER-003 (RevenueCat/Legal)
  - BLOCKER-005 (Physical iPhone deploy still depends on valid Apple provisioning for `tremble.dating.app.dev` / dev targets)
- Next Action:
  1. Run on the iPhone 15 once provisioning is available and manually verify tutorial opt-in, Firebase bundle logs, intro slide overflow, login language pill visibility, and first-frame fonts.
  2. Commit `fix/device-bug-fixes` after physical-device verification or after accepting simulator/build-only coverage.

## Session State — 2026-05-17 (Session 29)
- Active Task: Interactive Tutorial Flow & Passive Tourist Icon Remediation — completed locally
- Environment: Dev
- Modified Files:
    - `lib/src/core/translations.dart`
    - `lib/src/features/dashboard/application/tutorial_notifier.dart`
    - `lib/src/features/dashboard/presentation/home_screen.dart`
    - `lib/src/features/dashboard/presentation/widgets/premium_tutorial_overlay.dart`
    - `lib/src/features/profile/presentation/profile_card_preview.dart`
    - `lib/src/features/profile/presentation/profile_detail_screen.dart`
    - `lib/src/features/settings/presentation/settings_screen.dart`
    - `lib/src/shared/ui/liquid_nav_bar.dart`
    - `test/features/dashboard/tutorial_notifier_test.dart`
    - `tasks/context.md`
    - `tasks/PLAN_interactive_tutorial_and_tourist_remediation.md`
- Open Problems: BLOCKER-003 (RevenueCat), BLOCKER-005 (iOS dev provisioning for `com.pulse`)
- System Status: `dart format` SUCCESS. `flutter analyze` SUCCESS. `flutter test` SUCCESS (60/60). `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` SUCCESS.

## Session Handoff
- Completed:
  - Reworked the premium tutorial state machine into hidden / opt-in / active phases with six interaction-driven steps and persisted completion.
  - Added the startup quick tutorial opt-in bottom sheet and interactive step advancement from the mode button, schedule button, nav tabs, popups, and central radar button.
  - Replaced the blurred tutorial overlay with a sharp graphite spotlight overlay that passes taps through inside the highlighted circle and blocks outside taps.
  - Added dynamic target rect registration and pulsing highlights for top controls, nav bar destinations, and radar CTA.
  - Removed the manual Traveler Mode switch from Settings and kept the tourist indicator as a passive profile badge sourced from existing `isTraveler`.
  - Updated English and Slovenian tutorial / tourist badge translations.
- In Progress: None.
- Blocked:
  - BLOCKER-003 (RevenueCat/Legal)
  - BLOCKER-005 (Physical iPhone deploy cannot sign `com.pulse`; no matching development provisioning profile)
- Next Action:
  1. Run on a simulator or physical Android device and manually step through the tutorial to visually verify spotlight alignment and click-through behavior across viewports.
  2. Commit the completed feature branch when ready.

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
    - `ios/Runner/Info.plist`
    - `ios/Runner.xcodeproj/project.pbxproj`
    - `ios/Runner/en.lproj/InfoPlist.strings`
    - `ios/Runner/sl.lproj/InfoPlist.strings`
    - `ios/Runner/hr.lproj/InfoPlist.strings`
    - `tasks/context.md`
- Open Problems: BLOCKER-003 (RevenueCat), BLOCKER-005 (iOS dev provisioning for `com.pulse`)
- System Status: `dart format .` SUCCESS (0 changed). `plutil -lint` SUCCESS for plist/project/localization files. `flutter analyze` SUCCESS. `flutter test` SUCCESS (59/59). `flutter build ios --debug --flavor dev --dart-define=FLAVOR=dev --no-codesign` SUCCESS. Built app contains `en.lproj`, `sl.lproj`, and `hr.lproj` `InfoPlist.strings`. Physical iPhone run still blocked by provisioning.

## Session Handoff
- Completed:
  - **iOS Permission Localization:** Replaced Slovenian `NSContactsUsageDescription` fallback in `Info.plist` with English. Added native iOS `InfoPlist.strings` translations for English, Slovenian, and Croatian covering contacts, location, Bluetooth, and motion prompts.
  - **Xcode Resource Registration:** Registered `InfoPlist.strings` as a localized `PBXVariantGroup` resource in `project.pbxproj` after the first build showed `.lproj` files were not bundled automatically. Verified the built `Runner.app` contains all three localized strings files.
  - **iOS Splash Fix Plan Execution:** Ran `dart run flutter_native_splash:create`, confirmed generated iOS launch image sizes are 512/1024/1536 px and `LaunchBackground` is 1x1. The generator temporarily reset `LaunchScreen.storyboard` fallback background to white; restored graphite `#1A1A18` and verified no tracked diff remained.
  - **Cache Reset + Builds:** Ran `flutter clean`, `flutter pub get`, `flutter analyze`, `flutter test`, unsigned dev iOS build, and dev debug APK build successfully.
  - **Premium Tutorial Flow:** Implemented clean Premium Spotlight tutorial (radar scan, wave button, activity settings) backed by SharedPreferences, with manual restart button "Spoznaj Tremble ponovno" in settings screen.
  - **Map Privacy Limits:** Capped maximum map zoom to `16.0` (max 4.0 meters per pixel) to prevent centimeter-precise coordinates tracking. Restricted heatmap circles by forcing `useRadiusInMeter: true` with a secure `120` meter radius constraint.
  - **Multilingual Support:** Resolved language inconsistency bugs by localizing the onboarding flow, map's events banner, and map's zoom control toggle with Slovene and English translations.
  - **iOS Splash Fix:** Ran `dart run flutter_native_splash:create`, verified iOS launch images are generated at 512/1024/1536 px and `LaunchBackground` is a 1x1 RGB asset. Corrected the generator regression that reset `LaunchScreen.storyboard` background to white by restoring graphite `#1A1A18`.
  - **Cache Reset:** Ran `flutter clean` and `flutter pub get` after splash generation.
- In Progress: None.
- Blocked:
  - BLOCKER-003 (RevenueCat/Legal)
  - BLOCKER-005 (Physical iPhone deploy cannot sign `com.pulse`; no matching development provisioning profile)
- Next Action:
  1. Fix Apple Developer/Xcode provisioning for bundle identifier `com.pulse`, then rerun `flutter run -d 00008120-001618402604201E --flavor dev --dart-define=FLAVOR=dev`.
  2. On the physical iPhone, uninstall Tremble and reboot before rerun to flush iOS launch screen cache, then visually confirm no white splash and centered rose logo.

## Price Decision (2026-05-11)
- **7,99 € / month** — confirmed by founder
- `premium_paywall.dart` already shows 7,99 € ✅
- `tremble-brand-identity.html` updated from 4,99 → 7,99 ✅
- `Master_Strategy_v6.html` not found in repo (may be external)

## What was implemented (My Gyms — Phase 12)

### ✅ 1. lib/src/core/places_service.dart (Session 2)
- PlaceDetails class, gymAutocomplete(), getPlaceDetails(), placesServiceProvider

### ✅ 2. lib/src/features/auth/data/auth_repository.dart (Session 2)
- selectedGyms field in AuthUser, fromFirestore parse, copyWith, updateSelectedGyms (repo + notifier)

### ✅ 3. lib/src/features/gym/domain/selected_gym.dart (Session 2)
- SelectedGym model with placeId, name, address, lat, lng — toMap()/fromMap()

### ✅ 4. lib/src/features/gym/application/gym_selection_notifier.dart (Session 3)
- GymSelectionNotifier extends Notifier<List<SelectedGym>>
- addGym() max 3 cap, removeGym(), persists via authStateProvider.notifier.updateSelectedGyms()
- gymSelectionProvider = NotifierProvider

### ✅ 5. lib/src/features/gym/presentation/gym_search_widget.dart (Session 3)
- ConsumerStatefulWidget with debounced search (300ms), predictions list, gym tiles
- Uses placesServiceProvider, calls gymAutocomplete + getPlaceDetails
- SnackBar "Max 3 gyms reached" on cap violation
- _GymTile component with remove button

### ✅ 6. lib/src/features/auth/presentation/widgets/registration_steps/gym_step.dart (Session 3)
- Optional onboarding step — "Your Gyms" title, dumbbell icon, 3-slot indicator
- Skip button (top right) + "Skip for now" / "Continue" CTA
- Wraps GymSearchWidget

### ✅ 7. lib/src/features/auth/presentation/registration_flow.dart (Session 3)
- Added GymStep at index 27 (after PhotosStep)
- _selectedGymsForRegistration field
- Progress bar totalSteps: iOS 28, Android 29 (was 27/28)
- Ritual step index: iOS 29, Android 30 (was 28/29)
- Writes gyms after completeOnboarding via updateSelectedGyms

### ✅ 8. lib/src/features/gym/application/gym_dwell_service.dart (Session 3)
- Personal gyms priority: if user.selectedGyms.isNotEmpty, use those (converted to Gym model, 80m default radius)
- Falls back to global gymsListProvider if no personal gyms

### ✅ 9. lib/src/features/settings/presentation/settings_screen.dart (Session 3)
- Added 'gyms' GlobalKey to _sectionKeys
- Added "My Gyms" expandable section (LucideIcons.dumbbell) after lifestyle
- _buildMyGymsContent() renders GymSearchWidget with gymSelectionProvider

## Architecture Notes (permanent)
- Cloud Function (updateProfile, completeOnboarding) uses Zod strict schema — NEVER add selectedGyms to toApiPayload()
- selectedGyms writes directly to Firestore via updateSelectedGyms method
- GymDwellService converts SelectedGym to Gym inline (no separate converter needed)
- GymDwellService priority: personalGyms (placeId as id, 80m radius) > global Firestore gyms
- PlacesService billing: session token links gymAutocomplete + getPlaceDetails calls (Rule #42)
- Registration step is optional (has Skip button)
- Max 3 gyms enforced in GymSelectionNotifier.addGym() + GymSearchWidget UI
