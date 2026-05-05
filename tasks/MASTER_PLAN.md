# TREMBLE — CONSOLIDATED MASTER IMPLEMENTATION PLAN
**Last Updated:** 2026-04-29
> This document is the single source of truth for the remaining Tremble features, technical implementation details, store submission phases, metadata, and strict project policies. It replaces all fragmented implementation plans and policy files.

---

## Feature Implementation Roadmap (F1-F11)

# Tremble — Feature Implementation Plan v2
**AMS Solutions d.o.o. · Confidential · April 2026**

> Celoten tehnični implementation plan za 11 funkcij + 4 addons. Namenjen Claude Code sejam in Martin/Aleksandar koordinaciji. Vedno preberi pred začetkom nove seje.

---

## Metapodatki

| | |
|---|---|
| Verzija | v3.0 |
| Datum | April 2026 |
| Features | 11 (F1–F11) + addons |
| Faze | 4 |
| Est. skupaj | ~16 tednov |
| Founder required | F7, F10 (Info.plist), F11 (legal review) (F8 Postponed) |

---

## Pravila tega dokumenta

- Nikoli ne deployi v `am---dating-app` (prod) brez Aleksandarjevega odobrenja
- `AndroidManifest.xml`, `Info.plist`, `google-services.json` → founder approval pred vsako spremembo
- Flutter build vedno: `--flavor dev --dart-define=FLAVOR=dev`
- Nikoli ne deli API ključev med `tremble-dev` in `am---dating-app`
- Vsak nov Firestore collection zahteva Security Rule pred deployom
- SEC-001 (App Check) mora biti enforce-an preden gre karkoli v prod
- **[NOVO] 80% Context Rule:** Ko zasedenost kontekstnega okna (spomina) doseže 80%, mora agent obvezno posodobiti vse dokumente (`tasks/context.md`, `tasks/todo.md`) in izvesti *Session Handoff*, nato pa se sejo prekine, da se preprečijo napake zaradi pomanjkanja spomina.

---

## Implementacijski vrstni red

### Faza A — Teden 1–3 (foundation)
1. **F9** — Radius logic (RSSI threshold + geohash filter) ✅
2. **F1** — Google Maps / Places API (blocker za F10) ✅

*Opomba: F8 (Pricing) je začasno umaknjen iz Faze A in prestavljen na čas, ko bo uradno ustanovljeno podjetje AMS Solutions.*

### Faza B — Teden 4–8
4. **F11** — Smoking preferences (profil field + filter) ✅
5. **F3** — Match categories + history filters ✅
6. **F2** — Event mode matching ✅
7. **F10** — Gym Mode (zahteva F1) ✅

### Faza C — Teden 9–11
8. **F4** — Hot/Cold navigation (pure Flutter, brez infra)
9. **F6** — Run Club (native activity detection, ephemeral proximity) ✅

### Faza D — Teden 14–16
11. **F7** — Valentine Promo (time-gated, deploy pred 1. februarjem)

### Faza E — Next (Expansion)
12. **F12** — Pulse Intercept (Phone & Ephemeral Photo) ✅ DONE

---

## Predpogoji pred pisanjem kode

| Predpogoj | Za | Akcija | Odgovoren |
|---|---|---|---|
| Google Maps Platform billing enabled | F1, F10 | GCP Console → Billing | Founder |
| Places API (New) + Maps SDK iOS/Android | F1, F10 | GCP → APIs & Services → Enable | Martin/Dev |
| Maps API ključi z restrikcijami | F1 | GCP → Credentials → Create + restrict | Martin/Dev |
| RevenueCat — novi Product IDs v App Store Connect | F8 | ASC → In-App Purchases → New | Founder |
| RevenueCat — lifetime Non-Consumable product | F8 | ASC → Non-Consumable type | Founder |
| DPIA posodobitev — GPS ephemeral processing | F9 | Posodobi DPIA dokument | Founder |
| Privacy Policy update — GPS processing | F9 | Posodobi PP na trembledating.com | Founder |
| Apple Developer — Background Modes: Location | F10 | Info.plist + Capabilities | Founder + Dev |
| Legal review — smoking/cannabis profil field | F11 | Pravni vidik za SI/HR trg | Founder |
| Upstash — preveri plan limits (TTL support) | F6, F10 | Upstash dashboard | Martin/Dev |

---

## F1 — Google Maps / Places Integration

**Effort:** M · **Blocker za:** F10

### Problem
String lokacije (`"Ljubljana"`) povzročajo tipkarske napake in neujemanje pri matchingu. Gym Mode ne more delovati brez strukturiranih place podatkov.

### GCP Setup
```bash
# Enable v Google Cloud Console — oba projekta (tremble-dev + am---dating-app)
APIs za enable:
- Maps SDK for Android
- Maps SDK for iOS  
- Places API (New)
- Geocoding API

# Ustvari ločene API ključe z restrikcijami
MAPS_KEY_ANDROID → restrict: Android package name + SHA-1 fingerprint (dev + prod SHA-1 LOČENO)
MAPS_KEY_IOS     → restrict: iOS bundle ID

# Shrani v Firebase Secret Manager (ne v kodo)
gcloud secrets create MAPS_KEY_ANDROID --project=tremble-dev --data-file=- <<< "AIza..."
gcloud secrets create MAPS_KEY_IOS --project=tremble-dev --data-file=- <<< "AIza..."
# Ponovi za am---dating-app
```

### Session Token Model (kritično za cost)
```dart
// NIKOLI ne kliči Places API direktno na vsak keystroke
// VEDNO uporabi session tokens — en token pokrije celotno autocomplete sejo

class PlacesService {
  late final String _sessionToken;

  void startSession() {
    _sessionToken = const Uuid().v4(); // nov token ob vsakem odprtju autocomplete
  }

  Future<List<PlacePrediction>> autocomplete(String input) async {
    // Pošlji sessionToken z vsakim requestom
    return await _placesClient.findAutocompletePredictions(
      query: input,
      sessionToken: AutocompleteSessionToken.newInstance(),
    );
    // Ko user izbere rezultat → en Place Details klic zaključi sejo
    // Celotna seja = $0.017, ne $0.017 × N keystrokes
  }

  void endSession() {
    // Pokliči po user selekciji — zaključi billing session
    _sessionToken = const Uuid().v4(); // reset za naslednjo sejo
  }
}
```

**Brez session tokenov pri 50k DAU = ~$5.100/mesec. Z session tokeni = ~$200–500/mesec.**

### Flutter Paketi
```yaml
# pubspec.yaml
google_maps_flutter: ^2.6.0
google_places_flutter: ^2.0.8  # ali flutter_google_places_hive_16 za boljši session token mgmt
uuid: ^4.0.0  # za session token generacijo
```

### AndroidManifest.xml (founder approval)
```xml
<meta-data
  android:name="com.google.android.geo.API_KEY"
  android:value="${MAPS_KEY_ANDROID}"/>
```

### AppDelegate.swift (iOS)
```swift
GMSPlacesClient.provideAPIKey("MAPS_KEY_IOS")
// Dodaj pred GeneratedPluginRegistrant.register
```

### Firestore Schema — sprememba
```javascript
// PREJ: users/{uid}
homeCity: "Ljubljana"  // string — napaka

// ZDAJ: users/{uid}
homeLocation: {
  placeId: "ChIJW0...",    // Google Place ID — stabilen, canonicaliziran
  name: "Ljubljana",
  lat: 46.0569,
  lng: 14.5058,
  type: "city"             // "city" | "venue" | "gym"
}

locations: [              // array za multiple locations (dom, gym, work area)
  {
    placeId: "ChIJ...",
    name: "Gold's Gym Ljubljana",
    lat: 46.0551,
    lng: 14.5123,
    type: "gym"
  }
]
```

### Migration Cloud Function
```javascript
// Enkratni run — NE ob deployu, ročno po testu
exports.migrateStringLocations = onCall(async (req) => {
  // Samo za admin uid
  const users = await db.collection('users').get();
  for (const doc of users.docs) {
    const data = doc.data();
    if (typeof data.homeCity === 'string') {
      const geo = await geocodeCity(data.homeCity); // Geocoding API
      await doc.ref.update({
        homeLocation: geo,
        homeCity: FieldValue.delete()
      });
    }
  }
});
```

---

## F2 — Event Mode Matching

**Effort:** M

### Event Mode UI in UX Pravila
* **Logika ujemanja (0.55 prag):** Prag ujemanja se zniža na 0.55 (prej 0.70).
* **Brez piskov/notifikacij (Quiet List):** Uporabnik ne prejema nenehnih notifikacij med dogodkom. Prikaže se tih seznam vseh potencialnih ujemov.
* **Interakcija:** Na seznamu lahko uporabnike pozdraviš (pošlješ "wave").
* **Zgodovina:** Ko zapustiš dogodek, se ohrani zgodovina vseh, ki si jim lahko poslal wave ali z njimi ujel.
* **Začasni Premium:** Če je dogodek partneriziran, imajo uporabniki na dogodku **začasni Premium** (lahko vpogledajo v celotne Profile Cards, čeprav so sicer Free uporabniki).

### Firestore Schema

```javascript
// events/{eventId}
{
  name: "Treking Ljubljana 2026",
  location: { placeId, name, lat, lng },
  radiusMeters: 500,
  matchThreshold: 0.55,    // override — default je 0.70
  startsAt: Timestamp,
  endsAt: Timestamp,
  active: true,
  createdBy: "admin"        // Tremble admin only — ne user-created
}

// users/{uid} — dodaj
activeEventId: "eventId" | null
eventModeUntil: Timestamp | null
```

### Cloud Functions
```javascript
// Sprememba v obstoječi matching funkciji
async function computeMatchScore(uid1, uid2, context) {
  const threshold = context.eventMode
    ? (context.eventThreshold ?? 0.55)
    : 0.70;
  
  const score = calculateCompatibility(uid1, uid2);
  return { matches: score >= threshold, score };
}

// Nova funkcija
exports.onEventModeActivate = onCall(async (req) => {
  const { uid, eventId } = req.data;
  const event = await db.collection('events').doc(eventId).get();
  
  // Preveri, da je user znotraj radiusa od event lokacije
  const userLocation = await getCurrentGPS(uid); // ephemeral — ne shrani
  const distance = haversine(userLocation, event.data().location);
  
  if (distance > event.data().radiusMeters) {
    throw new HttpsError('failed-precondition', 'Not at event location');
  }
  
  await db.collection('users').doc(uid).update({
    activeEventId: eventId,
    eventModeUntil: event.data().endsAt
  });
});

// Scheduled — vsako uro
exports.expireEventModes = onSchedule('every 60 minutes', async () => {
  const expired = await db.collection('users')
    .where('eventModeUntil', '<', Timestamp.now())
    .where('activeEventId', '!=', null)
    .get();
  
  const batch = db.batch();
  expired.docs.forEach(doc => {
    batch.update(doc.ref, { activeEventId: null, eventModeUntil: null });
  });
  await batch.commit();
});
```

### Upstash Redis
```
event:active:{eventId}:users → sorted set {uid: arrivalTimestamp}
TTL: do endsAt eventa
```

