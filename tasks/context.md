## Session State — 2026-05-11 (Session 17)
- Active Task: Sprint 1 — Stabilization complete
- Environment: Dev
- Modified Files:
    - firestore.rules ✅ (rules for active_run_crosses, run_encounters, gyms, proximity_notifications — already done in prior session)
    - lib/src/features/map/presentation/event_recap_screen.dart ✅ (mock profiles removed, empty state)
    - lib/src/features/matches/data/match_repository.dart ✅ (watchMatches → Firestore real-time listener, kReleaseMode guard)
    - .gitignore ✅ (test_output.txt, desktop.ini, *.orig added)
    - tasks/context.md ✅ updated
- Deleted (Task 5): connect_script.dart, temp_script.dart, patch_registration.dart, patch_app_delegate.swift, update_modals.py, test_output.txt, desktop.ini
- Open Problems: BLOCKER-003 (RevenueCat), Protomaps tile server (Martin), translations incomplete for DE/FR/SR/HU
- System Status: 56/56 tests pass. flutter analyze clean.

## Session Handoff
- Completed: All 5 Sprint 1 tasks from PROJECT_STATUS_AUDIT.md
  - Task 1 (Firestore rules): Already done in prior session — confirmed present
  - Task 2 (Event Recap mock profiles): Removed _RecapProfile, _mockProfiles, dead card widgets → empty state
  - Task 3 (Red test): Already fixed by prior router logic — 23/23 router tests pass
  - Task 4 (watchMatches polling): Replaced while(true) loop with Firestore .snapshots().asyncMap(getMatches), added kReleaseMode guard + uid from authStateProvider
  - Task 5 (Repo cleanup): Deleted 7 junk files, updated .gitignore
- In Progress: —
- Blocked: BLOCKER-003 (RevenueCat/Legal), Task 8 (Protomaps — Martin)
- Next Action: Sprint 2 — Task 6 RevenueCat integration (requires Apple Dev Account $99 + Google Play Console $25 first)

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
