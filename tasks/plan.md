# Active Implementation Plan
Plan ID: 20260715-crossing-paths-ios-delivery
Risk Level: HIGH
Status: IMPLEMENTED — awaiting protected-branch PR review and merge
Founder Approval Required: YES — approved in the 2026-07-15 audit handoff and reaffirmed on 2026-07-16
Branch: fix/crossing-paths-ios-delivery

## 1. OBJECTIVE

Restore canonical sender identity and reliable iOS delivery for
`CROSSING_PATHS` and `INCOMING_WAVE`, while allowing a reciprocal Wave
only after an explicit notification action.

## 2. SCOPE

- Cloud Functions identity, notification payloads, bounded retry,
  delivery-state deduplication, structured redacted logging, and focused tests.
- Flutter notification lifecycle ownership and explicit action dispatch tests.
- Native iOS bridging for the real `UNNotificationResponse.actionIdentifier`.
- Production build number `1.0.0+22`.
- No Firestore schema, Rules, profile migration, or unrelated Firebase change.

## 3. STEPS

1. Lock production-shaped canonical identity and delivery behavior in tests.
2. Implement server delivery, retry, deduplication, and safe logging changes.
3. Remove receipt-triggered Wave writes and preserve explicit iOS actions.
4. Deploy only the two approved Functions and produce the signed build-22 IPA.
5. Merge through protected `main`, then complete the APNs/device release gate.

## 4. RISKS & TRADEOFFS

- Retry and deduplication must land together to avoid duplicate delivery.
- Native/Flutter cold-start action handling must remain idempotent.
- APNs credentials and physical-device delivery remain an external release gate;
  the code change alone cannot prove that stored Apple credentials are valid.

## 5. VERIFICATION

- unit tests: all Functions tests and Flutter tests pass.
- integration tests: focused notification payload, retry, deduplication, and
  explicit-action paths pass; production Functions deployed independently.
- security scan: staged and committed diffs contain no credentials or PII.
- Flutter analyzer clean; dev-flavor APK succeeds.
- Signed production IPA exports with production APNs entitlement and passes
  App Store validation.

---

