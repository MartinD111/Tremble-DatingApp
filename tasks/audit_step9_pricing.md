# Strategy Compliance Audit — Step 9: Pricing / Premium-gating

**Date:** 2026-06-06  
**Domain:** Pricing / Premium-gating  
**Source Claims:** `STRATEGY_CLAIMS.md` section 9 (`C-PRICING-01` through `C-PRICING-08`)  
**Scope:** Flutter app + Cloud Functions source. Read-only audit; no code edits.

## Summary

| Item | Status | Finding |
|---|---|---|
| 1. Product identifiers | MATCH | Flutter code defines and purchases exactly `monthly`, `weekly`, `yearly`, `lifetime`. Store-side RevenueCat offering contents cannot be verified locally. |
| 2. Single entitlement / identical features | MISMATCH | Runtime RevenueCat resolution uses one `premium` entitlement, but the paywall plan cards present tier-specific feature lists, including Weekend-only window and Lifetime priority support. |
| 3. Premium resolution | MISMATCH | Several client gates read raw `user.isPremium` / `user?.isPremium` instead of `effectiveIsPremiumProvider`; server gates read Firestore `isPremium` directly. |
| 4. New users default false | MATCH | `AuthUser` constructor, initial client doc write, and `onUserDocCreated` all default `isPremium` to `false`. |
| 5. Weekend Getaway Fri 19:00-Sun 19:00 | MISMATCH | The window is copy-only in `premium_screen.dart`; no active time-window enforcement was found. Founder decision needed. |
| 6. Premium status hidden from others | MATCH | Public/match profile DTOs do not expose another user's premium status, and visible profile badges are not premium-status badges. |

## 1. Product Identifiers

**Status: MATCH**

Code defines the RevenueCat product IDs as exactly the four strategy identifiers:

- `lib/src/features/subscriptions/application/revenuecat_subscription.dart:11` — `const revenueCatMonthlyProduct = 'monthly';`
- `lib/src/features/subscriptions/application/revenuecat_subscription.dart:12` — `const revenueCatYearlyProduct = 'yearly';`
- `lib/src/features/subscriptions/application/revenuecat_subscription.dart:13` — `const revenueCatLifetimeProduct = 'lifetime';`
- `lib/src/features/subscriptions/application/revenuecat_subscription.dart:14` — `const revenueCatWeeklyProduct = 'weekly';`
- `lib/src/features/subscriptions/application/revenuecat_subscription.dart:16` — `revenueCatProductIdentifiers` contains only those constants.

The paywall cards reference only those constants:

- `lib/src/features/settings/presentation/premium_screen.dart:72` — monthly card uses `revenueCatMonthlyProduct`.
- `lib/src/features/settings/presentation/premium_screen.dart:93` — Weekend card uses `revenueCatWeeklyProduct`.
- `lib/src/features/settings/presentation/premium_screen.dart:115` — Yearly card uses `revenueCatYearlyProduct`.
- `lib/src/features/settings/presentation/premium_screen.dart:134` — Lifetime card uses `revenueCatLifetimeProduct`.

Purchase flow passes only the selected card's `productIdentifier`:

- `lib/src/features/settings/presentation/premium_screen.dart:380` — `_purchasePlan(AuthUser user, PremiumPlanCard plan)`.
- `lib/src/features/settings/presentation/premium_screen.dart:381` — reads `plan.productIdentifier`.
- `lib/src/features/settings/presentation/premium_screen.dart:388` — calls `.purchaseProduct(productIdentifier)`.

No other hardcoded paid product identifier was found in app source. The free card intentionally has no product identifier:

- `test/features/settings/premium_screen_test.dart:31` — asserts `premiumPlanCards[4].productIdentifier` is null.

**Caveat:** RevenueCat dashboard/default offering contents are external and were not verified from local code.

## 2. Single Entitlement / Identical Features

**Status: MISMATCH**

Runtime entitlement resolution is single-entitlement:

- `lib/src/features/subscriptions/application/revenuecat_subscription.dart:9` — `const revenueCatEntitlementPremium = 'premium';`
- `lib/src/features/subscriptions/application/revenuecat_subscription.dart:67` — `isPremium` is derived from `activeEntitlements.contains(revenueCatEntitlementPremium)`.
- `lib/src/features/subscriptions/application/revenuecat_subscription.dart:271` — RevenueCat UI is presented for `revenueCatEntitlementPremium`.
- `lib/src/features/subscriptions/application/revenuecat_subscription.dart:402` — purchase result is checked through returned customer info.
- `lib/src/features/subscriptions/application/revenuecat_subscription.dart:404` — purchase succeeds only if `customerInfo.isPremium`.
- `lib/src/features/subscriptions/application/revenuecat_subscription.dart:424` — restore result is checked through returned customer info.
- `lib/src/features/subscriptions/application/revenuecat_subscription.dart:426` — restore succeeds only if `customerInfo.isPremium`.

However, paid plan cards do **not** present identical features:

