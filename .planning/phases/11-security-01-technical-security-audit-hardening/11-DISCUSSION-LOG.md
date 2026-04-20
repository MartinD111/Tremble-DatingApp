# Phase 11: SECURITY-01 — Technical Security Audit & Hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-20
**Phase:** 11-security-01-technical-security-audit-hardening
**Areas discussed:** PII log masking strategy, proximity_events write validation depth, Safety module input validation

---

## PII Log Masking Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Partial mask: uid.substring(0,8) | Keeps enough entropy for cross-log correlation without exposing full UID. Standard Firebase practice. | ✓ |
| Full redaction: replace with [UID] | Strongest privacy. Logs become opaque — cannot correlate events across functions for a single user. | |
| Keep full UID in logs | Easy to debug. Not recommended for GDPR — UIDs are pseudonymous personal data. | |

**User's choice:** Partial mask — `uid.substring(0, 8)` + `...`
**Notes:** Applies to all 7 affected function files.

---

## Email Address in Logs

| Option | Description | Selected |
|--------|-------------|----------|
| Remove email entirely | Log only "[EMAIL] Welcome email sent" — no address in output. | ✓ |
| Mask: first 3 chars + domain | e.g. ale***@gmail.com — useful for delivery debugging, slightly less strict. | |
| Keep as-is | Not recommended — email address in Cloud Function logs is a GDPR risk. | |

**User's choice:** Remove entirely.
**Notes:** Affects email.functions.ts line 59 only.

---

## proximity_events Write Validation Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Field presence + type check | Require all 5 fields + rssi is int + timestamp is timestamp. Matches audit spec exactly. | ✓ |
| Presence-only | Require all 5 fields but no type checks. Simpler. | |
| Full range validation | Add rssi -120…0 dBm, ttl > 0 < 86400. Maximum strictness but complex maintenance. | |

**User's choice:** Field presence + type check.

---

## proximity_events from == auth.uid enforcement

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — enforce from == request.auth.uid | Prevents spoofed proximity events attributed to another user. | ✓ |
| No — keep auth-only check | Simpler rule, no spoofing protection. | |

**User's choice:** Enforce `from == request.auth.uid`.
**Notes:** One-line addition with meaningful spoofing protection.

---

## Safety Module Input Validation

| Option | Description | Selected |
|--------|-------------|----------|
| Migrate to Zod schemas | Consistent with auth, users, proximity, uploads. Full schema file + validateRequest(). | ✓ |
| Harden manual checks in-place | Add length checks without Zod. Inconsistent with codebase pattern. | |

**User's choice:** Migrate to Zod.
**Notes:** New file: safety.schema.ts in functions/src/modules/safety/

---

## Report Reasons Enum Whitelist

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — enum whitelist | Prevent arbitrary strings. Consistent with client-side structured reason codes. | ✓ |
| No — any string up to max length | More flexible but reduces data quality in moderation queue. | |

**User's choice:** Enum whitelist: `["harassment", "fake_profile", "underage", "inappropriate_content", "spam"]`

---

## Claude's Discretion

- Exact formatting and JSDoc style in safety.schema.ts — follow existing module conventions
- config.ts RESEND_API_KEY sourcing — confirmed correct via process.env, no change required

## Deferred Ideas

None.
