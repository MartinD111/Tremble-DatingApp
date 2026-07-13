# PLAN 03 — APLIKACIJSKA KODA
**Faza 3 · Začne se po PLAN_01 (varen CI) · Koraki 3.1-3.2 takoj, ostalo po vrsti · Ocenjen čas: 3-5 dni CLI dela**

Preberi PLAN_00_MASTER_INDEX.md pred tem dokumentom. Vsak korak tu je
🤖 CODE — poln prompt je vključen, kopiraj ga v CLI dobesedno. Po vsakem:
founder preveri Output polje in dokaze, preden gre naprej.

---

## KORAK 3.1 — CROSSING_PATHS vidna notifikacija (P1 — jedrna mehanika)

**Kontekst:** Backend deluje (proximity_events zapisan 11. jul), ampak
uporabnik v ozadju NIKOLI ne vidi obvestila:
- Android: sendCrossingPaths pošlje data-only FCM (brez notification
  bloka) — Android v ozadju ne prikaže ničesar; edina display pot
  (notification_service.dart ~358) zahteva message.notification! in teče
  samo v foregroundu.
- iOS: apns alert-body-loc-key `notify_nearby_body_rich` se razrešuje
  proti NATIVE bundlu (ios/Runner/*/Localizable.strings) — ta datoteka NE
  OBSTAJA (samo InfoPlist.strings). Ključ v Flutter translations.dart za
  APNs ni relevanten.
- Bonus bug: pairsNotified++ se inkrementira tudi brez FCM tokena —
  metrika laže.

**CLI prompt (dobesedno):**
```
In the Tremble project, fix the architectural flaw that makes
CROSSING_PATHS notifications invisible to backgrounded users on BOTH
platforms.

## Decision (already made by founder): take path (a) — the Cloud
Function sends a full FCM notification payload (title/body localized
server-side from the recipient's users doc `language` field, fallback
EN), replacing the data-only + loc-key approach. Keep the existing data
fields so foreground in-app handling continues to work.

## Files
- functions/src/modules/proximity/proximity.functions.ts
  (sendCrossingPaths and the second-encounter variant)
- lib/src/core/notification_service.dart (verify foreground path still
  dedupes correctly when a notification block is now present — avoid
  double-display in foreground: if app is foreground, suppress system
  banner and keep in-app pill)
- Remove/ignore the now-dead loc-key APNs fields.

## Also fix
pairsNotified must count actual successful sends (use the results of
Promise.allSettled), not optimistic pre-send increments.

## Tests
- CF test: mock FCM, assert notification.title/body present and
  localized per recipient language (test at least en + sl), assert
  pairsNotified reflects real success/failure (one token missing →
  count reflects it).
- Flutter: existing tests must stay green.

## Constraints
- Do NOT modify Info.plist or AndroidManifest.xml.
- No PII in logs (truncate UIDs to 8 chars).
- flutter analyze 0 issues; flutter test all green;
  cd functions && npm run build && npm run lint && npm test all green.
- Branch: feat/crossing-paths-visible-notification
- tasks/plan.md rewritten with Plan ID: 20260712-fix-crossing-paths-visibility
- PR title: [PLAN-ID: 20260712-fix-crossing-paths-visibility] fix(notifications): CROSSING_PATHS visible on both platforms
- PR body: include literal phrases Verification checklist, unit tests,
  integration tests, security scan. This touches core notification
  infra — include literal risk_level: high.
- Evidence in PR body: grep output showing no remaining loc-key
  references, test run summary.
```

**Founder po merge:** E2E verifikacija ostane ročna — ponovi mini BLE
test z novima buildoma (PLAN_05 korak 5.2 pokrije polni matrix).

**Output:**
```text
PR / merge datum:  PR #17 (github.com/MartinD111/Tremble-DatingApp/pull/17)
                    squash-merged v main 2026-07-12 (commit 7df1159).
                    Feature commit: d457e95.
Deploy target:      PRODUCTION (founder odločitev 2026-07-12 —
                    dev preskočen, popravek gre direktno v prod
                    pri naslednjem `firebase deploy --only functions`).
Founder approval:   granted via GitHub Environment `founder-approval`
                    (risk_level: high gate — ⑦ MPC — Founder Approval).
Testni dokaz (št. testov, jeziki pokriti):
  - functions/ Jest: 100 tests / 11 suites GREEN
    (novo: proximity_crossing_paths.test.ts — pokriva EN + SL +
    fallback za neznan locale + one-token-missing → pairsNotified
    pravilen + silent-mode ni štet).
  - Flutter: 221 tests GREEN, `flutter analyze` 0 issues.
  - Grep evidence: `alert-body-loc-key` / `alert-title-loc-key` /
    `notify_nearby_body_rich` nikjer več v produkcijskih payloadih
    (functions/src/modules) — ostane samo dokumentacijski komentar
    na proximity.functions.ts:140 in test assertions.
  - CI: vseh 10 required checks PASS (MPC PR-Metadata na prvem
    pushu, ⑦ Founder Approval po odobritvi, ⑧ All Checks Passed).
Locali pokriti:      en (fallback), sl. Ostali locale-i padejo na
                    en (dokumentirano v resolveNotificationLocale).
```

## KORAK 3.2 — prefer_not_to_say translation key + bad text visually shown (P3, hiter) ✅

**Kontekst:** ključ 'prefer_not_to_say' NE obstaja v translations.dart
(grep = 0), klican iz religion_step.dart in ethnicity_step.dart →
UI prikazuje surov ključ. Pa tudi je grdo zapisan in ni lep gumb. popravi izgled gumba in ga naredi enostavnega za klik pa da se ga lepo vidi in da paše v dizajn.

**CLI prompt:**
```
In lib/src/core/translations.dart add the missing key
'prefer_not_to_say' to EVERY locale block present in the file (verify
the number of locale blocks with grep before and after — counts must
match). EN: "Prefer not to say". SL: "Raje ne bi povedal/a". Other
locales: sensible translation or EN fallback.
flutter analyze 0 issues, flutter test green.
Branch feat/prefer-not-to-say-translation, Plan ID
20260712-fix-prefer-not-to-say-translation, PR with required phrases.
Evidence: grep -c "'prefer_not_to_say'" output pre/post.
```

**Output:**
```text
PR / merge datum:  PR #18 (github.com/MartinD111/Tremble-DatingApp/pull/18)
                    merged v main 2026-07-12.
Locale-i pokriti:   vseh 8 — en, sl, de, it, fr, hr, sr, hu.
                    Prevodi:
                      en → "Prefer not to say"
                      sl → "Raje ne bi povedal/a"
                      de → "Möchte ich nicht angeben"
                      it → "Preferisco non dirlo"
                      fr → "Je préfère ne pas dire"
                      hr → "Radije ne bih rekao/rekla"
                      sr → "Radije ne bih rekao/rekla"
                      hu → "Inkább nem mondom meg"
Grep evidence:      pre-edit  grep -c "'prefer_not_to_say'" = 0
                    post-edit grep -c "'prefer_not_to_say'" = 8
                    Locale-block count nespremenjen: 8 pred, 8 po.
Gumb (izgled):      OptionPill v religion_step.dart in ethnicity_step.dart
                    zdaj nosi `Icons.privacy_tip_outlined` na
                    prefer_not_to_say možnosti — pill je vizualno
                    poravnan z ostalimi (v religion so imele vse
                    možnosti ikono) in v ethnicity opt-out izstopa
                    kot zavesten "opt-out" izbor. Sam widget ni
                    spremenjen — hit-target ostane full-width,
                    16pt vertical padding (enostaven za klik).
Deploy target:      PROD (built v naslednji APK/TestFlight bundle,
                    ni potreben firebase deploy — Flutter strings only).
Verification:       dart format . (0 changed), flutter analyze
                    (0 issues), flutter test (221 tests green).
```

## KORAK 3.3 — Gym Mode: odstrani proximity gate na ročni aktivaciji ✅

**Kontekst (compliance report Del IV):** gym.functions.ts:66-70 zavrne
ročno aktivacijo, če uporabnik ni fizično v telovadnici — izniči smisel
ročne aktivacije. Aktivacija = izjava konteksta; zaznava = živ GPS/BLE.

**CLI prompt:**
```
In functions/src/modules/gym/gym.functions.ts (onGymModeActivate or
equivalent), remove the haversine distance gate that throws when
distance > radiusMeters on MANUAL activation. Keep lat/lng usage for
the first proximity iteration; keep the geofence dwell service as the
automatic-activation enhancement (unchanged). Update gym.test.ts:
manual activation from anywhere succeeds; dwell auto-activation
unchanged. CF build/lint/test green. Branch feat/gym-manual-activation-
no-gate, Plan ID 20260712-fix-gym-manual-activation, PR with required
phrases. Evidence: diff of removed gate + test output.
```

**Output:**
```text
PR / merge datum:  PR #19 (github.com/MartinD111/Tremble-DatingApp/pull/19)
                    merged v main 2026-07-12 21:56 UTC
                    (merge commit f48ff52, feature commit e470650).
Deploy target:      PROD (naslednji `firebase deploy --only
                    functions:onGymModeActivate` — samo CF sprememba,
                    Flutter build ni potreben; klientov contract
                    nespremenjen: lat/lng se še vedno pošiljata).
Founder approval:   ni zahtevan (risk_level: low — odstranitev
                    check-a, ne varnostne meje; Gym Mode je filter,
                    ne auth gate). Ročni merge (2026-07-12).
Odstranjeno:        - haversine() helper (dead code po odstranitvi gate).
                    - distance gate v onGymModeActivate (throw
                      "failed-precondition" pri distance > radiusMeters).
Ohranjeno:          - lat/lng v request payloadu (shape validation ostane;
                      klient nespremenjen).
                    - Geofence dwell service (avtomatska pot) — untouched.
                    - onGymModeDeactivate, expireGymSessions, RunMode
                      funkcije — untouched.
Testni dokaz:       functions/ Jest: 12 suites / 105 tests GREEN
                    (prej 100, +5 novih: manual iz Ljubljane proti Koper
                    gym uspe, inside-geofence uspe, unknown gymId →
                    not-found, missing lat/lng → invalid-argument,
                    missing auth → unauthenticated).
                    npm run build: 0 errors. npm run lint: 0 warnings.
Grep evidence:      `grep -rn "haversine" functions/src/modules/gym/`
                    → 0 hits post-merge.
CI:                 vseh required checks PASS pred ročnim mergeom.
```

## KORAK 3.4 — Hobby lokalizacija: jezikovno-nevtralni ID-ji ✅

**Kontekst:** hobby_data.dart uporablja display imena kot ključe →
mešan SL/EN prikaz IN matching bug ("Hiking" ≠ "Pohodništvo" za isti
hobi). To kvari compatibility scoring med uporabniki z različnimi
jeziki — ni kozmetika.

**CLI prompt:**
```
In the Tremble Flutter project, migrate hobbies to language-neutral IDs:
1. lib/.../hobby_data.dart: canonical list of stable hobby IDs
   (snake_case, e.g. hiking, board_games), each with a category.
2. Localization table: id → display name per locale (reuse
   translations.dart pattern or a dedicated map in hobby_data.dart —
   follow whichever pattern the file already leans toward).
3. Migration mapping on READ (parseHobbies): map legacy display-name
   values (both EN and SL variants) to IDs so existing profiles keep
   working without a Firestore migration.
4. Replace every hobby['name'] render with the localized lookup.
5. Verify matching/compatibility code compares IDs, not display text —
   grep for hobby comparisons in both lib/ and functions/src/ and fix
   any text-based comparison (the CF compatibility calculator likely
   compares raw strings; if so, add the same legacy mapping there).
Tests: parseHobbies legacy-name mapping (EN + SL inputs → same ID);
matching test where user A stored "Hiking" and user B "Pohodništvo" →
counts as shared hobby. All suites green (flutter + functions).
Branch feat/hobby-language-neutral-ids, Plan ID
20260713-hobby-neutral-ids, PR with required phrases.
Evidence: grep output showing no remaining display-name comparisons.
```

**Output:**
```text
PR / merge datum:  PR #20 (github.com/MartinD111/Tremble-DatingApp/pull/20)
                    → main 2026-07-13 (bo ročno merged; direct-to-prod
                    ker klientov contract nespremenjen in on-read
                    migracija ne zahteva Firestore backfill-a).
Deploy target:      PROD.
                    - Cloud Functions deploy (compatibility_calculator.ts
                      spremenjen) prek naslednjega `firebase deploy
                      --only functions` cikla. Vpliva na: matches,
                      proximity scoring (isti binarni izračun, samo
                      normaliziran).
                    - Flutter: vključeno v naslednji APK/TestFlight
                      bundle. Migracija je popolnoma on-read — starim
                      profilom se `hobbies: ["Hiking"]` normalizira v
                      `id: "hiking"` ob branju, brez migracije.
Legacy mapping testiran (da/ne): DA.
                    - Flutter (`test/core/hobby_utils_test.dart`, 16 testov):
                      "Hiking" (EN) → id="hiking",
                      "Pohodništvo" (SL) → id="hiking",
                      "hobby_running" (stari translation key) → id="running",
                      map input s samo "name" → obogaten s kanoničnim id,
                      map input s novim "id" → resolve prek predefined,
                      custom hobbi preservirani (custom=true, id=''),
                      neznane strine → custom entry brez crash-a,
                      locale display: EN → "Hiking", SL → "Pohodništvo",
                      HU (brez prevoda) → fallback na EN,
                      language-neutral (SUP/BJJ) → enak niz v vseh locales.
                    - Functions (`compatibility_calculator.test.ts`, 4
                      novi testi):
                      cross-locale EN+SL ["Hiking", "Cycling", "Yoga"]
                        vs ["Pohodništvo", "Kolesarjenje", "Joga"] →
                        score identičen s canonical-ID score,
                      mixed-locale profil (EN+SL v istem array) → tudi
                        pravilno normaliziran,
                      hobby_running (legacy key) → matcha z "running",
                      unknown/custom strini → NE cross-match z drugimi
                        unknowni.
Testni dokaz:       Flutter: 237 tests GREEN (prej 221, +16 novih).
                    `flutter analyze` 0 issues.
                    Functions: 12 suites / 109 tests GREEN (prej 105,
                    +4 nova). npm run build 0 errors, npm run lint 0
                    warnings.
Grep evidence:      - Vsi preostali `hobby['name']` klici v `lib/`
                      so write-path serializacije (auth_repository,
                      hobby_utils.toStorage) ali fallbacki za custom
                      hobije (hobby_categories, hobbies_step._isSelected).
                      Noben display site ne uporablja več `hobby['name']`
                      neposredno — vsi gredo skozi `HobbyData.hobbyDisplay(h, lang)`.
                    - V CF modulih (`functions/src/modules/**`) ni več
                      `CATEGORY_MAP` reference — zamenjano z
                      `ID_TO_CATEGORY` + `LEGACY_NAME_TO_ID`.
Kritični pattern:   on-read migracija (LEGACY_NAME_TO_ID) obstaja tako
                    na Flutter (HobbyData.idForLegacyName) kot CF
                    (normaliseHobbyId) — obe strani MORATA ostati
                    sinhronizirani, če kdo doda nov predefined hobby.
                    Če dodaš id-je, jih dodaj v OBA seznama.
```

## KORAK 3.5 — Event Mode: koordinate v Firestore

**Kontekst:** 3 ljubljanske lokacije hardcoded za _isDev — v produkciji
prazen zaslon (Apple 2.1 App Completeness tveganje).

**CLI prompt:**
```
Move Event Mode locations from hardcoded _eventLocations (+_isDev gate)
in tremble_map_screen.dart to Firestore `events` documents with a
`location` GeoPoint field. Client reads events from Firestore in all
flavors. Provide a seed script functions/src/scripts/seed_events.ts
(same safety pattern as existing migration scripts: --dry-run default,
--i-know-this-is-prod guard) that seeds the current 3 Ljubljana
locations. Do NOT run against prod. Firestore rules: events readable
by authenticated users, writable by no client. Tests green. Branch
feat/event-locations-firestore, Plan ID 20260713-event-locations-
firestore, PR with required phrases.
```

**Founder po merge:** zaženi seed na tremble-dev, preveri pine na mapi,
šele nato (z eksplicitno potrditvijo) na prod.

**Output:**
```text
PR / merge datum:
Seed izveden dev/prod (datuma):
```

## KORAK 3.6 — Registracijsko lokacijsko polje: prost tekst

**Kontekst:** KP/LJ/ZG selektor nima funkcije (ni v matchingu). Manj
podatka = GDPR minimizacija. Če Places API tu odpade in ni uporabljen
drugje, se poenostavi tudi DPA/PP.

**CLI prompt:**
```
Replace the KP/LJ/ZG/Other OptionPill selector in the registration
location step with a plain TextField (no Places API, no geocoding).
Grep the whole repo for remaining Places API usage and report whether
it can be removed from dependencies entirely (report only — removal of
the dependency is a separate decision). Tests green. Branch
feat/registration-location-freetext, Plan ID 20260713-registration-
location-freetext, PR with required phrases.
```

**Output:**
```text
PR / merge datum:
Places API še uporabljen drugje (da/ne, kje):
```

## KORAK 3.7 — 🧑‍⚖️ ODLOČITEV + 🤖 CODE: Paywall uskladitev

**Najprej founder odloči (ne CLI):** Pulse Intercept — Free ali Premium?
(Implementation plan Korak 21, Todoist 6h3pmrQ5wgFxRrCw.) Argumenta:
core-mechanic (Free, ker je del obljube "no chat, samo essentials") vs
monetizacija (Premium, ker je visok-value moment). Zapiši odločitev.

**Nato CLI prompt:**
```
Align the paywall with reality (compliance report Part V):
1. premium_screen.dart advertises "unlimited geofence pings" and
   "advanced filtering matrix" — grep the codebase for gates backing
   these. They do not exist: REMOVE both from the paywall copy (do not
   implement them).
2. Code gates "see who waved" and "near-miss recap" but the paywall
   does not mention them — ADD both, at the TOP of the feature list
   (strongest conversion triggers).
3. Implement the founder's Pulse Intercept tier decision: [VSTAVI
   ODLOČITEV] — gate or un-gate consistently in CF + Flutter.
4. Copy rules: EN + SL together, no forbidden phrases (revolutionary,
   seamless, game-changing, find love today, find your person, swipe,
   match queue, chat), no emoji in headlines, describe mechanics not
   emotions. Pricing may appear here (paywall is an allowed surface).
Tests green both suites. Branch feat/paywall-reality-alignment, Plan ID
20260714-paywall-alignment, PR with required phrases + risk_level: high
is NOT needed (no auth/billing logic change — RevenueCat wiring
untouched) unless you end up touching subscription CFs; if you do,
include it.
Evidence: table in PR body mapping each advertised feature → gate
file:line.
```

**Output:**
```text
Pulse Intercept odločitev:
PR / merge datum:
```

## KORAK 3.8 — Preostali znani drobci (batch, nizka prioriteta)

- Flaky GymStep test (photo_upload_registration_test.dart:467) —
  Todoist 6h4rqCpQ3jjg9vjw ima poln prompt.
- Info.plist podvojeni ključi + Contacts string (implementation plan
  Korak 7) — ČE ŠE NI narejen (preveri Output polje v implementation
  planu!). POZOR: Info.plist spremembe zahtevajo founder odobritev —
  CLI pripravi diff, founder ga aplicira.
- Heatmap realna geohash agregacija (implementation plan Korak 17) —
  velik kos, POST-LAUNCH razen če Apple reviewer zavrne zaradi prazne
  mape; mapa z event pini (3.5) verjetno zadošča za App Completeness.

**Output:**
```text
GymStep test stabiliziran (datum):
Korak 7 status:
Heatmap odločitev (pre/post launch):
```

---
**KONEC FAZE 3 — merila:** notifikacije vidne na obeh platformah (ročni
device test), UI brez surovih ključev, gym ročna aktivacija dela od
koderkoli, hobbiji enojezično dosledni in matching pravilen, event pini
vidni v produkciji, paywall oglašuje samo obstoječe.

---
## STATUS (posodobljeno 2026-07-12)

| Korak | Naslov                                                          | Status         | PR / merge                                    |
|-------|-----------------------------------------------------------------|----------------|-----------------------------------------------|
| 3.1   | CROSSING_PATHS vidna notifikacija (P1)                          | ✅ MERGED       | #17 → main 2026-07-12 (commit 7df1159)         |
| 3.2   | prefer_not_to_say translation key + gumb                        | ✅ MERGED       | #18 → main 2026-07-12                          |
| 3.3   | Gym Mode: odstrani proximity gate na ročni aktivaciji           | ✅ MERGED       | #19 → main 2026-07-12 (commit f48ff52)         |
| 3.4   | Hobby lokalizacija: jezikovno-nevtralni ID-ji                   | ✅ MERGED       | #20 → main 2026-07-13                          |
| 3.5   | Event Mode: koordinate v Firestore                              | ⬜ TODO         | —                                             |
| 3.6   | Registracijsko lokacijsko polje: prost tekst                    | ⬜ TODO         | —                                             |
| 3.7   | Paywall uskladitev (potreben founder odločitev pred CLI)        | ⬜ BLOCKED (founder odločitev za Pulse Intercept) | —      |
| 3.8   | Preostali drobci (batch)                                        | ⬜ TODO         | —                                             |

**Naslednji korak (predlog):** KORAK 3.5 — mape v prod, hitro odpre "Event Mode dela v Apple review" ustvarno tveganje; ali KORAK 3.6 — prost tekst za lokacijo (poenostavitev DPA/PP če Places API pade ven).

**Prod deploy dnevnik:**
- 2026-07-12 · KORAK 3.1 · Cloud Functions deploy na produkcijo predviden ročno prek `firebase deploy --only functions:scanProximityPairs` (founder odločitev: dev preskočen).
- 2026-07-12 · KORAK 3.2 · Flutter-only sprememba (translations + button icon) — vključena v naslednji APK/TestFlight bundle, brez CF deploya.
- 2026-07-12 · KORAK 3.3 · Cloud Functions deploy predviden ročno prek `firebase deploy --only functions:onGymModeActivate` (samo CF sprememba; klientov contract nespremenjen — Flutter bump ni potreben).
- 2026-07-13 · KORAK 3.4 · Cloud Functions deploy prek `firebase deploy --only functions` (compatibility_calculator.ts spremenjen — vpliva na matches + proximity scoring). Flutter: vključeno v naslednji APK/TestFlight bundle. On-read migracija — brez Firestore backfill-a.
