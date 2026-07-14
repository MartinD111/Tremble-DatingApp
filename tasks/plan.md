# Active Implementation Plan
Plan ID: 20260714-brand-voice-prominent-disclosure
Risk Level: LOW
Founder Approval Required: NO
Branch: feat/brand-voice-prominent-disclosure

## 0. CHANGE — KORAK 3.9-4 brand-voice pass on Prominent Disclosure copy

Copy for the 4 disclosure translation keys was spec-verbatim from PR
#7 (2026-07-07). BLOCKER-STORE-003 progress note flagged it as
"⏳ must go through brand-voice review before ship." This PR closes
that item.

## 1. OBJECTIVE
Ship a brand-voice-reviewed EN + SL copy for the Google Play
Prominent Disclosure screen without diluting the Play-policy phrases
the regulator's reviewer greps for. Pin the brand-voice keywords in
the widget test so a future refactor can't silently regress.

## 2. SCOPE

- `lib/src/core/translations.dart`
  - EN body: `matches → signals`, `deleted → cleared`.
  - SL body: `ujemanja → signale`.
  - Headline + CTAs unchanged (Play-standard).
  - EN comment above the keys rewritten to record the brand-voice
    review outcome and the exact policy phrases preserved.
- `test/features/auth/prominent_disclosure_screen_test.dart`
  - Add 2 EN + 1 SL `textContaining` assertions pinning the new
    brand-voice keywords (`signals nearby`, `cleared within hours`,
    `signale v tvoji bližini`).
  - Existing spec-locked assertions kept unchanged.
- `tasks/blockers.md` — BLOCKER-STORE-003 progress: brand-voice
  review DONE; remaining actions = screenshots + demo video + Play
  Console submission.
- `tasks/plan.md` — this file, Plan-ID.
- `tasks/plans/PLAN_03_APP_CODE.md` — KORAK 3.9-4 Output block filled.

**Not touched:** no code under `functions/`, no native config
(`ios/Runner/Info.plist`, `AndroidManifest.xml`, `PrivacyInfo.xcprivacy`),
no CI, no Firestore Rules, no other translation keys, no other
locales (`de`, `fr`, `it`, `es`, `pt`).

## 3. STEPS

1. Cut `feat/brand-voice-prominent-disclosure` off `main` @ 17f7b5c.
2. Apply the 2 surgical edits to EN body + 1 edit to SL body in
   `translations.dart`. Rewrite the source-comment above the keys.
3. Extend `prominent_disclosure_screen_test.dart` with pinning
   assertions for the new brand-voice keywords.
4. Update `tasks/blockers.md` BLOCKER-STORE-003 progress.
5. Update `tasks/plans/PLAN_03_APP_CODE.md` KORAK 3.9-4 Output.
6. Commit; pre-commit hook re-verifies `flutter analyze` + full test
   suite.
7. Open PR with Rule #79 + Rule #80 pre-flight.

## 4. RISKS & TRADEOFFS

- Copy change is user-facing and ships in a regulatory submission
  package (Play Console). Diluting the Play-policy phrases could
  cause review rejection. Mitigation: preserved verbatim the exact
  phrases the regulator's reviewer looks for (`approximate
  location`, `in the background`, `Allow background location`) in
  both EN + SL. Only the surrounding narrative changes.
- No other locales updated. `de/fr/it/es/pt` still show the
  original English fallback (they never had disclosure keys). Not a
  regression; those locales are out of scope for the Play SI + HR
  launch package. To be picked up in a future translation sprint.

## 5. VERIFICATION

- `git diff --stat` on branch → ≤6 files (translations, test,
  blockers.md, plan.md, PLAN_03_APP_CODE.md).
- `flutter analyze` → 0 issues (pre-commit hook re-verifies).
- `flutter test` → all tests green; `prominent_disclosure_screen_test.dart`
  now passes 5 checks per language (headline + 4 pinning assertions
  for EN, 4 for SL) + 2 CTA-contract checks + 1 no-permission-handler
  leak check.
- unit tests — n/a (no domain logic changed).
- integration tests — n/a (widget test covers surface).
- security scan — no PII/auth/billing/security-boundary change. Copy
  only.
- MPC PR pre-flight (Rules #79 + #80):
  - Title: `[PLAN-ID: 20260714-brand-voice-prominent-disclosure] feat(auth): brand-voice pass on Prominent Disclosure copy (EN + SL)`.
  - Body contains `## Verification checklist` naming `unit tests`,
    `integration tests`, `security scan`.
  - Body contains zero Rule #80 naive-regex trigger substrings.
  - Plan-ID present in this file (line 2).
