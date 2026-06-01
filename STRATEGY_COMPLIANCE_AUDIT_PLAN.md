# Tremble — Strategy Compliance Audit Plan

**Source of truth:** `Tremble_Master_Strategy_v9.html`
**Target:** Flutter app (161 Dart files, ~53.7K LOC) + Cloud Functions (11 TS modules) + Firestore rules
**Tool:** Claude Code CLI
**Date:** June 2026

---

## How to run this

Each step is an independent audit unit: **FIND → REPORT → (founder decides) → FIX**.

Do **not** auto-fix on discovery. The strategy describes intent; the code implements mechanics. When they diverge, the strategy is not automatically right — it may be the stale artifact. Every step ends with a written report. A human approves the direction before any edit lands.

Run steps in order. Steps 1–4 are pure verification (read-only). Step 5+ depend on what the earlier steps surface. Never push to `main`. Never deploy to prod. Never touch `AndroidManifest.xml`, `Info.plist`, or `google-services.json` without explicit approval.

Each step below has two blocks:
- **AUDIT PROMPT** — paste into Claude Code CLI to run the check.
- **FIX PROMPT** — paste only if the audit found a real discrepancy and the founder approved the fix direction.

---

## Step 0 — Establish the baseline

Before any audit, the agent must hold the strategy claims as a structured checklist. This step produces that checklist so later steps reference a single artifact instead of re-parsing the HTML each time.

**AUDIT PROMPT:**
```
Read Tremble_Master_Strategy_v9.html in full. Extract every claim that is verifiable in code into a structured checklist file called STRATEGY_CLAIMS.md. A claim is "verifiable in code" if it asserts a specific numeric threshold, a feature gate (free vs premium), a data field, a TTL, a radius, a limit, a notification trigger, or an architectural guarantee.

For each claim, record:
- Claim ID (e.g. C-RADIUS-01)
- Exact quote from the strategy
- Strategy section it came from
- Where in the codebase it WOULD be implemented (your best guess, file/dir level)
- Verification method (what to grep / what to read)

Do NOT verify anything yet. Do NOT edit any code. Output only STRATEGY_CLAIMS.md. Group claims by domain: Proximity/Radar, Wave/Limits, Trembling Window, History/Recaps, Filters, Heatmap/Map, Notifications, Privacy/TTL, Pricing/Premium-gating, Brand/Copy.
```

---

## Step 1 — Proximity & Radar engine

Strategy claims to verify:
- Free radius 100m, Premium 250m
- RSSI threshold -75 dBm (Free), -85 dBm (Premium)
- GPS geohash precision 7 pre-filter + BLE RSSI confirmation
- BLE advertises service UUID only (no identity), identity resolved server-side via `findNearby`
- Matching threshold: 0.55 (auto) / 0.70 (manual)

**AUDIT PROMPT:**
```
Audit the proximity and radar engine against STRATEGY_CLAIMS.md (domain: Proximity/Radar).

Check specifically:
1. Radius values: is Free=100m and Premium=250m enforced, and is the value driven by premium status (not hardcoded single value)? Find where radius is selected.
2. RSSI thresholds: is -75dBm used for Free and -85dBm for Premium? Find the filtering code.
3. Geohash precision: confirm precision 7 is used in the proximity write path and the findNearby query. Confirm raw GPS coordinates are NEVER written to Firestore — only geohash.
4. BLE advertising: confirm advertising broadcasts the fixed Tremble service UUID only, with no identity payload. Confirm scanning filters by that service UUID.
5. Identity resolution: confirm identity is resolved server-side (findNearby / geohash set), not from BLE payload.
6. Matching thresholds: confirm 0.55 auto / 0.70 manual.

For each: report MATCH / MISMATCH / CANNOT VERIFY, cite the exact file:line, and quote the code. Do NOT edit anything. Where the code diverges from strategy, state which one is more likely correct and why, but do not change it.
```

