# TREMBLE — MASTER LAUNCH PLAN (INDEX)
**Ustvarjeno: 11. julij 2026, ~23:00 · Stanje verificirano proti kodi in živim logom tega dne**
**Cilj: aplikacija živa v App Store (iOS-first), Android sledi po Play odobritvi**

---

## KAKO UPORABLJATI TE DOKUMENTE (preberi najprej, vsakič)

Teh 6 datotek je celoten operativni načrt do launcha. Vsaka prihodnja CLI seja
(Claude Code, Codex, ali šibkejši model) MORA prebrati:
1. To datoteko (PLAN_00) — vedno, v celoti.
2. Datoteko faze, na kateri dela — v celoti, preden se dotakne kode.

**Pravila za CLI instanco (nepogajalska):**
- Nikoli ne trdi "narejeno" brez dokaza: grep output, test rezultat, ali link.
  Trditev brez dokaza se šteje kot NEnarejeno.
- Nikoli push direktno na main. Vedno: feature branch → PR → merge.
- Nikoli deploy na `am---dating-app` (produkcija) brez founderjevega
  eksplicitnega "da, deploj v prod" v isti seji.
- Nikoli ne spreminjaj: AndroidManifest.xml, Info.plist, google-services.json,
  firebase.json brez founder odobritve. (Nove datoteke, npr. Localizable.strings,
  so dovoljene — spremembe obstoječih naštetih niso.)
- Vsak PR: naslov vsebuje `[PLAN-ID: YYYYMMDD-kratko-ime]`, ki se ujema s
  `tasks/plan.md` (en sam aktiven dokument — prepiši ga pred vsakim PR).
  Telo PR-ja vsebuje dobesedne fraze: `Verification checklist`, `unit tests`,
  `integration tests`, `security scan`.
- Če je PR visoko tvegan (billing, auth, PII/GDPR polja, infra, workflows),
  telo mora vsebovati dobesedno `risk_level: high` (podčrtaj, ne presledek!)
  da CI sproži Founder Approval gate.
- V PR telesu NE uporabljaj backtick code spans, dokler PLAN_01 korak 1.1
  ni potrjeno mergean (star ci.yml izvaja vsebino PR telesa kot bash — resnična,
  dokazana ranljivost).
- Testni ukazi: `flutter analyze` (0 issues), `flutter test` (vsi zeleno),
  `cd functions && npm run build && npm run lint && npm test`.
- Arhitekturne konstante: `effectiveIsPremiumProvider` (nikoli raw isPremium),
  GPS nikoli v Firestore (samo geohash), barve samo prek TrembleTheme tokenov,
  TTL polja: proximity_events/run_encounters → `expiresAt`,
  rateLimits/gdprRequests → `ttl`.

**Pravila za founderja (Aleksandar):**
- Vsak korak ima oznako 🤖 CODE (CLI izvede) ali 🧑‍⚖️ FOUNDER (samo ti /
  Martin). Ne prosi CLI, naj izvede FOUNDER korake — ne more, in če trdi
  da jih je, laže.
- Output polja izpolnjuj sproti. Prazno Output polje = korak ni narejen,
  ne glede na to, kaj kdo trdi.
- HIGH RISK diff-e (billing, auth, GDPR, workflows) pred Martinovim approvalom
  prilepi v Claude chat za tehnični pregled, če je dostop do močnega modela
  še na voljo. Če ni: preberi diff sam, vrstico po vrstico, in preveri da
  spreminja SAMO datoteke, ki jih naloga omenja.

## VRSTNI RED FAZ (odvisnosti so resnične, ne birokracija)

