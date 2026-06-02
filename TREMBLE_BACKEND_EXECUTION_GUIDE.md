# Tremble — Backend Execution Guide
**Datum:** 2. junij 2026  
**Osnova:** Audit celotnega backend repozitorija (functions/, firestore.rules, firestore.indexes.json, firebase.json)  
**Namen:** Odpri kot učbenik. Koraki so v zaporedju. Ne preskoči nobenega.

---

## Kako brati ta dokument

Vsak korak ima:
- **Kaj:** kaj točno narediš
- **Kdo:** ti (founder akcija) / Claude Code CLI / Firebase konzola
- **Ukaz ali prompt:** copy-paste ready
- **Done kriterij:** kako veš da je korak zaključen

Faze so v zaporedju. Faza 2 čaka na Fazo 1. Faza 3 čaka na Fazo 2.

---

## STATUS pred začetkom (2. junij 2026)

### Že narejeno ✓
- Wave limit fix: sent waves unlimited; mutual waves limited per calendar month (`users/{uid}.mutualWaves_YYYY_MM`) — deployed to dev 2026-06-02
- Dev Cloud Scheduler job `firebase-schedule-scanProximityPairs-europe-west1` verified enabled 2026-06-02
- Dev `proximity_events` Firestore rule verified with new schema (`fromUid`, `geohash`, `rssi`, `timestamp`, `expiresAt`) 2026-06-02
- `scanProximityPairs` deployed na dev (tremble-dev) — 1-minutni scheduler, live
- `proximity_events` Firestore rule posodobljena (nova schema: fromUid/geohash/expiresAt)
- `proximity/isActive+updatedAt` composite index deployed na dev
- TTL policies na dev: `proximity → geoHashExpiresAt`, `gdprRequests → ttl`
- Prod TTL policies: `proximity_events → expiresAt`, `run_encounters → expiresAt`, `gdprRequests → ttl`, `rateLimits → ttl`
- GDPR funkcije: `exportUserData`, `deleteUserAccount` — pravilno implementirani
- Auth: `onUserDocCreated` nastavi `isPremium: false` za vse nove userje ✓
- Safety: `onReportCreated` velocity check (3 reporti / 48h → flaggedForReview) ✓
- Pulse Intercept: Redis only, 10-min TTL, view-once delete ✓
- `assertNotBanned` na vseh kritičnih CF endpointih ✓

### Kritični odprti problemi
- **Prod nima deployanih functions, rules, indexes**
- **Prod TTL policy za `proximity` je napačna** (targetira `ttl`, mora biti `geoHashExpiresAt`)
- **`greetings` kolekcija** — indexi obstajajo, ni v rules, ni jasno kaj je
- **Matching threshold 0.55** — samo Event mode; Run Club/Gym ne implementirano

---

## FAZA 1 — Wave limit fix (pred vsem drugim)

### Korak 1.1 — Audit wave limit logike ✅ DONE 2026-06-02

**Kdo:** Claude Code CLI  
**Prompt:**
```
Audit the sendWave function in functions/src/modules/matches/matches.functions.ts.

Current code uses checkRateLimit with:
  - maxRequests: isPremium ? 20 : 5
  - windowMs: 30 * 24 * 60 * 60 * 1000 (30 days)

This limits SENT waves. The strategy requires limiting MUTUAL waves instead:
  - Sent waves: unlimited
  - Mutual waves per calendar month (1st–31st): Free = 5, Premium = 20
  - Limit checked at the moment a match is CREATED (mutual wave detected)
  - Both users' counters increment when match is created
  - Calendar month reset (not rolling 30 days)

Step 1: Show me the current onWaveCreated trigger — specifically the 
mutual wave branch where the match is created.

Step 2: Identify exactly where the mutual wave limit check needs to be added.

Step 3: Propose the implementation:
  - Store counter as mutualWaves_YYYY_MM field on users/{uid}
    (auto-resets each month — no cron needed)
  - Check BEFORE creating match: if counter >= limit → HttpsError
  - Increment BOTH users' counters in the same batch as match creation
  - Remove the existing checkRateLimit call from sendWave (or keep it 
    as a soft DoS guard with higher limit, e.g. 100/day)

Show full implementation before writing. Do NOT deploy.
```

**Done kriterij:** Vidiš diff pred pisanjem. Preveriš logiko. Potrdiš.

