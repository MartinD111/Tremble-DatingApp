# Mock Location Audit — Tremble Flutter App

**Date:** 2026-06-28
**Scope:** Every source of mock, hardcoded, or simulated GPS coordinates in `lib/`.
**Trigger:** Dev log line `"📍 Location Captured: mock_lat: 46.05, mock_lng: 14.50 [Ljubljana]"` observed during dev run. Need to confirm no mock path can leak to a production build.
**Prod build flag:** `--flavor prod --dart-define=FLAVOR=prod`

## Executive summary

| Severity | Count | Notes |
|---|---|---|
| 🔴 HIGH | 1 | Misleading hardcoded log line, prints in **every** build (no guard) |
| 🟡 MEDIUM | 4 | Hardcoded map default center / venue pins — UX-only, no backend leak |
| 🟢 LOW / INFO | 2 | Intentional Places API geographic bias (SI/HR market) |
| ✅ PASS | 4 | Mock data sources correctly gated by `kDebugMode` / `kReleaseMode` / `FLAVOR != 'prod'` |

**No mock GPS coordinates are written to Firestore or fed into the real `GeoService` / BLE pipeline in any build.** The actual location-capture path (`GeoService.updateLocation`, `event_geofence_service`, all `_buildEventMarkers` distance math) routes through `Geolocator.getCurrentPosition()` — real GPS only. The dev log line is **a static string**, not a real mock injection.

That said, the high-severity log line is misleading and ships in release, and several hardcoded Ljubljana-centric defaults are present in non-dev paths. Detailed findings follow.

---

## 🔴 HIGH

### H1. `lib/src/features/dashboard/presentation/home_screen.dart:1060`

```dart
debugPrint(
    "📍 Location Captured: mock_lat: 46.05, mock_lng: 14.50 [Ljubljana]");
```

- **Type:** Hardcoded log string (NOT a real GPS source).
- **Current guard:** **NONE.** Runs every time the user toggles radar scanning on, in every build (dev and prod).
- **Can it leak to prod?** YES — the log line itself ships to prod. `debugPrint` is not stripped in release builds; it forwards to the platform log (logcat / oslog), so any QA, support, or attacker pulling device logs will see this exact line on every prod radar start.
- **Does it affect real proximity?** NO. The string `46.05, 14.50` is *not* read by `GeoService` or any provider; it is only the log payload. The real location pipeline (`GeoService.updateLocation` → `Geolocator.getCurrentPosition` → geohash → Firestore) runs immediately below this line and uses the actual device GPS.
- **Risk:** Operationally misleading (debug log claims a mock location is in use when it is not). On a prod incident, this line would actively send a support engineer down the wrong path. It also implies to a security reviewer that the app is using a mock location in prod, which is false but damaging.
- **Recommended fix:** Either delete the line, or replace it with a real `debugPrint('[Radar] scanning enabled (location captured by GeoService)')` and wrap the entire `debugPrint` call site in `if (kDebugMode) { ... }`. Do NOT keep the `mock_lat`/`mock_lng`/`Ljubljana` literals in the source at all.

---

## 🟡 MEDIUM

### M1. `lib/src/features/map/presentation/tremble_map_screen.dart:34`

```dart
static const LatLng _ljubljanaCenter = LatLng(46.0569, 14.5058);
```

- **Type:** Hardcoded default map center.
- **Current guard:** **NONE.** Used regardless of flavor.
- **Used at:**
  - Line 57 — seed for the dev-only `_proximityPoints` generator (this call site IS gated: `_proximityPoints = _isDev ? _generateProximityPoints() : const []`).
  - Line 76 — `_mapController.move(_ljubljanaCenter, ...)` when user taps a zoom toggle. Runs in prod.
  - Line 312 — `MapOptions(initialCenter: _ljubljanaCenter, ...)` — initial render of the FlutterMap. Runs in prod.
- **Can it leak to prod?** It does not leak to any backend or to proximity matching. It is a UX default only. But every prod user opening the Map tab and every zoom-toggle interaction recenters the map on Ljubljana, regardless of where the user actually is. A user in Zagreb tapping "City" sees Ljubljana.
- **Recommended fix:** Replace the constant with a resolved center derived from the user's last known Geolocator position (or last persisted geohash → decoded center) and fall back to a sensible default only if location permission is denied. Keep the literal out of any always-on path. Acceptable interim: gate the `initialCenter` and `_setZoom` move on user position with the constant as a last-resort fallback.