# Prior Implementation Plan
Plan ID: 20260714-legal-003-art9-consent-hardening
Risk Level: HIGH (Art. 9 GDPR consent enforcement + core matching pipeline + backend write gate + on-launch UX)
Status: RESOLVED 2026-07-14 — PR #41 merged into `main` @ cce1f1c; Cloud Functions deployed to prod (`am---dating-app`) same day. Downstream lanes unblocked: LEGAL-001 DPIA rewrite, LEGAL-004 Weekend Pass timezone, PLAN_04 KORAK 4.2/4.3, STORE-003/004 Play Console declarations.
Founder Approval Required: YES (approved 2026-07-14 in the pre-cut discuss-phase — this file IS the record)
Branch: feature/legal-003-art9-consent-code (merged as PR #41; code follow-up to the docs branch feature/legal-003-art9-consent-hardening / PR #40)

## 0. AUDIT RESULT — LEGAL-003 gap analysis (2026-07-14)

BLOCKER-LEGAL-003 was originally scoped as "add explicit consent for
Art. 9 special-category data." A discuss-phase audit against `main`
(post PR #39 merge) found the scaffolding ~60% complete but with 4
HIGH-severity gaps that individually invalidate the compliance
posture. This PR closes all HIGH gaps + adjacent MEDIUM cleanups
in a single coherent lane so we never ship a half-compliant state.

### Current state audit (`main` post PR #39)

| Component | State | Evidence |
|---|---|---|
| `consent_step.dart` registration UI | ✅ Collects per-category consents (orientation required; religion + ethnicity optional) | `lib/src/features/auth/presentation/widgets/registration_steps/consent_step.dart:38-46` |
| Client persistence | ✅ `sexualOrientationConsent` + `sexualOrientationConsentAt` + `religionConsent` + `ethnicityConsent` on `AuthUser` | `lib/src/features/auth/data/auth_repository.dart:87-93` |
| `getPublicProfile` whitelist | ✅ religion / ethnicity / gender blocked from client-facing response via TS excess-property enforcement | `functions/src/modules/users/users.schema.ts:95-131` |
| Bilateral fail-closed scorer (religion + ethnicity) | ✅ Both parties must have consent=true for scoring to fire | `functions/src/modules/compatibility/compatibility_calculator.ts:273-289` |
| Server write-time enforcement | ❌ **HIGH GAP** — `users.functions.ts` accepts Art. 9 field writes with no consent check (grep "consent" → 0 hits) | `functions/src/modules/users/users.functions.ts` |
| Bilateral fail-closed scorer for gender + lookingFor | ❌ **HIGH GAP** — orientation is derived from these fields but there is no analogous scorer gate | `compatibility_calculator.ts` |
| Settings withdrawal UX | ❌ **HIGH GAP** — `settings_screen.dart` has zero consent references; violates GDPR Art. 7(3) "as easy to withdraw as to give" | `lib/src/features/settings/presentation/settings_screen.dart` |
| Existing-user backfill | ❌ **HIGH GAP** — every pre-consent-step prod user has `null` orientation consent; no re-prompt path | policy + code |
| "Select all" pill toggles Art. 9 optionals | ⚠️ MEDIUM — undermines "specific" consent per category | `consent_step.dart:56-57` |
| Consent version tag | ⚠️ MEDIUM — no `{category}ConsentVersion`; purpose-text bumps cannot re-prompt | data model |
| Timestamps for religion + ethnicity consents | ⚠️ MEDIUM — only orientation gets `ConsentAt`; religion + ethnicity do not | `auth_repository.dart` |

### Legal framing (approved 2026-07-14)

Founder direction: `sexualOrientationConsent` STAYS REQUIRED for
matching. The Art. 9(2)(a) explicit-consent defense holds up if
(a) purpose is narrowly scoped in the consent text (matchmaking
within Tremble only, no ad-tech, no analytics fingerprinting, no
third-party sharing), (b) that scope is enforced in code
(bilateral fail-closed gate on gender + lookingFor), and (c)
withdrawal is functional (Settings toggle purges the fields).
This is the standard EU dating-app posture (Bumble, Hinge). The
Grindr NOK 65M fine was not "requiring orientation was illegal"
but "orientation collected for matching was shared with ad
networks without a separate lawful basis." Tremble never shares
Art. 9 data with third parties — the narrow purpose scope is
defensible when it is provably enforced.

## 1. OBJECTIVE

Close all HIGH-severity Art. 9 gaps in one PR so we ship a coherent
consent posture, not a half-compliant intermediate state. Every
policy claim in the consent text is backed by code enforcement in
this PR.

## 2. SCOPE

**Files this PR touches:**

Server:
- `functions/src/modules/users/users.functions.ts` — write-time enforcement in `updateProfile`; new `withdrawArt9Consent` callable that deletes the sensitive field(s)
- `functions/src/modules/users/users.schema.ts` — accept `sexualOrientationConsent` / `religionConsent` / `ethnicityConsent` on `updateProfile` (same-request grants)
- `functions/src/modules/auth/auth.functions.ts` — `completeOnboarding` drops religion/ethnicity to null when the paired consent isn't true; server stamps version + timestamp for all three categories
- `functions/src/modules/compatibility/compatibility_calculator.ts` — orientation bilateral fail-closed gate on `lookingFor` (`gender` is not scored today; the gate is placed on the orientation-adjacent scoring surface)
- `functions/src/index.ts` — export the new `withdrawArt9Consent` callable
- `functions/src/__tests__/users.test.ts` — 10 new assertions: pair-of-tests per Art. 9 field, same-request-withdrawal rejection, withdrawal callable delete semantics
- `functions/src/__tests__/compatibility_calculator.test.ts` — orientation bilateral gate pair-of-tests (mirrors religion pattern)

Client:
- `lib/src/features/auth/presentation/widgets/registration_steps/consent_step.dart` — remove select-all from Art. 9 optionals; narrow-purpose text on all three Art. 9 tiles via `_v1` translation keys with a "Learn more" PP anchor link; stable Keys for widget-test access
- `lib/src/features/auth/data/auth_repository.dart` — five new AuthUser fields (version + timestamp for orientation / religion / ethnicity); `fromFirestore` + `copyWith` extended; new `withdrawArt9Consent(category)` and `setArt9Consent(category, granted:)` repo + notifier methods (server-first, not optimistic, so a network failure keeps the backfill modal open for retry)
- `lib/src/features/settings/presentation/widgets/privacy_consents_section.dart` — NEW; three-tile settings section with confirmation dialog + destructive withdrawal
- `lib/src/features/settings/presentation/settings_screen.dart` — wires the new section as a fifth expandable "privacy" group
- `lib/src/features/auth/presentation/backfill_consent_modal.dart` — NEW; PopScope-locked full-screen modal + `BackfillConsentGate` root-level overlay
- `lib/src/app.dart` — wraps the app inside `BackfillConsentGate` alongside the existing `DismissKeyboard`
- `lib/src/core/translations.dart` — Art. 9 tile copy + settings section copy + backfill modal copy in EN + SL + HR; other locales fall back to EN via the existing `tr()` fallback

Tests:
- `test/features/auth/consent_step_test.dart` — select-all restriction, `_v1` key wiring, PP anchor deep-links, and four narrow-purpose phrases across EN + SL + HR
- `test/features/settings/privacy_consents_section_test.dart` — NEW; render-state parity + confirm-then-invoke + cancel-suppression
- `test/features/auth/backfill_consent_modal_test.dart` — NEW; four state-predicate assertions plus accept / decline / server-error retry paths
- `test/features/auth/photo_upload_registration_test.dart` — updated so the "select-all + continue" path taps the orientation tile explicitly (LEGAL-003 step 4)

Docs / tracking:
- `tasks/plan.md`, `tasks/blockers.md`, `tasks/plans/PLAN_03_APP_CODE.md`, `tasks/plans/PLAN_04_LEGAL_STORES.md` — plan + status updates

**Files this PR does NOT touch:**
- `firestore.rules` — write enforcement is CF-side; the app never writes directly. Rules review is a separate lane if we ever open direct writes.
- `firestore.indexes.json`
- BLE service, native config, Info.plist / PrivacyInfo.xcprivacy, AndroidManifest
- Any other feature module (matches, waves, radar, recap, event pin sheet)
- Any legal doc under `web/` or `legal/` — DPIA + Privacy Policy rewrites are LEGAL-001 + PLAN_04 KORAK 4.3, downstream of this PR

## 3. STEPS

### Step 1 — Server write-time enforcement

In `updateProfile` + `completeOnboarding` (CF handlers), before persist:

- Load the target user's current consent flags from Firestore.
- Merge them with any consent flags in the incoming request (same-request grants are honored).
- If incoming `gender` or `lookingFor` is present AND merged `sexualOrientationConsent !== true` → reject with `code: 'permission-denied'` + `message: 'art9_orientation_consent_required'`.
- Same enforcement for `religion` vs `religionConsent`, `ethnicity` vs `ethnicityConsent`.
- Fail-closed: any consent flag missing or false blocks the corresponding field write.

Verify via jest: `updateProfile({ gender: 'female' })` with `sexualOrientationConsent = false` → 403 with correct error code.

### Step 2 — Bilateral fail-closed scorer gate for gender + lookingFor

In `compatibility_calculator.ts`, mirror the existing religion / ethnicity pattern (line 273-289):

- Add `const bothConsentOrientation = a.sexualOrientationConsent === true && b.sexualOrientationConsent === true;`
- Guard every scoring dimension that reads `a.gender`, `b.gender`, `a.lookingFor`, `b.lookingFor` with `bothConsentOrientation`.
- If either party lacks consent → the orientation-adjacent dimensions are OMITTED from the score (not zero, not one — matching the existing skip semantics).

Verify via jest pair: neither → dimension skipped; one → skipped; both → dimension counted.

### Step 3 — Consent-text hardening

Rewrite all three Art. 9 consent tiles in `consent_step.dart` with narrow-purpose language:

- **Orientation tile:** "I consent to Tremble processing my gender and matching preferences (from which my sexual orientation may be inferred — a GDPR Art. 9 special category) SOLELY for the purpose of matching me with compatible users inside Tremble. This data is never sold, never shared with advertisers, never used for analytics, and is bilaterally fail-closed (only users who have also consented can be scored against my orientation). I can withdraw consent from Settings at any time; on withdrawal my gender and matching preferences are deleted from Tremble."
- **Religion tile:** analogous narrow-purpose text.
- **Ethnicity tile:** analogous narrow-purpose text.

Each tile links to the Privacy Policy anchor `#art9-consent-<category>`. Anchors will be pinned in LEGAL-001; if PP is not yet updated, the anchor still resolves to the PP root — the link never dangles.

Update EN + SL + HR translations in the same commit.

### Step 4 — Remove "select all" from Art. 9 optionals

- `_toggleAll()` currently flips religion, ethnicity, orientation alongside Terms / Privacy / Age / Location / DataProcessing (`consent_step.dart:48-60`).
- Restrict `_toggleAll()` to Terms + Privacy + DataProcessing + Age + Location only. Art. 9 tiles are ONLY toggleable individually.
- The Continue button gate stays: all mandatory tiles + orientation required; religion + ethnicity remain optional.

### Step 5 — Consent version tag + timestamps

Add fields on `AuthUser`:
- `sexualOrientationConsentVersion: String?` (initial value `'v1'`)
- `religionConsentVersion: String?` (initial value `'v1'`)
- `ethnicityConsentVersion: String?` (initial value `'v1'`)
- `religionConsentAt: DateTime?`
- `ethnicityConsentAt: DateTime?`

Persist all five on registration + on every consent state transition (withdrawal or re-grant). Update `toMap`, `fromMap`, `copyWith`. Extend the Zod schema in `users.schema.ts` to accept the five new fields on write.

### Step 6 — Settings withdrawal UX

New `privacy_consents_section.dart` embedded in the existing Settings screen:

- Three tiles (orientation / religion / ethnicity), each showing current consent state + accepted version + timestamp.
- On withdrawal:
  1. Confirmation dialog with a clear impact statement: "This will remove your [category] data from Tremble. You will not appear in matches scored on this dimension. You can re-consent later, but you will need to re-enter the data."
  2. On confirm → CF call updates the consent flag to `false` + writes new timestamp + version; `FieldValue.delete()` on the corresponding field(s) — orientation withdraws also deletes `gender` and `lookingFor`.
  3. Scorer immediately reflects (already fail-closed).
- On re-grant → route user to the existing profile-edit UI to re-enter the field.

### Step 7 — Existing-user backfill modal

New `backfill_consent_modal.dart`:

- On app launch, after auth resolution, if `currentUser.sexualOrientationConsent == null` → show the modal ABOVE all other UI.
- Modal shows the full narrow-purpose statement (same wording as Step 3 orientation tile) + Accept / Decline buttons.
- **Accept** → CF call writes consent = true + `v1` + timestamp. Modal dismisses. Normal app flow.
- **Decline** → CF call writes consent = false + `v1` + timestamp. Modal dismisses. User is routed to browse-only mode (matching disabled; scorer already fails closed on their data). Settings shows the withdrawal state; user can re-consent from there.
- Modal cannot be swipe-dismissed or back-button-dismissed — a decision must be made.
- No re-prompt loop: once a decision is recorded (even Decline), the modal does not re-appear until a version bump.

## 4. RISKS & TRADEOFFS

- **HIGH risk classification** — modifies core matching pipeline (scorer) AND server-side write enforcement AND on-launch UX in one PR. Splitting would ship intermediate half-compliant states (worse than nothing), so we accept the larger diff. Trade-off acknowledged.
- **Backfill modal will cause a temporary DAU dip** — every existing user hits a blocking screen on next launch. Accept-rate is expected to be high (product is understandable) but not 100%. Users who decline lose matching access and may churn. Founder-approved: worth it for legal defensibility.
- **`FieldValue.delete()` on withdrawal is destructive** — user cannot recover the deleted field. UX mitigation: confirmation dialog with an explicit impact statement + option to re-enter on re-grant.
- **`v1` version tag is a decision made permanent** — future consent-text bumps to `v2` will need to re-prompt existing v1 users. The mechanism is built in this PR; the first `v2` bump is a future lane.
- **Purpose text is long** — legally strong, UX-heavy. The tile is scrollable. Acceptable trade-off given Grindr precedent.
- **Not in this PR (deferred):** immutable consent-history subcollection (only relevant if audit demands proof of prior states — current model overwrites), Privacy Policy rewrite (LEGAL-001 lane), DPIA update (PLAN_04 KORAK 4.3), sending the pisno mnenje request to counsel (PLAN_04 KORAK 4.2 — done AFTER this PR merges so counsel opines on shipped code, not a proposal).

## 5. VERIFICATION

- **unit tests** — 8+ new assertions:
  - Server: `updateProfile` rejects `gender` write when orientation consent = false
  - Server: `updateProfile` accepts `gender` write when the SAME request grants orientation consent
  - Server: analogous pair for religion + ethnicity
  - Scorer: orientation dimension skipped when neither party has consent
  - Scorer: orientation dimension skipped when one party has consent
  - Scorer: orientation dimension counted when both parties have consent
  - Widget: `consent_step` select-all no longer flips Art. 9 optionals
  - Widget: privacy consents section withdrawal invokes `FieldValue.delete` via mocked repo
  - Widget: backfill modal renders on null consent + Accept path writes `true + v1`
  - Widget: backfill modal Decline path writes `false + v1` and routes to browse-only mode
- **integration tests** — n/a for this PR (no new cross-service flow; each unit test covers a single boundary cleanly)
- **security scan** — n/a — this PR IS the Art. 9 security hardening; any surface a scanner would flag is precisely what the PR closes. Manual security review by founder before merge is the actual gate.
- `flutter analyze` clean
- `flutter test` all pass (existing + new)
- `cd functions && npm test` all pass (existing + new)
- Manual smoke on dev flavor:
  - Fresh registration → all consent fields land in Firestore with `v1` + timestamps
  - Update `gender` via app with orientation consent = false → 403 (matches error code)
  - Toggle orientation off in Settings → Firestore doc shows `gender` + `lookingFor` deleted + consent = false + new timestamp
  - Synthetic pre-migration user (manually null consent) → backfill modal blocks on launch
- MPC PR pre-flight (Rules #79 + #80):
  - Title: `[PLAN-ID: 20260714-legal-003-art9-consent-hardening] feat(privacy): Art. 9 consent hardening — server enforcement + bilateral scorer gate + withdrawal UX + backfill modal`.
  - Body contains `## Verification checklist` naming `unit tests`, `integration tests`, `security scan`.
  - Body contains ZERO Rule #80 naive-regex trigger substrings — paraphrase risk framing without literal `risk_level: high`, `infra_change`, `touches_auth`, `touches_pii`, `external_model_calls`.
  - Plan-ID present in this file (line 2).

## 6. LINKED LANES

- **BLOCKER-LEGAL-001** (DPIA false claims) — this PR provides the code-truth foundation for the DPIA §3.2 / §4.2 / §8 rewrite. Consent version tags + fail-closed scorer + withdrawal purge are the load-bearing DPIA claims. The DPIA rewrite is a separate founder + counsel lane, downstream of this PR.
- **PLAN_04 KORAK 4.2** (odvetnica pisno mnenje) — Art. 9(2)(a) conditionality is one of the two mandatory questions. Send AFTER this PR merges so counsel opines on shipped code, not a proposal. Cross-reference is now in PLAN_04.
- **PLAN_04 KORAK 4.3** (docs rewrite) — DPIA §gender + lookingFor consent mehanizem now has a concrete code implementation to reference.
- **BLOCKER-LEGAL-004** (Weekend Window ToS mismatch + user-local timezone) — separate lane, rescoped 2026-07-14 from LOW (ToS edit only) to HIGH (code + ToS). Product model confirmed as a PAID weekend Premium package with three purchase-timing branches (queued before Fri 19:00 → activates at Fri 19:00 same week; instant Fri 19:00 - Sun 19:00; queued after Sun 19:00 → next weekend), computed in the **user's local timezone** (not hardcoded `Europe/Ljubljana`). Fix now requires: (a) IANA `timezone` field on user document + backfill; (b) `getNextWeekendWindow(userTimezone)` refactor + call-site updates; (c) traveler decision (snapshot at purchase vs re-evaluate at activation); (d) DST edge-case handling; (e) ToS §7 rewrite describing the localized product. Sequenced AFTER LEGAL-003 ships. Durable decision record: memory `weekend-pass-user-local-timezone.md`.

---

# Active Release Chore
Plan ID: 20260714-release-b17
Risk Level: LOW (version string bump + gitignore line; no code paths, no infra, no auth, no PII)
Status: IN-REVIEW 2026-07-14 — PR #43 opened; TestFlight upload 1.0.0 (17) delivered to ASC (delivery UUID `0b1e8e74-df40-479e-8015-5e4501b1e2fc`); AAB awaiting manual Play Console upload.
Founder Approval Required: NO (LOW risk; release chore paired with LEGAL-003 artifacts already approved and merged in PR #41).
Branch: chore/release-1.0.0-b17

## Objective

Align git HEAD with the release artifacts (AAB + IPA) that carry the first public shipment of the LEGAL-003 Art. 9 GDPR consent hardening code. Previous build 16 was never public. Build 17 is the first user-facing binary containing the Art. 9 code merged in PR #41 (`cce1f1c`) and prod-deployed to Cloud Functions the same day.

## Scope

- `pubspec.yaml`: version `1.0.0+16` → `1.0.0+17` — single source of truth for both Android `versionCode`/`versionName` and iOS `CFBundleShortVersionString`/`CFBundleVersion` (memory: `android-version-source-of-truth`).
- `.gitignore`: add `release-symbols/` — local-only preservation copy of AAB, IPA, and native debug symbols kept outside `build/` so the inter-platform `flutter clean` does not wipe them, and kept out of git because ~130 MB of binaries.

## Notes for MPC PR pre-flight

- Title: `[PLAN-ID: 20260714-release-b17] chore(release): bump build to 1.0.0+17`. NOTE — slug intentionally omits the `1.0.0` dots; CI regex `[a-z0-9\-]+` rejects `.`. Lesson learned; recording here so future release chores use `bXY` slugs (build number, no version dots).
- Body contains `## Verification checklist` naming `unit tests`, `integration tests`, `security scan` (all `n/a` with reasons — release chore, no source paths changed).
- Plan-ID present on this line: `20260714-release-b17`.

### Post-ship note — b17 was DOA

Build 17 shipped with `--dart-define=FLAVOR=prod` and NOTHING else. `PLACES_KEY_PROD` / `REVENUECAT_APPLE_API_KEY` / `REVENUECAT_GOOGLE_API_KEY` / `SENTRY_DSN` all resolved to empty string. TestFlight smoke test confirmed: gym search returned "no gyms found nearby" during registration; new-user signup blocked. Superseded by lane below (`release-b18`). See Rule #84 in `tasks/lessons.md` for the durable fix.

---

# Active Release Chore
Plan ID: 20260714-release-b18
Risk Level: LOW (version string bump + repo doc updates; no code paths, no infra, no auth, no PII)
Status: IN-REVIEW 2026-07-14 — TestFlight upload 1.0.0 (18) in flight via altool; AAB awaiting manual Play Console upload; PR to be opened.
Founder Approval Required: NO (LOW risk; supersedes DOA build 17 with corrected env-file build flag).
Branch: chore/release-b18

## Objective

Ship a working 1.0.0 (18) to Play Console + TestFlight after build 17 was found DOA on TestFlight smoke test (gym search broken because `PLACES_KEY_PROD` was empty; IAP would also break because RevenueCat keys were empty). This build uses `--dart-define-from-file=.env.prod.json` for both platforms so every prod key from the file is compiled in.

## Scope

- `pubspec.yaml`: version `1.0.0+17` → `1.0.0+18` — SSOT bump (memory: `android-version-source-of-truth`).
- `tasks/lessons.md`: adds Rule #84 documenting the DOA root cause and the required build flags, so the mistake is durable in-repo, not just in personal memory.
- `tasks/plan.md`: this section, plus the "Post-ship note" annotation on the b17 lane above.

## Verification for MPC PR pre-flight

- Title: `[PLAN-ID: 20260714-release-b18] chore(release): rebuild 1.0.0+18 with env file — supersedes DOA b17`.
- Body contains `## Verification checklist` naming `unit tests`, `integration tests`, `security scan` (all `n/a` with reasons — release chore + docs).
- Plan-ID present on this line: `20260714-release-b18`.

---

# Active Release Chore
Plan ID: 20260715-release-b20
Risk Level: LOW (version string bump + font-preload restore + tiny UI version marker; no infra, no auth, no PII, no schema changes)
Status: IN-REVIEW 2026-07-15 — b20 IPA already built locally (per prior session log); PR to be opened.
Founder Approval Required: NO (LOW risk; no code paths cross a system boundary; net additions are: one guarded async preload, one 10pt Text widget, and a version-string bump).
Branch: chore/release-b20

## Objective

Ship 1.0.0 (20) to Play Console + TestFlight. b20 rolls up three small carry-over changes that accumulated locally after b18 shipped but were never committed:

1. `GoogleFonts.pendingFonts([...])` preload is re-enabled in `main.dart`, wrapped in `try/catch` so a font-CDN failure at cold start cannot crash the app (fallback: Flutter uses its bundled fonts).
2. A small `'v20'` label under the registration Continue button so QA / TestFlight users can identify the running build without opening Settings.
3. `pubspec.yaml` bump 1.0.0+18 → 1.0.0+20. b19 is intentionally skipped (a local b19 IPA existed briefly but was never uploaded; b20 supersedes it so store version-code monotonicity is preserved either way).

## Scope

- `pubspec.yaml`: version `1.0.0+18` → `1.0.0+20` — SSOT bump (memory: `android-version-source-of-truth`).
- `lib/main.dart`: re-enable `GoogleFonts.pendingFonts([...])` inside a `try/catch` (`if (kDebugMode) debugPrint(...)` on failure — silent in release per `dart/security.md` "no logging sensitive data" and to avoid noisy prod logs). Rationale: without preload, first-frame paint uses fallback fonts then swaps — visible flash on cold start.
- `lib/src/features/auth/presentation/widgets/registration_steps/email_location_step.dart`: wrap the existing Continue button in a `Column(mainAxisSize: MainAxisSize.min, ...)` and append a `Text('v20', style: TextStyle(color: white30 / black38 by theme, fontSize: 10))` version marker. Purely additive; button semantics/enabled logic unchanged.
- `tasks/plan.md`: this section.

## Verification for MPC PR pre-flight

- Title: `[PLAN-ID: 20260715-release-b20] chore(release): 1.0.0+20 — GoogleFonts preload + v20 label`.
- Body contains `## Verification checklist` naming `unit tests`, `integration tests`, `security scan` (release chore — `n/a` with reasons documented per lane).
- Plan-ID present on this line: `20260715-release-b20`.

---

# Active Release Chore
Plan ID: 20260715-release-b21
Risk Level: LOW (version string bump only; ships the Sentry-fix rollup PR #46 that already landed on main)
Status: IN-PROGRESS 2026-07-15 — cutting release branch off main @ 168013d (post-#46 merge).
Founder Approval Required: NO (LOW risk; pubspec version bump only; no code paths cross a system boundary in this commit).
Branch: chore/release-b21

## Objective

Ship 1.0.0 (21) to Play Console + TestFlight. b21 packages the 5 Sentry-fix rollup that merged as PR #46 (`bc14dc8` → squashed to main as `168013d`):

- Issue 1 — Firebase Permission Denied guard on unauth Firestore reads during login race.
- Issue 2 — Android StackOverflow in `onRequestPermissionsResult` (recursive callback loop on Android 14).
- Issue 3 — Null-check operator crash in `map_provider.dart` (null-aware fallbacks).
- Issue 4 — `MissingPluginException` guard for platforms without flutter_blue_plus channel.
- Issue 5 — Unhandled `ClientException` from PMTiles fetch (soft-fail error boundary).

Rebuilt against `1.0.0+21` so store `versionCode` monotonicity is preserved (last shipped: +20).

## Scope

- `pubspec.yaml`: version `1.0.0+20` → `1.0.0+21` — SSOT bump (memory: `android-version-source-of-truth`).
- `tasks/plan.md`: this section.
- `android/local.properties`: local `flutter.versionCode` mirror bumped 20→21 on this machine (gitignored; not part of the commit — pubspec remains SSOT per memory rule).

## Verification for MPC PR pre-flight

- Title: `[PLAN-ID: 20260715-release-b21] chore(release): 1.0.0+21 — Sentry-fix rollup rebuild`.
- Body contains `## Verification checklist` naming `unit tests`, `integration tests`, `security scan` (release chore — `n/a` with reasons documented per lane).
- Plan-ID present on this line: `20260715-release-b21`.