**Status 2026-06-02:** ✅ DONE — audit completed; implementation proposed, reviewed, then implemented.

---

### Korak 1.2 — Deploy wave limit fix na dev ✅ DONE 2026-06-02

**Kdo:** Ti  
**Ukaz:**
```bash
firebase deploy --only functions:sendWave,functions:onWaveCreated --project tremble-dev
```

**Done kriterij:** Deploy success. Ni error v Firebase Functions logu.

**Status 2026-06-02:** ✅ DONE — deployed `sendWave` and `onWaveCreated` to `tremble-dev`. Functions logs showed both functions `ACTIVE`; no function errors observed.

---

## FAZA 2 — Dev validacija (device test z Martinom)

### Korak 2.1 — Preveri Cloud Scheduler ✅ DONE 2026-06-02

**Kdo:** Ti — Google Cloud Console  
**URL:** `console.cloud.google.com/cloudscheduler?project=tremble-dev`

Poišči job: `firebase-schedule-scanProximityPairs-europe-west1`  
Status mora biti: `Enabled`

**Done kriterij:** Job obstaja in je enabled. Če ni — pojdi na Korak 2.1b.

**Status 2026-06-02:** ✅ DONE — founder verified scheduler job exists and is `Enabled`.

**Korak 2.1b (samo če job ne obstaja):**
```bash
firebase deploy --only functions:scanProximityPairs --project tremble-dev
```

---

### Korak 2.2 — E2E device test (dva telefona) ⏳ PENDING

**Kdo:** Ti + Martin  
**Naprave:** Martin (Samsung S25 Ultra) + tvoj telefon  
**Build:**
```bash
flutter run --flavor dev --dart-define=FLAVOR=dev
```

**Testni scenarij:**
1. Oba odpreta app, oba sta prijavljena z dev accounti
2. Oba sta fizično na isti lokaciji (isti prostor)
3. Oba imata `isActive: true` v proximity dokumentu
4. Počakaj 1-2 minuti (scheduler teče vsako minuto)
5. Preveri Firebase Console dev → Firestore → `proximity_events` kolekcija

**Done kriterij — vse 4 točke morajo biti ✓:**
- [ ] `proximity/{uid}` dokumenta obstajata za oba userja z `updatedAt` svežim timestampom
- [ ] `proximity_events` dokument se pojavi z `fromUid`, `toUid`, `geohash`, `expiresAt`
- [ ] CROSSING_PATHS notifikacija pride na oba telefona
- [ ] Cloud Functions log (`console.cloud.google.com/logs` → filter `scanProximityPairs`) kaže `event: "complete", pairsNotified: 1`

**Status 2026-06-02:** ⏳ PENDING — cannot run device E2E yet.

**Če korak 3 ne dela (dokument ne nastane):**
```
Preveri functions log za napako:
console.cloud.google.com/logs?project=tremble-dev
Filter: resource.type="cloud_run_revision" AND textPayload:"scanProximityPairs"
```

---

### Korak 2.3 — Preveri proximity rule deploy ✅ DONE 2026-06-02

**Kdo:** Ti  
**Preveri:** Firebase Console dev → Firestore → Rules

Pravilna `proximity_events` rule mora biti:
```
match /proximity_events/{eventId} {
  allow create: if signedIn() &&
    request.resource.data.fromUid == request.auth.uid &&
    request.resource.data.keys().hasAll(['fromUid', 'geohash', 'rssi', 'timestamp', 'expiresAt'])
    ...
```

Če je še stara (`from`, `toDeviceId`, `ttl`) — rules niso deployane. Zaženi:
```bash
firebase deploy --only firestore:rules --project tremble-dev
```

**Done kriterij:** Rules v konzoli kažejo novo shemo.

**Status 2026-06-02:** ✅ DONE — founder pasted dev rules; `proximity_events` rule uses new schema (`fromUid`, `geohash`, `rssi`, `timestamp`, `expiresAt`) and no old `from` / `toDeviceId` / `ttl` schema.

---

### Korak 2.4 — TTL policies za ostale kolekcije (po device testu)

**Kdo:** Ti — Google Cloud Console  
**URL:** `console.cloud.google.com/firestore/databases/-default-/ttl?project=tremble-dev`

Ko `proximity_events` kolekcija obstaja v dev (po device testu), dodaj:

| Collection group | Timestamp field |
|---|---|
| `proximity_events` | `expiresAt` |
| `matches` | `expiresAt` |

> `run_encounters` in `active_run_crosses` dodaj ko te kolekcije nastanejo v dev.

**Done kriterij:** Obe policy sta Serving.

---

### Korak 2.5 — Audit greetings kolekcije

**Kdo:** Claude Code CLI  
**Prompt:**
```
Search the entire codebase (all TypeScript files in functions/src/ and 
all Dart files in lib/) for any reference to a "greetings" collection.

What writes to it, what reads from it? Is it related to waves, or a 
separate feature? Should it be in firestore.rules?

Report every file:line reference. Do NOT edit anything.
```

**Done kriterij:** Razumeš kaj je `greetings`. Odločiš ali rabiš Firestore rule za to kolekcijo.

---

## FAZA 3 — Prod deploy (po uspešnem device testu)

### Korak 3.1 — Fix prod TTL policy za proximity

**Kdo:** Ti — Google Cloud Console prod  
**URL:** `console.cloud.google.com/firestore/databases/-default-/ttl?project=am---dating-app`

Trenutno stanje: `proximity → ttl` ← NAPAČNO (field `ttl` nikoli ni zapisan)  
Potrebno: `proximity → geoHashExpiresAt`

Koraki:
1. Izbriši obstoječo `proximity → ttl` policy (trash ikona)
2. Ko pridejo pravi userji v prod in `proximity` kolekcija nastane → ustvari `proximity → geoHashExpiresAt`

> Zdaj ne moreš ustvariti policy ker kolekcija v produ ne obstaja (ni pravih userjev). Todoist task za to je že dodan.

---

### Korak 3.2 — Full prod deploy

**Kdo:** Ti  
**Ukaz:**
```bash
firebase deploy --only functions,firestore --project am---dating-app
```

To deployna:
- Vse Cloud Functions (vključno s `scanProximityPairs`)
- Firestore rules (posodobljene)
- Firestore indexes

**Done kriterij:** Deploy success. Preveril Firebase Console prod → Functions → vse funkcije so listed.

---

### Korak 3.3 — Preveri Cloud Scheduler na produ

**Kdo:** Ti  
**URL:** `console.cloud.google.com/cloudscheduler?project=am---dating-app`

Poišči: `firebase-schedule-scanProximityPairs-europe-west1`  
Status: Enabled

**Done kriterij:** Job obstaja in je enabled.

---

### Korak 3.4 — Preveri prod TTL policies

**Kdo:** Ti  
**URL:** `console.cloud.google.com/firestore/databases/-default-/ttl?project=am---dating-app`

Pričakovano stanje po deployu (brez proximity ker kolekcija ne obstaja):

| Collection | Field | Status |
|---|---|---|
| `gdprRequests` | `ttl` | Serving ✓ |
| `proximity_events` | `expiresAt` | Serving ✓ |
| `run_encounters` | `expiresAt` | Serving ✓ |
| `rateLimits` | `ttl` | Serving ✓ |

`proximity` dodaš po prvem pravem userju.

---

## FAZA 4 — Post-launch (ne dela zdaj)

### Korak 4.1 — Matching threshold za Run Club in Gym

**Problem:** `findNearby` CF implementira 0.55 threshold samo za Event mode. Run Club in Gym auto-detect mode ne znižata praga na 0.55.

**Kdaj:** Po prvih 50 aktivnih userjih — najprej validiraš ali je 0.70 threshold v praksi previsok.

**Prompt (ko si pripravljen):**
```
In proximity.functions.ts, findNearby function, the threshold logic at 
line ~402 lowers the threshold to 0.55 only when both users share the 
same activeEventId.

Strategy requires 0.55 for ALL auto-detected activity modes:
- Run Club auto-detect (isRunModeActive == true, not manually triggered)
- Gym Mode auto-detect (activeGymId set by geofence, not manual)  
- Event Mode (already implemented)

Manual activations keep 0.70.

The problem: there's currently no way to distinguish auto vs manual 
activation in the user document. 

Propose how to implement this distinction — what field to add, 
where to set it, and how findNearby reads it. Show the full plan 
before writing any code.
```

---

### Korak 4.2 — Odstrani deprecated CF

**Kdaj:** Naslednji breaking deploy (po stabilizaciji proda)

