# Phase 11: SECURITY-01 — Technical Security Audit & Hardening - Context

**Gathered:** 2026-04-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Harden the Tremble backend and Flutter client to production security standards:
- Mask PII (UIDs, email) in Cloud Function console.log statements
- Add field-presence + type-checked write validation to the `proximity_events` Firestore rule
- Migrate the Safety module (blockUser, unblockUser, reportUser) from manual typeof checks to Zod schemas with an enum whitelist for report reasons

What does NOT change:
- enforceAppCheck is already present on all 21 onCall functions — no changes needed
- Zod .passthrough() not present anywhere — no changes needed
- rateLimits / idempotencyKeys already deny-all — no changes needed
- Global deny rule already present — no changes needed
- .env.example contains only placeholders — no changes needed
- redis.ts uses process.env only — no changes needed
- main.dart App Check providers already correct (debug for dev, PlayIntegrity/DeviceCheck for prod) — no changes needed

</domain>

<decisions>
## Implementation Decisions

### PII Log Masking — Cloud Functions

- **D-01:** Mask UIDs using `uid.substring(0, 8)` followed by `...` — e.g. `[AUTH] User enriched: abc12345...`
  Applies to all `console.log` statements across: auth.functions.ts, uploads.functions.ts, safety.functions.ts, gdpr.functions.ts, proximity.functions.ts, users.functions.ts
- **D-02:** Email addresses must be removed entirely from logs — log `[EMAIL] Welcome email sent` with no address.
  Applies to: email.functions.ts line 59: `console.log(\`[EMAIL] Welcome email sent to ${toEmail}\`)`

### proximity_events Firestore Write Rule

- **D-03:** Validate field presence AND types. Required fields: `from`, `toDeviceId`, `rssi`, `timestamp`, `ttl`.
  Type checks: `rssi` is int (`request.resource.data.rssi is int`), `timestamp` is timestamp type.
- **D-04:** Enforce that `request.resource.data.from == request.auth.uid` — prevents one user writing a proximity event attributed to another user's device.
- **D-05:** Final rule shape:
  ```
  match /proximity_events/{eventId} {
    allow write: if request.auth != null
      && request.resource.data.from == request.auth.uid
      && request.resource.data.keys().hasAll(['from', 'toDeviceId', 'rssi', 'timestamp', 'ttl'])
      && request.resource.data.rssi is int
      && request.resource.data.timestamp is timestamp;
    allow read: if false;
  }
  ```

### Safety Module — Zod Schema Migration

- **D-06:** Create `functions/src/modules/safety/safety.schema.ts` with Zod schemas:
  - `blockUserSchema`: `z.object({ targetUid: z.string().min(1).max(128) })`
  - `unblockUserSchema`: same as blockUserSchema
  - `reportUserSchema`: `z.object({ reportedUid: z.string().min(1).max(128), reasons: z.array(z.enum([...REPORT_REASONS])).min(1).max(10), explanation: z.string().max(500).optional() })`
- **D-07:** Report reasons enum whitelist: `["harassment", "fake_profile", "underage", "inappropriate_content", "spam"]`
- **D-08:** Replace manual `typeof` checks with `validateRequest(schema, request.data)` calls in all three functions, matching the pattern already used in auth, users, proximity, uploads modules.
- **D-09:** Remove now-redundant manual `if (!targetUid || typeof targetUid !== "string")` checks after Zod migration.

### Claude's Discretion
- Exact import ordering / formatting in new safety.schema.ts — follow existing module conventions
- Whether to add JSDoc to new schema file — consistent with other schema files' style
- config.ts RESEND_API_KEY sourcing — already confirmed to use process.env via config object; no change required

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Cloud Functions — schemas and middleware patterns
- `functions/src/modules/auth/auth.schema.ts` — Reference Zod schema pattern (field constraints, string max, number int ranges)
- `functions/src/modules/users/users.schema.ts` — Another reference schema
- `functions/src/middleware/validate.ts` — validateRequest() implementation — use this, don't roll a new one
- `functions/src/middleware/authGuard.ts` — requireAuth() pattern

### Cloud Functions — modules to patch
- `functions/src/modules/auth/auth.functions.ts` — PII log: lines 42, 58, 135
- `functions/src/modules/uploads/uploads.functions.ts` — PII log: line 78
- `functions/src/modules/safety/safety.functions.ts` — PII logs + manual validation to replace with Zod
- `functions/src/modules/gdpr/gdpr.functions.ts` — PII logs: lines 88, 185, 295, 325
- `functions/src/modules/proximity/proximity.functions.ts` — PII logs: lines 163, 230
- `functions/src/modules/users/users.functions.ts` — PII log: line 47
- `functions/src/modules/email/email.functions.ts` — Email PII log: line 59

### Firestore Rules
- `firestore.rules` — Full file. The proximity_events rule (lines ~47-51) is the only rule to change.

### Flutter Client
- `lib/main.dart` — App Check configuration (lines 24, 39-44) — already correct, verify only, do not change

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `validateRequest(schema, request.data)` in `functions/src/middleware/validate.ts` — already used in auth, uploads, users, proximity; Safety module should adopt it exactly
- Zod import pattern: `import { z } from "zod"` — consistent across all existing schema files
- Schema file naming convention: `{module}.schema.ts` in the module directory

### Established Patterns
- All existing schemas use `.min(1).max(N)` on strings, never bare `z.string()`
- `requireAuth(request)` returns uid — this is the uid that must be used for logging, not re-extracted from request.data
- Firestore rules file uses `match /{document=**}` global deny as the final rule — do not move it

### Integration Points
- safety.functions.ts imports `requireAuth` from `../../middleware/authGuard` and `checkRateLimit` from `../../middleware/rateLimit` — new schema import follows same relative path pattern: `import { validateRequest } from "../../middleware/validate"`

</code_context>

<specifics>
## Specific Ideas

- UID masking: `uid.substring(0, 8)` — not `uid.slice(0, 5)`, not `uid.slice(0, 12)`. 8 characters.
- Email: completely removed from log messages, not masked.
- proximity_events Firestore rule: use `request.resource.data.keys().hasAll([...])` syntax (v1 Firestore rules compatible).
- Report reasons enum exactly: `["harassment", "fake_profile", "underage", "inappropriate_content", "spam"]`

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 11-security-01-technical-security-audit-hardening*
*Context gathered: 2026-04-20*
