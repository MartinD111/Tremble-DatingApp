## Session State — 2026-05-17 (Session 23)
- Active Task: Outdated Tutorial Bypass, Launcher Icon & Code Style Formatting
- Environment: Dev
- Modified Files:
    - `flutter_launcher_icons.yaml`
    - `Logo/tremble_icon_clean_full_bleed.png`
    - `lib/src/features/dashboard/presentation/home_screen.dart`
    - 16 files reformatted via `dart format`
- Open Problems: BLOCKER-003 (RevenueCat)
- System Status: Compile analysis: SUCCESS. Zero warnings. Codebase formatted.

## Session Handoff
- Completed:
  - **Outdated Tutorial Bypass:** Disabled the old, static first-launch tutorial (`_showTutorial` popup overlay) from triggering automatically in debug mode (`!kDebugMode` condition). This prevents developer irritation and keeps the workspace clean and focused on live Radar, BLE, and gym interactions.
  - **Master Icon Resolution:** Created a 1024x1024 full-bleed, brand-accurate launcher icon (`Logo/tremble_icon_clean_full_bleed.png`) with the official radial gradient (`#F95B82` center-ish to `#E12F58` edges) and transparent wave logo overlay.
  - **White Border Prevention:** Updated `flutter_launcher_icons.yaml` to point to the new full-bleed PNG, eliminating the previous rounded squircle which left white borders on iOS devices.
- In Progress: None.
- Blocked: BLOCKER-003 (RevenueCat/Legal)
- Next Action:
  1. **How to Run the App (CLI):** Run `flutter run --flavor dev --dart-define=FLAVOR=dev` in terminal to launch the app on your connected device/simulator with the correct development configurations.
  2. **How to Run the App (Xcode):** Open `ios/Runner.xcworkspace` in Xcode, select the **Runner** scheme + your connected iPhone, and click **Run** (or `Cmd + R`).

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