| Faza | Datoteka | Zakaj ta vrstni red |
|---|---|---|
| 1 | PLAN_01_GIT_CI_SECURITY.md | CI injection fix blokira zaupanje v VSE ostale CI rezultate. Org/private repo ščiti vse nadaljnje delo. |
| 2 | PLAN_02_INFRA_OPS.md | stopBilling crashira v produkciji ZDAJ. Build verifikacija je pogoj za vsak smiseln test. |
| 3 | PLAN_03_APP_CODE.md | CROSSING_PATHS = jedrna mehanika, trenutno nevidna. Ostali app fixi. |
| 4 | PLAN_04_LEGAL_STORES.md | Pravna podlaga + store deklaracije. Play Korak 0 traja 2-4 TEDNE — začni čim prej, teče vzporedno. |
| 5 | PLAN_05_LAUNCH.md | Finalni build, BLE matrix test, submission. Zadnja faza, ničesar ne preskakuj. |

Faza 4 (Play deklaracija) se začne TAKOJ vzporedno s Fazo 1 — ne čaka.
Vse ostalo je zaporedno, razen kjer je izrecno označeno "vzporedno".

## TRENUTNO STANJE (11. jul 2026, zvečer — verificirano, ne po spominu)

**Deluje in dokazano:**
- Backend proximity pipeline: prvi realen proximity_events zapis 11. jul
  (fromUid/toUid/geohash/expiresAt vsi pravilni)
- Kanabis + politična pripadnost: odstranjena iz kode (grep = 0 zadetkov v main)
- getPublicProfile: ne vrača Art. 9 polj (STRIP izveden, regression testi)
- Weekend Getaway enforcement: v main, 10/10 testov
- flutter_native_splash: popravljen
- iOS PrivacyInfo.xcprivacy + ITSAppUsesNonExemptEncryption: v repu
- Branch protection na main: ustvarjena (Martin, 11. jul)
- 221/221 Flutter testov, 77/77 CF testov na main

**Pokvarjeno / odprto (podrobnosti v fazi datotekah):**
- ci.yml: shell injection prek PR title/body — fix na branchu
  `security/fix-ci-pr-body-injection` (commit 6923a42), PR ŠE NI ODPRT
- stop-billing-10eur CF: crashira na VSAKEM budget sporočilu v produkciji
  — nadomestek na branchu `feat/stop-billing-cf` (PR #13), čaka na security fix
- CROSSING_PATHS notifikacija: arhitekturno nevidna na OBEH platformah
  (Android data-only brez notification bloka; iOS loc-key brez Localizable.strings)
- prefer_not_to_say: prikazuje surov ključ (manjka v translations.dart)
- Testni napravi verjetno poganjata STARE builde (updateProfile 400 na obeh)
- R2 fotografije + Redis ključi 4 izbrisanih računov: niso počiščeni
- Repo je JAVEN — org + private migracija načrtovana
- Play Console background location deklaracija: STATUS NEZNAN — preveri!
- Prava pravna konzultacija: NI izvedena (samo Gemini pass)

**Todoist (projekt 6fxxh6MXfmh2q3FP) — živi taski s polnimi prompti:**
- 6h4rx2R9CC3WvxGw — stopBilling (Infra, p1)
- 6h4xVHjRqhp56VQP — CI injection (Infra, p1)
- 6h4rx2JH52hFHxQw — CROSSING_PATHS (App, p1)
- 6h4rx2M8RfPF9QmP — build verifikacija (Blockers, p1)
- 6h4rx2WHvf5728Xw — R2/Redis cleanup (Infra, p2)
- 6h4rx2VJmmW7XjHP — prefer_not_to_say (App, p3)
- 6h4rqCpQ3jjg9vjw — flaky GymStep test (App, p3)
- 6h4mGfW5FjMhvGmw — founder-approval environment (Infra, p1)

## POVEZANI DOKUMENTI
- `TREMBLE_MASTER_COMPLIANCE_REPORT_06JUL2026.md` — izvorni compliance audit
- `tasks/TREMBLE_IMPLEMENTATION_PLAN.md` — Koraki 0-50 z Output polji
  (ta plan set NE nadomešča implementation plana — ga operacionalizira;
  ob konfliktu velja novejši datum in dejanska koda)
- `tasks/plan.md` — en sam aktiven Plan-ID dokument za CI gate
