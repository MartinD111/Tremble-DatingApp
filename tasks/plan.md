# Active Implementation Plan
Plan ID: 20260714-legal-002-cannabis-close
Risk Level: LOW
Founder Approval Required: NO
Branch: docs/legal-002-cannabis-close-20260714

## 0. AUDIT RESULT — BLOCKER-LEGAL-002 cannabis removal

Founder flagged 2026-07-14 that cannabis has been fully removed from
the product. Session 2026-07-14 verified across every surface where
cannabis could persist. Docs-only close; zero runtime edit.

### Cannabis is unreachable — 4-surface evidence

| Surface | Evidence | Verified |
|---|---|---|
| Registration UI | `lib/src/features/auth/presentation/widgets/registration_steps/nicotine_step.dart:15-19` — only 5 options: `cigarettes`, `vape`, `iqos`, `zyn`, `shisha`. No cannabis chip. | ✅ |
| Server API (Zod) | `functions/src/modules/users/users.schema.ts:17-23` — `nicotineUseValueSchema = z.enum(["cigarettes", "vape", "iqos", "zyn", "shisha"])`. Requests carrying `"cannabis"` are rejected with 400 at the API boundary. | ✅ |
| Edit-profile display | `lib/src/features/profile/presentation/edit_profile_screen.dart:124` — `..addAll(user.nicotineUse.where((v) => v != 'cannabis'))` defensively filters any residual legacy Firestore entries out of the render. | ✅ |
| Legacy Firestore data | `functions/src/scripts/remove_cannabis.ts` migration ran against **prod (`am---dating-app`)** — founder confirmed 2026-07-14. `FieldValue.arrayRemove("cannabis")` is idempotent; subsequent writes cannot re-introduce it. | ✅ |

### Why stronger than the original ask

BLOCKER-LEGAL-002's original action was "separate cannabis into its
own field pending legal review." The founder chose to *remove*
cannabis entirely instead. No collection → no consent needed → no
Art. 10 GDPR "criminal offense data" exposure — resolved without
waiting on a per-jurisdiction legal opinion.

PLAN_00 §Deluje already recorded "Kanabis + politična pripadnost:
odstranjena iz kode (grep = 0 zadetkov v main)" but the corresponding
blocker was never marked RESOLVED. This PR closes that documentation
gap so future sessions and audits see the full evidence chain.

## 1. OBJECTIVE
Close BLOCKER-LEGAL-002 with concrete evidence so future sessions
don't inherit stale "OPEN" state (Rule #83 verify-intel discipline).

## 2. SCOPE
- `tasks/blockers.md` — BLOCKER-LEGAL-002 → RESOLVED with the
  4-surface evidence chain.
- `tasks/plan.md` — this file; Plan-ID + §0 audit evidence + §3
  index refresh (LEGAL-002 removed from deferred list).

**Not touched:** any code under `lib/`, `functions/`, `test/`,
`ios/`, `android/`, `.github/`. Zero runtime code, zero test change.
Cannabis was already removed from all four surfaces long before this
session began; this PR only records the closure.

## 3. NEXT LANES — durable index of deferred work

After both PR #37 (LEGAL-005) and this PR merge, remaining ship-side
blockers indexed here for future sessions:

### Ship-critical blockers

- **BLOCKER-STORE-003** — Play Console submission for background
  location. Copy review DONE (KORAK 3.9-4, PR #36). Still owed: EN +
  SL screenshots on a real device, demo video, Play Console
  declaration form. Task `6h3p8gWG7WHWV7JP`.
- **BLOCKER-STORE-004** — Android Foreground Services declaration on
  Play Console (types: location, connectedDevice, dataSync). Task
  `6h3p8gc78572RF9P`.

### Legal blockers (unfab + counsel)

- **BLOCKER-LEGAL-001** — DPIA false claims (`getPublicProfile` leak
  claim + TTLs mismatch). Task `6h3jFhxVHpRmph9P`.
- **BLOCKER-LEGAL-003** — `gender` + `lookingFor` = implicit Art. 9
  sexual-orientation category; explicit consent gate missing (Grindr
  precedent: NOK 65M fine). Task `6h3j9q65vh3mG64P`.
- **BLOCKER-LEGAL-004** — ToS §7 promises automatic weekend window
  (Fri 19h – Sun 19h), code enforces user-triggered activation
  (Rule: single write path via `activateWeekendPass`). Sync ToS to
  code or code to ToS. Task `6h332RFRW946QWXw`.

### Test-hardening lane

- **ADR-007 §4 pair-of-tests per gate.** MEDIUM risk (billing-adjacent
  test surface). Founder approval required to start. Not gating any
  blocker closure — separate quality investment.

## 4. RISKS & TRADEOFFS
- Zero runtime change; zero submission risk.
- Docs-only closure — the code state that resolves LEGAL-002 has been
  in `main` for weeks; this PR only aligns the tracking documents
  with that reality.

## 5. VERIFICATION
- `git diff --stat` on branch → 2 files under `tasks/**`.
- `flutter analyze` → 0 issues (pre-commit hook re-verifies).
- `flutter test` → 263-baseline preserved.
- unit tests — n/a (docs-only, no runtime code).
- integration tests — n/a (docs-only).
- security scan — branch diff limited to `tasks/**`. Zero secrets,
  zero PII, zero auth/billing/security-boundary change.
- MPC PR pre-flight (Rules #79 + #80):
  - Title: `[PLAN-ID: 20260714-legal-002-cannabis-close] docs(blockers+plan): close BLOCKER-LEGAL-002 — cannabis removed from all 4 surfaces`.
  - Body contains `## Verification checklist` naming `unit tests`,
    `integration tests`, `security scan`.
  - Body contains zero Rule #80 naive-regex trigger substrings.
  - Plan-ID present in this file (line 2).
