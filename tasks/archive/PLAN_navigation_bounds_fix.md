# Plan: Navigation Bounds Crash Fix

Plan ID: 20260518-navigation-bounds-fix
Risk Level: MEDIUM
Founder Approval Required: NO
Branch: feature/navigation-bounds-fix

---

## 1. OBJECTIVE
Eliminate the intermittent Android/iOS blank "empty home screen" state by (a) defensively clamping the navigated index to the bounds of the active tab list (`screens`), and (b) reactively mapping the active tab index when transitioning between Free (3-state navigation) and Premium (4-state navigation) user states.

## 2. SCOPE
- **Files Modified:**
  - `lib/src/features/dashboard/presentation/home_screen.dart`
- **Files Unchanged:**
  - `lib/src/features/auth/data/auth_repository.dart`
  - `lib/src/core/router.dart`
  - All other business logic and BLE services.

## 3. STEPS
1. **Defensive Index Clamping:** ✅ DONE
   - Retrieve `navIndex` from `navIndexProvider` in `HomeScreen.build()`.
   - Calculate `final int safeNavIndex = navIndex.clamp(0, screens.length - 1);`.
   - Use `safeNavIndex` to look up the active widget in `screens[safeNavIndex]`, key the `KeyedSubtree` via `ValueKey<int>(safeNavIndex)`, and pass to the `LiquidNavBar` widget.
   - *Verification:* The build method compiles successfully and can never throw a `RangeError (Index out of range)` even if `navIndex` is temporarily greater than the size of the dynamic `screens` list.
2. **Reactive Navigation Mapping on Status Transition:** ✅ DONE
   - Listen to changes in the user's premium status reactively inside `HomeScreen.build()` using `ref.listen` on `authStateProvider.select((user) => user?.isPremium == true)`.
   - Implement the index conversion mapping to preserve Settings or Matches placement, and reset `Map` to `Radar` (index 0) if downgraded:
     - **Downgrade (Premium -> Free):**
       - Map `Map (1)` to `Radar (0)`.
       - Map `Matches (2)` to `Matches (1)`.
       - Map `Settings (3)` to `Settings (2)`.
     - **Upgrade (Free -> Premium):**
       - Map `Matches (1)` to `Matches (2)`.
       - Map `Settings (2)` to `Settings (3)`.
       - Keep `Radar (0)` as `Radar (0)`.
   - *Verification:* Transitioning user's premium status updates the active tab index smoothly without layout jumps or resetting the user to the starting page unless they were on the Premium Map.
3. **Write Unit/Widget Tests:** ✅ DONE
   - Add a focused widget/provider test inside a new test file `test/features/dashboard/navigation_bounds_test.dart` to verify that:
     - The home screen maps the navIndex defensively when premium status is updated.
     - Changing the premium status updates `navIndexProvider` with correct mapped values.
     - Clamping works for an out-of-bounds index (e.g. index 3 when free).
   - *Verification:* `flutter test test/features/dashboard/navigation_bounds_test.dart` passes.
4. **Full Verification Loop:** ✅ DONE
   - Run `flutter analyze` to ensure zero compilation or linter warnings.
   - Run `flutter test` to ensure all 62 original tests plus the new tests pass.
   - Run `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` to ensure the dev build works flawlessly.

## 4. RISKS & TRADEOFFS
- **Risks:** 
  - An unexpected edge-case during first startup could trigger a brief mismatch before the first stream event.
- **Mitigation:**
  - The combination of instant clamping + reactive selective mapping guarantees that at any point in the lifecycle, the rendered screen index is mathematically valid and correct.
- **Debt Introduced:** Zero. This is clean, self-correcting logic encapsulated entirely within the presentation layer.

## 5. VERIFICATION
- **Statics:** `flutter analyze` (Zero warnings/errors).
- **Unit/Widget Tests:** High-fidelity unit/widget tests covering the premium transitions.
- **Flavored Build:** `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev`.
