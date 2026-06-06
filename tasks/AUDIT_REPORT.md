# Strategy Compliance Audit Report

**Date:** 2026-06-06  
**Scope:** `tasks/audit_step2_waves.md` through `tasks/audit_step10_brand.md`  
**Purpose:** Decision document. No fixes applied.

## 1. Summary Table

Counts are normalized from the audit files. `CRITICAL` is counted separately and may also be part of `MISMATCH`.

| Domain | Claims checked | MATCH | MISMATCH | CANNOT VERIFY | CRITICAL |
|---|---:|---:|---:|---:|---:|
| Wave / Limits | 4 | 3 | 1 | 0 | 0 |
| Trembling Window / Pulse Intercept | 7 | 5 | 2 | 0 | 0 |
| History / Recaps / Near-Miss | 11 | 8 | 3 | 0 | 0 |
| Filters / Hard Filters | 4 | 2 | 2 | 0 | 0 |
| Heatmap / Map Events | 6 | 2 | 2 | 2 | 0 |
| Notifications | 7 | 0 | 7 | 0 | 0 |
| Privacy / TTL | 8 | 3 | 3 | 2 | 2 |
| Pricing / Premium-gating | 6 | 3 | 3 | 0 | 0 |
| Brand / Copy | 14 | 8 | 5 | 1 | 0 |
| **Total** | **67** | **34** | **28** | **5** | **2** |

## 2. CRITICAL Findings First

### CRIT-1 — GDPR request TTL field may not expire

- **Claim ID:** C-PRIVACY-06 / TTL storage limitation
- **File:line:** `functions/src/modules/gdpr/gdpr.functions.ts:153`, `functions/src/modules/gdpr/gdpr.functions.ts:233`
- **Strategy says:** GDPR/audit-retention records must respect storage limitation and expire after the intended retention period.
- **Code does:** Writes `ttl: twoYearsFromNow()` to `gdprRequests`, not `expiresAt`.
- **Recommended direction:** **Fix code or verify deployed TTL policy first.** If Firestore TTL policy targets `ttl` on `gdprRequests`, update strategy/control-plane evidence. If it targets `expiresAt`, rename the field or add the correct TTL field.
- **Why:** If the deployed TTL policy targets `expiresAt`, these records persist indefinitely despite the intended two-year cap. That is a legal-retention risk.

### CRIT-2 — Proximity geohash TTL field may not expire

- **Claim ID:** C-PRIVACY-04 / C-RADAR-11
- **File:line:** `lib/src/core/geo_service.dart:182-195`, `functions/src/modules/proximity/proximity.functions.ts:209-215`
- **Strategy says:** Proximity geohash documents must expire; strategy claims are internally inconsistent between 30 minutes and 24 hours.
- **Code does:** Flutter writes `geoHashExpiresAt`, not `expiresAt`; Cloud Function `updateLocation` writes no TTL field at all.
- **Recommended direction:** **Fix code or verify deployed TTL policy first.** If Firestore TTL policy targets `geoHashExpiresAt`, document it and make the strategy consistent. If it targets `expiresAt`, write `expiresAt` from all proximity write paths.
- **Why:** If Firestore TTL is not pointed at `geoHashExpiresAt`, proximity geohash/activity documents can persist beyond the promised window.

## 3. Non-critical Mismatches

### WAV-1 — Wave limit enforcement returns success before authoritative limit check

- **Claim ID:** C-WAVE-01 / C-WAVE-02
- **File:line:** `functions/src/modules/matches/matches.functions.ts:73-112`, `functions/src/modules/matches/matches.functions.ts:227-232`
- **Strategy says:** Mutual waves are capped at 5/month Free and 20/month Premium.
- **Code does:** Constants and monthly counter are correct, but `sendWave` writes the wave and returns success before the background `onWaveCreated` trigger checks limits. Over-limit users can get a success response, and the trigger failure is silent to the client.
- **Recommended direction:** **Fix code.**
- **Why:** The backend authority is in the wrong phase of the flow. The callable should reject before writing, or otherwise atomically enforce the limit with user-visible failure.

### WAV-2 — Client wave limit reads the wrong counter source