---

## F3 — Match Categories + History Filters

**Effort:** M

### Firestore Schema
```javascript
// matches/{matchId} — dodaj polja
{
  uid1: "...",
  uid2: "...",
  matchType: "standard",   // "standard" | "event" | "activity" | "gym"
  matchContext: {
    eventId: "eventId" | null,
    activityType: "running" | null,
    gymPlaceId: "ChIJ..." | null
  },
  createdAt: Timestamp,
  status: "active" | "expired" | "confirmed"
}
```

### Firestore Indexes (composite)
```
Collection: matches
Index 1: uid1 (asc) + matchType (asc) + createdAt (desc)
Index 2: uid2 (asc) + matchType (asc) + createdAt (desc)
Index 3: uid1 (asc) + createdAt (desc)   // za "All" tab + history filter
Index 4: uid2 (asc) + createdAt (desc)
```

### History Filter — Firestore Query
```dart
// Flutter — Match History filter
enum HistoryFilter { lastWeek, lastMonth, last3Months, last12Months, all }

Timestamp _filterToTimestamp(HistoryFilter filter) {
  final now = DateTime.now();
  return switch (filter) {
    HistoryFilter.lastWeek    => Timestamp.fromDate(now.subtract(const Duration(days: 7))),
    HistoryFilter.lastMonth   => Timestamp.fromDate(now.subtract(const Duration(days: 30))),
    HistoryFilter.last3Months => Timestamp.fromDate(now.subtract(const Duration(days: 90))),
    HistoryFilter.last12Months => Timestamp.fromDate(now.subtract(const Duration(days: 365))),
    HistoryFilter.all         => Timestamp.fromDate(DateTime(2020)),
  };
}

Stream<List<Match>> getMatchHistory(String uid, HistoryFilter filter, String? typeFilter) {
  Query query = db.collection('matches')
    .where(Filter.or(
      Filter('uid1', isEqualTo: uid),
      Filter('uid2', isEqualTo: uid),
    ))
    .where('createdAt', isGreaterThan: _filterToTimestamp(filter))
    .orderBy('createdAt', descending: true);

  if (typeFilter != null) {
    query = query.where('matchType', isEqualTo: typeFilter);
  }
  
  return query.snapshots().map((s) => s.docs.map(Match.fromFirestore).toList());
}
```

### Flutter UI
- Zamenjaj "Your People" → **"Your Matches"**
- Tabbed interface: All / Event / Activity / Gym
- History filter row pod tabi: pill buttons Last Week / Last Month / Last 3M / Last 12M / All
- Prazni tabi: empty state v brand tonu brez error-ja
- Migration: `migrateMatchTypes` Cloud Function, obstoječi → `matchType: "standard"`

---

## F4 — Hot/Cold Navigation (DONE ✅)

**Effort:** S · **Infrastructure:** nič — pure Flutter

### Implementacija
```dart
// V obstoječem BLE RSSI handling-u — samo dodaj delta kalkulacijo
enum WarmthDirection { warmer, colder, neutral }

WarmthDirection computeWarmth(List<int> rssiBuffer) {
  if (rssiBuffer.length < 3) return WarmthDirection.neutral;
  
  final recent = rssiBuffer.last;
  final prev = rssiBuffer[rssiBuffer.length - 3];
  final delta = recent - prev; // RSSI je negativen: -55 je boljši kot -70
  
  if (delta > 3)  return WarmthDirection.warmer;
  if (delta < -3) return WarmthDirection.colder;
  return WarmthDirection.neutral;
}
// Threshold ±3 dBm — pod tem je šum. Testiraj na Samsung S25 Ultra + iPhone 14.
```

### Flutter UI
```dart
// Na radar view med active trembling window
Widget _warmthIndicator(WarmthDirection direction) => switch (direction) {
  WarmthDirection.warmer  => Text('Getting closer', style: TextStyle(color: Color(0xFFF4436C))),
  WarmthDirection.colder  => Text('Moving away',    style: TextStyle(color: Color(0xFF6B8CAE))),
  WarmthDirection.neutral => const SizedBox.shrink(), // nič — brez šuma
};
```

**Brez Firebase sprememb. Brez Upstash sprememb.**

---

## F6 — Run Club (In-Motion Handshake)

**Effort:** L · **Status:** 🟡 In Progress (Native Bridge Foundation Complete)

### Philosophy
Strictly ephemeral. No GPS maps. No historical tracks. No Strava. Tremble detected in the moment only.

### Technology Stack
1.  **Motion Detection:** `CMMotionActivityManager` (iOS) & `Activity Recognition API` (Android).
2.  **Native Bridge:** `NativeMotionService` (Flutter `EventChannel`) bridges real-time activity states (`RUNNING`, `STATIONARY`, `WALKING`) to the background isolate.
3.  **Bluetooth:** BLE Advertisement with `Run Mode Flag (0x01)` in manufacturer data byte 0.
4.  **Infrastructure:** Firebase Cloud Functions (Handshake processor) + Firestore TTL (10-minute expiry).
5.  **Redis (Upstash):** Ephemeral tracking of "Run Club Active" users for geohash-based proximity optimization (optional/future).

### Phase 6.1: Native & Background Foundation (DONE ✅)
*   **Permissions:** `ACTIVITY_RECOGNITION` (Android) and `NSMotionUsageDescription` (iOS) configured.
*   **Bridges:** `MainActivity.kt` and `AppDelegate.swift` now stream motion states via `app.tremble/motion/events`.
*   **Logic:** `background_service.dart` handles the state machine:
    *   **5-min Running:** Smart Activation trigger.
    *   **15-min Stationary:** Smart Deactivation trigger.
    *   **20-min Inactivity:** Auto-Close logic.

### Phase 6.2: BLE Signature & Handshake (DONE ✅)
*   **BLE Flag:** Restore `Run Mode Flag (0x01)` in `BleService.dart` manufacturer data.
*   **Logic:** When `run_club_active` is true in `SharedPreferences`, `BleService` restarts advertising with the flag.
*   **Handshake:** Scanning runners who detect the 0x01 flag use a more aggressive RSSI threshold (55% signal) to account for high-speed crossing.

### Phase 6.3: Ephemeral Handshake (The Momentum Rule) (DONE ✅)
*   **Handshake Entry:** Proximity events marked as `run_cross` are sent to a dedicated Firestore collection or processed via Cloud Functions.
*   **TTL Policy:** Every `run_cross` record MUST have an `expiresAt` field set to `now + 10 minutes`.
*   **Handshake Function:** A Cloud Function monitors mutual crosses. If both users "Wave" within the 10-minute window, the match is upgraded to a `Pulse Confirmed`. If the window closes, the data is purged.

### Phase 6.4: UI/UX (Mid-Run Intercept) (DONE ✅)
*   **Dashboard:** A dedicated **Live Run Card** appears at the top of the radar during an active run session.
    *   *Visuals:* GlassCard with neon/vibrant pulse border.
    *   *Content:* "Pravkar šla mimo: Ana, 24".
*   **Interaction:**
    *   **[Send Wave]**: Explicitly notifies the other user (overriding Silent Mode).
    *   **[Recap]**: Appears post-run to show all crosses from the last 10 minutes.
*   **Notifications:** High-priority "Intercept" notification for the receiver: *"Ana (24) ti pošilja Wave med tekom! 👀"*.

### Phase 6.5: Verification & Polish
*   **Physical Testing:** Samsung S25 Ultra vs iPhone 15 Pro crossing test.
*   **Battery Audit:** Verify 3–4% battery consumption over a 1-hour active run session (GPS + BLE hybrid).
*   **Privacy Audit:** Ensure zero GPS traces are left in Firestore after the 10-minute expiry.

### Firestore Schema (Handshake)
```javascript
// run_encounters/{encounterId}
{
  participants: ["uid1", "uid2"],
  timestamp: ServerTimestamp,
  expiresAt: Timestamp, // 10 min TTL
  signals: {
    "uid1": { rssi: -72, waved: false },
    "uid2": { rssi: -85, waved: false }
  }
}
```

### Upstash Redis
```
runners:active:{city_geohash}   → sorted set {uid: timestamp}   TTL per member: 30min
runners:nearby:{userId}          → sorted set of runner uids     TTL: 60s
```

### Matching — Run Mode
```javascript
// Ko sta oba userja v Run Mode in BLE ju zazna skupaj
matchThreshold: 0.55  // 55% threshold za visoke hitrosti
matchType: "activity"
matchContext.activityType: "running"
```

---

## F7 — Valentine's Promo

**Effort:** S · **Founder required:** RevenueCat + App Stores

### App Store Connect (founder action)
```
Features → In-App Purchases → [Monthly product] → Promotional Offers → + Add
Offer ID: valentine_2026_7day_free
Duration: 7 days
Price: free
```

### Firestore Schema
```javascript
// promotions/{promoId}
{
  promoCode: "VALENTINE26",
  validFrom: Timestamp,    // 10. februar
  validUntil: Timestamp,   // 16. februar  
  maxActivations: 5000,
  currentActivations: 0    // atomic increment
}

// users/{uid}
activePromo: {
  type: "valentine_2026",
  activatedAt: Timestamp,
  expiresAt: Timestamp,    // + 7 dni
  revertedAt: Timestamp | null
}
```

### Cloud Functions
```javascript
exports.activateValentinePromo = onCall(async (req) => {
  const { uid } = req.auth;
  const now = Timestamp.now();
  
  // Preveri promo window
  const promo = await db.collection('promotions').doc('valentine_2026').get();
  if (now < promo.data().validFrom || now > promo.data().validUntil) {
    throw new HttpsError('failed-precondition', 'Promo not active');
  }
  
  // Preveri da user ni Pro in ni že aktiviral
  const user = await db.collection('users').doc(uid).get();
  if (user.data().activePromo || user.data().isPro) {
    throw new HttpsError('already-exists', 'Already active');
  }
  
  // Atomic counter check
  await db.runTransaction(async (t) => {
    const promoRef = db.collection('promotions').doc('valentine_2026');
    const promoDoc = await t.get(promoRef);
    if (promoDoc.data().currentActivations >= promoDoc.data().maxActivations) {
      throw new HttpsError('resource-exhausted', 'Promo full');
    }
    t.update(promoRef, { currentActivations: FieldValue.increment(1) });
    t.update(db.collection('users').doc(uid), {
      activePromo: {
        type: 'valentine_2026',
        activatedAt: now,
        expiresAt: Timestamp.fromDate(new Date(now.toDate().getTime() + 7 * 24 * 60 * 60 * 1000))
      }
    });
  });
  
  // RevenueCat promo offer aktivacija prek SDK
  // ...
});

// Scheduled — vsako uro
exports.revertExpiredPromos = onSchedule('every 60 minutes', async () => {
  const expired = await db.collection('users')
    .where('activePromo.expiresAt', '<', Timestamp.now())
    .where('activePromo.revertedAt', '==', null)
    .get();
  // RevenueCat revert je avtomatski (trial expiry)
  // Samo Firestore tracking posodobi
});
```

---

