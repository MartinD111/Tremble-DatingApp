# Compliance Audit: Wave Mechanic & Limits

## 1. Wave Limit (Cap & Reset Window)
**Result:** MATCH (on constants and reset window), but with significant implementation bugs.

### Client-side Definitions
- **File:** [auth_repository.dart](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/features/auth/data/auth_repository.dart#L126-L131)
```dart
  bool get hasReachedFreeWaveLimit => !isPremium && wavesThisMonth >= 5;

  bool get hasReachedProWaveLimit => isPremium && wavesThisMonth >= 20;

  bool get hasReachedWaveLimit =>
      isPremium ? hasReachedProWaveLimit : hasReachedFreeWaveLimit;
```

### Server-side Definitions
- **File:** [matches.functions.ts](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/functions/src/modules/matches/matches.functions.ts#L34-L59)
```typescript
const MUTUAL_WAVE_FREE_LIMIT = 5;
const MUTUAL_WAVE_PREMIUM_LIMIT = 20;
const MUTUAL_WAVE_COUNTER_TIME_ZONE = "Europe/Ljubljana";

export function mutualWaveCounterField(now = new Date()): string {
    const parts = new Intl.DateTimeFormat("en-CA", {
        timeZone: MUTUAL_WAVE_COUNTER_TIME_ZONE,
        year: "numeric",
        month: "2-digit",
    }).formatToParts(now);

    const year = parts.find((part) => part.type === "year")?.value;
    const month = parts.find((part) => part.type === "month")?.value;

    if (!year || !month) {
        throw new Error("Failed to compute mutual wave counter month");
    }

    return `mutualWaves_${year}_${month}`;
}

export function mutualWaveLimitForUser(userData: FirebaseFirestore.DocumentData | undefined): number {
    return userData?.isPremium === true
        ? MUTUAL_WAVE_PREMIUM_LIMIT
        : MUTUAL_WAVE_FREE_LIMIT;
}
```

### Reset Window
- The reset window is a **calendar month** computed via `mutualWaves_YYYY_MM` using the `Europe/Ljubljana` time zone. This matches the requirement (not rolling 30 days).

---

## 2. Limit Enforcement Location
**Result:** MISMATCH & VULNERABILITY

### Server-side Enforcement Location
- **File:** [matches.functions.ts](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/functions/src/modules/matches/matches.functions.ts#L227-L232) (inside `onWaveCreated` background Firestore trigger transaction)
```typescript
                const userACount = mutualWaveCountForUser(userAData, counterField);
                const userBCount = mutualWaveCountForUser(userBData, counterField);
                const userALimit = mutualWaveLimitForUser(userAData);
                const userBLimit = mutualWaveLimitForUser(userBData);

                if (userACount >= userALimit || userBCount >= userBLimit) {
                    throw new HttpsError(
                        "resource-exhausted",
                        "Monthly mutual wave limit reached."
                    );
                }
```
- **VULNERABILITY 1:** The `sendWave` Cloud Callable function ([matches.functions.ts](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/functions/src/modules/matches/matches.functions.ts#L73-L112)) contains **no monthly limit checks** before writing a wave to the `waves` collection. Limit checks are deferred to the `onWaveCreated` background trigger transaction. A client calling `sendWave` will always receive a success response (`{ success: true }`) even if they are over their limit; the background trigger simply fails silently to the client, leaving the wave document in Firestore.

### Client-side Checks Mismatches
- **VULNERABILITY 2 (Data Source Mismatch):** The client fetches the wave count from the `rateLimits` collection (`rateLimits/{uid}:wave_monthly`):
  - **File:** [auth_repository.dart](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/features/auth/data/auth_repository.dart#L957-L970)
```dart
  Future<int> _fetchMonthlyWaveCount(String uid) async {
    try {
      // TODO(mutual-waves): This still reads the legacy sent-wave rateLimit doc.
      // Migrate wave count display to users/{uid}.mutualWaves_YYYY_MM.
      final doc = await _db
          .collection('rateLimits')
          .doc(waveMonthlyRateLimitDocId(uid))
          .get();
      return waveCountFromRateLimitData(doc.data());
    } catch (e) {
      debugPrint('[AUTH] Failed to fetch wave monthly rate limit for $uid: $e');
      return 0;
    }
  }
```
  However, the backend updates the actual count in the `users` document under `mutualWaves_YYYY_MM` field in `onWaveCreated`. This data source mismatch violates **Rule #4** and results in silent client-side bypasses.

- **VULNERABILITY 3 (Incorrect Getter Checked in UI):** The client-side UI files only check `hasReachedFreeWaveLimit` instead of `hasReachedWaveLimit`:
  - **File:** [profile_detail_screen.dart](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/features/profile/presentation/profile_detail_screen.dart#L558)
```dart
      final user = ref.read(authStateProvider);
      if (user?.hasReachedFreeWaveLimit == true) {
        PremiumPaywallBottomSheet.show(context);
        return;
      }
```
  - **File:** [home_screen.dart](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/features/dashboard/presentation/home_screen.dart#L117)
```dart
                final user = ref.read(authStateProvider);
                if (user?.hasReachedFreeWaveLimit == true) {
                  PremiumPaywallBottomSheet.show(context);
                  return;
                }
```
  - **File:** [router.dart](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/core/router.dart#L524)
```dart
          final user = ref.read(authStateProvider);
          if (user?.hasReachedFreeWaveLimit == true) {
            PremiumPaywallBottomSheet.show(context);
            return;
          }
```
  - **File:** [match_dialog.dart](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/features/matches/presentation/match_dialog.dart#L49)
```dart
    final user = ref.read(authStateProvider);
    if (user?.hasReachedFreeWaveLimit == true) {
      PremiumPaywallBottomSheet.show(context);
      return;
    }
```
  Since `hasReachedFreeWaveLimit` returns false for Premium users regardless of wave count, Premium users are **never capped at 20/month** by the client UI.

---

## 3. Mutual-Wave-Only Radar
**Result:** MATCH

- The radar / search overlay is displayed when a pending match exists:
  - **File:** [home_screen.dart](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/features/dashboard/presentation/home_screen.dart#L1207-L1223)
```dart
                                    final partnerId = activeMatch!
                                        .getPartnerId(user?.id ?? '');
                                    final profile = ref.watch(
                                        publicProfileProvider(partnerId));
                                    Widget buildOverlay(String name) =>
                                        RadarSearchOverlay(
                                          session: RadarSearchSession(
                                            partnerName: name,
                                            expiresAt: activeMatch.createdAt
                                                .add(const Duration(
                                                    minutes: 30)),
                                            onStop: () => ref
                                                .read(waveRepositoryProvider)
                                                .markMatchAsFound(
                                                    activeMatch.id),
                                          ),
                                        );
```
- Match documents in the `matches` collection are only created upon a mutual wave:
  - **Standard Proximity Match:** [matches.functions.ts](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/functions/src/modules/matches/matches.functions.ts#L186-L203)
```typescript
        // Check for reciprocal wave (mutual match)
        const reciprocalQuery = await db
            .collection("waves")
            .where("fromUid", "==", toUid)
            .where("toUid", "==", fromUid)
            .limit(1)
            .get();

        const messaging = getMessaging();

        if (!reciprocalQuery.empty) {
            // ── MUTUAL_WAVE: Create match + notify both ───

            const uids = [fromUid, toUid].sort();
            const matchId = `${uids[0]}_${uids[1]}`;
```
  - **Run Club Match:** [proximity.functions.ts](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/functions/src/modules/proximity/proximity.functions.ts#L893-L907)
```typescript
        // Check if both users sent a wave
        if (userIds.length === 2 && signals[userIds[0]] === true && signals[userIds[1]] === true) {
            
            // Mark as matched to prevent duplicate triggers
            await snap.after.ref.update({ status: "matched" });

            const matchId = userIds.sort().join("_");
            const existingMatch = await db.collection("matches").doc(matchId).get();
            if (existingMatch.exists) {
                console.log(`[RUN_CLUB] Match ${matchId} already exists — skipping duplicate trigger`);
                return;
            }

            // Create match
            const batch = db.batch();
            batch.set(db.collection("matches").doc(matchId), {
```

---

## 4. Wave Entry Points
**Result:** MATCH

- **Live Proximity:** Waves can be sent via `WavePillService` (`MatchNotificationPill`) overlay shown during real-time BLE proximity events ([home_screen.dart](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/features/dashboard/presentation/home_screen.dart#L121)) and `ProfileDetailScreen` ([profile_detail_screen.dart](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/features/profile/presentation/profile_detail_screen.dart#L570)) when `showActions` is true.
- **Run Recap Window (10-min TTL):** Waves can be sent in the active `RunRecapScreen` ([run_recap_screen.dart](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/features/dashboard/presentation/run_recap_screen.dart#L585-L615)) via the inline wave button or tapping the profile (which opens `/profile` with actions enabled), but only while the encounter has not expired (`!isExpired`) and the user is Premium (`widget.isPremium`).
- **Blocked Paths (Static History):** 
  - Cards in [matches_screen.dart](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/features/matches/presentation/matches_screen.dart#L122) explicitly push `/profile?showActions=false`, which hides action buttons.
  - Locked matches in the history list ignore taps ([matches_screen.dart](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/features/matches/presentation/matches_screen.dart#L762)):
```dart
                          onTap: isNearMissLocked
                              ? () => PremiumPaywallBottomSheet.show(context)
                              : (isLocked || _isEditMode)
                                  ? null
                                  : () => _openProfile(profile),
```
  - [event_recap_screen.dart](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/features/map/presentation/event_recap_screen.dart) has no profile links or wave controls.