**FIX PROMPT (only if approved):**
```
Discrepancy [paste the specific finding, e.g. "radius is hardcoded to 150m in ble_service.dart:X instead of 100/250 split"].

Fix the code to match the strategy claim [C-RADIUS-01]: Free=100m, Premium=250m, selected by effectiveIsPremiumProvider. Do not change any other behavior. Do not touch RSSI logic. Show me the diff before writing. After writing, run `flutter analyze` and report the result. Do not commit.
```

---

## Step 2 — Wave mechanic & limits

Strategy claims:
- Mutual waves: 5/month (Free), 20/month (Premium)
- Wave sending is transparent to recipient ("[name] waved at you"), discreet for sender
- Only mutual wave opens active radar
- Wave possible ONLY in two places: live proximity event OR 10-min Premium recap window

**AUDIT PROMPT:**
```
Audit the wave mechanic against STRATEGY_CLAIMS.md (domain: Wave/Limits).

Check specifically:
1. Wave limit: is the cap 5/month for Free and 20/month for Premium? Find where the limit is enforced (client and/or Cloud Function). Confirm the reset window is monthly, not daily or weekly.
2. Limit enforcement location: is it enforced server-side (sendWave CF), or only client-side? Client-only is a vulnerability — report it.
3. Mutual-wave-only radar: confirm the active radar opens ONLY on mutual wave, not on a single wave.
4. Wave entry points: confirm a wave can be initiated ONLY during a live proximity event or the 10-min Premium recap TTL window. Confirm there is no other code path that allows sending a wave (e.g. from a static history list).

Report MATCH / MISMATCH / CANNOT VERIFY per item with file:line and code quote. Do NOT edit. Flag any place where the monthly limit could be bypassed.
```

**FIX PROMPT (only if approved):**
```
Discrepancy [paste finding].

Fix to match [C-WAVE-LIMIT]: Free 5/month, Premium 20/month, enforced server-side in the sendWave Cloud Function with a monthly reset. If the limit is currently client-only, add server-side enforcement; keep the client check as UX but make the CF authoritative. Show the diff before writing. Do not change the wave UI copy. After writing, report whether tests cover this path; if not, write one. Do not deploy.
```

---

## Step 3 — Trembling Window & Pulse Intercept

Strategy claims:
- 30-minute window opens on mutual match
- Active radar: two moving points, compass rotates view, dot leaves trail
- Pulse Intercept: send phone number OR view-once photo, 10-min TTL, snap-style delete on viewedAt
- No free text input anywhere
- Pulse Intercept is identical for Free and Premium

**AUDIT PROMPT:**
```
Audit the Trembling Window and Pulse Intercept against STRATEGY_CLAIMS.md (domain: Trembling Window).

Check specifically:
1. Window duration: confirm 30 minutes. Find the TTL / timer. Cross-check against matches/{id} expiresAt = 30min in Firestore.
2. Pulse Intercept payloads: confirm exactly two options — phone number and view-once photo. Confirm NO free-text message field exists anywhere in the Trembling Window UI.
3. View-once + TTL: confirm the photo deletes on viewedAt OR after 10-min TTL, server-side. Confirm the Redis TTL is 10 minutes.
4. Free vs Premium parity: confirm Pulse Intercept behaves identically for Free and Premium (it is NOT gated).

Report per item with file:line. Do NOT edit. The "no free text" rule is a product absolute — if you find ANY text input in this flow, flag it as CRITICAL.
```

**FIX PROMPT (only if approved):**
```
Discrepancy [paste finding].

Fix to match [C-TREMBLING / C-PULSE]. [State the exact change, e.g. "remove the free-text field at X" or "change Pulse Intercept TTL from 15min to 10min at Y"]. The "no free text, no chat" rule is a permanent product absolute — never replace it with a hidden or disabled field; remove it. Show the diff before writing. After writing, run flutter analyze and report. Do not commit.
```

---

## Step 4 — History tab: Matches / Recaps / Near-Miss

This is the highest-discrepancy-risk area because the free/premium gating is dense.

