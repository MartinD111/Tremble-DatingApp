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
                    merged v main 2026-07-13 07:08 UTC
                    (merge commit a31e2b8, feature commit a3890e7).
                    Direct-to-prod pot — klientov contract nespremenjen
                    in on-read migracija ne zahteva Firestore backfill-a.
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

## KORAK 3.5 — Event Mode: koordinate v Firestore ✅

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
PR / merge datum:  PR #21 (github.com/MartinD111/Tremble-DatingApp/pull/21)
                    squash-merged v main 2026-07-13 (merge commit be2f9c7).
                    Feature commit: 149d101. Chore (backfill KORAK 3.4
                    merge details): fb12508. Docs (Output block prep):
                    b54d5dc.
Deploy target:      PRODUCTION (founder odločitev 2026-07-13 —
                    dev preskočen, popravek gre direktno v prod, isti
                    pattern kot KORAK 3.1).
                    - Cloud Functions: `firebase deploy --only
                      functions:onEventModeActivate --project
                      am---dating-app` uspešno izveden 2026-07-13.
                      Nova verzija sprejema GeoPoint IN legacy
                      {lat,lng} map (backward-compatible); klientov
                      contract nespremenjen.
                    - Flutter: vključeno v naslednji APK/TestFlight
                      bundle. Prod build bere `events` collection v
                      vseh flavors — hardcoded gate odstranjen.
Seed izveden dev/prod (datuma):  DEV preskočen (founder odločitev).
                    PROD seeded 2026-07-13 prek
                    `node ./lib/scripts/seed_events.js
                     --project=am---dating-app --i-know-this-is-prod
                     --apply`.
                    - Dry-run pred apply: OK (created=0 skipped=0,
                      3 documents pripravljeni — brez trkov z
                      obstoječimi).
                    - Apply: created=3 skipped=0.
                    - Ustvarjeni dokumenti (id, radius):
                        club_monokel  (150m)
                        labaratorij   (150m)
                        metelkova     (250m)
                    Skripta je idempotentna — če jo pozneje spet
                    zaženeš, bo preskočila obstoječe dokumente.
Firestore rules:    NE spremenjen — `match /events/{eventId}` je že
                    imel `read: signedIn(); write: false` pred
                    KORAK-om 3.5 (firestore.rules:197-200).
                    Seed script piše prek Admin SDK-ja (bypass rules).
Testni dokaz:       Flutter: 242 tests GREEN (prej 237, +5 novih v
                    `test/features/gym/tremble_event_from_firestore_test.dart`
                    — GeoPoint, legacy map, missing, malformed, name
                    fallback). `flutter analyze` 0 issues.
                    Functions: 13 suites / 114 tests GREEN (prej 109,
                    +5 novih v `events.test.ts` — GeoPoint accept,
                    legacy map accept, out-of-radius reject, unknown
                    eventId, inactive event). `npm run build` 0 errors,
                    `npm run lint` 0 warnings.
Grep evidence:      `grep -n "_eventLocations\|_events\s*=" lib/src/features/map/`
                    → 0 hits (hardcoded map + const list odstranjena);
                    `_isDev` ostane samo za dev proximity mock circles,
                    ne več za event render gate.
Backward compat:    `TrembleEvent.fromMap` (Flutter) IN
                    `onEventModeActivate` (CF) sprejemata OBOJE:
                    canonical GeoPoint (seed_events.ts piše to) IN
                    legacy `{lat, lng}` map (dev docs pred migracijo).
                    Če dodaš nov predefined event, ga dodaj v
                    `EVENTS` array v seed_events.ts z GeoPoint-om.
```

## KORAK 3.6 — Registracijsko lokacijsko polje: prost tekst ✅

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
PR / merge datum:  PR #23 (github.com/MartinD111/Tremble-DatingApp/pull/23)
                    squash-merged v main 2026-07-13 10:11 UTC
                    (merge commit ee48c69, feature commit 2cb0d5e,
                    docs glyph commit 7cab04e).
Deploy target:      PROD.
                    - Cloud Functions: naslednji `firebase deploy
                      --only functions` cikel bo posodobil
                      completeOnboarding + updateProfile Zod schema
                      (location z.enum → z.string.trim.min1.max80).
                      Klientov contract je backward-compatible —
                      legacy vrednosti ("Ljubljana"/"Koper"/"Zagreb"/
                      "Other") še vedno passajo, Firestore migracija
                      NI potrebna.
                    - Flutter: vključeno v naslednji APK/TestFlight
                      bundle. Freetext lokacija se pokaže v obeh
                      registracijskih flow-ih (email_location_step +
                      edit_profile_screen) v vseh flavors.
Places API še uporabljen drugje (da/ne, kje):
                    DA — `lib/src/features/gym/presentation/gym_search_widget.dart`
                    še vedno uporablja `lib/src/core/places_service.dart`
                    za gym autocomplete v Gym Mode. Ni pub package —
                    servis kliče Places API (New) direkt prek HTTP
                    z `PLACES_KEY_DEV` / `PLACES_KEY_PROD`
                    compile-time defines. V `pubspec.yaml` NI ničesar
                    za odstraniti; odstranitev bi bila mogoča šele,
                    ko / če Gym Mode preneha uporabljati gym search
                    (ločena odločitev, izven scope-a KORAK 3.6).
Testni dokaz:       Flutter: 242 tests GREEN (nespremenjen count —
                    obstoječi `registration_flow_test.dart` "profile
                    location input is freetext" test flipped v nov
                    contract). `flutter analyze` 0 issues.
                    Functions: 13 suites / 114 tests GREEN
                    (nespremenjen count — trije test bodies rewritten
                    v users.test.ts + auth.test.ts pod nov freetext
                    contract). `npm run build` 0 errors, `npm run
                    lint` 0 warnings.
Grep evidence:      - `grep -rn "profileLocationOptions" lib/ test/`
                      → samo tri negativne assertion-e v
                      `registration_flow_test.dart` (linije 261-263).
                      Const je izbrisan iz `step_shared.dart`, oba
                      screen-a ga več ne referencirata.
                    - `grep -rn "z.enum.*Ljubljana" functions/src/modules/`
                      → 0 hits (enum odstranjen iz obeh Zod schem).
                    - `grep -n "OptionPill" lib/src/features/auth/presentation/widgets/registration_steps/email_location_step.dart`
                      → 0 hits (OptionPill map zamenjan z
                      `_inputField` klicem).
Backward compat:    Firestore dokumenti z legacy enum vrednostmi
                    ("Ljubljana"/"Koper"/"Zagreb"/"Other") še vedno
                    pravilno parsajo skozi novo `z.string().trim()
                    .min(1).max(80)` schemo. `edit_profile_screen.dart`
                    NE overwritea več custom string-a (prej je
                    `profileLocationOptions.contains(...) ? ... :
                    'Other'` clamp zbrisala vsako non-enum vrednost
                    ob prvem edit-u — zdaj se ohrani).
```

