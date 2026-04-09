# Session Report — 2026-04-09 (Session 3)

**Date:** 2026-04-09
**Branch:** main
**Commits this session:** ea8e742, 99b300f, 70dfc9b
**Session type:** Security Audit + UI Audit

---

## Summary

This session had two major tracks: (1) a comprehensive security audit that identified and fixed credential exposure issues, and (2) a full UI/UX audit of every Flutter screen in the app. No new features were built. The session established a clear baseline for Phase 2A (UI refinement).

RevenueCat (Phase 8) remains deliberately parked — requires both founders present.

---

## Track 1 — Security Audit & Remediation

### Actions taken

| Action | Commit | Risk |
|--------|--------|------|
| Split `functions/.env` into `functions/.env.dev` + `functions/.env.prod` | 70dfc9b | CRIT-01 fix |
| Deleted old mixed `functions/.env` | 70dfc9b | CRIT-01 fix |
| Added explicit gitignore entries for both new env files | 70dfc9b | CRIT-01 prevention |
| Implemented `scripts/ci/secret_scan.sh` with gitleaks + pattern scan + filename check | 70dfc9b | HIGH-02 fix |
| Gitignored `lib/firebase_options.dart` and `lib/firebase_options_dev.dart` permanently | 99b300f | CRIT-02 prevention |

### Actions taken by founder (outside codebase)

| Action | Service |
|--------|---------|
| Rotated Resend API key (dev) | Resend Dashboard |
| Rotated Resend API key (prod) | Resend Dashboard |
| Rotated Cloudflare R2 access key + secret (dev) | Cloudflare Dashboard |
| Rotated Cloudflare R2 access key + secret (prod) | Cloudflare Dashboard |
| Created separate iOS Maps API key | Google Cloud Console |
| Created separate Android Maps API key | Google Cloud Console |

### Security findings not yet fully resolved

| Finding | Status | Mitigation path |
|---------|--------|-----------------|
| Prod Firebase API keys in git history (commit 0044b4f) | Open | Resolve SEC-001 (App Check enforcement) — primary mitigation |
| Maps API key revocation confirmation | Open | Verify in Google Cloud Console that old keys are revoked |
| `mpc-ci.yml` missing Firebase options injection | Open | Fix before mpc-ci builds are relied on |

### Key lesson: Google OAuth Client ID

`GOOGLE_WEB_CLIENT_ID` is NOT a secret. It is a public OAuth identifier embedded in compiled app binaries. It cannot be rotated without breaking all existing Google Sign-In sessions. Belongs in `.env` for environment separation but should be treated as config, not a credential. Documented as Rule #7.

---

## Track 2 — UI/UX Audit (Comprehensive)

### Audit scope

All Flutter screens and shared components were audited:
- Auth: login, onboarding, registration flow (27 pages), forgot password, permission gate
- Main app: home/radar, matches, profile detail, profile card, edit profile
- Secondary: map, settings, blocked users, match dialog, match reveal
- Shared: GlassCard, PrimaryButton, LiquidNavBar, TrembleLogo, GradientScaffold, paywall

### Overall assessment

**Grade: B-** — Solidna baza z vidno design debt.

The theme system is correctly implemented. Brand fonts are wired. Colors are defined. The architecture is sound. However, the implementation is inconsistent — the same patterns are executed differently across screens, and several Material defaults bleed through in the most visible places.

### Critical findings (P0 — blocks TestFlight)