Strategy claims:
- **Matches:** Free = limited card, Premium = full card
- **Recaps (Run/Gym/Event):** Free = photo+name+age, greyscale, no card open, no action, gone on close. Premium = colour, open card + 10-min TTL wave, then read-only archive forever. "To ni več naključje" notif on 2nd encounter (Premium).
- **Near-Miss History:** Free = tab NOT visible, 1×/month aggregated push (count only, no names/photos). Premium = full tab, full card, read-only forever.
- Wave possible only in live proximity event or 10-min Premium recap window.
- Compatibility score (≥70% Near-Miss filter) computed real-time, NEVER stored in Firestore.

**AUDIT PROMPT:**
```
Audit the History tab against STRATEGY_CLAIMS.md (domain: History/Recaps). This is the densest gating area — be exhaustive.

Check specifically:
1. Matches tab: Free shows limited card, Premium shows full card. Find the gate.
2. Recaps greyscale gate: confirm Free recaps render greyscale with no card-open and no wave action; Premium renders colour with card-open + 10-min TTL wave. Find the premium gate on this screen.
3. Recap archive: confirm Premium recaps move to read-only archive after the 10-min TTL; confirm Free recaps are NOT persisted after close.
4. "To ni več naključje" notification: confirm it fires on 2nd encounter with the same person, Premium-only.
5. Near-Miss tab visibility: confirm the Near-Miss History TAB is hidden entirely for Free users. Free must NOT see the tab — only receive the monthly aggregated push.
6. Near-Miss monthly push: confirm Free gets a 1×/month aggregated push containing a COUNT ONLY — no names, no photos.
7. Compatibility score storage: CRITICAL — confirm the ≥70% compatibility score used to populate Near-Miss is computed at read time and is NEVER written to Firestore. Grep the entire codebase and Cloud Functions for any write of a compatibility/match score to Firestore. If found, flag CRITICAL.

Report per item with file:line and code quote. Do NOT edit. Items 5, 6, and 7 are product/privacy absolutes — flag any violation as CRITICAL.
```

**FIX PROMPT (only if approved):**
```
Discrepancy [paste finding].

Fix to match [C-HISTORY-xx]. [State exact change.] Constraints that must hold after the fix:
- Free never sees the Near-Miss tab.
- Free Near-Miss push contains count only — no names, no photos, no thumbnails.
- Compatibility score is never persisted to Firestore — compute at read time only.
- Free recaps render greyscale and are not persisted after close.
Show the diff before writing. If the fix touches the Near-Miss data path, also show me what data the Cloud Function returns to a Free client and confirm it cannot leak names/photos. After writing, run flutter analyze. Do not commit.
```

---

## Step 5 — Filters (Hard Filters / exclusion rules)

Strategy claims:
- Free = basic filtering (gender, age)
- Premium = Hard Filters as **exclusion rules** ("I don't want someone who smokes to wave at me")
- Exclusion is enforced **server-side** in findNearby, **directional**: the receiver's filter protects the receiver's signal. If A excludes smokers, a smoker cannot trigger a proximity event at A.

**AUDIT PROMPT:**
```
Audit filtering against STRATEGY_CLAIMS.md (domain: Filters).

Check specifically:
1. Free filtering: confirm gender + age filtering is available to Free.
2. Hard Filters gating: confirm exclusion-rule filters are Premium-only.
3. Server-side enforcement: confirm Hard Filters are applied SERVER-SIDE in the findNearby Cloud Function (in the geohash query path), NOT client-side. Client-side filtering means all nearby users' data is already transferred to the device — that is a privacy violation. If filtering is client-side, flag CRITICAL.
4. Directional logic: confirm the filter protects the RECEIVER. If user A excludes "smokers", confirm a smoker cannot generate a proximity event at A. Confirm the filter is applied to A's own query (A's exclusion set), not bilaterally.

Report per item with file:line. Do NOT edit. Item 3 is a privacy absolute.
```

**FIX PROMPT (only if approved):**
```
Discrepancy [paste finding].

Fix to match [C-FILTER]. Hard Filters must be exclusion rules enforced server-side in findNearby, applied to the querying user's own exclusion set (directional — protects the receiver). Never filter client-side after transferring nearby users' data. Show the diff before writing. Show me the exact findNearby query shape after the change. Do not deploy the Cloud Function — output the changed code and the deploy command for the founder to run.
```