- **Claim ID:** C-WAVE-01 / C-WAVE-02
- **File:line:** `lib/src/features/auth/data/auth_repository.dart:957-970`
- **Strategy says:** Client UX should reflect the same monthly wave count the backend enforces.
- **Code does:** Client reads `rateLimits/{uid}:wave_monthly`, while backend increments `users/{uid}.mutualWaves_YYYY_MM`.
- **Recommended direction:** **Fix code.**
- **Why:** This violates the existing project lesson that client guards must read the same source the backend writes. It can silently show the wrong limit state.

### WAV-3 — Premium users are not client-capped at 20/month

- **Claim ID:** C-WAVE-02
- **File:line:** `lib/src/features/profile/presentation/profile_detail_screen.dart:558`, `lib/src/features/dashboard/presentation/home_screen.dart:117`, `lib/src/core/router.dart:524`, `lib/src/features/matches/presentation/match_dialog.dart:49`
- **Strategy says:** Premium mutual wave cap is 20/month.
- **Code does:** UI call sites check `hasReachedFreeWaveLimit`, not `hasReachedWaveLimit`, so Premium users never hit the client-side 20/month cap.
- **Recommended direction:** **Fix code.**
- **Why:** This is a UX guard mismatch. Server enforcement still matters, but client behavior should not promise unlimited waves.

### TREM-1 — Send Phone Pulse Intercept UI is not wired

- **Claim ID:** C-TREMBL-03
- **File:line:** `functions/src/modules/matches/intercept.functions.ts:57-59`, no Flutter call site found
- **Strategy says:** Trembling Window includes a Send Phone Pulse Intercept option.
- **Code does:** Cloud Function accepts `type: "phone"`, but Flutter has no `requestPulseIntercept` call and no button in `match_reveal_screen.dart`, `radar_search_overlay.dart`, or `match_dialog.dart`.
- **Recommended direction:** **Fix code.**
- **Why:** Backend exists but the feature is not usable in the app.

### TREM-2 — Send Photo Pulse Intercept UI is not wired

- **Claim ID:** C-TREMBL-04
- **File:line:** `functions/src/modules/matches/intercept.functions.ts:57-59`, `functions/src/modules/matches/intercept.functions.ts:167-169`, no Flutter call site found
- **Strategy says:** Trembling Window includes a view-once Send Photo Pulse Intercept option.
- **Code does:** Cloud Function accepts `type: "photo"` and deletes photo intercept on read, but Flutter has no button/call site.
- **Recommended direction:** **Fix code.**
- **Why:** Strategy-critical interaction is backend-only right now.

### HIST-1 — Near-Miss tab is visible to Free users

- **Claim ID:** C-HISTORY-03
- **File:line:** `lib/src/features/matches/presentation/matches_screen.dart:94-98`, `lib/src/features/matches/presentation/matches_screen.dart:585`, `lib/src/features/matches/presentation/matches_screen.dart:730-731`
- **Strategy says:** Near-Miss History tab is not visible to Free users.
- **Code does:** Activity/Near-Miss tab is always rendered; Free users see locked/blurred cards and a paywall CTA.
- **Recommended direction:** **Founder decision: fix code OR update strategy.**
- **Why:** No PII leak was found, and current implementation is a valid upsell funnel. Literal strategy says hide the tab.

### HIST-2 — "To ni vec nakljucje" second-encounter notification is not implemented

- **Claim ID:** C-HISTORY-06 / C-NOTIFY-02
- **File:line:** `functions/src/modules/proximity/proximity.functions.ts:679-685`, `functions/src/modules/proximity/proximity.functions.ts:714-722`
- **Strategy says:** On the second encounter with the same person after a wave, send the special normal notification.
- **Code does:** Uses only a 30-minute Redis pair cooldown. No encounter counter, no repeat marker, no special payload.
- **Recommended direction:** **Fix code if feature remains in strategy.**
- **Why:** Pure feature gap; no current code path can produce this notification.

### HIST-3 — Free Near-Miss monthly aggregate push is not implemented

- **Claim ID:** C-HISTORY-04 / C-NOTIFY-06
- **File:line:** `functions/src/index.ts:27-87`
- **Strategy says:** Free users receive a monthly aggregate Near-Miss push with count only.
- **Code does:** No scheduled Near-Miss monthly notification function exists.
- **Recommended direction:** **Fix code if feature remains in strategy.**
- **Why:** The count-only privacy behavior cannot exist without the scheduler/payload.

