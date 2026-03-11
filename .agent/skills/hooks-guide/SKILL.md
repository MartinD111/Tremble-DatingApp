---
name: hooks-guide
description: Tremble-specific guide: how to verify ECC hooks are active, what each hook does, and how agents interact with hooks.
origin: Tremble
---

# Hooks — Verification & Agent Guide

## Kaj so hooks

Hooks so Node.js skripti, ki se **avtomatično izvajajo** ob določenih Claude Code dejanjih — brez da moraš karkoli pisati v prompt. Nastavljeni so v `hooks/hooks.json` in se zaženejo ko Claude Code:

- začne session (`SessionStart`)
- uredi datoteko (`PostToolUse → Edit`)
- izvede bash ukaz (`PostToolUse → Bash`)
- konča odgovor (`Stop`)
- zaključi session (`SessionEnd`)

---

## Kako veš da so hooks aktivirani?

### Metoda 1: Preveri hooks.json je nastavljen

V Claude Code terminalu:

```bash
# Pokaže aktivno konfiguracijo Claude Code
cat ~/.claude/settings.json | grep -A5 hooks

# ALI: pokaži project-level hooks (v repo)
cat .claude/settings.json | python3 -m json.tool | grep -A3 "hooks"
```

### Metoda 2: SessionStart izpis

Ko odpreš novo Claude Code session, `session-start.js` hook **izpiše v terminal**:

```
[SessionStart] Found 2 recent session(s)
[SessionStart] Latest: /Users/aleksander/.claude/sessions/tremble-2025-03-11.tmp
[SessionStart] Package manager: npm
[SessionStart] Project type: typescript
```

Če vidiš ta izpis → `SessionStart` hook dela.

### Metoda 3: Typecheck izpis po editu

Ko Claude Code uredi `.ts` datoteko in je TypeScript napaka:

```
[Hook] TypeScript errors in appCheck.ts:
  src/middleware/appCheck.ts(12,5): error TS2345: ...
```

Ta izpis pomeni `post-edit-typecheck.js` hook je aktiven.

### Metoda 4: console.log warning

Ko Claude Code uredi `.ts` datoteko ki vsebuje `console.log`:

```
[Hook] console.log found in modified files:
  functions/src/index.ts:45 - console.log('debug')
```

### Metoda 5: Cost tracker pri Stop

Na koncu vsakega Claude Code odgovora:

```
[CostTracker] Session: tremble-dev | Tokens: 12,450 | Est. cost: $0.03
```

---

## Kje so hooks nastavljeni

ECC hooks so nastavljeni na **dveh nivojih**:

### 1. Global level (`~/.claude/settings.json`)
Velja za vse projekte. Nastavi enkrat:

```bash
# Preveri globalne nastavitve
cat ~/.claude/settings.json
```

### 2. Project level (`.claude/settings.json` v repo)
Velja samo za Tremble repo. Ima prednost pred globalnimi.

```bash
# V Tremble-DatingApp-main/
cat .claude/settings.json
```

**Za Tremble**: ECC hooks bi morali biti v project-level `.claude/settings.json` — tako veljajo samo ko delaš v tem projektu.

---

## Tabela aktivnih hooks za Tremble

| Hook | Trigger | Kaj dela | Mora biti aktiven |
|------|---------|----------|-------------------|
| `session-start.js` | SessionStart | Naloži prejšnji context, detektira package manager | ✅ Da |
| `post-edit-typecheck.js` | PostToolUse → Edit `.ts` | TypeScript check za urejeno datoteko | ✅ Da |
| `post-edit-console-warn.js` | PostToolUse → Edit | Opozori na `console.log` | ✅ Da |
| `post-edit-flutter-analyze.js` | PostToolUse → Edit `.dart` | Flutter analyze za urejeno datoteko | ✅ Da (dodaj ročno) |
| `quality-gate.js` | PostToolUse → Edit/Write | Lint + build check | 🟡 Opcijsko |
| `cost-tracker.js` | Stop | Zapiše token/cost metrics | ✅ Da |
| `session-end.js` | Stop | Shrani session state | ✅ Da |
| `pre-compact.js` | PreCompact | Shrani stanje pred compaction | ✅ Da |
| `check-console-log.js` | Stop | Preveri vse modificirane fajle za console.log | ✅ Da |
| `auto-tmux-dev.js` | PreToolUse → Bash | Auto-start dev serverje v tmux | 🟡 Opcijsko |

### Hooks ki jih NE rabiš za Tremble
- `go-*` hooks — Go stack
- `python-*` hooks — Python stack
- `post-bash-pr-created.js` — auto-detektira GitHub PR URL (neobvezno)

---

## Ali agenti lahko uporabljajo hooks?

**Kratki odgovor: Ne direktno — ampak hooks vplivajo na agente.**

### Kako to deluje

```
Ti → Claude Code prompt
  → Claude Code (Implementer agent)
      → Edit file: functions/src/middleware/appCheck.ts
          ↓ PostToolUse hook se avtomatično sproži
          ↓ post-edit-typecheck.js preveri TypeScript
          ↓ Če napaka → console.error izpis v terminal
      → Claude Code vidi hook output
      → Claude Code popravi napako sam
```

**Torej**: Hooks se sprožijo **pri vsakem tool use** — ne glede na to ali to naredi direktno Claude Code ali sub-agent (Implementer, Architect, ...). Claude Code vidi hook output in reagira nanj.

### Primer: Agent + hook interakcija

```
[Architect agent] planira strukturo
[Implementer agent] ureja appCheck.ts
  → post-edit-typecheck.js se sproži
  → najde TS napako
  → Claude Code vidi: "[Hook] TypeScript errors in appCheck.ts: ..."
  → Implementer agent popravi napako brez da ga moraš prositi
```

### Kaj agenti ne morejo

- Agenti **ne morejo klicati hooks direktno** z `/checkpoint` ali podobnim
- Agenti **ne vidijo hooks.json** razen če jih eksplicitno prosiš da ga preberejo
- `session-start.js` se sproži **samo ob novem sessioni** — ne ob spawnu sub-agenta

---

## Dodaj flutter-analyze hook (manual step)

Ta hook moraš dodati ročno v `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "node \"${CLAUDE_PLUGIN_ROOT}/scripts/hooks/post-edit-flutter-analyze.js\""
          }
        ],
        "description": "Flutter analyze after editing .dart files"
      }
    ]
  }
}
```

Zamenjaj `${CLAUDE_PLUGIN_ROOT}` z absolutno potjo do ECC mape v tvojem repotu:

```json
"command": "node \"/Users/aleksander/dev/Tremble-DatingApp-main/.agents/scripts/hooks/post-edit-flutter-analyze.js\""
```

---

## Hitro preverjanje (copy-paste v terminal)

```bash
# 1. Ali ima projekt settings?
ls -la .claude/settings.json

# 2. Koliko hooks je nastavljenih?
cat .claude/settings.json | python3 -c "import json,sys; d=json.load(sys.stdin); hooks=d.get('hooks',{}); total=sum(len(v) for v in hooks.values()); print(f'Hooks: {total} across {list(hooks.keys())}')"

# 3. Ali session-start skripta obstaja?
ls ~/.claude/plugins/everything-claude-code/scripts/hooks/session-start.js

# 4. Test cost-tracker ročno
echo '{"session_id":"test"}' | node ~/.claude/plugins/everything-claude-code/scripts/hooks/cost-tracker.js
```
