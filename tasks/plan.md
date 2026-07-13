# Active Implementation Plan
Plan ID: 20260713-paywall-copy-rewrite
Risk Level: LOW
Founder Approval Required: NO
Branch: feat/paywall-copy-rewrite

1. OBJECTIVE — Rewrite `premium_screen.dart` paywall bullet copy so it
   matches ADR-007's Free/Premium tier matrix exactly. The paywall
   previously advertised features that were never gated in code
   (`unlimited geofence pings`, `advanced filtering matrix`, `custom
   themes`, `50% wider radar scan`) and omitted features that are
   actually gated (mutual-wave cap, near-miss history, recap TTL,
   distance slider bounds, etc.). Copy-only change — no gate logic
   touched.

2. SCOPE —
   - **Modified:**
     - `lib/src/features/settings/presentation/premium_screen.dart`
       — introduced two top-level const lists
       (`premiumOnlyFeatureBullets`, `freeTierFeatureBullets`) sourced
       from ADR-007. Premium (monthly) and Free cards reference them
       directly; Weekend card composes `[...premiumOnlyFeatureBullets,
       weekend_window]`. EN + SL translation blocks fully rewritten
       for the 8 Premium + 7 Free new keys. Retired 7 old keys
       (`premium_feature_wider_radar/unlimited_geofence/custom_themes/
       advanced_filters`, `premium_free_gym_mode/local_radar/wave_limit`).
     - `test/features/settings/premium_screen_test.dart` — added
       `paywall copy matches ADR-007 tier matrix` group with four
       assertions: (a) Premium card = exact ordered set from ADR-007;
       (b) Weekend card = Premium + weekend suffix; (c) Free card =
       exact ordered set from ADR-007; (d) retired keys physically
       absent from the file; (e) no ADR-007 §3 forbidden phrases in
       user-facing translation strings.
   - **Untouched:** any gate logic, `revenuecat_subscription.dart`,
     Cloud Functions, other locale blocks (de/hr/it/es/fr/pt fall
     back to EN for feature bullets, as they already did).

3. STEPS —
   1. Extract the ADR-007 Premium-only + Free-tier bullet lists into
      two top-level `const` arrays with a comment linking back to the
      ADR and the test that guards them.
   2. Point each card's `features` list at the appropriate array
      (Weekend spreads Premium + adds the weekend-window key).
   3. Rewrite the EN + SL translation entries for the new keys.
      Remove the 7 retired entries wholesale.
   4. Add the ADR-007 contract test group. Include a copy-rules
      assertion scoped to translation values (regex over
      `'key': 'value',` lines) — full-file scan would fail on
      internal comments (`// left swipe pulls the previous card...`).
   5. Verify: `flutter analyze` clean, `flutter test` green.

4. RISKS & TRADEOFFS —
   - **Legacy translation keys (LOW):** the 7 retired keys are no
     longer referenced. Removed from the EN + SL maps in the same
     commit so they cannot be resurrected accidentally. Fallback
     locales that used to hit the retired keys will now hit the new
     ones via the EN fallback chain (`_t()` already handles unknown
     keys by falling through EN).
   - **Missing localizations (LOW):** only EN + SL have the new
     bullets. Other locales (de/hr/it/es/fr/pt) already only
     translated `weekend_window` and CTA strings and let feature
     bullets fall through to EN — same behaviour as before. Adding
     full localization for the remaining 6 locales is out of scope
     for 3.7a; that is a separate translation task.
   - **Copy accuracy (assumption):** the new EN + SL bullets restate
     the mechanics from ADR-007 (250 m, −85 dBm, 20/mo, 100 km, etc.).
     If ADR-007 shifts, this copy AND the ADR-007 contract test must
     shift together — the test failure will point to the mismatch.
   - **No gate changes:** feature-parity work (3.7b onward) will
     verify that these advertised features actually exist as gates.
     Until then the paywall is honest about what is CLAIMED to exist
     per ADR-007, but not yet a proof of implementation. That is
     explicitly deferred to KORAK 3.7b.

5. VERIFICATION —
   - `flutter analyze` — 0 issues.
   - `flutter test` — 247 tests green (was 242, +5 new tests in
     `premium_screen_test.dart`).
   - `flutter test test/features/settings/premium_screen_test.dart`
     — 6/6 green.
   - Grep evidence:
     - `grep -n "premium_feature_wider_radar\|premium_feature_
       unlimited_geofence\|premium_feature_custom_themes\|premium_
       feature_advanced_filters\|premium_free_gym_mode\|premium_
       free_local_radar\|premium_free_wave_limit" lib/` → 0 hits
       (retired keys gone).
     - `grep -n "premium_feature_radar_extended\|premium_feature_
       mutual_waves_20\|premium_feature_open_profile_cards\|premium_
       feature_recap_full\|premium_feature_near_miss_history\|
       premium_feature_hard_filters\|premium_feature_event_insights\|
       premium_feature_distance_100" lib/` → 8 hits (1 per new key,
       all inside `premium_screen.dart`).
   - Device test not applicable — pure Flutter copy change; smoke
     verification deferred to the next TestFlight build.