## F8 — Pricing Update
> **[PRESTAVLJENO / POSTPONED]** 
> Ta funkcija je začasno umaknjena iz aktivnega načrta in prestavljena na čas, ko bo uradno ustanovljeno podjetje AMS Solutions d.o.o.

**Effort:** S · **Founder required:** App Store Connect + Play Console

### Produkt konfiguracija
```
App Store Connect:
tremble_pro_monthly_799   → Auto-Renewable Subscription → €7.99/mes
tremble_pro_annual_45     → Auto-Renewable Subscription → €45.00/leto
tremble_pro_lifetime_80   → Non-Consumable (NE Subscription) → €80.00

Play Console:
tremble_pro_monthly_799   → Subscription → Base Plan → €7.99/mes
tremble_pro_annual_45     → Subscription → Base Plan → €45.00/leto  
tremble_pro_lifetime_80   → Managed Product (One-time) → €80.00
```

**Lifetime = Non-Consumable, ne Subscription.** Apple vzame 30% samo enkrat. RevenueCat tratira kot večno `pro` entitlement. Ni auto-renewing.

### RevenueCat
```
Dashboard → Products → attach novi product IDs
Offerings → "default" → posodobi packages: Monthly, Annual, Lifetime
Entitlement: "pro" (ostane isto — logika v applikaciji se ne spreminja)
```

### Entitlement check (ni spremembe)
```dart
final info = await Purchases.getCustomerInfo();
final isPro = info.entitlements.active.containsKey('pro');
// Lifetime in subscription sta oba 'pro' — enaka logika
```

---

## F9 — Radius Logic

**Effort:** M · **GDPR note:** ephemeral GPS processing

### Fizikalna realnost
BLE: max 30–80m v realnem svetu. 250m ni BLE — je **GPS geohash pre-filter + BLE potrditev**.

- **Free (100m):** GPS geohash filter 100m + RSSI threshold ≥ -75 dBm
- **Premium (250m):** GPS geohash filter 250m + RSSI threshold ≥ -85 dBm

GPS primerjava poteka v Cloud Function RAM-u — ni shranjena, ni logirana. Privacy Policy mora eksplicitno opisati: *"location used transiently for proximity calculation, never stored or logged."*

### Cloud Function
```javascript
const RADIUS_FREE_M = 100;
const RADIUS_PRO_M = 250;

async function getProximityMatchCandidates(uid, lat, lng) {
  const user = await db.collection('users').doc(uid).get();
  const radius = user.data().isPro ? RADIUS_PRO_M : RADIUS_FREE_M;
  
  // Geohash neighbors query — Firestore geohash library
  const geohashRange = geohashQueryBounds([lat, lng], radius);
  
  const candidates = [];
  for (const b of geohashRange) {
    const snap = await db.collection('users')
      .orderBy('geoHash')
      .startAt(b[0])
      .endAt(b[1])
      .get();
    candidates.push(...snap.docs);
  }
  
  // lat/lng se NE shrani — samo za ta query, potem GC
  return candidates.filter(doc => 
    haversine([lat, lng], [doc.data().geoHash_lat, doc.data().geoHash_lng]) <= radius
  );
}
```

### Firestore Schema — geohash
```javascript
// users/{uid} — ephemeral, 30-min TTL
geoHash: "u2xk7p",                // geohash level 7 (~76m × 38m)
geoHashUpdatedAt: Timestamp,
geoHashExpiresAt: Timestamp       // +30 min → Scheduled cleanup
// OPOMBA: geohash je reverzibilen do ~76m natančnosti — NI točna koordinata
// Privacy Policy mora to opisati
```

### Paywall trigger copy
```
"[Ime] je bil/a v bližini, a izven tvojega brezplačnega radiusa 100m.
 S Pro bi zaznal/a nekoga v radiju 250m."
```

---

## F10 — Gym Mode

**Effort:** XL · **Zahteva:** F1 · **Founder required:** Info.plist permissions

### Tehnična arhitektura: Native Geofencing (Avtomatizacija)

Tukaj je podroben pregled vseh scenarijev, ki prikazuje, kako Native Geofencing deluje v praksi. Celoten sistem je zasnovan tako, da **naprava opravi vse delo**, strežnik pa ne ve ničesar, dokler uporabnik ne poda izrecnega soglasja.

#### Kako rešujemo GDPR, Zasebnost in Stroške?
* **GDPR & Zasebnost:** Točne GPS koordinate uporabnika se **nikoli** ne pošiljajo na naš backend. Lokacija se računa izključno znotraj varnega čipa na telefonu.
* **Stroški za backend:** Ko se uporabnik giblje po mestu, se na naš strežnik ne pošlje **niti en sam API klic**. Strežnik je vključen šele takrat, ko uporabnik dejansko aktivira Gym Mode (samo 1 Firestore zapis).

---

#### Scenarij 1: Aplikacija je popolnoma ugasnjena (Killed / Swiped away)
* **Poraba baterije:** Praktično 0 %.
* **Kaj se dogaja:** Operacijski sistem v ozadju pasivno spremlja bazne postaje in Wi-Fi omrežja. Naša aplikacija "spi" in ne porablja procesorskih moči.

#### Scenarij 2: Aplikacija je odprta, vendar Radar NI aktiven
* **Poraba baterije:** Normalna uporaba aplikacije.
* **Kaj se dogaja:** Geofencing sistem operacijskega sistema še vedno deluje pasivno v ozadju in čaka na vstop v fitnes.

#### Scenarij 3: Radar JE aktiven (aplikacija je v ozadju)
* **Poraba baterije:** Zmerna poraba (zaradi delovanja Bluetooth Low Energy skenerja).
* **Kaj se dogaja:** Aplikacija preko BLE išče druge telefone v bližini ter hkrati preko Geofence API-ja čaka na prihod v fitnes.

#### Scenarij 4: Uporabnik pride v fitnes in tam ostane 10 minut (App je v ozadju/ugasnjena)
1. **Vstop (0. minuta):** Uporabnik prečka navidezno mejo (radius 80 m) okoli fitnesa. Operacijski sistem zazna vstop in za 30 sekund **tiho prebudi** našo aplikacijo iz mirovanja.
2. **Zagon časovnika:** Aplikacija si lokalno zabeleži čas vstopa.
3. **Dwell preverjanje (10. minuta):** Ko mine 10 minut, operacijski sistem preveri, ali je uporabnik še vedno znotraj meje.
4. **Lokalno obvestilo:** Če je še vedno tam, aplikacija neposredno iz telefona (brez klica na strežnik!) sproži push obvestilo:
   * *»Si v [Ime Fitnesa]. Vklopiš Gym Mode?«*
5. **Zaključek:**
   * Če uporabnik obvestilo prezre: **0 API stroškov**.
   * Če uporabnik klikne "Vklopi": Aplikacija pošlje **en sam** zapis na backend, ki ga označi kot aktivnega v fitnesu za naslednji 2 uri.

S tem dosežemo popoln »Set and forget« mehanizem, ki ne segreva naprave in spoštuje zasebnost.

### GPS in Radar (Razlike v varčevanju z baterijo)

Za Radar (iskanje drugih uporabnikov v bližini) že uporabljamo GPS, vendar deluje na povsem drugačen način kot pri fitnesih.

#### 1. Gym Mode (Fiksne točke -> Geofencing)
* **Stavba fitnesa se ne premika.**
* Ker je to fiksna točka, delo v celoti prepustimo operacijskemu sistemu preko **pasivnega Geofencinga**. To ne porablja baterije.

#### 2. Radar (Premikajoče se točke -> GPS Geohashing)
* **Uporabniki se premikajo.** Tukaj operacijski sistem ne more vnaprej vedeti, kje se bosta srečala dva človeka, zato je potreben GPS.
* **Kako deluje omejitev razdalje (100 m / 250 m):**
  * Ko uporabnik **vklopi Radar**, aplikacija vsakih nekaj minut strežniku sporoči svojo trenutno lokacijo.
  * Strežnik nato izvede hitro ujemanje:
    * **Free paket:** Uporabniku prikaže samo tiste ljudi, ki so znotraj **100 m**.
    * **Premium paket:** Krog se razširi na **250 m**, kar pomeni bistveno več možnosti za hitro ujemanje.

#### Ključ za varčevanje z baterijo pri Radarju:
Radar deluje **samo takrat, ko ga uporabnik zavestno vklopi** (ko gre npr. v mesto in želi spoznavati ljudi). Ko ga ugasne, se sledenje lokaciji v trenutku popolnoma ustavi.

Tako imamo najboljše iz obeh svetov:
* **Gym Mode:** Popolnoma avtomatski (set-and-forget), brez porabe baterije.
* **Radar:** Ročno nadzorovan, porablja baterijo samo takrat, ko uporabnik to želi.

Prej je bila poraba okoli 2 % na uro, ker je deloval zgolj izjemno varčen Bluetooth (BLE). Če bi zdaj GPS pustili teči neprekinjeno z maksimalno natančnostjo (kot npr. pri Google Maps navigacija), bi poraba poskočila na 10–15 % na uro, telefon pa bi se začel močno greti.

#### Kako preprečimo praznjenje baterije?
1. **Zaznava znatnega premika (Significant Motion Changes):** GPS-a ne sprašujemo po koordinatah vsako minuto. Operacijskemu sistemu naročimo, naj nas prebudi samo takrat, ko zazna, da se je uporabnik premaknil za več kot npr. 50 metrov.
2. **Spanje ob mirovanju:** Če uporabnik sedi v pisarni ali kavarni, GPS popolnoma miruje in poraba je spet 0 %.

Z vsemi pametnimi triki bo poraba med aktivnim iskanjem narasla iz prejšnjih 2 % na **približno 3 do 4 % na uro**.


### Gym Mode UI in UX Pravila
* **Basic Tier:** Uporabnik ima status "Basic" (Free) uporabnika, razen če že ima kupljen Premium.
* **Vpogled v profile:** Free uporabniki vidijo samo "pill" (zaklenjeno), Premium pa polno kartico (razen če se z osebo ujamejo).
* **Avtomatski DND:** Vklopi se Do Not Disturb (DND) — brez proximity notifikacij med vadbo.
* **Interakcija (Quiet List):** Prikaže se tih seznam prisotnih, kjer lahko pošlješ "wave".
* **Zgodovina:** Ohrani se zgodovina vseh ljudi, ki si jih srečal v fitnesu.

### Session obnašanje
```
Gym Mode aktiven:
→ Prikaži vse Tremble userje v prostoru (matching threshold: 55%)
→ DND: supresiraj proximity notifikacije
→ Beleži vse prisotne v gymSessions dokument

Gym Mode konča (GEOFENCE EXIT ali ročno):

→ Push: "Workout done. [N] people were with you."
→ Summary screen — mini profili vseh prisotnih
→ Wave iz summary screena (ne med treningom)
```

