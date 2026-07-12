# Active Implementation Plan
Plan ID: 20260712-fix-crossing-paths-visibility
Risk Level: HIGH
Founder Approval Required: YES (already granted — path (a) chosen)
Branch: feat/crossing-paths-visible-notification

1. OBJECTIVE — Make CROSSING_PATHS notifications actually visible to backgrounded users on both Android and iOS by moving to a full FCM `notification` payload with title/body localized server-side from the recipient's `appLanguage` field (fallback `en`), while preserving the existing `data` fields so the foreground in-app pill path continues to work end-to-end.

2. SCOPE —
   - **Modified:**
     - `functions/src/modules/proximity/proximity.functions.ts` — `sendCrossingPaths` (both silent/non-silent branches) and the `SECOND_ENCOUNTER` FCM path in `scanProximityPairs`.
     - `functions/src/__tests__/proximity_crossing_paths.test.ts` — **new** Jest suite covering title/body localization (en + sl) and `pairsNotified` counting.
     - `lib/src/core/notification_service.dart` — early-return after in-app pill so the OS banner is not double-shown in foreground now that a `notification` block is present.
     - `tasks/plan.md` (this file).
   - **Does NOT change:**
     - `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml` (native manifests untouched).
     - `pubspec.yaml`, Cloud Functions dependency list.
     - Firestore Rules, `.github/workflows/`, secrets, App Check config.
     - `lib/src/core/translations.dart` (Flutter loc strings; APNs no longer relies on them).

3. STEPS —
   (a) **Server-side i18n table.** Add a small in-file map `CROSSING_PATHS_STRINGS: Record<lang, {title, body(name, age)}>` covering `en` + `sl` (fallback `en`). Same map is exported via a helper so tests can assert exact strings.
   (b) **Rewrite `sendCrossingPaths`.** Build recipient language from `recipientData.appLanguage` (fallback `language`, else `en`). Always send a full `notification: { title, body }`; keep the existing `data` block so foreground pill still receives `senderId/senderName/senderAge/senderPhotoUrl/type`. Preserve the silent-mode branch (Run Mode / Gym / Event) — silent still uses `content_available` only, no user-visible notification. Drop `alert-body-loc-key` / `alert-body-loc-args` / `notify_nearby_body_rich`. Set `apns.payload.aps.sound: "default"` and iOS category `NEARBY_CATEGORY` only for the non-silent branch. Preserve throttle + PII truncation.
   (c) **Fix `pairsNotified`.** Remove the pre-send optimistic increment. Await `Promise.allSettled([send1, send2])` and increment `pairsNotified` by the count of fulfilled promises whose handler returned `{sent: true}` (silent-mode returns `{sent: false, skipped: "silent"}`, throttled/token-missing returns `{sent: false, skipped: "throttled" | "no_token"}`).
   (d) **SECOND_ENCOUNTER localization.** Same treatment: full `notification.title/body` per recipient `appLanguage`; drop `alert-title-loc-key` / `alert-body-loc-key`.
   (e) **Flutter foreground dedupe.** Confirm existing `return;` in `_onMessageSub` handler after `onForegroundWave(...)` fires — this already suppresses the OS banner when the app is foreground and the pill is shown, so no double-display when the CF now includes a `notification` block. Add a short comment documenting the invariant.
   (f) **Tests.** New Jest suite mocks `firebase-admin/messaging` and `firebase-admin/firestore`, drives `scanProximityPairs` via a captured handler, and asserts:
       - Recipient with `appLanguage: 'en'` receives EN title/body.
       - Recipient with `appLanguage: 'sl'` receives SL title/body.
       - Unknown language falls back to EN.
       - When one recipient lacks `fcmToken`, `pairsNotified` reflects only the successful send.
       - No remaining `alert-body-loc-key` / `notify_nearby_body_rich` in outgoing payloads.

4. RISKS & TRADEOFFS —
   - **Rendering risk:** now that CF sends a full `notification` block, foreground clients see both the pill AND the OS banner if the handler is not short-circuited. Mitigation: `_onMessageSub` already returns after invoking `onForegroundWave`; step (e) documents/asserts that path.
   - **APNs alert vs. data trade-off:** dropping `alert-body-loc-key` means we lose native OS-locale switching; instead we key off `appLanguage`, which lags OS locale if the user picks a language in-app that differs from OS locale — this is the founder's chosen trade-off (path a).
   - **In-file loc strings:** Cloud Function does not import Flutter translations. Deliberately small map, only two strings; future languages added here. Drift risk mitigated by tests that assert the exact strings.
   - **`pairsNotified` semantics change:** callers/dashboards reading this metric will see it drop when tokens are missing — this is the intended correction (metric was previously lying), not a regression.

5. VERIFICATION —
   - **Verification checklist:**
     - [ ] **unit tests** — `cd functions && npm test` passes new proximity_crossing_paths suite (en + sl + fallback + partial success).
     - [ ] **integration tests** — existing `matches.test.ts` and `compatibility_calculator.test.ts` still green; `scanProximityPairs` handler exercised end-to-end with mocked Firestore + Redis + FCM.
     - [ ] **security scan** — no new dependencies; no PII in logs (`substring(0, 8)` truncation preserved); no secrets touched; `npm run lint` clean.
     - [ ] `cd functions && npm run build && npm run lint && npm test` — all green.
     - [ ] `flutter analyze` — 0 issues.
     - [ ] `flutter test` — all green (no new Flutter tests required; existing suite must stay green).
     - [ ] Grep evidence in PR body: `grep -rn "notify_nearby_body_rich\|alert-body-loc-key\|alert-title-loc-key" functions/src` returns zero results.
     - [ ] `risk_level: high` recorded in PR body.
