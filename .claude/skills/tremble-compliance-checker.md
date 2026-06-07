---
name: tremble-compliance-checker
description: Use this skill to check any Tremble code, copy, or feature against the strategy document and brand guidelines before it ships. Covers architectural violations (raw GPS writes, isPremium misuse, hardcoded hex, direct main push), brand voice violations (forbidden phrases, emoji in headlines, stock photo references), and strategy phase conflicts. Use before writing new features, reviewing PRs, auditing copy, or checking if something belongs in Phase 1–10. Also use when the user asks "is this on-brand", "does this conflict with strategy", or "can we do X".
origin: Tremble
---

# Tremble Compliance Checker

AI pattern matching against Tremble strategy, brand, and architectural rules.

**Scope:** This skill uses AI judgment — not a linter. It catches semantic violations that static analysis misses. For TypeScript errors, use `npm run build`. For Dart errors, use `flutter analyze`.

**Last verified:** 6 Jun 2026

---

## 1. Architectural Violations

Check any Flutter or CF code for these patterns. Each is a hard violation.

### A. isPremium misuse

```dart
// ❌ VIOLATION — raw Firestore field
final isPremium = userDoc['isPremium'];
final isPremium = userData.isPremium;
ref.watch(userProvider).isPremium

// ✅ CORRECT
final isPremium = ref.watch(effectiveIsPremiumProvider);
```

`effectiveIsPremiumProvider` combines RevenueCat entitlement + Firestore fallback. Raw `isPremium` bypasses RevenueCat. ~36 files were corrected Jun 2026 — never regress.

### B. Raw GPS writes to Firestore

```dart
// ❌ VIOLATION — raw coordinates in any Firestore write
firestore.collection('proximity').doc(uid).set({'lat': lat, 'lng': lng});
'latitude': position.latitude

// ✅ CORRECT — geohash only, via Cloud Function
await functions.httpsCallable('updateLocation').call({'geohash': geohash});
```

GPS is computed in Cloud Function RAM only. Never stored. This is both a privacy promise and an architecture rule.

### C. Hardcoded hex colors

```dart
// ❌ VIOLATION
color: Color(0xFFF4436C)
color: Colors.pink

// ✅ CORRECT
color: TrembleTheme.rose
color: context.colors.rose
```

26 files still have hardcoded hex as of Jun 2026 (P3, post-launch). Flag new ones, don't add more.

### D. onBleProximity / onRunEncounter references

```typescript
// ❌ DEAD — these triggers are deleted
onBleProximity
onRunEncounter

// ✅ CURRENT
scanProximityPairs  // scheduled CF, 1-min interval
```

### E. TTL field names

```typescript
// ❌ VIOLATION on proximity_events and run_encounters
expiresAt: null  // wrong field name caused prod bug
{ ttl: timestamp }  // wrong for these collections

// ✅ CORRECT
// proximity_events → expiresAt
// run_encounters → expiresAt
// rateLimits → ttl
// gdprRequests → ttl
```

See `references/ttl-field-map.md` for full table.

### F. Missing AppCheck on onCall functions

```typescript
// ❌ VIOLATION — every onCall needs AppCheck first
export const myFn = onCall(async (request) => {
  const uid = requireAuth(request); // AppCheck missing
});

// ✅ CORRECT
export const myFn = onCall(async (request) => {
  requireAppCheck(request);
  const uid = requireAuth(request);
});
```

Exception: scheduled functions (onSchedule) — no AppCheck needed, server-side only.

---

## 2. Brand Voice Violations

Check any copy — app UI, website, Instagram, ads — for these patterns.

### Forbidden phrases (hard block)

| Phrase | Reason |
|---|---|
| revolutionary | Generic hype — forbidden |
| seamless | Generic hype — forbidden |
| game-changing | Generic hype — forbidden |
| find love today | Too generic, sounds like Tinder |
| find your person | Bumble owns this framing |
| swipe | We don't swipe. Wrong mechanic |
| match queue | We have radar, not queues |
| chat | No chat in Tremble. Architecture-level claim |

### Forbidden visuals (flag in any copy referencing visuals)

- Stock couple photos on a couch or in a park
- 3D phone mockups
- Glassmorphism on content cards
- Emoji in headlines or display text
- Animated GIFs as hero content

### Voice rules — check copy against these

```
✅ Short sentences. One idea, one sentence.
✅ 2nd person direct — "you", not "users" or "people"
✅ Describe the mechanic — don't promise the emotion
✅ Technical language allowed only when it builds trust (BLE, GDPR by design)
✅ Sell the behavior, not the feature name
✅ No exclamation marks in headlines
✅ No emoji in headlines

❌ Never promise: love, connection, finding your person
❌ Never: "We exist to bring people together"
❌ Never: over-the-top emotional outcome framing
```

### Canonical copy lines (use or riff from these — don't rewrite from scratch)

| # | Line | Context |
|---|---|---|
| 01 | Dating apps turned human connection into a numbers game. Tremble is different by design. | Opening/manifesto |
| 03 | You don't open the app — the app works for you. | Core differentiator |
| 07 | Your location is never stored. Not policy. Architecture. | Privacy |
| 10 | Dating apps taught you to scroll. We're teaching you to look up. | Manifesto |
| 11 | Stop scrolling. Start being somewhere. | Social/short |
| 17 | 30 minutes. Find each other or don't. The clock is real. So is the person. | Trembling Window |

---

## 3. Strategy Phase Conflicts

Before implementing any feature, check which phase it belongs to.

| Phase | Scope |
|---|---|
| 1–9 | Complete as of Jun 2026 |
| 10 | Launch Polish — COMPLETE |
| Post-launch P2 | image compression, DND (NOTIF-5), Weekend Getaway enforcement |
| Post-launch P3 | heatmap (PRO only, requires F1 Protomaps first), raster tile migration |

**Flags:**
- Heatmap feature → P3, not before F1 Protomaps device test passes
- Weekend Getaway enforcement → founder decision pending
- Near-Miss tab visibility → founder decision pending
- Chat or messaging feature → architectural violation, not a phase issue — Tremble has no chat

---

## 4. How to Run a Compliance Check

When asked to check code or copy:

1. **Identify the type:** code (Dart/TS), copy (UI/marketing), or feature (new functionality)
2. **Run applicable checks:**
   - Code → Section 1 (A through F)
   - Copy → Section 2
   - Feature → Section 3
3. **Report format:**

```
## Compliance Report

Type: [code | copy | feature]
Target: [filename or description]

### VIOLATIONS
- [A] isPremium: line 47 — raw userDoc['isPremium'] read
- [Voice] Forbidden phrase: "seamless experience" in onboarding_step_3.dart:82

### WARNINGS
- Hardcoded hex Color(0xFFF4436C) on line 103 — P3 backlog, flag but don't block

### PASS
- AppCheck pattern correct on all onCall functions
- No raw GPS coordinates found
- TTL fields correct
```

---

## Composability

**This skill calls:**
- `firebase-security` — for AppCheck + TTL verification details
- `flutter-ble-proximity` — for proximity architecture reference
- `references/ttl-field-map.md` — TTL field lookups

**This skill is called by:**
- `tremble:deploy-workflow` — as final compliance gate before prod deploy recommendation
- `agents/security-reviewer` — for full OWASP audit, calls this as pre-check
- `agents/brand-voice-agent` — for copy compliance, calls Section 2
