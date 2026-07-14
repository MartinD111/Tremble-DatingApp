# Active Implementation Plan
Plan ID: 20260714-ios-submission-audit
Risk Level: LOW
Founder Approval Required: NO
Branch: docs/ios-submission-audit-20260714

## 0. AUDIT RESULT — KORAK 3.9-2 iOS submission-readiness (Rule #82)

Audit against `main` @ 49e679c, post PR #32 (Info.plist Contacts
reconcile) and PR #34 (stale-intel cleanup). Read-only sweep of the
three surfaces mandated by Rule #82.

**Overall verdict: CLEAN.** No submission-blocking gap. BLOCKER-STORE-001
closed with evidence.

### Surface (a) — master ↔ localized divergence
- Master `ios/Runner/Info.plist` declares 10 `NS*UsageDescription`
  keys (Bluetooth×2, Camera, Contacts, Location×3, Motion, Photo×2).
- `en.lproj/InfoPlist.strings` localizes 7 of the 10; the 7 present
  are **byte-identical** to the master strings (`plutil -convert
  json` diff → zero divergence).
- `sl.lproj/InfoPlist.strings` and `hr.lproj/InfoPlist.strings`
  cover the same 7 keys with locale-appropriate translations
  (Bluetooth, Contacts, Location×3, Motion, but NOT Camera/Photo).
- **Not a Rule #82 violation**: iOS falls back to master when a
  localization is missing → user sees the English master string, not
  a lie. Apple's static reviewer reads the master → same string.
- **Follow-up (non-blocker)**: sl/hr users see English Camera / Photo
  prompts. Worth a translation sprint before broader EU launch, but
  not gating submission.

### Surface (b) — duplicate permission-key sweep
Every `NS*UsageDescription` key present in master `Info.plist`
counts **exactly 1**:
- NSBluetoothAlwaysUsageDescription: 1
- NSBluetoothPeripheralUsageDescription: 1
- NSCameraUsageDescription: 1
- NSContactsUsageDescription: 1
- NSLocationAlwaysAndWhenInUseUsageDescription: 1
- NSLocationAlwaysUsageDescription: 1
- NSLocationWhenInUseUsageDescription: 1
- NSMotionUsageDescription: 1
- NSPhotoLibraryAddUsageDescription: 1
- NSPhotoLibraryUsageDescription: 1
- NSMicrophoneUsageDescription: 0 (correct — not requested)
- NSFaceIDUsageDescription: 0 (correct — not requested)

PR #32's dedupe (Camera / Photo / PhotoAdd) held; no regression.

### Surface (c) — PrivacyInfo.xcprivacy completeness
`ios/Runner/PrivacyInfo.xcprivacy` (`plutil -lint` OK):
- **NSPrivacyAccessedAPITypes** — all 4 Required Reasons categories
  declared with valid reason codes: UserDefaults (CA92.1),
  FileTimestamp (C617.1), SystemBootTime (35F9.1), DiskSpace (E174.1).
- **NSPrivacyCollectedDataTypes** — 10 categories declared, all
  `NSPrivacyCollectedDataTypePurposeAppFunctionality`, `Tracking=false`:
  CoarseLocation, PhotosorVideos, Name, EmailAddress, PhoneNumber,
  UserID, PurchaseHistory, CrashData, OtherDiagnosticData, Contacts.
- Contacts entry has `Linked=false` per ADR-004 zero-data hash-only
  architecture; all others `Linked=true`.
- **NSPrivacyTrackingDomains** empty; **NSPrivacyTracking** false.
  Correct for a no-ads dating app.

### Encryption declaration
`ITSAppUsesNonExemptEncryption = false` present in master `Info.plist`.
Combined with `PrivacyInfo.xcprivacy` presence → iOS 17.4 gate cleared.

## 1. OBJECTIVE
Close BLOCKER-STORE-001 with audit evidence and record the audit
result in the durable plan of record so the next submission cycle
inherits the verification, not a re-verification cost.

## 2. SCOPE
- `tasks/blockers.md` — BLOCKER-STORE-001 status → RESOLVED with
  audit evidence + non-blocker follow-up note (sl/hr Camera/Photo
  localizations).
- `tasks/plan.md` — this file; Plan-ID rewrite + audit result §0.
- `tasks/plans/PLAN_03_APP_CODE.md` — KORAK 3.9-2 Output block
  filled (result CLEAN, PR#, merge commit after merge).

**Not touched:** `ios/Runner/Info.plist`, `PrivacyInfo.xcprivacy`,
any `.lproj/InfoPlist.strings`, any code under `lib/`, `functions/`,
`ios/Runner/*.swift`, `android/`, `.github/`. Zero native config
edit → no founder approval gate triggered.

## 3. NEXT LANES
- KORAK 3.9-3 paywall accuracy sync (BLOCKER-LEGAL-005) — MEDIUM
  risk, billing-adjacent, founder approval required.
- KORAK 3.9-4 brand-voice review Prominent Disclosure copy
  (BLOCKER-STORE-003 companion) — LOW risk, docs/copy only.

## 4. RISKS & TRADEOFFS
- Zero runtime change; zero submission risk introduced.
- Follow-up sl/hr Camera/Photo localization is recorded in
  blockers.md as a non-blocker so it can be picked up as a small
  translation sprint any time before broader EU launch. Not
  bundled into this PR because it would require translation review
  through `brand-voice-agent`, which is a separate lane.

## 5. VERIFICATION
- `git diff --stat` on branch → 3 files under `tasks/**`.
- `flutter analyze` → 0 issues (no Dart touched; pre-commit hook
  re-verifies).
- `flutter test` → 263 tests green baseline preserved.
- unit tests — n/a (docs-only, no runtime code).
- integration tests — n/a (docs-only).
- security scan — branch diff limited to `tasks/**`. Zero secrets,
  zero PII, zero auth/billing/security-boundary change.
- MPC PR pre-flight (Rules #79 + #80):
  - Title: `[PLAN-ID: 20260714-ios-submission-audit] docs(blockers+plan): close BLOCKER-STORE-001 — Rule #82 3-surface audit CLEAN`.
  - Body contains `## Verification checklist` naming `unit tests`,
    `integration tests`, `security scan` (each n/a with a one-line
    docs-only reason).
  - Body contains zero Rule #80 naive-regex trigger substrings.
  - Plan-ID present in this file (line 2).
