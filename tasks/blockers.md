# Blockers & Investigation Findings

---

## CRITICAL — Store Blockers (Pred Submissionom)

### BLOCKER-STORE-001 — iOS Privacy Manifest & Encryption Declaration
**Date:** 2026-07-06
**Status:** RESOLVED 2026-07-14 — verified via Rule #82 3-surface audit (KORAK 3.9-2)
**Impact:** App Store will automatically reject the build starting from iOS 17.4 without a privacy manifest. Missing encryption declaration will cause App Store Connect rejection.
**Resolution (audit evidence, 2026-07-14):**
- `ios/Runner/PrivacyInfo.xcprivacy` present and `plutil -lint` clean.
- **NSPrivacyAccessedAPITypes** — all 4 Required Reasons API categories declared: UserDefaults (CA92.1), FileTimestamp (C617.1), SystemBootTime (35F9.1), DiskSpace (E174.1).
- **NSPrivacyCollectedDataTypes** — 10 categories declared covering CoarseLocation, PhotosorVideos, Name, EmailAddress, PhoneNumber, UserID, PurchaseHistory, CrashData, OtherDiagnosticData, and Contacts (Linked=false per ADR-004 hash-only transmission).
- **`Info.plist` encryption declaration** — `ITSAppUsesNonExemptEncryption = false` present (Info.plist line verified via grep).
- **Rule #82 surface (a) master↔localized divergence** — 7 present keys byte-identical between master `Info.plist` and `en.lproj/InfoPlist.strings`.
- **Rule #82 surface (b) duplicate-key sweep** — every `NS*UsageDescription` key counts exactly 1 in master Info.plist.
**Follow-up (non-blocker, LOW):** `sl.lproj/InfoPlist.strings` and `hr.lproj/InfoPlist.strings` do NOT localize NSCameraUsageDescription, NSPhotoLibraryUsageDescription, NSPhotoLibraryAddUsageDescription — iOS falls back to the English master string for those 3 prompts on Slovenian/Croatian device locales. Not a submission blocker (no lie, no divergence) but a UX gap worth a future translation sprint. (Task 6h3grHhjVXFhMRJP, 6h3grHqC22mCcccP)

### BLOCKER-STORE-002 — iOS Info.plist Contacts Contradiction
**Date:** 2026-07-06
**Status:** RESOLVED 2026-07-13 — code side reconciled
**Impact:** `Info.plist` stated contacts are not accessed, but Privacy Policy §2.5 says they are. Apple 5.1.1 rejection risk.
**Resolution (PR fix/info-plist-contacts-reconcile, KORAK 3.8-1):**
- Master `NSContactsUsageDescription` rewritten to match localized `en.lproj/InfoPlist.strings` verbatim (describes Anonymity Mode / ADR-004).
- Three duplicate permission keys removed from Info.plist (NSCameraUsageDescription, NSPhotoLibraryUsageDescription, NSPhotoLibraryAddUsageDescription). Founder decision 2026-07-13: kept the L46/L48 wording that covers Pulse Intercept (v1 feature); L50-51 replaced with the Apple-preferred explicit-consent NSPhotoLibraryAdd variant.
- `PrivacyInfo.xcprivacy` now declares `NSPrivacyCollectedDataTypeContacts` (Linked=false per ADR-004 hash-only transmission; Tracking=false; Purpose=AppFunctionality).
**Still-owed (founder, PLAN_04 KORAK 4.2):** align `trembledating.com/privacy` §2.5 web copy with Anonymity Mode + hashed transmission. Required before actual App Store submission.
(Task 6h3p8gWpxpq7rWXw)

