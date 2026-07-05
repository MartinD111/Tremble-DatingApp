# TREMBLE — PROJECT CONTEXT
**Stanje: 5. julij 2026**

---

## PRODUKT

**Tremble** — proximity dating app. Pasivno BLE + GPS zaznavanje. Brez swipanja, brez chata, brez shranjenih točnih GPS koordinat. V Firestore se začasno (z 24-urnim TTL-om) shrani le grob geohash precision 7 (~150m x 75m celica). Natančne GPS koordinate se procesirajo izključno v pomnilniku Cloud Functions, kjer se preračunava dejanski domet: **100m za brezplačne (Free)** in **250m za premium (Pro)** uporabnike.

Core mechanic: Wave → Mutual Wave → 30-min radar okno → srečanje v resničnem svetu.

**Ekosistem:**
- Flutter 3 + Riverpod 2 + GoRouter app (iOS + Android)
- trembledating.com (Next.js 16, Cloudflare Pages)
- Firebase: `tremble-dev` (dev) | `am---dating-app` (prod, europe-west1) — NIKOLI ne mešaj
- Cloudflare R2: media.trembledating.com (prod)
- Upstash Redis EU (proximity cooldowns, throttling, wave dedup)
- Resend (email), RevenueCat (`purchases_flutter v10.2.0`, dashboard config DONE, koda ima key-name drift)
- Sentry: `tremble-functions` + `tremble-app`

**Pravna entiteta:** AMS Solutions d.o.o. (Slovenija, registrirana 7. maj 2026). **GDPR controller: AMS Solutions d.o.o.** — ne fizična oseba. Ta trditev se je napačno ponavljala v več sejah prek prilepljenega zastarelega context bloka; to je edini pravilen vir.

**Co-founderja:** Aleksandar (GitHub: unfab, iPhone 15 UDID `00008120-001618402604201E`) + Martin (GitHub: MartinD111, Samsung S25 Ultra). Oba delata vse — koda, branding, legal, marketing, brez delitve vlog.

**Target markets:** Ljubljana, Koper, Zagreb (Phase 1). Adriatic focus.

**Repo:** `MartinD111/Tremble-DatingApp`, lokalno `/Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app`.

---

## STANJE BUILDOV

### iOS (TestFlight)

| Build | Datum | Status | Opomba |
|---|---|---|---|
| 14 | 2 jul | Complete | `AppleSettings` + `allowBackgroundLocationUpdates` + Timer fallback. Faza C PASS. |
| 16 | — | Ne obstaja še | Naslednji build — vključuje App Check fix, map tab fix, maxDistance purge |

### Android (Play Console — Internal Testing)

| Build | Datum | Status | Opomba |
|---|---|---|---|
| 15 (AAB) | 4 jul | Live | Manifest fix, 18.561 podprtih naprav |
| 16 | — | Ne obstaja še | Vključuje App Check fix (glej spodaj) |

**App Check — dokončno rešeno (5 jul):** SHA-1 + SHA-256 iz Play App Signing dodana v Firebase Console, svež `google-services.json`, Play Integrity API enabled na GCP, Android app registriran s Play Integrity providerjem v App Check. Koda je bila ves čas čista (`main.dart:63`) — root cause je bil manjkajoč SHA fingerprint v Firebase, ki je povzročal malformed App Check token (`invalid-argument`), ne attestation rejection.

**Odločitev testerjev (5 jul):** vsi štirje (Aleksandar, Martin, žena, Nikolina) brišejo obstoječe test builde in namestijo build 16 sveže. Ni potrebe po version-compat skrbi za trenutni testni krog.

**App Store Connect (iOS):** App ID `6782018915`. Team ID `LB6LS532CV`.

---

## AKTIVNI BUGI / ODPRTI TASKI

### 🔴 P1 — App Store blockerji (Todoist, sekcija App) — nedotaknjeni več sej

| Task | ID | Tip |
|---|---|---|
| CRIT-1: GDPR TTL field (`ttl` vs `expiresAt` na gdprRequests) | `6h332R24cr3Qx9xw` | autonomous |
| CRIT-2: proximity TTL (`geoHashExpiresAt` field/duration verify) | `6h332R4PwWhvrfxP` | autonomous |
| PRIV-1: encryption wording v `consent_step.dart:179` | `6h332R8fhG7X9FHP` | founder-action |
| PRICE-3: Weekend Getaway oglaševan brez backend enforcementa | `6h332RFRW946QWXw` | founder-action |

Priporočilo za PRICE-3: odstrani specifično uro-okno iz marketing copyja, prodaj kot "weekend pass" brez obljube točnih ur, enforcement zgradi post-launch. CRIT-1/CRIT-2 sta GCP konzolne preverbe, verjetno pod eno uro dela skupaj. PRIV-1 je branje ene vrstice.

### 🔴 P1 — Nikolina onboarding loop (5 jul, FIX GOTOV, DEPLOY PENDING)

Root cause: `onUserDocCreated` (functions/src/modules/auth/auth.functions.ts) je preverjal `createdAt` namesto `isOnboarded` v idempotency guardu — comment/code mismatch. Google userji (brez client-side initial doca) so ob vsakem sign-inu dobili `isOnboarded: false` povoženo čez dokončan profil.