### FILTER-1 — Hard filter gating is not Premium-only

- **Claim ID:** C-FILTER-02
- **File:line:** `lib/src/features/auth/presentation/widgets/registration_steps/nicotine_step.dart:140-160`, `lib/src/features/settings/presentation/settings_screen.dart:1444-1460`, `functions/src/modules/proximity/proximity.functions.ts:283-288`
- **Strategy says:** Hard Filters are Premium-only exclusion rules.
- **Code does:** Nicotine exclusion preference is exposed without a Premium gate and applied regardless of `requesterData.isPremium`.
- **Recommended direction:** **Fix code or update strategy.**
- **Why:** Current behavior makes at least one hard filter available to Free users.

### FILTER-2 — Hard filter logic is symmetric and missing from scheduled proximity events

- **Claim ID:** C-FILTER-02
- **File:line:** `functions/src/modules/proximity/proximity.functions.ts:171-177`, `functions/src/modules/proximity/proximity.functions.ts:342-346`, `functions/src/modules/proximity/proximity.functions.ts:687-722`, `functions/src/modules/proximity/proximity.functions.ts:808-812`
- **Strategy says:** Receiver's exclusion set protects the receiver, directionally, before proximity events.
- **Code does:** `findNearby` helper is bilateral/symmetric. The scheduled `scanProximityPairs` event generator does not apply the hard filter before writing events or sending CROSSING_PATHS notifications.
- **Recommended direction:** **Fix code.**
- **Why:** A user can still receive a proximity event from someone their exclusion rules should block.

### MAP-1 — Free heatmap circles are hidden entirely

- **Claim ID:** C-MAP-01
- **File:line:** `lib/src/features/map/presentation/tremble_map_screen.dart:109-110`
- **Strategy says:** Free users see heatmap circles, but data inside is hidden.
- **Code does:** `_buildProximityCircles` returns `const []` when `effectivePremium` is false.
- **Recommended direction:** **Fix code when Phase 3 heatmap ships.**
- **Why:** Current dev/mock gating hides the entire layer for Free users.

### MAP-2 — Premium heatmap count and type filter are missing

- **Claim ID:** C-MAP-02
- **File:line:** `lib/src/features/map/presentation/tremble_map_screen.dart:109-121`, `lib/src/features/map/presentation/event_pin_sheet.dart:316-357`
- **Strategy says:** Premium users see count inside heatmap circles and a type filter toggle.
- **Code does:** Circles have no count badge and no type filter exists. Event sheet has a generic heatmap-active row, not circle-level count.
- **Recommended direction:** **Fix code when Phase 3 heatmap ships.**
- **Why:** Required Premium heatmap detail UI does not exist.

### NOTIF-1 — Proximity event push is normal, not silent

- **Claim ID:** C-NOTIFY-08
- **File:line:** `functions/src/modules/proximity/proximity.functions.ts:765-798`
- **Strategy says:** New-person proximity event is silent/data-only.
- **Code does:** Sends top-level `notification`, APNs `sound: "default"`, Android high priority notification fields.
- **Recommended direction:** **Fix code.**
- **Why:** Background OS delivery can produce banner/sound, violating the silent interaction model.

### NOTIF-2 — Incoming wave push is normal, not silent

- **Claim ID:** C-NOTIFY-09
- **File:line:** `functions/src/modules/matches/matches.functions.ts:350-379`
- **Strategy says:** Wave received is silent.
- **Code does:** Sends top-level `notification`, image, APNs default sound, Android high priority.
- **Recommended direction:** **Fix code or update strategy.**
- **Why:** This is a direct notification-modality mismatch. If visible incoming waves are now desired, strategy must say so.

### NOTIF-3 — Mutual wave does not deep-link straight to active radar

- **Claim ID:** C-NOTIFY-10
- **File:line:** `functions/src/modules/matches/matches.functions.ts:281-302`, `lib/src/core/router.dart:214-233`
- **Strategy says:** Mutual wave notification is normal and opens active radar.
- **Code does:** Payload includes `path: "/radar"`, but Dart routes `MUTUAL_WAVE` to `match_reveal`.
- **Recommended direction:** **Update strategy or fix routing.**
- **Why:** Match reveal may be the intended premium UX, but it is not the literal "opens active radar" behavior.