## KORAK 3.7 — Tier Matrix alignment (multi-PR umbrella)

**Status change 2026-07-13:** originalno je bil 3.7 en majhen "paywall
copy fix". Founder je 2026-07-13 zapisal **celotni tier matrix** kot
source of truth v `tasks/decisions/ADR-007-tier-matrix.md` (glej ADR
za tabelo). 3.7 zdaj ni več copy fix — je umbrella za več PR-jev, ki
poravnajo kodo z ADR-007.

**Pulse Intercept odločitev (ADR-007):** **FREE v obeh variantah**
(Send Phone + Send Photo). Argumentacija: core-mechanic obljuba ("no
chat, samo essentials"). Monetizacija gre skozi širši radar + bogatejši
history.

**Audit posnetek 2026-07-13** (grep kode proti ADR-007 matrixu):

| Row | Trenutno stanje | Delta |
|---|---|---|
| Radar Radius 100/250 m | ✅ v `geo_service.dart` | none |
| Radar RSSI −75/−85 dBm | ⚠️ dokumentirano v `geo_service.dart:20-21`, treba verificirati BLE enforcement | verify |
| Proximity detekcija + notifikacija (Free) | ✅ `proximity.functions.ts` | none |
| Wave pošiljanje/prejemanje (Free) | ✅ | none |
| Mutual waves 5/20/mesec | ✅ `MUTUAL_WAVE_FREE_LIMIT=5` / `PREMIUM_LIMIT=20` v `matches.functions.ts:38-39` | verify enforcement path |
| Trembling Window 30-min active radar (Free) | ✅ (taste_of_premium translations) | verify |
| Pulse Intercept — Send Phone + Send Photo (Free) | ⚠️ audit `intercept.functions.ts` — ADR-007 zahteva Free obojno | audit + likely un-gate če je gated |
| History — Matches, prikaz profila (Omejen/Celoten) | ⚠️ audit `matches_screen.dart` | verify + implement Free clamp če manjka |
| History — Matches, odpiranje profil kartice (✗/✓) | ⚠️ audit | verify gate |
| History — Recaps, foto sivina/barvno | ⚠️ audit `run_recap_screen.dart` | verify color gate |
| History — Recaps, odpiranje profil kartice (✗/✓) | ⚠️ audit | verify gate |
| History — Recaps, 10-min TTL val (✗/✓) | ⚠️ audit | verify gate |
| History — Recaps, arhiv po TTL (read-only za Pro) | ⚠️ audit `viewed_recaps_repository.dart` | verify gate |
| Near-Miss History tab viden (✗/✓) | ⚠️ audit — `isNearMissProfile` obstaja v `matches_screen.dart:29` | verify tab gate |
| Near-Miss History odpiranje profil kartice (✗/✓) | ⚠️ audit | verify gate |
| Near-Miss upsell banner nearMissCount (Free ✓, Premium ✗) | ✅ `shouldShowNearMissUpsell` v `matches_screen.dart:40` — pravilno gated na `!isPremium` | none |
| Filtri — osnovno (spol, starost) (Free) | ✅ | none |
| Filtri — Nicotine exclusion (Free) | ✅ (v nicotine_step) | none |
| Filtri — ostali hard filtri (Premium) | ⚠️ audit filter surfaces | verify Premium gate |
| Map — event pini (Free obojno) | ✅ `tremble_map_screen.dart` (po KORAK 3.5) | none |
| Map — število udeležencev na eventu (Premium) | ⚠️ audit `event_pin_sheet.dart` | verify gate |
| Map — heatmap indikator na event pinu (Premium) | ✅ `event_pin_sheet.dart:158` gated na `heatmap_locked` | verify Free path |
| Map — heatmap krogi (Free brez podatkov / Premium s podatki) | ⚠️ audit map heatmap layer | verify + likely add Free empty-circle path |
| Nastavitve — max distance slider 50/100 km | ⚠️ audit `preference_range_slider.dart` | verify tier bounds |
| Paywall copy (`premium_screen.dart`) | ❌ oglašuje "unlimited geofence pings" + "advanced filtering matrix" ki NE obstajata; ne omenja mutual-wave limita, radar radius/RSSI, recap colors, near-miss history, hard filtrov, event participants, heatmap indikatorja, distance slider — kompletno stran od ADR-007 | **wholesale rewrite** |

**Naslednji koraki so razdelijo na več PR-jev** — vsak zapre eno vrsto
ADR-007 matrixa in ima svoj Plan ID + branch. Vrstni red je predlog;
founder izbere.

### 3.7a — Paywall copy rewrite (Flutter only, LOW risk) — ✅ MERGED 2026-07-13
Prepiši `premiumPlanCards.features` v `premium_screen.dart` točno po
ADR-007 tabeli. Odstrani štiri neveljavne feature ključe (`wider_radar`
kot "50% wider" — matrix pravi 100/250 m, ne %; `unlimited_geofence` —
ne obstaja; `custom_themes` — ne obstaja; `advanced_filters` — matrix
pravi "hard filtri", ne "matrix"). Doda: mutual waves 20/mo, radar 250
m + RSSI −85 dBm, recap barvno + TTL + arhiv, match profile card
open, near-miss tab + card, hard filtri, event participants count,
heatmap indikator + data, distance slider 100 km. Copy pravila
(ADR-007 §3): EN + SL, no forbidden phrases, no emoji v headlinih,
mechanics ne emotions. **Ne dodaja gate-ov, samo copy.** Plan ID:
20260713-paywall-copy-rewrite. Branch: feat/paywall-copy-rewrite.

### 3.7b — Feature-parity audit report (research, no code) — ✅ MERGED 2026-07-13
Za vsak ⚠️ v audit tabeli zgoraj naredi grep + izpiši dejansko stanje
gate-a (server-side enforcement da/ne, client-side check da/ne).
Rezultat: `tasks/AUDIT_TIER_MATRIX_20260713.md` z ordered fix list.
Iz te liste izvirajo 3.7c-3.7n PR-ji. Founder pregleda pred kodiranjem.

**Output (3.7b):**
```text
Audit PR:           PR #26 (docs plan-03-korak-3-7a-merged prep) +
                    PR #27 (research/tier-matrix-audit-3-7b)
                    → main 2026-07-13 15:47 UTC (merge commit f2842bb).
                    Ključni feature commit: 2612958 (audit report),
                    plus ADR-007 Amendments §1-§6 (b521de3, c392ad3,
                    ae0c19a).
Deliverable:        tasks/AUDIT_TIER_MATRIX_20260713.md — 429 vrstic,
                    verdict-tag na vsaki ADR-007 vrstici (OK / PARTIAL
                    / MISSING / N/A) + ordered fix list.
ADR-007 Amendments: §1 matches three-state render (grey / colour+3-hobbies
                    / colour+full-card) — greyscaled fallback za no-mutual-wave.
                    §2 hard filtri paused post-launch — paywall bullet
                    ostane, doda se "coming soon" suffix v vseh locales.
                    §3 heatmap in event tier razbit v 3.7c-3, 3.7c-4a,
                    3.7c-4b (chip + per-filter subset count).
                    §5 max distance slider vrstica UMAKNJENA — nikoli ni
                    obstajala kot widget; paywall bullete odstranit.
                    §6 hard-filters "coming soon" localizacija v 8 locales.
P1 ambiguity:       vsi trije P1 items RESOLVED (matches shape, hard
                    filtri, heatmap/event tiers).
Fix list vrstni red: P1 gates (3.7c-1, 3.7c-3, 3.7c-4a, 3.7c-4b) →
                    P2 quick wins (bundle 3.7c-5R + 3.7c-2C) →
                    P3 pair-of-tests (3.7c-6..11) → P4 deferred
                    (3.7c-rssi-threshold-tier, blocked na ADR-001) →
                    3.7z integration matrix.
Deploy target:      N/A (docs-only, no CF/Flutter change).
```

### 3.7c-3.7n — Individual gate fixes (izvirajo iz 3.7b) — 🟡 IN PROGRESS
Vsak gate = svoj PR (Plan ID 20260713-tier-<row-slug>, branch
feat/tier-<row-slug>). Vsak PR mora priložiti pair-of-tests (Free hit
gate + Premium bypass gate) kot je zahtevano v ADR-007 §4.

### 3.7c-5R + 3.7c-2C (bundled) — Distance retire + hard-filters coming-soon — ✅ MERGE-READY 2026-07-13
Plan ID: `20260713-distance-remove-and-hardfilters-comingsoon`
Branch: `feat/tier-3-7c-5R-and-3-7c-2C`
PR: #28

**Output (bundle):**
```text
Ships:              ADR-007 Amendment §5 (distance row retired,
                    zero widget backing) + Amendment §6 (hard-filters
                    "coming soon" localised across all 8 paywall
                    locales — en, sl, de, hr, it, es, fr, pt).
Bonus cleanup:      translations.dart orphan `distance_help` key
                    surfaced during pre-flight (0 callers in lib/,
                    fossil from the never-built distance slider) —
                    removed from all 8 locale blocks. Locale-block
                    count unchanged (8 → 8).
Files touched:      lib/src/features/settings/presentation/premium_screen.dart
                    lib/src/core/translations.dart
                    test/features/settings/premium_screen_test.dart
                    tasks/plan.md (Plan-ID rewrite)
                    tasks/plans/PLAN_03_APP_CODE.md (this file)
Test evidence:      Flutter 249 tests GREEN (prev 247, +2 new
                    hard-filter locale coverage tests). flutter
                    analyze 0 issues.
Bullet count diff:  premiumOnlyFeatureBullets 8 → 7 items.
                    freeTierFeatureBullets 7 → 6 items.
Deploy target:      PROD via next APK/TestFlight bundle. No Cloud
                    Functions deploy needed (copy-only). No Firestore
                    migration (no user-facing DB change).
Risk assessment:    LOW — copy-only, no gate logic, no server contract
                    change. False-advertisement risk goes DOWN.
```

### 3.7c-1 — Matches three-state mutual-wave render pipeline — 🟨 OPEN 2026-07-13
Plan ID: `20260713-matches-three-state-mutual-wave`
Branch: `feat/tier-3-7c-1-matches-three-state`
PR: #29

**Output (3.7c-1):**
```text
Ships:              ADR-007 Amendment §1 compound gate
                    `isPremium && hasMutualWave` on Matches list.
                    Neither condition alone unlocks the full card.
Three-state:        A. non-mutual (both tiers) → greyscaled photo +
                       name + age, no tap-open.
                    B. mutual + Free → colour + name + age, tap =
                       paywall upsell.
                    C. mutual + Premium → colour + name + age, tap
                       opens full profile card.
Server:             getMatches emits hasMutualWave: bool per profile
                    (Object.keys(gestures ?? {}).length >= 2). No
                    schema, no migration. Older APKs default to
                    non-mutual — safe.
Client DTO:         MatchProfile + fromApi gain hasMutualWave (default
                    false, backward-compat with mock data + tests).
Widget helper:      resolveMatchDisplayState() enum-returning pure
                    function isolates the compound gate for testing.
Mock data:          Nika/Sara = mutual, Luka = non-mutual → Admin
                    Bypass shows all three states visibly.
UX replacement:     Old isLocked "Someone sent you a wave" placeholder
                    + "Upgrade to see" pill REPLACED by §1 non-mutual
                    render (real name + age + greyscaled photo).
                    Founder decision 2026-07-13.
Test evidence:      Flutter 259 tests GREEN (+10 new in
                    matches_three_state_test.dart). functions npm
                    test 117 GREEN (+3 new pair-of-tests in
                    matches.test.ts `ADR-007 §1 hasMutualWave
                    contract` describe block). flutter analyze 0
                    issues. npm build + lint clean.
Deploy target:      PROD via `firebase deploy --only
                    functions:getMatches --project am---dating-app`
                    + next APK/TestFlight bundle. Additive CF change
                    is backward-compatible for older clients.
Scope confined:     Matches list only. Recap card + Near-Miss card
                    three-state → separate follow-ups (3.7c-10,
                    3.7c-11). Free-mutual preview card with 3
                    shared hobbies → separate small copy PR.
```

### 3.7c-3 Slice A — Event pin sheet tier gate pair-of-tests — ✅ MERGED 2026-07-13
Plan ID: `20260713-event-pin-sheet-tier-gate-tests`
Branch: `feat/tier-3-7c-3-event-pin-sheet-tests`
PR: #30

**Output (3.7c-3 Slice A):**
```text
Ships:              ADR-007 §4 pair-of-tests for the two existing
                    tier gates on event_pin_sheet.dart (participant
                    count row + heatmap indicator row). Zero
                    behaviour change — regression net only.
Verified by read:   Both gates already match ADR-007 §3 today:
                    - Line 138-149: effectiveIsPremium ternary
                      _PeopleCountRow vs _LockedFeatureRow with
                      pro_feature_locked pill.
                    - Line 152-160: effectiveIsPremium ternary
                      _HeatmapActiveRow ("LIVE") vs _LockedFeatureRow
                      with heatmap_locked pill.
Tests added:        4× pair-of-tests in
                    test/features/map/event_pin_sheet_tier_gates_test.dart:
                    Free-count-locked, Premium-count-visible,
                    Free-heatmap-locked, Premium-heatmap-visible.
Slice B deferred:   Potential-matches count for Premium (subset of
                    participants fitting caller's filter prefs, per
                    ADR-007 §3) → will bundle with 3.7c-4b (owns
                    per-filter subset CF endpoint). Design pending.
Test evidence:      Flutter 263 tests GREEN (prev 259, +4 new).
                    flutter analyze 0 issues.
Deploy target:      No deploy needed (test-only PR).
```

**Preostali fix wave (per audit report):**
- P1 code slices remaining: 3.7c-4a (heatmap count chip on circles),
  3.7c-4b (CF endpoint za per-filter subset count + bundle Slice B
  potential-matches count za event pin sheet).
- P3 pair-of-tests batch: 3.7c-6..11.
- P4 deferred: 3.7c-rssi-threshold-tier (blocked na ADR-001).

### 3.7z — Consistency test suite (integracija, MEDIUM risk) — **ZADNJI**
Ko so 3.7a-3.7n zaključeni, dodaj integrations test ki za vsak ADR-007
row assertira dvojico (Free-behavior + Premium-behavior). To zapre
regression window za bodoče spremembe.

**CLI prompt za 3.7a (edini takoj izvedljiv brez audit-a):**
```
Rewrite lib/src/features/settings/presentation/premium_screen.dart
paywall copy in accordance with tasks/decisions/ADR-007-tier-matrix.md.
Do NOT add or change any gate logic — copy-only change. Steps:
1. Read ADR-007 (do NOT paraphrase — match its wording).
2. Delete these feature keys from every card (Weekend, Premium,
   Yearly, Lifetime cards): premium_feature_wider_radar,
   premium_feature_unlimited_geofence, premium_feature_custom_themes,
   premium_feature_advanced_filters.
3. Replace with the ADR-007-derived feature bullets, ordered by
   conversion strength (per founder judgement): mutual waves 20/mo,
   radar 250 m + RSSI −85 dBm sensitivity, match profile card
   openable, recap in color + 10-min TTL wave + archive read-only,
   near-miss history tab + card, hard filters unlocked, event
   participants count + heatmap indicator, max distance up to 100 km.
   Free card lists what stays free: proximity detection + notification,
   wave send/receive, Pulse Intercept (Phone + Photo), 30-min active
   radar, event pins, empty heatmap circles, nicotine exclusion, mutual
   waves 5/mo, distance up to 50 km.
4. Add EN + SL translations for every new key. Copy rules (ADR-007 §3):
   no forbidden phrases (revolutionary, seamless, game-changing, find
   love today, find your person, swipe, match queue, chat), no emoji
   in headlines, describe mechanics not emotions.
5. Tests: existing premium_screen widget tests must still pass (adjust
   assertions for the new copy). Add a new test that asserts the
   premium card lists exactly the ADR-007 Premium-only features.
Constraints: flutter analyze 0 issues, flutter test green.
Branch: feat/paywall-copy-rewrite
Plan ID: 20260713-paywall-copy-rewrite
Risk level: low (copy only, no gate logic).
PR body: literal phrases Verification checklist, unit tests,
integration tests, security scan.
```

**Output:**
```text
ADR:                tasks/decisions/ADR-007-tier-matrix.md (accepted 2026-07-13)
Pulse Intercept odločitev: FREE (Phone + Photo obojno; core-mechanic obljuba)
3.7a PR / merge:    PR #25 (github.com/MartinD111/Tremble-DatingApp/pull/25)
                    merged v main 2026-07-13 12:13 UTC
                    (merge commit 0cd8b4c, feature commit 03a6afc,
                    conflict-resolution merge 6911ad8).
                    Retired feature keys (7): premium_feature_wider_radar,
                    premium_feature_unlimited_geofence, premium_feature_
                    custom_themes, premium_feature_advanced_filters,
                    premium_free_gym_mode, premium_free_local_radar,
                    premium_free_wave_limit.
                    Novi feature keys (15): 8× premium_feature_*
                    (radar_extended, mutual_waves_20, open_profile_cards,
                    recap_full, near_miss_history, hard_filters,
                    event_insights, distance_100) + 7× premium_free_*
                    (proximity, pulse_intercept, active_radar,
                    mutual_waves_5, event_pins, nicotine_filter,
                    distance_50). EN + SL translation blocks vsi
                    prepisani; de/hr/it/es/fr/pt še vedno fallback na
                    EN za feature bullets (nespremenjeno, ločen
                    translation task).
                    Contract testi v premium_screen_test.dart (4 novi):
                    Premium card = točen ordered ADR-007 set;
                    Weekend card = Premium + weekend suffix;
                    Free card = točen ordered ADR-007 set;
                    retired keys fizično odsotni iz datoteke;
                    ADR-007 §3 copy pravila (regex nad translation
                    values samo — scoped da internal code komentarji
                    ne false-positive-jajo).
                    Testni dokaz: Flutter 247 tests GREEN (prej 242,
                    +5 novih). flutter analyze 0 issues.
                    Deploy target: PROD, v naslednji APK/TestFlight
                    bundle. Ni CF deploya (copy-only).
                    Lessons naučene med izvedbo: PR #24 (docs za 3.6)
                    in PR #25 sta oba na začetku propadla MPC PR-
                    Metadata gate (title brez [PLAN-ID: …] + body
                    brez štirih zahtevanih fraz) — dodano kot Rule #80
                    v tasks/lessons.md. Poleg tega je PR #25 body
                    vseboval literal `risk_level: high` (v negaciji
                    "NOT needed") kar CI regex ujame naivno in prižge
                    ⑦ Founder Approval gate — nikoli več v telesu PR-
                    ja, celo v negaciji.
3.7b audit report path:  tasks/AUDIT_TIER_MATRIX_20260713.md ✅ landed 2026-07-13 (PR #27, f2842bb)
3.7c-3.7n PRs:      🟡 IN PROGRESS — next slice is bundled 3.7c-5R + 3.7c-2C
3.7z integration tests PR: TBD after 3.7c-3.7n done
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
## KORAK 3.9 — Session 2026-07-14 audit follow-up (P1 — process + ship-gate lane)

Session 2026-07-14 je razkril, da je 5 od 8 "živih" p1/p3 tasks v
PLAN_00 §Todoist že MERGEAN (PR #14 CI injection, PR #13 stopBilling,
PR #17 CROSSING_PATHS, PR #18 prefer_not_to_say + KORAK 3.8-2 flaky
GymStep test = cannot repro 43/43). PLAN_00 in `~/.claude/CLAUDE.md`
"active blockers" sekciji NISO POSODOBLJENI in vsaka nova CLI seja
ponovno zapravi ~1h ure odkrivanjem istih zaključenih ticket-ov.
Naslednji 4 podnalog naslavljajo (1) sam problem stale intel-a in
(2) tri prave preostale ship-blockerje na code-side.

### KORAK 3.9-1 — Stale-intel audit docs PR (P1 — process hygiene)

**Cilj:** Uskladi `tasks/plans/PLAN_00_MASTER_INDEX.md` §"Pokvarjeno /
odprto" in §"Todoist živi taski" z dejanskim stanjem `main` po session
2026-07-14. Doda Rule #83 v `tasks/lessons.md`. Predlaga diff za
`~/.claude/CLAUDE.md` active-blocker sekcijo (globalna datoteka —
founder aplicira).

**Scope:**
- `tasks/plans/PLAN_00_MASTER_INDEX.md` — odstrani zaključene alineje;
  posodobi Todoist seznam (5 → 3 live task).
- `tasks/lessons.md` — Rule #83: "Verify handoff intel against `git
  log` + `gh pr list` pred kot cutнeš fix branch."
- `tasks/plan.md` — Plan-ID rewrite.
- `~/.claude/CLAUDE.md` (globalna) — CLI pripravi diff, founder aplicira.

**Risk:** LOW · Founder approval: NO · Branch: `docs/stale-intel-audit-20260714`
**Plan-ID:** `20260714-stale-intel-audit-docs`

**Output:**
```text
PR#:               (fill after opening)
Merge commit:
Rule #83 landed:
CLAUDE.md diff proposed (path/patch):
```

### KORAK 3.9-2 — iOS submission-readiness audit (Rule #82 3-surface check)

**Cilj:** Verificira, da so PR #32 (Info.plist Contacts reconcile) +
PrivacyInfo.xcprivacy + `en.lproj/InfoPlist.strings` skupaj resnično
submission-ready proti Rule #82 3-surface protokolu:
(a) master `Info.plist` ↔ localized `en.lproj/InfoPlist.strings`
    divergence sweep za VSE `NS*UsageDescription` ključe (ne samo
    Contacts).
(b) duplicate permission-key sweep prek `plutil -lint` +
    `grep -c "<key>NS.*UsageDescription</key>"` za vsak ključ.
(c) `PrivacyInfo.xcprivacy` — NSPrivacyAccessedAPITypes derived-data
    completeness (User Defaults, File Timestamp, System Boot Time,
    Disk Space) + NSPrivacyCollectedDataTypes coverage za VSA
    Firebase/R2/Redis polja, ne samo Contacts.

**Scope:**
- `ios/Runner/Info.plist` (read-only sweep prek plutil + grep)
- `ios/Runner/en.lproj/InfoPlist.strings` (read-only)
- `ios/Runner/PrivacyInfo.xcprivacy` (read-only unless gap found)
- `tasks/blockers.md` — posodobi BLOCKER-STORE-001 status
- `tasks/plan.md` — Plan-ID rewrite

**Risk:** LOW če audit vrne clean; MEDIUM če najde gap (Info.plist
edits zahtevajo founder odobritev per PLAN_00 native-config rule).
**Founder approval:** NO za samo audit poročilo; YES če gap zahteva
edit.
**Branch:** `docs/ios-submission-audit-20260714`
**Plan-ID:** `20260714-ios-submission-audit`

**Output:**
```text
PR#:               (fill after opening)
Merge commit:      (fill after merge)
Audit result:      CLEAN — Rule #82 3-surface sweep passed 2026-07-14.
                   (a) master↔localized: 7/7 present keys byte-identical.
                   (b) duplicate sweep: every NS*UsageDescription = 1.
                   (c) PrivacyInfo.xcprivacy: all 4 Required Reasons
                       API categories (UserDefaults CA92.1,
                       FileTimestamp C617.1, SystemBootTime 35F9.1,
                       DiskSpace E174.1) + 10 collected data types
                       incl. hashed Contacts (ADR-004, Linked=false).
                   Encryption declaration ITSAppUsesNonExemptEncryption=false present.
                   BLOCKER-STORE-001 closed with evidence in tasks/blockers.md.
Gap details:       Non-blocker follow-up only — sl.lproj + hr.lproj
                   do not localize NSCameraUsageDescription /
                   NSPhotoLibraryUsageDescription /
                   NSPhotoLibraryAddUsageDescription. iOS falls back
                   to master EN string → no divergence, no submission
                   risk. Recorded in blockers.md STORE-001 follow-up
                   for a future translation sprint pre-EU launch.
```

### KORAK 3.9-3 — Paywall accuracy sync (BLOCKER-LEGAL-005 → App Store 3.1.2)

**Cilj:** `lib/src/features/settings/presentation/premium_screen.dart`
oglašuje feature-e, ki jih ni v kodi, in skriva feature-e, ki so
gated. To je App Store 3.1.2 zavrnitveno tveganje + potrošniška
zaščita per BLOCKER-LEGAL-005. Uskladi paywall bulleti z dejansko
backend gate logiko (compound gates iz KORAK 3.7c-1: `hasMutualWave`,
`effectiveIsPremium`, weekend pass window, itd.).

**Scope:**
- `lib/src/features/settings/presentation/premium_screen.dart` —
  copy sync z realno gate logiko.
- `lib/src/core/translations.dart` — nova/spremenjena copy v EN + SL
  (+ ostalih 6 locales fallback).
- `test/features/settings/premium_screen_test.dart` — regression
  testi za vsak paywall bullet ↔ backend gate.
- `tasks/blockers.md` — zapri BLOCKER-LEGAL-005.
- `tasks/plan.md` — Plan-ID rewrite.

**Risk:** MEDIUM — paywall je user-facing + billing-adjacent; HIGH če
sprememba zadeva RevenueCat entitlement mapping. Test coverage MUST
verificirati vsak bullet ↔ code gate.
**Founder approval:** YES (billing-adjacent per MPC).
**Branch:** `fix/paywall-accuracy-sync`
**Plan-ID:** `20260714-paywall-accuracy-sync`

**Output:**
```text
PR#:               (fill after opening)
Bullete spremenjeni:
RevenueCat mapping touched (yes/no):
BLOCKER-LEGAL-005 closed:
```

### KORAK 3.9-4 — Brand-voice review Prominent Disclosure copy (BLOCKER-STORE-003 companion)

**Cilj:** 4 nove Prominent Disclosure translation ključe (EN + SL)
uvedene v PR #7 (2026-07-07) skozi `brand-voice-agent` skill. Trenutna
copy je spec-verbatim in ni šla skozi brand review; blokira Play
Console submission per BLOCKER-STORE-003.

**Scope:**
- Read: `lib/src/features/auth/presentation/prominent_disclosure_screen.dart`
- Read: `lib/src/core/translations.dart` — 4 ključi:
  `disclosure_bg_location_headline`, `disclosure_bg_location_body`,
  `disclosure_bg_location_cta_allow`, `disclosure_bg_location_cta_not_now`.
- Modify: `lib/src/core/translations.dart` s pregledano copy (EN + SL).
- Test: obstoječi `test/features/auth/prominent_disclosure_screen_test.dart`
  posodobi za novo copy (pins string content).
- `tasks/blockers.md` — posodobi BLOCKER-STORE-003 progress.
- `tasks/plan.md` — Plan-ID rewrite.

**Risk:** LOW — copy only, no gate logic, no native config.
**Founder approval:** NO (copy review is delegable). Founder Martin
lahko final review copy pred Play submission.
**Branch:** `feat/brand-voice-prominent-disclosure`
**Plan-ID:** `20260714-brand-voice-prominent-disclosure`

**Output:**
```text
PR#:               (fill after opening)
Copy revidirana (EN + SL):
BLOCKER-STORE-003 progress:
```

---
**KONEC FAZE 3 — merila:** notifikacije vidne na obeh platformah (ročni
device test), UI brez surovih ključev, gym ročna aktivacija dela od
koderkoli, hobbiji enojezično dosledni in matching pravilen, event pini
vidni v produkciji, paywall oglašuje samo obstoječe.

---
## STATUS (posodobljeno 2026-07-13)

| Korak | Naslov                                                          | Status         | PR / merge                                    |
|-------|-----------------------------------------------------------------|----------------|-----------------------------------------------|
| 3.1   | CROSSING_PATHS vidna notifikacija (P1)                          | ✅ MERGED       | #17 → main 2026-07-12 (commit 7df1159)         |
| 3.2   | prefer_not_to_say translation key + gumb                        | ✅ MERGED       | #18 → main 2026-07-12                          |
| 3.3   | Gym Mode: odstrani proximity gate na ročni aktivaciji           | ✅ MERGED       | #19 → main 2026-07-12 (commit f48ff52)         |
| 3.4   | Hobby lokalizacija: jezikovno-nevtralni ID-ji                   | ✅ MERGED       | #20 → main 2026-07-13 (commit a31e2b8)         |
| 3.5   | Event Mode: koordinate v Firestore                              | ✅ MERGED       | #21 → main 2026-07-13 (commit be2f9c7, prod seeded 3/3) |
| 3.6   | Registracijsko lokacijsko polje: prost tekst                    | ✅ MERGED       | #23 → main 2026-07-13 (commit ee48c69)         |
| 3.7   | Tier Matrix alignment (ADR-007 umbrella — več PR-jev)           | 🟢 SHIP-READY (see ship-path note below) — 3.7a ✅, 3.7b ✅, 3.7c-5R+2C ✅, 3.7c-1 ✅, 3.7c-3-A ✅ | 3.7a: #25 · 3.7b: #26+#27 · 3.7c-5R+2C: #28 · 3.7c-1: #29 · 3.7c-3-A: #30 |
| 3.8   | Preostali drobci (batch)                                        | 🟨 IN PROGRESS — 3.8-1 ✅ merged, 3.8-2 pending | 3.8-1: PR #32 → main 2026-07-13 (commit 184f951, 0dfb672); 3.8-2 flaky GymStep test pending |

**Naslednji korak (SHIP-PIVOT 2026-07-13):** KORAK 3.7 substancialno zaključen — PR #25 / #26+#27 / #28 / #29 / #30 vsi merged. Vse core paywall in matches-list gate spremembe iz ADR-007 §1–§6 so v prod-pripravljenem stanju. Preostali 3.7c-* work je **deferrable in NE blokira launcha**:

- **3.7c-4a** (heatmap count chip Premium-only) — potrebuje UX design decision + majhen widget; ni Apple/Play review blocker.
- **3.7c-4b + 3.7c-3 Slice B** (per-filter subset CF endpoint za heatmap circle subset in event pin potential-matches count) — potrebuje Firestore schema design + aggregate cost budget; velik kos, "design pending" per audit — ni ship-critical.
- **3.7c-6..11** (dodatni pair-of-tests batch) — regression net; koristno, ni ship blocker.
- **3.7z** (integration matrix) — regression net; koristno, ni ship blocker.
- **3.7c-rssi-threshold-tier** — blocked na ADR-001 (BLE mock).

**Zato: naslednji korak za ship je KORAK 3.8 (ship-critical drobci), potem PLAN_04 (Legal + Play Console) → PLAN_05 (final build + BLE matrix test + submission).**

Ship-critical KORAK 3.8 podnaloge (per `tasks/blockers.md`):
1. ~~**Info.plist Contacts contradiction** (BLOCKER-STORE-002) — Apple 5.1.1 rejection risk.~~ ✅ **DONE 2026-07-13** — PR `fix/info-plist-contacts-reconcile`. Master `NSContactsUsageDescription` string zdaj natančno opisuje Anonymity Mode (ADR-004); 3 podvojeni permission keys odstranjeni (NSCamera, NSPhotoLibrary, NSPhotoLibraryAdd); `PrivacyInfo.xcprivacy` deklarira `NSPrivacyCollectedDataTypeContacts` (Linked=false per ADR-004 hash-only transmission). **Preostalo**: PLAN_04 KORAK 4.2 založnik posodobi `trembledating.com/privacy` §2.5 spletno stran — pred App Store submissionom.
2. **Flaky GymStep test** (Todoist 6h4rqCpQ3jjg9vjw) — `test/features/auth/photo_upload_registration_test.dart:467`. Nizka prioriteta, ampak zmanjša CI noise pred final build push.
3. **Heatmap realna geohash agregacija** — POST-LAUNCH razen če Apple reviewer specifično zavrne prazno mapo; mapa z event pini iz KORAK 3.5 verjetno zadošča za App Completeness.

Vzporedno se lahko začne **PLAN_04 KORAK 4.1** (🧑‍⚖️ FOUNDER only — Play Console background location deklaracija, 2-4 tedne review) — CLI ne more izvesti, ampak lahko pripravi brand-voice pregled 4 novih stringov in preveri je Prominent Disclosure branch merged.

**Prod deploy dnevnik:**
- 2026-07-12 · KORAK 3.1 · Cloud Functions deploy na produkcijo predviden ročno prek `firebase deploy --only functions:scanProximityPairs` (founder odločitev: dev preskočen).
- 2026-07-12 · KORAK 3.2 · Flutter-only sprememba (translations + button icon) — vključena v naslednji APK/TestFlight bundle, brez CF deploya.
- 2026-07-12 · KORAK 3.3 · Cloud Functions deploy predviden ročno prek `firebase deploy --only functions:onGymModeActivate` (samo CF sprememba; klientov contract nespremenjen — Flutter bump ni potreben).
- 2026-07-13 · KORAK 3.4 · Cloud Functions deploy prek `firebase deploy --only functions` (compatibility_calculator.ts spremenjen — vpliva na matches + proximity scoring). Flutter: vključeno v naslednji APK/TestFlight bundle. On-read migracija — brez Firestore backfill-a.
- 2026-07-13 · KORAK 3.5 · PR #21 merged v main (be2f9c7). Cloud Function `onEventModeActivate` deployan direktno na prod (`firebase deploy --only functions:onEventModeActivate --project am---dating-app`) — dev preskočen (founder odločitev, isti pattern kot KORAK 3.1). Prod events collection seeded s 3 dokumenti (club_monokel, labaratorij, metelkova) prek `seed_events.js --project=am---dating-app --i-know-this-is-prod --apply`. Flutter build vključen v naslednji APK/TestFlight bundle.
- 2026-07-13 · KORAK 3.6 · PR #23 merged v main (ee48c69). Cloud Functions deploy predviden prek naslednjega `firebase deploy --only functions` cikla (posodobi Zod schemo za `completeOnboarding` + `updateProfile` — `location` polje iz `z.enum` v `z.string().trim().min(1).max(80)`). Klientov contract je backward-compatible — legacy enum vrednosti ("Ljubljana"/"Koper"/"Zagreb"/"Other") še vedno passajo, Firestore migracija NI potrebna. Flutter: vključeno v naslednji APK/TestFlight bundle — freetext lokacijsko polje v obeh flow-ih (registracija + edit profile). Places API ostaja aktiven za Gym Mode gym autocomplete (raw HTTP + PLACES_KEY_DEV/PROD compile-time defines; odstranitev iz `pubspec.yaml` ni relevantna ker ni pub package).
- 2026-07-13 · KORAK 3.7a · PR #25 merged v main (0cd8b4c). Paywall copy prepisan po ADR-007 tabeli — 7 retired feature ključev odstranjenih, 15 novih dodanih (EN + SL). Flutter-only: vključeno v naslednji APK/TestFlight bundle. Brez CF deploya (copy-only, no gate logic change). Naslednji sub-KORAK je 3.7b (feature-parity audit — research only). Tudi ADR-007 (`tasks/decisions/ADR-007-tier-matrix.md`) landeal na main prek PR #24 (0da6da9) — služi kot single source of truth za vse bodoče per-gate PR-je.
- 2026-07-13 · KORAK 3.7b · PR #26 (docs plan-03 update) + PR #27 (research/tier-matrix-audit-3-7b) merged v main (f2842bb). Docs-only, no deploy. Deliverable: `tasks/AUDIT_TIER_MATRIX_20260713.md` (429 vrstic) + ADR-007 Amendments §1-§6 (matches three-state render, hard filtri pause + coming-soon localizacija, heatmap/event tier split v 3.7c-3/4a/4b, distance vrstica UMAKNJENA, greyscaled fallback za no-mutual-wave). Fix wave vrstni red potrjen: P1 code slices (3.7c-1/3/4a/4b) → P2 quick wins (bundle 3.7c-5R + 3.7c-2C) → P3 pair-of-tests (3.7c-6..11) → P4 deferred (RSSI) → 3.7z integration matrix.
- 2026-07-13 · KORAK 3.7c-5R + 3.7c-2C (bundled) · PR #28 merged v main (d256d4a). Flutter-only copy-only sprememba. ADR-007 Amendment §5: retire distance paywall bullete (grep dokazal: `settings_screen.dart` uporablja `PreferenceRangeSlider` samo za age line 1011 + height line 1034; nikjer ni `maxDistance`/`distanceKm`). ADR-007 Amendment §6: hard-filters "coming soon" localised v vseh 8 locales z natančnim ADR §6 phrasingom. Bonus cleanup: orphan `distance_help` translation key (0 callers v `lib/`) odstranjen iz vseh 8 locale blokov v `translations.dart`. Deploy: naslednji APK/TestFlight bundle, brez CF deploya. Test: 249 tests green (+2 nova za hard-filters locale coverage), analyze 0 issues. Extracted lesson: Rule #81 (sweep the fossil trail when retiring never-wired features).
- 2026-07-13 · KORAK 3.7c-1 · PR #29 merged v main (ba8a3dd). Executes ADR-007 Amendment §1 — compound gate `isPremium && hasMutualWave` na Matches list + three-state render pipeline (non-mutual = greyscaled + name + age, mutual+Free = colour + name + age tap-upsell, mutual+Premium = colour + name + age tap opens full card). CF change: `getMatches` emits `hasMutualWave: bool` from `matchData.gestures`. Client DTO: `MatchProfile.hasMutualWave` (default false, backward-compat). Widget: extracted pure `resolveMatchDisplayState()` enum helper. Deploy: `firebase deploy --only functions:getMatches --project am---dating-app` + naslednji APK/TestFlight bundle (additive CF change je backward-compatible za starejše kliente). Test: Flutter 259 green (+10 novih), functions 117 green (+3 novih pair-of-tests za mutual/non-mutual/missing-gestures). Scope confined: Matches list only; Recap + Near-Miss three-state migracije so v ločenih follow-up-ih (3.7c-10, 3.7c-11).
- 2026-07-13 · KORAK 3.7c-3 Slice A · PR #30 merged v main (2f245b6). Read-only regression net za event pin sheet: 4 pair-of-tests (Free-count-locked, Premium-count-visible, Free-heatmap-locked, Premium-heatmap-visible) v `test/features/map/event_pin_sheet_tier_gates_test.dart`. Verified: participant-count + heatmap indicator gates že matchata ADR-007 §3 (obstoječi `effectiveIsPremium` ternary). Slice B (potential-matches count za Premium — subset participants matching caller filter prefs) deferred, bo bundled z 3.7c-4b (owns per-filter subset CF endpoint, design pending). Zero behaviour change; no deploy needed. Test: Flutter 263 green (+4 novih), analyze 0 issues.
- 2026-07-13 · **SHIP PIVOT** · KORAK 3.7 substancialno zaključen (5 PR-jev v prod-ready stanju). Preostali 3.7c-* work je deferrable in ne blokira launcha. Naslednji korak: KORAK 3.8 ship-critical drobci (Info.plist Contacts contradiction — BLOCKER-STORE-002, Apple 5.1.1 tveganje; flaky GymStep test), potem PLAN_04 (Legal + Play Console — 4.1 lahko FOUNDER začne takoj, 2-4 tedne Google review) → PLAN_05 (final build + BLE matrix test + submission). ADR-001 (BLE prava wire-up) ostane največji tehnični launch blocker.
- 2026-07-13 · KORAK 3.8-1 · PR #32 merged v main (184f951, commit 0dfb672). BLOCKER-STORE-002 zaprt na code-side: master `ios/Runner/Info.plist` `NSContactsUsageDescription` mirrorira `en.lproj/InfoPlist.strings` verbatim; 3 podvojeni permission-keys odstranjeni (Camera L58/59, PhotoLibrary L72/73, PhotoLibraryAdd L50/51 — obdržane L46/L48 verzije ki pokrivajo Pulse Intercept v1 feature); `PrivacyInfo.xcprivacy` doda `NSPrivacyCollectedDataTypeContacts` (Linked=false, Tracking=false, Purpose=AppFunctionality — utemeljeno z ADR-004 hash-only transmission). Verifikacija: `plutil -lint` OK za oba plista, vsi 4 dedup'd keys count = 1, Contacts count = 1, `flutter analyze` 0 issues, `flutter test` 263 green, `flutter build ios --no-codesign --flavor dev` uspeh (99.6 MB). No CF/Firestore change, no Dart change; naslednji APK/TestFlight bundle za deploy. Preostalo: PLAN_04 KORAK 4.2 web §2.5 uskladitev na `trembledating.com/privacy` — founder-only, pred App Store submissionom.
