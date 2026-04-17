# TREMBLE — MASTER IMPLEMENTATION PLAN v1.0
## Za: Gemini Agent (Antigravity)
## Datum: 18. april 2026
## Avtor: Claude (na podlagi analize celotnega repozitorija)

---

> **NAVODILO ZA AGENTA:** Ta dokument je popolna tehnična analiza trenutnega stanja aplikacije Tremble in seznam vseh nalog, ki jih je treba izvesti. Iz tega dokumenta sestavi: Roadmap, Debt Register, Task List, Phase Plans in Blockers. Vsaka naloga ima točno določene datoteke, root cause analize in acceptance criteria. Sledi struturam obstoječih `.planning/` in `tasks/` direktorijev.

---

## SEKCIJA 1 — TRENUTNO STANJE (april 2026)

### Stack
- Flutter 3 + Riverpod 2 + GoRouter
- Firebase: Auth, Firestore, Cloud Functions (europe-west1)
- Storage: Cloudflare R2 (media.trembledating.com)
- Upstash Redis (rate limiting), Resend (email), RevenueCat (pending)
- Environments: `tremble-dev` (dev) | `am---dating-app` (prod) — STROGA LOČITEV

### Faze dokončane (1–7 + parcialno 8–10)
| Faza | Opis | Status |
|------|------|--------|
| 1 | Foundation — arhitektura, tema, nav | ✅ |
| 2 | Core UX — profili, registracija, monolith razbit | ✅ |
| 3 | BLE Engine — flutter_blue_plus implementiran | ✅ |
| 4 | Infrastructure — Firebase, R2, Upstash, Resend | ✅ |
| 5 | Auth & Routing — login, onboarding, permission gate | ✅ |
| 6 | Brand Alignment — theme tokeni, tipografija | ✅ |
| 7 | Wave Mechanic + Push Notifications | ✅ |
| 8 | RevenueCat / Paywall | ❌ NOT STARTED |
| 9 | Security Hardening (App Check) | 🟡 PARTIAL (SEC-001) |
| 10 | Store Launch | ❌ NOT STARTED |

### Kritična arhitekturna opomba — DVA MATCH SISTEMA
Aplikacija ima dve ločeni match logiki ki se MORATA razlikovati:

**Sistem A — Matches Screen (MatchProfile / matchesStreamProvider)**
- Prikazuje profile od ljudi, s katerimi si naredil mutual wave (pretekli matchi)
- `matchesStreamProvider` → `watchMatches()` → `getMatches` CF → Firestore `matches` collection
- Prikaže `MatchDialog` ko BLE zazna enega od teh matchev v bližini
- "Greet" gumb = STARI SISTEM (sendGreeting CF — IZBRISAN) → zdaj mora biti `WaveRepository.sendWave()`

**Sistem B — Active Radar (Match / activeMatchesStreamProvider)**
- Prikazuje trenutni aktiven 30-min search session po mutual wave
- `activeMatchesStreamProvider` → Firestore `matches` collection (real-time)
- `currentSearchProvider` → filtrira po `status == 'pending'` + < 30 min
- Prikaže `RadarSearchOverlay` v HomeScreen ko je aktiven match

---

## SEKCIJA 2 — KRITIČNI BAGI (P0 — fix takoj, blokirajo vse ostalo)

---

### BUG-001 — "TREMBLE API NOT FOUND" pri wave akciji ✅ RESOLVED (2026-04-18)
*Rešeno: MatchController zdaj uporablja WaveRepository.sendWave().*

### BUG-002 — Profil, hobbies in slike se ne shranjujejo ✅ RESOLVED (2026-04-18)
*Rešeno: updateProfileSchema posodobljen z 21 manjkajočimi polji.*

### BUG-003 — Phase 2D uncommitted files ✅ RESOLVED
*Rešeno: Vsi koraki registracije so zdaj v samostojnih datotekah in commitani.*

### BUG-004 — Match dokument brez `expiresAt` serverskega polja ✅ RESOLVED
*Rešeno: onWaveCreated CF zdaj nastavi expiresAt in status: 'pending'.*

---

## SEKCIJA 3 — OBSTOJEČI DOLG (D-serija)

### D-25 — 40+ hardcoded Slovenian strings 🔴 PENDING
Hardcoded Slovenian strings ki zaobidejo `translations.dart` i18n sistem.

### D-26 — UGC Action Sheet barva ✅ RESOLVED
Popravljeno na `TrembleTheme.textColor`.

### D-27 — Forgot Password neskončen spinner 🔴 PENDING
Bug, kjer se nalaganje ne ustavi po poslanem e-poštnem sporočilu.

---

## SEKCIJA 4 — NOVE NALOGE (Faze B, C, D)

### TASK-001 — Copy & Translations Cleanup 🔴 P1
- Popravi "No matches" state v `matches_screen.dart`.
- Uredi "Ljudje" label (brez narekovajev, "Tvoji ljudje").
- Posodobi opis People strani: "Prikazani so vsi, s katerimi si se križal...".
- Sistematičen scan za hardcoded stringi.

### TASK-002 — Pills Transparency Fix 🔴 P1
- Popravi opacity za `OptionPill` in `FilterChip`.
- Radar animacija ne sme biti vidna skozi pill.
- Ozadje: `Color(0xFF2A2A28)`, Border: `rose.withValues(alpha: 0.3)`.

### TASK-003 — Match Card UI Redesign 🔴 P1
- GlassCard z `Color(0xFF1A1A18)` ozadjem.
- Ime + starost v `Playfair Display 900`.
- CTA "Pomahaj" mora biti viden in brand-aligned.
- Jasen "Cancel" gumb z borderjem.

### TASK-004 — Profile Card Hobbies + Political Slider 🔴 P2
- Redesign hobbies sekcije (Wrap + Chips).
- Read-only political orientation slider.
- Dodaj Edit button na lasten profil.

### TASK-005 — Tremble Logo v Centru Radarja 🔴 P1
- Dodaj `TrembleLogo` v center radarja.
- Logo mora pulzirati med skeniranjem.

### TASK-006 — 30-Minutni Timer UI + Cancel gumb 🔴 P0
- Timer v `RadarSearchOverlay` mora biti prominenten.
- Dodaj viden "Prekini iskanje" gumb pod timerjem.
- Ko < 5 min: timer se obarva rose.

### TASK-007 — Match Flow UX (Notification Logic) 🔴 P1
- Prepreči dvojne notifikacije za isti par.
- Akcijski gumbi v bannerju (Pomahaj nazaj / Ignoriraj).

### TASK-008 — Map Page 3-State Toggle 🔴 P2
- State 0: City level count.
- State 1: Zoom user + nearby count (1km).
- State 2: Zoom country + national count.

### TASK-010 — Profile Status Tracking (New) ✅ RESOLVED
- Router redirection na podlagi `profileStatusProvider` (ready, loading, notFound).

---

## SEKCIJA 5 — INFRASTRUKTURA & VARNOST

### SEC-001 — Firebase App Check 🔴 OPEN BLOCKER
- Enforce `enforceAppCheck: true` na vseh funkcijah.
- Zahteva ročno nastavitev Debug ključev za emulatorje.

---

*Dokument pripravljen: Antigravity AI (Technical Co-Founder)*
*Status: Arhivirano kot master referenca za Milestone v1.2*
