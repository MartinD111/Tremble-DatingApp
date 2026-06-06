# Step 10 — Brand & Copy Compliance Audit

**Date:** 2026-06-06  
**Scope:** In-app strings (`translations.dart`), widget Dart files, theme/token definitions  
**NOT audited:** Marketing website (explicitly excluded)  
**Status:** READ-ONLY — no edits made

---

## 1. Forbidden Words

**Claim IDs:** C-BRAND-01 through C-BRAND-08 (forbidden copy section)  
**Words checked:** revolutionary, seamless, game-changing, "find love today", revolucionarno, brezhibno, spreminjajoče

### Verdict: MATCH (user-facing strings)

No forbidden word appears in any translation key value in `translations.dart` or as a UI string literal in any Dart widget file.

**One edge case — "seamless" in code comments (NOT user-facing):**

| File | Line | Context |
|------|------|---------|
| `lib/src/features/match/presentation/widgets/match_reveal_overlay.dart` | 70 | `Color(0xFFF4436C), // back to rose — seamless` — inline color comment |
| `lib/src/shared/widgets/running_stickman.dart` | 71 | `// exact pose on start, so the run begins seamlessly.` — code comment |
| `lib/src/shared/widgets/running_stickman.dart` | 118 | `// frame 0 (a full-stride pose), so starting the loop continues seamlessly.` — code comment |

**Judgment:** These are developer comments on animation logic, not UI copy. Not a brand violation. No action required.

**Slovenian false-positive — "Spremeniti" in translations.dart:**

| File | Line | Full sentence |
|------|------|---------------|
| `lib/src/core/translations.dart` | 1421 | `'Prepričaj se, da je datum rojstva pravilen. Spremeniti ga je mogoče samo enkrat.'` |
| `lib/src/core/translations.dart` | 1424 | `'Je {date} tvoj datum rojstva? Spremeniti ga je mogoče samo enkrat.'` |

**Judgment:** "Spremeniti" = "to change" in Slovenian (the birthday-edit warning). This is not the forbidden word "spreminjajoče" (game-changing). NOT a violation.

---

## 2. Emoji in Headlines

**Claim:** No emoji in headlines.

### Verdict: MATCH

No headline or title translation key (`*_title`, `*_headline`, `*_header`) contains emoji.

**Emoji found — non-headline keys only:**

| Key | Value (excerpt) | Category |
|-----|-----------------|----------|
| `label` (language picker) | `'🇩🇪 Deutsch'`, `'🇸🇮 Slovenščina'`, etc. | UI picker labels — intentional flag use |
| `pride_mode` | `'Pride Mode 🏳️‍🌈'` | Settings toggle label — not a headline |
| `event_share_text` | `'At {name} tonight. Find me on Tremble. 📍 {location}'` | OS share sheet text — not rendered as in-app headline |
| `notify_incoming_wave_run_body` | `'…sending you a Wave! Look back 👀'` | Push notification body — not in-app UI |
| `gym_mode_nav_hint` | `'People tab (👥) is set to My Gym…'` | Hint/tooltip body text — not a headline |
| `gym_activated_body` | `'People who are also at this gym…(👥)…'` | Activation toast body — not a headline |
| `sim_instruction` | `'Hold the 👋 button to send a greeting.'` | Dev simulator instruction — not shown in prod |

**Judgment:** All emoji appearances are in non-headline contexts. The flag emoji in language-picker labels is a standard UI pattern. No action required.

---

## 3. Hardcoded Hex Colors

**Claim:** Brand colors must come from `TrembleTheme` tokens, not inline hex. Forbidden inline: `#F4436C`, `#F5C842`, `#2D9B6F`, `#1A1A18`, `#FAFAF7`.

### Verdict: MISMATCH — systemic, widespread

Brand token hex values are hardcoded inline across **20+ widget files** instead of using `TrembleTheme.rose`, `TrembleTheme.signalYellow`, `TrembleTheme.confirmGreen`, `TrembleTheme.deepGraphite`, `TrembleTheme.warmCream`.

#### Brand token violations (hex that has a named `TrembleTheme` constant)

**`0xFFF4436C` — should be `TrembleTheme.rose`:**

