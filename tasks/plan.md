# Active Implementation Plan
Plan ID: 20260712-fix-prefer-not-to-say-translation
Risk Level: LOW
Founder Approval Required: NO
Branch: feat/prefer-not-to-say-translation

1. OBJECTIVE — Ship the missing `'prefer_not_to_say'` translation key across every locale in `translations.dart` so the religion and ethnicity registration steps stop rendering a raw key string, AND make the option itself feel intentional in the design (icon + consistent pill styling) so the choice is easy to see and tap.

2. SCOPE —
   - **Modified:**
     - `lib/src/core/translations.dart` — add `'prefer_not_to_say'` to all 8 locale blocks (en, sl, de, it, fr, hr, sr, hu). Inserted immediately after each block's `'atheist'` line so it lives beside religion strings.
     - `lib/src/features/auth/presentation/widgets/registration_steps/religion_step.dart` — add a neutral icon on the `prefer_not_to_say` option so it renders like the other religion pills (all others already carry an icon).
     - `lib/src/features/auth/presentation/widgets/registration_steps/ethnicity_step.dart` — add the same neutral icon so the "opt-out" pill is visually distinct from the ethnicity options.
     - `tasks/plans/PLAN_03_APP_CODE.md` — Output block for KORAK 3.1 and 3.2 + status footer.
     - `.gitignore` — ignore `.claude/scheduled_tasks.lock` (session-local, harness-generated).
     - `tasks/plan.md` (this file).
   - **Does NOT change:**
     - Firestore schema, Cloud Functions, native manifests (Info.plist / AndroidManifest.xml), CI workflows.
     - `sub_screen_step.dart` / `step_shared.dart` OptionPill widget — leave the shared button alone; only add the missing icon prop at the two call sites.

3. STEPS —
   (a) Confirm locale block count via `grep -n "^  '[a-z]\{2\}': {"` — expect 8 (en, sl, de, it, fr, hr, sr, hu). Post-edit count must also be 8 and each block must now grep-hit `'prefer_not_to_say'`.
   (b) Add `'prefer_not_to_say'` immediately after the `'atheist'` line in each locale. Translations:
       - en: "Prefer not to say"
       - sl: "Raje ne bi povedal/a"
       - de: "Möchte ich nicht angeben"
       - it: "Preferisco non dirlo"
       - fr: "Je préfère ne pas dire"
       - hr: "Radije ne bih rekao/rekla"
       - sr: "Radije ne bih rekao/rekla"
       - hu: "Inkább nem mondom meg"
   (c) In `religion_step.dart` add `'icon': Icons.privacy_tip_outlined` on the `prefer_not_to_say` option — every other religion option already carries an icon, so this pill previously rendered flat.
   (d) In `ethnicity_step.dart` add the same icon (import `package:flutter/material.dart` already present in `religion_step.dart`; ethnicity does the same) — makes the opt-out choice visually anchored.
   (e) Run `dart format .`, `flutter analyze`, `flutter test`. All must be clean/green.
   (f) Commit, push, open PR with the four MPC phrases and the pre/post grep counts as evidence.

4. RISKS & TRADEOFFS —
   - Translation quality for hr/sr/hu — I use a common polite form; a native speaker may polish later but the UX is now readable in every language and no raw key leaks.
   - Adding an icon to the ethnicity pill: none of the other ethnicity options have icons today, so this pill will stand out. That is desired (it is semantically different — an opt-out rather than a category), and it matches the pattern already used in the religion step where every option carries an icon.
   - We keep the shared `OptionPill` widget untouched — no cross-cutting styling change, no regression surface outside the two callers.

5. VERIFICATION —
   - **Verification checklist:**
     - [ ] **unit tests** — n/a (no logic changes); existing Flutter test suite must stay green.
     - [ ] **integration tests** — n/a (no data/network path touched); `flutter test` full suite green.
     - [ ] **security scan** — n/a (docs + strings + one icon prop); no new deps, no secrets, no permission changes.
     - [ ] `dart format .` — no diff.
     - [ ] `flutter analyze` — 0 issues.
     - [ ] `flutter test` — all green.
     - [ ] Grep evidence in PR body:
       - `grep -c "'prefer_not_to_say'" lib/src/core/translations.dart` pre = 0, post = 8.
       - `grep -c "^  '[a-z]\{2\}': {" lib/src/core/translations.dart` unchanged at 8 (no locale block accidentally deleted or duplicated).
