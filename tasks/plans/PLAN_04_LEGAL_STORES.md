# PLAN 04 — PRAVO, DOKUMENTI, TRGOVINI
**Faza 4 · Korak 4.1 se začne TAKOJ (vzporedno z vsem) · Ostalo po Fazi 3 · Ocenjen čas: raztegnjen — 2-4 tedne čakanja na Google + odvetnika**

Preberi PLAN_00_MASTER_INDEX.md pred tem dokumentom. Ta faza je skoraj
v celoti 🧑‍⚖️ FOUNDER — CLI tu ne more nadomestiti podpisov, oddaj in
pravnih mnenj. Ne prosi ga.

---

## KORAK 4.1 — 🧑‍⚖️ FOUNDER: Play Console deklaracije — PREVERI STATUS DANES

**To je časovno najbolj kritičen korak celotnega launcha.** Google
pregled background lokacije traja 2-4 tedne in ni odvisen od tvoje
hitrosti. Vsak dan, ko se ni začel, je dan zamude Android launcha.

Koda (Prominent Disclosure screen, branch feature/prominent-disclosure-
background-location, commit a3f793b) je bila po implementation plan
Korak 0 outputu narejena — ampak polji "Datum oddaje v Play Console" in
"Datum odobritve" sta PRAZNI, in odprta vprašanja iz tistega outputa
(screenshoti EN+SL, on-device potrditev prompt vedenja, brand-voice
pregled 4 novih stringov) niso zaprta.

**Kaj narediti:**
1. Preveri: je bil branch a3f793b sploh mergean v main in vključen v
   build 15 / novi AAB? (`git log main --oneline | grep -i disclosure`
   ali `git merge-base --is-ancestor a3f793b main`). Če NE → najprej
   merge po standardnem PR postopku.
2. Brand-voice pregled 4 novih stringov (blokira store submission po
   tvojem lastnem pravilu iz Korak 0 outputa) — preveri proti brand
   pravilom: kratke povedi, 2. oseba, brez klicajev, brez prepovedanih
   fraz, EN+SL.
3. Posnemi demo video: Radar aktiven → app v ozadje → notifikacija ob
   proximity (po PLAN_03 3.1 bo to sploh mogoče prikazati!).
4. Play Console → App content → Permissions declaration →
   ACCESS_BACKGROUND_LOCATION utemeljitev + video.
5. Play Console → App content → Foreground service permissions →
   deklariraj location, connectedDevice, dataSync.
6. Oddaj. Zabeleži datum. Nato ČAKAŠ — ne blokira ničesar drugega.

**Output:**
```text
Disclosure koda v main + buildu (da/ne, commit):
Brand-voice pregled stringov (da/ne):
Datum oddaje obeh deklaracij:
Datum odobritve:
```

## KORAK 4.2 — 🧑‍⚖️ FOUNDER: Prava pravna konzultacija (ne AI pass)

**Kontekst:** Implementation plan Korak 1 Output odkrito pravi: odvetnica
ni bila kontaktirana, opravljen je bil samo Gemini prehod. Gemini
interpretacija NI pravna podlaga — in tvoj lasten compliance report
(Del II) šteje razkorak med dokumenti in realnostjo kot oteževalno
okoliščino. Dokument "Navodila za pravno mnenje — Tremble, Člen 9 GDPR"
je pripravljen za pošiljanje.

**Kaj narediti:**
1. Pošlji pripravljen dokument + TREMBLE_MASTER_COMPLIANCE_REPORT Del II
   odvetnici, specializirani za GDPR/podatke (ne splošno gospodarsko pravo).
2. Vprašanji, ki NUJNO rabita pisen odgovor pred javnim launchom:
   (a) potrditev čl. 9(2)(a) podlage za gender+lookingFor s conditionality
   analizo (Gemini sklep je verjeten, a nepodpisan);
   (b) DPO obveznost ob javnem launchu (trenutna "začasno ni obvezen"
   odločitev je vezana na <50 uporabnikov TestFlight — ob launchu pade).