| File | Lines |
|------|-------|
| `lib/src/core/router.dart` | 165 |
| `lib/src/features/settings/presentation/settings_screen.dart` | 998 |
| `lib/src/features/settings/presentation/premium_screen.dart` | 68–69, 89–90, 226, 464, 487, 521, 567 |
| `lib/src/features/auth/presentation/registration_flow.dart` | 1960, 1962 |
| `lib/src/features/auth/presentation/login_screen.dart` | 501, 506, 530 |
| `lib/src/features/auth/presentation/widgets/registration_steps/gym_step.dart` | 33, 208 |
| `lib/src/features/auth/presentation/widgets/registration_steps/name_step.dart` | 102 |
| `lib/src/features/match/presentation/widgets/match_background_animation.dart` | 48 |
| `lib/src/features/match/presentation/widgets/match_reveal_overlay.dart` | 65, 70, 247 |
| `lib/src/features/match/presentation/widgets/match_notification_pill.dart` | 369 |
| `lib/src/features/matches/presentation/match_dialog.dart` | 115, 127, 160, 164 |
| `lib/src/features/matches/presentation/matches_screen.dart` | 162, 481, 876, 894, 1047, 1264, 1275, 1291, 1307, 1319 |
| `lib/src/features/safety/presentation/account_suspended_screen.dart` | 28 |
| `lib/src/features/safety/presentation/blocked_users_screen.dart` | 129 |
| `lib/src/features/safety/presentation/widgets/ugc_action_sheet.dart` | 11 |
| `lib/src/features/dashboard/presentation/home_screen.dart` | 156, 194, 275, 304, 1542 |
| `lib/src/features/dashboard/presentation/widgets/radar_search_overlay.dart` | 171 |
| `lib/src/features/map/presentation/event_recap_screen.dart` | 228 |
| `lib/src/features/map/presentation/tremble_map_screen.dart` | 117, 118 |
| `lib/src/features/profile/presentation/profile_card_preview.dart` | 189, 192, 198 |
| `lib/src/features/profile/presentation/profile_detail_screen.dart` | 310 |
| `lib/src/features/profile/presentation/edit_profile_screen.dart` | 625 |
| `lib/src/shared/ui/premium_paywall.dart` | 23, 30, 41 |
| `lib/src/shared/widgets/radar_painter.dart` | 22 |

**`0xFF1A1A18` — should be `TrembleTheme.deepGraphite` (or via `Theme.of(context).scaffoldBackgroundColor`):**

| File | Lines |
|------|-------|
| `lib/src/core/router.dart` | 162 |
| `lib/src/features/settings/presentation/settings_screen.dart` | 592, 599, 814 |
| `lib/src/features/settings/presentation/premium_screen.dart` | 67, 88, 110, 129, 148, 477, 551, 764 |
| `lib/src/features/settings/presentation/widgets/phone_edit_modal.dart` | 396 |
| `lib/src/features/settings/presentation/widgets/preference_range_slider.dart` | 56 |
| `lib/src/features/settings/presentation/widgets/preference_pill_row.dart` | 46 |
| `lib/src/features/auth/presentation/registration_flow.dart` | 627 |
| `lib/src/features/auth/presentation/login_screen.dart` | 315, 460 |
| `lib/src/features/auth/presentation/widgets/registration_steps/phone_step.dart` | 128 |
| `lib/src/features/match/presentation/match_reveal_screen.dart` | 150 (as `_bgDeep`) |
| `lib/src/features/matches/presentation/match_dialog.dart` | 112, 221, 259 |
| `lib/src/features/matches/presentation/matches_screen.dart` | 222, 1112 |
| `lib/src/features/safety/presentation/account_suspended_screen.dart` | 15 |
| `lib/src/features/safety/screen_protection_service.dart` | 24, 67 |
| `lib/src/features/safety/presentation/safe_zones_screen.dart` | 395 |
| `lib/src/features/safety/presentation/anonymous_mode_screen.dart` | 51 |
| `lib/src/features/safety/presentation/widgets/ugc_action_sheet.dart` | 10 |
| `lib/src/features/dashboard/presentation/run_recap_screen.dart` | 141 |
| `lib/src/features/dashboard/presentation/home_screen.dart` | 1017, 1031 |
| `lib/src/features/gym/presentation/my_gyms_screen.dart` | 55 |
| `lib/src/shared/ui/gradient_scaffold.dart` | 74 |
| `lib/src/shared/ui/tremble_outage_screen.dart` | 176 |
| `lib/src/shared/ui/skeleton.dart` | 58 |

