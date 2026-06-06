# Audit Step 8 — Privacy & TTL Architecture

**Date:** 2026-06-06  
**Auditor:** Claude Code CLI  
**Status:** COMPLETE — 2 CRITICAL findings, 2 FLAG findings. Stop for founder review before any fix.

---

## Summary

| Item | Verdict | Severity |
|------|---------|----------|
| 1. GPS never in Firestore | MATCH | — |
| 2. Geohash precision 7 | MATCH | — |
| 3. TTL field consistency | MISMATCH × 2 | CRITICAL |
| 4. TTL values | PARTIAL MATCH | FLAG |
| 5. "encrypted" claim | FLAG — founder review required | FLAG |
| 6. "zero location stored" overclaim | PARTIAL FLAG | FLAG |

---

## Item 1 — GPS never in Firestore

**Verdict: MATCH**

Every Firestore write path was inspected. Raw lat/lng is accepted at the API boundary but converted to geohash immediately before any write. It never appears in a Firestore write payload.

### Dart client — geo_service.dart

`lib/src/core/geo_service.dart:155–196` — Firestore write:
```dart
await _firestore.collection('proximity').doc(uid).set({
  'geohash': geohash,        // precision 7 — see Item 2
  'radiusTier': radiusTier,
  'radarActive': true,
  'isActive': true,
  'isLowPowerMode': _isLowPowerMode,
  'updatedAt': FieldValue.serverTimestamp(),
  'geoHashExpiresAt': geoHashExpiresAt,  // ← NOTE: field is geoHashExpiresAt, not expiresAt — see Item 3
}, SetOptions(merge: true));
```

Comment at line 164–168:
> "Raw coordinates are used locally for encoding ONLY and are never written to Firestore."

### TypeScript Cloud Function — updateLocation

`functions/src/modules/proximity/proximity.functions.ts:204–220` — Firestore write:
```typescript
const geohash = encodeGeohash(data.latitude, data.longitude); // lat/lng consumed, geohash produced
await db.collection("proximity").doc(uid).set(
    { geohash, lastSeen: FieldValue.serverTimestamp(), isActive: true },
    { merge: true }
);
```
No lat/lng in the write payload.

### proximity_events write

`functions/src/modules/proximity/proximity.functions.ts:716–722`:
```typescript
await db.collection("proximity_events").add({
    fromUid: a.uid,
    toUid: b.uid,
    geohash: a.geohash,      // geohash only — no lat/lng
    timestamp: FieldValue.serverTimestamp(),
    expiresAt,
});
```

**No lat/lng field appears in any Firestore write across all Dart files and Cloud Functions.**

---

## Item 2 — Geohash precision

**Verdict: MATCH**

### Dart client
`lib/src/core/geo_service.dart:41`:
```dart
static const int _geohashPrecision = 7;
```
Used at line 172: `precision: _geohashPrecision`.

### Cloud Function encodeGeohash
`functions/src/modules/proximity/proximity.functions.ts:81`:
```typescript
function encodeGeohash(lat: number, lng: number, precision: number = 7): string {
```
Default precision 7. Comment at line 110:
> "At precision 7, accuracy is ~75m. This is GDPR-safe (Art. 5 minimization)."

### Notes (not violations)
- `lib/src/features/map/domain/safe_zone_repository.dart:73`: uses `precision: 6` — this is for safe-zone geofence computation (a wider ~1.2km cell), not proximity storage. Intentional.
- `proximity.functions.ts:244–246`: findNearby query encodes requester at precision 6 to cast a wide net, then haversine-filters to actual radius. The stored proximity geohash remains at precision 7. This design is documented in code comments.

---

## Item 3 — TTL field consistency

### CRITICAL FINDING 1 — gdprRequests uses `ttl`, not `expiresAt`

**File:** `functions/src/modules/gdpr/gdpr.functions.ts:153` and `:233`

```typescript
// Line 148–154 (exportUserData):
await db.collection("gdprRequests").add({
    uid,
    type: "export",
    status: "processing",
    requestedAt: FieldValue.serverTimestamp(),
    ttl: twoYearsFromNow(), // ← FIELD IS "ttl", not "expiresAt"
});

// Line 228–234 (deleteUserAccount):
const gdprRef = await db.collection("gdprRequests").add({
    uid,
    type: "delete",
    status: "processing",
    requestedAt: FieldValue.serverTimestamp(),
    ttl: twoYearsFromNow(), // ← FIELD IS "ttl", not "expiresAt"
});
```

`twoYearsFromNow()` (lines 119–123) correctly computes `d.setFullYear(d.getFullYear() + 2)` — the TTL value is correct. But the **field name** is `ttl`, not `expiresAt`.