| ID | Issue | Location |
|----|-------|----------|
| D-19 | `Colors.pinkAccent` (#FF4081) used instead of `TrembleTheme.rose` (#F4436C) throughout RadarAnimation (sweep, sonar, scanning line) and 5 other locations | radar_animation.dart, matches_screen.dart, profile_detail_screen.dart, blocked_users_screen.dart |
| D-20 | DEV TEST flame button (amber, empty onPressed) renders when `isScanning == true` | home_screen.dart lines 333–345 |
| D-21 | Google logo in login loaded from `upload.wikimedia.org` via `Image.network` — fails with no internet, no fallback | login_screen.dart |
| D-22 | Map screen has 3 hardcoded markers with fabricated user counts displayed as real data | pulse_map_screen.dart |
| D-23 | Profile detail screen shows hardcoded `"Ljubljana, 2km"` as real user location | profile_detail_screen.dart |

### Strong points

| Item | Quality |
|------|---------|
| TrembleLogo animation | Polished — 3 sequential arc pulses, correct brand colors |
| MatchRevealScreen | Best-executed screen — correct brand tokens, intentional typography |
| PermissionGateScreen | Good — clear copy, correct flutter_animate entrance animations |
| Theme system (`TrembleTheme`) | Correctly defined — all 4 fonts, all brand colors, both light/dark themes |
| GradientScaffold + LiquidNavBar | Architecture correct |
| RadarAnimation pulsing button | Functional, correct feel — wrong color only |

### Systemic issues

1. **`Colors.pinkAccent` anti-pattern** — 6+ locations use the wrong brand color on the most prominent widgets. Add Rule #9 to lessons.md.
2. **40+ hardcoded Slovenian strings** bypass the translation system — entire screens' copy is untranslatable.
3. **Fake data displayed as real** — map markers and location badge show fabricated data to users.
4. **`registration_flow.dart` monolith** — 27 pages, ~38K tokens in a single StatefulWidget. Highest architectural debt.
5. **Debug artifacts** — DEV TEST button should never have survived to this stage.

### Phase 2A plan (next session)

Fast P0 fixes before any external TestFlight build:

```
1. Remove DEV TEST flame button from home_screen.dart
2. Replace Colors.pinkAccent → TrembleTheme.rose in:
   - radar_animation.dart (sweep gradient, sonar dot, scanning line)
   - matches_screen.dart (edit toggle)
   - profile_detail_screen.dart (slider activeColor)
   - blocked_users_screen.dart (CircularProgressIndicator)
3. Bundle Google logo SVG as asset, replace Image.network
4. Remove fake map markers (or label clearly as demo)
5. Remove hardcoded "Ljubljana, 2km" location
```

---

## Track 3 — SVG Logo Geometry Fix

Fixed geometric error in both SVG logo assets where the `wave_inner` (innermost right stroke) had all Y coordinates shifted +4 units too low, breaking vertical symmetry.

**Root cause:** When SVG paths were derived from `logo.html`, the X offset (+2) was applied consistently but the Y coordinates for `wave_inner` were additionally shifted +4 without justification.

**Fix:** Corrected all 7 Y coordinates in `wave_inner` path:
- Before: `M 12, 25 C 16, 15 26, 18 26, 24 C 26, 30 16, 35 12, 40`
- After: `M 12, 21 C 16, 11 26, 14 26, 20 C 26, 26 16, 31 12, 36`

Applied to: `Logo/tremble_icon_clean.svg` + `Logo/tremble ikona animacija 5 z 3d efektom.svg`
Commit: ea8e742

---

## MPC Files Updated

| File | Update |
|------|--------|
| `tasks/context.md` | Full session handoff + security findings + UI audit P0 list |
| `tasks/lessons.md` | Rules #7–#10 added |
| `tasks/debt.md` | D-19 through D-30 added (12 new items, 3 resolved) |

---

## Commits

| Hash | Message |
|------|---------|
| ea8e742 | fix: correct inner wave Y offset in SVG logo assets |
| 99b300f | security: gitignore orphan lib/firebase_options files |
| 70dfc9b | security: update gitignore and add secret scan script |

---

## Next Session

**Priority 1:** Phase 2A — P0 bugfixes (estimated 2–3h)
**Priority 2:** Phase 2B — Registration & onboarding visual polish
**Blocked:** Phase 8 RevenueCat (needs Martin), SEC-001 App Check (needs developer accounts)

*Report generated: 2026-04-09*
