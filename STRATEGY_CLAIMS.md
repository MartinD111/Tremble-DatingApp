# STRATEGY_CLAIMS.md

> **Source:** Tremble_Master_Strategy_v9.html  
> **Purpose:** Verifiable claims extracted from strategy doc for audit against live codebase.  
> **Status:** PARTIALLY VERIFIED — wave limit claims verified against live codebase on 2026-06-02.  
> **Instructions:** Do NOT edit code based on this file. Verify each claim separately.

---

## How to Read This File

- **Claim ID** — `C-{DOMAIN}-{NN}` format
- **Exact Quote** — verbatim text from the strategy (HTML tags stripped)
- **Section** — strategy section heading
- **Codebase Location** — best guess at file/dir; verify before acting
- **Verification Method** — what to grep or read to confirm

---

## 1. Proximity / Radar

| Claim ID | Exact Quote | Section | Codebase Location | Verification Method |
|---|---|---|---|---|
| C-RADAR-01 | "BLE + GPS geohash, 30s scan / 5min" | 02 — Produktna Strategija | `lib/src/core/ble_service.dart` | Grep `30` + `300` (scan interval in seconds) |
| C-RADAR-02 | "Low power (<20% bat): 30s scan / 15min" | 02 — Produktna Strategija | `lib/src/core/ble_service.dart` | Grep battery threshold `0.20` + scan interval `900` |
| C-RADAR-03 | "Match mode (mutual wave): ~vsako sekundo (RSSI)" | 02 — Produktna Strategija | `lib/src/features/dashboard/` | Grep RSSI rapid-poll interval during active match |
| C-RADAR-04 | "Run Club mode: Agresivni RSSI, 55% threshold" | 02 — Produktna Strategija | `lib/src/core/ble_service.dart` | Grep `0.55` near run-club-specific scan logic |
| C-RADAR-05 | "BLE proximity log: RAM only — izbriše ob koncu seje" | 02 — Produktna Strategija | `lib/src/core/ble_service.dart` | Verify no Firestore/file write of raw proximity events |
| C-RADAR-06 | "Run encounter: Firestore TTL 10 minut" | 02 — Produktna Strategija | `functions/src/modules/proximity/` | Grep `ttl` or `600` in run_encounter documents |
| C-RADAR-07 | "Gym session: Firestore TTL 24 ur" | 02 — Produktna Strategija | `functions/src/modules/proximity/` | Grep `ttl` or `86400` in gym_session documents |
| C-RADAR-08 | "GPS koordinate: Nikoli shranjene na strežniku" | 010 — Pravni vidik | `functions/src/modules/proximity/` | Verify no `lat`/`lng`/`coordinates` written to Firestore |
| C-RADAR-09 | "Radius zaznave Free: 100m" | 011 — Monetizacijski Model | `lib/src/core/ble_service.dart` or `functions/src/modules/proximity/` | Grep `100` as radius constant for free tier |
| C-RADAR-10 | "Radius zaznave Premium: 250m" | 011 — Monetizacijski Model | `lib/src/core/ble_service.dart` or `functions/src/modules/proximity/` | Grep `250` as radius constant for premium tier |
| C-RADAR-11 | "Geohash precision 7, ~76m × 38m, 30-min TTL" | 010 — Pravni vidik | `lib/src/core/ble_service.dart` or `functions/src/modules/proximity/` | Grep `precision` value `7` and geohash TTL `1800` |
| C-RADAR-12 | "Matching prag (Radar default): 0.55" | 03 — UX/UI | `lib/src/core/ble_service.dart` | Grep `0.55` as default match threshold |

---

## 2. Wave / Limits

| Claim ID | Exact Quote | Section | Codebase Location | Verification Method |
|---|---|---|---|---|
| C-WAVE-01 ✅ VERIFIED 2026-06-02 | "Mutual waves / mesec Free: 5 valov" | 011 — Monetizacijski Model | `functions/src/modules/matches/matches.functions.ts` | Implemented as `MUTUAL_WAVE_FREE_LIMIT = 5`; checked in `onWaveCreated` transaction before match creation; counter field `users/{uid}.mutualWaves_YYYY_MM`; deployed to `tremble-dev` 2026-06-02 |
| C-WAVE-02 ✅ VERIFIED 2026-06-02 | "Mutual waves / mesec Premium: 20 valov" | 011 — Monetizacijski Model | `functions/src/modules/matches/matches.functions.ts` | Implemented as `MUTUAL_WAVE_PREMIUM_LIMIT = 20`; checked in `onWaveCreated` transaction before match creation; counter field `users/{uid}.mutualWaves_YYYY_MM`; deployed to `tremble-dev` 2026-06-02 |
| C-WAVE-03 | "Ob proximity eventu user vidi profilno kartico" | 02 — Produktna Strategija | `lib/src/features/dashboard/presentation/home_screen.dart` | Verify proximity event surfaces profile card UI |
| C-WAVE-04 | "Prejeli wave notifikacija: '[ime], [starost] waved at you'" | 02 — Produktna Strategija | `functions/src/modules/waves/` | Grep notification body template for wave received |
| C-WAVE-05 | "Proximity notifikacija: 'Someone nearby — [ime], [starost]'" | 02 — Produktna Strategija | `functions/src/modules/proximity/` | Grep proximity push notification template |

