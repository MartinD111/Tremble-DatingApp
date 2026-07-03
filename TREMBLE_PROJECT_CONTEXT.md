# TREMBLE — PROJECT CONTEXT
**Stanje: 2. julij 2026, dopoldne CEST**

---

## PRODUKT

**Tremble** — proximity dating app. Pasivno BLE + GPS zaznavanje. Brez swipanja, brez chata, brez shranjenih GPS koordinat (geohash precision 7, ~75-150m, samo v CF RAM, nikoli v Firestore).

Core mechanic: Wave → Mutual Wave → 30-min radar okno → srečanje v resničnem svetu.

**Ekosistem:**
- Flutter 3 + Riverpod 2 + GoRouter app (iOS + Android)
- trembledating.com (Next.js 16, Cloudflare Pages)
- Firebase: `tremble-dev` (dev) | `am---dating-app` (prod, europe-west1) — NIKOLI ne mešaj
- Cloudflare R2: media.trembledating.com (prod), media.dev.trembledating.com (dev)
- Upstash Redis EU (proximity cooldowns, throttling, wave dedup)
- Resend (email), RevenueCat (`purchases_flutter v10.2.0`, dashboard config DONE, koda ima key-name drift — glej Odprti bugi)
- Sentry: `tremble-functions` + `tremble-app`

**Pravna entiteta:** AMS Solutions d.o.o. (Slovenija, registrirana 7. maj 2026). GDPR controller: AMS Solutions d.o.o.

**Co-founderja:** Aleksandar (GitHub: unfab, iPhone 15 UDID `00008120-001618402604201E`) + Martin (GitHub: MartinD111, Samsung S25 Ultra). Oba delata vse — koda, branding, legal, marketing, brez delitve vlog.

**Target markets:** Ljubljana, Koper, Zagreb (Phase 1). Adriatic focus.

**Repo:** `MartinD111/Tremble-DatingApp`, lokalno `/Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app`.

---

## STANJE BUILDOV (TestFlight)

| Build | Datum | Status | Opomba |
|---|---|---|---|
| 9 | 30 jun | Complete | Stale za testiranje |
| 10 | 1 jul | Complete | B2 background crash fix (home_screen.dart:424) |
| 11 | 2 jul 01:00 | Complete | Sentry async error handlers (PlatformDispatcher + Isolate) |
| 12 | 2 jul 01:30 | Uploadan | iOS background fix (getPositionStream, BLE Android guard, BGTask heartbeat) — ima bug: brez timer fallbacka za statične userje |
| 13 | — | Ne obstaja | Po commit geo_service.dart timer fallback fix |

**Verification standard:** 200 Flutter testov, 52 CF testov (7 test suites), `flutter analyze` 0 issues, `tsc` clean.

**Distribucija:** Internal Testing (ne External) — instant, brez Beta App Review. Testerji morajo biti App Store Connect Users na teamu `LB6LS532CV`.

---

## AKTIVNI BUGI

### 🔴 P1 — geo_service.dart timer fallback — DONE, NI COMMITAN
`lib/src/core/geo_service.dart` modificiran v working tree. 200/200 testi, analyzer clean.
`distanceFilter: 50m` na getPositionStream ne odda eventov ko user stoji → updatedAt se ustavi → user izgine z radarjev.
Fix: `Timer.periodic(90s)` vzporedno s streamom, oba tečeta skozi `_uploadLocation()`.
**Akcija: git commit + build 13.** Task: `6h2jg9xw7X4MM29w`

### 🟡 P2 — Gym Firestore permission-denied
`updateSelectedGyms` (`auth_repository.dart:1035`) pada na `validUserUpdateTypes()`/`validUserUpdateSizes()` v firestore.rules.
Task: `6h2RpGvGWFvc5JcP` (autonomous)

### 🟡 P2 — RevenueCat API key drift
Koda bere `REVENUECAT_API_KEY`, env ima `REVENUECAT_APPLE_API_KEY`. Paywall nefunkcionalen.
Task: `6h2Mmmvg4qMPrF7P` (autonomous)

### 🟡 P2 — PII debugPrint (95 klicev)
`debugPrint()` teče v release modu. UIDs, FCM tokeni, photo URLji gredo v App Store binary.
Mora biti zaprto pred App Store submission.
Task: `6h2Mmp4Xp2j2JJCw` (autonomous)

### 🟡 P2 — App Check fail-open hardening
`TREMBLE_ENV ?? 'dev'` tiho ugasne App Check namesto da glasno pade.
Naredi PO potrditvi Faze C.
Task: `6h2Rv69r5pqpr5hw` (autonomous)

---

## PROD BACKEND

36 CF funkcij, europe-west1. Node.js v22.
Schedulerji: `scanProximityPairs` (1 min), `processWeekendPasses` (hourly), `expireGymSessions/RunModes/EventModes` (60 min).

**Env fix (2. jul):** `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN`, `PLACES_KEY_PROD`, `REVENUECAT_APPLE_API_KEY` dodani v `functions/.env` brez `< >` oklepajev. Redeploy OK, 36/36 funkcij.

**Proximity filter (commit `8ef1258`):** mutual gender → mutual age → nicotine → `calculateCompatibilityScore` ≥ 0.70 (0.55 za shared context: `activeEventId || isRunModeActive || activeGymId`). Empty-hobby neutral 0.50 → 0.30.

**Redis:** proximity cooldown (30 min), global throttle (10 min, max 3/window), wave dedup (5 min).