### Firestore Schema
```javascript
// gymSessions/{sessionId}
{
  gymPlaceId: "ChIJ...",
  gymName: "Gold's Gym Ljubljana",
  date: "2026-05-15",          // string date za grouping
  participants: [
    { uid: "abc123", arrivedAt: Timestamp, leftAt: Timestamp | null }
  ],
  active: true,
  createdAt: Timestamp,
  expiresAt: Timestamp          // +24h — auto cleanup
}

// users/{uid}
gymMode: {
  active: true,
  sessionId: "sessionId",
  gymPlaceId: "ChIJ...",
  startedAt: Timestamp
}

savedGym: {                     // persistent — iz F1
  placeId, name, lat, lng
}
```

### Upstash Redis
```
gym:session:{placeId}:{date}    → hash {uid: arrivalTimestamp}    TTL: 8ur
gym:user:{uid}:active           → sessionId string                TTL: 8ur
```

### Cloud Functions
```javascript
// Ob aktivaciji
exports.onGymModeActivate = onCall(async (req) => {
  const { gymPlaceId } = req.data;
  const uid = req.auth.uid;
  const today = new Date().toISOString().split('T')[0];
  const sessionId = `${gymPlaceId}_${today}`;
  
  // Upsert session
  await db.collection('gymSessions').doc(sessionId).set({
    gymPlaceId, date: today, active: true,
    createdAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromDate(new Date(Date.now() + 24 * 60 * 60 * 1000))
  }, { merge: true });
  
  await db.collection('gymSessions').doc(sessionId).update({
    participants: FieldValue.arrayUnion({ uid, arrivedAt: Timestamp.now(), leftAt: null })
  });
  
  // Redis
  await redis.hset(`gym:session:${gymPlaceId}:${today}`, uid, Date.now());
  await redis.expire(`gym:session:${gymPlaceId}:${today}`, 28800); // 8ur
  await redis.set(`gym:user:${uid}:active`, sessionId, { ex: 28800 });
  
  await db.collection('users').doc(uid).update({
    gymMode: { active: true, sessionId, gymPlaceId, startedAt: Timestamp.now() }
  });
});

// Ob deaktivaciji
exports.onGymModeDeactivate = onCall(async (req) => {
  const uid = req.auth.uid;
  const user = await db.collection('users').doc(uid).get();
  const { sessionId } = user.data().gymMode;
  
  // Zabeleži odhod
  const session = await db.collection('gymSessions').doc(sessionId).get();
  const updatedParticipants = session.data().participants.map(p =>
    p.uid === uid ? { ...p, leftAt: Timestamp.now() } : p
  );
  
  await db.collection('gymSessions').doc(sessionId).update({ participants: updatedParticipants });
  await db.collection('users').doc(uid).update({ gymMode: FieldValue.delete() });
  
  // Redis cleanup
  await redis.hdel(`gym:session:${gymPlaceId}:${today}`, uid);
  await redis.del(`gym:user:${uid}:active`);
  
  // Pošlji summary notification
  const count = updatedParticipants.length - 1; // minus self
  await sendPushNotification(uid, `Workout done. ${count} people were with you.`);
});

// Scheduled — vsako uro
exports.expireGymSessions = onSchedule('every 60 minutes', async () => {
  const expired = await db.collection('gymSessions')
    .where('expiresAt', '<', Timestamp.now())
    .where('active', '==', true)
    .get();
  
  const batch = db.batch();
  expired.docs.forEach(doc => batch.update(doc.ref, { active: false }));
  await batch.commit();
});
```

---

## F11 — Smoking / Lifestyle Preferences

**Effort:** M · **Legal review required**

### Pravni vidik — preberi pred implementacijo

Smoking habits so v SI/HR pravnem okviru lifestyle podatki, ne zdravstveni podatki (za razliko od medicinskih stanj). Kljub temu:
1. Marihuána / fuge: legalno vprašanje. V Sloveniji dekriminalizirana (ne legalna). V Hrvaški kaznivo dejanje. **Preden dodaš "weed" kot opcijo, se posvetuj s pravnikom za oba trga.** Alternativa: "cannabis" kot nevtralen izraz ali ga izpusti iz prvega launcha.
2. GDPR: lifestyle preference je osebni podatek — zahteva consent, ki je že pokrit z obstoječim GDPR consent flowom. Ni posebne zahteve za DPIA, ampak Privacy Policy mora omeniti lifestyle preference processing.

### Firestore Schema
```javascript
// users/{uid}
smokingPreferences: ["cigarettes", "vape", "iqos"],  // array — multi-select
// Možne vrednosti: "none" | "cigarettes" | "vape" | "iqos" | "shisha" | "joints" | "cannabis"

// Matching filter
smokingFilter: "any" | "smokers_only" | "non_smokers" | "match_preference"
// "match_preference" → pokaži samo userje z vsaj eno skupno preferenco ali oba "none"
```

### Flutter UI — Onboarding
```dart
// Multi-select chip grid — po obstoječem interest selection patternu
const smokingOptions = [
  SmokingOption(id: 'none',        label: 'None',      icon: '🚫'),
  SmokingOption(id: 'cigarettes',  label: 'Cigarettes'),
  SmokingOption(id: 'vape',        label: 'Vape'),
  SmokingOption(id: 'iqos',        label: 'IQOS'),
  SmokingOption(id: 'shisha',      label: 'Shisha'),
  SmokingOption(id: 'joints',      label: 'Joints'),  // legal review za SI/HR
  // 'cannabis' kot alternativa za nevtralnejši izraz
];
// Selekcija "None" → deselektira vse ostale
// Selekcija česar koli → deselektira "None"
```

### Matching logika
```javascript
// V Cloud Function — opcijsko, ne blokira match
function smokingCompatible(user1Prefs, user2Prefs, filter) {
  if (filter === 'any') return true;
  if (filter === 'non_smokers') return user2Prefs.includes('none');
  if (filter === 'smokers_only') return !user2Prefs.includes('none');
  if (filter === 'match_preference') {
    // Vsaj ena skupna ali oba none
    const overlap = user1Prefs.filter(p => user2Prefs.includes(p));
    return overlap.length > 0;
  }
  return true;
}

---

## F12 — Pulse Intercept (Assistance & Visual Aid)

**Effort:** L · **Risk:** HIGH (PII, Ephemeral Media)

### Problem
Med "Trembling Window" (F4) uporabniki včasih potrebujejo dodatno pomoč za fizično lociranje partnerja, ne da bi se pri tem zapletli v klasičen chat.

### Rešitev
Dva atomska gumba na Radar overlay-u:
1. **[Send Phone]**: Pošlje svojo številko za neposreden klic (asistenca).
2. **[Send Photo]**: Pošlje "view-once" sliko okolice (orientacija).

### Onboarding & GDPR
* **Onboarding:** Dodan `PhoneStep`. Če uporabnik preskoči, gumb "Send Phone" kasneje ni na voljo.
* **Privacy Policy:** Posodobitev za hrambo PII (tel. št.) in efemerno obdelavo slik.
* **Zero Chat Policy:** Nobenega prostega vnosa besedila. Komunikacija je omejena na gumbe in slike.

### Firestore Schema
```javascript
// users/{uid}
phoneNumber: "+386..." | null

