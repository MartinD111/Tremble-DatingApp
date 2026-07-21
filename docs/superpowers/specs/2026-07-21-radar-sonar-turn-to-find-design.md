# FEATURE-RADAR-SONAR — Turn-to-Find Sonar (Design)

**Date:** 2026-07-21 · **Session:** 56 · **Risk:** HIGH (core trembling feature + new sensor dependency + BLE, device-only to validate)
**Branch:** `feature/radar-sonar` · **Status:** design approved (founder, Session 56)
**Related:** blocker `FEATURE-RADAR-SONAR`, memory `radar-sonar-search-feature`, ADR-008 (compass dependency, to be written)

---

## 1. Problem & confirmed root cause

The trembling-window radar is ~90% visually complete but the **partner dot never appears**. Root cause is confirmed in code (Session 55 trace, re-verified Session 56):

- The dot painter is fully wired — `radar_painter.dart:135` `_drawSonarPing` draws the dot at `pingDistance × maxRadius` along `pingAngle` whenever `pingDistance != null`.
- `pingDistanceProvider` / `pingAngleProvider` (`home_screen.dart:64-65`, default `null`) have **exactly one writer**: the dev-sim bridge (`home_screen.dart:445-453`, gated on `devSim.isMutualWaveActive`).
- In a **real** mutual wave nothing feeds them → they stay `null` → no dot.

**This is a missing production data source, not a render bug.** The animation layer already implements more than expected:

| Mechanic | Status |
|---|---|
| Pulse rate by distance (close→250ms, far→2000ms) + haptic per ping | Already built (`radar_animation.dart:96` `_calculatePingDuration`) |
| Stop the sweep during an active search | Already built (`home_screen.dart:870` sets `isScanning:false`; `radar_animation.dart:112` stops the sweep controller) |
| Dot radius by distance | Already built (painter) |
| **Feed `pingDistance`/`pingAngle` from real signals** | **Missing — this feature** |

## 2. Product vision (founder, verbatim intent)

A **privacy-by-design search-and-rescue sonar**. Turn the phone and the partner's position on the radar turns with it — you *hunt* by rotating, not by reading a pin. **Privacy is the point:** never a fixed/absolute location, never a map pin, precision deliberately capped. "Precision can never be 100% — privacy is much more important."

## 3. The governing constraint & the resolution

**BLE RSSI gives distance, never bearing.** No sensor says "the partner is that way." Two independent findings resolve this:

1. **BLE only resolves the last ~20–30m.** The app already pre-filters by GPS geohash *because* BLE alone can't cover the radius (Free 100m / Premium 250m). An RSSI-only sonar would leave ~220m of the radius unguided, and its direction inference (RSSI-peak-vs-heading) is the noisiest, spike-heaviest part.
2. **Tremble already publishes a privacy-minimized coarse location.** `geo_service.dart` writes **only a geohash at precision 7** (~150m×75m cell, reversible to ~75m) to Firestore — raw GPS is never stored (GDPR data-minimization). The proximity model is explicitly two-stage: *"GPS geohash = coarse pre-filter; BLE RSSI confirms final proximity."*

**Resolution — a two-stage homing beacon that reuses existing infrastructure:**

| Regime | Distance | Direction source | Distance source | Status of infra |
|---|---|---|---|---|
| **Approach** | 250m → ~30m | `geohashBearing − compassHeading` (real, fuzzed to ~75m) | coarse distance bucket from geohash | geohash exists; add compass + bearing math |
| **Final approach** | ~30m → 0m | (bearing unreliable at this range) → falls back to orbit/last bearing | **BLE RSSI warmth** (warmer/colder) | `warmth_controller.dart` already ships |

The dot points a **deterministic** direction (geohash-derived), not a flaky RSSI-peak guess. **The scary RSSI directional inference drops off the critical path.** BLE returns to doing only what it already does well — warmth for the last few meters. Privacy is preserved because the bearing is built from the geohash-7 that is *already* deliberately fuzzed to ~75m; precision is capped by the existing design.

## 4. Approved decisions (Session 56)

| # | Decision | Choice |
|---|---|---|
| D1 | Direction signal | **Hybrid**: geohash bearing (approach) + BLE warmth (final) |
| D2 | Bearing computation | **Server-side** — computed from both geohashes, written as `bearing`/`distanceBucket` on the active match/session doc (or a callable). Partner's geohash **never reaches the client**. Client adds local compass heading each frame (turning never hits the backend). |
| D3 | Compass dependency | **`flutter_compass_v2`** (fused, tilt-compensated heading in degrees; smallest custom-math surface). Version pinned + pub.dev health verified in **ADR-008**. |
| D4 | Closer/further feel | Dot **radius + pulse rate together** (both already built) |
| D5 | Angle when no bearing yet / same geohash cell | **Slow orbit** ("distance known, direction searching") — fallback |
| D6 | Warmth text coexistence | Dot primary + **keep the subtle warmth caption** (existing `_warmthIndicator`) |
| D7 | Signal loss (geohash stale AND no RSSI) | **Fade to "Searching…"**, hold last hint briefly first |

## 5. Architecture (Approach 1)