- `lib/src/features/settings/presentation/premium_screen.dart:59` to `64` — Monthly lists wider radar, unlimited geofence, custom themes, advanced filters.
- `lib/src/features/settings/presentation/premium_screen.dart:79` to `85` — Weekend lists the Monthly features plus `premium_feature_weekend_window`.
- `lib/src/features/settings/presentation/premium_screen.dart:103` to `107` — Yearly lists all premium, yearly access, cancel anytime.
- `lib/src/features/settings/presentation/premium_screen.dart:122` to `126` — Lifetime lists all premium, lifetime upgrades, priority support.

This violates the literal requirement that all paid tiers grant identical features and duration is the only difference. The entitlement mechanics mostly match, but the visible product definition does not.

## 3. Premium Resolution / Provider Bypasses

**Status: MISMATCH**

Central provider exists and correctly combines RevenueCat, Firestore user state, and event "Taste of Premium":

- `lib/src/features/auth/data/auth_repository.dart:1082` — defines `effectiveIsPremiumProvider`.
- `lib/src/features/auth/data/auth_repository.dart:1083` — watches `authStateProvider`.
- `lib/src/features/auth/data/auth_repository.dart:1084` — watches `eventGeofenceServiceProvider`.
- `lib/src/features/auth/data/auth_repository.dart:1085` — watches `revenueCatIsPremiumProvider`.
- `lib/src/features/auth/data/auth_repository.dart:1086` to `1088` — returns RevenueCat premium OR user effective premium OR false.

Provider-compliant premium checks found:

- `lib/src/features/dashboard/presentation/home_screen.dart:507` — main HomeScreen premium state uses `ref.watch(effectiveIsPremiumProvider)`.
- `lib/src/features/dashboard/application/proximity_ping_controller.dart:21` — high-frequency proximity mode uses `ref.watch(effectiveIsPremiumProvider)`.
- `lib/src/features/dashboard/presentation/run_recap_screen.dart:102` — free viewed-recap close handling uses `ref.read(effectiveIsPremiumProvider)`.
- `lib/src/features/dashboard/presentation/run_recap_screen.dart:130` — recap UI uses `ref.watch(effectiveIsPremiumProvider)`.
- `lib/src/features/map/presentation/event_recap_screen.dart:79` — free viewed-event close handling uses `ref.read(effectiveIsPremiumProvider)`.
- `lib/src/features/map/presentation/event_recap_screen.dart:103` — event recap UI uses `ref.watch(effectiveIsPremiumProvider)`.

Direct client reads that bypass the provider:

- `lib/src/features/dashboard/presentation/home_screen.dart:452` — listens to `authStateProvider.select((user) => user?.isPremium == true)` for nav remapping.
- `lib/src/features/dashboard/presentation/home_screen.dart:859` — dev-sim profile gate reads `tapUser?.isPremium == true`; RevenueCat-only premium users would hit the paywall.
- `lib/src/features/matches/presentation/matches_screen.dart:399` — history/recap/near-miss gating derives `isPremium` from `user?.isPremium == true`.
- `lib/src/features/matches/presentation/matches_screen.dart:671` — recap lock uses that raw-derived `isPremium`.
- `lib/src/features/matches/presentation/matches_screen.dart:687` to `690` — Near-Miss upsell uses that raw-derived `isPremium`.
- `lib/src/features/matches/presentation/matches_screen.dart:730` to `731` — Near-Miss locked/read-only state uses that raw-derived `isPremium`.
- `lib/src/features/map/presentation/tremble_map_screen.dart:86` — "Taste of Premium" sheet check reads `!ref.read(authStateProvider)!.isPremium`.
- `lib/src/features/map/presentation/tremble_map_screen.dart:170` to `172` — map premium state calls `user?.effectiveIsPremium(...)` directly, bypassing the provider and therefore RevenueCat.
- `lib/src/features/profile/presentation/edit_profile_screen.dart:207` — caches `_isPremium = user.isPremium`.
- `lib/src/features/profile/presentation/edit_profile_screen.dart:2158` — distance slider max uses cached `_isPremium`.
- `lib/src/features/profile/presentation/profile_card_preview.dart:295` — self profile preview filters visible "looking for" values by `user.isPremium`.
- `lib/src/features/settings/presentation/settings_screen.dart:757` — Premium profile action checks `!user.isPremium`.
- `lib/src/features/settings/presentation/settings_screen.dart:1077` and `1089` — height filter UI/modal lock uses `!user.isPremium`.
- `lib/src/features/settings/presentation/settings_screen.dart:1194`, `1243`, `1260` — premium preference rows use `!user.isPremium`.
- `lib/src/features/settings/presentation/settings_screen.dart:1555` — self status switch displays `user.isPremium`.
- `lib/src/features/settings/presentation/settings_controller.dart:98` — height update guard checks `!user.isPremium`.
- `lib/src/features/settings/presentation/settings_controller.dart:185` — pill modal guard checks `!user.isPremium`.
- `lib/src/features/settings/presentation/settings_controller.dart:227` — slider modal guard checks `!user.isPremium`.
- `lib/src/features/settings/presentation/premium_screen.dart:938` — upgrade CTA state reads `user.isPremium`.

