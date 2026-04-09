## Session State — 2026-04-09 09:24
- Active Task: Phase 7 Interaction System v2.1 — FULLY DEPLOYED ✅
- Environment: Dev (tremble-dev)
- Branch: main
- System Status: `flutter analyze` → No issues ✅ | `tsc` → No errors ✅ | Firebase deploy → 19 functions ✅

## Interaction System v2.1 — Zaključeno

### Kar je delujoče v tremble-dev zdaj:
| Trigger | Notifikacija | Status |
|---|---|---|
| BLE zaznava (onBleProximity) | "Nekdo je blizu. Boš pomahal-a?" (anonimno, 15-min cooldown) | ✅ Live |
| 1. val (onWaveCreated) | "[Ime] ti je pomahal-a. Pomahaš nazaj?" (Rich Push: ime + slika) | ✅ Live |
| Mutual wave | "[Ime] ti je pomahal-a nazaj! Odpremo radar?" + deep link /radar | ✅ Live |
| Background "Pomahaj nazaj" | Silent wave v Firestore brez odpiranja app | ✅ Flutter ready |
| Deep link cold-start | Notification tap → MatchRevealScreen | ✅ Flutter ready |

### Odprto — zahteva founder approval:
1. **iOS Notification Service Extension** — Xcode native target, zahteva spremembe v `ios/` mapi.
   - Risk: HIGH (native iOS config)
   - Potrebno za: prikaz sender slike v push notifikacijah na iOS-u
   - Brez tega: Android prikazuje slike ✅, iOS prikazuje samo tekst

2. **Node.js 20 → 22 upgrade** ⚠️ URGENT (deadline: 2026-04-30, 21 dni)
   - Firebase CLI je opozoril: Node.js 20 decommission 2026-10-30
   - Risk: LOW-MEDIUM (sprememba v `functions/package.json` + `.node-version`)
   - Brez tega: deploy bo blokiran po 2026-10-30

## Session Handoff
- **Completed:** Interaction System v2.1 — Flutter + Cloud Functions + Deploy
- **In Progress:** Nič
- **Blocked:** iOS Notification Service Extension (HIGH, Xcode) — čaka founder approval
- **Next Action (priporočeno):**
  1. Node.js 20 → 22 upgrade (URGENT, 21 dni do deprecation)
  2. iOS Notification Service Extension (po approvalov)
  3. Phase 8: Paywall / RevenueCat

Staleness rule: if this block is >48h old, re-validate before executing.