V `functions/src/index.ts` in `proximity.functions.ts`:
- Odstrani `onBleProximity` export in implementacijo
- Odstrani `onRunEncounter` export in implementacijo

**Prompt:**
```
Remove the deprecated onBleProximity and onRunEncounter functions 
from proximity.functions.ts and index.ts.

These are currently no-ops marked @deprecated. Remove:
- The export statements in index.ts
- The complete function bodies in proximity.functions.ts

Show the diff before writing. After writing, run: npx tsc --noEmit
Report any TypeScript errors. Do NOT deploy.
```

---

### Korak 4.3 — TTL policies za proximity in matches na produ

**Kdaj:** Ko kolekciji obstajata v produ (po prvem pravem userju)

Dev TTL policies (za referenco):
- `proximity → geoHashExpiresAt`
- `gdprRequests → ttl`

Prod TTL policies (dodati):
- `proximity → geoHashExpiresAt` (čaka na prve userje)
- `matches → expiresAt` (čaka na prve userje)
- `active_run_crosses → expiresAt` (čaka na prve userje)

---

### Korak 4.4 — Audit Steps 2-10

Iz `STRATEGY_COMPLIANCE_AUDIT_PLAN.md` ostane:
- Step 2: Wave mechanic & limits
- Step 3: Trembling Window & Pulse Intercept
- Step 4: History tab gating
- Step 5: Hard Filters server-side enforcement
- Step 6: Heatmap & Map events
- Step 7: Notifications
- Step 8: Privacy & TTL
- Step 9: Pricing & Premium gating
- Step 10: Brand & copy compliance

---

## ZNANE NAPAKE (neblokirajoče za launch)

### BUG-001: GDPR deleteUserAccount queries staro polje
**Lokacija:** `gdpr.functions.ts:180`  
**Problem:**
```typescript
.where("from", "==", uid)  // staro polje
```
Mora biti:
```typescript
.where("fromUid", "==", uid)  // novo polje po BLE redesignu
```
**Impact:** GDPR brisanje ne pobriše proximity_events za userja. Privacy issue — ne App Store blocker.  
**Fix prompt:**
```
In gdpr.functions.ts, the deleteUserAccount function queries 
proximity_events with:
  .where("from", "==", uid)

After the BLE redesign, the field is "fromUid", not "from".

Fix the query to use "fromUid". Also check: does the function query 
for toUid as well? proximity_events now have both fromUid and toUid 
(both parties of the encounter). The deletion should cover both.

Show diff before writing. Do NOT deploy.
```

### BUG-002: `updateLocation` piše samo 3 polja
**Lokacija:** `proximity.functions.ts:205-215`  
**Problem:** `updateLocation` CF piše samo `geohash`, `lastSeen`, `isActive`. `updatedAt`, `radiusTier`, `geoHashExpiresAt` pišeta Dart klient direktno.  
**Impact:** `scanProximityPairs` deluje (query-a `updatedAt` ki ga piše klient). Ampak če klient ne piše `updatedAt` (npr. stara verzija app), scanner ne bo zaznal parjev.  
**Monitoring:** Cloud Functions log za `event: "complete", activeUsers: 0` ko je app aktiven — to bi signaliziralo da `updatedAt` ni zapisan.

### BUG-003: `proximity_notifications` kolekcija v GDPR brisu
**Lokacija:** `gdpr.functions.ts:188`  
**Problem:** GDPR bris query-a `proximity_notifications` kolekcijo, ki ne obstaja v Firestore rules in ni nikjer zapisana v kodi. Verjetno legacy ali placeholder.  
**Impact:** Query vrne prazno, bris se nadaljuje normalno. Ni napaka, samo dead code.

---

## REFERENCA: Prod vs Dev

| | Dev (tremble-dev) | Prod (am---dating-app) |
|---|---|---|
| Flutter build | `--flavor dev` | `--flavor prod` |
| Firebase options | `firebase_options_dev.dart` | `firebase_options_prod.dart` |
| Deploy ukaz | `--project tremble-dev` | `--project am---dating-app` |
| Cloud Functions | `europe-west1` | `europe-west1` |
| Firestore backup | Disabled | Enabled |
| scanProximityPairs | ✓ Live | ✗ Čaka deploy |
| TTL policies | proximity ✓, gdprRequests ✓ | proximity_events ✓, run_encounters ✓, gdprRequests ✓, rateLimits ✓ |

