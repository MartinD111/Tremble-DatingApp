# Audit Step 6 — Heatmap & Map Events

**Date:** 2026-06-06  
**Auditor:** Claude Code CLI  
**Scope:** C-MAP-01 through C-MAP-06 (Heatmap/Map domain in STRATEGY_CLAIMS.md)  
**Files read:**
- `lib/src/features/map/presentation/tremble_map_screen.dart`
- `lib/src/features/map/presentation/event_pin_sheet.dart`
- `functions/src/modules/events/events.functions.ts`
- `lib/src/core/translations.dart` (pulsing_here / heatmap strings)

---

## Item 1 — Heatmap existence

**Claim:** C-MAP-01 / C-MAP-02 (Strategy Phase 3)

**State: DEFERRED (Phase 3)**

The heatmap is mock/placeholder, not a live backend feature.

Evidence:
- `tremble_map_screen.dart:50`: comment reads `// Dev mock proximity circles (replace with Firestore stream in prod).`
- `tremble_map_screen.dart:57`: `_proximityPoints = _isDev ? _generateProximityPoints() : const [];`
- `_generateProximityPoints()` (lines 62-71) uses a seeded random (`math.Random(42)`) to scatter 22–32 points around Ljubljana. This is purely local and deterministic; it has no connection to Firestore or any backend.
- In production builds (`FLAVOR=prod`), `_proximityPoints` is `const []` — no circles render.
- `functions/src/modules/events/events.functions.ts` contains no endpoint that returns proximity density or heatmap data.

**Verdict:** The heatmap is a dev-only visual mock. No backend feeds real data. This is consistent with Phase 3 not being shipped. Do not treat mock vs strategy as a discrepancy — noted per audit instructions.

---

## Item 2 — Heatmap gating (IF built)

**Claims:** C-MAP-01 (Free: circles visible, data inside hidden) | C-MAP-02 (Premium: count inside circle + filter toggle)

### C-MAP-01 — Free sees circles (data hidden)

**State: MISMATCH**

Strategy: Free users see heatmap circles on the map; only the data *inside* the circle (count, type) is hidden.

Code: `tremble_map_screen.dart:109-110`:
```dart
List<CircleMarker> _buildProximityCircles(bool effectivePremium) {
  if (!effectivePremium || _proximityPoints.isEmpty) return const [];
```

Free users (`effectivePremium = false`) get an empty list — **no circles at all**. The gating suppresses the entire circle layer rather than showing circles with hidden internals.

This is a behavioural mismatch with the strategy even if the heatmap were live. The correct implementation for Free would render `CircleMarker` objects but omit count/type overlays. The current implementation renders nothing for Free.

Since heatmap is Phase 3 / mock, this mismatch is inside unshipped code. Flag it now so the gating logic is corrected before Phase 3 ships, not after.

### C-MAP-02 — Premium: count inside circle + filter toggle

**State: MISMATCH**

Strategy: Premium sees the number of active users inside each heatmap circle, plus a filter toggle (by activity type).

Code:
- The circles themselves (`CircleMarker` at lines 112-121) are plain coloured circles — no count badge, no label inside the circle.
- The `EventPinSheet` (`event_pin_sheet.dart:316-357`) has a `_HeatmapActiveRow` widget that shows "Heatmap aktiven" with a "LIVE" badge. This is a label in the event bottom sheet, not a count inside a map circle.
- No filter toggle widget exists anywhere in `tremble_map_screen.dart` or `event_pin_sheet.dart`.

The heatmap "count inside circle" and "filter toggle by type" are not implemented. Again, this is inside Phase 3 unshipped code; flag for when Phase 3 is built.

---

## Item 3 — Map events gating

**Claims:** C-MAP-03 (Free: events visible, no participant count) | C-MAP-04 (Premium: active user count inside event)

### C-MAP-03 — Free sees events without participant count

**State: MATCH (UI logic correct; events list is empty)**