Fix: field-level guardi na `isOnboarded`/`isPremium`/`isAdmin`/`createdAt` v triggerju, `completeOnboarding` doda `createdAt` če maniha. 3 novi regresijski testi, 55/55 testov zeleno. **Ni deployano na tremble-dev.** Nikolinin obstoječi doc potrebuje ročni `isOnboarded: true` popravek v Firebase Console po deployu.

### 🟡 P2 — Ostali znani bugi

RevenueCat API key drift, PII debugPrint cleanup, gym Firestore permission-denied, App Check fail-open hardening, npm audit moderate (`uuid`/`firebase-admin` chain). Podrobnosti in Codex prompti so v posameznih Todoist taskih.

### ⚪ Nerazrešena kontradikcija

Task `6gwM94Mg74x78VGP` trdi "DONE (build 4)" za C1-C6 + H1-H9 + M1-M4, ampak 17 posameznih taskov je još odprtih v Todoistu. Ne zapiraj na zaupanje — potreben Claude Code audit dejanskega stanja kode.

---

## COMPATIBILITY / MATCHING ARHITEKTURA

**Status: Implementirano na veji `fix/ci-tests-and-compatibility` (merga se v `main`).**

### Stanje kode (popravljeno v zadnji seji)

`functions/src/modules/compatibility/compatibility_calculator.ts` in `proximity.functions.ts`:
- Uteži: hobbiji 50% / osebnost 25% / lifestyle 25%. Threshold 0.70 standard, 0.55 za shared event/run/gym context.
- Hard filtri (score = 0.0, par se ne prikaže): nikotin je odstranjen iz hard filtrov kalkulatorja in se nanj zanaša izključno skozi zunanji `nicotineCompatible` pre-filter. Pitje (`partnerDrinkingHabit === none_only`) in `lookingFor` (brez overlapa) ostajata.
- **Religija in Etničnost:** Odstranjena iz hard filtrov! Obe sta spremenjeni v mehko (soft) oceno znotraj lifestyle bucketa. Preference se preverjajo dvosmerno in simetrično. Legacy enum `same_only` je backward-compatible preimenovan v `prefer_same` ( Firestore dokumentov ni potrebno migrirati).
- **Nikotin premium-gate fix:** Popravljeno, da je gating simetričen. Requesterjeve in candidate-ove vrednosti so zdaj pravilno gated preko prenosnih spremenljivk `myNicotineFilter`/`theirNicotineFilter` znotraj `proximity.functions.ts` pred klicem compatibility kalkulatorja. Dodan je regresijski test za `none_only` prostih kandidatov.
- Etničnost, barva las, višina: shranjeni v Firestoru. Etničnost se sedaj uporablja v soft lifestyle scoringu.

*Naslednji korak za religijo/etničnost:* Gate-anje na `sensitiveDataConsent` flag (GDPR varovalka), ki čaka na legal review.

---

## GDPR / LEGAL

Code audit je razkril strukturni problem:

1. `religion_step.dart` + `ethnicity_step.dart` nimata opcije "ne želim povedati". Continue gumb je blokiran, dokler ni izbire — razkritje je funkcionalno obvezno kljub temu, da sta polji `.nullish()` v `auth.schema.ts`.
2. `consent_step.dart:169-183` združuje religijo + etničnost v EN checkbox skupaj z "interests, preferences" — ni granularno.
3. `consent_step.dart:31-36` zahteva vseh 5 checkboxov obkljukanih za Continue — registracija je nemogoča brez privolitve v posebne kategorije podatkov (GDPR "freely given" standard kršitev).

**Sekvenca v Todoistu:**
1. Legal review (`6h3JCC8m76XQPQ4P`, P1, founder-action) — blokira vse spodaj
2. Skip opcija na religion/ethnicity stepih (`6h3JCC8Ffphh692P`, P1, autonomous)
3. Razcep bundled consenta, ločen `sensitiveDataConsent` flag, ne blokira registracije (`6h3JCCG7FFPh667P`, P1, autonomous)
4. Gate religion/ethnicity soft scoringa na consent (`6h3JCCGrMxP9PwXw`, P1, autonomous)

---

## PROD BACKEND

36 CF funkcij, europe-west1, Node.js v22. Schedulerji: `scanProximityPairs` (1 min), `processWeekendPasses` (hourly), `expireGymSessions/RunModes/EventModes` (60 min).

**Redis (Upstash):** proximity cooldown (30 min), global throttle (10 min, max 3/window), wave dedup (5 min).

**TTL polja:** `proximity_events`/`run_encounters`/`idempotencyKeys` → `expiresAt`. `rateLimits`/`gdprRequests` → `ttl`. Verifikacija v teku (CRIT-1, CRIT-2).

**maxDistance — dokončno odstranjen:** dead field iz onboardinga in profile-edita popolnoma počiščen iz `functions/src` in `lib` (grep-potrjeno 0 pojavitev). Backend radij je vedno bil pravilen tier-based konstant (`RADIUS_FREE_M = 100`, `RADIUS_PRO_M = 250`).