---

## 3. Trembling Window

| Claim ID | Exact Quote | Section | Codebase Location | Verification Method |
|---|---|---|---|---|
| C-TREMBL-01 | "30-minutno okno (Trembling Window) ob mutual wave" | 02 — Produktna Strategija | `lib/src/features/dashboard/` or `functions/src/modules/matches/` | Grep `1800` or `30` minutes as match window duration |
| C-TREMBL-02 | "Mutual wave sproži match in odpre active radar" | 02 — Produktna Strategija | `lib/src/features/dashboard/presentation/home_screen.dart` | Verify mutual wave navigates to active radar view |
| C-TREMBL-03 | "Pulse Intercept med Trembling Window: Send Phone button" | 02 — Produktna Strategija | `lib/src/features/dashboard/` | Grep "Send Phone" button widget in active radar/match screen |
| C-TREMBL-04 | "Pulse Intercept med Trembling Window: Send Photo button" | 02 — Produktna Strategija | `lib/src/features/dashboard/` | Grep "Send Photo" button widget in active radar/match screen |
| C-TREMBL-05 | "Pulse Intercept photo: view-once, 10 min TTL / Snap-style" | 02 — Produktna Strategija | `functions/src/modules/` | Grep `600` or `10 min` TTL on Pulse Intercept media documents |

---

## 4. History / Recaps

| Claim ID | Exact Quote | Section | Codebase Location | Verification Method |
|---|---|---|---|---|
| C-HISTORY-01 | "Recaps tab Free: Foto + ime + starost, sivina, brez akcije" | 03 — UX/UI | `lib/src/features/dashboard/` or `lib/src/features/matches/` | Verify free recap cards use grayscale + no action button |
| C-HISTORY-02 | "Recaps tab Premium: Barvno + 10 min TTL za val" | 011 — Monetizacijski Model | `lib/src/features/matches/` | Verify premium recap shows color + 10-min wave window |
| C-HISTORY-03 | "Near-Miss History Free: Tab ni viden" | 03 — UX/UI | `lib/src/features/matches/` | Verify near-miss tab is conditionally hidden for free users |
| C-HISTORY-04 | "Near-Miss History Free: 1×/mesec agregirano push notifikacijo (samo število)" | 03 — UX/UI | `functions/src/modules/` | Grep monthly aggregate near-miss push, count-only payload |
| C-HISTORY-05 | "Near-Miss History Premium: Odpreš kadarkoli, celoten profil kartica" | 011 — Monetizacijski Model | `lib/src/features/matches/` | Verify full profile card accessible in premium near-miss tab |
| C-HISTORY-06 | "Ob 2. srečanju z isto osebo: forced notif 'To ni več naključje'" | 011 — Monetizacijski Model | `functions/src/modules/proximity/` | Grep second-encounter detection + notification trigger |
| C-HISTORY-07 | "Post-run recap Free: foto + ime + starost, sivina, brez akcije" | 03 — Run Club aktivacijski flow | `lib/src/features/dashboard/presentation/` | Read `RunRecapScreen` — verify grayscale + no wave action for free |
| C-HISTORY-08 | "Post-run recap Premium: barvno, kartica + 10 min TTL" | 03 — Run Club aktivacijski flow | `lib/src/features/dashboard/presentation/` | Verify premium run recap shows color + 10-min wave window |
| C-HISTORY-09 | "Run Club match expiry: 10-min TTL" | 02 — Produktna Strategija | `functions/src/modules/proximity/` | Grep `600` as run encounter TTL in Firestore write |

---

## 5. Filters

