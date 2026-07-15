# PLAN 01 — GIT, CI VARNOST, ORGANIZACIJA
**Faza 1 · Blokira vse ostale faze · Ocenjen čas: 1-2 dni (večina je čakanje na Martina)**

Preberi PLAN_00_MASTER_INDEX.md pred tem dokumentom.

---

## ZAKAJ TA FAZA PRVA
11. jul je bilo dokazano (živ CI log, PR #13): star `ci.yml` izvaja vsebino
PR naslova/telesa kot bash. CI je dejansko poskusil pognati `gcloud functions
delete` ukaz iz PR opisa — ustavljen samo, ker runner ni imel gcloud auth.
Dokler to ni popravljeno, se NOBENEMU CI rezultatu ne sme zaupati in noben
PR se ne sme mergati. Vse ostale faze so odvisne od delujočega, varnega CI.

---

## KORAK 1.1 ✅ — 🧑‍⚖️ FOUNDER: Odpri in mergaj security fix PR

**Stanje:** Koda je narejena in pushana. Branch `security/fix-ci-pr-body-injection`,
commit `6923a42`. Fix: 4 stepi v job-u ① (Check Plan-ID, Check verification
checklist, Check ADR reference, Evaluate risk level) prestavljeni iz inline
`${{ steps.pr_meta.outputs.* }}` interpolacije v `env:` bloke. Verificirano
lokalno: flutter analyze 0 issues, 221/221, backend 77/77.

**Kaj narediti:**
1. `git checkout security/fix-ci-pr-body-injection`
2. Prepiši `tasks/plan.md`:
   ```
   Plan ID: 20260711-fix-ci-pr-body-injection
   Risk Level: HIGH
   ```
   Commit + push.
3. Odpri PR na https://github.com/MartinD111/Tremble-DatingApp/pull/new/security/fix-ci-pr-body-injection
   - Naslov: `[PLAN-ID: 20260711-fix-ci-pr-body-injection] fix(ci): prevent shell injection via PR title/body in mpc-validate-pr`
   - Telo: BREZ backtickov (ta PR še teče na starem, ranljivem ci.yml —
     GitHub za pull_request evente uporabi workflow z BASE brancha).
     Telo mora vsebovati: "Verification checklist", "unit tests",
     "integration tests", "security scan", in "risk_level: high".
4. Martin: review + approve (diff je 1 datoteka, +10/-5 — 5 minut).
5. Merge.

**Dokaz o zaključku:** PR mergean, `git log main` vsebuje commit s
"prevent shell injection".

**Output:**
```text
PR številka:
Datum merge:
```

## KORAK 1.2 ✅ — 🧑‍⚖️ FOUNDER (Martin): Environment + branch protection nastavitev

**Kaj narediti (Martin, ~3 minute, natančno tako):**
1. Repo → Settings → Environments → New environment → ime TOČNO:
   `founder-approval`
2. Required reviewers → dodaj SAMO Martina (ne Aleksandarja — sicer
   Aleksandar lahko sam sebi odobri HIGH RISK PR).
3. Save protection rules.
4. Settings → Branches → main → Edit:
   - ODSTRANI "Require a pull request before merging / Require approvals"
     (če je vklopljeno) — approvals na vsak PR ustvarjajo friction;
     tveganje krije Founder Approval gate samo za HIGH RISK.
   - OBDRŽI/VKLOPI "Require status checks to pass before merging" in
     označi vse CI jobe kot required.

**POZOR — znana omejitev:** Environment required reviewers na PRIVATNIH
repojih deluje samo na GitHub Enterprise planu (ne Free/Pro/Team). Dokler
je repo javen, deluje. Ko se repo migrira na org + private (Korak 1.4),
ta mehanizem NEHA delovati — nadomesti ga CODEOWNERS (Korak 1.5).

**Output:**
```text
Environment ustvarjen (datum):
Required reviewer:
Branch protection posodobljena (da/ne):
```

## KORAK 1.3 ✅ — 🧑‍⚖️ FOUNDER: Rebase in merge PR #13 (stopBilling)

**Šele PO 1.1 in 1.2.**

1. ```
   git checkout feat/stop-billing-cf
   git fetch origin
   git rebase origin/main
   git push --force-with-lease
   ```
2. Popravi PR #13 telo: dodaj vrstico z dobesedno `risk_level: high`
   (regex v ci.yml zahteva podčrtaj; "Risk Level: HIGH" s presledkom
   se NE ujema).
3. CI teče na popravljenem ci.yml → tokrat varno prebere telo, zazna
   high risk → job ⑦ Founder Approval se aktivira → Martin approve v
   GitHub UI (obvestilo dobi, ali: Actions → čakajoči run → Review
   deployments → founder-approval → Approve).
4. Merge.

**NE deployaj še — deploy je PLAN_02 korak 2.1.**

**Output:**
```text
Datum merge PR #13:
Founder Approval gate se je sprožil (da/ne):
```

## KORAK 1.4 — 🧑‍⚖️ FOUNDER (oba): AMS Solutions organizacija + privaten repo

**Zakaj:** repo je trenutno JAVEN — celotna arhitektura, GDPR migracije,
project ID-ji in git zgodovina vidni komurkoli. Namerno začasno (čakanje
na org), ampak vsak dan javnosti je dan tveganja.

**Odločitev (sprejeta 11. jul):** NE tretji "company login" profil za
approvanje PR-jev — deljen login krši GitHub ToS in izniči review (approve
brez identitete = ni approve). Org je LASTNIK repoja in billing entiteta;
osebna računa ostaneta login identiteti.

**Martin (ali Aleksandar, oba sta lahko):**
1. GitHub → profilna slika → Your organizations → New organization
2. Plan pri kreaciji: Free. Ime: `ams-solutions` (ali podobno). Email:
   poslovni AMS email. Billing podatki + poslovna kartica se dodajo v
   org Settings → Billing.
3. Org → Settings → People → Invite → drugi co-founder → vloga: Owner.
4. Org → Settings → Billing and plans → Change plan → **GitHub Team**
   (POZOR: "Pro" za organizacije NE obstaja — Pro je samo za osebne
   račune. Team = $4/uporabnik/mesec, za vaju ~$8/mesec.)
5. Repo transfer: Tremble-DatingApp → Settings → General → Danger Zone →
   Transfer ownership → v org.
6. Repo → Settings → General → Danger Zone → Change visibility → Private.
7. Po transferju PONOVNO preveri: branch protection pravila, GitHub
   Secrets (FIREBASE_OPTIONS_*_BASE64, MAPS_API_KEY — transfer jih
   lahko izgubi!), Actions permissions, lokalni remote:
   `git remote set-url origin git@github.com:ams-solutions/Tremble-DatingApp.git`

**Output:**
```text
Org ime:
Team plan aktiven (datum):
Repo transferiran + private (datum):
Secrets preverjeni po transferju (da/ne):
```

## KORAK 1.5 — 🤖 CODE: CODEOWNERS nadomesti Environment gate (po 1.4)

**Zakaj:** na privatnem repoju (tudi Team plan) environment required
reviewers ne delujejo. CODEOWNERS + branch protection "Require review
from Code Owners" pa deluje na Team planu in je celo natančnejši —
zahteva review SAMO ko PR spreminja občutljive poti.

**CLI prompt:**
```
In the Tremble project (now under the ams-solutions org), create a
CODEOWNERS file and adjust CI:

1. Create .github/CODEOWNERS with content (adjust usernames to actual):
   /functions/                  @unfab
   /.github/                    @unfab
   /firestore.rules             @unfab
   /android/app/src/main/AndroidManifest.xml  @unfab
   /ios/Runner/Info.plist       @unfab
   (Rationale: Martin authors little code; Aleksandar authors most, so
   the code owner for sensitive paths should be the person who did NOT
   author the PR in most cases. Discuss with founder: if Aleksandar
   authors 99% of PRs, set @MartinD111 as owner instead so review is
   meaningful. DO NOT decide this yourself — ask.)
2. In ci.yml, leave the ⑦ Founder Approval job in place but add a
   comment noting it is inert on private repos below Enterprise; the
   enforcement now lives in branch protection "Require review from
   Code Owners".
3. Founder then enables: Settings → Branches → main → Edit →
   Require a pull request before merging → Require review from Code
   Owners (approvals: 1) — this only bites when owned paths change.

Requirements: PR with Plan-ID, required body phrases, no backticks
until 1.1 confirmed merged. flutter analyze/test + functions build/lint/
test all green (no code change expected to affect them, but run anyway).
```

**Output:**
```text
CODEOWNERS vsebina potrjena s founderjem (kdo je owner):
PR mergean (datum):
Branch protection "Require review from Code Owners" vklopljen (da/ne):
```

## KORAK 1.6 — 🤖 CODE: Preiskava — kaj pristaja na main s 3/8 checki

**Kontekst:** main HEAD je 11. jul kazal 3/8 checkov. Znan star vzorec:
avtomatski "chore: coverage" commiti direktno na main s padlim CI (4
zaporedni, vir neidentificiran). Branch protection zdaj obstaja, ampak
ali dejansko blokira ta vir?

**CLI prompt:**
```
In MartinD111/Tremble-DatingApp (or ams-solutions/... after transfer),
diagnose — do not fix:
1. git log --format="%H %an %ae %s %ci" -10 main — identify any commits
   that did not arrive via PR merge (no "Merge pull request" ancestry).
2. For each direct-push commit: which author/email? Is it a bot/hook?
   Check .git/hooks, CI workflows with push triggers, and any local
   tooling (e.g. coverage upload scripts) that might auto-commit.
3. Report findings; recommend removal/redirect of the auto-commit
   source. Evidence: commit hashes + author emails + the code/config
   that generates them.
```

**Output:**
```text
Vir avtomatskih commitov:
Blokiran z branch protection (da/ne):
Priporočilo izvedeno (da/ne):
```

---
**KONEC FAZE 1 — merila:** ci.yml varen (test PR z benignim backtickom
se NE izvede), PR #13 mergean, org + private repo, CODEOWNERS aktiven,
main brez direct-push virov.