---

## REFERENCA: Vse Cloud Functions

| Funkcija | Tip | Modul | Status |
|---|---|---|---|
| `onUserDocCreated` | Trigger | auth | ✓ |
| `completeOnboarding` | Callable | auth | ✓ |
| `verifyGoogleToken` | Callable | auth | ✓ |
| `updateProfile` | Callable | users | ✓ |
| `getProfile` | Callable | users | ✓ |
| `getPublicProfile` | Callable | users | ✓ |
| `sendWave` | Callable | matches | ⚠️ Limit je na sent, ne mutual |
| `onWaveCreated` | Trigger | matches | ✓ |
| `getMatches` | Callable | matches | ✓ |
| `migrateMatchTypes` | Callable (admin) | matches | ✓ |
| `requestPulseIntercept` | Callable | matches | ✓ |
| `getPulseIntercept` | Callable | matches | ✓ |
| `generateUploadUrl` | Callable | uploads | ✓ |
| `updateLocation` | Callable | proximity | ✓ |
| `findNearby` | Callable | proximity | ⚠️ 0.55 samo Event mode |
| `setInactive` | Callable | proximity | ✓ |
| `scanProximityPairs` | Scheduled 1min | proximity | ✓ Dev / ✗ Prod |
| `onBleProximity` | Trigger (no-op) | proximity | DEPRECATED |
| `getProximityMatchCandidates` | Callable | proximity | ✓ |
| `onRunEncounter` | Trigger (no-op) | proximity | DEPRECATED |
| `onRunCrossUpdated` | Trigger | proximity | ✓ |
| `exportUserData` | Callable | gdpr | ✓ |
| `deleteUserAccount` | Callable | gdpr | ⚠️ BUG-001 |
| `resendVerificationEmail` | Callable | email | ✓ |
| `blockUser` | Callable | safety | ✓ |
| `unblockUser` | Callable | safety | ✓ |
| `reportUser` | Callable | safety | ✓ |
| `onContactAnonymityCheck` | Callable | safety | ✓ |
| `onReportCreated` | Trigger | safety | ✓ |
| `onEventModeActivate` | Callable | events | ✓ |
| `onEventModeDeactivate` | Callable | events | ✓ |
| `expireEventModes` | Scheduled 60min | events | ✓ |
| `onGymModeActivate` | Callable | gym | ✓ |
| `onGymModeDeactivate` | Callable | gym | ✓ |
| `expireGymSessions` | Scheduled 60min | gym | ✓ |
| `onRunModeActivate` | Callable | gym | ✓ |
| `onRunModeDeactivate` | Callable | gym | ✓ |
| `expireRunModes` | Scheduled 60min | gym | ✓ |

---

## REFERENCA: Firestore Security Rules — pokritost

| Kolekcija | Rule | Opomba |
|---|---|---|
| `users` | ✓ Strict | validCreateKeys, validUpdateKeys, type+size checks |
| `users/{uid}/viewedRecaps` | ✓ | isSelf |
| `drafts` | ✓ | isSelf |
| `waitlist` | ✓ | Public create only |
| `matches` | ✓ | Participants read, seenBy update only |
| `waves` | ✓ | Sender create, participants read |
| `sessions` | ✓ | Participants read, backend write |
| `events` | ✓ | Authenticated read, backend write |
| `proximity` | ✓ | Self write, whitelisted fields |
| `active_run_crosses` | ✓ | userIds read, backend write |
| `proximity_events` | ✓ | Posodobljeno po BLE redesignu |
| `rateLimits` | ✓ | Self read, backend write |
| `idempotencyKeys` | ✓ | Backend only |
| `gdprRequests` | ✓ | Self read, backend write |
| `gyms` | ✗ MANJKA | Default deny via admin SDK — gap |
| `greetings` | ✗ MANJKA | 3 indexi obstajajo — neznana kolekcija |
| `reports` | ✗ MANJKA | Backend only OK, ampak ni eksplicitnega rula |
| `proximity_notifications` | ✗ MANJKA | Legacy/dead code v GDPR brisanju |
| `*` | ✓ | Default deny |

---

*Zadnja posodobitev: 2. junij 2026 — po auditu ZIP repozitorija*