**Why this is CRITICAL:**  
Every other collection uses `expiresAt` as the field name targeted by Firestore TTL policies. If the Firestore TTL policy for `gdprRequests` targets `expiresAt` (the standard field), then GDPR audit records written with `ttl` will **never auto-expire**. They will persist indefinitely — violating GDPR Art. 5(1)(e) storage limitation and the 2-year cap the code intends to enforce.

**To fix this, the founder must either:**
- Verify that a separate Firestore TTL policy exists for `gdprRequests` targeting the field `ttl`, OR
- Rename the field to `expiresAt` in `gdpr.functions.ts` (aligned with all other collections) and confirm the TTL policy targets `expiresAt`.

**Do NOT edit. Stop for founder review.**

---

### CRITICAL FINDING 2 — proximity/{uid} uses `geoHashExpiresAt`, not `expiresAt`

**File:** `lib/src/core/geo_service.dart:182–195`

```dart
final geoHashExpiresAt = Timestamp.fromDate(
    DateTime.now().add(_geoTtl), // _geoTtl = Duration(minutes: 30)
);
await _firestore.collection('proximity').doc(uid).set({
    ...
    'geoHashExpiresAt': geoHashExpiresAt, // ← FIELD IS "geoHashExpiresAt", not "expiresAt"
}, SetOptions(merge: true));
```

The Cloud Function `updateLocation` writes to `proximity/{uid}` with NO TTL field at all:
```typescript
// proximity.functions.ts:209–215
await db.collection("proximity").doc(uid).set(
    { geohash, lastSeen: FieldValue.serverTimestamp(), isActive: true },
    { merge: true }
);
```

**Why this is CRITICAL:**  
If the Firestore TTL policy for `proximity` collection targets `expiresAt`, documents in this collection will **never auto-expire** through the TTL mechanism. The only active TTL field written is `geoHashExpiresAt` (from the Dart client), which no known Firestore TTL policy targets. Location data (geohash + activity state) would persist indefinitely.

**Do NOT edit. Stop for founder review.**

---

### All other TTL writers — verified consistent

| Collection | Field | Writer | Status |
|---|---|---|---|
| `proximity_events` | `expiresAt` | proximity.functions.ts:721 | ✓ |
| `matches` | `expiresAt` | matches.functions.ts:257, proximity.functions.ts:914 | ✓ |
| `waves` | `expiresAt` | matches.functions.ts:102 | ✓ |
| `rateLimits` | `expiresAt` | rateLimit.ts:54,68,109 | ✓ |
| `gdprRequests` | **`ttl`** | gdpr.functions.ts:153,233 | ✗ CRITICAL |
| `proximity/{uid}` | **`geoHashExpiresAt`** | geo_service.dart:195 | ✗ CRITICAL |

---

## Item 4 — TTL values

### proximity/{uid} — 30 min (client), no TTL (CF)
- `geo_service.dart:45`: `static const Duration _geoTtl = Duration(minutes: 30);`
- `geoHashExpiresAt` = `now + 30 min`
- CF `updateLocation` writes NO TTL field
- Strategy audit plan says 24h for `proximity/{uid}`; `C-RADAR-11` says "30-min TTL" — contradiction within the strategy document. The client code implements 30 min. **Report to founder to resolve the strategy inconsistency; do not change code.**

### proximity_events — 10 min ✓
- `proximity.functions.ts:715`: `new Date(Date.now() + 10 * 60 * 1000)` = 10 min ✓

### run_encounters — CANNOT VERIFY (deprecated)
- `proximity.functions.ts:851–868`: Collection is deprecated/no-op. `onRunEncounter` trigger is a registered no-op. Run Club encounters now go through `scanProximityPairs` → `proximity_events`. The `run_encounters` collection is no longer written to.

### active_run_crosses — TTL CANNOT CONFIRM
- Client reads expect `expiresAt` field (`run_club_repository.dart:19–23`).
- Client writes only merge `signals.{userId}: true` and `dismissedBy` — no TTL written.
- No Cloud Function creates these documents (only `onRunCrossUpdated` listens).
- Document creation path is unresolved — cannot confirm `expiresAt` is written at creation time.

### matches — 30 min ✓
- `proximity.functions.ts:914`: `new Date(Date.now() + 30 * 60 * 1000)` = 30 min ✓
- `matches.functions.ts:257`: `new Date(Date.now() + 30 * 60 * 1000)` = 30 min ✓
- `matches.functions.ts:102` (`sendWave` → `waves` collection): `new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)` = **30 DAYS** — this is the `waves` collection expiry (not `matches`). Waves are retained 30 days to prevent re-waving. Strategy does not specify a waves TTL; this appears intentional.

### gdprRequests — 2 years (correct value, wrong field)
- `gdpr.functions.ts:119–123`: `twoYearsFromNow()` correctly computes 2 calendar years.
- **Field name is `ttl` (CRITICAL — see Item 3).**

---

## Item 5 — "encrypted" claim in consent_step.dart

**Verdict: FLAG — requires founder/legal review. Do NOT auto-reword.**

