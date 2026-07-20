# Blockers & Investigation Findings

---

## POST-MATCH FLOW REPAIR (Session 50-51 — branch `fix/post-match-flow-repair`, PR #69)

> Full detail + priority order in `context.md` Session 51. Batch 2 shipped in build 29.

### BLOCKER-POSTMATCH-CI — PR #69 CI red (blocked merge)
**Status:** ✅ RESOLVED (Session 51, `a9ba5eb`). **The Session-50 root-cause guess was wrong.** The CI failure was NOT TREMBLE-FUNCTIONS-12 — it was a Flutter framework assert *"ListTile background color or ink splashes may be invisible"* (×2), fired because `UgcActionSheet` wrapped its `ListTile`s in an opaque `Container`/`DecoratedBox` with no `Material` between. It only reproduces on CI's newer `stable` Flutter (local is pinned 3.41.4 → passes locally). Fixed structurally: the sheet surface is now a `Material(color:)`. See lesson #93.

### BLOCKER-POSTMATCH-DIALOGS — iOS block + report broken (crash TREMBLE-FUNCTIONS-12)
**Status:** ✅ RESOLVED (Session 51, `a9ba5eb`). Block + report rebuilt as themed **Material bottom sheets**; dropped `CupertinoAlertDialog`/`TrembleAlertDialog` for these two. No more `Platform.isIOS` branch → no `Material.of` null, testable on all platforms, dark-themed (#9), report scrolls with a Submit (#10), block works (#8). `ugc_action_sheet.dart` rebuilt (`_BlockConfirmSheet` + `_ReportSheet`). NOTE: `tremble_alert_dialog.dart` still used by settings/edit-profile/discard/safe-zones/email-location — those are Text-only confirms (no Material-in-Cupertino), left as-is. **Needs iOS device verification on build 29.**

### BLOCKER-POSTMATCH-PHOTO — reveal "?" (email gate)
**Status:** 🔧 FIX SHIPPED TO BRANCH + DIAGNOSTIC DEPLOYED (Session 52, `e87f73c` + `fc737e6`), awaiting build-30 device confirm.

**Session-52 resolution (two-track, per founder decision):**
- **Root-cause instrumentation (deployed to prod):** `getPublicProfile` now logs which branch nulls the reveal (`target-doc-missing | caller-in-blockedBy | no-match-doc | OK`) — `functions/src/modules/users/users.functions.ts`. Redeployed to `am---dating-app`/europe-west1 (`fc737e6`). Because the current source already carries `requireAuth` (`dbbc7b7`), this redeploy ALSO tests the "stale email-gate deploy" hypothesis — if that was the cause, the reveal recovers on build 29 immediately. **Next device tap writes the decisive log line** (Firebase console → Functions → getPublicProfile logs, `[USERS getPublicProfile]`).
- **Preferred fix (client, `e87f73c`):** reveal + trembling window re-sourced from `getMatches`/`MatchProfile` via new `partnerMatchProfileProvider` — the proven People-tab path — so partner photo/name/age no longer depend on `getPublicProfile`. Also added the always-visible `TremblingPartnerCard` (FEATURE-POSTMATCH-TREMBLING-REDESIGN step 2). run-club `LiveRunCard` (home_screen:2464) stays on `getPublicProfile` (pre-match strangers, not in getMatches). 380/380 Flutter + 163 CF green, analyze clean.
- **REMAINING:** build 30 → device: (a) reveal + trembling window show real identity; (b) partner card tap → profile (premium) / paywall (free); (c) read the CF log to confirm the original cause and decide if the diagnostic can be removed / whether recap needs the same re-source.

**Prior (Session 52 investigation) —** The `requireVerifiedEmail`→`requireAuth` deploy (`dbbc7b7`) did NOT fix it — build 29 STILL shows "?" on the match page AND no partner identity in the trembling window. `publicProfileProvider(partnerId)` → `getPublicProfile` returns null/throws and is **silently swallowed** (reveal `.whenOrNull(data:)`; `ProfileRepository.getPublicProfile` throws on `profile==null`) — zero Sentry events for `release:…@1.0.0+29`. RULED OUT: match-ID mismatch (creation `matches.functions.ts:593` + CF lookup both sorted `uidA_uidB`) and match-doc schema (`matches.functions.ts:682` has userA/userB/userIds). Cause UNKNOWN. **P0. Next:** (a) surface the swallowed error — temporary `Sentry.captureException` in the client repo catch OR per-branch logging in the CF + redeploy — to learn permission vs App-Check vs match-gate; (b) PREFERRED FIX: re-source the reveal + profile card + history from `getMatches`/`MatchProfile` (`matches.functions.ts:964`, `match_repository.dart:126/189`), which already returns name/age/photoUrls/hobbies via Admin SDK and works for the matches list — one proven path, sidesteps getPublicProfile.

### FEATURE-POSTMATCH-TREMBLING-REDESIGN — always-visible profile card + full intercept flow (Session 52 founder spec)
**Status:** OPEN (design locked, see context.md Session 52 target spec). Trembling window top→bottom: (1) partner profile card — circle photo + name/age under it, ALWAYS visible, tap → free/premium full card; (2) radar (spinning, partner dot past the circle edge); (3) pulse intercept — Send Photo opens camera (Snapchat-style) → send → recipient notification/pill → tap opens photo; Send Phone → recipient notification → tap → dialer/call; + timer + working Stop. History → free-user basic card (not greyscale). `RadarSearchOverlay` already carries `partnerUid`; extend to show the card (source from `MatchProfile`).

### FEATURE-POSTMATCH-INTERCEPT — move Pulse Intercept into the trembling window
**Status:** ✅ RESOLVED (Session 51, `095b50c`). New `PulseInterceptBar` widget (`match/presentation/widgets/`); rendered in `RadarSearchOverlay` (the trembling window) above the countdown when `session.partnerUid != null` (prod passes computed `partnerId`, dev-sim `profile.id`). Removed from `match_reveal_screen` (reveal = photo+age+3 hobbies). **Needs device verification of placement.** Still OPEN (uninvestigated, cluster 3): pulse-intercept notification image never viewable + duplicate 2× on the send/receive side.

### UI-POSTMATCH-PILLS — in-app pills too high
**Status:** ✅ PARTIAL (Session 51, `e094a5d`). `WavePillService` pill moved `topPad+14 → topPad+80` (matches `_MatchNotificationPillOverlay`), clears the mode + schedule control bar. **STILL OPEN:** iOS "wave sent" shows 2× overlapping "is nearby" — presentation dedup between the local pill and the APNs pill (cluster 2). Needs device repro.

### FEATURE-POSTMATCH-NOTIFTAP — notification tap opens profile card
**Status:** OPEN (Step 4, NOT done). Tapping a "nearby" / "wave" notification must open the partner's profile card (free vs premium view differs). Deferred: needs notification-tap handler wiring (`router.dart` / `notification_service` / `wave_pill_service`) + the free/premium card + device verification.

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
**Status:** RESOLVED 2026-07-16 — code and live policy reconciled
**Impact:** `Info.plist` stated contacts are not accessed, but Privacy Policy §2.5 says they are. Apple 5.1.1 rejection risk.
**Resolution (PR fix/info-plist-contacts-reconcile, KORAK 3.8-1):**
- Master `NSContactsUsageDescription` rewritten to match localized `en.lproj/InfoPlist.strings` verbatim (describes Anonymity Mode / ADR-004).
- Three duplicate permission keys removed from Info.plist (NSCameraUsageDescription, NSPhotoLibraryUsageDescription, NSPhotoLibraryAddUsageDescription). Founder decision 2026-07-13: kept the L46/L48 wording that covers Pulse Intercept (v1 feature); L50-51 replaced with the Apple-preferred explicit-consent NSPhotoLibraryAdd variant.
- `PrivacyInfo.xcprivacy` now declares `NSPrivacyCollectedDataTypeContacts` (Linked=false per ADR-004 hash-only transmission; Tracking=false; Purpose=AppFunctionality).
**Live-policy verification (2026-07-16):** `trembledating.com/privacy` §2.5 now describes the on-device SHA-256 Anonymity Mode flow and states that hashes are not stored. The previously owed web-copy correction is complete.
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

### BLOCKER-STORE-005 — Production APNs Credential Verification
**Date:** 2026-07-16
**Status:** OPEN — code-side repair deployed; Firebase/Apple credential gate pending
**Impact:** Production iOS FCM delivery previously returned the invalid-APNs-credential error class. Bundle ID `tremble.dating.app`, Firebase iOS App ID `1:343655004163:ios:5eea92b9656fc3b8fc3636`, Team ID `LB6LS532CV`, production entitlement, and build-22 signing metadata align, leaving the APNs credential stored under the Firebase Apple app as the strongest unresolved cause. App Store submission must not be declared push-ready until a controlled device send succeeds.
**Progress:**
- ✅ `scanProximityPairs` and `onWaveCreated` identity/delivery/retry fixes deployed to `am---dating-app` in `europe-west1` on 2026-07-16.
- ✅ APNs delivery CONFIRMED working: 2026-07-18 08:48:03 prod scan sent two visible CROSSING_PATHS (`pairsNotified:2`, `notification_sent`) to both test accounts — the credential class error is resolved in practice. Delivery is no longer the blocker.
- ✅ **Wave pill render bug fixed (build 26)** — `presentWavePill` read the overlay from `Overlay.maybeOf(currentContext)` (always null), so the pill never showed foreground OR tap. Fixed to `currentState.overlay` (PR #65) + bounded readiness retry + Sentry give-up (PR #62). See Rule #86. This was the actual cause of "nothing showed", NOT APNs.
- ✅ **Freeze fix (PR #60) shipped in build 25**; build 26 carries it too. Both platforms of build 26 are up (TestFlight Delivery UUID `2024e76c-bed2-4b21-a6f2-f0f57c4b6835`; AAB at `release-symbols/b26/`).
- ⏳ **Device verification of build 26 is the only remaining gate**, using `send_test_push.ts` (Rule #88): (a) foreground → pill, no freeze; (b) background tap → pill; (c) killed tap → cold-launch pill; (d) airplane map → offline card. If a pill drops, Sentry (`tremble-functions`, dist 26) logs `wave pill dropped: auth-null|no-overlay`.
**Action:** Founder runs the build-26 device matrix (Rule #88). On green, STORE-005 closes and the freeze fix is proven in the same pass. APNs credential inspection is no longer required — delivery is confirmed.

---

## Security Follow-ups (Not Submission Blockers)

### FOLLOWUP-SEC-002 — Production Runtime Values Printed in a Local Tool Transcript
**Date:** 2026-07-16
**Status:** OPEN — security-hygiene follow-up; no public or source-control exposure found
**Impact:** A globally enabled shell `DEBUG` variable caused Firebase CLI diagnostics to print runtime configuration into the local authenticated tool transcript. This was not a public chat, no value entered Git history, and committed-diff scans passed. A local transcript has a wider retention surface than the terminal, so true server-side credentials should still be rotated as prudent hygiene, but this is not evidence of public compromise and does not block App Store submission.
**Scope:** Rotate only actual server secrets (for example R2, Resend, and Upstash credentials). Do not classify public client identifiers such as a RevenueCat SDK key or Sentry DSN as secrets. Provider-restricted client keys should be reviewed against their platform restrictions before deciding whether rotation adds value.
**Action:** Remove or scope the global `DEBUG` variable, rotate genuine server secrets in a separate approved production-config lane, validate each replacement before revoking the old value, and never paste credential values into issues, commits, or chat.

**2026-07-19 — second exposure (Session 52).** During the getPublicProfile diagnostic redeploy, a Cloud Run revision spec (full `env` block) was pasted into the assistant chat transcript, printing plaintext values of three genuine server secrets. Rotate these in the approved config lane, validating each new value before revoking the old:
- `R2_SECRET_ACCESS_KEY` (+ its `R2_ACCESS_KEY_ID`)
- `RESEND_API_KEY`
- `UPSTASH_REDIS_REST_TOKEN`

Public/client identifiers in the same block (`SENTRY_DSN`, `REVENUECAT_APPLE_API_KEY`) are NOT secrets; `PLACES_KEY_PROD` is a provider-restricted client key — review its API restrictions rather than rotate. To read function logs without dumping env, use Logs Explorer filtered to `resource.labels.service_name` + a `textPayload:` term, not the revision spec. Not an App Store submission blocker.

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
**Status:** RESOLVED 2026-07-14 — PR #41 merged into `main` @ cce1f1c. Cloud Functions deployed to prod (`am---dating-app`, europe-west1) same day; `withdrawArt9Consent` created, `updateProfile` + `completeOnboarding` updated with the enforcement.
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
**Action:** DONE (PR merged, prod deployed). Downstream lanes now unblocked: BLOCKER-LEGAL-001 (DPIA rewrite), PLAN_04 KORAK 4.2 (pisno mnenje to counsel — send with the two mandatory questions now that shipped code exists to reference), PLAN_04 KORAK 4.3 (Privacy Policy §art9-* anchors). (Task 6h3j9q65vh3mG64P — mark done)

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

**Session-53 amendment (2026-07-20) — `premium_feature_open_profile_cards` gate boundary.** BUG-HISTORY-CARD-TAP changed the Free + mutual tap from a bare paywall to a read-only **basic card** (`BasicMatchProfileScreen`: photo + name/age + 3 hobbies) with a subtle "See full profile · Premium" CTA → paywall. The paywall bullet stays truthful because the **full** profile card (`ProfileDetailScreen`) remains Premium-only (`isPremium && hasMutualWave`, route `/profile`; Free routes to `/profile?...&basic=true`) and the CTA explicitly advertises it. See ADR-007 §1 Amendment (Session 53). No paywall-copy change required.

---

## ARCHIVED BLOCKERS (Resolved)

> **B001 / ADR-001** (iOS BLE Background State) ✅ RESOLVED 2026-04-29
> **B002 / D-37** (3-State Map Toggle) ✅ RESOLVED 2026-04-29
> **B003** (Company Setup / RevenueCat) ✅ RESOLVED 2026-05-07
> **B004 / F5** (Strava/Health Integration) ✅ REMOVED 2026-04-30
> **B005** (iOS Dev Provisioning for com.pulse) ✅ RESOLVED
> **B006** (Photo Upload / Onboarding E2E) ✅ RESOLVED
> **B007** (Legal Web Pages Live) ✅ RESOLVED 2026-05-26
