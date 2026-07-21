# Radar Sonar — Turn-to-Find Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the trembling-window radar plot a live partner dot from real signals — distance from BLE RSSI (dot radius + pulse rate), and, in Phase B, direction from a server-computed geohash bearing combined with the device compass, so the user hunts by rotating the phone.

**Architecture:** A pure, unit-tested `SonarPingController` (evolved from the orphaned `ProximityPingController`) sources the partner's smoothed RSSI from `ble.proximityStream` and emits an immutable `SonarPing`. A production writer arm in `home_screen.dart` (beside the existing dev-sim arm) feeds `pingDistanceProvider`/`pingAngleProvider`, which the already-wired `RadarAnimation`→`RadarPainter` chain renders. Phase B layers a server-side geohash `bearing` (reusing `decodeGeohash` in `proximity.functions.ts`) and a `flutter_compass_v2` heading to turn the orbit into a real bearing.

**Tech Stack:** Flutter 3 · Riverpod 2 (`@riverpod` codegen) · Firebase Cloud Functions (TypeScript) · `dart_geohash` (client, existing) · `flutter_compass_v2` (Phase B, new) · flutter_test + mocktail-style hand fakes.

## Global Constraints

- Run/test with `--flavor dev --dart-define=FLAVOR=dev`; never cross dev/prod projects.
- Immutability: `SonarPing` is `@immutable` with `copyWith`; no in-place mutation.
- Dart format (80 col), `dart analyze` clean, `flutter test` green before every commit (commit-quality hook enforces).
- No new client dependency in Phase A. Phase B's `flutter_compass_v2` requires ADR-008 + founder approval before `pubspec.yaml` changes.
- Privacy: never store/read raw lat-lng; bearing is computed server-side from geohash-7 only and returned as `bearing` (0–359°) + `distanceBucket` (string) — the partner's geohash never reaches the client. No map pin, ever.
- RSSI convention (match existing code): `-40 dBm` = very close, `-100 dBm` = far. Painter convention: `pingDistance` `0.0` = center, `1.0` = edge. Therefore near → small radius (center).
- PR: `[PLAN-ID: 20260721-radar-sonar-turn-to-find]`, body with Verification checklist (unit tests / integration tests / security scan). ADR-008 committed in Phase B.

---

## File Structure

**Phase A (client, no new deps):**
- Modify → rename responsibility: `lib/src/features/dashboard/application/proximity_ping_controller.dart` → becomes `SonarPingController` emitting `SonarPing` (keeps the vibration loop; adds the dot data). Orphaned today (zero consumers), safe to evolve.
- Create: `lib/src/features/dashboard/domain/sonar_ping.dart` — immutable `SonarPing` + pure mappers (`rssiToRadius`, `SonarSignalState`).
- Create: `lib/src/features/dashboard/domain/sonar_math.dart` — pure helpers (`orbitAngle`, Phase B `dotAngle`).
- Modify: `lib/src/features/dashboard/presentation/home_screen.dart:445-453` — add production writer arm; keep the controller alive via a watch in `_RadarSection` (`:2272`).
- Modify: `lib/src/features/dashboard/presentation/widgets/radar_search_overlay.dart` — "Searching…" caption on signal loss (extends existing `_warmthIndicator`).
- Tests: `test/features/dashboard/sonar_ping_test.dart`, `test/features/dashboard/sonar_math_test.dart`, `test/features/dashboard/sonar_ping_controller_test.dart`.

**Phase B (compass + server bearing):**
- Create: `docs/adr/ADR-008-compass-dependency.md`; Modify: `pubspec.yaml` (+`flutter_compass_v2`).
- Create: `lib/src/core/compass_service.dart` + `compassHeadingProvider` (degrees stream).
- Modify: `lib/src/features/match/domain/match.dart` — add `bearing`/`distanceBucket` fields to `Match.fromFirestore`.
- Modify: `functions/src/modules/proximity/proximity.functions.ts` — compute + write `bearing`/`distanceBucket` on the match doc (reuse `decodeGeohash`).
- Tests: `functions/src/__tests__/match_bearing.test.ts`, extend `sonar_math_test.dart` (`dotAngle`).

---

## PHASE A — Resurrect the dot from real RSSI (no new deps, device-testable)

### Task A1: `SonarPing` model + `rssiToRadius`

**Files:**
- Create: `lib/src/features/dashboard/domain/sonar_ping.dart`
- Test: `test/features/dashboard/sonar_ping_test.dart`

