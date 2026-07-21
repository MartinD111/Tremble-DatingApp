# FEATURE-RADAR-SONAR — Precise Turn-to-Find (in-window live finder) — Design

**Date:** 2026-07-22 · **Session:** 60 · **Risk:** HIGH (location-privacy posture change + new sensor stream + BLE handoff, device-only to validate)
**Branch (spec):** `feat/precise-finder-spec` · **Status:** design approved (founder, Session 60)
**Related:** [ADR-010](../../../tasks/decisions/ADR-010-precise-window-location.md), prior spec `2026-07-21-radar-sonar-turn-to-find-design.md`, [ADR-009](../../../tasks/decisions/ADR-009-compass-dependency.md) (compass), blocker `FEATURE-RADAR-SONAR`, memory `radar-sonar-search-feature`

---

## 1. Problem & confirmed root cause

Build-33's turn-to-find direction is driven by a server bearing computed between **geohash-7 cell centres** (`bearing.ts`, `proximity.functions.ts:151`). Geohash-7 is ~150m×75m (`geo_service.dart:56`). When two matched users are close — the exact moment they need to find each other — they fall in the same/adjacent cell, so the bearing collapses to ~0°/north and the radar arrow points at a fixed compass direction regardless of the real partner direction. The math (`sonar_math.dart:28`) is correct; the **input is too coarse** to be meaningful below ~75m.

Device pass (Session 60) confirmed: dots appeared, but rotating the phone did not lead to the partner. "Honest degrade" (hide the arrow up close) is defensible but abandons the core value — helping two people who already matched actually meet, especially in the final ~50m on tight European streets.

## 2. Key insight — consent context

Geohash-7 is the **global discovery** privacy floor: it protects everyone a user has NOT matched with. The trembling window is a different trust context — **both people have already mutually waved; they have consented to meet.** That is the justified, bounded moment to unlock precise location, exactly as rideshare pickup / Find My Friends / Snap Map do. This does not weaken privacy for strangers; it unlocks precision for two people who both said "yes, find me."

## 3. Decisions (founder, Session 60)

| # | Decision | Choice |
|---|---|---|
| Activation | How precise finding turns on | **Per-window one-tap, reciprocal.** A "Help us find each other" button; precise mode turns on only for users who tap; the sharp arrow only appears if BOTH tap (share yours to receive theirs). Resets every window. |
| What's shown | What each person sees of the other | **Arrow + distance only.** Raw coords go only to a Cloud Function; it returns bearing + distance. The partner never receives coordinates and never sees a map dot. |
| Tier | Free vs premium | **Free for everyone.** Completing a meet you already earned is the core promise; premium stays tied to reach/volume, not to finding. |
| Transport | How positions become an arrow | **Callable polling (v1).** Each phone POSTs its coord to a callable every ~3s; server stores it server-only, reads the partner's latest, returns bearing+distance. Realtime trigger is a future upgrade. |

## 4. Privacy guarantee (the story we defend)

- Raw coordinates live **only** in `matches/{matchId}/finder/{uid}` — Firestore rules **deny all client access**; only the Admin SDK (the callable) reads/writes them.
- Only **bearing (0–359°) + distance (m)** are ever returned to a phone, computed server-side. The partner receives neither coordinates nor a map dot — just an arrow and "38 m".
- Activated **only per window, only when BOTH opt in**, revocable at any time.
- Coordinates are **purged** at window end (explicit delete on `markMatchFound`) plus a **~2-min Firestore TTL** on `expireAt`, so a phone that stops polling self-cleans. No coordinate is logged, analysed, or persisted beyond that TTL.

## 5. Components