---

## iOS KONFIGURACIJA

| Kaj | Vrednost |
|---|---|
| Bundle ID dev / prod | `tremble.dating.app.dev` / `tremble.dating.app` |
| Prod extensions | `tremble.dating.app.RadarWidget` + `tremble.dating.app.NotificationService` |
| ZASEDENA (nikoli) | `.radar` + `.notifications` — tuj account |
| Team ID | `LB6LS532CV` |
| App Store Connect App ID | `6782018915` |
| App Check debug token | `26697195-D797-4FFE-ADEA-9631258A1C88` (pod `tremble.dating.app.dev`) |

**Background location (build 14, PASS):** `LocationSettings` → `AppleSettings` v `geo_service.dart`, `Timer.periodic(90s)` fallback za statične userje.

**Prod build ukaz:**
```bash
flutter build ipa --flavor prod \
  --dart-define-from-file=.env.prod.json \
  --dart-define=FLAVOR=prod \
  --export-options-plist=ios/ExportOptions.plist \
  --build-number=N
```

---

## ANDROID KONFIGURACIJA

**App Check:** `AndroidPlayIntegrityProvider()` za prod flavor. Zahteva namestitev prek Play Store (sideloadan APK ne more pridobiti veljavne Play Integrity attestacije). SHA-1 + SHA-256 iz Play App Signing sta registrirana v Firebase Console.

**AndroidManifest duplicate permission (rešeno, build 15):** `tools:node="remove"` na `<uses-permission-sdk-23>` v app manifestu za `flutter_ble_peripheral` konflikt.

**minSdk:** eksplicitno 24 (Android 7.0+) — tranzitivne odvisnosti to zahtevajo.

**Prod build ukaz:**
```bash
flutter build appbundle --flavor prod \
  --dart-define-from-file=.env.prod.json \
  --dart-define=FLAVOR=prod \
  --build-number=N
```

---

## MONETIZACIJA

| Produkt | Cena | Product ID | Status |
|---|---|---|---|
| Signal Prime Monthly | €7.99/mo | monthly | ✅ App Store Connect |
| Signal Prime Yearly | €59.99/leto | yearly | ✅ App Store Connect |
| Lifetime Non-Consumable | €149.99 | lifetime | ✅ App Store Connect |
| Weekend Getaway | €2.99/vikend | weekly | ✅ App Store Connect — **enforcement manjka, glej PRICE-3** |

RevenueCat dashboard DONE. Koda ima key-name drift. Sandbox test čaka na key fix.

**Paywall trigger copy (SL):** "Bil/a je izven tvojega 100m radiusa. S Pro bi jo/ga zaznal/a."

---

## BRAND

Barve: Rose `#F4436C`, Yellow `#F5C842`, Green `#2D9B6F`, Graphite `#1A1A18`, Cream `#FAFAF7`.
Fonti: Playfair Display (display), Lora (body), Instrument Sans (UI), JetBrains Mono (tehnično).
Glas: kratke povedi, 2. oseba direktno, brez hype, brez emoji v naslovih.
Prepovedano: glassmorphism content cards, 3D phone mockupi, stock couple photos, "revolutionary/seamless/game-changing/find your person/swipe/chat".
Privacy copy pravilo: "GPS computed in CF RAM only, never stored" — NE "zero location stored" (grob geohash ~150m JE shranjen začasno).

---

## TODOIST

Project: `6fxxh6MXfmh2q3FP`
Sekcije: Blockers `6gj5rPJfRwPCfMGw` · App `6ggWg86gP3qF3Hfw` · Website `6ggWg86XHJp37fjw` · Marketing `6ghmF6Gxjc9FP9rP` · Legal `6ggWg85rFC7jqXcP` · Infra `6gj5rPP2hwh8WmfP`

Labels: `founder-action` vs `autonomous`.

---

## KRITIČNA PRAVILA — NE KRŠI

- NIKOLI push na main direktno · prod deploy avtonomno · sprememba AndroidManifest/Info.plist/google-services/entitlements brez soglasja
- GPS natančne koordinate samo v CF RAM, nikoli v Firestore (v Firestore gre le grob geohash p7 s 24-urnim TTL-om)
- `effectiveIsPremiumProvider` za vse premium checke, nikoli raw `isPremium` iz Firestore
- Raw compatibility score (`calculateCompatibilityScore`) nikoli ne gre v Firestore ali v UI response — client dobi samo boolean flage
- `.radar` + `.notifications` extension ID-ji zasedeni pod tujim accountom — nikoli ne uporabi
- Pri deljenju `.env` vsebine v chat: vedno maskiraj vrednosti
- Pred kakršnim koli file-creation/code taskom: preveri relevanten skill v `/mnt/skills/`
- `minSdk` nikoli ne postavljaj pod 24
- Android testni buildi grejo izključno prek Play Console Internal Testing, nikoli sideload
- Ta dokument (`TREMBLE_PROJECT_CONTEXT.md`) je edini vir resnice za splošni kontekst projekta.
