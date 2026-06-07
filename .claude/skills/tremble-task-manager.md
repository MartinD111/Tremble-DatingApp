---
name: tremble-task-manager
description: Use this skill to create, update, close, or organize Todoist tasks for the Tremble project. Covers correct sectionId routing, priority levels, label assignment (founder-action vs autonomous), and Codex prompt formatting in task descriptions. Use whenever adding new tasks, closing completed work, searching for open tasks by section, or converting a discovered issue into a properly formatted Todoist task.
origin: Tremble
---

# Tremble Task Manager

Todoist task management for the Tremble project. Always uses sectionId — never freetext search alone.

**Last verified:** 6 Jun 2026

---

## 1. Project + Section IDs

**Project:** `6fxxh6MXfmh2q3FP`

| Section | ID | Use for |
|---|---|---|
| Blockers | `6gj5rPJfRwPCfMGw` | Launch blockers, Apple Dev, RevenueCat gates |
| App | `6ggWg86gP3qF3Hfw` | Flutter, Firebase, BLE, CF changes |
| Website | `6ggWg86XHJp37fjw` | trembledating.com, Next.js, Cloudflare Pages |
| Marketing | `6ghmF6Gxjc9FP9rP` | Instagram, Meta, content ops, waitlist |
| Legal | `6ggWg85rFC7jqXcP` | GDPR, DPA, ToS, App Store legal |
| Infra | `6gj5rPP2hwh8WmfP` | Firebase billing, Cloudflare, Upstash, R2 |

**Rule:** Always pass `sectionId` when creating or filtering tasks. `searchText` is unreliable in Todoist MCP — use `sectionId` for all filtering.

---

## 2. Priority Levels

| Priority | Todoist value | Meaning |
|---|---|---|
| p1 | `4` | Launch blocker — gates TestFlight, App Store, prod deploy |
| p2 | `3` | Pre-launch required — must ship before public release |
| p3 | `2` | Post-launch — does not block release |
| p4 | `1` | Nice to have, no deadline |

---

## 3. Labels

| Label | When to use |
|---|---|
| `founder-action` | Requires manual action: Firebase Console, Apple Developer, terminal command that can't be scripted |
| `autonomous` | Can be executed by Claude Code CLI without founder intervention |

Every task gets exactly one label. No task without a label.

---

## 4. Task Description Format

For `autonomous` tasks, always include the Codex/Claude Code fix prompt in the description field. This is the prompt the founder will paste into CLI.

```
[CODEX PROMPT]
In the Tremble Flutter project (MartinD111/Tremble-DatingApp), fix the following:

<specific issue description>

Requirements:
- Use effectiveIsPremiumProvider, never raw isPremium
- Never write raw GPS coordinates to Firestore
- Build: flutter run --dart-define-from-file=.env.json --flavor dev --dart-define=FLAVOR=dev
- All tests must pass after fix: flutter test

Files likely affected: <list>
```

For `founder-action` tasks, describe the exact manual steps:
```
[FOUNDER ACTION]
1. Go to: Firebase Console → <project> → <section>
2. Do: <exact action>
3. Verify: <what to check>
```

---

## 5. Creating a Task

When creating a new task, always collect:

1. **Title** — concise, starts with verb (Fix, Add, Deploy, Review, Update)
2. **Section** — which area? (App/Website/Marketing/Legal/Infra/Blockers)
3. **Priority** — p1/p2/p3/p4
4. **Label** — founder-action or autonomous
5. **Description** — Codex prompt OR manual steps (see Section 4)
6. **Due date** — only if there's a real deadline

Template:
```
Title: Fix [what] in [where]
Section: [sectionId from table above]
Priority: p[1-4]
Label: [founder-action | autonomous]
Description: [Codex prompt or manual steps]
```

---

## 6. Closing Tasks

Before closing, always retrieve the task ID first:

```
1. find-tasks with sectionId filter
2. Identify task ID from results
3. complete-tasks with exact task ID
```

Never guess task IDs. Never complete without verifying the title matches.

---

## 7. Current Open Blockers (as of 6 Jun 2026)

For reference — do not create duplicates:

| Task | Section | Priority |
|---|---|---|
| Apple Developer org €300 approval | Blockers | p1 |
| iOS dev provisioning com.pulse (BLOCKER-005) | Blockers | p1 |
| Deploy prod Firestore indexes | App | p1 |
| Fix prod TTL: proximity → geoHashExpiresAt | App | p1 |
| DPA re-sign under AMS Solutions d.o.o. | Legal | p2 |
| Pricing carousel visual review + deploy | Website | p2 |
| /bug form sanitization + length cap | Website | p2 |
| image compression (flutter_image_compress) | App | p2 |

---

## Composability

**This skill is called by:**
- `tremble:session-closer` — to close completed tasks after a dev session

**This skill calls:**
- Todoist MCP tools directly: `find-tasks`, `add-tasks`, `complete-tasks`, `update-tasks`