**`0xFFF5C842` — should be `TrembleTheme.signalYellow`:**

| File | Lines |
|------|-------|
| `lib/src/features/settings/presentation/premium_screen.dart` | 89–90, 1001 |
| `lib/src/features/matches/presentation/matches_screen.dart` | 482, 1046, 1266, 1277, 1292, 1308, 1320 |
| `lib/src/features/dashboard/presentation/home_screen.dart` | 1538 |
| `lib/src/features/dashboard/presentation/widgets/radar_search_overlay.dart` | 215 |
| `lib/src/features/map/presentation/event_pin_sheet.dart` | 483 |

**`0xFF2D9B6F` — should be `TrembleTheme.confirmGreen`:**

| File | Lines |
|------|-------|
| `lib/src/features/auth/presentation/permission_gate_screen.dart` | 339 |
| `lib/src/features/match/presentation/match_reveal_screen.dart` | 153 (as `_greenDark`) |

**`0xFFFAFAF7` — should be `TrembleTheme.warmCream` / `TrembleTheme.backgroundColor`:**

| File | Lines |
|------|-------|
| `lib/src/features/settings/presentation/premium_screen.dart` | 149, 150, 181, 187, 212 |
| `lib/src/features/match/presentation/match_reveal_screen.dart` | 155 (as `_cream`) |
| `lib/src/features/matches/presentation/matches_screen.dart` | 384 |
| `lib/src/features/safety/screen_protection_service.dart` | 74 |

#### Non-brand inline hex (contextual — not in `TrembleTheme`)

The following hex values are NOT in `TrembleTheme` and represent either theme card variants or off-palette colors. These are a separate concern from the brand token violations:

- `0xFF2A2A2E`, `0xFF1E1E2E`, `0xFF1A1A2E` — dark surface/card variants defined in theme but not exported as named constants
- `0xFF00C8FF`, `0xFFFFB347` — accent colors for premium tier cards (premium_screen only)
- `0xFF0EA5E9` — sky blue on permission_gate_screen:223
- `0xFF4A9EFF` — male accent on matches_screen:161, premium_screen:225
- `0xFFFF4C4C` — error red on birthday_step:72
- `0xFF6B0025`, `0xFF2B000F`, `0xFF0C0008` — deep rose animation gradients in match_reveal_overlay (purely decorative)

These are lower priority but contribute to color management drift.

---

## 4. Font Overrides

**Claim:** Playfair Display, Lora, Instrument Sans wired via `TrembleTheme`; not overridden ad hoc.

### Verdict: MATCH

Grep for `fontFamily` in all widget Dart files (excluding `theme.dart` and `theme_provider.dart`) returned **zero results**.

All font families are applied exclusively through `TrembleTheme` → `ThemeData` → `TextTheme`. No ad-hoc `fontFamily` string in any widget.

---

## 5. Glassmorphism

**Claim:** No glassmorphism package. No blur on content cards. `useGlassEffect` defaults to false.

### 5a. Package check — MATCH

`pubspec.yaml` contains no glassmorphism package. Neither `glassmorphism`, `glass_morphism`, `frosted_glass`, nor similar is present.

### 5b. `useGlassEffect: true` — MATCH

`useGlassEffect: true` appears **nowhere** in the codebase. All `GlassCard(...)` calls use the default (`useGlassEffect: false`), which renders as a solid card with no blur.

### 5c. Direct `BackdropFilter` / `ImageFilter.blur` usage — CANNOT VERIFY (founder judgment required)

`BackdropFilter` with `ImageFilter.blur` is used directly (bypassing GlassCard) in the following locations. These are **not** routed through GlassCard and therefore not controlled by `useGlassEffect`. Founder must judge which are acceptable overlays vs. content card violations:

| File | Lines | Context |
|------|-------|---------|
| `lib/src/features/settings/presentation/premium_screen.dart` | 727–728 | `sigmaX: 8, sigmaY: 8` — blur on premium plan card overlay |
| `lib/src/features/auth/presentation/login_screen.dart` | 454–455 | `sigmaX: 20, sigmaY: 20` — background blur on login bottom sheet |
| `lib/src/features/auth/presentation/widgets/registration_steps/birthday_step.dart` | 91–92, 143–144 | `sigmaX: 15, sigmaY: 15` — blur on date-picker modal backgrounds |
| `lib/src/features/auth/presentation/widgets/registration_steps/gym_step.dart` | 293–294 | `sigmaX: 20, sigmaY: 20` — blur on gym search modal background |
| `lib/src/features/auth/presentation/registration_flow.dart` | 1219–1220, 1386–1387, 1569–1570 | `sigmaX: 15, sigmaY: 15` — blur on step-transition modal backgrounds |
| `lib/src/features/auth/presentation/widgets/registration_steps/photos_step.dart` | 69–70 | `sigmaX: 10, sigmaY: 10` — blur on photo upload overlay |
| `lib/src/features/auth/presentation/widgets/registration_steps/partner_preference_modal.dart` | 29–30, 183–184 | `sigmaX: 15, sigmaY: 15` — blur on preference modal background |
| `lib/src/features/matches/presentation/match_dialog.dart` | 107–108, 217–218 | `sigmaX: 20, sigmaY: 20` / `sigmaX: 16` — blur on wave-action dialog background |
| `lib/src/features/matches/presentation/matches_screen.dart` | 217–218 | `sigmaX: 24, sigmaY: 24` — blur on matches filter bottom sheet background |
| `lib/src/features/matches/presentation/matches_screen.dart` | 751 | `sigmaX: 8.0, sigmaY: 8.0` — **profile avatar blurred as premium gate for Near-Miss** |
| `lib/src/features/dashboard/presentation/home_screen.dart` | 968 | blur on home screen overlay (context: radar modal) |

**Most are modal/overlay backgrounds** (standard glass-style sheets — acceptable). One warrants specific attention:

> `matches_screen.dart:751` — The profile avatar image is blurred via `ImageFilter.blur` when `isNearMissLocked` is true (free user seeing Near-Miss list). This is functional gating (blurring a content element to enforce premium), not decorative glassmorphism. The strategy does not explicitly address avatar blur gates. **Founder judgment needed on whether this constitutes a "content card" glass effect.**

---

## Summary Table

| Check | Result | Severity | Files Affected |
|-------|--------|----------|----------------|
| Forbidden words (user-facing) | MATCH | — | None |
| "seamless" in code comments | MATCH (not copy) | — | 2 (comments only) |
| Emoji in headlines/titles | MATCH | — | None |
| Emoji in non-headline keys | MATCH (acceptable) | — | 7 keys |
| Font overrides outside theme | MATCH | — | None |
| Glassmorphism package | MATCH | — | Not present |
| `useGlassEffect: true` | MATCH | — | Not used anywhere |
| Brand hex (`0xFFF4436C`) inline | MISMATCH | MEDIUM | 24+ files |
| Brand hex (`0xFF1A1A18`) inline | MISMATCH | MEDIUM | 22+ files |
| Brand hex (`0xFFF5C842`) inline | MISMATCH | MEDIUM | 5 files |
| Brand hex (`0xFF2D9B6F`) inline | MISMATCH | LOW | 2 files |
| Brand hex (`0xFFFAFAF7`) inline | MISMATCH | LOW | 4 files |
| Direct BackdropFilter (modals) | MATCH (acceptable) | — | 9 locations |
| Direct BackdropFilter (avatar blur gate) | CANNOT VERIFY | LOW | matches_screen.dart:751 |

---

## Recommended Fix Direction (founder approves before any edit)

**Hardcoded hex → token replacement:**  
Replace all inline `Color(0xFFF4436C)` with `TrembleTheme.rose`, `Color(0xFF1A1A18)` with `TrembleTheme.deepGraphite`, etc. This is purely mechanical. Total file count: ~26 files. No functional behavior changes.

**No fix needed for:**
- Forbidden words — clean
- Font overrides — clean
- Glassmorphism package — clean
- `useGlassEffect` — correctly defaulting to false everywhere

**Founder decision needed:**
- `matches_screen.dart:751` — Near-Miss avatar blur gate: acceptable premium UX pattern or content card glass violation?
