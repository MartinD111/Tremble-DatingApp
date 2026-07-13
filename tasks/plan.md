# Active Implementation Plan
Plan ID: 20260713-hobby-neutral-ids
Risk Level: MEDIUM
Founder Approval Required: NO
Branch: feat/hobby-language-neutral-ids

1. OBJECTIVE — Migrate hobbies from mixed-locale display strings (SL/EN
   soup like "Hiking" vs "Pohodništvo") to language-neutral snake_case
   IDs. Two concrete bugs get fixed by this migration:
     - Matching bug: user A stored "Hiking" and user B stored
       "Pohodništvo" were treated as different hobbies by the CF
       compatibility calculator, deflating shared-hobby scores between
       cross-locale profiles.
     - Display bug: profile viewers saw hobbies in whatever locale the
       author had entered them, not their own locale.
   Historical Firestore documents must keep working with zero migration
   — normalisation happens on read.

2. SCOPE —
   - **Modified:**
     - `lib/src/core/hobby_data.dart` — canonical list keyed by stable
       `id` (snake_case), plus a `displays` map (EN overrides where SL
       differs) and helpers: `hobbyById`, `idForLegacyName`,
       `hobbyDisplay`. Category constants extracted.
     - `lib/src/core/hobby_utils.dart` — `parseHobbies` now emits
       `{id, name, emoji, category, custom}` and routes legacy strings
       (EN, SL, old translation keys) through `idForLegacyName`. New
       `toStorage` helper serialises to canonical IDs for writes.
     - `lib/src/core/hobby_categories.dart` — internal map switched to
       `_idToCategory`; public `getCategory` accepts either ID or legacy
       display name.
     - `lib/src/features/auth/presentation/widgets/registration_steps/hobbies_step.dart`
       — accepts a `lang` parameter, renders pill labels via
       `HobbyData.hobbyDisplay(hobby, lang)`, and selection check
       compares IDs when available.
     - `lib/src/features/auth/presentation/registration_flow.dart` —
       passes `_selectedLanguage` into `HobbiesStep`.
     - `lib/src/features/profile/presentation/edit_profile_screen.dart`
       — pill labels use `HobbyData.hobbyDisplay(hobby, lang)`; remove
       compares by ID; passes `lang` into the modal `HobbiesStep`.
     - `lib/src/features/profile/presentation/profile_detail_screen.dart`
       — pill labels use `HobbyData.hobbyDisplay(h, lang)`.
     - `lib/src/features/profile/presentation/profile_card_preview.dart`
       — pill labels use `HobbyData.hobbyDisplay(h, lang)`.
     - `lib/src/features/matches/presentation/match_dialog.dart` —
       hobby chip text uses `HobbyData.hobbyDisplay(h, lang)`.
     - `functions/src/modules/compatibility/compatibility_calculator.ts`
       — `CATEGORY_MAP` replaced with `ID_TO_CATEGORY`; new
       `LEGACY_NAME_TO_ID` normalises EN + SL display strings and older
       translation keys into canonical IDs before exact-match and
       category scoring.
     - `test/core/hobby_utils_test.dart` — new. 16 tests covering
       legacy-name → ID mapping (EN + SL yield same ID), map-form input,
       custom pass-through, locale-aware display, and write-path.
     - `functions/src/__tests__/compatibility_calculator.test.ts` — 4 new
       tests: cross-locale EN + SL score equals canonical-ID score,
       mixed-locale profiles score correctly, legacy translation keys
       normalise, custom strings don't spurious-match.
     - `tasks/plans/PLAN_03_APP_CODE.md` — KORAK 3.3 Output block +
       status update, KORAK 3.4 Output block (this migration).
     - `tasks/plan.md` (this file).
   - **Does NOT change:**
     - Firestore schema or existing documents (migration is on-read).
     - `translations.dart` (no new per-locale hobby keys added — the
       localisation lives inline in `hobby_data.dart` for cohesion).
     - Auth repository write path (already used `h['id'] ?? h['name']`
       — now IDs flow through cleanly).
     - RegistrationFlow logic, PhotosStep, GymStep, etc.
     - Cloud Function auth/matches/proximity handlers (they pass
       `data.hobbies` through to the calculator, which does its own
       normalisation).