---

## Step 6 — Heatmap & Map events

Strategy claims:
- **Heatmap:** Free = circles visible, data inside hidden. Premium = count of active inside circle + filter toggle by type. (Phase 3 — may be mock/not built.)
- **Map events:** Free = events visible, no participant count. Premium = count of active users inside event.

**AUDIT PROMPT:**
```
Audit Heatmap and Map events against STRATEGY_CLAIMS.md (domain: Heatmap/Map).

Check specifically:
1. Heatmap existence: is the heatmap built, or still mock/placeholder? Report its actual state. Strategy marks it Phase 3.
2. Heatmap gating: IF built, confirm Free sees circles without inside-count, Premium sees count + type filter toggle.
3. Map events gating: confirm Free sees events without participant count; Premium sees the active-user count inside an event.
4. Confirm the event participant count is a TOTAL active count, not a count of matches (per strategy: "skupno, ne matchi").

Report per item with file:line. If heatmap is mock, say so plainly and do not treat mock as a discrepancy — note it as "deferred per Phase 3". Do NOT edit.
```

**FIX PROMPT (only if approved):**
```
Discrepancy [paste finding].

Fix to match [C-HEATMAP / C-MAP-EVENT]. [Exact change.] For map events: Free hides the participant count, Premium shows total active count (not match count). For heatmap: only fix if it is actually built — if it is mock/Phase 3, do NOT implement it now; instead add a TODO referencing the strategy claim. Show the diff before writing. Do not commit.
```

---

## Step 7 — Notifications

Strategy claims (section 3.6):
- Proximity event (new person): silent, always
- Wave received: silent, always
- Mutual wave: normal, opens active radar
- 2nd+ same person near (after wave sent): normal — "To ni več naključje" + Trembling Window offer
- Recap after activity: normal, once
- Near-Miss aggregated push (Free, 1×/month): normal, count only
- During Run/Gym/Event: silent (DND) except mutual wave

**AUDIT PROMPT:**
```
Audit the notification rules against STRATEGY_CLAIMS.md (domain: Notifications).

For each of the 7 notification situations in strategy section 3.6, find the code that triggers it and confirm:
- The trigger condition matches.
- The notification type matches (silent vs normal).
- The DND/silent logic during Run/Gym/Event is enforced, with the mutual-wave exception.

Specifically verify:
1. Proximity event and wave-received are SILENT.
2. "To ni več naključje" fires on 2nd+ encounter with the same person after a wave was sent.
3. Near-Miss monthly push is count-only (cross-check with Step 4 item 6).
4. During activities, all notifications are suppressed EXCEPT mutual wave.

Report per item with file:line. Do NOT edit.
```

**FIX PROMPT (only if approved):**
```
Discrepancy [paste finding].

Fix to match [C-NOTIF-xx]. [Exact change.] Constraints: proximity and wave-received stay silent; during activities only mutual wave breaks DND. Show the diff before writing. After writing, run flutter analyze. Do not commit.
```

---

## Step 8 — Privacy & TTL architecture

This is the legal-risk core. Strategy claims:
- GPS coordinates exist only transiently in Cloud Function RAM, converted to geohash p7, never reach Firestore.
- TTL: `proximity/{uid}` = 24h; `proximity_events` + `run_encounters` + `active_run_crosses` = 10min; `matches` = 30min; `gdprRequests` = 2y.
- TTL field is `expiresAt` everywhere (the known `ttl` vs `expiresAt` mismatch must be resolved).
- No "encrypted" overclaim (infra-level only, no field-level) — `consent_step.dart` claim needs legal review.
- No "zero location stored" claim — geohash p7 IS stored (~150m cell).

