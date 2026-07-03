# ADR-002: UGC Safety & Privacy Architecture

Date: 2026-03-10  
Status: Implemented  
Implemented In: `lib/src/features/safety/`, `functions/src/modules/safety/`, `functions/src/modules/gdpr/`  
Risk Level: MEDIUM  
Requires Founder Approval: YES

---

## Context

To comply with Apple App Store (Guideline 1.2) and Google Play (UGC Policy), Tremble must provide explicit mechanisms for users to protect themselves from objectionable content and abusive behavior. Furthermore, GDPR requires strict data minimization and limited retention periods.

The previous "Hide" toggle was insufficient as it was easily reversible and lacked a reporting mechanism for moderation.

---

## Decision

Implement a comprehensive tiered safety and privacy system:

### 1. User Safety (UGC)
- **Block:** A permanent, server-side exclusion. Multi-step:
    - Add Target UID to Caller's `blockedUserIds` array.
    - Delete any existing matches between the two.
    - Server-side filtering in `getMatches` and `findNearby` to ensure zero visibility.
- **Report:** A formal moderation flag.
    - Captures reason, optional explanation, and timestamps.
    - **Auto-Block:** Reporting a user automatically triggers the Block logic to protect the reporter immediately.

### 2. Data Retention (TTL)
To minimize the footprint of sensitive data, implement automated Time-To-Live (TTL) policies in Firestore:
- **`proximity_events` (BLE):** 10-minute TTL. Highly transient, used only for immediate mutual detection.
- **`proximity` (GPS Geohash):** 2-hour TTL. Ensures radar data doesn't persist after user inactivity.
- **`gdprRequests` (Audit Logs):** 2-year TTL. Retained for legal audit compliance, then auto-deleted.

### 3. Right to Erasure (GDPR Art. 17)
- Account deletion must be absolute.
- **Cloudflare R2:** Photos must be deleted via API (`deleteR2UserFiles`) before the Auth record is purged.

---

## Architecture

- **Backend:** Cloud Functions (`blockUser`, `reportUser`, `deleteUserAccount`) as the exclusive writers for safety state.
- **Frontend:** `UgcActionSheet` as the unified entry point for report/block actions across Profile and History screens.
- **Database:** Standardized `ttl` field (Timestamp) across collections for Cloud Console policy compatibility.

---

## Consequences

- Increased server-side compute for filtering matches (mitigated by array-based exclusion for small/medium lists).
- Users can only reverse a block through a dedicated "Blocked Users" settings screen (prevents accidental unblocking).
- Improved legal standing for App Store and Google Play submissions.
