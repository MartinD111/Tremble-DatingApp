# TREMBLE — IMPLEMENTATION PLAN
**Stanje: 2. julij 2026, dopoldne CEST**

---

## TRENUTNO ZAPOREDJE (kritična pot do App Store)

```
Faza A — Redis/TREMBLE_ENV verifikacija          ✅ DONE
Faza B1 — Upstash env fix + redeploy             ✅ DONE
Faza B2 — Background crash fix (home_screen)     ✅ DONE (build 10)
Sentry async error handlers                      ✅ DONE (build 11)
Background architecture audit                    ✅ DONE
iOS background fix (getPositionStream)           ✅ DONE (build 12)
GeoService timer fallback (statični userji)      ✅ DONE — NI COMMITAN
Build 13                                         ⬜ NASLEDNJE
Faza C — background test #3                      ⬜
Faza D — BLE proximity matrix                    ⬜
P2 cleanup (PII, App Check hardening)            ⬜
Faza E — App Store submission                    ⬜
```

---

## FAZA: BUILD 13
**Task:** `6h2jg9xw7X4MM29w` (founder-action, P1)

`geo_service.dart` je modificiran v working tree (timer fallback za statične userje, 200/200 testi, analyzer clean). Ni commitan.

```bash
# 1. Commit
git add lib/src/core/geo_service.dart
git commit -m "fix(geo): add 90s timer fallback for stationary users"

# 2. Build
flutter build ipa --flavor prod \
  --dart-define-from-file=.env.prod.json \
  --dart-define=FLAVOR=prod \
  --export-options-plist=ios/ExportOptions.plist \
  --build-number=13

# 3. Upload
xcrun altool --upload-app --type ios \
  -f build/ios/ipa/*.ipa \
  --apiKey V24BM2VRC2 \
  --apiIssuer 752b6022-1929-42dd-b8a4-c894cd4f131d
```

4. App Store Connect → TestFlight → Internal Testing → Family+Friends → dodaj build 13.

**Blocker:** Ne testiraj Faze C na buildu 12 — ima bug (brez timer fallbacka).

---

## FAZA C — BACKGROUND TEST #3
**Task:** `6h2jGCHVvM78c2Mw` (founder-action, P1)
**Predpogoj:** Build 13 v TestFlightu.

### Protokol

Na iPhone 15 z build 13:

1. Odpri app → preveri da je radar aktiven
2. Zapri app (home button) — zaslon ZAKLENJEN, v žepu, ne dotikaj se
3. **Segment 1 — sede (20 min):** sedi pri miru. Po 20 min preveri Firestore:
   `https://console.firebase.google.com/project/am---dating-app/firestore/data/proximity`
   → `proximity/{tvoj_uid}` → `updatedAt` mora tiktakati. Interval: ~90s (timer fallback).
4. **Segment 2 — hodi (20 min):** sprehod, zaslon zaklenjen. Po 20 min preveri `updatedAt`.
   Interval: ~1-3 min (stream events) ALI ~90s (timer), karkoli prej.
5. **Segment 3 — sede (20 min):** vrni se, sedi. Po 20 min preveri `updatedAt`. Interval: ~90s.

### Kriterij za uspeh

`updatedAt` se osvežuje v vseh treh segmentih. Ni potrebno da je točno 90s — iOS ima jitter. Kriterij: osvežuje se vsaj enkrat na 3 minute v vsakem segmentu.

### Kriterij za neuspeh

`updatedAt` se ustavi za več kot 5 minut med testom. Če se to zgodi:
- Zapiši kateri segment je padel (sede/hodi/sede)
- Zapiši zadnji `updatedAt` timestamp in čas ko si preveril
- Sporoči v naslednjem chatu — arhitektura potrebuje drugačen pristop

### NE med testom

- Ne odklepaj telefona med testom (razen za preverjanje Firestore po segmentu)
- Ne vozi z avtom med testom
- Ne forceaj app close in reopen

---

## FAZA D — BLE PROXIMITY MATRIX TEST
**Predpogoj:** Faza C ✅
**Potrebuješ:** Aleksandar (iPhone 15, build 13) + Martin (Samsung S25 Ultra, Android build) + partner/tretja oseba opcijsko

### Setup pred testom