// interactions/{id}
{
  fromUid: "...",
  toUid: "...",
  type: "phone" | "photo_once",
  payload: "+386..." | "storage_path",
  createdAt: ServerTimestamp,
  viewedAt: Timestamp | null,
  expiresAt: Timestamp // 10 min TTL
}
```

### Tehnična izvedba (Snap-style)
* **Photo Storage:** Slike se nalagajo v ločen bucket z minimalnim TTL.
* **View Once Logic:** Cloud Function ob posodobitvi `viewedAt` (ko prejemnik odpre sliko) takoj izbriše datoteko iz storage-a in zapre dostop.
* **Notifications:** High-priority push: *"Ana ti je poslala svojo številko za pomoč! 📞"* ali *"Ana ti pošilja sliko okolice! 📷"*.

---

## Appendix A — Firestore Schema (celoten seznam sprememb)

| Kolekcionarka / Polje | Tip spremembe | Zahtevano za |
|---|---|---|
| users/{uid}.homeLocation | STRING → LocationData objekt | F1 |
| users/{uid}.locations[] | Nov array field | F1, F10 |
| users/{uid}.savedGym | Nov field | F10 |
| users/{uid}.gymMode | Nov field (ephemeral) | F10 |
| users/{uid}.runMode | Nov field (ephemeral) | F6 |
| users/{uid}.activeEventId | Nov field | F2 |
| users/{uid}.activePromo | Nov field | F7 |
| users/{uid}.geoHash | Nov field (ephemeral) | F9 |
| users/{uid}.smokingPreferences | Nov array field | F11 |
| users/{uid}.smokingFilter | Nov field | F11 |
| matches/{matchId}.matchType | Nov enum field | F3 |
| matches/{matchId}.matchContext | Nov objekt field | F3 |
| events/{eventId} | Nova kolekcionarka | F2 |
| gymSessions/{sessionId} | Nova kolekcionarka | F10 |
| promotions/{promoId} | Nova kolekcionarka | F7 |
| users/{uid}/activityData/{id} | Nova subkolekcija | F5 |
| users/{uid}/integrations/{provider} | Nova subkolekcija | F5 |
| heatmapAggregates/{geohash} | Nova kolekcionarka | F5 |

**KRITIČNO:** Vsaka nova kolekcionarka zahteva Firestore Security Rule pred deployom. Privzeto je `deny all`.

---

## Appendix B — Upstash Redis Key Map

| Key pattern | Tip | TTL | Za |
|---|---|---|---|
| event:active:{eventId}:users | Sorted Set | do endsAt | F2 |
| hm:tile:{zoom}:{geohash} | String (JSON) | 300s | F5 |
| hm:filter:running:{geohash} | String (JSON) | 300s | F5 |
| hm:filter:events:{geohash} | String (JSON) | 300s | F5 |
| runners:active:{city_geohash} | Sorted Set | 30min/member | F6 |
| runners:nearby:{userId} | Sorted Set | 60s | F6 |
| gym:session:{placeId}:{date} | Hash | 8ur | F10 |
| gym:user:{uid}:active | String | 8ur | F10 |

---

## Appendix C — GCP Checklist

| Akcija | GCP Pot | Projekt |
|---|---|---|
| Enable Maps SDK for Android | APIs & Services → Enable | dev + prod |
| Enable Maps SDK for iOS | APIs & Services → Enable | dev + prod |
| Enable Places API (New) | APIs & Services → Enable | dev + prod |
| Enable Geocoding API | APIs & Services → Enable | dev + prod |
| API Key Android (restricted) | Credentials → Create | dev + prod |
| API Key iOS (restricted) | Credentials → Create | dev + prod |
| Secret: MAPS_KEY_ANDROID | Secret Manager → Create | dev + prod |
| Secret: MAPS_KEY_IOS | Secret Manager → Create | dev + prod |
| Billing Alert $50/mesec | Billing → Budgets & Alerts | prod |

---

## Appendix D — Stroškovni model pri 50.000 DAU

| Postavka | Mesečno (optimizirano) |
|---|---|
| Cloud Functions compute | ~$35 |
| Firestore reads (geohash + matching) | ~$45 |
| Firestore writes | ~$20 |
| Places API (z session tokeni) | ~$200–500 |
| Upstash Redis | ~$30 |
| Cloudflare R2 (avatarji) | ~$5 |
| **Skupaj** | **~$335–635/mesec** |

Revenue pri 50k DAU, 8% payer conversion, €7.99/mes ≈ **$25.000/mesec**

Infrastruktura = ~4% revenue. Zdravo — SaaS benchmark je pod 20%.

**Največje tveganje:** Places API brez session tokenov = $5.100/mesec. Z session tokeni = $200–500/mesec. Implementiraj session token model od prvega dne.



---

## Store Submission & Release Pipeline

# Tremble — Store Submission Master Plan
Date: April 2026
Target: TestFlight internal beta → App Store + Play Store submission

## ZAPOREDJE

KORAK 1 — Privacy Fix (dev)          ✅ DONE 2026-04-24
KORAK 2 — Privacy Fix (prod)         ✅ DONE 2026-04-24
KORAK 3 — Docs update                ✅ DONE 2026-04-24
KORAK 4 — iOS BLE background         🔴 NEXT (Ti + Martin, 3–5 dni)
KORAK 5 — Android BLE background     🔴 PENDING (Martin, 1–2 dni)
KORAK 6 — D-37 Map toggle test       🔴 PENDING (Martin, 1 dan)
KORAK 7 — App Store metadata rewrite 🔴 PENDING (Ti, 2 uri)
KORAK 8 — TestFlight internal beta   🔴 PENDING (oba, po 4+5)
KORAK 9 — Store submission           🔴 PENDING (oba)

## KORAK 4 — iOS BLE Background State Restoration
Claude CLI prompt:

Read CLAUDE.md fully. Then read tasks/context.md, tasks/blockers.md, tasks/lessons.md, and tasks/decisions/ folder. Also read lib/src/core/ble_service.dart and lib/src/core/background_service.dart in full.

TASK: Plan iOS CoreBluetooth background state restoration for ADR-001.

CONTEXT:
- flutter_blue_plus 2.2.1 is in pubspec.yaml
- BleService is correctly implemented for foreground scanning
- background_service.dart explicitly does NOT import BleService — correct, BLE must run on main isolate
- iOS requires UIBackgroundModes bluetooth-central in Info.plist
- flutter_blue_plus 2.x supports state restoration but requires explicit configuration

REQUIRED:
1. Read ios/Runner/Info.plist — report existing UIBackgroundModes entries
2. Read pubspec.lock — confirm exact flutter_blue_plus version
3. Produce a 5-step plan per CLAUDE.md orchestral loop format
4. Risk level: HIGH — Info.plist changes require founder approval before any code is written
5. Do not modify any files — plan only

## KORAK 5 — Android BLE Background
Claude CLI prompt:

Read CLAUDE.md fully. Then read tasks/context.md and lib/src/core/background_service.dart.

TASK: Verify Android BLE background scanning on physical device.

REQUIRED:
1. Read android/app/src/main/AndroidManifest.xml — report all bluetooth and location permissions
2. Verify foreground service configuration in background_service.dart
3. Produce test checklist for Martin (Samsung S25 Ultra)
4. Risk level: HIGH for any AndroidManifest.xml changes — founder approval required
5. Do not modify any files — audit and checklist only

## KORAK 6 — D-37 Map Toggle Test
Martin: Run dev flavor on Samsung S25 Ultra. Navigate to map screen. Test all 3 states of the toggle. Report in tasks/debt.md D-37.

## KORAK 7 — App Store Metadata Rewrite
Claude CLI prompt:

Read CLAUDE.md fully. Then read tasks/metadata_draft.md and tasks/store_submission_plan.md.

TASK: Rewrite App Store and Google Play metadata for store submission.

CONSTRAINTS:
- Apple subtitle max 30 chars — descriptive, not brand language
- Apple description must be clear to a reviewer who has never heard of Tremble
- Google Play short description max 80 chars
- Brand voice rules apply: no hype, no revolutionary, no emoji in headlines
- Privacy claims must reflect SEC-002 fix: location is architecturally never stored

PRODUCE:
1. iOS: Title (30 chars), Subtitle (30 chars), Promotional Text (170 chars), Description (800–1000 words)
2. Google Play: Title (50 chars), Short Description (80 chars), Full Description
3. Keywords list for both stores
4. App Store privacy nutrition label answers

Save to tasks/metadata_draft_v2.md

## KORAK 8 — TestFlight Internal Beta
Predpogoji pred začetkom:
- iOS BLE background works on physical device ✅
- Android BLE background verified on Samsung S25 Ultra ✅
- Apple Developer Account ($99) purchased ✅
- App Store Connect app record created ✅

Claude CLI prompt:

Read CLAUDE.md deploy pipeline section and tasks/context.md.

TASK: Prepare TestFlight internal beta build checklist.

1. Run flutter analyze — must be zero issues
2. Run flutter test — must pass
3. Produce exact build command for iOS release build
4. List all App Store Connect pre-submission checklist items
5. Do NOT trigger any deployment — checklist only. Founder executes.

## FOUNDER ACTION ITEMS (blokirajo napredek)
| Akcija | Kdaj | Zakaj |
|--------|------|-------|
| Apple Developer Account ($99) | Pred Korakom 8 | Brez tega ni TestFlight |
| AMS Solutions d.o.o. registracija | ASAP | Unblocks Phase 8 RevenueCat |

## REALNI TIMELINE
| Teden | Naloge |
|-------|--------|
| Teden 1 (zdaj) | Koraki 1–3 ✅ DONE |
| Teden 2 | Korak 4 iOS BLE + Korak 5 Android BLE |
| Teden 3 | Korak 6 map test + Korak 7 metadata |
| Teden 4 | Korak 8 TestFlight — če Apple account kupljen |
| Teden 5–6 | Beta perioda |
| Maj/Junij 2026 | Store submission |


---

## iOS Lock Screen Radar Widget Implementation

# Handoff — Aleksandar: iOS Radar Widget + Control Center Toggle

**Date:** 2026-04-26
**From:** Martin
**To:** Aleksandar
**Plan ID:** 20260426-ios-radar-widget
**Risk Level:** HIGH (native iOS targets, entitlements, App Group, App Intents)
**Founder Approval Required:** YES (Martin) — pridobi pred Step 1
**Branch:** `feature/ios-radar-widget`

---

## Kontekst

Android stran je narejena: QS Tile (`RadarTileService.kt`) + home-screen widget (`RadarWidgetProvider`) + state bridge (`RadarStateBridge` → SharedPreferences, ključ `radar_active`).

Naloga: ekvivalent na iOS, dva surface-a:
1. **Lock Screen accessory widget** (iOS 16.1+, krog)
2. **Control Center toggle** (iOS 18.0+, `ControlWidget`)

State mora biti shared med Flutter app, Lock Screen widget in Control Center → **App Group + UserDefaults**.

ADR-001 (BLE wiring) je še vedno odprt — to delo je **neodvisno**: widget samo flippa flag in deep-linka v app. End-to-end QA pride šele po ADR-001 resolu.

---

## OBJECTIVE

iOS uporabnik lahko vklopi/izklopi Tremble Radar iz (a) Lock Screen circular widgeta in (b) iOS 18 Control Center toggla. Stanje je sinhrono med oboje + Flutter UI prek App Group `UserDefaults`.

---

## SCOPE

**Novo (dodaj):**

- `ios/TrembleRadarWidget/` — Widget Extension target (deployment iOS 16.1)
- `ios/TrembleRadarWidget/RadarStateStore.swift` — App Group `UserDefaults` reader/writer (target membership: Runner **in** TrembleRadarWidget)
- `ios/TrembleRadarWidget/RadarToggleIntent.swift` — `AppIntent`
- `ios/TrembleRadarWidget/RadarLockScreenWidget.swift` — `accessoryCircular` widget
- `ios/TrembleRadarWidget/RadarControlWidget.swift` — iOS 18 `ControlWidget` + `SetValueIntent`
- `ios/TrembleRadarWidget/Info.plist`, `TrembleRadarWidget.entitlements`
- `ios/Runner/Runner.entitlements` — dodaj App Group
- `lib/src/core/radar_state_bridge_ios.dart` — Dart writer prek MethodChannel
- `ios/Runner/AppDelegate.swift` — registriraj MethodChannel + URL handler

**NE spreminjaj:**

- `lib/src/core/background_service.dart` (radar lifecycle ostane v main isolate)
- Firebase config, Cloud Functions, security rules
- Android tile / widget kodo
- `flutter_blue_plus` wiring (ADR-001)

---

## STEP 1 — Xcode setup checklist

V `ios/Runner.xcworkspace`. Vsako točko atomarno.

1. **Capabilities → Runner target:**
   - Signing & Capabilities → `+ Capability` → **App Groups**
   - Dodaj **dva** group ID-ja (per-flavor isolation, glej Risk #1):
     - `group.com.pulse.radar` (Debug-dev)
     - `group.tremble.dating.app.radar` (Release-prod)
   - Preveri da je `Runner.entitlements` updated.

2. **Create Widget Extension target:**
   - File → New → Target → **Widget Extension**
   - Product Name: `TrembleRadarWidget`
   - Bundle ID per-config:
     - Debug-dev: `com.pulse.TrembleRadarWidget`
     - Release-prod: `tremble.dating.app.TrembleRadarWidget`
   - Include Live Activity: **No**
   - Include Configuration App Intent: **Yes**
   - Embed in Application: `Runner`
   - Activate scheme: **No**

3. **Capabilities → TrembleRadarWidget target:**
   - Dodaj iste App Group ID-je kot Runner.
   - Preveri `TrembleRadarWidget.entitlements`.

4. **Deployment targets:**
   - TrembleRadarWidget: iOS **16.1** minimum
   - Runner: pusti kot je

5. **Build settings (TrembleRadarWidget):**
   - Swift version match z Runner
   - `PRODUCT_BUNDLE_IDENTIFIER` per-config (glej zgoraj)
   - **NE** dodajaj v Podfile — extension naj ostane Pod-free

6. **Info.plist (TrembleRadarWidget):**
   - `NSExtension → NSExtensionPointIdentifier = com.apple.widgetkit-extension`
   - `NSSupportsLiveActivities = NO`
   - **Brez** Bluetooth/Location keys

7. **Target Membership:** `RadarStateStore.swift` mora biti checked za **OBA** targeta (Runner + TrembleRadarWidget).

---

## STEP 2 — App Group state contract

| Key | Type | Owner | Read by |
|-----|------|-------|---------|
| `radar_active` | `Bool` | Flutter (main isolate) on toggle, AppIntent on widget tap | Lock Screen Widget, Control Widget, Flutter at boot |
| `radar_last_changed` | `Double` (epoch s) | Isto | Widget za "since 19:42" subtitle |

Group ID izberi runtime z `#if DEBUG`:

```swift
enum RadarStateStore {
    static var appGroup: String {
        #if DEBUG
        return "group.com.pulse.radar"
        #else
        return "group.tremble.dating.app.radar"
        #endif
    }
    // ...
}
```

---

## STEP 3 — Swift reference koda

### `RadarStateStore.swift` (skupen Runner + Widget target)

