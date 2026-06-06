# Strategy Compliance Audit — Step 7 Notifications

Date: 2026-06-06
Domain: Notifications
Scope: Read-only audit. No code changes.

## Summary

- Scenario 1 — Proximity event: MISMATCH. Current payload is normal, not silent.
- Scenario 2 — Wave received: MISMATCH. Current payload is normal, not silent.
- Scenario 3 — Mutual wave: MISMATCH. Payload is normal, but tap navigation opens `match_reveal`, not the `/radar` active radar path.
- Scenario 4 — 2nd+ encounter after wave: MISMATCH. Not implemented.
- Scenario 5 — Recap after activity: MISMATCH. No push notification; only an in-app bottom sheet after Run Club deactivation.
- Scenario 6 — Near-Miss monthly aggregate push: MISMATCH. Not implemented.
- Scenario 7 — During Run/Gym/Event DND: MISMATCH. No DND/silent suppression found, except mutual waves are normal.

## Scenario 1 — Proximity Event, New Person Nearby

Status: MISMATCH

Required: SILENT — data-only push, no sound, no banner.

Trigger found:
- `scanProximityPairs` scheduled Cloud Function evaluates active proximity pairs and sends `CROSSING_PATHS`: `functions/src/modules/proximity/proximity.functions.ts:583-607`, `:737-812`.

Current payload:
```ts
// functions/src/modules/proximity/proximity.functions.ts:765-798
await messaging.send({
  token: fcmToken,
  notification: {
    title: "Tremble",
    body: `${name}, ${age} is nearby. Want to send a wave?`,
    imageUrl: photoUrl || undefined,
  },
  data: {
    type: "CROSSING_PATHS",
    fromUid: senderUid,
    senderId: senderUid,
    senderName: name,
    senderAge: age.toString(),
    senderPhotoUrl: photoUrl,
  },
  apns: { payload: { aps: { sound: "default", category: "NEARBY_CATEGORY" } } },
  android: { priority: "high", notification: { clickAction: "NEARBY_CATEGORY" } },
});
```

Silent vs normal:
- Normal. It includes a top-level `notification` block, APNs `sound: "default"`, Android `priority: "high"`, and Android notification fields.
- This will produce a banner/sound on background OS delivery.

Additional Dart behavior:
- Foreground handling suppresses the OS banner and shows an in-app pill for `CROSSING_PATHS`: `lib/src/core/notification_service.dart:222-241`.
- That foreground behavior does not make the FCM itself silent.

## Scenario 2 — Wave Received

Status: MISMATCH

Required: SILENT.

Trigger found:
- `sendWave` writes a `waves/{waveId}` document: `functions/src/modules/matches/matches.functions.ts:70-105`.
- `onWaveCreated` sends `INCOMING_WAVE` when no reciprocal wave exists: `functions/src/modules/matches/matches.functions.ts:342-382`.

Current payload:
```ts
// functions/src/modules/matches/matches.functions.ts:350-379
await messaging.send({
  token: receiverToken,
  notification: {
    title: `${senderName} ti je pomahal-a`,
    body: "Pomahaš nazaj?",
    imageUrl: senderPhoto || undefined,
  },
  data: {
    type: "INCOMING_WAVE",
    senderId: fromUid,
    senderName,
    senderAge: senderAge.toString(),
    senderPhotoUrl: senderPhoto,
    click_action: "WAVE_BACK_ACTION",
  },
  apns: { payload: { aps: { sound: "default", category: "WAVE_CATEGORY", "mutable-content": 1 } } },
  android: { priority: "high" },
});
```

Silent vs normal:
- Normal. It includes a top-level `notification` block and APNs `sound: "default"`.
- Foreground Dart renders an in-app pill for `INCOMING_WAVE`: `lib/src/core/notification_service.dart:222-241`, but background delivery is not silent.

## Scenario 3 — Mutual Wave

Status: MISMATCH

Required: NORMAL — sound + banner, opens active radar via deeplink.

Trigger found:
- `onWaveCreated` detects reciprocal waves and sends `MUTUAL_WAVE`: `functions/src/modules/matches/matches.functions.ts:185-196`, `:276-333`.
- Run Club mutual wave path also sends `MUTUAL_WAVE`: `functions/src/modules/proximity/proximity.functions.ts:871-988`.

Current standard mutual-wave payload:
```ts
// functions/src/modules/matches/matches.functions.ts:281-302
messaging.send({
  token: receiverToken,
  notification: {
    title: `${senderName} ti je pomahal-a nazaj!`,
    body: "Odpremo radar?",
    imageUrl: senderPhoto || undefined,
  },
  data: {
    type: "MUTUAL_WAVE",
    matchId,
    path: "/radar",
  },
  apns: { payload: { aps: { sound: "default", "mutable-content": 1 } } },
  android: { priority: "high" },
});
```

Current Run Club mutual-wave payload:
```ts
// functions/src/modules/proximity/proximity.functions.ts:945-961
messaging.send({
  token: tokenA,
  notification: {
    title: `Ujeli smo se! 🏃‍♀️`,
    body: `${nameB} ti je pomahal-a nazaj! Odpremo radar?`,
    imageUrl: photoB || undefined,
  },
  data: { type: "MUTUAL_WAVE", matchId, path: "/radar" },
  apns: { payload: { aps: { sound: "default", "mutable-content": 1 } } },
  android: { priority: "high" },
});
```