| Claim ID | Exact Quote | Section | Codebase Location | Verification Method |
|---|---|---|---|---|
| C-FILTER-01 | "Filtri iskanja Free: Osnovno (spol, starost)" | 011 — Monetizacijski Model | `lib/src/features/profile/` or `lib/src/features/auth/` | Verify gender + age filters are available without premium |
| C-FILTER-02 | "Hard filtri Premium: izključitvena pravila (server-side, pred proximity eventom)" | 011 — Monetizacijski Model | `functions/src/modules/proximity/proximity.functions.ts` | Grep "hard filter" or exclusion logic applied before proximity candidates returned |
| C-FILTER-03 | "flaggedForReview filter v proximity candidates (post-query, oba endpointa)" | v8.1 Changelog | `functions/src/modules/proximity/proximity.functions.ts` | Grep `flaggedForReview` filter in both getNearbyUsers and getRunEncounters (or equivalent) |

---

## 6. Heatmap / Map

| Claim ID | Exact Quote | Section | Codebase Location | Verification Method |
|---|---|---|---|---|
| C-MAP-01 | "Heatmap Free: Krogi vidni na mapi, podatki znotraj kroga skriti" | 011 — Monetizacijski Model | `lib/src/features/map/` | Verify heatmap circles render without count/detail for free tier |
| C-MAP-02 | "Heatmap Premium: Število aktivnih znotraj kroga + filter toggle" | 011 — Monetizacijski Model | `lib/src/features/map/` | Verify premium users see count badge inside heatmap circles |
| C-MAP-03 | "Map Events Free: Vidni na mapi, brez števca udeležencev" | 011 — Monetizacijski Model | `lib/src/features/map/` | Verify event markers appear without attendee count for free users |
| C-MAP-04 | "Map Events Premium: Število aktivnih userjev znotraj eventa" | 011 — Monetizacijski Model | `lib/src/features/map/` | Verify premium users see active user count on event markers |
| C-MAP-05 | "Protomaps — Google Maps zamenjava" | v8.1 Changelog | `pubspec.yaml`, `lib/src/features/map/` | Grep `protomaps` or `flutter_map` in pubspec; verify no google_maps_flutter |
| C-MAP-06 | "Cloudflare R2 tile hosting (~€1.50/mes)" | v8.1 Changelog | `lib/src/features/map/` or Worker config | Grep `maps.trembledating.com` tile URL in map init |

---

## 7. Notifications

| Claim ID | Exact Quote | Section | Codebase Location | Verification Method |
|---|---|---|---|---|
| C-NOTIFY-01 | "Med Run Club / Gym / Event: Silent Mode (DND)" | 03 — Run Club aktivacijski flow | `lib/src/features/dashboard/` or notification service | Grep silent/DND flag set during active activity modes |
| C-NOTIFY-02 | "Izjema Silent Mode: 2. ali večkrat ista osoba blizu (po poslanem valu)" | 03 — Run Club aktivacijski flow | `functions/src/modules/proximity/` | Grep override logic for repeat-encounter notification during DND |
| C-NOTIFY-03 | "Recap push po aktivnosti: normalna notifikacija" | 03 — Run Club aktivacijski flow | `functions/src/modules/` | Verify recap push sent as normal priority (not silent) |
| C-NOTIFY-04 | "Run Club activation: 'Zazdan tek — vklopim Run Club?'" | 03 — Run Club aktivacijski flow | `lib/src/features/dashboard/` or FCM handler | Grep this exact Slovenian copy string |
| C-NOTIFY-05 | "Gym Mode activation: 'Si v [Gym name]. Vklopiš Gym Mode?'" | 03 — Gym Mode aktivacijski flow | `lib/src/features/dashboard/` or FCM handler | Grep this Slovenian copy string with gym name interpolation |
| C-NOTIFY-06 | "Mid-run mutual wave: '[ime] ti pošilja Wave med tekom!'" | 03 — Run Club aktivacijski flow | `functions/src/modules/waves/` | Grep mid-run wave notification template |
| C-NOTIFY-07 | "Post-run recap offer: 'Končal/a s tekom? Poglej kdo je bil tam.'" | 03 — Run Club aktivacijski flow | `functions/src/modules/` | Grep post-run recap offer notification template |
| C-NOTIFY-08 | "Proximity event notification: tiha (silent)" | 03 — UX/UI | `functions/src/modules/proximity/` | Verify data-only / silent push for proximity detection |
| C-NOTIFY-09 | "Wave received notification: tiha (silent)" | 03 — UX/UI | `functions/src/modules/waves/` | Verify wave-received push is silent/data-only |
| C-NOTIFY-10 | "Mutual wave notification: normalna, odpre active radar" | 03 — UX/UI | `functions/src/modules/waves/` | Verify mutual wave push has sound + deeplink to active radar |

