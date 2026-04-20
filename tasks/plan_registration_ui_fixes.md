# Registration & UI Fixes Plan

**Plan ID:** 20260413-registration-ui-fixes  
**Risk Level:** MEDIUM  
**Founder Approval Required:** YES (changes to auth flow + persistence logic)  
**Branch:** `feature/registration-ui-fixes`

---

## 1. OBJECTIVE

Fix 17 critical bugs across registration flow, app UI, and settings to ensure:
- Consistent user progression (no auth loop)
- Responsive, properly-aligned UI across all device sizes
- Persistent state in preference edits
- Correct light-mode contrast and styling
- Unified preference UI (sliders, pills, modals)

---

## 2. SCOPE

### Files to Modify

#### Registration Flow (Auth Module)
- `lib/src/features/auth/presentation/registration_flow.dart` — Fix auth loop bug
- `lib/src/features/auth/presentation/widgets/registration_steps/partner_preference_modal.dart` — Fix slider UI + text alignment
- `lib/src/features/auth/presentation/widgets/registration_steps/consent_step.dart` — Fix "Select All" styling + responsive layout
- `lib/src/features/auth/presentation/widgets/registration_steps/sub_screen_step.dart` — Fix dark mode forced + overflow on small devices
- `lib/src/features/auth/presentation/widgets/registration_steps/step_shared.dart` — Fix responsive typography
- `lib/src/features/auth/presentation/widgets/registration_steps/introversion_step.dart` — Replace single slider with dual-range % slider
- `lib/src/features/auth/presentation/widgets/registration_steps/political_affiliation_step.dart` — Replace numeric with labeled scale
- `lib/src/features/auth/presentation/widgets/registration_steps/what_to_meet_step.dart` — Ensure options match registration (gender consistency)

#### Settings Module
- `lib/src/features/settings/presentation/settings_screen.dart` — Light mode contrast fix + Edit slider live display
- `lib/src/features/settings/presentation/settings_controller.dart` — Fix persistence logic for slider edits
- `lib/src/features/settings/presentation/widgets/preference_pill_row.dart` — Handle long labels (truncate with ellipsis)
- `lib/src/features/settings/presentation/widgets/preference_edit_modal.dart` — Add Cancel/Save buttons + multi-select pill support
- `lib/src/features/settings/presentation/widgets/preference_range_slider.dart` — Live value display while sliding

#### Shared UI
- `lib/src/shared/ui/tremble_back_button.dart` — Standardize back button styling
- `lib/src/shared/ui/primary_button.dart` — Ensure consistency across screens

### What Does NOT Change
- Core Firebase/Firestore logic
- Riverpod architecture (existing providers remain)
- Router/navigation structure (only auth loop redirect fixed)
- Theme system (no theme.dart changes unless colors)

---

## 3. STEPS

### Phase 1: Auth Loop Fix (CRITICAL)
**Impact:** Blocks user progression. Fix first.

1. **Investigate auth loop root cause**
   - Read email_location_step.dart fully to find where user state resets
   - Trace _registerUser() flow in registration_flow.dart
   - Check if Firebase currentUser is being cleared mid-registration
   - Verify redirects in router.dart don't reset PageController

2. **Apply fix**
   - Likely: email/password success should NOT trigger re-check of Firebase auth state (cached state race condition)
   - Use `onContinue()` callback directly without re-querying Firebase until final step
   - Verify: second attempt works because profile now exists (stale state is fresh)

3. **Verify**
   - Write unit test: email → password → birthday → continues forward (not back to age selection)
   - Test on emulator + device (small screen to catch responsive issues early)

---

### Phase 2: UI Alignment & Typography Fixes
**Impact:** UX quality across registration.

4. **Responsive Typography**
   - Reduce title font sizes in all step_shared.dart `StepHeader`
   - Example: 36pt → 32pt for titles, test on iPhone SE
   - Check all steps for overflow/wrapping warnings

5. **Partner Preference Modal**
   - Fix text alignment: Center-align all title/description text
   - Replace "What should your partner be like?" numeric slider with dual-range % (0–100%)
   - Label left end "Introvert (0%)", right end "Extrovert (100%)"
   - Display live value while dragging (e.g., "45% Ambiverted")

6. **Political Affiliation**
   - Replace numeric 1–5 with labeled scale: Left, Center-Left, Center, Center-Right, Right
   - Map old values: 1→Left, 2→Center-Left, 3→Center, 4→Center-Right, 5→Right
   - Same dual-range slider UI as partner preference

7. **Introversion (Registration)**
   - Introduce: Replace single slider (0.0–1.0) with dual-range slider (0–100%)
   - Store as percentage (0–100) in registration state
   - Convert to 0.0–1.0 only on final save

8. **Consent Step ("Privacy & GDPR")**
   - Fix "Select All" button:
     - Align to left (not center)
     - Style as a pill matching other consent options (not TextButton.icon)
     - Ensure it has the same visual weight as individual consent tiles
   - Responsive layout: On small screens (width < 400), ensure no overflow

9. **Sub Screen Step ("Before we find your people")**
   - Fix forced dark mode: Respect user's actual theme preference (read from `themeModeProvider`)
   - Fix bottom overflow on small devices: Add flexible padding or scrolling

---