### M2. `lib/src/features/map/presentation/tremble_map_screen.dart:45-47`

```dart
static const Map<String, LatLng> _eventLocations = {
  'club_monokel': LatLng(46.0514, 14.5058),
  'labaratorij':  LatLng(46.0540, 14.5120),
  'metelkova':    LatLng(46.0560, 14.5097),
};
```

- **Type:** Hardcoded venue coordinates for three Ljubljana clubs.
- **Current guard:** **NONE directly**, but effectively gated by `_events`: line 42 declares `static const List<TrembleEventData> _events = [];` (empty). `_buildEventMarkers` (line 159) iterates `_events`, so these coords are only resolved if a `TrembleEventData` with a matching id is added.
- **Can it leak to prod?** Today, no — `_events` is empty so the markers never render. As soon as `_events` is populated with one of those three ids (in dev or prod), these literals are drawn on the prod map.
- **Recommended fix:** Move venue coordinates out of the source file. Either (a) source them from Firestore as part of the event document, or (b) keep them only in a dev fixture that is `_isDev`-gated alongside `_proximityPoints`. Do not allow a static const map of real venue coords to be wired into a prod render path.

### M3. `lib/src/features/map/presentation/tremble_map_screen.dart:76`

```dart
_mapController.move(_ljubljanaCenter, _zoomLevels[zoom]!);
```

- **Type:** Hardcoded recenter on user interaction (zoom toggle).
- **Current guard:** **NONE.**
- **Can it leak to prod?** Yes — covered under M1. Cited separately because the fix is independent of `initialCenter`: even after fixing M1's seed center, this line will still snap the map back to Ljubljana on every zoom-toggle tap.
- **Recommended fix:** Move toward the user's current/last-known position, not `_ljubljanaCenter`.

### M4. `lib/src/features/map/presentation/tremble_map_screen.dart:312`

```dart
initialCenter: _ljubljanaCenter,
```

- **Type:** Hardcoded initial map view.
- **Current guard:** **NONE.**
- **Can it leak to prod?** Yes — first frame of the map for every prod user is Ljubljana. UX-only impact, not a privacy/proximity leak.
- **Recommended fix:** Same as M1.

---

## 🟢 LOW / INFO

### L1. `lib/src/core/places_service.dart:147`

```dart
'locationBias': {
  'circle': {
    'center': {'latitude': 46.1512, 'longitude': 14.9955}, // center of Slovenia
    'radius': 50000.0,
  },
},
```

- **Type:** Hardcoded geographic bias for the Google Places (cities) autocomplete API.
- **Current guard:** **NONE — intentional.**
- **Can it leak to prod?** Yes, and intentionally so: this is an explicit product decision to bias city suggestions toward Slovenia for the SI/HR launch market. It is not the user's location; it is the API search center.
- **Recommended fix:** No fix required for prod safety. If/when the app expands beyond SI/HR, replace the constant with a region-aware default (user device locale / IP geo / last known position).

### L2. `lib/src/core/places_service.dart:205`

```dart
: {
    'circle': {
      'center': {'latitude': 46.1512, 'longitude': 14.9955},
      'radius': 50000.0,
    },
  };
```

- **Type:** Same constant, used as fallback bias in `gymAutocomplete` when the caller does not pass an explicit `latitude` / `longitude`.
- **Current guard:** Caller-driven: if the gym search widget passes real user lat/lng, the literal is bypassed (see lines 196–203). Only the fallback branch hits the Slovenia center.
- **Can it leak to prod?** Yes by design — same rationale as L1.
- **Recommended fix:** None for prod safety. Long term, make the fallback the user's last known position rather than a region constant.

---

## ✅ PASS (verified correctly gated, no action required)

### P1. `lib/src/core/dev_mock_users.dart` — `kMockNearbyUsers`
- Three hardcoded mock profiles. The file header comments "These are never visible in prod — kDebugMode gates all call sites."
- Only consumer: `dev_simulation_controller.dart:280` (`_pickMockProfile`).
- Only caller chain to that controller: `home_screen.dart:1115`, wrapped in `if (kDebugMode && (ref.read(bypassRadarProvider) || canAccessRadar))`.
- ✅ Correctly gated. Mocks cannot start a sim in release.

### P2. `lib/src/features/dashboard/application/dev_mock_matches_provider.dart`
- In-memory store of mock matches added by the dev sim controller.
- Consumed only by `matchesStreamProvider` (`match_repository.dart:342`), which has an explicit early-return on `kReleaseMode` at line 349 — the dev mocks are never even read in a release build.
- ✅ Correctly gated.