Other raw premium reads:

- `lib/src/core/geo_service.dart:64` — fetches Firestore `isPremium` into `_isPremium`.
- `lib/src/core/geo_service.dart:178` — writes `radiusTier` from cached `_isPremium`.
- `functions/src/modules/matches/matches.functions.ts:56` — server mutual-wave limit reads `userData?.isPremium === true`.
- `functions/src/modules/proximity/proximity.functions.ts:287` — server nearby radius reads `requesterData.isPremium === true`.
- `functions/src/modules/proximity/proximity.functions.ts:500` — server candidate radius reads `requesterData.isPremium === true`.

Server-side provider use is not possible directly, but this still matters: local search found no RevenueCat webhook or Firestore sync path that writes RevenueCat entitlement changes back to `users/{uid}.isPremium`. Evidence:

- `lib/src/app.dart:47` to `56` — RevenueCat listener only syncs app user ID.
- Search for RevenueCat/entitlement update paths found no Cloud Function or app write setting `isPremium: true`.

Risk: a user with an active RevenueCat `premium` entitlement can be treated as premium by provider-compliant client UI, while raw Firestore/server gates may still treat the same user as Free.

## 4. New Users Default

**Status: MATCH**

Client model default:

- `lib/src/features/auth/data/auth_repository.dart:194` — `this.isPremium = false` in `AuthUser` constructor.

Client initial user doc write:

- `lib/src/features/auth/data/auth_repository.dart:904` to `912` — initial `/users/{uid}` set includes `isPremium: false`.

Cloud Function default:

- `functions/src/modules/auth/auth.functions.ts:48` to `57` — `onUserDocCreated` merges `isPremium: false`.

Firestore read fallback also defaults missing field to false:

- `lib/src/features/auth/data/auth_repository.dart:387` — `isPremium: data['isPremium'] as bool? ?? false`.

## 5. Weekend Getaway Fri 19:00-Sun 19:00 Window

**Status: MISMATCH**

The window exists as visible copy only:

- `lib/src/features/settings/presentation/premium_screen.dart:78` — Weekend card has `windowKey: 'premium_card_weekend_window'`.
- `lib/src/features/settings/presentation/premium_screen.dart:84` — Weekend card includes `premium_feature_weekend_window`.
- `lib/src/features/settings/presentation/premium_screen.dart:267` — English copy says `Friday 7:00 PM to Sunday 7:00 PM`.
- `lib/src/features/settings/presentation/premium_screen.dart:324` — Slovenian copy says `Petek 19:00 do nedelja 19:00`.

No code path enforcing Fri 19:00-Sun 19:00 was found. Searches for `Weekend`, `weekend`, `Friday`, `Fri`, `Sunday`, `Sun`, `19:00`, `Getaway`, and `getaway` found only premium screen copy/tests and unrelated weekly radar schedule UI.

Founder decision needed: either implement time-window enforcement for the `weekly` product, or redefine Weekend Getaway as a normal weekly RevenueCat entitlement and change the strategy/copy.

## 6. Premium Status Hidden From Other Users

**Status: MATCH**

Public and match profile models do not expose another user's premium status:

- `lib/src/features/matches/data/match_repository.dart:36` to `79` — `MatchProfile` fields include profile/match context data, not `isPremium`.
- `lib/src/features/matches/data/match_repository.dart:120` to `150` — `MatchProfile.fromApi` does not parse `isPremium`.
- `lib/src/features/profile/domain/public_profile.dart:4` to `12` — `PublicProfile` fields do not include premium status.
- `lib/src/features/profile/domain/public_profile.dart:23` to `33` — `PublicProfile.fromFirestore` does not parse `isPremium`.

Visible other-user badge area shows profile facts, not premium status:

- `lib/src/features/profile/presentation/profile_detail_screen.dart:423` to `426` — renders `_buildInfoBadges`.
- `lib/src/features/profile/presentation/profile_detail_screen.dart:623` to `674` — badges are school, university, job-seeking, hair color, ethnicity.

Search findings:

- `lib/src/features/profile/presentation/profile_card_preview.dart:295` reads `user.isPremium`, but this is self preview (`AuthUser`), not another user's profile card.
- `lib/src/features/settings/presentation/settings_screen.dart:725` to `745` shows premium status text in the current user's own settings area.
- `lib/src/features/map/presentation/event_pin_sheet.dart` uses a premium-style icon for event/Taste of Premium UI, not another user's premium badge.

No UI evidence was found of a premium badge/indicator on profile cards visible to others.

## Audit Decision Log

Open decisions for founder:

1. Whether the paywall plan-card copy must be changed so all paid tiers list identical Premium features and differ only by duration/price.
2. Whether all client gates should be migrated to `effectiveIsPremiumProvider`, including settings/profile/history/map.
3. Whether RevenueCat entitlement state must be synced server-side to Firestore or verified server-side before Cloud Functions apply premium radius and wave limits.
4. Whether Weekend Getaway should be an enforced Fri 19:00-Sun 19:00 access window or a normal weekly paid entitlement.