3. STEPS —
   (a) Rewrite `hobby_data.dart`: add `id` to every predefined hobby
       (95 entries), add category constants, `displays` map, and helper
       functions.
   (b) Rewrite `hobby_utils.dart` parseHobbies to enrich each entry with
       canonical ID; drop the inline legacy map (moved into
       `hobby_data.dart`).
   (c) Rewrite `hobby_categories.dart` to use `_idToCategory`; keep the
       public `getCategory(String)` API accepting ID or legacy name.
   (d) Update the 5 widget render sites and thread `lang` where
       missing. Selection checks in `hobbies_step.dart` and
       `edit_profile_screen.dart` compare IDs when available, fall back
       to name for custom.
   (e) In `compatibility_calculator.ts`: replace `CATEGORY_MAP` with
       `ID_TO_CATEGORY` + a `LEGACY_NAME_TO_ID` reverse map; apply
       normalisation at the top of `calculateHobbyScore` so exact-match
       and category signals both work off canonical IDs.
   (f) Add `test/core/hobby_utils_test.dart` (Flutter) and extend
       `compatibility_calculator.test.ts` (Functions) with the
       cross-locale scenarios.
   (g) `flutter analyze` → 0 issues. `flutter test` → all green.
       `cd functions && npm run build && npm run lint && npm test` →
       all green.
   (h) Commit, push, open PR.

4. RISKS & TRADEOFFS —
   - Legacy string coverage: the `LEGACY_NAME_TO_ID` table on the CF
     side and `idForLegacyName` on the Flutter side must cover every
     historical value seen in production. Covered all 95 canonical
     hobbies × 2 locales + the older `hobby_*` translation keys used by
     pre-hobby_data.dart profiles. Any unmapped custom string simply
     passes through as-is (a custom hobby), so worst case is a legacy
     "Filmi" won't category-boost but also won't crash.
   - No Firestore backfill: profiles keep their original strings until
     someone edits their hobbies. This is intentional — a batch write
     is a HIGH-risk change and the on-read migration achieves the same
     outcome for reads (matching + display).
   - Widget diffs are wide (5 files) but each is a one-line label
     swap. `HobbiesStep` gained a `lang` parameter, so the two callers
     needed a one-line update.
   - The `CATEGORY_MAP → ID_TO_CATEGORY` rename touches the compat
     calculator, which is critical scoring logic. All existing tests
     still pass, and the four new tests explicitly cover the
     cross-locale scenarios that motivated the change.

5. VERIFICATION —
   - **Verification checklist:**
     - [x] **unit tests** — `test/core/hobby_utils_test.dart` (16 new)
       covers EN/SL → same ID, map-form, custom, locale display, write.
       `functions/src/__tests__/compatibility_calculator.test.ts` (4 new)
       covers cross-locale scoring equivalence.
     - [x] **integration tests** — n/a. This migration touches shared
       data mapping only; the callable functions that consume hobbies
       (matches, proximity, users) are covered by their existing suites
       and continue to pass.
     - [x] **security scan** — n/a. No new deps, no auth/permission
       changes, no external I/O, no PII schema change.
     - [x] `flutter analyze` — 0 issues.
     - [x] `flutter test` — 237 tests green (previously 221; +16 new).
     - [x] `cd functions && npm run build` — 0 errors.
     - [x] `cd functions && npm run lint` — 0 warnings.
     - [x] `cd functions && npm test` — 12 suites / 109 tests green
       (previously 105; +4 new).
     - [x] Evidence in PR body: grep output showing remaining
       `hobby['name']` usages are all write-path serialisation or
       custom-hobby fallbacks (no display sites); grep showing
       `CATEGORY_MAP` no longer exists in CF modules.