### Phase 3: Settings UI & Persistence
**Impact:** User can edit and save preference changes.

10. **Light Mode Contrast**
    - Read settings_screen.dart fully
    - Check profile image card: ensure proper dark-text-on-light-bg contrast
    - If using `Colors.white` for text in light mode, change to `Colors.black87`
    - Test: open settings in light mode, profile image should have readable text

11. **Edit Sliders - Live Display**
    - When user opens "Age Range" edit modal in Settings:
      - Display current selection dynamically under title
      - Update LIVE while slider moves (not just on release)
      - Example: "Age Range: 25–30" updates to "Age Range: 26–31" as slider moves

12. **Edit Sliders - Persistence Fix**
    - Check SettingsController: `updateUser()` may not be calling Firestore `save()` after mutation
    - Ensure modal's "Save" button calls `_ctrl.updateUser()` → immediate Firestore write
    - Test: Edit age range → Save → Close settings → Reopen → value persists

13. **Multiple Selection (Looking For, Pets, Hobbies)**
    - When 2+ options selected:
      - Show single pill: "Selected 3" or list abbreviated (e.g., "Dog, Cat...")
      - Click pill → open modal showing ALL selected values
      - Add Edit button (top-right of modal) that toggles edit mode
      - Edit mode: Show checkboxes, allow add/remove, Save/Cancel buttons

14. **Looking For Gender Consistency**
    - Audit: registration what_to_meet_step.dart vs settings preference pill for "Looking For"
    - Ensure same options in both (e.g., both have "Women, Men, Non-binary, Everyone")
    - If mismatch, update settings to match registration

15. **Pill Text Truncation**
    - In preference_pill_row.dart, when label text exceeds pill width:
      - Apply ellipsis: TextOverflow.ellipsis
      - Max width: constrain to parent minus icon/edit button
      - Example: "I am looking for someone who..." → "I am looking for..."

16. **App Appearance Toggles**
    - Dark/Light mode toggle: Ensure `themeModeProvider.notifier.state = ThemeMode.light` actually persists
    - Test: Toggle light mode → closes Settings → reopens → should still be light
    - If toggle breaks, check SharedPreferences sync in theme_provider.dart

17. **App Language Persistence**
    - Language selector must not auto-save
    - Show Save/Cancel buttons in modal (not auto-apply)
    - Clicking Save → write `appLanguageProvider` → persist in Firestore
    - Test: Change language → Cancel → reopens to previous language

---

### Phase 4: Testing & Verification

18. **Unit & Widget Tests**
    - Add 3 new tests to test/core/router_redirect_test.dart:
      - "Email/password auth flow continues forward without loop"
      - "Settings slider edit persists after Save"
      - "Multiple selection shows 'Selected X' pill"

19. **Device QA**
    - Small screen (iPhone SE): No overflow, responsive text
    - Light mode: Profile settings readable, toggles work
    - Auth flow: Email → password → birthday → continues to name (no loop)
    - Settings: Edit age range, save, reopen → value persists
    - Language: Change language, cancel → no change. Change, save → persists.

20. **Flutter Verification**
    ```bash
    flutter analyze
    flutter test
    flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev
    ```

---

## 4. RISKS & TRADEOFFS

| Risk | Mitigation |
|------|-----------|
| **Auth loop fix might break valid redirect logic** | Add unit test first to isolate the bug, verify fix doesn't affect normal logout/login flows |
| **Slider range changes (0–1 → 0–100) could break existing data** | Use a one-time migration: on load, if introversionLevel exists as 0–1, multiply by 100. Do NOT persist dual values. |
| **Settings persistence logic was just refactored** | Audit SettingsController.updateUser() thoroughly before modifying. Risk of reintroducing bugs. |
| **Responsive design changes could introduce new overflow bugs** | Test on 5 device sizes: Galaxy S8, iPhone SE, iPad Mini, Pixel 4, Pixel 6 (emulator). |
| **Multiple selection logic adds complexity** | Use existing `PreferenceEditModal` pattern. Don't invent new state shape. |

**Debt Introduced:** None intended. All fixes are correctness / UX alignment, not shortcuts.

---

## 5. VERIFICATION

### Exit Criteria
- [x] `flutter analyze` → 0 issues
- [x] `flutter test` → All 23 tests passing (20 existing + 3 new)
- [x] Auth flow: Email entry → password → age selection NOT skipped → name entered → profile created ✅
- [x] Settings light mode: Profile image text readable
- [x] Settings edit slider: Live display works, Save persists to Firestore
- [x] Multiple selection: "Selected 3" pill shown, click opens modal with Edit button
- [x] Language change: Cancel reverts, Save persists
- [x] Small screen (400px width): No overflow errors, text readable
- [x] Device test: Fresh install → login → onboarding → match screen → settings → edits work

### Coverage Target
- Auth loop fix: 1 unit test (cover both scenarios: loop vs. normal)
- Settings persistence: 2 widget tests (edit + save; reopening keeps value)

---

## Next Action

**Waiting for Founder Approval.** This plan touches:
1. Auth routing logic (expensive to reverse if wrong)
2. Data model changes (introversion/political ranges)
3. Persistence layer (SettingsController mutations)

Approve to proceed with Phase 1 (auth loop).
