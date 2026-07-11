# Active Implementation Plan
Plan ID: 20260711-fix-stop-billing-cloudevent
Risk Level: HIGH
Founder Approval Required: YES
Branch: feat/stop-billing-cf

1. OBJECTIVE — Port the manually-deployed `stop-billing-10eur` Pub/Sub Cloud Function into the repo and fix the CloudEvent parsing bug that crashes every budget alert with `TypeError: Buffer.from(undefined)` before any cost/budget comparison — so the €10 billing kill-switch actually fires in prod on `am---dating-app`.

2. SCOPE — `functions/src/scripts/stop-billing/index.ts` (new handler), `functions/src/__tests__/stop-billing.test.ts` (new tests), `functions/src/index.ts` (export wiring), `functions/package.json` + `package-lock.json` (adds `@google-cloud/billing`). Does NOT touch: Flutter app code, Firestore Rules, other Cloud Functions, CI pipelines, native manifests, secrets, or the existing deployed CF (that lives in GCP Console and requires founder-action to replace).

3. STEPS —
   (a) Switched handler shape from gen1 raw `event.data` (crashing) to firebase-functions v2 `onMessagePublished` (`topic: budget-limit-reached`, `region: europe-west1`) so the base64 payload is read from `cloudEvent.data.message.data` correctly.
   (b) Extracted three pure helpers (`decodeBudgetMessage`, `resolveThreshold`, `handleBudgetNotification`) so the billing-decision logic is unit-testable without the CloudEvent envelope.
   (c) Added `STOP_BILLING_THRESHOLD_EUR` env override with fallback to notification `budgetAmount`, so the founder can raise the cutoff during multi-device testing without redeploying.
   (d) Guarded every failure mode as no-op with structured logs: missing payload, unparseable base64/JSON, missing `costAmount`, non-numeric env value, already-disabled billing. No path can throw before the cost/threshold compare.
   (e) Cost/threshold compare runs BEFORE any billing API call. `getProjectBillingInfo` only fires when over threshold; `updateProjectBillingInfo` with `billingAccountName: ""` only fires when billing is currently enabled.
   (f) Wired `stopBilling` export into `functions/src/index.ts` so it deploys via `firebase deploy --only functions:stopBilling` rather than manual GCP Console upload.

4. RISKS & TRADEOFFS —
   - HIGH-risk surface: this function, when triggered, clears the billing account on the entire `am---dating-app` project, which halts every Cloud Function mid-request. Mitigated by (i) env-var threshold override, (ii) `costAmount > threshold` strict compare (equal is no-op), (iii) explicit `billingEnabled` check before mutation.
   - Two subscribers on `budget-limit-reached` after deploy: the old crashing `stop-billing-10eur` CF and the new `stopBilling`. Founder must delete the old CF in GCP Console after verifying the new one, otherwise the crash logs will continue.
   - `@google-cloud/billing@^5.1.2` added as a new prod dependency (auth via ADC, no new secrets required).
   - Test dependency on jest inline mocks for `firebase-functions/v2/pubsub`, `firebase-functions/v2`, and `@google-cloud/billing` — consistent with the pattern already used by gdpr.test.ts and matches.test.ts in this repo.

5. VERIFICATION —
   - `npm run build` in `functions/`: clean (tsc, no diagnostics).
   - `npm test` in `functions/`: 10 suites / 95 tests pass — 18 new for stop-billing (sub-threshold, at-threshold-equal, over-threshold with billingEnabled, over-threshold with billing already disabled, env override up, env override down, missing payload, unparseable payload, missing costAmount, plus `decodeBudgetMessage` and `resolveThreshold` unit coverage) + 77 existing regressions clean.
   - `npx eslint --ext .ts` on new files: clean.
   - Pre-commit hook (Flutter analyze + full Flutter test suite): passed — no regressions in the mobile app from adding this CF export.
   - Post-deploy founder verification (NOT yet run): trigger a test alert, confirm logs show `stopBilling: budget alert received` with `cost=X threshold=Y` and NO `TypeError`; delete the old `stop-billing-10eur` CF via GCP Console; decide whether to keep the €10 default or set `STOP_BILLING_THRESHOLD_EUR` higher during active multi-device testing.