3. Kanabis/politika: odstranjena iz produkta — odvetnici samo v vednost,
   ne rabi mnenja.
4. Budget realnost: eno pisno mnenje na 2 vprašanji je nekaj sto EUR,
   ne tisoči. To ni "ko bo denar" postavka — je launch pogoj.

**Output:**
```text
Poslano odvetnici (datum, komu):
Pisno mnenje prejeto (datum, kje shranjeno):
DPO odločitev ob launchu:
```

## KORAK 4.3 — 🧑‍⚖️ FOUNDER + 🤖 CODE pomoč: Dokumenti (implementation plan Koraki 23-30)

Po Fazi 3 (koda stabilna) in 4.2 (pravno mnenje) — enkraten prepis,
da ne prepisuješ dvakrat. CLI lahko pripravi osnutke diff-ov dokumentov,
podpisuje in objavlja founder.

| Dokument | Kaj | Vir resnice |
|---|---|---|
| DPIA | §3.2/§4.2/§8: TTL 2h (ne 24h), getPublicProfile STRIP, politika odstranjena, gender/lookingFor consent mehanizem | dejanska koda + 4.2 mnenje |
| ToS | §7 Weekend okno ZDAJ drži (enforcement v main) — samo preveri besedilo ur; §16 SL verzija ali popravek klavzule; DSA Contact Points sekcija | koda + Korak 24 |
| Privacy Policy | §2.2 gender/lookingFor NI "voluntarily provided" — popravi na pogodbeno/consent formulacijo iz 4.2; §2.5 Contacts — **koda že usklajena 2026-07-13 (KORAK 3.8-1)**: master `Info.plist` `NSContactsUsageDescription` zdaj natančno opisuje Anonymity Mode + `PrivacyInfo.xcprivacy` deklarira Contacts (Linked=false per ADR-004 hash-only). Preostane samo posodobitev spletne §2.5 na `trembledating.com/privacy` da opiše Anonymity Mode + SHA-256 hash-only transmission (nič raw contact data leaves device); PostHog NI aktiven → ne dodajaj | 4.2 + koda |
| DPA | matična številka; re-sign Google/Cloudflare/Upstash/Resend pod AMS Solutions d.o.o. | AJPES izpis |
| ROPA | konsolidacija v en čl. 30 dokument | DPA/DPIA/PP |
| Breach postopek | upravljavec→IP 72h + register | Korak 28 |
| DSA čl. 16/18 | notice-and-action preverba report flowa + interni postopek | safety.functions.ts |

**Output:**
```text
DPIA v2 (datum):
ToS final + SL (datum):
PP final (datum):
DPA ×4 re-signed (datumi):
ROPA (datum):
Breach + DSA (datum):
```

## KORAK 4.4 — 🧑‍⚖️ FOUNDER: Apple Privacy Labels + Play Data Safety

Po 4.2 in 4.3 (končno stanje kategorij podatkov znano).

- Deklariraj VSE zbrane kategorije, vključno s spolno usmerjenostjo
  (izpeljana iz gender+lookingFor — Apple/Google jo štejeta kot zbrano).
- Neskladje med labels in dejanskim zbiranjem = zavrnitev + GDPR
  kršitev hkrati (dvojna škoda).
- App Store Connect → App Privacy; Play Console → Data safety.

**Output:**
```text
Apple labels (datum):
Play Data Safety (datum):
```

## KORAK 4.5 — 🌐 WEB: DSA Contact Points + SL ToS objava

Po 4.3. Next.js 16 site, Cloudflare Pages. CLI lahko izvede (website
repo je ločen — trembledating.com). EN+SL, brand pravila veljajo.

**Output:**
```text
/dsa-contact (ali sekcija) URL + datum:
SL ToS URL + datum:
```

---
**KONEC FAZE 4 — merila:** Play deklaracije ODOBRENE (ne samo oddane),
pisno pravno mnenje v roki, vsi dokumenti usklajeni s kodo in
objavljeni, store labels izpolnjeni.
