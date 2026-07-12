# Active Implementation Plan
Plan ID: 20260712-fix-gym-manual-activation
Risk Level: LOW
Founder Approval Required: NO
Branch: feat/gym-manual-activation-no-gate

1. OBJECTIVE — Remove the server-side haversine geofence gate that currently rejects manual Gym Mode activation when the caller's location is farther than `gyms/{gymId}.radiusMeters` from the gym centre. Manual activation is an explicit context declaration by the user — physical presence is verified elsewhere (client-side geofence dwell service on the automatic path). The current gate contradicts the intent of a "manual" activation and makes offline check-in impossible when GPS is drifting or the user just left the geofence for a moment.

2. SCOPE —
   - **Modified:**
     - `functions/src/modules/gym/gym.functions.ts` — remove the `haversine(...)` distance gate inside `onGymModeActivate`, plus the now-unused `haversine` helper. Keep the `latitude`/`longitude` payload contract (client still sends them; server still requires them for shape validity) so downstream first-proximity writes on the client stay unaffected. Update the docstring so it no longer promises server-side proximity validation.
     - `functions/src/__tests__/gym.test.ts` — new test file. Covers: (a) manual activation succeeds from far away (previously failed-precondition), (b) manual activation still succeeds when inside geofence, (c) still rejects unknown gymId, (d) still rejects missing lat/lng, (e) still rejects unauthenticated caller.
     - `tasks/plans/PLAN_03_APP_CODE.md` — Output block for KORAK 3.3 + status footer.
     - `tasks/plan.md` (this file).
   - **Does NOT change:**
     - The geofence dwell service (automatic activation path) — unchanged.
     - `onGymModeDeactivate`, `expireGymSessions`, `onRunModeActivate`, `onRunModeDeactivate`, `expireRunModes` — untouched.
     - Firestore schema, Firestore Rules, client-side gym UI, native manifests.
     - CI workflow files.

3. STEPS —
   (a) Delete lines 15–25 (haversine helper) and lines 65–73 (the distance gate) in `gym.functions.ts`. Rewrite the `onGymModeActivate` docstring to describe manual activation as an explicit context declaration.
   (b) Write `functions/src/__tests__/gym.test.ts` with 5 tests exercising the callable (Ljubljana caller / Koper gym stays green; inside geofence stays green; missing gym → not-found; missing lat/lng → invalid-argument; missing auth → unauthenticated).
   (c) `cd functions && npm run build && npm run lint && npm test` — all three must pass. Confirm `haversine` no longer appears anywhere in `functions/src/modules/gym/**`.
   (d) Update `tasks/plans/PLAN_03_APP_CODE.md` KORAK 3.3 Output block with PR / merge / evidence details after merge.
   (e) Commit, push, open PR with the four MPC phrases and the diff-removed grep as evidence.

4. RISKS & TRADEOFFS —
   - Trade-off: a bad actor can flag Gym Mode from any location. Acceptable — Gym Mode's product value is contextual filtering during a workout, not physical-presence attestation. The automatic dwell path still requires real proximity for its own trigger. If future abuse metrics show gym-mode fraud, we add a rate limit tier or a challenge (e.g. BLE beacon requirement), not a distance gate.
   - Client contract preserved: the client still sends lat/lng. The server still validates their presence to catch schema drift early, but does not use them for a geofence decision. This means client rollout is not required — no client bump needed.
   - Compliance report Del IV (2026-07) called this gate out as contradicting the manual/automatic split; removing it aligns implementation with the documented product intent.

5. VERIFICATION —
   - **Verification checklist:**
     - [ ] **unit tests** — `gym.test.ts` covers the 5 scenarios above; all must be green.
     - [ ] **integration tests** — n/a. This callable has no external integrations beyond Firestore reads/writes already covered by the unit tests.
     - [ ] **security scan** — n/a. No new deps, no new secrets, no permission or rule changes. Removing a check is a behavioural change, not a security-surface change (Gym Mode is not a permission gate).
     - [ ] `cd functions && npm run build` — 0 errors.
     - [ ] `cd functions && npm run lint` — 0 warnings.
     - [ ] `cd functions && npm test` — all suites green (expected 12 suites / 105 tests, i.e. previous 100 + 5 new gym tests).
     - [ ] Evidence in PR body: unified diff of the removed gate block, `grep -n "haversine" functions/src/modules/gym/**` output showing 0 hits post-edit, and the Jest run summary.
