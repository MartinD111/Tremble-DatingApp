## ADR-009: Compass dependency for radar turn-to-find (flutter_compass_v2)

Date: 2026-07-21
Status: Accepted

> **Numbering note:** The FEATURE-RADAR-SONAR plan and Session-56/57 handoffs
> refer to this as "ADR-008". That slug was already taken
> (`ADR-008-bundled-brand-typefaces.md`), so the compass decision is recorded
> here as **ADR-009**. Any doc/PR/memory that says "ADR-008 (compass)" means
> this file.

Context:

FEATURE-RADAR-SONAR Phase B turns the trembling-window radar dot into a
turn-to-find sonar: the user rotates the phone and the partner dot swings to
the partner's real direction. BLE RSSI (Phase A) gives an approximate distance
but **no bearing**. The direction model (design doc
`docs/superpowers/specs/2026-07-21-radar-sonar-turn-to-find-design.md`) is
hybrid: a server-computed geohash-7 `bearing` (absolute, 0–359° from north) is
combined with the device's live compass `heading` to produce a
screen-relative dot angle: `dotAngle = wrap(bearing − heading)`.

That requires a device heading source. The app has **no** compass/magnetometer
dependency today (`pubspec.yaml` carries `geolocator: ^14.0.2`,
`dart_geohash: ^2.1.0`, no sensor package). Adding one is a `dependencies.md`
lane → ADR + founder approval (MPC HIGH). Founder approval granted 2026-07-21.

Decision:

Add **`flutter_compass_v2: ^1.0.3`** (pinned at 1.0.3) as the heading source.

- Exposes `FlutterCompass.events` → `Stream<CompassEvent?>` with a ready-made
  `heading` in `0–360` (0 = magnetic north). No manual sensor-fusion math.
- Latest 1.0.3 (published 2024-03-28); pub points 150/160; SDK
  `>=2.12.0 <4.0.0`, `flutter >=1.10.0` — compatible with our toolchain.
- It is the maintained fork of the original `flutter_compass` (stale at 0.8.1,
  null-safety/Flutter-compat issues), which is why the plan chose the `_v2`
  fork rather than the original.

Platform notes:
- **Android:** uses the rotation-vector / magnetometer sensor. No new manifest
  permission.
- **iOS:** heading comes via `CLLocationManager` heading updates, which require
  location authorization. The app **already** declares
  `NSLocationWhenInUseUsageDescription` (used by `geolocator`), so **no new
  Info.plist usage key is required.** Heading updates work under When-In-Use.

Alternatives Considered:
- **`sensors_plus` (raw magnetometer):** actively maintained, very popular, but
  returns raw magnetometer vectors — we'd hand-roll heading + tilt
  compensation + smoothing. More code, more error surface, for an *approximate*
  turn-to-find. Rejected: cost > benefit for a gamified hunt.
- **Original `flutter_compass` (0.8.1):** unmaintained, older null-safety
  story. Rejected in favour of the `_v2` fork.
- **No compass — server bearing only:** cannot render a screen-relative dot
  without the device's facing direction; the dot could not "swing" as the user
  rotates. Defeats the feature. Rejected.

Consequences:
- (Pro) Direct 0–360 heading stream; minimal integration code.
- (Pro) No new OS permission prompt — reuses existing location authorization.
- (Pro) Privacy preserved: heading is device-local; the partner's geohash never
  reaches the client (server returns only `bearing`/`distanceBucket`).
- (Con) Low adoption (3 likes) and last published 2024; the compass API is
  small and stable, but this is a maintenance-tail risk to re-evaluate if the
  package breaks on a future Flutter major.
- (Con) Magnetometer heading is noisy / affected by magnetic interference →
  mitigated by EMA smoothing on `compassHeadingProvider` and a graceful
  fallback to the Phase-A orbit angle when `bearing`/`heading` is unavailable.
- (Con) Device-only to validate (no compass in the simulator) — covered by the
  B0 diagnostic overlay + the combined prod two-phone device pass.