```swift
import Foundation
import WidgetKit

enum RadarStateStore {
    static var appGroup: String {
        #if DEBUG
        return "group.com.pulse.radar"
        #else
        return "group.tremble.dating.app.radar"
        #endif
    }
    static let activeKey = "radar_active"
    static let changedKey = "radar_last_changed"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }

    static var isActive: Bool {
        defaults?.bool(forKey: activeKey) ?? false
    }

    static func setActive(_ value: Bool) {
        defaults?.set(value, forKey: activeKey)
        defaults?.set(Date().timeIntervalSince1970, forKey: changedKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
```

### `RadarToggleIntent.swift` (Lock Screen)

```swift
import AppIntents
import WidgetKit

struct RadarToggleIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Tremble Radar"
    static var description = IntentDescription("Turn the Tremble proximity radar on or off.")
    static var openAppWhenRun: Bool = true   // glej Risk #2

    @Parameter(title: "Turn on")
    var turnOn: Bool

    init() {}
    init(turnOn: Bool) { self.turnOn = turnOn }

    func perform() async throws -> some IntentResult {
        RadarStateStore.setActive(turnOn)
        return .result(opensIntent: OpenURLIntent(
            URL(string: "tremble://radar?active=\(turnOn ? 1 : 0)")!
        ))
    }
}
```

### `RadarLockScreenWidget.swift`

```swift
import WidgetKit
import SwiftUI
import AppIntents

struct RadarEntry: TimelineEntry {
    let date: Date
    let isActive: Bool
}

struct RadarProvider: TimelineProvider {
    func placeholder(in context: Context) -> RadarEntry {
        RadarEntry(date: .now, isActive: false)
    }
    func getSnapshot(in context: Context, completion: @escaping (RadarEntry) -> Void) {
        completion(RadarEntry(date: .now, isActive: RadarStateStore.isActive))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<RadarEntry>) -> Void) {
        let entry = RadarEntry(date: .now, isActive: RadarStateStore.isActive)
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct RadarLockScreenView: View {
    let entry: RadarEntry

    var body: some View {
        Button(intent: RadarToggleIntent(turnOn: !entry.isActive)) {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: entry.isActive
                    ? "dot.radiowaves.left.and.right"
                    : "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 18, weight: .semibold))
            }
            .widgetAccentable()
        }
        .buttonStyle(.plain)
    }
}

struct RadarLockScreenWidget: Widget {
    let kind = "RadarLockScreenWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RadarProvider()) { entry in
            RadarLockScreenView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Tremble Radar")
        .description("Toggle radar from your lock screen.")
        .supportedFamilies([.accessoryCircular])
    }
}
```

### `RadarControlWidget.swift` (iOS 18)

```swift
import AppIntents
import WidgetKit
import SwiftUI

@available(iOS 18.0, *)
struct RadarControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "RadarControlWidget") {
            ControlWidgetToggle(
                "Tremble Radar",
                isOn: RadarStateStore.isActive,
                action: RadarSetActiveIntent()
            ) { isOn in
                Label(
                    isOn ? "Radar On" : "Radar Off",
                    systemImage: isOn
                        ? "dot.radiowaves.left.and.right"
                        : "antenna.radiowaves.left.and.right.slash"
                )
            }
        }
        .displayName("Tremble Radar")
        .description("Quickly toggle proximity radar.")
    }
}

@available(iOS 18.0, *)
struct RadarSetActiveIntent: SetValueIntent {
    static var title: LocalizedStringResource = "Set Tremble Radar"
    static var openAppWhenRun: Bool = true   // Risk #2

    @Parameter(title: "Active")
    var value: Bool

    init() {}

    func perform() async throws -> some IntentResult {
        RadarStateStore.setActive(value)
        return .result(opensIntent: OpenURLIntent(
            URL(string: "tremble://radar?active=\(value ? 1 : 0)")!
        ))
    }
}
```

### Widget Bundle entry point

```swift
@main
struct TrembleWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        RadarLockScreenWidget()
        if #available(iOS 18.0, *) { RadarControlWidget() }
    }
}
```

---

## STEP 4 — AppDelegate: MethodChannel + URL handler

V `ios/Runner/AppDelegate.swift`:

```swift
override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
        name: "tremble.dating.app/radar_state",
        binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
        if call.method == "setRadarActive",
           let args = call.arguments as? [String: Any],
           let active = args["active"] as? Bool {
            RadarStateStore.setActive(active)
            result(nil)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}

override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
) -> Bool {
    // Forward `tremble://radar?active=…` v Flutter (app_links plugin pickta).
    return super.application(app, open: url, options: options)
}
```

> Pomembno: `RadarStateStore.swift` mora imeti **Target Membership** Runner + TrembleRadarWidget (oboje).

---

## STEP 5 — Flutter / Dart bridge

`shared_preferences_foundation` ne piše v App Group suite. Uporabi MethodChannel.

### `lib/src/core/radar_state_bridge_ios.dart`

```dart
import 'dart:io';
import 'package:flutter/services.dart';

class RadarStateBridgeIos {
  static const _channel = MethodChannel('tremble.dating.app/radar_state');

  static Future<void> write(bool active) async {
    if (!Platform.isIOS) return;
    await _channel.invokeMethod('setRadarActive', {'active': active});
  }
}
```

### Wire up v radar toggle controllerju

Kjerkoli se v Flutter app pokliče Android `RadarStateBridge` (MethodChannel za Android), dodaj **vzporedno** še `RadarStateBridgeIos.write(active)`. Oba klica naj bosta v isti tranzakciji ko user flippa toggle v UI.

### Deep link handler (Dart)

Kjer obstaja app_links / uri listener:

```dart
if (uri.scheme == 'tremble' && uri.host == 'radar') {
  final active = uri.queryParameters['active'] == '1';
  await RadarStateBridgeIos.write(active);
  if (active) {
    await ref.read(radarControllerProvider).start();
  } else {
    await ref.read(radarControllerProvider).stop();
  }
}
```

Če app_links handlerja še ni → preveri `lib/src/core/` ali router; če manjka, dodaj minimalno listener v `main.dart` (vprašaj Martina).

---

## RISKS & TRADEOFFS — preberi pred kodiranjem

**Risk #1 — App Group per-flavor isolation.**
Po CLAUDE.md "no cross-contamination": dva ID-ja, dev/prod ločena. Implementirano prek `#if DEBUG` v `RadarStateStore`. Entitlements morajo vsebovati **oba** ID-ja na obeh targetih.

**Risk #2 — iOS background execution iz Intenta.**
Za razliko od Androida iOS extension **ne sme** držati BLE scana ali Firebase write-a. AppIntent ne more direktno startati CoreLocation/BLE — **mora** zbudit host app. Zato `openAppWhenRun = true` + deep link `tremble://radar?active=…`. To je nujno; ni workaround-a.

**Risk #3 — Tap latenca.**
Lock Screen Button-with-Intent na cold launch traja 1–3s. View naj flippa state takoj iz `entry.isActive` po `setActive`, da percepcija ostane snappy.

**Risk #4 — Control Widget je iOS 18+.**
`@available(iOS 18.0, *)` gate. Lock widget pokriva 16.1+. Brez fallback breme.

**Risk #5 — Privacy review.**
"Radar on/off" tekst je viden na lock screenu. Android tile že uporablja "Radar" — verjetno OK, ampak označi v PR opisu za Martin/legal sign-off.

**Risk #6 — TestFlight gated by ADR-001.**
Merge je možen neodvisno, ampak end-to-end test (BLE actually scanning) šele po ADR-001. To dokumentiraj v PR.

---

## VERIFICATION (preden odpreš PR)

```bash
flutter analyze                                                        # 0 issues
flutter test                                                            # green
flutter build ipa --flavor dev --dart-define=FLAVOR=dev                # success
```

**Manual on physical iPhone (dev flavor):**

1. Install dev build, toggle radar v app → Lock Screen widget reflectira state v ≤2s.
2. Add widget na lock screen → tap → app foregrounda, radar starta; tap ponovno → stop.
3. iOS 18 device: dodaj Control Center toggle → toggle → state sync med UI/widget/CC.
4. Force-quit Tremble → toggle iz lock widgeta → cold launch + radar start.
5. Switch flavor dev↔prod → preveri da App Group ni shared (state separate).

**Rule #1:** vsak `flutter build` / `flutter run` mora imeti `--flavor`. Brez izjem.

---

## Plan execution order (eden commit per komponento)

1. Branch `feature/ios-radar-widget` iz `main`.
2. Xcode setup (Step 1) → commit: `chore(ios): add TrembleRadarWidget extension target + App Groups`
3. Swift files (Step 3) → commit: `feat(ios): RadarStateStore + AppIntent + Lock Screen widget`
4. Control Widget (iOS 18) → commit: `feat(ios): Control Center toggle (iOS 18 ControlWidget)`
5. AppDelegate channel + URL forward (Step 4) → commit: `feat(ios): MethodChannel + URL handler for radar state`
6. Dart bridge + toggle wire-up (Step 5) → commit: `feat(flutter): RadarStateBridgeIos + deep-link handler`
7. Update `tasks/context.md` handoff blok + dodaj morebitne nove `lessons.md` rule-e.
8. Open PR proti `main`, taggaj Martina za sign-off (HIGH risk per CLAUDE.md).

---

## Vprašanja preden začneš

- [ ] Martin OK z dvema App Group ID-jema (dev/prod) ali enim?
- [ ] Obstaja že app_links listener v Dart kodi? (preveri `lib/src/core/`, router)
- [ ] Ali naj widget kaže "Radar" v slovenščini ali angleščini? (Android trenutno uporablja `R.string.qs_tile_label`)

Ko končaš → posodobi `tasks/context.md` z handoff blokom in pingaj Martina za review.


---

## App Store Metadata Draft

# Tremble App Store & Play Store Metadata Draft

## App Details
- **Name**: Tremble
- **Subtitle**: Find nearby signals.
- **Category**: Social Networking / Dating
- **Keywords**: proximity, dating, nearby, signal, bluetooth, real-world, connection

## Promotional Text
Stop swiping. Start sensing. Tremble is the tool for real-world proximity discovery.

## Description
Tremble is not a game. It is a technical tool designed for proximity-based human connection.

We have eliminated the digital noise of modern dating. No endless swiping. No performative profiles. No infinite chat loops. Tremble exists to get you off your phone and into the real world.

### How it works:
1. **Signal Calibration**: Set your preferences and let Tremble run in the background.
2. **Passive Discovery**: Using Bluetooth Low Energy (BLE), Tremble passively scans for other signals in your immediate vicinity.
3. **The Radar**: When a mutual signal is detected, the Radar activates.
4. **The Ritual**: You have 30 minutes to find each other in the real world. The app provides a proximity signal, not a GPS coordinate. Use your senses.

### Core Philosophy:
- **Stoic Utility**: An interface designed for clarity and speed, not engagement.
- **Anti-Hype**: We don't use algorithms to keep you scrolling. We use technology to help you meet.
- **Signal, Not Noise**: Every interaction is grounded in physical proximity.

