# Step 3 Audit — Trembling Window & Pulse Intercept

**Date:** 2026-06-06  
**Auditor:** Antigravity (Claude Code CLI)  
**Strategy claims domain:** Trembling Window (C-TREMBL-01 through C-TREMBL-05, C-PRIVACY-05)  
**Verdict format:** MATCH / MISMATCH / CANNOT VERIFY

---

## Summary

| Claim | Status | Notes |
|-------|--------|-------|
| C-TREMBL-01 — 30-minute window | ✅ MATCH | CF + client consistent |
| C-TREMBL-02 — Mutual wave → active radar | ✅ MATCH | Wired correctly |
| C-TREMBL-03 — Send Phone button | ⚠️ PARTIAL — CF EXISTS, UI NOT WIRED | CF implemented; no Flutter client call site |
| C-TREMBL-04 — Send Photo button | ⚠️ PARTIAL — CF EXISTS, UI NOT WIRED | CF implemented; no Flutter client call site |
| No free-text input in Trembling Window | ✅ MATCH — NO CRITICAL | Zero text inputs in match flow |
| C-TREMBL-05 / C-PRIVACY-05 — View-once + 10-min Redis TTL | ✅ MATCH | `INTERCEPT_TTL_SECS = 600`, delete on viewedAt |
| Free vs Premium parity (Pulse Intercept) | ✅ MATCH — no premium gate | No `isPremium` check in intercept CF or UI |

---

## Claim-by-claim findings

---

### C-TREMBL-01 — 30-minute window

**Claim:** "30-minutno okno (Trembling Window) ob mutual wave"

**Status: ✅ MATCH**

**Backend (authoritative):**
```typescript
// functions/src/modules/matches/matches.functions.ts:257
expiresAt: new Date(Date.now() + 30 * 60 * 1000),
```
Written atomically inside the `onWaveCreated` transaction when a mutual match is created.

**Client (UI timer):**
```dart
// lib/src/features/dashboard/presentation/home_screen.dart:1215–1217
expiresAt: activeMatch.createdAt
    .add(const Duration(minutes: 30)),
```
`RadarSearchOverlay` timer ticks down from `session.expiresAt - now` with 1-second `Timer.periodic`. Turns red with pulse animation at `< 5 min` remaining.

**Dev-sim fallback:**
```dart
// home_screen.dart:813, 847
expiresAt: now.add(const Duration(minutes: 30)),
```
All three construction sites use `Duration(minutes: 30)` — consistent.

**Verdict:** Backend writes `expiresAt = now + 30 min`, client computes countdown from `createdAt + 30 min`. The two are equivalent. MATCH.

---

### C-TREMBL-02 — Mutual wave opens active radar

**Claim:** "Mutual wave sproži match in odpre active radar"

**Status: ✅ MATCH**

```dart
// lib/src/features/dashboard/presentation/home_screen.dart:355
ref.listen(activeMatchesStreamProvider, (previous, next) {
  ...
  context.pushNamed('match_reveal', extra: unseenMatch);
```

Flow:
1. `onWaveCreated` CF creates `matches/{id}` document with `status: pending`.
2. Client `activeMatchesStreamProvider` picks up new match.
3. `home_screen.dart:335` listener triggers `pushNamed('match_reveal')`.
4. `MatchRevealScreen` animates the reveal, then "Tap anywhere to start radar" navigates to the active `RadarSearchOverlay`.

Correct — radar only opens after a confirmed mutual match document exists in Firestore.

---

### C-TREMBL-03 + C-TREMBL-04 — Pulse Intercept: Send Phone + Send Photo

**Claim:** "Pulse Intercept med Trembling Window: Send Phone button" + "Send Photo button"

**Status: ⚠️ PARTIAL — CF IMPLEMENTED, FLUTTER CLIENT NOT WIRED**

**Backend (fully implemented):**
```typescript
// functions/src/modules/matches/intercept.functions.ts:57–59
if (type !== "phone" && type !== "photo") {
    throw new HttpsError("invalid-argument", "Invalid intercept type.");
}
```
`requestPulseIntercept` accepts exactly `type: "phone" | "photo"`. Phone reads `users/{uid}.phoneNumber` server-side. Photo payload is whatever the caller passes (a Cloudflare R2 pre-signed URL). Both stored in Redis under `intercept:{targetUid}:{senderUid}` with 10-min TTL.

Exported in `functions/src/index.ts:35–37`:
```typescript
requestPulseIntercept,
getPulseIntercept,
```

**Flutter client — gap found:**
```
grep -r "requestPulseIntercept\|getPulseIntercept\|pulseIntercept" lib/
→ No results found
```

- No `ApiClient.call('requestPulseIntercept', ...)` anywhere in `lib/`.
- No `ApiClient.call('getPulseIntercept', ...)` anywhere in `lib/`.
- `match_reveal_screen.dart` (601 lines, fully read) — **no Pulse Intercept buttons**. It is a reveal animation only ("Tap anywhere to start radar").
- `radar_search_overlay.dart` (248 lines, fully read) — contains only: countdown timer, warmth indicator, Stop button. **No Pulse Intercept buttons.**
- `match_dialog.dart` (502 lines, fully read) — contains only a Wave button and Dismiss. **No Pulse Intercept buttons.**

**Conclusion:** The Pulse Intercept Cloud Functions exist and are correct. The Flutter UI does **not yet surface the "Send Phone" / "Send Photo" buttons** inside the Trembling Window. This is a **feature gap, not a regression** — the backend is ahead of the client.

**Impact:** Free and Premium users currently cannot trigger a Pulse Intercept from the app. The strategy claim is unverifiable in the UI layer because the buttons do not exist yet.