**AUDIT PROMPT:**
```
Audit privacy and TTL against STRATEGY_CLAIMS.md (domain: Privacy/TTL). This is the legal-risk core — be exhaustive and literal.

Check specifically:
1. GPS never in Firestore: grep every Firestore write across the app AND Cloud Functions. Confirm NO raw lat/lng is ever written. Only geohash should reach Firestore. List every write that includes location-like data.
2. Geohash precision: confirm precision 7 everywhere geohash is written.
3. TTL field consistency: confirm every writer (client + CF) writes the field named `expiresAt`, and confirm the deployed Firestore TTL policy targets `expiresAt` — NOT `ttl`. If any writer uses a different field name, flag CRITICAL (data would never expire).
4. TTL values: proximity/{uid}=24h, proximity_events/run_encounters/active_run_crosses=10min, matches=30min, gdprRequests=2y. Confirm each.
5. "encrypted" claim: locate the encryption claim in consent_step.dart. Report the exact wording and line. Confirm whether the app does field-level encryption or only infra-level. If only infra-level, the claim is an overclaim — flag for legal review (do not auto-reword).
6. "zero location stored" overclaim: grep all copy (Dart translations + any in-app strings) for claims like "zero location", "location never stored", "we don't store location". Geohash p7 IS stored. Flag every instance.

Report per item with file:line and exact quote. Do NOT edit. Items 1, 3, 5, 6 are legal/privacy critical — flag violations as CRITICAL and stop for founder review before any fix.
```

**FIX PROMPT (only if approved):**
```
Discrepancy [paste finding].

Fix to match [C-PRIVACY-xx]. Hard constraints:
- Raw GPS must never be written to Firestore — only geohash p7.
- All TTL writers use the field `expiresAt`; the Firestore TTL policy must target `expiresAt`.
- Copy must not claim "zero location stored" or imply no location data exists. The honest claim is: exact coordinates are never stored; only a coarse geohash (~150m cell) is retained transiently with a TTL.
- Do NOT rewrite the "encrypted" claim yourself — output options for the founder; this needs legal sign-off.
For the TTL field fix specifically: if the policy targets `ttl` but writers use `expiresAt`, the correct fix is to align the deployed policy to `expiresAt` (founder runs the gcloud/firebase command) — do not silently rename the field in code without confirming which the live policy uses. Show the diff and the exact commands for the founder. Do not deploy.
```

---

## Step 9 — Pricing & Premium gating integrity

Strategy claims:
- Tiers: Signal Prime €7,99/mo (`monthly`), Weekend Getaway €2,99/weekend Fri 19:00–Sun 19:00 (`weekly`), Yearly €59,99 (`yearly`), Lifetime €149,99 (`lifetime`).
- All paid tiers grant identical Premium features — only duration differs.
- Premium status fully hidden from other users (no stigma badge).
- `isPremium: false` for all new users.
- Premium resolved via `effectiveIsPremiumProvider` (RevenueCat + event geofence "Taste of Premium").

**AUDIT PROMPT:**
```
Audit pricing and premium-gating integrity against STRATEGY_CLAIMS.md (domain: Pricing/Premium-gating).

Check specifically:
1. Product identifiers: confirm the code references exactly monthly / weekly / yearly / lifetime and nothing else.
2. Single entitlement: confirm all paid tiers map to ONE premium entitlement granting identical features — duration is the only difference. There must be no tier that grants more features than another.
3. Premium resolution: confirm gating uses effectiveIsPremiumProvider (RevenueCat + event geofence), not a raw isPremium read scattered across screens. List every place premium status is checked and confirm they all go through the single provider.
4. New users default: confirm isPremium defaults to false (client AND Cloud Function).
5. Weekend Getaway window: confirm the weekly tier's active window is Fri 19:00–Sun 19:00 — if that time-bounding is implemented anywhere, verify it; if not, note it as unimplemented.
6. Premium status hidden: confirm no UI exposes another user's premium status.

Report per item with file:line. Do NOT edit. Flag any feature that is gated by a SPECIFIC tier rather than the single premium entitlement.
```

**FIX PROMPT (only if approved):**
```
Discrepancy [paste finding].

Fix to match [C-PRICING-xx]. Constraints: all paid tiers grant identical features via one premium entitlement; gating goes through effectiveIsPremiumProvider only; new users default isPremium=false; no UI reveals another user's premium status. If a screen reads premium status directly instead of via the provider, route it through the provider. Show the diff before writing. Do not change RevenueCat product identifiers. After writing, run flutter analyze. Do not commit.
```