Silent vs normal:
- Normal. This part matches: `notification` block, APNs sound, Android high priority.

Deeplink behavior:
- Payload includes `path: "/radar"`, but Dart ignores `path` and navigates to `match_reveal`: `lib/src/core/router.dart:214-233`.
- Router comment explicitly says it routes `MUTUAL_WAVE` to `MatchRevealScreen`: `lib/src/core/router.dart:173-175`.
- Therefore the active-radar deeplink requirement is not verified as implemented.

## Scenario 4 — 2nd+ Encounter After Wave Sent

Status: MISMATCH

Required: "To ni več naključje" — NORMAL notification, Premium-only.

Trigger found:
- No dedicated trigger found.
- Current `scanProximityPairs` only uses a 30-minute Redis pair cooldown: `functions/src/modules/proximity/proximity.functions.ts:679-685`.
- Current proximity event write contains no encounter count / repeat marker / wave-sent state: `functions/src/modules/proximity/proximity.functions.ts:714-722`.

Current payload:
- None. No notification payload for `"To ni več naključje"` exists.

Cross-check:
- Previous Step 4 audit also found this unimplemented: `tasks/audit_step4_history.md:113-125`.

Silent vs normal:
- Cannot be correct because the trigger/payload is absent.

Premium-only:
- No Premium gate found because the feature is absent.

## Scenario 5 — Recap After Activity

Status: MISMATCH

Required: NORMAL, sent once.

Trigger found:
- No Cloud Function push for post-activity recap found.
- Run Club deactivation emits an in-app bottom sheet, not a push notification: `lib/src/features/dashboard/presentation/home_screen.dart:1602-1666`.
- Duplicate display is only guarded locally by `_runRecapShown`: `lib/src/features/dashboard/presentation/home_screen.dart:80-81`, reset/set at `:412-416`.

Current payload:
- No FCM payload exists for recap-after-activity.
- There is a local Run Club deactivation notification, but it is not a recap prompt:
```dart
// lib/src/core/background_service.dart:256-270
await notificationsPlugin.show(
  3,
  '💤 Run Club izklopljen',
  'Upamo, da je bil dober tek.',
  NotificationDetails(
    android: AndroidNotificationDetails(
      'tremble_run_club',
      'Tremble Run Club',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  ),
  payload: 'run_club_deactivated',
);
```

Silent vs normal:
- The unrelated Run Club deactivation local notification is normal/default.
- The required recap push is absent.

Sent once:
- The in-app prompt is once per local `HomeScreen` run transition, not a server-side or push-level once guarantee.

## Scenario 6 — Near-Miss Aggregated Push

Status: MISMATCH

Required: Free users, 1x/month, NORMAL, count only — no names/photos.

Trigger found:
- No scheduled Near-Miss aggregate push Cloud Function found.
- Export list has no Near-Miss monthly scheduler: `functions/src/index.ts:27-87`.
- Previous Step 4 audit found the same gap: `tasks/audit_step4_history.md:169-180`.

Current payload:
- None.

Silent vs normal:
- Cannot be correct because the feature/payload is absent.

Count-only privacy:
- Cannot verify from payload because no payload exists.

## Scenario 7 — During Run/Gym/Event DND

Status: MISMATCH

Required: During Run/Gym/Event, all notifications SILENT except mutual wave.

Evidence:
- `scanProximityPairs` sends `CROSSING_PATHS` to both users after block/flag checks; it does not check `isRunModeActive`, `activeGymId`, or `activeEventId` before sending: `functions/src/modules/proximity/proximity.functions.ts:687-712`, `:765-812`.
- `onWaveCreated` reads `activeEventId` / `activeGymId` only to set match context/type, not to silence incoming-wave notifications: `functions/src/modules/matches/matches.functions.ts:234-248`.
- The incoming-wave branch sends a normal notification regardless of activity mode: `functions/src/modules/matches/matches.functions.ts:350-379`.
- Mutual wave remains normal, which matches the exception: `functions/src/modules/matches/matches.functions.ts:281-302`; Run Club mutual wave also normal at `functions/src/modules/proximity/proximity.functions.ts:945-982`.

Current non-mutual activity-mode payloads:
- Same normal `CROSSING_PATHS` payload as Scenario 1.
- Same normal `INCOMING_WAVE` payload as Scenario 2.

Silent vs normal:
- DND is not enforced. Non-mutual proximity and incoming-wave notifications can still be normal pushes during activity modes.

Additional local notifications:
- Run Club activation prompt is a normal local notification with high importance/priority: `lib/src/core/background_service.dart:218-239`.
- Run Club stationary/deactivation prompts are local notifications with default importance/priority: `lib/src/core/background_service.dart:256-297`.
- These are activity-control notifications, not the mutual-wave exception.

## Overall Findings

1. The two notifications that strategy requires to be silent (`CROSSING_PATHS`, `INCOMING_WAVE`) are currently normal OS notifications.
2. Mutual wave notification modality is normal, but the actual Dart tap route opens `match_reveal`, while the payload path says `/radar`.
3. "To ni več naključje", recap push, and monthly Near-Miss aggregate push are not implemented.
4. DND/silent suppression during Run/Gym/Event is not implemented for proximity or incoming-wave pushes.
