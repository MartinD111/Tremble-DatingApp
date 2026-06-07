---
name: tremble-session-closer
description: Use this skill at the end of any dev, design, or ops session to close completed Todoist tasks, generate a TREMBLE_PROJECT_CONTEXT.md diff, and update Notion. Triggers when the user uploads a session_summary.md file, says "close this session", "wrap up", "end of session", "session done", or "what do I need to update". Also use when the user asks what was accomplished in a session and wants to sync it to the project tracking system.
origin: Tremble
---

# Tremble Session Closer

Processes `session_summary.md` from a CLI session, closes Todoist tasks, and generates context updates.

**Last verified:** 6 Jun 2026

---

## How This Works

```
Claude Code / Codex CLI session
         │
         ▼
  session_summary.md     ← you write this at end of CLI session
         │
         ▼ (upload to claude.ai)
  tremble:session-closer ← this skill
         │
    ┌────┴────────────────┐
    ▼                     ▼
Todoist tasks        Context delta
(close completed)    (for TREMBLE_PROJECT_CONTEXT.md)
         │                     │
         ▼                     ▼
  Your confirmation      You apply manually
  required before close
```

---

## 1. session_summary.md Format

The CLI session must produce this file. Template in `references/session_summary_template.md`.

Required fields:
- `## Session:` — date + duration
- `## Type:` — app | website | marketing | infra | legal
- `### Completed` — tasks finished, with Todoist IDs where known
- `### Files Changed` — list of modified files
- `### Deployed` — what was deployed and where
- `### Blockers Discovered` — new issues found
- `### Decisions Made` — architectural or strategy decisions
- `### Next Session Start Point` — exact re-entry point
- `### Context Delta` — what changed for TREMBLE_PROJECT_CONTEXT.md

If the user hasn't produced a `session_summary.md`, ask them to fill the template from `references/session_summary_template.md` before proceeding.

---

## 2. Processing Steps

When `session_summary.md` is uploaded or pasted:

### Step A — Parse completed tasks

Extract the `### Completed` section. For each item:
1. If Todoist task ID is present → add to close list
2. If no ID → search Todoist with `sectionId` (from `tremble-task-manager`) to find the matching task
3. Present the close list to the founder before executing

**Never close tasks without founder confirmation.**

### Step B — Create new tasks for blockers

For each item in `### Blockers Discovered`:
1. Determine section (App/Website/Legal/Infra/Marketing/Blockers)
2. Determine priority (p1/p2/p3)
3. Determine label (founder-action or autonomous)
4. Create task via `tremble-task-manager`

### Step C — Generate context delta

From `### Context Delta` + `### Decisions Made`, produce a diff block:

```markdown
## TREMBLE_PROJECT_CONTEXT.md — Suggested Updates

### Section: Trenutno stanje — App
ADD under "Kar je DONE":
- [new achievement] ✅

CHANGE:
- Old line: "..."
- New line: "..."

### Section: BLOCKERS
ADD:
- 🔴 [new blocker] — [description]

REMOVE:
- ✅ [completed blocker]
```

Present this diff — **do not apply it**. The founder applies it manually.

### Step D — Notion update block

Generate a brief Notion update for `315b7419-2f1e-80a1-999e-fdeb5b425aea`:

```
Session [date]: [1-sentence summary of what was done]
Status: [which phase / what's next]
Blockers: [count open blockers]
```

---

## 3. What Remains Manual

These steps are always manual — the skill does not do them:

| Action | Why manual |
|---|---|
| Applying TREMBLE_PROJECT_CONTEXT.md diff | Too critical for autonomous write |
| Confirming Todoist task closures | Avoid false-positive closes |
| Notion page edit | Requires human judgment on framing |
| Git commit / PR creation | Never autonomous on main |

---

## 4. Session Closer Without session_summary.md

If the user says "close this session" without a file:

1. Ask: "Can you fill the session template? It's in `references/session_summary_template.md`"
2. If they give a freeform summary instead, extract the five required fields from their description
3. Proceed with whatever you can extract — flag missing fields

---

## Composability

**This skill calls:**
- `tremble-task-manager` — to close completed tasks + create new blocker tasks
- Notion MCP — to update `315b7419-2f1e-80a1-999e-fdeb5b425aea`

**This skill is triggered by:**
- End of any dev session (upload of session_summary.md)
- Manual "close session" request