## Privacy & Permissions
Tremble respects your signal. 
- **Bluetooth**: Required for passive proximity detection.
- **Location**: Required to calibrate signal density and ensure accurate discovery.
- **Data**: Your data is yours. We use it only to facilitate the connection ritual.

---
*Drafted: 2026-04-23*


---

## Agent Routing Rules (MPC)

```yaml
# MASTER PROJECT CONTROLLER (MPC Workflow) — Agent Router
version: "2.0-Mobile"
meta:
  name: "MASTER PROJECT CONTROLLER (MPC Workflow) — Agent Router (Tremble App)"
  maintained_by: "platform/automation"
  last_modified: "2026-03-31"
  notes: >
    The Dispatcher reads this config to auto-assign agents and enforce sequencing.
    HIGH RISK tasks (Native Config, Permissions, BLE) pause for founder approval.

task_schema:
  required:
    - plan_id
    - title
    - risk_level
    - affected_components
  properties:
    risk_level:
      type: string
      enum: [low, medium, high, critical]
      description: >
        low: UI tweaks, copy logic, stateless widgets.
        medium: state management, new screens, complex UI logic.
        high: Native iOS/Android changes, BLE logic, Cloud Functions, hardware permissions.
        critical: Prod Data migrations, Payment logic, Firebase Auth rules.

agents:
  architect:
    role: "Architect"
    responsibilities:
      - "Validate Flutter/Firebase architecture against system_map.md"
  researcher:
    role: "Researcher"
    responsibilities:
      - "Evaluate Flutter packages and native (Swift/Kotlin) dependencies"
  implementer:
    role: "Implementer"
    responsibilities:
      - "Write atomic Dart code, Flutter tests, and apply flavors"
  auditor:
    role: "Security / Auditor"
    responsibilities:
      - "Verify Firebase Rules, secure local storage, permissions"
  qa:
    role: "QA / Mobile Tester"
    responsibilities:
      - "Test dev flavor, check for UI jank, widget overflow, platform parity"

routing_rules:
  - id: ROUTE-LOW
    match: { risk_level: low }
    route: [implementer, qa]
    founder_approval_required: false

  - id: ROUTE-MEDIUM
    match: { risk_level: medium }
    route: [architect, implementer, qa]
    founder_approval_required: false

  - id: ROUTE-HIGH
    match: { risk_level: high }
    route: [architect, researcher, implementer, auditor, qa]
    founder_approval_required: true
    founder_approval_gate: "after_architect"

  - id: ROUTE-CRITICAL
    match: { risk_level: critical }
    route: [architect, researcher, implementer, auditor, qa]
    founder_approval_required: true
    additional_gates: ["post_auditor_founder_review"]

human_escalation_rules:
  - condition: "Task requires modifying native Info.plist or AndroidManifest.xml"
    action: "Require explicit Founder review."
  - condition: "Flutter analyze fails continuously"
    action: "Rollback and ask for assistance."

```

---

## Policy: Cost Governance

```yaml
version: "2.0"
meta:
  name: "MPC Workflow — Cost Management Policies"
  maintained_by: "platform/ops-team"
  last_reviewed: "2026-03-10"
  enforcement: "ci"

rules:
  # ── Cloud Functions ─────────────────────────────────────────────────────
  - id: COST-001
    title: "Cloud Function Invocation Limits"
    category: compute
    description: >
      Cloud Functions must be optimized to prevent runaway billing.
      Heavy tasks (like ML, image processing) must be queued or bounded.
    severity: high
    action: require_approval
    detector:
      type: code_scan
      patterns:
        - "pubsub\\.schedule\\(['\"]\\* \\* \\* \\* \\*" # Block per-minute cron jobs
    remediation: >
      Change cron jobs to run at most every 5-15 minutes unless strictly necessary.

  # ── Database Operations ──────────────────────────────────────────────────
  - id: COST-002
    title: "Firestore Read Minimization"
    category: database
    description: >
      Avoid fetching entire collections or unbounded queries.
      Queries must include a `limit()` clause.
    severity: medium
    action: warn
    detector:
      type: code_scan
      patterns:
        - "\\.get\\(\\)"
      required_companion:
        - "\\.limit\\("
    remediation: >
      Always paginate or add a strict `.limit()` when fetching documents from Firestore.

  # ── Third Party APIs ─────────────────────────────────────────────────────
  - id: COST-003
    title: "External API Cost Approval"
    category: paid_apis
    description: >
      Any new integration with a paid API (OpenAI, Stripe, Maps API) requires a documented cost estimate.
    severity: high
    action: block_merge_without_estimate
    detector:
      type: pr_body_contains
      required_phrases:
        - "Monthly cost:"
    remediation: >
      Provide a breakdown of API usage per 1000 users in the PR description.

policy_tuning:
  critical: block_merge
  high: require_approval
  medium: warn
  low: warn

```

---

## Policy: Design & Visuals

```yaml
# Visual Design Policies
style_contract:
  - Tremble UI is dark-themed by default.
  - Glassmorphism is used strategically (e.g. `GlassCard`), not everywhere to avoid jank.
  - Google Fonts ONLY — no generic system fonts. Use the brand tokens.
  - Animations must be fluid (radar pulse, match reveal).
  - No generic Material default blue (#2196F3) — use Tremble brand tokens.
  - Icons should typically be sharp and premium, not generic outline defaults.

```

---

## Policy: Privacy & GDPR

```yaml
version: "2.0"
meta:
  name: "MPC Workflow — Privacy & Data Protection Policies"
  maintained_by: "platform/compliance-team"
  last_reviewed: "2026-03-10"
  enforcement: "ci"
  notes: >
    Enforces GDPR and ZVOP-2 requirements globally across the codebase.
    Any violation of user consent models or data minimization immediately blocks merges.

rules:
  # ── ZVOP-2 / GDPR Age Requirements ───────────────────────────────────────
  - id: PRIV-001
    title: "Strict 18+ Age Gate"
    category: user_eligibility
    description: >
      The application must enforce a strict 18+ age requirement before any
      personal data is collected. No exemptions.
    severity: critical
    action: block_merge
    detector:
      type: code_scan
      patterns:
        - "age\\s*<\\s*18"
      required_companion:
        - "return" 
        - "Exception"
    remediation: >
      Ensure age < 18 always results in a hard stop / return during the onboarding flow.

  # ── Location Data Minimization ───────────────────────────────────────────
  - id: PRIV-002
    title: "No Raw GPS Coordinates in Database"
    category: data_minimization
    description: >
      Raw latitude and longitude must never be saved to the database.
      Only hashed area codes (e.g., Geohash precision 8) are permitted to protect user tracking.
    severity: critical
    action: block_merge
    detector:
      type: regex_list
      patterns:
        - "['\"]lat['\"]\\s*:"
        - "['\"]lng['\"]\\s*:"
        - "['\"]latitude['\"]\\s*:"
        - "['\"]longitude['\"]\\s*:"
      check_paths:
        - "lib/src/core/geo_service.dart"
        - "functions/src/**"
    remediation: >
      Remove lat/lng from Firestore map payloads. Use dart_geohash to generate a geohash string and string matching.

  # ── Data Retention (TTL) ────────────────────────────────────────────────
  - id: PRIV-003
    title: "Mandatory TTL on Ephemeral Data"
    category: retention
    description: >
      Ephemeral data (proximity events, radar locations, gdpr request logs) must have a strict automated deletion policy via an `expiresAt` or `ttl` field.
    severity: high
    action: block_merge
    detector:
      type: code_scan
      patterns:
        - "\\.collection\\(['\"]proximity"
      required_companion:
        - "expiresAt"
        - "ttl"
    remediation: >
      Add a server timestamp + duration (e.g. 2 hours for location, 10 min for BLE) to the document field.

  # ── Explicit Consent ────────────────────────────────────────────────────
  - id: PRIV-004
    title: "Explicit Unbundled Consent"
    category: consent
    description: >
      Consent for specific features (location tracking, sensitive data processing) must be unbundled from general Terms of Service.
    severity: high
    action: block_merge
    detector:
      type: code_scan
      patterns:
        - "_consentGiven\\s*=>"
      required_companion:
        - "_consentLocation"
        - "_consentDataProcessing"
    remediation: >
      Ensure frontend registration flows require dedicated checkboxes for location and sensitive data before allowing account creation.

policy_tuning:
  critical: block_merge
  high: block_merge
  medium: require_approval
  low: warn

```

---

## Policy: Release & Build

```yaml
version: "2.0"
meta:
  name: "MPC Workflow — Release & Deployment Policies"
  maintained_by: "platform/release-team"
  last_reviewed: "2026-03-10"
  enforcement: "ci"

rules:
  # ── Build & Tests ────────────────────────────────────────────────────────
  - id: REL-001
    title: "Flutter Analyzer Must Be Clean"
    category: code_quality
    description: >
      `flutter analyze` must return 0 issues (ignoring specific allowed infos).
    severity: high
    action: block_release
    detector:
      type: ci_step
      command: "flutter analyze"

  - id: REL-002
    title: "TypeScript Backend Compilation"
    category: code_quality
    description: >
      Cloud Functions must compile locally without TypeScript errors.
    severity: high
    action: block_release
    detector:
      type: ci_step
      command: "npm run build"
      directory: "functions/"

  - id: REL-003
    title: "No UI Placeholder Text in Production"
    category: UX
    description: >
      No "Lorem ipsum", "TODO", or "Fix me" text should be visible in production screens.
    severity: medium
    action: warn
    detector:
      type: regex_list
      patterns:
        - "(?i)lorem ipsum"
        - "TODO:"
        - "FIXME:"

  # ── Store Compliance ─────────────────────────────────────────────────────
  - id: REL-004
    title: "App Store Review Guidelines"
    category: store_compliance
    description: >
      Ensure Apple Developer Guidelines and Google Play Policies are met.
      Specifically: User Block/Report functionality must be present and EULA clearly accessible.
    severity: critical
    action: block_release
    detector:
      type: feature_check
      requires:
        - "Block User"
        - "Report User"
        - "EULA Acceptance"

policy_tuning:
  critical: block_release
  high: block_merge
  medium: warn
  low: warn

```

---

## Policy: Security & Compliance