Preveri za OBA profila:
- Hobbies izpolnjeni (vsaj 3 v isti kategoriji skupaj)
- `introvertScale` izpolnjen
- Lifestyle polja izpolnjena
- Hetero par → gender compatibility ✅

Izračunaj compatibility score ročno iz `users/{uid}` Firestore dokumentov preden začneš.
Formula: `(hobby×0.50) + (personality×0.25) + (lifestyle×0.25)`. Prag: ≥ 0.70.

### Test

1. Oba ugasneta app (force quit)
2. Oba oddata app (restart)
3. Hodita skupaj ~5 min
4. Preveri Firebase Console → `proximity_events` → ali je nastal dokument za par

### Kriterij za uspeh

`proximity_events` dokument obstaja za ta par v 5 minutah od skupne hoje.

---

## FAZA E — APP STORE SUBMISSION
**Predpogoj:** Faza C ✅ + Faza D ✅ + P2 cleanup taskov zaprtih

### P2 taski ki morajo biti DONE pred submission

| Task | ID | Tip |
|---|---|---|
| PII debugPrint cleanup (95 klicev) | `6h2Mmp4Xp2j2JJCw` | autonomous |
| RevenueCat key drift fix | `6h2Mmmvg4qMPrF7P` | autonomous |
| Gym Firestore permission fix | `6h2RpGvGWFvc5JcP` | autonomous |
| App Check fail-open hardening | `6h2Rv69r5pqpr5hw` | autonomous |

### App Store submission checklist

- [ ] App Store screenshots v Transporter (iap_review_screenshot_5-9.png na Desktopu)
- [ ] App Store description (EN + SL)
- [ ] Privacy Policy URL live (trembledating.com/privacy)
- [ ] Support URL live (trembledating.com/bug)
- [ ] Age rating: 17+
- [ ] `ITSAppUsesNonExemptEncryption` = false v Info.plist
- [ ] PrivacyInfo.xcprivacy prisoten (iOS 17.4+ zahteva)
- [ ] IAP products: monthly, yearly, lifetime, weekly — vsi v App Store Connect ✅
- [ ] RevenueCat sandbox end-to-end test ✅

---

## OPEN INFRA TASKS (founder-action, ni na kritični poti)

- TTL policies v Firebase Console (proximity_events + run_encounters)
- Places API key restrictions v GCP Console
- Upstash segmentation (prod vs dev Redis)
- Dependabot (Martin)

---

## MARKETING (vzporedno, ne blokira launch)

- Cloudflare Pages SPA (repo: `unfab/Tremble.Marketing`) — built, not deployed. Čaka: Anthropic API key, Upstash creds, CF account ID + API token, `CF_OPS_PASSWORD`
- Meta app approval: pending (2-4 tedni)
- Pricing carousel: ready, čaka vizualni review founderja

---

## KLJUČNA TEHNIČNA ZNANJA (za referenco)

**Background execution na iOS:**
- `BGAppRefreshTask` ne garantira intervalov — napačen za 60s heartbeat
- `getPositionStream()` + `location` background mode je edina zanesljiva metoda
- `distanceFilter: 50m` blokira statične userje → `Timer.periodic(90s)` fallback je obvezen
- `BleService().stop()` na `paused` ubije BLE scanning na iOS → `Platform.isAndroid` guard

**Proximity arhitektura:**
- GPS samo v CF RAM, nikoli Firestore
- Geohash precision 7 (~75-150m) je shranjeni unit
- BLE service UUID: `73a9429f-fd01-4ac9-9e5a-eabd0d31438e`
- `scanProximityPairs` (1-min scheduled CF) je entry point za vse proximity matching

**App Check:**
- `TREMBLE_ENV ?? 'dev'` → če env var manjka, App Check tiho ugasne
- Dev build (`flutter run`) ne more producirati veljavnih App Attest tokenov — samo TestFlight/App Store binarji
- Debug token: `26697195-D797-4FFE-ADEA-9631258A1C88` pod `tremble.dating.app.dev`

**isPremium:**
- `effectiveIsPremiumProvider` = RevenueCat entitlement + Firestore fallback
- Raw `isPremium` iz Firestore — nikoli direktno

**TTL polja (točna imena):**
- `proximity_events` / `run_encounters` / `idempotencyKeys` → `expiresAt`
- `rateLimits` / `gdprRequests` → `ttl`
