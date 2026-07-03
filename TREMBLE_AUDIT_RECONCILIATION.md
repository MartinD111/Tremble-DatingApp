# Tremble Audit Reconciliation Report

Based on the audit reports in `tasks.zip` and the current state of the codebase, here is the reconciliation of all findings.

## 1. CONFIRMED DONE
These findings were flagged in the audit, but the current codebase shows they have been fixed.

*   **WAV-2 (Client wave limit reads the wrong counter source):** Fixed. `auth_repository.dart` now reads `mutualWaves_YYYY_MM` to match the backend.
*   **WAV-3 (Premium users are not client-capped at 20/month):** Fixed. UI call sites in router, profile, matches, and dashboard now check `hasReachedWaveLimit` instead of the free-only limit.
*   **TREM-1 (Send Phone Pulse Intercept UI is not wired):** Fixed. Flutter code now calls `_sendPulseIntercept(type: 'phone')` in `match_reveal_screen.dart` via the repository `requestPulseIntercept`.
*   **TREM-2 (Send Photo Pulse Intercept UI is not wired):** Fixed. Flutter code now calls `_sendPulseIntercept(type: 'photo')` in `match_reveal_screen.dart`.
*   **HIST-3 (Free Near-Miss monthly aggregate push is not implemented):** Fixed. `monthlyNearMissRecap` scheduled function exists in `notifications.functions.ts`.
*   **FILTER-1 (Hard filter gating is not Premium-only):** Fixed. `nicotine_step.dart` and `settings_screen.dart` correctly apply a paywall/gate via `isPremium` checks for nicotine preferences.
*   **FILTER-2 (Hard filter logic is symmetric and missing from scheduled proximity events):** Fixed. `scanProximityPairs` in `proximity.functions.ts` now calls `nicotineCompatible` before creating crosses.
*   **MAP-1 (Free heatmap circles are hidden entirely):** Fixed. `_buildProximityCircles` in `tremble_map_screen.dart` no longer requires `effectivePremium` to render the heatmap shapes.
*   **NOTIF-4 (Recap-after-activity push is not implemented):** Fixed. `EVENT_SESSION_RECAP`, `GYM_SESSION_RECAP`, and `RUN_SESSION_RECAP` pushes are implemented in `events.functions.ts` and `gym.functions.ts`.
*   **NOTIF-5 (DND during Run/Gym/Event is not enforced):** Fixed. `CROSSING_PATHS` and `INCOMING_WAVE` pushes now calculate `isSilent` based on active gym/event/run modes and send data-only silent pushes appropriately.
*   **PRIV-2 ("Your real location is never stored" is overbroad):** Fixed. UI text in `safe_zones_screen.dart` was updated to accurately state "precise GPS coordinates are never stored" and only "coarse geohash cells" are used.
*   **PRICE-2 (Premium gates bypass `effectiveIsPremiumProvider`):** Fixed. Known resolved on 2026-06-06 via `purchases_flutter` v10.2.0 integration.

*(Note: Other known fixed items from the context: `allowBackgroundLocationUpdates` in `geo_service.dart`, Redis env vars, `home_screen.dart` background crash, Sentry async handlers, BleService Android guard)*

## 2. STILL OPEN
These findings still exist in the current codebase and need addressing or a formal strategy update.

*   **CRIT-1 (GDPR request TTL field may not expire):** `functions/src/modules/gdpr/gdpr.functions.ts:153` writes `ttl: twoYearsFromNow()` rather than an `expiresAt` field.
*   **CRIT-2 (Proximity geohash TTL field may not expire):** `lib/src/core/geo_service.dart:244` writes `geoHashExpiresAt` while the strategy specifies 24h vs 30m TTL discrepancy and missing function TTL writes.
*   **WAV-1 (Wave limit enforcement returns success before authoritative limit check):** `functions/src/modules/matches/matches.functions.ts:115` writes the wave doc and returns success immediately, relying on the background trigger for limits.
*   **HIST-1 (Near-Miss tab is visible to Free users):** `lib/src/features/matches/presentation/matches_screen.dart:97` unconditionally includes the `match_tab_activity` tab.
*   **HIST-2 ("To ni vec nakljucje" second-encounter notification is not implemented):** No implementation found in `functions/src/modules/proximity/proximity.functions.ts`.
*   **MAP-2 (Premium heatmap count and type filter are missing):** `lib/src/features/map/presentation/event_pin_sheet.dart` and `tremble_map_screen.dart` still mock the heatmap UI without count or type filter toggles.
*   **NOTIF-1 (Proximity event push is normal, not silent):** `functions/src/modules/proximity/proximity.functions.ts:792` still sends a high-priority push with sound for users who are not in DND/Run/Gym mode.
*   **NOTIF-2 (Incoming wave push is normal, not silent):** `functions/src/modules/matches/matches.functions.ts:406` sends a normal high-priority notification to users not in DND mode.
*   **NOTIF-3 (Mutual wave does not deep-link straight to active radar):** `lib/src/core/router.dart:217` explicitly routes `MUTUAL_WAVE` to the `MatchRevealScreen` instead of radar.
*   **PRIV-1 (Encryption wording requires legal/product decision):** `lib/src/features/auth/presentation/widgets/registration_steps/consent_step.dart:179` claims "infrastructure-level encryption at rest".
*   **PRICE-1 (Paid tier cards advertise different features):** `lib/src/features/settings/presentation/premium_screen.dart:124` lists unique copy like "priority support" for lifetime upgrades despite identical technical entitlements.
*   **PRICE-3 (Weekend Getaway time window is copy-only):** `lib/src/features/settings/presentation/premium_screen.dart` advertises a weekend window for the weekly sub without corresponding backend enforcement.
*   **BRAND-1 (Brand token colors are hardcoded inline):** Hardcoded hex `0xFFF4436C` is present across multiple files, e.g., `lib/src/features/dashboard/presentation/home_screen.dart:2842`.
*   **BRAND-2 (Direct blur on Near-Miss avatar needs founder judgment):** `lib/src/features/matches/presentation/matches_screen.dart:751` uses `ImageFilter.blur` which may violate the glassmorphism/content-card design rule.

## 3. STALE / NOT APPLICABLE
*None.* (All listed findings from the audit directly correspond to code structures that currently exist in the repository; they are either fixed or still open as listed above.)
