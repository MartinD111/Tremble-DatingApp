# Retrospective: Tremble

Living document — one section per milestone. Updated at each milestone completion.

---

## Milestone: v1.1 — Core Product

**Shipped:** 2026-04-09
**Archived:** 2026-04-18
**Phases:** 2 (Phase 6: Brand Alignment, Phase 7: Wave Mechanic + Push Notifications)
**Plans:** 4 (3 in Phase 6 via GSD + 1 reconstructed for Phase 7)

### What Was Built

- Brand identity fully applied: Tremble Rose (#F4436C) throughout, JetBrains Mono on all radar telemetry, all four font families wired
- Brand-voice onboarding copy in 8 languages — short, direct, confident; replaced generic placeholder copy
- Google Maps API key injected via CI (`scripts/ci/setup_maps_key.sh`) — remediated pre-existing security gap (Debug.xcconfig was tracked in git with real key)
- Wave mechanic: one-tap `sendWave()`, server-side mutual detection via `onWaveCreated` Cloud Function, 30-minute match session constraint in `match_service.dart`
- Match reveal screen with glassmorphic brand animation + `ProximityPingController` EMA-smoothed RSSI → vibration
- Full push notification stack: CROSSING_PATHS (anonymous proximity), INCOMING_WAVE (no sender identity), MUTUAL_WAVE (deep link to /radar), `WAVE_BACK_ACTION` without opening app

### What Worked

- **Plan-first execution on Phase 6** — three GSD plan files with clear scope meant each plan executed in ~12 minutes with zero deviations
- **Privacy-by-design decisions made at code time** — removing `{name}` from `wave_sent` toast and sending `INCOMING_WAVE` without sender identity were architectural choices enforced in the implementation, not retrofitted
- **Rule #3 (no chat)** formalized early — MSG-01–04 removed cleanly, PUSH-03 closed as N/A, no zombie requirements lingering
- **Retrospective SUMMARY** for Phase 7 was reconstructable from code alone — good naming conventions and commit messages made reconstruction viable

### What Was Inefficient

- **Phase 7 executed outside GSD framework** — no PLAN files created, SUMMARY reconstructed 2026-04-18 from code inspection. Lost planning discipline for the most complex phase. Future: even for "fast" implementations, create a plan file before executing.
- **VERIFICATION.md skipped for both phases** — tracking gap that triggered partial audit status. REQUIREMENTS.md and ROADMAP.md were authoritative but Nyquist compliance requires VERIFICATION.md files.
- **STATE.md went stale immediately** — sat at "Phase 6: Planning" state from 2026-04-08 through archival on 2026-04-18. Not updated after any phase completion.
- **REQUIREMENTS.md traceability table started stale** — WAVE-01–06 misassigned to Phase 6, MSG-01–04 not removed, all checkboxes at Pending despite completion. Required manual cleanup before archival.
- **Pre-existing security gap discovered mid-execution** — `ios/Flutter/Debug.xcconfig` was tracked in git with real Maps API key. Should have been caught in v1.0 security review.

### Patterns Established

- `TrembleTheme.telemetryTextStyle(context)` — canonical pattern for all JetBrains Mono telemetry/radar readout text
- `scripts/ci/setup_maps_key.sh` — CI secret injection pattern for platform-specific key files
- GSD plan files scoped to ~12 minute execution windows — correct granularity for this codebase
- Server-side mutual detection (no client-side confirmation) — correct architecture for unidirectional wave mechanic

### Key Lessons

1. **Always create a GSD PLAN file, even for fast execution.** Phase 7 took ~1 day and had no plan file. The implementation was correct but the planning artifacts were lost.
2. **Update STATE.md at phase completion, not at session end.** It went stale within the same session it was created.
3. **VERIFICATION.md is not optional overhead** — it's the artifact that closes the loop from plan → execute → verify. Missing it means reconstructing evidence at audit time.
4. **Security gaps surface during execution** — build a security checkpoint into every phase that touches platform files (xcconfig, local.properties, AndroidManifest).
5. **REQUIREMENTS.md traceability degrades fast under pressure** — checkbox discipline needs to be enforced at plan completion, not at milestone closure.

### Cost Observations

- Sessions: estimated 3–4 focused sessions for v1.1
- Phase 6 plans averaged ~12 min each — optimal granularity
- Phase 7 was executed in a single day without GSD tracking — faster but produced planning debt
- Audit reconstruction took roughly as long as writing a proper VERIFICATION.md would have

---

## Cross-Milestone Trends

| Trend | v1.0 | v1.1 |
|-------|------|------|
| Planning discipline | Retrospectively inferred | Partial (Phase 6 good, Phase 7 skipped) |
| VERIFICATION.md coverage | None | None |
| STATE.md currency | Stale | Stale |
| Security gap discovery | — | 1 (xcconfig in git) |
| Plan execution time | — | ~12 min/plan (Phase 6) |
| Tech debt items | ~3 | 6 |

**Emerging pattern:** GSD framework adherence degrades under time pressure. Phase 7 (most complex phase) had the least process. Need to make plan creation fast enough that it doesn't feel like overhead.