---

## 8. Privacy / TTL

| Claim ID | Exact Quote | Section | Codebase Location | Verification Method |
|---|---|---|---|---|
| C-PRIVACY-01 | "Proximity log: RAM only — izbriše ob koncu seje" | 010 — Pravni vidik | `lib/src/core/ble_service.dart` | Verify in-memory only buffer; no Firestore/file write |
| C-PRIVACY-02 | "Run encounter: Firestore TTL 10 minut" | 010 — Pravni vidik | `functions/src/modules/proximity/proximity.functions.ts` | Grep `ttl` field value `600` on run encounter write |
| C-PRIVACY-03 | "Gym session: Firestore TTL 24 ur" | 010 — Pravni vidik | `functions/src/modules/proximity/proximity.functions.ts` | Grep `ttl` field value `86400` on gym session write |
| C-PRIVACY-04 | "Geohash: 30-min TTL" | 010 — Pravni vidik | `functions/src/modules/proximity/proximity.functions.ts` | Grep geohash document TTL `1800` |
| C-PRIVACY-05 | "Pulse Intercept media: izbriše ob viewedAt ali po 10 min" | 010 — Pravni vidik | `functions/src/modules/` | Grep `viewedAt` delete trigger or 10-min TTL on pulse media |
| C-PRIVACY-06 | "Celoten user account — 72 ur po zahtevi" | 010 — Pravni vidik | `functions/src/modules/` | Grep `72` hours or `259200` seconds in account deletion handler |
| C-PRIVACY-07 | "Telefonska številka: za Pulse Intercept, opcijsko, encrypted" | 010 — Pravni vidik | `lib/src/features/auth/` or `functions/src/modules/` | Verify phone field encrypted (not plain text) in Firestore |
| C-PRIVACY-08 | "GPS koordinate — nikoli na strežniku" | 010 — Pravni vidik | `functions/src/modules/proximity/proximity.functions.ts` | Grep for `latitude`, `longitude`, `lat`, `lng` — should NOT appear in Firestore writes |
| C-PRIVACY-09 | "Email: encrypted at rest" | 010 — Pravni vidik | `functions/src/modules/` or `lib/src/features/auth/` | Verify email field not stored as plaintext in Firestore user doc |
| C-PRIVACY-10 | "Server-side age gate — HttpsError če age < 18" | v8.1 Changelog | `functions/src/modules/auth/` | Grep `age < 18` or `HttpsError` in registration Cloud Function |

---

## 9. Pricing / Premium-Gating

| Claim ID | Exact Quote | Section | Codebase Location | Verification Method |
|---|---|---|---|---|
| C-PRICING-01 | "Signal Prime: €7.99/mes (identifikator: monthly)" | 011 — Monetizacijski Model | `lib/src/features/settings/presentation/premium_screen.dart` or RevenueCat config | Grep `monthly` product identifier, `7.99` price |
| C-PRICING-02 | "Weekend Getaway: €2.99/vikend Pet 19:00–Ned 19:00 (identifikator: weekly)" | 011 — Monetizacijski Model | `lib/src/features/settings/presentation/premium_screen.dart` | Grep `weekly` product identifier, `2.99` price |
| C-PRICING-03 | "Yearly: €59.99/leto (identifikator: yearly)" | 011 — Monetizacijski Model | `lib/src/features/settings/presentation/premium_screen.dart` | Grep `yearly` product identifier, `59.99` price |
| C-PRICING-04 | "Lifetime: €149.99 (identifikator: lifetime)" | 011 — Monetizacijski Model | `lib/src/features/settings/presentation/premium_screen.dart` | Grep `lifetime` product identifier, `149.99` price |
| C-PRICING-05 | "purchases_flutter RevenueCat SDK v10.2.0" | v8.1 Changelog | `pubspec.yaml` | Grep `purchases_flutter:` version pin |
| C-PRICING-06 | "Vsi tieri dajejo enake Premium features — razlikuje se samo trajanje dostopa" | v8.1 Changelog | `lib/src/features/auth/` or provider logic | Verify all tiers set same `isPremium: true` flag; no tier-differentiated feature gates |
| C-PRICING-07 | "isPremium: false za vse nove userje (client + CF)" | v8.1 Changelog | `functions/src/modules/auth/` | Grep `isPremium` default value in registration Cloud Function |
| C-PRICING-08 | "Premium status vidnost: Popolnoma skrit (ni badge)" | 011 — Monetizacijski Model | `lib/src/features/profile/` | Verify no premium badge widget on profile card shown to other users |

