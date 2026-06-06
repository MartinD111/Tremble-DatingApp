# Strategy Compliance Audit — Step 5 Filters

Date: 2026-06-06
Domain: Filters / Hard Filters / exclusion rules
Scope: Read-only audit. No code changes.

## Summary

- Item 1 Free filtering: MATCH
- Item 2 Hard Filters Premium gating: MISMATCH
- Item 3 Server-side enforcement in `findNearby`: MATCH, with event-path caveat
- Item 4 Directional receiver-protection logic: MISMATCH

No client-side hard-filtering privacy violation was found in the `findNearby` path. The filtering in `findNearby` is server-side and returns only `userId` plus `distanceM`, not full nearby user data. However, the scheduled server proximity-event path does not apply the hard filter before writing/sending proximity events, and the helper used by `findNearby` is symmetric rather than receiver-directional.

## 1. Free Filtering — Gender + Age

Status: MATCH

Evidence:
- Gender preference is available in onboarding without a Premium gate: `lib/src/features/auth/presentation/widgets/registration_steps/what_to_meet_step.dart:24-31`, `:61-69`, `:77-80`.
- Age range is available in onboarding without a Premium gate: `lib/src/features/auth/presentation/widgets/registration_steps/dating_preferences_step.dart:87-99`.
- Age range remains editable in Settings without a Premium lock: `lib/src/features/settings/presentation/settings_screen.dart:1044-1063`.
- Gender preference remains editable in Settings without a Premium lock: `lib/src/features/settings/presentation/settings_screen.dart:1164-1180`.
- Settings controller updates age range without checking Premium: `lib/src/features/settings/presentation/settings_controller.dart:89-93`.
- Settings controller updates `interestedIn` without checking Premium: `lib/src/features/settings/presentation/settings_controller.dart:147-149`.
- `findNearby` applies gender + age filtering server-side: requester fields at `functions/src/modules/proximity/proximity.functions.ts:274-278`, candidate fields at `:336-340`, match checks at `:350-359`, score gate at `:364-365`.

Caveat:
- The onboarding age-range selection is currently not persisted from `_ageRangePref`; the UI passes changes at `lib/src/features/auth/presentation/registration_flow.dart:958-964`, but final onboarding constructs `AuthUser` with hardcoded `ageRangeStart: 18` and `ageRangeEnd: 45` at `:1834-1835`. Free users can still edit age range later in Settings.

## 2. Hard Filters Premium Gating

Status: MISMATCH

Evidence:
- Onboarding exposes the nicotine exclusion preference without a Premium gate when the user selects no nicotine use: `lib/src/features/auth/presentation/widgets/registration_steps/nicotine_step.dart:140-160`.
- Registration wires that partner preference into `_partnerNicotineFilter` without a Premium check: `lib/src/features/auth/presentation/registration_flow.dart:814-827`.
- Settings exposes the nicotine hard-filter row without passing `isPremium: !user.isPremium`: `lib/src/features/settings/presentation/settings_screen.dart:1444-1460`.
- The settings controller only blocks Premium rows when `isPremium` is passed and the user is not Premium: `lib/src/features/settings/presentation/settings_controller.dart:183-194`. The nicotine row does not pass that guard.
- `findNearby` reads and applies `requesterData.nicotineFilter` regardless of `requesterData.isPremium`: `functions/src/modules/proximity/proximity.functions.ts:283-288`, `:342-346`.

Additional persistence concern:
- `completeOnboardingSchema` accepts legacy `isSmoker` / `partnerSmokingPreference`, but not `nicotineUse` / `nicotineFilter`: `functions/src/modules/auth/auth.schema.ts:18-69`.
- `updateProfileSchema` is strict and also does not allow `nicotineUse` / `nicotineFilter`: `functions/src/modules/users/users.schema.ts:17-78`.
- The Flutter API payload sends `nicotineUse` and `nicotineFilter`: `lib/src/features/auth/data/auth_repository.dart:226-240`. This means the hard-filter fields used by `findNearby` may fail to persist through production Cloud Functions even though the UI exposes them.

## 3. Server-Side Enforcement In `findNearby`

Status: MATCH, with event-path caveat

Evidence:
- `findNearby` accepts only caller coordinates plus optional ignored radius: `functions/src/modules/proximity/proximity.functions.ts:60-66`.
- It queries active proximity documents server-side: `functions/src/modules/proximity/proximity.functions.ts:296-302`.
- Candidate user profiles are fetched server-side before filtering: `functions/src/modules/proximity/proximity.functions.ts:325-328`.
- Hard-filter logic is applied before adding a user to the response: `functions/src/modules/proximity/proximity.functions.ts:342-347`.
- The response only includes `userId` and rounded `distanceM`: `functions/src/modules/proximity/proximity.functions.ts:413-427`.
- A codebase search found no Flutter `httpsCallable('findNearby')` call and no client-side nearby-user hard-filter path; Flutter references to `findNearby` are comments in `lib/src/core/ble_service.dart:101`, `:157`, and `:179`.

Privacy absolute check:
- No evidence found that full nearby users are transferred to the device and then hard-filtered client-side.
- Therefore the Item 3 client-side-filtering CRITICAL condition was not triggered.

Event-path caveat:
- The scheduled proximity event generator `scanProximityPairs` is also server-side, but it does not apply the nicotine hard filter before writing `proximity_events` or sending CROSSING_PATHS notifications. It fetches profiles and checks only flagged/block status at `functions/src/modules/proximity/proximity.functions.ts:687-712`, then writes the event at `:714-722` and notifies both users at `:808-812`.

## 4. Directional Receiver Protection

Status: MISMATCH

Evidence:
- The helper is bilateral/symmetric, not receiver-directional: `functions/src/modules/proximity/proximity.functions.ts:171-177`.
- Specifically, it rejects both when the requester's filter excludes the candidate and when the candidate's filter excludes the requester: `functions/src/modules/proximity/proximity.functions.ts:175-176`.
- `findNearby` applies that symmetric helper using both users' filters: `functions/src/modules/proximity/proximity.functions.ts:342-346`.

Why this mismatches the strategy:
- The strategy says the receiver's exclusion set protects the receiver: if A excludes smokers, a smoker cannot generate a proximity event at A.
- `findNearby` is not purely directional because it also applies the candidate's exclusion set to the requester.
- More importantly, the actual proximity-event generator `scanProximityPairs` does not apply the hard filter at all before writing/sending events: `functions/src/modules/proximity/proximity.functions.ts:687-722`, `:808-812`.

Result:
- A smoker can still generate a server-created proximity event / CROSSING_PATHS notification at A through `scanProximityPairs` if A excludes smokers.
- In `findNearby`, the filter is server-side but symmetric, not receiver-only.