---

## Step 10 — Brand & copy compliance (in-app strings only)

Strategy claims (sections 4.1, 4.2, 7):
- Forbidden words: revolutionary, seamless, game-changing, "find love today".
- No emoji in headlines.
- Colors: Rose #F4436C, Yellow #F5C842, Green #2D9B6F, Graphite #1A1A18, Cream #FAFAF7 — referenced as design tokens, never hardcoded hex.
- Fonts: Playfair Display (display), Lora (body), Instrument Sans (UI).
- No glassmorphism on content cards (package already removed — verify it stays removed).

**AUDIT PROMPT:**
```
Audit in-app brand and copy compliance against STRATEGY_CLAIMS.md (domain: Brand/Copy). Scope: Dart UI strings, translation files, and theme/token definitions. Do NOT audit the marketing website here.

Check specifically:
1. Forbidden words: grep all translation files (all 8 languages) and in-app strings for: revolutionary, seamless, game-changing, "find love today" (and SL equivalents). Report every hit.
2. Emoji in headlines: scan headline/title strings for emoji. Report any.
3. Hardcoded hex: grep for hardcoded color hex values (#F4436C etc. and any other raw hex) in widget files. Brand colors must come from a token/theme, not inline hex. List every hardcoded hex in UI code.
4. Fonts: confirm the three fonts are wired via theme (Playfair Display / Lora / Instrument Sans) and not overridden ad hoc.
5. Glassmorphism: confirm no glassmorphism package is back in pubspec.yaml and no blur-based glass effect is applied to content cards.

Report per item with file:line and exact string. Do NOT edit. For forbidden words, show the surrounding sentence so the founder can judge replacement.
```

**FIX PROMPT (only if approved):**
```
Discrepancy [paste finding].

Fix to match [C-BRAND-xx]. For forbidden words: replace with on-brand alternatives that keep the meaning — short, direct, no hype. Show me each before/after string in both EN and SL before writing; do not change meaning. For hardcoded hex: replace with the corresponding design token. Do not touch any string whose replacement changes legal or functional meaning. Show the full diff before writing. After writing, run flutter analyze. Do not commit.
```

---

## Step 11 — Consolidated report

**AUDIT PROMPT:**
```
Produce AUDIT_REPORT.md consolidating Steps 1–10. Structure:

1. Summary table: domain | claims checked | MATCH | MISMATCH | CANNOT VERIFY | CRITICAL.
2. CRITICAL findings first, each with: claim ID, file:line, what the strategy says, what the code does, recommended direction (fix code OR update strategy), and why.
3. Non-critical mismatches, same format.
4. "Strategy is stale" candidates — places where the code is correct and the STRATEGY document should change instead. List the exact strategy section to edit.
5. CANNOT VERIFY list — what blocked verification and what's needed to resolve.

Do NOT fix anything in this step. This report is the decision document. After I review it, I will approve fixes step by step using the FIX PROMPTs.
```

---

## Notes on sequencing and risk

- **Steps 4, 5, 8 carry the privacy/legal weight.** If any of them surfaces a CRITICAL (GPS in Firestore, client-side filtering, compatibility score persisted, TTL field mismatch, "zero location" copy), stop the whole audit and resolve before continuing — these are App Store rejection and GDPR exposure risks, not cosmetic.
- **Cloud Function changes are never deployed by the agent.** The agent outputs the changed code and the deploy command; the founder deploys.
- **The "strategy is stale" path matters.** Some mismatches mean the v9 document is wrong, not the code. Step 11 section 4 exists so you don't blindly bend working code to a document that drifted. When that happens, the fix is a strategy edit, which comes back to this Claude session, not Claude Code CLI.
- **Cross-check option:** for any high-risk diff (Firestore rules, BLE, findNearby), run the same diff through Codex 5.5 High as a second opinion before the founder approves. Do not use Gemini Flash-Low for any of this — wrong tool for audit-depth reasoning.
