## ADR-010: Precise, consented, ephemeral location inside the trembling window

Date: 2026-07-22
Status: Accepted

Context:
The turn-to-find direction (build 33) derives bearing from geohash-7 cell centres
(~150m×75m). At the close range where two matched users actually try to find each
other, the cells coincide and the bearing collapses to ~0°/north — the arrow does
not point at the partner. Geohash-7 is the correct GLOBAL discovery privacy floor
(protects everyone a user has not matched with), but the trembling window is a
different trust context: both users have already mutually waved and consented to
meet. Hiding the arrow up close ("honest degrade") is safe but abandons the core
value of the app — helping two matched people meet.

Decision:
Inside an active mutual-wave window, and ONLY when BOTH participants explicitly
opt in per window, share precise location to compute an accurate turn-to-find
arrow — WITHOUT ever exposing raw coordinates to the other client.
- Each phone POSTs its coordinate to the `updateFinderLocation` callable (~3s).
- Raw coordinates are stored only in `matches/{matchId}/finder/{uid}`, which
  Firestore rules deny to all clients (Admin SDK only).
- The callable returns ONLY bearing (0–359°) + distance (m) to the caller. The
  partner never receives coordinates and never sees a map dot.
- Coordinates are purged on `markMatchFound` and by a ~2-min Firestore TTL on
  `finder.expireAt`; never logged, analysed, or persisted beyond the TTL.
- Free for all users. Falls back to the coarse geohash arrow (>75m) + BLE warmth
  when either side has not opted in or GPS is poor.

Alternatives Considered:
- Honest degrade only (hide the arrow up close): safe but abandons the finding
  value the feature exists for.
- Raise global geohash precision: weakens the discovery privacy floor for
  strangers — rejected.
- Share a map dot / full live map: exposes exact position visually — rejected in
  favour of arrow+distance-only minimal disclosure.
- Realtime Firestore-trigger transport: smoother but per-write fan-out cost and
  harder purge guarantees — deferred; callable polling chosen for v1.
- Client-side bearing compute: would require sending the partner's coordinates to
  the client — rejected, violates the arrow-only guarantee.

Consequences:
- (Pro) Accurate, live turn-to-find arrow + distance in the 60→15m band, without
  exposing coordinates to the other user.
- (Pro) Consent is contextual, reciprocal, per-window, and revocable — a strong,
  defensible privacy story for store review / ToS.
- (Pro) Reuses existing infra (matches doc, compass, BLE warmth handoff).
- (Con) New HIGH-risk surface: Firestore rules must lock `finder/**`, a TTL policy
  must exist on `finder.expireAt`, and purge-on-found must be reliable — a rules
  or purge regression could leak/retain coordinates.
- (Con) High-accuracy GPS at ~3s while foregrounded costs battery during a window.
- (Con) Urban GPS (~10–30m) means the arrow guides, not lasers; final meters still
  need BLE warmth + visual confirmation.