### NOTIF-4 — Recap-after-activity push is not implemented

- **Claim ID:** C-NOTIFY-03 / C-NOTIFY-07
- **File:line:** `lib/src/features/dashboard/presentation/home_screen.dart:1602-1666`, `lib/src/core/background_service.dart:256-270`
- **Strategy says:** Recap after activity is a normal push, sent once.
- **Code does:** Run Club shows an in-app bottom sheet after deactivation; the local notification is only "Run Club off", not a recap prompt. No Cloud Function push exists.
- **Recommended direction:** **Fix code if push is still desired.**
- **Why:** Users outside the active app flow will not receive the described recap prompt.

### NOTIF-5 — DND during Run/Gym/Event is not enforced

- **Claim ID:** C-NOTIFY-01
- **File:line:** `functions/src/modules/proximity/proximity.functions.ts:687-712`, `functions/src/modules/proximity/proximity.functions.ts:765-812`, `functions/src/modules/matches/matches.functions.ts:234-248`, `functions/src/modules/matches/matches.functions.ts:350-379`
- **Strategy says:** During Run/Gym/Event, all notifications are silent/suppressed except mutual wave.
- **Code does:** `CROSSING_PATHS` and `INCOMING_WAVE` remain normal. Activity fields are used for match context, not notification suppression.
- **Recommended direction:** **Fix code.**
- **Why:** This breaks the activity-mode DND promise.

### PRIV-1 — Encryption wording requires legal/product decision

- **Claim ID:** C-PRIVACY-07 / C-PRIVACY-09
- **File:line:** `lib/src/features/auth/presentation/widgets/registration_steps/consent_step.dart:174-180`
- **Strategy says:** Sensitive data/email/phone encryption claims are present in privacy strategy.
- **Code does:** UI says "Google Cloud infrastructure-level encryption at rest"; no field-level encryption is implemented.
- **Recommended direction:** **Update strategy/legal copy OR implement field-level encryption.**
- **Why:** The current string is technically scoped to infrastructure encryption, but broader strategy claims can be read as stronger protection.

### PRIV-2 — "Your real location is never stored" is overbroad

- **Claim ID:** C-BRAND-02 / C-PRIVACY-08
- **File:line:** `lib/src/features/safety/presentation/safe_zones_screen.dart:239`
- **Strategy says:** "Your location is never stored. Not policy. Architecture."
- **Code does:** Stores coarse geohash cells; precise GPS coordinates are not stored.
- **Recommended direction:** **Update copy/strategy.**
- **Why:** "Real location" or "location is never stored" can overclaim. The defensible claim is "precise/exact coordinates are never stored; coarse geohash is stored."

### PRICE-1 — Paid tier cards advertise different features

- **Claim ID:** C-PRICING-06
- **File:line:** `lib/src/features/settings/presentation/premium_screen.dart:59-64`, `:79-85`, `:103-107`, `:122-126`
- **Strategy says:** All paid tiers grant identical Premium features; duration is the only difference.
- **Code does:** Runtime entitlement is one `premium`, but cards list tier-specific features such as Weekend window, yearly access, lifetime upgrades, priority support.
- **Recommended direction:** **Fix paywall copy/card model OR update strategy.**
- **Why:** Actual entitlement mapping is single, but product presentation contradicts "identical features."

### PRICE-2 — Premium gates bypass `effectiveIsPremiumProvider`

- **Claim ID:** C-PRICING-06 / premium resolution requirement
- **File:line:** `lib/src/features/dashboard/presentation/home_screen.dart:452`, `:859`; `lib/src/features/matches/presentation/matches_screen.dart:399`, `:671`, `:687-690`, `:730-731`; `lib/src/features/map/presentation/tremble_map_screen.dart:86`, `:170-172`; `lib/src/features/settings/presentation/settings_screen.dart:757`, `:1077`, `:1089`, `:1194`, `:1243`, `:1260`; `lib/src/features/settings/presentation/settings_controller.dart:98`, `:185`, `:227`
- **Strategy says:** Premium status should resolve through the effective premium provider.
- **Code does:** Multiple client gates read raw Firestore-backed `user.isPremium`. Server gates also read Firestore `isPremium`, and no RevenueCat-to-Firestore sync path was found.
- **Recommended direction:** **Fix code.**
- **Why:** RevenueCat-entitled users can be Premium in provider-compliant UI while still Free in raw gates/server decisions.

