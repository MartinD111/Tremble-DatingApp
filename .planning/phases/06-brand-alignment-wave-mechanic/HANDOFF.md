# Phase 6 Planning Handoff

**Written:** 2026-04-08 — context limit approached at ~78%
**For:** Next Claude instance continuing `/gsd:plan-phase 6`
**Status:** Research complete, PLAN.md not yet written

---

## What Was Accomplished This Session

1. **GSD project initialized** — PROJECT.md, REQUIREMENTS.md, ROADMAP.md, STATE.md all written and committed (825723c)
2. **Roadmap updated** — Phase 6 split into two:
   - Phase 6: Brand Alignment (BRAND-01–05) ← planning in progress
   - Phase 7: Wave Mechanic (WAVE-01–06)
   - Phases 8–11 renumbered accordingly
3. **Phase 6 dir created:** `.planning/phases/06-brand-alignment-wave-mechanic/`
4. **Research completed manually** (researcher agent hit rate limit)

---

## Research Findings — Phase 6: Brand Alignment

### 🟢 BRAND-01 (Color tokens): ALREADY DONE
`lib/src/core/theme.dart` already has full brand palette:
- `rose = Color(0xFFF4436C)` — primary
- `roseLight = Color(0xFFF9839E)`
- `roseDark = Color(0xFFC02048)`
- `accentYellow = Color(0xFFF5C842)`
- `successGreen = Color(0xFF2D9B6F)`
- `warmGray = Color(0xFF6B6B63)`
- `border = Color(0xFFE2E2DC)`
- **No teal exists in theme.dart**

One file flagged by grep: `registration_flow.dart` — needs manual inspection for `Color(0xFF00...` pattern. Run:
```bash
grep -n "Color(0xFF" lib/src/features/auth/presentation/registration_flow.dart
```

### 🟢 BRAND-02 (Font system): ALREADY DONE
`theme.dart` already has all 4 fonts wired via `google_fonts` package:
- `GoogleFonts.playfairDisplay()` — display/headlines
- `GoogleFonts.lora()` — body text
- `GoogleFonts.instrumentSans()` — UI/buttons/labels
- `GoogleFonts.jetBrainsMono()` — telemetry
- Helper methods: `TrembleTheme.displayFont()`, `bodyFont()`, `uiFont()`, `telemetryTextStyle()`
- Full TextTheme + component-level overrides (buttons, dialogs, chips, appbar, etc.)

**ACTION NEEDED:** Verify individual screen files are using `Theme.of(context).textTheme.*` and `TrembleTheme.*Font()` helpers rather than hardcoded `TextStyle(fontFamily: ...)`.

### 🔴 BRAND-03 (Onboarding copy): NOT DONE
`lib/src/core/translations.dart` has onboarding/registration strings that need brand voice rewrite.
- File is >10k tokens — read in chunks: offset 0–200, 200–400, etc.
- Key areas to check: onboarding page titles/subtitles, CTA button labels, registration flow copy
- Brand voice rule: short, direct, confident. No filler. "Start Discovering" not "Begin your journey"

### 🔴 BRAND-04 (Registration CTA copy): NOT DONE
- In `translations.dart` — find `registration_cta` or similar keys
- Also check `registration_flow.dart` for hardcoded strings

### 🔴 BRAND-05 (Maps API key): NOT DONE
Current state (from session 2026-04-08):
- `android/local.properties` → `MAPS_API_KEY=YOUR_MAPS_API_KEY_HERE` (placeholder)
- `ios/Flutter/Debug.xcconfig` → `MAPS_API_KEY=YOUR_MAPS_API_KEY_HERE` (placeholder)
- Injection mechanism is wired correctly — just needs the real key value
- **ACTION:** Aleksandar must fill in the real key manually — it's a secret, not code

---

## Files to Read Before Planning

Critical reads for the planner:
1. `lib/src/core/theme.dart` — already read, fully brand-aligned
2. `lib/src/core/translations.dart` — read in chunks (>10k tokens), focus on onboarding/registration keys
3. `lib/src/features/auth/presentation/registration_flow.dart` — check for hardcoded colors/strings
4. `lib/src/features/auth/presentation/onboarding_screen.dart` — check copy + any hardcoded styles
5. `lib/src/features/dashboard/presentation/home_screen.dart` — verify using theme colors
6. `lib/src/features/dashboard/presentation/radar_animation.dart` — verify rose/graphite only
7. `.planning/REQUIREMENTS.md` — BRAND-01 through BRAND-05
8. `.planning/ROADMAP.md` — Phase 6 success criteria

---

## What To Do Next

### Step 1: Complete Research
Read translations.dart (chunks) and all screen files listed above to confirm:
- Which files have hardcoded colors that bypass the theme
- Which copy keys need rewriting
- Whether google_fonts is in pubspec.yaml (likely yes, already used in theme.dart)

### Step 2: Write RESEARCH.md
Save findings to: `.planning/phases/06-brand-alignment-wave-mechanic/RESEARCH.md`

### Step 3: Write CONTEXT.md (discuss-phase output)
Save phase context to: `.planning/phases/06-brand-alignment-wave-mechanic/CONTEXT.md`
Content: phase goal, scope, requirements, constraints, key decisions, success criteria.

### Step 4: Spawn gsd-planner
Use `gsd-planner` subagent type with full context to create `PLAN.md` at:
`.planning/phases/06-brand-alignment-wave-mechanic/PLAN.md`

### Step 5: Verify with gsd-plan-checker
Use `gsd-plan-checker` subagent type to verify the plan covers all success criteria.

### Step 6: Commit
```bash
node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" commit "docs: phase 6 plan — brand alignment" --files .planning/phases/06-brand-alignment-wave-mechanic/
```

---

## Key Decisions Made This Session

| Decision | Rationale |
|----------|-----------|
| Split Phase 6 into Brand (6) + Wave (7) | User preference — focused phases, wave mechanic needs separate audit |
| Audit existing wave code before planning Phase 7 | User preference — avoid re-implementing what's already there |
| BRAND-01 and BRAND-02 are already done at theme level | Discovered during research — focus Phase 6 plan on copy + individual screen audit |

---

## GSD State

```
Current phase: 6 — Brand Alignment
Phase dir: .planning/phases/06-brand-alignment-wave-mechanic/
Artifacts present: HANDOFF.md (this file)
Artifacts missing: RESEARCH.md, CONTEXT.md, PLAN.md
Next command: /gsd:plan-phase 6 --skip-research (research done manually)
OR: continue manually — read translations.dart, write CONTEXT.md, spawn gsd-planner
```

---

## Context for Wave Mechanic (Phase 7 — not yet planned)

Files to audit when planning Phase 7:
- `lib/src/features/matches/data/match_repository.dart`
- `lib/src/features/matches/presentation/match_dialog.dart`
- `lib/src/features/matches/presentation/matches_screen.dart`
- `lib/src/features/dashboard/presentation/home_screen.dart` (wave button location)

Wave mechanic requirements: WAVE-01 through WAVE-06
- One-tap wave send from dashboard
- Mutual wave = match in Firestore
- Unidirectional hidden (no one-sided visibility)
- Profile unlock after match
- Brand match reveal animation
- No duplicate waves, no race conditions