### Client (Flutter)
- **`PreciseFinderController`** (Riverpod): owns per-window opt-in state; runs a high-accuracy location stream (geolocator) only while the finding screen is foregrounded, precise mode is on, and the match is not yet found; pushes the coord to the callable every ~3s (with a distance-filter to skip redundant pushes when stationary); receives `{bearing, distanceM, partnerSharing}` and feeds the radar dot + a distance label.
- **UI**: a "Help us find each other" button on `RadarSearchOverlay`. States: *idle* (button shown), *waiting for partner* (I opted in, partner hasn't), *active* (arrow + meters), *fallback* (partner off / GPS poor).
- **Rendering**: reuse the existing radar dot. When a precise bearing is present → `dotAngle(bearing, heading)` (compass still rotates it as the phone turns) in a solid/high-confidence style + "NN m". Otherwise → fallback (§8).

### Server (Cloud Functions, europe-west1, App Check enforced in prod)
- **`updateFinderLocation`** callable — input `{matchId, lat, lng, accuracy, optIn}`:
  1. Auth + participant check (reuse `loadParticipantMatch`).
  2. If `optIn` and not already set, set `finderOptIn.{callerUid}=true` on the match doc.
  3. Write the caller's coord to `matches/{matchId}/finder/{callerUid}` with `updatedAt` + `expireAt = now + 2min`.
  4. Read the partner's latest `finder/{partnerUid}`.
  5. If **both opted in AND window active (status pending, not expired) AND partner coord fresh (`updatedAt` within staleness)** → compute `bearing(caller→partner)` (reuse `computeBearing`) + haversine `distanceM`; return `{partnerSharing:true, bearing, distanceM}`. Else `{partnerSharing:false}` (with a reason: `partner_not_opted` | `partner_stale` | `window_over`).
- **Purge**: `markMatchFound` additionally deletes the `finder` subcollection docs and clears `finderOptIn`. TTL handles abandoned windows.

## 6. Data model

- **`matches/{matchId}/finder/{uid}`** → `{lat:number, lng:number, accuracy:number, updatedAt:Timestamp, expireAt:Timestamp}` — **server-only**; Firestore TTL policy on `expireAt`.
- **`matches/{matchId}.finderOptIn: Map<uid,bool>`** — booleans only, **no location**; participant-readable so each side can render "waiting for {name}…". Written via callable, never by the client.
- Derived bearing/distance are **not stored** anywhere — returned in the callable response only.

## 7. Control flow

1. Mutual window opens (existing). Radar shows the coarse arrow/warmth + a "Help us find each other" button.
2. User taps → client calls `updateFinderLocation` with `optIn:true`, starts the location stream + 3s push loop.
3. Each push: server stores the coord, gates on both-opted + fresh → returns bearing+distance, or `partnerSharing:false`.
4. Client renders: both sharing → solid arrow + "NN m"; else → "Waiting for {name}…" and keep the coarse/warmth fallback.
5. **Handoff**: as distance shrinks, BLE warmth + haptics take the final ~30m (existing); at very close range, surface the photo / "what am I wearing" exchange for the last visual step.
6. **Stop**: "We found each other" (`markMatchFound`) OR expiry OR app backgrounded OR toggle off → stop the stream, callable purge (delete `finder` docs + `finderOptIn`), revoke.

## 8. Fallback (supersedes standalone "honest degrade")

If the partner has not opted in, GPS is unavailable, or accuracy is poor → **never show a precise arrow.** Show the coarse geohash bearing only at approach range (>75m) + hot/cold BLE warmth up close, with honest microcopy ("They're close — look around"). The build-33 "honest degrade" behaviour becomes the graceful fallback, not the main path. Concretely this is `bearingIsMeaningful(distanceBucket)` gating the coarse arrow, plus the precise arrow taking priority whenever `partnerSharing:true`.

## 9. Accuracy realism

Urban GPS is ~10–30m (multipath in street canyons) — the arrow is directional guidance, not a laser. Both people moving + light smoothing tightens it. Design assumes the precise arrow owns **60→15m**; the final meters are always warmth + haptics + eyes. Do not oversell a GPS "laser".

## 10. Testing

- **Server unit**: `computeBearing`/haversine correctness; both-opted gating; participant check rejects non-members; not-both-opted → `partnerSharing:false` with reason; stale partner coord → `partner_stale`; window over → `window_over`; `markMatchFound` purges `finder` + `finderOptIn`; `expireAt` is set to now+2min.
- **Client unit**: `PreciseFinderController` state machine (idle → waiting → active → fallback → stopped); stop on background / found / expiry / toggle off; render mapping (`partnerSharing:true` → solid arrow + meters; false → fallback).
- **Firestore rules test**: client read/write of `matches/{matchId}/finder/**` is denied; participant read of `finderOptIn` allowed; non-participant denied.
- **Device**: two phones, both opt in, walk 60→10m — arrow points true, distance counts down, warmth handoff; one declines → other stays in fallback (no precise arrow); background one app → its sharing stops and coord purges.

## 11. Scope, risk, rollout

- **Risk: HIGH** (location-privacy posture change). Requires ADR-010 + founder approval (granted Session 60), a Firestore **rules change** locking the `finder` path, a Firestore **TTL policy** on `finder.expireAt`, a new callable, a new client controller + UI.
- **Escalation**: touches Firestore Rules + Cloud Functions + location handling → HIGH-risk lane per MPC.
- **Rollout**: ships as its own **build 35**, separate from the build-34 (C/D/E) batch. Backend (callable + rules + TTL) deploys with `--project prod`; client ships in build 35 via `build_prod.sh`.
- **Out of scope (future)**: realtime-trigger transport (Approach 2), UWB precision finding for the last ~10m on capable devices, RSSI-gradient direction hint.