### PRICE-3 — Weekend Getaway time window is copy-only

- **Claim ID:** C-PRICING-02
- **File:line:** `lib/src/features/settings/presentation/premium_screen.dart:78`, `:84`, `:267`, `:324`
- **Strategy says:** Weekend Getaway is active Friday 19:00 to Sunday 19:00.
- **Code does:** Shows the window in copy only; no enforcement found.
- **Recommended direction:** **Founder decision: fix code OR update strategy.**
- **Why:** If `weekly` is a normal RevenueCat entitlement, strategy/copy should not promise a weekend-only active window.

### BRAND-1 — Brand token colors are hardcoded inline

- **Claim ID:** Visual contract / C-BRAND token audit
- **File:line:** Representative examples: `lib/src/features/settings/presentation/premium_screen.dart:68-69`, `:89-90`, `:149-150`; `lib/src/features/matches/presentation/matches_screen.dart:1264-1320`; `lib/src/features/dashboard/presentation/home_screen.dart:1538-1542`
- **Strategy says:** Use Tremble brand tokens; no inline brand hex drift.
- **Code does:** Repeats brand token hex values (`0xFFF4436C`, `0xFF1A1A18`, `0xFFF5C842`, `0xFF2D9B6F`, `0xFFFAFAF7`) across 20+ files.
- **Recommended direction:** **Fix code mechanically.**
- **Why:** This is maintainability/design-system drift, not behavioral risk.

### BRAND-2 — Direct blur on Near-Miss avatar needs founder judgment

- **Claim ID:** Glassmorphism/content-card audit
- **File:line:** `lib/src/features/matches/presentation/matches_screen.dart:751`
- **Strategy says:** No glassmorphism on dark content cards; `GlassCard.useGlassEffect` should default false.
- **Code does:** `GlassCard` is clean, but a locked Near-Miss avatar is blurred directly with `ImageFilter.blur`.
- **Recommended direction:** **Founder decision.**
- **Why:** This is functional premium masking, not decorative glassmorphism. Strategy should explicitly allow or disallow it.

## 4. Strategy Is Stale Candidates

These are places where the code may be product-correct and the strategy should be updated instead of forcing code to match old wording.

1. **Matches tab limited-card wording**
   - **Strategy section:** History / Recaps, Matches tab claim.
   - **Evidence:** `lib/src/features/matches/presentation/matches_screen.dart:671`.
   - **Why strategy may be stale:** Free users see full cards in some legitimate states; only incoming-wave-not-responded cards are locked. This is more nuanced than "Free limited, Premium full."

2. **Near-Miss Free tab visibility**
   - **Strategy section:** `03 — UX/UI`, C-HISTORY-03.
   - **Evidence:** `lib/src/features/matches/presentation/matches_screen.dart:94-98`, `:730-731`.
   - **Why strategy may be stale:** Current tab-visible/PII-hidden flow is a valid upsell pattern and does not leak names/photos. If founder prefers the funnel, update strategy to "tab visible, content locked."

3. **Mutual wave opens match reveal before radar**
   - **Strategy section:** Notifications / Trembling Window, C-NOTIFY-10 and C-TREMBL-02.
   - **Evidence:** `lib/src/core/router.dart:214-233`.
   - **Why strategy may be stale:** Match reveal animation may be the intended current UX. If so, strategy should say "opens match reveal, then active radar."

4. **Proximity TTL duration inconsistency**
   - **Strategy section:** Privacy / TTL and Proximity / Radar, C-PRIVACY-04 / C-RADAR-11.
   - **Evidence:** `lib/src/core/geo_service.dart:45`, `:182-195`.
   - **Why strategy may be stale:** Audit files note conflicting strategy expectations: 24h vs 30-min TTL. Code implements 30 minutes. Strategy must choose one.

5. **Location marketing copy**
   - **Strategy section:** `04 — Brand Language`, C-BRAND-02.
   - **Evidence:** `lib/src/core/geo_service.dart:155-196`, `functions/src/modules/proximity/proximity.functions.ts:204-220`.
   - **Why strategy may be stale:** Code stores coarse geohash, not raw GPS. Strategy should not say "location is never stored"; it should say precise coordinates are never stored and coarse geohash cells expire.