**TTL polja:** `proximity_events`/`run_encounters` → `expiresAt`. `rateLimits`/`gdprRequests` → `ttl`.

---

## iOS KONFIGURACIJA

| Kaj | Vrednost |
|---|---|
| Bundle ID dev / prod | `tremble.dating.app.dev` / `tremble.dating.app` |
| Prod extensions | `tremble.dating.app.RadarWidget` + `tremble.dating.app.NotificationService` |
| ZASEDENA (nikoli) | `.radar` + `.notifications` — tuj account |
| Team ID | `LB6LS532CV` |
| App Store Connect App ID | `6782018915` (ime: "Tremble Dating") |
| iPhone 15 UDID | `00008120-001618402604201E` |
| App Store Connect API | Key `V24BM2VRC2`, Issuer `752b6022-1929-42dd-b8a4-c894cd4f131d`, `.p8` v `~/.appstoreconnect/private_keys/` |
| App Check debug token | `26697195-D797-4FFE-ADEA-9631258A1C88` (pod `tremble.dating.app.dev`) |

**Flavor-switching (commit `b6338a5`):** `*-prod` → `GoogleService-Info-Prod.plist` (`am---dating-app`), ostalo → `GoogleService-Info-Dev.plist` (`tremble-dev`). Oba plist gitignored.

**Prod build ukaz:**
```bash
flutter build ipa --flavor prod \
  --dart-define-from-file=.env.prod.json \
  --dart-define=FLAVOR=prod \
  --export-options-plist=ios/ExportOptions.plist \
  --build-number=N

xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa \
  --apiKey V24BM2VRC2 \
  --apiIssuer 752b6022-1929-42dd-b8a4-c894cd4f131d
```

**Dev run ukaz:**
```bash
flutter config --no-enable-lldb-debugging
security unlock-keychain ~/Library/Keychains/login.keychain-db && \
flutter run --flavor dev --dart-define-from-file=.env.json --dart-define=FLAVOR=dev \
  -d 00008120-001618402604201E
```

---

## BACKGROUND DETECTION — KLJUČNI X-FAKTOR

Arhitektura (po build 12): `getPositionStream(distanceFilter: 50m, accuracy: medium)` drži iOS proces živ prek `location` background mode. Vzporedno: `Timer.periodic(90s)` kot fallback za statične userje (build 13).

`BGAppRefreshTask` ne garantira intervalov (Apple DTS Engineer potrjeno) — napačen za 60s heartbeat. Zamenjano z location stream v build 12.

`BleService().stop()` na `AppLifecycleState.paused` je Android-specifična napaka — `Platform.isAndroid` guard dodan v build 12.

**Status testiranja:** Faza C test #3 čaka na build 13. Prejšnji testi kontaminirani (crash v build 9, bug v build 12).

---

## MONETIZACIJA

| Produkt | Cena | Product ID | Status |
|---|---|---|---|
| Signal Prime Monthly | €7.99/mo | monthly | ✅ App Store Connect |
| Signal Prime Yearly | €59.99/leto | yearly | ✅ App Store Connect |
| Lifetime Non-Consumable | €149.99 | lifetime | ✅ App Store Connect |
| Weekend Getaway | €2.99/vikend | weekly | ✅ App Store Connect |

RevenueCat dashboard DONE. Koda ima key-name drift (glej Aktivni bugi). Sandbox test čaka na key fix.

**Paywall trigger copy (SL):** "Bil/a je izven tvojega 100m radiusa. S Pro bi jo/ga zaznal/a."

---

## BRAND

Barve: Rose `#F4436C`, Yellow `#F5C842` (nikoli CTA), Green `#2D9B6F`, Graphite `#1A1A18`, Cream `#FAFAF7`.
Fonti: Playfair Display (display), Lora (body), Instrument Sans (UI), JetBrains Mono (tehnično).
Glas: kratke povedi, 2. oseba direktno, brez hype, brez emoji v naslovih, mehaniko opisuj, čustev ne obljubljaj.
Prepovedano: glassmorphism content cards, 3D phone mockupi, stock couple photos, "revolutionary/seamless/game-changing/find your person/swipe/chat".
Privacy copy pravilo: "GPS computed in CF RAM only, never stored" — NE "zero location stored" (geohash ~150m JE shranjen začasno).

---

## TODOIST

Project: `6fxxh6MXfmh2q3FP`
Sekcije: Blockers `6gj5rPJfRwPCfMGw` · App `6ggWg86gP3qF3Hfw` · Website `6ggWg86XHJp37fjw` · Marketing `6ghmF6Gxjc9FP9rP` · Legal `6ggWg85rFC7jqXcP` · Infra `6gj5rPP2hwh8WmfP`

Pravilo: vedno `sectionId` za filtriranje. Labels: `founder-action` vs `autonomous`, vsak task ima natanko enega.

Notion: `315b7419-2f1e-80a1-999e-fdeb5b425aea`

---

## KRITIČNA PRAVILA — NE KRŠI

- NIKOLI push na main direktno · prod deploy avtonomno · sprememba AndroidManifest/Info.plist/google-services/entitlements brez soglasja
- GPS samo v CF RAM, nikoli v Firestore
- `effectiveIsPremiumProvider` za vse premium checke, nikoli raw `isPremium` iz Firestore
- `.radar` + `.notifications` extension ID-ji zasedeni pod tujim accountom — nikoli ne uporabi
- Pri deljenju `.env` vsebine v chat: vedno maskiraj vrednosti, imena ključev so OK
- Pred kakršnim koli file-creation/code taskom: preveri relevanten skill v `/mnt/skills/`