---

## 10. Brand / Copy

| Claim ID | Exact Quote | Section | Codebase Location | Verification Method |
|---|---|---|---|---|
| C-BRAND-01 | "It runs while you live." | 04 — Brand Language | `lib/src/` (any screen) or `assets/` | Grep exact string `It runs while you live` |
| C-BRAND-02 | "Your location is never stored. Not policy. Architecture." | 04 — Brand Language | `lib/src/` or onboarding screens | Grep exact string |
| C-BRAND-03 | "Zero swipes. One wave." | 04 — Brand Language | `lib/src/` or onboarding screens | Grep exact string |
| C-BRAND-04 | "You were running. She was running. Tremble noticed." | 04 — Brand Language | `lib/src/` or marketing assets | Grep exact string |
| C-BRAND-05 | "30 minutes. Find each other or don't." | 04 — Brand Language | `lib/src/` | Grep exact string |
| C-BRAND-06 | "Send Wave" (CTA — not 'Like' or 'Show Interest')" | 05 — CTA Strategija | `lib/src/features/dashboard/` or shared widgets | Grep `Send Wave` button label |
| C-BRAND-07 | "Activate Radar" (CTA — not 'Start' or 'Enable')" | 05 — CTA Strategija | `lib/src/features/dashboard/presentation/home_screen.dart` | Grep `Activate Radar` button text |
| C-BRAND-08 | "Get Early Access" (waitlist CTA) | 05 — CTA Strategija | Website / web app | Grep `Get Early Access` in web codebase |

---

## Supplementary: Activity Mode Thresholds

> These span multiple domains above but are grouped here for completeness.

| Claim ID | Exact Quote | Section | Codebase Location | Verification Method |
|---|---|---|---|---|
| C-ACT-01 | "Run Club trigger: 5 min continuous running (CMMotionActivityManager)" | 03 — Run Club aktivacijski flow | `lib/src/core/ble_service.dart` or native channel | Grep `5` minutes as running detection trigger |
| C-ACT-02 | "Run Club autostart: 10 min brez potrditve. Prag 0.55" | 03 — Run Club aktivacijski flow | `lib/src/features/dashboard/` | Grep `10` min autostart timer + `0.55` threshold |
| C-ACT-03 | "Manual Run Club: 6-urni cooldown od konca. Prag 0.70" | 03 — Run Club aktivacijski flow | `lib/src/features/dashboard/` | Grep `6` hour cooldown + `0.70` manual threshold |
| C-ACT-04 | "Run Club: 15 min stationary → deactivation prompt" | 03 — Run Club aktivacijski flow | `lib/src/features/dashboard/` | Grep `15` min stationary deactivation trigger |
| C-ACT-05 | "Run Club: 20 min stationary → auto-deactivate" | 03 — Run Club aktivacijski flow | `lib/src/features/dashboard/` | Grep `20` min auto-deactivate |
| C-ACT-06 | "Gym Mode trigger: 10 min dwell geofence (GPS)" | 03 — Gym Mode aktivacijski flow | `lib/src/features/map/` or geofence service | Grep `10` min dwell timer |
| C-ACT-07 | "Gym Mode autostart: 15 min brez potrditve. Prag 0.55" | 03 — Gym Mode aktivacijski flow | `lib/src/features/dashboard/` | Grep `15` min autostart + `0.55` threshold |
| C-ACT-08 | "Manual Gym Mode: 6-urni cooldown. Prag 0.70" | 03 — Gym Mode aktivacijski flow | `lib/src/features/dashboard/` | Grep `6` hour cooldown + `0.70` manual threshold |
| C-ACT-09 | "Gym Mode: 10 min post-exit recap offer" | 03 — Gym Mode aktivacijski flow | `lib/src/features/dashboard/` | Grep `10` min grace period after gym exit |
| C-ACT-10 | "Gym Mode: 20 min post-exit auto-recap" | 03 — Gym Mode aktivacijski flow | `lib/src/features/dashboard/` | Grep `20` min auto-recap trigger |
| C-ACT-11 | "Event Mode: Geofence auto-detect, 0.55 threshold" | 03 — Event Mode aktivacijski flow | `lib/src/features/map/` | Grep `0.55` in event mode detection |
| C-ACT-12 | "Event Mode: Manual 6-urni cooldown, 0.70 threshold" | 03 — Event Mode aktivacijski flow | `lib/src/features/map/` | Grep `6` hour cooldown + `0.70` in event mode |
| C-ACT-13 | "Event Mode: 10 min post-exit recap offer" | 03 — Event Mode aktivacijski flow | `lib/src/features/map/` | Grep `10` min post-event grace |
| C-ACT-14 | "Event Mode: 20 min post-exit auto-recap" | 03 — Event Mode aktivacijski flow | `lib/src/features/map/` | Grep `20` min auto-recap after event exit |