6. **Infrastructure encryption vs field-level encryption**
   - **Strategy section:** `010 — Pravni vidik`, C-PRIVACY-07 / C-PRIVACY-09.
   - **Evidence:** `lib/src/features/auth/presentation/widgets/registration_steps/consent_step.dart:174-180`.
   - **Why strategy may be stale:** Code and UI currently claim infrastructure-level encryption at rest. If that is the intended legal posture, strategy should not imply field-level encryption.

7. **Weekend Getaway**
   - **Strategy section:** `011 — Monetizacijski Model`, C-PRICING-02.
   - **Evidence:** `lib/src/features/settings/presentation/premium_screen.dart:267`, `:324`.
   - **Why strategy may be stale:** RevenueCat `weekly` may practically be a weekly entitlement, not an enforced weekend-only entitlement. Decide before implementing complex time gating.

8. **Near-Miss avatar blur gate**
   - **Strategy section:** Visual Contract / Glassmorphism.
   - **Evidence:** `lib/src/features/matches/presentation/matches_screen.dart:751`.
   - **Why strategy may be stale:** Blurring as privacy/premium masking is different from decorative glassmorphism. Strategy should explicitly classify it.

## 5. CANNOT VERIFY List

### CV-1 — RevenueCat offering contents

- **Domain:** Pricing / Premium-gating
- **Blocked verification:** Local code defines exactly four product identifiers, but the actual RevenueCat dashboard/default offering contents are external.
- **Needed to resolve:** Inspect RevenueCat default offering and product mapping for `monthly`, `weekly`, `yearly`, `lifetime`, and confirm all attach to `premium`.

### CV-2 — Event participant count is total active count, not match count

- **Domain:** Heatmap / Map Events
- **Blocked verification:** `TrembleEventData.peopleCount` is neutral and `_events` is empty; Cloud Function does not return active event counts.
- **Needed to resolve:** Implement or inspect backend event-count source and verify it counts total active users, not matches/compatible users.

### CV-3 — Heatmap live behavior

- **Domain:** Heatmap / Map Events
- **Blocked verification:** Current heatmap is a dev-only mock (`_proximityPoints` generated locally) and disabled in prod.
- **Needed to resolve:** Build or inspect live Firestore/Cloud Function heatmap feed, then verify Free/Premium behavior against strategy.

### CV-4 — `active_run_crosses` TTL creation path

- **Domain:** Privacy / TTL
- **Blocked verification:** Client reads expect `expiresAt`, but no audited Cloud Function creation path was found.
- **Needed to resolve:** Locate the writer for `active_run_crosses` or verify the collection is deprecated/unused; confirm TTL field and deployed Firestore TTL policy.

### CV-5 — `run_encounters` TTL

- **Domain:** Privacy / TTL
- **Blocked verification:** Audit found `run_encounters` trigger is deprecated/no-op and current flow uses `proximity_events`.
- **Needed to resolve:** Confirm `run_encounters` is no longer written anywhere, then remove/update the strategy claim or archive the collection.

### CV-6 — Direct blur on Near-Miss avatar

- **Domain:** Brand / Copy
- **Blocked verification:** This is a product/design judgment, not a code fact.
- **Needed to resolve:** Founder decides whether avatar blur as premium masking is allowed under the no-glassmorphism/content-card rule.

### CV-7 — Deployed Firestore TTL policies

- **Domain:** Privacy / TTL
- **Blocked verification:** Audit read code only; deployed TTL policy target fields were not verified.
- **Needed to resolve:** Query Firestore TTL policies for `gdprRequests`, `proximity`, `proximity_events`, `matches`, `waves`, and `rateLimits` and compare target fields to code writes.

## Decision Priorities

1. Resolve CRIT-1 and CRIT-2 first by verifying deployed TTL policies or approving code changes.
2. Decide whether RevenueCat entitlement should sync to Firestore/server before fixing all premium-gating bypasses.
3. Decide which strategy-stale candidates should be updated before engineering work starts.
4. Batch low-risk UI/code-copy fixes separately from backend notification/filter/TTL changes.
