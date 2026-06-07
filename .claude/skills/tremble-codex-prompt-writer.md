---
name: tremble-codex-prompt-writer
description: Use this skill to generate Codex CLI or Claude Code CLI prompts for Tremble development tasks. Covers the correct prompt format, Flutter build flags, architecture constraints, and task-specific context injection. Use whenever the user needs a prompt to run in terminal — for bug fixes, feature implementation, refactoring, CF changes, or any code task. Triggers on "write a Codex prompt", "generate a CLI prompt", "give me a prompt for Claude Code", "write the fix prompt", or any task where the output is meant to be executed in a terminal agent.
origin: Tremble
---

# Tremble Codex Prompt Writer

Generates properly formatted prompts for Codex CLI (Gemini-based) and Claude Code CLI.

**Last verified:** 6 Jun 2026

---

## 1. Agent Selection

| Agent | Use when |
|---|---|
| **Codex CLI** | Complex multi-file tasks, large context needed, architectural changes |
| **Claude Code CLI** | Targeted single-file or 2-3 file fixes, fast iteration |

Default to Codex CLI for anything touching more than 3 files or requiring cross-file understanding.

---

## 2. Prompt Template — Standard Fix

```
In the Tremble Flutter project (GitHub: MartinD111/Tremble-DatingApp), fix the following:

## Task
[Specific description of what needs to be done]

## Context
[Why this matters / what it fixes / relevant background]

## Requirements

### Architecture (non-negotiable)
- Use `effectiveIsPremiumProvider` for all isPremium checks — never `userDoc['isPremium']` or raw Firestore field
- Never write raw GPS coordinates to Firestore — geohash only via `updateLocation` CF
- BLE service UUID: `73a9429f-fd01-4ac9-9e5a-eabd0d31438e` — never change
- Proximity detection is server-side via `scanProximityPairs` scheduled CF — no `onBleProximity` or `onRunEncounter`
- Colors: use TrembleTheme tokens — never hardcoded hex
- TTL fields: proximity_events/run_encounters → `expiresAt` | rateLimits/gdprRequests → `ttl`

### Build
- Build command: `flutter run --dart-define-from-file=.env.json --flavor dev --dart-define=FLAVOR=dev`
- All tests must pass: `flutter test`
- Zero Flutter analyze errors: `flutter analyze`

### Restrictions
- Never push to main directly
- Never modify AndroidManifest.xml, Info.plist, or google-services.json
- Never deploy to am---dating-app (prod) autonomously

## Files Likely Affected
[List specific files]

## Expected Output
[What the finished state looks like — test passing, screen rendering correctly, CF returning 200, etc.]
```

---

## 3. Prompt Template — Cloud Function

```
In the Tremble Firebase Functions project (functions/ folder, MartinD111/Tremble-DatingApp):

## Task
[CF-specific task]

## Context
[Background]

## Requirements

### CF Architecture
- Runtime: Node.js v22, region: europe-west1
- All onCall functions: `requireAppCheck(request)` FIRST, then `requireAuth(request)`, then Zod validation
- Scheduled functions (onSchedule): NO AppCheck, server-side only
- No PII in console.log — truncate UIDs: `uid.substring(0, 8) + '...'`
- TTL fields: see architecture requirements

### TypeScript
- `npm run build` must pass with 0 errors
- `npm run lint` must pass

### Deploy (dev only — NEVER prod autonomously)
- After implementing: `firebase deploy --only functions --project tremble-dev`
- Verify in Firebase Console → Functions → Logs

## Files Likely Affected
[List CF files]

## Expected Output
[Describe expected CF behavior]
```

---

## 4. Prompt Template — Website (Next.js)

```
In the Tremble website project (trembledating.com, Next.js 16, Cloudflare Pages):

## Task
[Website task]

## Context
[Background]

## Requirements

### Brand
- Colors: Rose #F4436C, Yellow #F5C842, Green #2D9B6F, Graphite #1A1A18, Cream #FAFAF7
- Fonts: Playfair Display (display), Lora (body), Instrument Sans (UI)
- No glassmorphism on content cards
- No 3D phone mockups
- No stock couple photos
- No emoji in headlines
- Forbidden phrases: revolutionary, seamless, game-changing, "find love today"

### Technical
- Next.js 16 patterns
- Deployed via Cloudflare Pages — no server-side APIs that require Node.js runtime
- Forms: email normalization via toLowerCase() on both client (WaitlistForm.tsx) and server (route.ts)

## Files Likely Affected
[List files]

## Expected Output
[Describe expected result]
```

---

## 5. Prompt Enhancers

Add these blocks when relevant:

**When touching Riverpod providers:**
```
Use Riverpod 2 patterns — no legacy ProviderReference. 
Providers must be defined at top-level, not inside functions.
```

**When touching GoRouter:**
```
Router is GoRouter. Use context.go() for replace, context.push() for stack.
Authenticated routes use redirect guards — do not bypass them.
```

**When touching RevenueCat:**
```
RevenueCat SDK: purchases_flutter v10.2.0 + purchases_ui_flutter.
API key via dart-define: REVENUECAT_API_KEY.
Not live yet — Apple Developer org approval pending.
Use effectiveIsPremiumProvider which combines RC entitlement + Firestore fallback.
```

---

## 6. Common Mistakes to Avoid in Prompts

| Mistake | Correct |
|---|---|
| "fix the isPremium bug" | Specify exact file + line number if known |
| "deploy when done" | Specify: deploy to tremble-dev only, never prod |
| "use the location service" | Specify: geohash only, no raw lat/lng |
| Including `#` inline comments in zsh commands | zsh interprets `#` as end-of-line — remove all inline comments |

---

## Composability

**This skill is called by:**
- `tremble-task-manager` — when generating task description with embedded Codex prompt
- `tremble-session-closer` — when the next session needs a starting prompt

**This skill calls:**
- `tremble-compliance-checker` — to verify the generated prompt doesn't encode a violation
- `firebase-security` — for CF-specific prompt requirements
- `flutter-ble-proximity` — for BLE/proximity-specific prompt requirements