### BLOCKER-STORE-003 — Android Background Location Declaration
**Date:** 2026-07-06 (updated 2026-07-07)
**Status:** OPEN — code side done, Play Console side pending
**Impact:** Requires Prominent Disclosure, a demo video, and a special declaration in Google Play Console. This review process takes 2-4 weeks and blocks Android launch.
**Progress (2026-07-14 update, PR pending, KORAK 3.9-4):**
- ✅ Standalone Prominent Disclosure screen added at `lib/src/features/auth/presentation/prominent_disclosure_screen.dart` — shown between foreground grant and OS background prompt on both Android and iOS. (PR #7 / commit a3f793b, 2026-07-07)
- ✅ Consent flow refactored so the OS `ACCESS_BACKGROUND_LOCATION` prompt only fires after the disclosure's primary CTA is tapped. "Not now" completes onboarding with foreground-only location.
- ✅ Android is now a first-class background-location caller (previously the manifest permission was silently dormant).
- ✅ **Brand-voice pass (2026-07-14, KORAK 3.9-4):** EN + SL body copy swaps generic "matches / ujemanja" for Tremble's radar lexicon "signals / signale" to reinforce Rule #3 (Wave-based mechanic, no chat). EN also swaps "deleted" → "cleared" to soften legalese without diluting the disclosure. Play-policy phrases ("approximate location / približno lokacijo", "in the background / v ozadju", "Allow background location / Dovoli lokacijo v ozadju") preserved verbatim. Test `prominent_disclosure_screen_test.dart` now pins the brand-voice keywords so a future refactor can't silently regress.
- ⏳ EN + SL screenshots of the new screen must be captured on an emulator/device for the Play submission package.
- ⏳ Play Console declaration + demo video still need to be submitted.
**Action:** Capture EN + SL screenshots, record demo video, submit Play declaration. Copy review DONE. (Task 6h3p8gWG7WHWV7JP)

### BLOCKER-STORE-004 — Android Foreground Services Declaration
**Date:** 2026-07-06
**Status:** OPEN
**Impact:** FGS types (location, connectedDevice, dataSync) require Google Play declaration.
**Action:** Submit FGS declaration to Google Play. (Task 6h3p8gc78572RF9P)

---

## CRITICAL — Legal Blockers (Pred Submissionom)

### BLOCKER-LEGAL-001 — DPIA False Claims
**Date:** 2026-07-06
**Status:** OPEN
**Impact:** DPIA falsely claims `getPublicProfile` doesn't leak sensitive data, and lists incorrect TTLs (24h vs 2h). Evidence of discrepancy during an audit is an aggravating factor.
**Action:** Fix DPIA to match codebase reality. (Task 6h3jFhxVHpRmph9P)

### BLOCKER-LEGAL-002 — Cannabis Legal Classification
**Date:** 2026-07-06
**Status:** RESOLVED 2026-07-14 — cannabis removed from product entirely (stronger than the original "separate into own field" action)
**Impact:** `nicotineUse` bundled cannabis with vape. In some jurisdictions, cannabis data is "criminal offense data" (Art. 10 GDPR), meaning consent cannot legitimize it.
**Resolution (audit evidence, 2026-07-14):**

Cannabis is unreachable across every surface of the product:

| Surface | Evidence | Verified |
|---|---|---|
| Registration UI | `lib/src/features/auth/presentation/widgets/registration_steps/nicotine_step.dart:15-19` — only 5 options offered: `cigarettes`, `vape`, `iqos`, `zyn`, `shisha`. No cannabis chip. | ✅ |
| Server API (Zod) | `functions/src/modules/users/users.schema.ts:17-23` — `nicotineUseValueSchema = z.enum(["cigarettes", "vape", "iqos", "zyn", "shisha"])`. Any request that sends `"cannabis"` is rejected with 400 at the API boundary. | ✅ |
| Edit-profile display | `lib/src/features/profile/presentation/edit_profile_screen.dart:124` — `..addAll(user.nicotineUse.where((v) => v != 'cannabis'))` defensively filters legacy Firestore entries out of the render. | ✅ |
| Legacy Firestore data | `functions/src/scripts/remove_cannabis.ts` migration ran against **prod (`am---dating-app`)**. Founder confirmed 2026-07-14. `FieldValue.arrayRemove("cannabis")` is idempotent — subsequent user writes cannot re-introduce it. | ✅ |

**Why stronger than the original action:** the blocker's original ask was to "separate cannabis into its own field pending legal review." The founder chose to *remove* cannabis entirely instead. No collection → no consent needed → no Art. 10 exposure at all. This closes the risk without waiting for a per-jurisdiction legal opinion.

**Related:** PLAN_00 §Deluje records "Kanabis + politična pripadnost: odstranjena iz kode (grep = 0 zadetkov v main)" — verifies the code-side removal. This closeout adds the schema-boundary + display-filter + prod-migration evidence. (Task 6h3jHjr7Hf58G8pw)

### BLOCKER-LEGAL-003 — Sexual Orientation (GDPR Art. 9) Missing Consent
**Date:** 2026-07-06
**Status:** IN-REVIEW 2026-07-14 — 7-step hardening shipped on branch `feature/legal-003-art9-consent-code`, pending founder + code-reviewer sign-off + merge. Marks as RESOLVED on merge.
**Impact:** The combination of `gender` + `lookingFor` implicitly reveals sexual orientation. As an Art. 9 category, processing without explicit consent is a massive GDPR violation (Grindr fined NOK 65M for this).
**Resolution (branch pending merge, Plan-ID 20260714-legal-003-art9-consent-hardening):**
- Server write-time enforcement in `updateProfile` — Art. 9 field writes (gender / lookingFor / religion / ethnicity) rejected unless the effective consent for that category is `=== true`. Same-request grants honoured; same-request withdrawals rejected.
- New `withdrawArt9Consent` callable that writes consent=false + version + timestamp AND `FieldValue.delete()`s the corresponding sensitive field(s) (orientation withdrawal deletes both gender + lookingFor).
- `completeOnboarding` drops religion + ethnicity to `null` when the paired consent flag isn't true so nothing lands in Firestore that the scorer would then read behind the bilateral gate.
- Bilateral fail-closed orientation gate in `compatibility_calculator.ts` on the `lookingFor` hard filter, mirroring the existing religion + ethnicity pattern.
- All three Art. 9 consent tiles rewritten with narrow-purpose text (v1) + PP anchor deep-link. Select-all no longer flips Art. 9 optionals — Art. 9(2)(a) "specific" consent requirement. EN + SL + HR translations.
- Settings-screen withdrawal UI (`privacy_consents_section.dart`) with confirmation dialog + destructive server call.
- App-launch backfill modal (`backfill_consent_modal.dart`) for pre-migration users with `sexualOrientationConsent == null`; PopScope-locked, accept/decline both server-first (not optimistic) so a network failure keeps the modal open.
- Server stamps `{category}ConsentVersion = "v1"` + `{category}ConsentAt = serverTimestamp()` on every grant OR withdrawal so future consent-text bumps can re-prompt v1 users through the same backfill machinery.
- Test coverage: 10 new CF assertions in `users.test.ts`, 4 new pair-of-tests in `compatibility_calculator.test.ts`, 7 widget assertions in `backfill_consent_modal_test.dart`, 3 in `privacy_consents_section_test.dart`, updated `consent_step_test.dart` (17 assertions after Step 3+4). 134/134 CF + 275/275 Flutter tests green.
**Action:** Merge the PR after founder + code-reviewer sign-off. Then close BLOCKER-LEGAL-001 (DPIA rewrite) since this PR is its code-truth foundation, and send the pisno mnenje request to counsel per PLAN_04 KORAK 4.2 (they should opine on shipped code, not a proposal). (Task 6h3j9q65vh3mG64P)

### BLOCKER-LEGAL-004 — Weekend Window ToS Mismatch + user-local timezone
**Date:** 2026-07-06 (rescoped 2026-07-14)
**Status:** OPEN — scope escalated from LOW (ToS edit only) to HIGH (code + ToS)
**Impact:** Two-layer problem.
- **Layer 1 (original):** ToS §7 promises an "automatic weekend window (Fri 19h - Sun 19h)" but the actual product model is a PAID Premium mini-package (Weekend Getaway) with flat pricing, three purchase-timing branches (queued if bought pre-Fri 19:00 → activates at Fri 19:00 same week; instant if bought Fri 19:00 - Sun 19:00; queued for next weekend if bought post-Sun 19:00), NOT an automatic free unlock. Unfair business practice / consumer deception risk.
- **Layer 2 (discovered 2026-07-14):** `getNextWeekendWindow` computes against hardcoded `Europe/Ljubljana`. A California user buying Weekend Getaway on Friday morning PST would see it activate at Thu 10:00 AM PST (Fri 19:00 CET) and expire Sun 10:00 AM PST — wrong product. The window must be computed in the **user's local timezone** (founder confirmed 2026-07-14).
**Rescoped action:** No longer a 5-min ToS edit. The lane now requires (a) `timezone: string` (IANA) field on user document + backfill for existing SI/HR users, (b) `getNextWeekendWindow(userTimezone)` refactor + all callers, (c) traveler decision (snapshot at purchase vs re-evaluate at activation), (d) DST edge-case handling for Fri-19:00 transition weekends, THEN (e) ToS §7 rewrite describing the paid weekend package in user-local time. Sequenced AFTER LEGAL-003 ships. See memory `weekend-pass-user-local-timezone.md` for the durable decision record. (Task 6h332RFRW946QWXw)

### BLOCKER-LEGAL-005 — Paywall False Advertising
**Date:** 2026-07-06
**Status:** RESOLVED 2026-07-14 — verified via bullet↔gate audit (KORAK 3.9-3)
**Impact:** Paywall advertised features that didn't exist in code ("unlimited geofence pings") and hid features that were actually gated ("see who waved"). Apple 3.1.2 rejection risk + consumer protection.
**Resolution (audit evidence, 2026-07-14):**

The KORAK 3.7 series (2026-07-13) already rewrote `premium_screen.dart` against the ADR-007 tier matrix. Every current Premium bullet maps to a real, implemented code gate:

| Bullet key | Backend / client gate | Evidence |
|---|---|---|
| `premium_feature_radar_extended` | 250 m + −85 dBm (vs Free 100 m + −75 dBm) | `lib/src/core/geo_service.dart:20-21` + `functions/src/modules/proximity/` |
| `premium_feature_mutual_waves_20` | Monthly cap 20 (vs Free 5), `Europe/Ljubljana` counter | `functions/src/modules/matches/matches.functions.ts:38-56` |
| `premium_feature_open_profile_cards` | Compound gate `isPremium && hasMutualWave` — three-state render | `lib/src/features/matches/presentation/matches_screen.dart:143` + `MatchProfile.hasMutualWave` field (`match_repository.dart:70`) |
| `premium_feature_recap_full` | Recap TTL 10-min + `isReadOnly = !isPremium \|\| isHistory \|\| isExpired` gates wave button and profile tap | `lib/src/features/recap/providers/recap_ttl_provider.dart` + `run_recap_screen.dart:498-503` |
| `premium_feature_near_miss_history` | Tab visible only when `isPremium`; Free shows upsell banner | `matches_screen.dart:40,54` |
| `premium_feature_hard_filters` | Soft-labelled "coming soon" in 8 locales per ADR-007 Amendment §2/§6 | `premium_screen_test.dart:99-153` locks localisation |
| `premium_feature_event_insights` | `effectiveIsPremium` gates participant count + heatmap chip | `lib/src/features/map/presentation/event_pin_sheet.dart:138,154,171` |

**Retired keys (LEGAL-005's original complaints) are gone AND test-locked as gone** in `test/features/settings/premium_screen_test.dart:75-97`: `premium_feature_unlimited_geofence`, `premium_feature_wider_radar`, `premium_feature_custom_themes`, `premium_feature_advanced_filters`, `premium_free_gym_mode`, `premium_free_local_radar`, `premium_free_wave_limit`, `premium_feature_distance_100`, `premium_free_distance_50`.

**Copy-rule enforcement** via `premium_screen_test.dart:155-189` scans user-facing strings for banned phrases (`revolutionary`, `seamless`, `game-changing`, `find love today`, `find your person`, `swipe`, `match queue`, `chat`) per ADR-007 §3.

**Follow-up (non-blocker, deferred):** ADR-007 §4 mandate — one *pair* of consistency tests per gate (Free hits gate / Premium doesn't). Partial coverage exists in `test/features/matches/matches_three_state_test.dart`, `test/features/subscriptions/revenuecat_subscription_test.dart`, and the `test/features/recap/` suite, but not systematically per-bullet. Not gating LEGAL-005 closure because the copy↔gate mapping is verified above; captured as a MEDIUM test-hardening lane in `tasks/plan.md` §3. (Task 6h3pmrF84Cf6JVQP)

**Deferred pair-of-tests lane — RESOLVED 2026-07-14 (Plan-ID `20260714-adr007-pair-of-tests-hardening`, branch `test/adr007-pair-of-tests-hardening`).** Coverage matrix across the 7 Premium bullets found 4 gates already well-covered (open_profile_cards, recap_full, near_miss_history, event_insights), 1 gate excluded by ADR-007 Amendment §2 (hard_filters — soft-labelled "coming soon", no behavioural gate), and 2 gaps to fill:

| Gate | Before | Added this lane |
|---|---|---|
| `premium_feature_radar_extended` | No test — the `_isPremium ? 'pro' : 'free'` tier ternary at `geo_service.dart:257` sits behind a Firebase-auth + `SharedPreferences` singleton, so a behavioural render is uneconomic. | New `test/core/geo_service_radar_tier_test.dart` — source-scan pair pinning the Free tuple (100 m + −75 dBm), the Premium tuple (250 m + −85 dBm), the shared ternary that writes both branches, and the `updatePremiumTier` runtime hook. Pattern mirrors `test/features/recap/recap_ui_wiring_test.dart` + `test/features/match/near_miss_locked_state_test.dart:146`. |
| `premium_feature_mutual_waves_20` (server) | Helper `mutualWaveLimitForUser` values pinned at `functions/src/__tests__/matches.test.ts:397` (Free=5, Premium=20). Client-side `hasReachedWaveLimit` already has an exhaustive threshold pair in `test/features/auth/auth_user_wave_limit_test.dart`. No server-side "at threshold, `count >= limit` is true" pair. | Two additional assertions in the existing `describe("mutual wave monthly counters")` block. Verifies that Free at count=5 satisfies the rejection predicate, Premium at count=5 does NOT, and Premium at count=20 does — mirrors the client-side threshold coverage at the server contract. |

All other gates have real widget or behavioural pairs; those files stay untouched. This close-out captures the deferred-lane execution referenced in the "Follow-up (non-blocker, deferred)" note above.

---

## ARCHIVED BLOCKERS (Resolved)

> **B001 / ADR-001** (iOS BLE Background State) ✅ RESOLVED 2026-04-29
> **B002 / D-37** (3-State Map Toggle) ✅ RESOLVED 2026-04-29
> **B003** (Company Setup / RevenueCat) ✅ RESOLVED 2026-05-07
> **B004 / F5** (Strava/Health Integration) ✅ REMOVED 2026-04-30
> **B005** (iOS Dev Provisioning for com.pulse) ✅ RESOLVED
> **B006** (Photo Upload / Onboarding E2E) ✅ RESOLVED
> **B007** (Legal Web Pages Live) ✅ RESOLVED 2026-05-26