**Interfaces:**
- Produces: `enum SonarSignalState { fresh, graceHold, searching }`; `class SonarPing { final double? radius; final double? angle; final SonarSignalState signalState; }` with `const` ctor + `copyWith`; `double rssiToRadius(double rssi)`.

- [ ] **Step 1: Write the failing test**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/dashboard/domain/sonar_ping.dart';

void main() {
  group('rssiToRadius', () {
    test('very close (-40 dBm) maps to center (0.0)', () {
      expect(rssiToRadius(-40), closeTo(0.0, 0.001));
    });
    test('far (-100 dBm) maps to edge (1.0)', () {
      expect(rssiToRadius(-100), closeTo(1.0, 0.001));
    });
    test('mid (-70 dBm) maps to ~0.5', () {
      expect(rssiToRadius(-70), closeTo(0.5, 0.02));
    });
    test('clamps values beyond the range', () {
      expect(rssiToRadius(-10), 0.0);
      expect(rssiToRadius(-140), 1.0);
    });
  });

  test('SonarPing.copyWith overrides only given fields', () {
    const p = SonarPing(radius: 0.4, angle: 1.0, signalState: SonarSignalState.fresh);
    final q = p.copyWith(signalState: SonarSignalState.searching);
    expect(q.radius, 0.4);
    expect(q.angle, 1.0);
    expect(q.signalState, SonarSignalState.searching);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/dashboard/sonar_ping_test.dart`
Expected: FAIL — `sonar_ping.dart` / `rssiToRadius` not defined.

- [ ] **Step 3: Write minimal implementation**
```dart
import 'package:flutter/foundation.dart';

/// Freshness of the partner signal driving the sonar dot.
enum SonarSignalState { fresh, graceHold, searching }

/// One frame of sonar state consumed by the radar ping providers.
/// `radius`: 0.0 = center (close) … 1.0 = edge (far); null = no dot.
/// `angle`: radians for the dot's bearing on the radar; null = unknown.
@immutable
class SonarPing {
  const SonarPing({this.radius, this.angle, this.signalState = SonarSignalState.searching});

  final double? radius;
  final double? angle;
  final SonarSignalState signalState;

  SonarPing copyWith({double? radius, double? angle, SonarSignalState? signalState}) =>
      SonarPing(
        radius: radius ?? this.radius,
        angle: angle ?? this.angle,
        signalState: signalState ?? this.signalState,
      );

  static const empty = SonarPing();
}

/// Maps smoothed RSSI (dBm) to a radar radius. -40 dBm (close) → 0.0 (center),
/// -100 dBm (far) → 1.0 (edge). Matches the existing proximity factor range.
double rssiToRadius(double rssi) {
  final factor = (rssi.clamp(-100.0, -40.0) + 100.0) / 60.0; // 0 far … 1 close
  return 1.0 - factor;
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/dashboard/sonar_ping_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**
```bash
git add lib/src/features/dashboard/domain/sonar_ping.dart test/features/dashboard/sonar_ping_test.dart
git commit -m "feat(radar): SonarPing model + rssiToRadius mapping"
```

---

### Task A2: Signal-state machine (fresh → graceHold → searching)

**Files:**
- Modify: `lib/src/features/dashboard/domain/sonar_ping.dart`
- Test: `test/features/dashboard/sonar_ping_test.dart`

**Interfaces:**
- Produces: `SonarSignalState signalStateFor({required Duration sinceLastSample, Duration grace = const Duration(seconds: 3), Duration lost = const Duration(seconds: 6)})`.

- [ ] **Step 1: Write the failing test**
```dart
group('signalStateFor', () {
  test('fresh within grace', () {
    expect(signalStateFor(sinceLastSample: const Duration(seconds: 1)), SonarSignalState.fresh);
  });
  test('graceHold between grace and lost', () {
    expect(signalStateFor(sinceLastSample: const Duration(seconds: 4)), SonarSignalState.graceHold);
  });
  test('searching past lost threshold', () {
    expect(signalStateFor(sinceLastSample: const Duration(seconds: 7)), SonarSignalState.searching);
  });
});
```

- [ ] **Step 2: Run to verify it fails** — `flutter test test/features/dashboard/sonar_ping_test.dart` → FAIL (undefined `signalStateFor`).

- [ ] **Step 3: Implement**
```dart
SonarSignalState signalStateFor({
  required Duration sinceLastSample,
  Duration grace = const Duration(seconds: 3),
  Duration lost = const Duration(seconds: 6),
}) {
  if (sinceLastSample <= grace) return SonarSignalState.fresh;
  if (sinceLastSample <= lost) return SonarSignalState.graceHold;
  return SonarSignalState.searching;
}
```

- [ ] **Step 4: Run to verify it passes** — Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/src/features/dashboard/domain/sonar_ping.dart test/features/dashboard/sonar_ping_test.dart
git commit -m "feat(radar): sonar signal-state machine (fresh/graceHold/searching)"
```

---

### Task A3: Orbit-angle helper

**Files:**
- Create: `lib/src/features/dashboard/domain/sonar_math.dart`
- Test: `test/features/dashboard/sonar_math_test.dart`

**Interfaces:**
- Produces: `double orbitAngle(Duration elapsed, {Duration period = const Duration(seconds: 10)})` → radians in `[0, 2π)`.

- [ ] **Step 1: Failing test**
```dart
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/dashboard/domain/sonar_math.dart';

void main() {
  group('orbitAngle', () {
    test('starts at 0', () {
      expect(orbitAngle(Duration.zero), closeTo(0.0, 1e-9));
    });
    test('quarter period ≈ π/2', () {
      expect(orbitAngle(const Duration(milliseconds: 2500)), closeTo(math.pi / 2, 1e-3));
    });
    test('wraps at full period', () {
      expect(orbitAngle(const Duration(seconds: 10)), closeTo(0.0, 1e-3));
    });
  });
}
```

- [ ] **Step 2: Run → FAIL** (`orbitAngle` undefined).

- [ ] **Step 3: Implement**
```dart
import 'dart:math' as math;

/// Slow orbit angle (radians) used when no real bearing is available yet.
/// Full sweep every [period]. Range [0, 2π).
double orbitAngle(Duration elapsed, {Duration period = const Duration(seconds: 10)}) {
  final t = elapsed.inMicroseconds / period.inMicroseconds;
  final frac = t - t.floorToDouble();
  return frac * 2 * math.pi;
}
```

- [ ] **Step 4: Run → PASS.**

- [ ] **Step 5: Commit**
```bash
git add lib/src/features/dashboard/domain/sonar_math.dart test/features/dashboard/sonar_math_test.dart
git commit -m "feat(radar): pure orbitAngle helper for direction-searching state"
```

---

### Task A4: `SonarPingController` (evolve the orphaned ProximityPingController)

**Files:**
- Modify: `lib/src/features/dashboard/application/proximity_ping_controller.dart` (rename class → `SonarPingController`, state `bool` → `SonarPing`)
- Test: `test/features/dashboard/sonar_ping_controller_test.dart`

**Interfaces:**
- Consumes: `bleServiceProvider` (`ble.proximityStream` : `Stream<Map<String,int>>`), `currentSearchProvider` (`Match?`), `authStateProvider`, `effectiveIsPremiumProvider`, `rssiToRadius`, `signalStateFor`, `SonarPing`.
- Produces: `sonarPingControllerProvider` → `SonarPing`. Keeps the existing vibration ping loop.

- [ ] **Step 1: Write the failing test** (fake BLE stream drives radius)
```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tremble/src/core/ble_service.dart';
import 'package:tremble/src/features/dashboard/application/proximity_ping_controller.dart';
import 'package:tremble/src/features/dashboard/domain/sonar_ping.dart';
// + import fakes for currentSearchProvider / authState / effectiveIsPremium overrides

void main() {
  test('emits a radius from partner RSSI when a mutual search is active', () async {
    final controller = StreamController<Map<String, int>>.broadcast();
    addTearDown(controller.close);
    final container = ProviderContainer(overrides: [
      bleServiceProvider.overrideWithValue(_FakeBle(controller.stream)),
      // override currentSearchProvider → mutual Match(userIds:['me','partner']),
      // authStateProvider → user id 'me', effectiveIsPremiumProvider → false
    ]);
    addTearDown(container.dispose);

    container.read(sonarPingControllerProvider); // instantiate
    controller.add({'partner': -40}); // very close
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final ping = container.read(sonarPingControllerProvider);
    expect(ping.radius, closeTo(0.0, 0.05)); // close → center
    expect(ping.signalState, SonarSignalState.fresh);
  });
}
```
(Include a `_FakeBle implements BleService` returning the injected stream and no-op `setHighFrequencyMode`.)

- [ ] **Step 2: Run → FAIL** (`sonarPingControllerProvider`/`SonarPing` state not present).

- [ ] **Step 3: Implement** — change `build()` return type to `SonarPing`, seed `SonarPing.empty`; in the `proximityStream` listener, after EMA smoothing set `state = state.copyWith(radius: rssiToRadius(_smoothedRssi!), signalState: SonarSignalState.fresh, angle: orbitAngle(_stopwatch.elapsed))` and stamp `_lastSampleAt`. Keep the vibration loop. Add a periodic 500ms `Timer` that recomputes `signalStateFor(now - _lastSampleAt)` and, when `searching`, sets `radius:null`. Rename class/part to `SonarPingController`; regenerate codegen.

- [ ] **Step 4: Run codegen + test**
Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/features/dashboard/sonar_ping_controller_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/src/features/dashboard/application/proximity_ping_controller.dart lib/src/features/dashboard/application/proximity_ping_controller.g.dart test/features/dashboard/sonar_ping_controller_test.dart
git commit -m "feat(radar): SonarPingController emits SonarPing from real RSSI"
```

---

### Task A5: Production writer arm + keep-alive

**Files:**
- Modify: `lib/src/features/dashboard/presentation/home_screen.dart:445-453` (writer arm) and `:2272` (`_RadarSection` watch)
- Test: covered by A4 controller test + a widget smoke test asserting `pingDistanceProvider` populates when a mutual search is active.

**Interfaces:**
- Consumes: `sonarPingControllerProvider`, `currentSearchProvider`, `pingDistanceProvider`, `pingAngleProvider`.

- [ ] **Step 1:** In `_RadarSection.build` (`:2272`) add `final sonar = ref.watch(sonarPingControllerProvider);` so the controller stays alive during a search (no behavior change otherwise).

- [ ] **Step 2:** Add a production writer `ref.listen` beside the dev-sim arm (`:445`):
```dart
// ── Production Sonar → Radar Ping bridge ───────────────────────────────
ref.listen(sonarPingControllerProvider, (prev, next) {
  final searching = ref.read(currentSearchProvider) != null;
  final devActive = ref.read(devSimulationControllerProvider).isMutualWaveActive;
  if (!searching || devActive) return; // dev-sim arm owns the providers in sim
  ref.read(pingDistanceProvider.notifier).state = next.radius;
  ref.read(pingAngleProvider.notifier).state = next.angle;
});
```

- [ ] **Step 3: Run analyze + full suite**
Run: `flutter analyze && flutter test`
Expected: clean + green.

- [ ] **Step 4: Commit**
```bash
git add lib/src/features/dashboard/presentation/home_screen.dart
git commit -m "feat(radar): production writer feeds ping providers from SonarPingController"
```

---

### Task A6: "Searching…" caption on signal loss

**Files:**
- Modify: `lib/src/features/dashboard/presentation/widgets/radar_search_overlay.dart` (`_warmthIndicator` area ~`:197-243`)
- Add i18n key `searching` in `core/translations.dart` (EN + SL).
- Test: `test/features/dashboard/radar_search_overlay_test.dart` (widget: searching state shows the caption).

- [ ] **Step 1:** Failing widget test — override `sonarPingControllerProvider` to `SonarPing(signalState: searching)`, pump overlay, expect `find.text(<searching label>)`.
- [ ] **Step 2: Run → FAIL.**
- [ ] **Step 3:** In `build`, read `ref.watch(sonarPingControllerProvider).signalState`; when `searching`, render a subtle "Searching…" row (mirror `_warmthIndicator` styling) above the pill; otherwise keep the existing warmth caption.
- [ ] **Step 4: Run → PASS**, then `flutter analyze && flutter test`.
- [ ] **Step 5: Commit**
```bash
git add lib/src/features/dashboard/presentation/widgets/radar_search_overlay.dart lib/src/core/translations.dart test/features/dashboard/radar_search_overlay_test.dart
git commit -m "feat(radar): searching caption + dot fade on signal loss"
```

**⇒ Phase A checkpoint (device pass, founder):** two phones, mutual wave → confirm the dot appears, radius tracks closer/further, ping rate speeds up when closer, dot orbits (no bearing yet), fades to "Searching…" on walk-away. This validates the whole render pipeline before Phase B commits the new dependency.

---

## PHASE B — Turn-to-find direction (ADR-008 + server geohash bearing)

> Starts only after: (a) Phase A device pass is good, (b) ADR-008 approved by founder.

### Task B1: ADR-008 + add `flutter_compass_v2`
- [ ] Write `docs/adr/ADR-008-compass-dependency.md` (context; decision: `flutter_compass_v2`; verified pub.dev version + maintenance; alternatives: `sensors_plus` raw heading, stale `flutter_compass`; risks). Pin exact version.
- [ ] Add the pinned dep to `pubspec.yaml`; `flutter pub get`; add iOS `NSLocationWhenInUseUsageDescription` note if the plugin requires it (verify in ADR).
- [ ] Commit: `chore(deps): add flutter_compass_v2 for radar bearing (ADR-008)`.

### Task B2: Server bearing + distance bucket
**Files:** Modify `functions/src/modules/proximity/proximity.functions.ts`; Test `functions/src/__tests__/match_bearing.test.ts`.
- [ ] TDD `computeBearing(a:{lat,lng}, b:{lat,lng}): number` (0–359°, standard forward-azimuth formula) and `distanceBucket(meters): 'close'|'~50m'|'~150m'|'far'`. Reuse existing `decodeGeohash`.
- [ ] On the geo/match update path (where `decodeGeohash` + distance already run, ~`:636`), when an active match exists for the pair, write `{ bearing, distanceBucket }` onto the match doc. Bearing is from each user's perspective → store `bearingFor: { [uid]: degrees }` (A→B and B→A differ by 180°).
- [ ] Jest: `npm --prefix functions test -- match_bearing`. Expected PASS.
- [ ] Commit: `feat(proximity): server-computed bearing + distance bucket on match doc`.

### Task B3: Compass heading provider + `dotAngle`
**Files:** Create `lib/src/core/compass_service.dart`; extend `sonar_math.dart` + `sonar_math_test.dart`; modify `match.dart`.
- [ ] TDD `double dotAngle({required double bearingDeg, required double headingDeg})` → radians, `wrap(bearing - heading)` into `[0,2π)` (e.g. facing the bearing → 0 = top). Cases: equal → 0; heading 90° behind → π/2; wrap across 360.
- [ ] Add `compassHeadingProvider` (`Stream<double>` degrees from `FlutterCompass.events`, null-safe, smoothed).
- [ ] Add `bearing`/`distanceBucket` (+ per-uid bearing) to `Match.fromFirestore`.
- [ ] Commit: `feat(radar): compass heading provider + dotAngle math`.

### Task B4: Integrate direction into the controller + writer
**Files:** Modify `proximity_ping_controller.dart`, `home_screen.dart`.
- [ ] `SonarPingController` also watches `compassHeadingProvider` + the match `bearing`; when bearing present → `angle = dotAngle(bearing, heading)`, else → `orbitAngle`. Radius: RSSI when live (final stage), else `distanceBucket`→radius (approach stage).
- [ ] Extend controller test: bearing 90°, heading 90° → angle ≈ 0 (dot at top).
- [ ] Commit: `feat(radar): turn-to-find — bearing+heading drive the dot angle`.

**⇒ Phase B checkpoint (device pass, founder):** two phones ~150m then ~30m apart → dot points the real direction, turning the phone re-centers it, handoff to warmth in the final meters feels smooth. If sub-30m bearing is too coarse → open v2 RSSI-peak refinement (fallback already graceful).

---

## Self-Review

- **Spec coverage:** D1 hybrid → Phases A+B; D2 server bearing → B2/B3; D3 flutter_compass_v2 → B1; D4 radius+pulse → A1 (+existing `_calculatePingDuration`); D5 orbit fallback → A3/A4/B4; D6 warmth caption kept → A6; D7 signal loss → A2/A6. Root-cause writer gap → A5. All covered.
- **Placeholder scan:** Phase A steps carry real code + exact commands. Phase B tasks are interface-and-test-named (not code-complete) **by design** — they are gated behind ADR-008 + Phase A device validation; each will be expanded to full TDD steps at execution time once the dependency version and device findings are fixed. Flagged explicitly, not hidden.
- **Type consistency:** `SonarPing{radius,angle,signalState}`, `SonarSignalState`, `rssiToRadius`, `signalStateFor`, `orbitAngle`, `dotAngle`, `sonarPingControllerProvider` used consistently A1→B4.

---

## MPC gate

This is a **HIGH-risk** feature (core trembling flow + new sensor dependency + BLE). Per MPC, founder approval of this plan is required before the TDD build begins, and ADR-008 gates Phase B. Phase A carries no new dependency and is safe to build on plan approval.