**File:** `lib/src/features/auth/presentation/widgets/registration_steps/consent_step.dart:174–180`

Exact text presented to users during registration consent:
> "I explicitly consent to the processing of my sensitive personal data (interests, preferences, religion, ethnicity) for the purpose of matchmaking. I understand this data is protected by **Google Cloud infrastructure-level encryption at rest**, never sold, and I can withdraw consent at any time from Settings."

**Assessment:**
- The claim says "Google Cloud infrastructure-level encryption at rest" — it is scoped to infrastructure level, NOT field-level.
- This is technically accurate: Firebase/GCP uses AES-256 encryption at rest at the infrastructure layer.
- **No field-level encryption (AES, RSA, or any crypto library) is applied to any Firestore fields before writing.** A search across all Dart and TypeScript files found no field-level encryption anywhere.
- The gap: the claim is accurate but users reading "encryption at rest" may assume stronger protection than infrastructure-level provides. If a Firebase admin or leaked service account gained Firestore access, sensitive fields (interests, religion, ethnicity) would be readable in plaintext.
- Per the strategy audit plan: "flag for legal review — do not auto-reword."

**Do NOT edit. Escalate to founder for legal sign-off.**

---

## Item 6 — "zero location stored" overclaim

**Verdict: PARTIAL FLAG — one string requires review**

Searched all Dart files, assets, and hardcoded UI strings for: "zero location", "location never stored", "we don't store location", "no location stored", "brez lokacije", "lokacija ni shranjena", "Your location is never stored."

**No ARB translation files found** — the app uses hardcoded English strings only. There are no 8-language translations to audit.

**String 1 — FLAG:**  
`lib/src/features/safety/presentation/safe_zones_screen.dart:239`:
> "You can enter a nearby street or intersection instead of your exact address. We build a range around it — **your real location is never stored.**"

This lacks the "exact" or "precise" qualifier. "Real location" could be read as "no location data whatsoever is stored" — but geohash IS stored. Geohash p7 (~150m cell) is a form of location data. This phrasing is legally borderline.

**String 2 — CLEAR (accurate):**  
`lib/src/features/safety/presentation/safe_zones_screen.dart:443` (UI title):
> "Your exact location is never stored"

Accurate: precise GPS coordinates are not stored; geohash p7 is. "Exact" correctly qualifies the claim.

**String 3 — CLEAR (accurate):**  
`lib/src/features/safety/presentation/safe_zones_screen.dart:445`:
> "Only coarse geohash cells (roughly ~150m blocks) are stored on our servers. Your precise GPS coordinates are never stored."

Explicitly discloses geohash storage. Accurate and defensible.

**String 4 — CLEAR (accurate):**  
`lib/src/features/auth/presentation/permission_gate_screen.dart:244`:
> "Your precise coordinates are never stored or shared."

Accurate: precise coordinates are never stored; geohash p7 is. "Precise" correctly qualifies the claim.

**Strategy brand claim C-BRAND-02** ("Your location is never stored. Not policy. Architecture.") does NOT appear anywhere in the app source code. It may be marketing-only copy. If it appears on the website, that is a separate and more serious overclaim — not in scope for this audit.

**The one string to address: `safe_zones_screen.dart:239`. Recommended fix direction (for founder to approve): add "exact" or "precise" qualifier.** Example: "your real location is never stored" → "your precise location is never stored." Do NOT edit without founder approval.

---

## Stop Condition

**Two CRITICAL findings were found (Item 3).**

Per the audit plan Step 8: *"if any CRITICAL is found, stop and report before continuing."*

**Do NOT proceed to Step 9 until the founder has reviewed and resolved:**
1. `gdprRequests` `ttl` field: verify deployed Firestore TTL policy for `gdprRequests` targets `ttl`, or approve renaming to `expiresAt`.
2. `proximity/{uid}` `geoHashExpiresAt` field: verify deployed Firestore TTL policy for `proximity` targets `geoHashExpiresAt`, or approve renaming to `expiresAt`.
3. `consent_step.dart` encryption claim: legal sign-off on "Google Cloud infrastructure-level encryption at rest."
4. `safe_zones_screen.dart:239` "your real location is never stored": approve phrasing fix.

---

## Appendix — Files Inspected

- `lib/src/core/geo_service.dart`
- `lib/src/features/auth/presentation/widgets/registration_steps/consent_step.dart`
- `lib/src/features/auth/presentation/permission_gate_screen.dart`
- `lib/src/features/safety/presentation/safe_zones_screen.dart`
- `lib/src/features/dashboard/data/run_club_repository.dart`
- `functions/src/modules/proximity/proximity.functions.ts`
- `functions/src/modules/matches/matches.functions.ts`
- `functions/src/modules/matches/intercept.functions.ts`
- `functions/src/modules/gdpr/gdpr.functions.ts`
- `functions/src/middleware/rateLimit.ts`
