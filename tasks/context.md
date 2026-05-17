## Session State — 2026-05-17 (Session 25)
- Active Task: iOS Splash Screen Fix Verification
- Environment: Dev
- Modified Files:
    - `lib/src/features/dashboard/presentation/home_screen.dart`
    - `lib/src/features/dashboard/application/tutorial_notifier.dart`
    - `lib/src/features/dashboard/presentation/widgets/premium_tutorial_overlay.dart`
    - `lib/src/features/dashboard/presentation/widgets/spotlight_painter.dart`
    - `lib/src/features/settings/presentation/settings_screen.dart`
    - `test/features/dashboard/tutorial_notifier_test.dart`
    - `lib/src/features/map/presentation/tremble_map_screen.dart`
    - `tasks/blockers.md`
    - `tasks/lessons.md`
    - `web/index.html` (generator newline only)
- Open Problems: BLOCKER-003 (RevenueCat), BLOCKER-005 (iOS dev provisioning for `com.pulse`)
- System Status: `flutter analyze` SUCCESS. `flutter test` SUCCESS (59/59). `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` SUCCESS. `flutter build ios --debug --flavor dev --dart-define=FLAVOR=dev --no-codesign` SUCCESS. Physical iPhone run blocked by provisioning.

## Session Handoff
- Completed:
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