`event_pin_sheet.dart:138-149`:
```dart
effectiveIsPremium
    ? _PeopleCountRow(count: event.peopleCount, ...)
    : _LockedFeatureRow(
        label: t('pulsing_here', lang).replaceAll('{count}', '??'),
        sublabel: t('pro_feature_locked', lang),
        ...
      ),
```

Free users see a locked row with "?? people out tonight" and a Pro lock badge — the count is hidden. The docstring at `event_pin_sheet.dart:29` explicitly states: "Free tier: event name + time + share button. People count and heatmap hidden."

Caveat: `tremble_map_screen.dart:42`: `static const List<TrembleEventData> _events = [];` — the events list is empty, so no event markers appear in practice. The gating code is correct but untestable against real events.

### C-MAP-04 — Premium sees active user count

**State: MATCH (UI logic correct; events list is empty)**

`event_pin_sheet.dart:138-143`:
```dart
effectiveIsPremium
    ? _PeopleCountRow(count: event.peopleCount, ...)
```

`_PeopleCountRow` renders `t('pulsing_here', lang).replaceAll('{count}', '$count')` — for EN: "{count} people out tonight". Premium users see the count. Docstring: "Pro tier / Taste of Premium: all of the above + people count + heatmap indicator."

Same caveat as C-MAP-03: events list is empty; gating is correct but unexercised.

---

## Item 4 — Participant count: total active count, not match count

**Claims:** Strategy specifies "skupno, ne matchi" (total, not matches)

**State: CANNOT VERIFY (backend not wired)**

Client-side evidence is consistent with total count:
- `TrembleEventData.peopleCount` is a plain `int` with no "match" qualifier (`event_pin_sheet.dart:14`).
- Translation string `pulsing_here` = "{count} people out tonight" (all 8 languages use generic count language — no reference to "matches" or "compatible users").
- `_PeopleCountRow` displays `event.peopleCount` with a `Icons.favorite_rounded` icon and no filter or match qualifier.
- `functions/src/modules/events/events.functions.ts` does not return an `activeCount` field. The CF tracks `activeEventId` per user but no aggregated count is computed or returned to the client.

Since `_events` is empty and no CF returns an active user count for events, the "total vs matches" distinction cannot be verified end-to-end. The client model is neutral (could receive either), but the naming (`peopleCount`), translations (generic count language), and lack of any "matchCount" field in the CF schema are all consistent with total active count.

---

## Summary Table

| Claim | Description | Verdict | File:Line |
|---|---|---|---|
| C-MAP-01 | Heatmap existence | DEFERRED (Phase 3) | `tremble_map_screen.dart:50` |
| C-MAP-01 | Free sees heatmap circles (data hidden) | MISMATCH | `tremble_map_screen.dart:109-110` |
| C-MAP-02 | Premium sees count inside circle + filter toggle | MISMATCH | `tremble_map_screen.dart:109-121` |
| C-MAP-03 | Free sees events, participant count hidden | MATCH | `event_pin_sheet.dart:138-149` |
| C-MAP-04 | Premium sees active user count on event | MATCH | `event_pin_sheet.dart:138-143` |
| C-MAP-04 | Count is total (not matches) | CANNOT VERIFY | `functions/src/modules/events/events.functions.ts` (no activeCount returned) |

---

## Notes for Phase 3 implementation

1. **Heatmap gating fix needed before shipping:** Change `_buildProximityCircles` so Free users see circles (the density visual) but no count or type overlay inside. Premium users see circles plus count badge and a filter toggle. Current code hides everything from Free.
2. **Count inside circle:** The strategy says the count lives inside the circle on the map. Currently the "Heatmap aktiven" indicator lives inside `EventPinSheet` (event bottom sheet). These are conceptually different surfaces — clarify with the founder whether heatmap count belongs on the circle itself or in the event sheet.
3. **Filter toggle:** Not implemented anywhere. Phase 3 must add an activity-type filter UI (likely a row of toggles on the map screen or inside the sheet).
4. **Events backend:** `_events` is `const []`. Phase 3 must wire a Firestore stream to populate `TrembleEventData` objects and the CF must return/maintain `activeCount` per event.