```yaml
version: "2.0"
meta:
  name: "MASTER PROJECT CONTROLLER (MPC Workflow) — Security & Compliance Policies"
  maintained_by: "platform/security-team"
  last_reviewed: "2026-03-09"
  enforcement: "ci"    # supported: ci, manual, advisory
  notes: >
    Drop into: tasks/policies/security.yaml
    CI parses this file and enforces all rules automatically.
    Any rule at severity: critical or high will block_merge by default (see policy_tuning).
    Rules at severity: medium require_approval. Rules at severity: low warn only.
    To suppress a rule for a PR, the PR must include a documented waiver signed off by the founder.

# ---------------------------------------------------------------------------
# GLOBAL DEFAULTS
# ---------------------------------------------------------------------------
global_defaults:
  fail_on_error: true
  autofix_allowed: false
  notification_channel: "#security-alerts"
  waiver_policy:
    allowed: true
    requires: "founder_approval"
    waiver_expiry_days: 30
    waiver_must_reference: "debt.md entry"

# ---------------------------------------------------------------------------
# SECURITY RULES
# ---------------------------------------------------------------------------
rules:

  # ── Secrets & Credentials ────────────────────────────────────────────────

  - id: SEC-001
    title: "No plaintext secrets in repo"
    category: secrets
    description: >
      Detect accidental plaintext secrets (API keys, tokens, credentials) in source
      and commit history. Includes common cloud provider key patterns.
    severity: critical
    action: block_merge
    detector:
      type: regex_list
      scan_targets: [source, commit_history, env_files, docker_files]
      patterns:
        - "(?i)aws_access_key_id\\s*[:=]\\s*[A-Z0-9]{16,}"
        - "(?i)-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----"
        - "(?i)api_key\\s*[:=]\\s*['\"][A-Za-z0-9\\-_]{20,}['\"]"
        - "(?i)secret\\s*[:=]\\s*['\"][A-Za-z0-9\\-_]{16,}['\"]"
        - "(?i)password\\s*[:=]\\s*['\"][^'\"]{8,}['\"]"
        - "(?i)(sk|pk)_(live|test)_[A-Za-z0-9]{24,}"   # Stripe keys
        - "CLOUDFLARE_API_TOKEN\\s*[:=]\\s*[A-Za-z0-9\\-_]{40}"
    remediation: >
      1. Remove the secret from source immediately.
      2. Rotate the credential in the provider dashboard.
      3. Store the new value in the secrets manager (never in source).
      4. Run `git-filter-repo` or BFG to purge from history.
      5. Log incident in lessons.md.
    auto_fix: false
    examples:
      - "Violation: API_KEY = \"AKIA...\" found in src/config.py"
      - "Violation: CLOUDFLARE_API_TOKEN=abc123 found in .env committed to repo"

  # ── Dependencies ─────────────────────────────────────────────────────────

  - id: SEC-002
    title: "Dependency Vulnerability Threshold"
    category: dependencies
    description: >
      Block merges when critical CVEs are present in the dependency tree.
      Medium and low severity issues are warnings unless they affect a core security boundary.
    severity: critical
    action: block_merge
    detector:
      type: sca
      engine: "snyk|owasp-dependency-check|npm-audit"
      policy:
        block_on: ["critical"]
        warn_on: ["high", "medium"]
        ignore_on: ["low"]
    remediation: >
      Patch or upgrade the dependency to a fixed version.
      If no fix is available, add compensating controls and document the accepted risk in debt.md.
    auto_fix: false

  - id: SEC-003
    title: "Prohibited Licenses"
    category: dependencies
    description: >
      Prevent introduction of dependencies with licenses incompatible with commercial use
      or that impose copyleft obligations on proprietary code.
    severity: high
    action: block_merge
    detector:
      type: license_scan
      banned_licenses:
        - "GPL-2.0-only"
        - "GPL-3.0-only"
        - "AGPL-3.0-only"
        - "LGPL-2.1-only"
        - "Unlicense"
        - "CC-BY-NC-4.0"
    allowed_licenses:
      - "MIT"
      - "Apache-2.0"
      - "BSD-2-Clause"
      - "BSD-3-Clause"
      - "ISC"
      - "MPL-2.0"
    remediation: >
      Replace with a compatibly licensed dependency or obtain a legal waiver.
      Document in ADR if a waiver is accepted.
    auto_fix: false

  # ── Encryption & Data Protection ─────────────────────────────────────────

  - id: SEC-004
    title: "Encryption at Rest & Transit Required"
    category: data_protection
    description: >
      All storage services and network transports must be encrypted.
      TLS 1.0 and 1.1 are prohibited.
    severity: critical
    action: block_merge
    detector:
      type: infra_check
      checks:
        - "storage.encryption_at_rest == true"
        - "transport.tls_min_version >= 1.2"
        - "database.encryption_at_rest == true"
        - "object_storage.server_side_encryption == true"
    remediation: >
      Enable provider-managed encryption on all storage.
      Enforce TLS 1.2+ in infrastructure config and load balancer settings.
    auto_fix: false

  - id: SEC-005
    title: "PII Flow & Retention Limits"
    category: privacy
    description: >
      Detect code that persists PII beyond the allowed retention window.
      Ensure deletion jobs and ephemeral token patterns are in place.
      Applies to: location data, device identifiers, email addresses, biometric signals.
    severity: critical
    action: block_merge
    detector:
      type: dataflow_static
      checks:
        - "user_location.retention_days <= policies/privacy.max_retention_days"
        - "pii_storage_class != 'permanent'"
        - "ble_scan_data.stored_to_disk == false"
        - "user_email.encrypted_at_rest == true"
    remediation: >
      Store only ephemeral tokens or cached data — never raw PII permanently.
      Add automated data deletion jobs and reference them in context.md.
      Log the data flow in system_map.md under the relevant service.
    auto_fix: false

  # ── Auth & Rate Limiting ──────────────────────────────────────────────────

  - id: SEC-011
    title: "Auth Endpoints Must Have Rate Limiting"
    category: auth
    description: >
      Any endpoint handling authentication, registration, or password reset
      must have rate limiting configured to prevent brute-force attacks.
    severity: critical
    action: block_merge
    detector:
      type: code_scan
      patterns:
        - "router\\.(post|put)\\(['\"].*/(login|auth|register|reset|verify)"
      required_companion:
        - "rateLimit("
        - "rateLimiter"
    remediation: >
      Add rate limiting middleware to all auth endpoints before the handler.
      Configure appropriate thresholds (e.g. 10 requests/minute per IP).
    auto_fix: false

  - id: SEC-012
    title: "No Hardcoded User IDs or Roles in Code"
    category: auth
    description: >
      Hardcoded user IDs, admin flags, or role strings in application logic
      bypass access control and create privilege escalation risks.
    severity: high
    action: block_merge
    detector:
      type: regex_list
      patterns:
        - "(?i)role\\s*==\\s*['\"]admin['\"]"
        - "(?i)user_id\\s*==\\s*['\"]?[0-9a-f\\-]{8,}['\"]?"
        - "(?i)is_admin\\s*=\\s*true"
    remediation: >
      Move role and permission checks to a centralized policy service or middleware.
      Never hardcode role strings in business logic.
    auto_fix: false

  # ── Process & Traceability ────────────────────────────────────────────────

  - id: SEC-006
    title: "Plan ID Required in PR Title"
    category: process
    description: >
      Every PR must reference a Plan ID from tasks/plan.md to ensure
      full traceability from requirement to deployment.
    severity: high
    action: block_merge
    detector:
      type: pr_title_regex
      pattern: "\\[PLAN-ID: ?[0-9]{8}-[a-z0-9\\-]+\\]"
    remediation: >
      Add the Plan ID to the PR title in format: [PLAN-ID: YYYYMMDD-short-name]
      The Plan ID must exist in tasks/plan.md.
    auto_fix: false

  - id: SEC-007
    title: "Verification Checklist Required"
    category: process
    description: >
      Every PR must include a completed verification checklist covering
      unit tests, integration tests, security scan, and performance baseline.
    severity: high
    action: block_merge
    detector:
      type: pr_body_contains
      required_phrases:
        - "Verification checklist"
        - "unit tests"
        - "integration tests"
        - "security scan"
    remediation: >
      Populate the PR description with the required verification checklist
      and link to evidence (test reports, logs, screenshots).
    auto_fix: false

  - id: SEC-013
    title: "ADR Required for Architecture Changes"
    category: process
    description: >
      Any change that introduces a new service, modifies data flows between services,
      or changes an infrastructure provider must include an ADR in tasks/decisions/.
    severity: high
    action: block_merge
    detector:
      type: pr_body_contains
      required_phrases:
        - "ADR-"
    remediation: >
      Write an Architecture Decision Record in tasks/decisions/ADR-NNN-description.md
      and reference it in the PR body.
    auto_fix: false

  # ── AI Safety ─────────────────────────────────────────────────────────────

  - id: SEC-008
    title: "AI Feature Safety Checks"
    category: ai_safety
    description: >
      Any change that invokes external LLMs or on-device AI models must include
      PII filtering, context sanitization, and adversarial prompt tests.
      Applies to: OpenAI, Anthropic, Gemini, or any model_call() abstraction.
    severity: critical
    action: block_merge
    detector:
      type: code_scan
      patterns:
        - "openai\\."
        - "anthropic\\."
        - "model_call\\("
        - "generative_model\\."
      required_artifacts:
        - "PII filter unit tests"
        - "adversarial prompt tests"
        - "safety policy verification report"
    remediation: >
      Add PII filters before model input and output safety filters after.
      Document model endpoint, access rules, and data retention in system_map.md.
      Run adversarial prompt test suite and attach results to PR.
    auto_fix: false

  # ── Infrastructure & Cost ─────────────────────────────────────────────────

  - id: SEC-009
    title: "Infrastructure Cost Estimate Required"
    category: cost_governance
    description: >
      Every infra change must include a conservative monthly cost estimate.
      Changes estimated above $100/month require explicit founder approval before merge.
    severity: medium
    action: require_approval
    detector:
      type: pr_body_contains
      required_phrases:
        - "Infra cost estimate"
        - "Monthly cost:"
    thresholds:
      auto_approve_below_usd: 100
      founder_approval_above_usd: 100
    remediation: >
      Add an estimated monthly cost to the PR body.
      Set budget alerts and quotas in the cloud provider dashboard.
      Log in debt.md if the estimate is uncertain.
    auto_fix: false

  - id: SEC-010
    title: "Large File Handling Policy"
    category: infrastructure
    description: >
      Prevent binary or large files being committed to the repository.
      Files above 5MB must use external object storage and be referenced by URL.
    severity: medium
    action: block_merge
    detector:
      type: git_diff_file_size
      max_size_bytes: 5242880   # 5 MB
      exempt_extensions: [".md", ".yaml", ".json", ".txt"]
    remediation: >
      Upload large files to Cloudflare R2 (or equivalent object storage)
      and reference the signed URL from code.
      Never commit binary assets, fixtures, or test data > 5MB.
    auto_fix: false

# ---------------------------------------------------------------------------
# POLICY STRICTNESS MATRIX
# Controls CI behavior per severity level.
# ---------------------------------------------------------------------------
policy_tuning:
  critical: block_merge
  high: block_merge
  medium: require_approval
  low: warn

# ---------------------------------------------------------------------------
# CI HOOKS
# Reference to scripts CI must call for each check category.
# All scripts must exit 0 on pass, non-zero on failure.
# ---------------------------------------------------------------------------
hooks:
  secret_scan:            "scripts/ci/secret_scan.sh"
  dependency_scan:        "scripts/ci/dependency_scan.sh"
  license_scan:           "scripts/ci/license_scan.sh"
  architecture_validate:  "scripts/ci/architecture_validate.sh"
  ai_safety_check:        "scripts/ci/ai_safety_check.sh"
  sast_scan:              "scripts/ci/sast_scan.sh"
  dast_scan:              "scripts/ci/dast_scan.sh"
  slo_evaluator:          "scripts/ci/slo_evaluator.sh"
  policy_engine:          "scripts/ci/policy_engine.py"

```

---