---

### No free-text input in Trembling Window

**Claim (product absolute):** "No free text input anywhere in Trembling Window / Pulse Intercept flow"

**Status: ✅ MATCH — NO CRITICAL FOUND**

Full scan of all `TextField` / `TextFormField` / `TextEditingController` across all features:

Text inputs found **only** in:
- `auth/presentation/login_screen.dart` — email + password (login)
- `auth/presentation/forgot_password_screen.dart` — email (password reset)
- `auth/presentation/registration_flow.dart` — registration fields
- `auth/presentation/widgets/registration_steps/hobbies_step.dart` — hobby name + emoji
- `profile/presentation/edit_profile_screen.dart` — profile editing fields
- `gym/presentation/gym_search_widget.dart` — gym search
- `safety/presentation/safe_zones_screen.dart` — safe zone name + address
- `safety/presentation/widgets/ugc_action_sheet.dart` — report explanation

**Zero text inputs** in:
- `match_reveal_screen.dart` ✅
- `radar_search_overlay.dart` ✅
- `match_dialog.dart` ✅
- `matches_screen.dart` (scanned via grep — no hits in matches feature)
- `home_screen.dart` (active radar section — no hits)

**No CRITICAL raised.**

---

### C-TREMBL-05 / C-PRIVACY-05 — View-once + 10-min Redis TTL

**Claim:** "Pulse Intercept photo: view-once, 10 min TTL / Snap-style delete on viewedAt"

**Status: ✅ MATCH**

```typescript
// functions/src/modules/matches/intercept.functions.ts:20
const INTERCEPT_TTL_SECS = 600; // 10 minutes
```

```typescript
// intercept.functions.ts:86–91
await redis.set(redisKey, JSON.stringify({
    type,
    senderUid,
    data: payloadData,
    timestamp: Date.now(),
}), { ex: INTERCEPT_TTL_SECS });
```
All intercepts (phone AND photo) stored in Redis with 10-min TTL. Auto-expires even if never retrieved.

**View-once (snap-style delete on read):**
```typescript
// intercept.functions.ts:167–169
if (intercept.type === "photo") {
    await redis.del(redisKey);
}
```
On `getPulseIntercept`, if type is `photo`, the Redis key is **deleted immediately** after the first successful read. Phone is **not** deleted on read (recipient may want to copy the number — this is correct behavior).

**Storage:** Redis only — no Firestore write, no SQL. Consistent with `C-PRIVACY-05`: "No data stored in persistent databases (Firestore/SQL)." MATCH.

**Phone number at rest:** Stored in `users/{uid}.phoneNumber` in Firestore (set during onboarding/profile). Privacy claim C-PRIVACY-07 ("encrypted") was not audited here — deferred to Step 8.

---

### Free vs Premium parity — Pulse Intercept

**Claim:** "Pulse Intercept behaves identically for Free and Premium"

**Status: ✅ MATCH (CF layer) / NOT APPLICABLE (UI not yet built)**

```
grep -r "isPremium" functions/src/modules/matches/intercept.functions.ts
→ No results found
```

`requestPulseIntercept` contains no `isPremium` check. Any authenticated, non-banned user with an active `matches/{id}` document may call it. No tier gating.

`getPulseIntercept` similarly has no premium check.

Since the client-side buttons are not yet wired, the client-side premium gate cannot exist either. When the UI is built, no premium gate should be introduced.

---

## Open Issues (not CRITICAL — feature gaps)

### ISSUE-1: Pulse Intercept UI not implemented

**Risk:** LOW (missing feature, not a regression or violation)  
**Description:** `requestPulseIntercept` and `getPulseIntercept` Cloud Functions are deployed and correct. The Flutter UI has no Send Phone / Send Photo buttons in any Trembling Window screen.  
**Affected screens:**
- `match_reveal_screen.dart` — no Pulse Intercept buttons
- `radar_search_overlay.dart` — no Pulse Intercept buttons  

**Next step:** Build the Pulse Intercept UI inside `RadarSearchOverlay` (two action buttons: Phone + Photo). The CF contract is fixed: `type: "phone" | "photo"`, response is `{ expiresAt }`. No new CF work required.

### ISSUE-2: Active radar — two moving points / compass

**Claim C-TREMBL-02 note:** Strategy also mentions "Active radar: two moving points, compass rotates view, dot leaves trail"  
**Status:** `radar_search_overlay.dart` renders a warmth indicator (getting closer / moving away) derived from `WarmthDirection`, not a compass-based two-dot view. The full active radar canvas is rendered by `radar_animation.dart` (behind the overlay) — not audited here. Deferred to a separate radar animation audit if needed.

---

## Files audited

| File | Lines | Finding |
|------|-------|---------|
| `functions/src/modules/matches/matches.functions.ts` | 477 | 30-min `expiresAt` at line 257 ✅ |
| `functions/src/modules/matches/intercept.functions.ts` | 191 | TTL=600, view-once delete, no premium gate ✅ |
| `lib/src/features/match/presentation/match_reveal_screen.dart` | 601 | No Pulse Intercept buttons, no text input ✅ |
| `lib/src/features/dashboard/presentation/widgets/radar_search_overlay.dart` | 248 | No Pulse Intercept buttons, no text input ✅ |
| `lib/src/features/matches/presentation/match_dialog.dart` | 502 | No text input ✅ |
| `lib/src/features/dashboard/presentation/home_screen.dart` | 3286 | 30-min client timer consistent ✅ |
| All `lib/src/features/**` | Full grep | No TextField in match/dashboard flow ✅ |

---

*Audit completed 2026-06-06. No edits made. Step 4 (History/Recaps) is next.*
