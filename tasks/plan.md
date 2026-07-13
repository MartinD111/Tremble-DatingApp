# Active Implementation Plan
Plan ID: 20260713-info-plist-contacts-reconcile
Risk Level: HIGH
Founder Approval Required: YES
Branch: fix/info-plist-contacts-reconcile

1. OBJECTIVE — Resolve BLOCKER-STORE-002 (Apple 5.1.1 rejection risk)
   by reconciling `ios/Runner/Info.plist` with the Anonymity Mode
   feature that actually ships (ADR-004). Master `NSContactsUsageDescription`
   currently denies contact access while `lib/src/core/contact_service.dart`
   invokes `flutter_contacts` and Privacy Policy §2.5 describes the
   behavior. In the same PR: dedupe three permission keys (Camera,
   PhotoLibrary, PhotoLibraryAdd) that were previously flagged in
   `TREMBLE_MASTER_COMPLIANCE_REPORT_06JUL2026.md`, and declare
   Contacts in `PrivacyInfo.xcprivacy` (missing declaration is a
   separate ITMS-91036-family submission risk). Founder confirmed
   2026-07-13: Pulse Intercept ships in v1, so keep the L46/L48
   photo-intercept wording; delete the L58/L72 duplicates.

2. SCOPE —
   - **Modified:**
     - `ios/Runner/Info.plist` — fix NSContactsUsageDescription
       master string to match `en.lproj/InfoPlist.strings:1`
       verbatim; remove 3 duplicate keys (NSCameraUsageDescription
       L58–59, NSPhotoLibraryUsageDescription L72–73,
       NSPhotoLibraryAddUsageDescription L50–51).
     - `ios/Runner/PrivacyInfo.xcprivacy` — insert
       `NSPrivacyCollectedDataTypeContacts` entry
       (Linked=false, Tracking=false, Purpose=AppFunctionality).
     - `tasks/plan.md` — this file.
     - `tasks/blockers.md` — mark BLOCKER-STORE-002 RESOLVED with
       PR reference.
     - `tasks/plans/PLAN_03_APP_CODE.md` — KORAK 3.8-1 status ✅.
     - `tasks/plans/PLAN_04_LEGAL_STORES.md` — KORAK 4.2 note that
       the code side is now truthful.
   - **Untouched:** all Dart code, all tests, `pubspec.yaml`,
     `translations.dart`, `en/sl/hr.lproj/InfoPlist.strings`
     (already correct), CI, Firestore Rules, Cloud Functions,
     ADR-004 (still ACCEPTED).

3. STEPS —
   1. Cut `fix/info-plist-contacts-reconcile` from latest `main`.
   2. Fix master NSContactsUsageDescription string in Info.plist.
   3. Remove 3 duplicate permission-key blocks in Info.plist.
   4. Insert Contacts declaration in PrivacyInfo.xcprivacy.
   5. Verify: `plutil -lint` on both files; grep occurrence counts
      = 1 for each dedup'd key; grep `NSPrivacyCollectedDataTypeContacts`
      count = 1; master + localized EN strings identical.
   6. `flutter analyze` and `flutter test` (no Dart touched — should
      remain clean).
   7. `flutter build ios --no-codesign --flavor dev
      --dart-define=FLAVOR=dev` sanity build.
   8. Update tasks docs (blockers, PLAN_03, PLAN_04, this file).
   9. Commit; open PR per Rule #79 + Rule #80 pre-flight.
  10. Founder approves in PR thread before merge (per PLAN_00 line
      20 — Info.plist edits require explicit sign-off).

4. RISKS & TRADEOFFS —
   - **HIGH-risk classification** because Info.plist is on the
     PLAN_00-protected list. Mitigation: founder-approval gate,
     surgical scope, unchanged localized `.lproj` files (runtime
     behavior identical for existing device locales).
   - **Wording change is Apple-visible.** New master
     NSContactsUsageDescription mirrors the string Apple already
     accepted under the localized `en.lproj` file. Low reject risk.
   - **NSPrivacyCollectedDataTypeLinked=false for Contacts** is a
     classification call. ADR-004's hash-only transmission supports
     `false`; legal review can flip to `true` before merge if a
     more conservative posture is preferred.
   - **Web-side Privacy Policy §2.5** is out of scope. §2.5 on
     `trembledating.com/privacy` still needs founder update before
     the actual App Store submission (recorded under PLAN_04
     KORAK 4.2). This PR closes the code-side rejection risk only.

5. VERIFICATION —
   - `plutil -lint ios/Runner/Info.plist` → OK.
   - `plutil -lint ios/Runner/PrivacyInfo.xcprivacy` → OK.
   - No duplicate keys: each of NSCameraUsageDescription,
     NSPhotoLibraryUsageDescription, NSPhotoLibraryAddUsageDescription,
     NSContactsUsageDescription appears exactly once
     (`grep -c '<key>X</key>' ios/Runner/Info.plist` = 1 for each).
   - `grep -c NSPrivacyCollectedDataTypeContacts ios/Runner/PrivacyInfo.xcprivacy` = 1.
   - Master + localized EN strings for NSContactsUsageDescription
     are byte-identical.
   - `flutter analyze` — 0 issues (no Dart touched).
   - `flutter test` — 263 tests green.
   - unit tests — n/a; no Dart or Cloud Function code touched.
   - integration tests — n/a; no CF or Firestore path touched.
   - security scan — branch diff limited to `ios/Runner/*.plist`,
     `ios/Runner/PrivacyInfo.xcprivacy`, and `tasks/**`. No
     secrets, no auth path, no billing path, no PII field change.
   - `flutter build ios --no-codesign --flavor dev
     --dart-define=FLAVOR=dev` — succeeds locally.
   - MPC PR pre-flight (Rule #79 + Rule #80):
     - Title format: `[PLAN-ID:
       20260713-info-plist-contacts-reconcile]
       fix(ios): reconcile Info.plist Contacts + dedupe permission
       keys + declare Contacts in PrivacyInfo`.
     - Body contains literal phrases: `Verification checklist`,
       `unit tests`, `integration tests`, `security scan`.
     - Body contains ZERO of the Rule #80 naive-regex trigger
       substrings.
     - Plan-ID present in this `tasks/plan.md` file (line 2).
     - Post-create: `gh pr view <N> --json body -q .body |
       grep -iE "(infra_change|touches_auth|touches_pii|external_model_calls|risk_level: (high|critical))"`
       → zero hits.
   - Founder approval gate (mandatory, PLAN_00 line 20): PR body
     opens with the founder-approval-request line; founder is
     non-admin; no branch-protection bypass.