```
ble.proximityStream ──┐
                      ├─► SonarPingController (@riverpod, PURE math, TDD'd)
partner bearing/dist ─┘        emits SonarPing { radius, bearing?, stage, signalState }
   (server field)                      │
compass heading  ──────────────────────┤  (combined client-side, per frame)
                                       ▼
        production writer arm (home_screen.dart:445, beside the dev-sim arm)
                                       ▼
      pingDistanceProvider / pingAngleProvider ─ unchanged ─► RadarAnimation ─► RadarPainter (dot)
```

### Components

- **`SonarPingController`** (new, `@riverpod`) — mirrors the proven `WarmthController` pattern: same `ble.proximityStream` + partnerId from `currentSearchProvider`, plus the server bearing field. Emits an immutable `SonarPing`. All mapping is **pure and unit-tested** with fakes:
  - `rssi → radius` (near → 0.0 center, far → 1.0 edge; EWMA-smoothed to stabilize the dot)
  - `stage` selection (approach vs final, keyed on whether partner RSSI is live above threshold)
  - `signalState` machine: `fresh → graceHold → searching`
- **Server bearing field** (D2) — a Cloud Function computes `bearing` + `distanceBucket` from the two geohash-7 values on the active session and writes them to the session/match doc; recompute fires only on geohash-cell change (geo updates already throttled to 50m/90s → cheap). Deliberately fuzzed; no coordinates, no pin.
- **Writer arm** (`home_screen.dart:445`) — the missing production data source: when `currentSearchProvider` is active, pipe `SonarPing` → the ping providers. Dev-sim arm retained for simulator work.
- **Orbit helper** (small, pure) — advances `pingAngle` when no bearing is available; driven by a slow AnimationController in `RadarAnimation`.

### Reused untouched
`radar_painter.dart` (dot math), the pulse-rate + sweep-stop logic in `radar_animation.dart`, `warmth_controller.dart` (final-stage warmth), `geo_service.dart` (geohash), the provider→painter chain.

## 6. Dot behavior (state machine)

```
              partner RSSI live (≥ threshold)?
                     │                    │
                    no                   yes
                     ▼                    ▼
        bearing available?          FINAL STAGE
          │            │            radius ← RSSI (smoothed)
         no           yes           angle  ← last bearing − heading (or orbit)
          ▼            ▼            warmth caption ← warmth_controller
     ORBIT         APPROACH STAGE
   radius ← bucket  radius ← distanceBucket
   angle  ← slow    angle  ← bearing − compassHeading
   orbit            pulse rate ← distance (existing)

  signalState = searching  (geohash stale AND no RSSI for > grace window)
          ▼
   dot fades, caption → "Searching…", hold last hint during grace
```

## 7. Privacy posture

- **No pin, ever.** The dot is a direction + coarse distance, never a coordinate.
- **Geohash-7 only** (~75m fuzz) — reuses the existing GDPR-minimized field; no new location data is collected or shared.
- **Server-side bearing (D2)** — the partner's geohash never reaches the other client; only `bearing` + `distanceBucket` are returned. Turning the phone is resolved locally by the compass and never contacts the backend.
- Precision is capped by design, satisfying the founder's "never 100%, privacy wins" principle.

## 8. New dependency & ADR

`flutter_compass_v2` is the only new dependency. This is the MPC HIGH-risk `dependencies.md` lane and requires **ADR-008** (context, decision, version pin, pub.dev/maintenance verification, alternatives: `sensors_plus` raw + hand-rolled heading, original stale `flutter_compass`). Founder approval of this design covers the dependency decision; ADR-008 records it.

## 9. Testing & validation

- **Unit (TDD, must be CI-green):** `rssi→radius`, `bearing = f(geohashA, geohashB)`, `dotAngle = wrap(bearing − heading)`, stage-handoff thresholds, `signalState` machine, orbit-angle helper. Server bearing function tested with the existing Functions test harness.
- **Device-only (two phones, founder):** the *felt* hunt — does turning center them, is the handoff smooth, is geohash bearing usefully accurate at ~150m / ~50m. BLE + compass are absent in the simulator, so feel cannot be simulated. Planned as a founder device pass.
- The spike concern is largely retired: direction is deterministic geohash math, not RSSI peak-finding. We validate *feel*, not *viability*. If sub-30m bearing proves not precise enough on device, the RSSI-peak directional refinement returns as a scoped v2 — the orbit/warmth fallback keeps v1 graceful regardless.

## 10. Scope

**In (this session):** `flutter_compass_v2` + ADR-008; `SonarPingController` + pure math; server bearing/distance field; writer wiring; orbit fallback; signal-loss UX; warmth handoff; unit tests; branch/atomic commits/PR with `[PLAN-ID]` + verification checklist; founder device pass.

**Deferred (v2):** RSSI-peak directional refinement for sub-30m bearing (only if the geohash+warmth handoff proves imprecise on device); richer Pulse Intercept meetup cues.

## 11. Risks & mitigations

| Risk | Mitigation |
|---|---|
| Geohash bearing too coarse at short range | By design — BLE warmth takes over < ~30m; orbit fallback covers gaps |
| Compass heading noisy/jittery | `flutter_compass_v2` fused heading; smoothing; device validation before ship |
| `flutter_compass_v2` fork maintenance | Verified in ADR-008; `sensors_plus` fallback documented |
| Server bearing recompute cost | Fires only on geohash-cell change (throttled 50m/90s) |
| Felt behavior can't be unit-tested | Pure math is TDD'd in CI; feel validated on two phones (founder) |
| Location privacy | Server-side bearing; geohash-7 reuse; no coordinates/pin ever leave the server |
