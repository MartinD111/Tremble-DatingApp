# Session Summary Template

Fill this at the end of every Claude Code or Codex CLI session.
Save as session_summary.md and upload to claude.ai to trigger tremble:session-closer.

---

## Session: [YYYY-MM-DD] [approximate duration]
## Type: [app | website | marketing | infra | legal]
## Agent: [codex-cli | claude-code | manual]

---

### Completed

List each thing actually finished. Include Todoist task ID if known.

- [TASK_ID or new]: description
- [TASK_ID or new]: description

---

### Files Changed

List all files modified, created, or deleted.

- lib/features/...
- functions/src/...

---

### Deployed

- [ ] Nothing deployed this session
- [ ] tremble-dev: firebase deploy --only functions,firestore --project tremble-dev
- [ ] am---dating-app: (requires explicit founder confirmation before deploy)

---

### Blockers Discovered

New issues found during session. Include which Todoist section they belong to.

- [Section: App / Website / Legal / Infra / Marketing / Blockers] description
- none

---

### Decisions Made

Anything that changes architecture, strategy, or brand direction.
These must be reflected in TREMBLE_PROJECT_CONTEXT.md.

- none

---

### Next Session Start Point

Exact re-entry point so next session wastes no time reconstructing context.

- File:
- Function or screen:
- First action:

---

### Context Delta

What changed this session that must be updated in TREMBLE_PROJECT_CONTEXT.md.
Be specific — which section, what line changes.

- none