### P3. `lib/src/features/dashboard/application/dev_simulation_controller.dart`
- Drives the dev passive-discovery simulation. Doc-comment at line 133 explicitly states `"Caller must guard with kDebugMode + bypass flag."` — caller does (see P1).
- ✅ Correctly gated upstream.

### P4. `lib/src/features/map/presentation/tremble_map_screen.dart` — `_proximityPoints` / `_generateProximityPoints`
- Line 31: `static const bool _isDev = String.fromEnvironment('FLAVOR', defaultValue: 'dev') != 'prod';`
- Line 57: `_proximityPoints = _isDev ? _generateProximityPoints() : const [];`
- Line 110: `if (_proximityPoints.isEmpty) return const [];` — circle layer no-op in prod.
- Line 243: `if (kDebugMode || const String.fromEnvironment('FLAVOR') == 'dev') ...[ _MapPill(...) ]` — "active people count" pill is double-gated.
- ✅ Correctly gated. Note: the `_isDev` constant uses `defaultValue: 'dev'` so the proximity simulation is enabled by default for any build that does not pass `--dart-define=FLAVOR=prod`. CI must always pass `FLAVOR=prod` for prod builds — already mandated by CLAUDE.md ("never run un-flavored flutter build"). Worth re-asserting in `pre-commit` / CI guards.

---

## Real-GPS pipeline (no mocks — confirmed clean)

For completeness, the actual location-capture paths use real `Geolocator` only, and write only geohash (no raw lat/lng) to Firestore. No hardcoded coords involved:

| File:line | Call |
|---|---|
| `lib/src/core/geo_service.dart:126` | `Geolocator.getCurrentPosition(...)` → `GeoHasher().encode(pos.longitude, pos.latitude, precision: 7)` → Firestore `proximity/{uid}.geohash` |
| `lib/src/core/event_geofence_service.dart:101` | `Geolocator.getPositionStream(...)` for event geofence entry/exit |
| `lib/src/features/dashboard/presentation/home_screen.dart:1910, 2032` | `Geolocator.getCurrentPosition(...)` for radar/event distance math |
| `lib/src/features/gym/application/gym_mode_controller.dart:104` | `Geolocator.getCurrentPosition(...)` for gym mode |
| `lib/src/features/safety/presentation/safe_zones_screen.dart:285, 294` | `Geolocator.getCurrentPosition(...)` for safe zones |

✅ All five real-GPS sites use the platform GPS. No mock injection point exists in the live geo pipeline.

---

## Recommended action order

1. **H1 (priority 1)** — Delete or rewrite the `home_screen.dart:1060` log line. Remove the literal coordinates and the word "Ljubljana" from the string. Wrap in `if (kDebugMode)`. Same-day fix.
2. **M1 / M3 / M4** — Make the map's `initialCenter` and zoom-toggle target derive from the user's last known position (`Geolocator.getLastKnownPosition()` or decoded geohash from `proximity/{uid}`). Keep `_ljubljanaCenter` only as a last-resort fallback inside a private helper, not as a UI literal. Same PR.
3. **M2** — Move `_eventLocations` out of the source file before populating `_events` with any of those three ids. Source venue coords from Firestore.
4. **P4 hardening (defensive)** — Add a CI guard that asserts release builds are invoked with `--dart-define=FLAVOR=prod`. Currently the `_isDev` flag defaults to `dev` if the flag is omitted; a forgotten flag at the build step would re-enable mock proximity circles.
5. **L1 / L2** — No prod-safety action. Revisit only when expanding outside SI/HR.

---

## Files touched by audit (read-only)

- `lib/src/features/dashboard/presentation/home_screen.dart`
- `lib/src/features/map/presentation/tremble_map_screen.dart`
- `lib/src/core/places_service.dart`
- `lib/src/core/dev_mock_users.dart`
- `lib/src/core/geo_service.dart`
- `lib/src/core/event_geofence_service.dart`
- `lib/src/features/dashboard/application/dev_simulation_controller.dart`
- `lib/src/features/dashboard/application/dev_mock_matches_provider.dart`
- `lib/src/features/matches/data/match_repository.dart`
- `lib/src/features/gym/application/gym_mode_controller.dart`
- `lib/src/features/gym/presentation/gym_search_widget.dart`
- `lib/src/features/safety/presentation/safe_zones_screen.dart`

**No code modified.** Audit only, per task scope.