---

## Supplementary: Security Claims

| Claim ID | Exact Quote | Section | Codebase Location | Verification Method |
|---|---|---|---|---|
| C-SEC-01 | "Screen Protection: Android FLAG_SECURE" | v8.1 Changelog | `android/app/src/main/kotlin/` | Grep `FLAG_SECURE` in MainActivity |
| C-SEC-02 | "Screen Protection: iOS ScreenProtector + RecordingShield overlay" | v8.1 Changelog | `ios/Runner/` | Grep `ScreenProtector` or recording shield in Swift files |
| C-SEC-03 | "Screen Protection aktiven na: ProfileDetailScreen, MatchRevealScreen, RunRecapScreen, EventRecapScreen" | v8.1 Changelog | `lib/src/features/` (4 screens) | Verify protection wrapper present on all 4 screens |
| C-SEC-04 | "Safe Zones: blokira proximity upload ko je user v zaščiteni coni" | v8.1 Changelog | `lib/src/core/ble_service.dart` or `functions/src/modules/proximity/` | Grep safe zone check before proximity upload |
| C-SEC-05 | "SHA-256 Contact Anonymity" | v8.1 Changelog | `functions/src/modules/` or `lib/src/` | Grep `sha256` or `SHA256` in contact hashing |
| C-SEC-06 | "Block + Report: velocity check (3 prijave / 48h → flaggedForReview)" | v8.1 Changelog | `functions/src/modules/` | Grep `3` reports + `48` hours threshold → `flaggedForReview` |
| C-SEC-07 | "assertNotBanned na vseh 10 CF endpointih" | v8.1 Changelog | `functions/src/` | Grep `assertNotBanned` — count occurrences across all CF entry points |
| C-SEC-08 | "isBanned + AccountSuspendedScreen (non-dismissible)" | v8.1 Changelog | `lib/src/` + `lib/src/core/router.dart` | Grep `isBanned` check; verify screen is non-dismissible |

---

## Supplementary: Infrastructure Claims

| Claim ID | Exact Quote | Section | Codebase Location | Verification Method |
|---|---|---|---|---|
| C-INFRA-01 | "Firebase Cloud Functions: europe-west1, Node 22" | Appendix — Stack | `functions/package.json`, `firebase.json` | Grep `europe-west1` region + Node version |
| C-INFRA-02 | "Storage: Cloudflare R2 via media.trembledating.com (GET only, LIST disabled)" | Appendix — Stack | `functions/src/modules/` or CF Worker | Grep `media.trembledating.com` upload URL generation |
| C-INFRA-03 | "Redis: Upstash (rate limiting, session caching)" | Appendix — Stack | `functions/src/modules/` | Grep Upstash client config or `UPSTASH_REDIS_REST_URL` |
| C-INFRA-04 | "Rate limiting: Upstash Redis (3 req / 10 min)" | Appendix — Stack | `functions/src/` rate limit middleware | Grep `3` + `600` (seconds) in rate-limit configuration |
| C-INFRA-05 | "BLE UUID: 73a9429f-fd01-4ac9-9e5a-eabd0d31438e" | Appendix — Stack | `lib/src/core/ble_service.dart` | Grep exact UUID string — strategy doc had wrong UUID (`00001820-…` is Bluetooth SIG Running Speed & Cadence profile); corrected to match `ble_service.dart:26` |
| C-INFRA-06 | "Dev bundle ID: com.pulse · --flavor dev" | Appendix — Stack | `android/app/build.gradle`, `ios/Runner.xcconfig` | Grep `com.pulse` applicationId in dev flavor |
| C-INFRA-07 | "Prod bundle ID: tremble.dating.app · --flavor prod" | Appendix — Stack | `android/app/build.gradle`, `ios/Runner.xcconfig` | Grep `tremble.dating.app` applicationId in prod flavor |

---

*Last updated: 2026-06-02 — C-WAVE-01 and C-WAVE-02 verified and deployed to dev; remaining claims are still unverified unless marked otherwise.*
