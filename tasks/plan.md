# Active Implementation Plan
Plan ID: 20260713-registration-location-freetext
Risk Level: MEDIUM
Founder Approval Required: NO
Branch: feat/registration-location-freetext

1. OBJECTIVE — Replace the KP/LJ/ZG/Other OptionPill selector in the
   registration location step with a bounded free-text field. The
   selector had no matching/scoring role — its only effect was to
   collect a coarse city label. GDPR data minimisation favours the
   simpler input, and freeing the field from the enum unblocks users
   outside the four hardcoded cities. Same treatment applied to the
   profile edit screen so the on-load clamp
   (`profileLocationOptions.contains(user.location) ? user.location :
   'Other'`) no longer overwrites a custom city on first edit.

2. SCOPE —
   - **Modified (Flutter):**
     - `lib/src/features/auth/presentation/widgets/registration_steps/email_location_step.dart`
       — `_locationSelector()` returns a plain `_inputField(...)`
       instead of a `profileLocationOptions.map(...)` OptionPill list.
       `_onLocationSelected` helper removed (unused).
     - `lib/src/features/profile/presentation/edit_profile_screen.dart`
       — location OptionPill list replaced by
       `_buildTextField(locationController, ..., maxLength: 80,
       onChanged: onLocationSelected)`; import narrowed to `show
       DrumPicker`; on-load clamp collapsed to
       `_locationController.text = user.location ?? ''`. `_buildTextField`
       extended with optional `onChanged` to keep `_markChanged()`
       reactive.
     - `lib/src/features/auth/presentation/widgets/registration_steps/step_shared.dart`
       — `profileLocationOptions` const deleted (no residual callers).
   - **Modified (Cloud Functions):**
     - `functions/src/modules/auth/auth.schema.ts` — `location:
       z.enum([...]).nullish()` → `z.string().trim().min(1).max(80)
       .nullish()`.
     - `functions/src/modules/users/users.schema.ts` — same swap on
       `updateProfileSchema`.
   - **Modified (Tests):**
     - `test/features/auth/registration_flow_test.dart` — flipped the
       "constrained to city enum" contract test to assert the freetext
       Zod prefix on both schemas, the removal of `profileLocationOptions`
       from `step_shared.dart` / both screens, and continued absence of
       `PlacesService`/`locationPredictions` on both surfaces.
     - `functions/src/__tests__/users.test.ts` — old
       "should constrain location to the city enum" flipped to accept
       freetext ≤80 chars, still reject whitespace-only, oversized,
       still allow explicit null.
     - `functions/src/__tests__/auth.test.ts` — "reject precise
       free-text location" flipped to "freetext bounded but no enum"
       (accept previous street-address example, reject whitespace-only
       and >80 chars).
   - **Untouched:** matching/compatibility calculator, Firestore rules,
     mock user data, `translations.dart` (hint strings unchanged),
     Places API path (still used by Gym Mode gym search).

3. STEPS —
   1. Update both Zod schemas to freetext with trim + bounds — verify
      by `grep "z.enum.*Ljubljana"` returning 0 hits in production
      code.
   2. Replace `_locationSelector()` body in `email_location_step.dart`
      with a `_inputField`-based TextField; delete the now-unused
      `_onLocationSelected` helper.
   3. Replace the OptionPill list in `_BasicInfoSection` of
      `edit_profile_screen.dart` with `_buildTextField(...)` wired to
      the existing `onLocationSelected` callback via a new optional
      `onChanged`; narrow the `step_shared.dart` import; fix the on-load
      clamp.
   4. Delete `profileLocationOptions` from `step_shared.dart`.
   5. Update three test files (Flutter registration_flow_test.dart,
      CF users.test.ts, CF auth.test.ts).
   6. Verify: `flutter analyze` clean, `flutter test` green,
      `cd functions && npm run lint && npm run build && npm test` green.
   7. Grep report on remaining Places API usage (report-only, no
      dependency removal).

4. RISKS & TRADEOFFS —
   - **Legacy value compatibility (LOW):** existing Firestore
     documents holding "Ljubljana"/"Koper"/"Zagreb"/"Other" still
     parse against the freetext schema (all fit the length bound); on
     load, edit_profile no longer rewrites them to "Other" if the
     legacy string is present. No Firestore migration required.
   - **Input abuse (LOW):** 80-char cap + `.trim()` + client-side
     `TextField(maxLength: 80)` bound the field. Location is
     display-only, no downstream logic parses it.
   - **UX regression (LOW):** four preset pills were fast for the
     three anchor cities but blocked everyone else. Freetext preserves
     the fast path (users type "Koper" in five characters) and unblocks
     other markets.
   - **Places API dependency (NONE removed):** report-only step. Places
     API is still called by `gym_search_widget.dart` for gym
     autocomplete — the dependency (raw HTTP + PLACES_KEY_DEV/PROD
     compile-time defines) stays.
   - **Assumption:** matching/compat calculator does NOT read
     `location` — verified by `grep "\.location" functions/src/modules/`
     returning only auth/users schema references.

5. VERIFICATION —
   - `flutter analyze` — 0 issues.
   - `flutter test` — 242 tests green (unchanged count).
   - `cd functions && npm run lint` — 0 warnings.
   - `cd functions && npm run build` — 0 errors.
   - `cd functions && npm test` — 114 tests green (unchanged count;
     three test bodies rewritten, no new tests added since the contract
     shifted rather than expanded).
   - Grep evidence:
     - `grep -rn "profileLocationOptions" lib/ test/` → only the two
       negative assertions in `registration_flow_test.dart`.
     - `grep -rn "z.enum.*Ljubljana" functions/src/modules/` → 0 hits.
   - Places API grep report:
     - Still used by `lib/src/core/places_service.dart` (imported by
       `lib/src/features/gym/presentation/gym_search_widget.dart`).
     - Not a pub package — invoked via raw HTTP with
       `PLACES_KEY_DEV`/`PLACES_KEY_PROD` compile-time defines.
     - Removal not possible while Gym Mode uses gym autocomplete.
   - Device test not applicable — pure UI + schema change; smoke
     verification deferred to the next TestFlight build alongside PLAN
     05 KORAK 5.2.
