# TREMBLE — IMPLEMENTATION PLAN & EXECUTION LOG
**Ustvarjeno: 6. julij 2026 · Spremljevalni dokument k `TREMBLE_MASTER_COMPLIANCE_REPORT_06JUL2026.md`**

---

## Kako uporabljati ta dokument

To ni samo plan — je obrazec. Vsak korak ima polje **Output**, ki ostane prazno, dokler ga ne izpolniš (ročno izveden korak) ali dokler ga ne izpolni Claude Code/Codex (avtomatiziran korak). Ne preskakuj korakov in ne izvajaj jih izven vrstnega reda — vrstni red ni naključen, vsak naslednji korak je odvisen od odgovora ali izida prejšnjega. Če korak preskočiš in ga izvede prihodnji Claude Code brez konteksta iz prejšnjega koraka, se delo podvoji.

**Postopek s Claude Code:** naloži ta dokument + `TREMBLE_MASTER_COMPLIANCE_REPORT_06JUL2026.md` v projekt. Ukaži: *"Do step 1, report back into this file and here in chat."* Ko konča, preveri Output polje, nato reci: *"Proceed to step 2."* Ne dovoli, da preskoči naprej sam.

**Ko je cel dokument izpolnjen:** vrni ga meni skupaj z novim ZIP-om posneto stanje kode. Analiziram izpolnjen plan proti dejanski kodi in povem, ali je Tremble pripravljen za launch ali ne.

**Oznake kategorij:**
- 📄 **DOC** — pravni dokument / dokumentacija
- 🧑‍⚖️ **FOUNDER** — odločitev ali ročno dejanje, ki ga AI ne more izvesti namesto tebe
- 🤖 **CODE** — Claude Code / Codex prompt, izvedljivo avtonomno
- 🌐 **WEB** — sprememba na trembledating.com

**Vzporedna proga:** Korak 0 se začne TAKOJ in teče v ozadju — ne čaka na noben drug korak in ga noben drug korak ne čaka, razen finalnega submita.

---

## KORAK 0 — 🧑‍⚖️ FOUNDER (vzporedno, začni danes)
### Naslov: Google Play — sprožitev deklaracij za background location + foreground service

**Kaj rešujemo:** Google Play zahteva poseben pregledni postopek za `ACCESS_BACKGROUND_LOCATION` in za foreground service tipe (`location|connectedDevice|dataSync`). Pregled traja 2–4 tedne. Če to začneš teden pred nameravanim launchom, se launch zamakne za mesec. Ta korak je edini v celotnem planu, ki ni odvisen od nobene odločitve spodaj — dovoljenja so že v kodi, samo deklariraj jih.

**Kaj moraš narediti:**
1. Play Console → App content → Permissions declaration → izpolni utemeljitev za `ACCESS_BACKGROUND_LOCATION`.
2. Posnemi demo video Radarja, ki teče v ozadju.
3. Ustvari in objavi Prominent Disclosure zaslon v aplikaciji (ločen od Privacy Policy, prikazan PRED sistemskim permission promptom).
4. Play Console → App content → Foreground service permissions → deklariraj vse tri tipe (location, connectedDevice, dataSync) z utemeljitvijo.
5. Oddaj in počakaj na odobritev.

**Pričakovan rezultat:** Obe deklaraciji odobreni v Play Console pred nameravanim Android launch datumom.

**Todoist:** `6h3p8gWG7WHWV7JP`, `6h3p8gc78572RF9P`

**Output (izpolni ti):**
```text
Status:Final summary

Branch: feature/prominent-disclosure-background-location
Commit: a3f793b
PR-create URL (open in browser): [https://github.com/MartinD111/Tremble-DatingApp/pull/new/feature/prominent-disclosure-background-location](https://github.com/MartinD111/Tremble-DatingApp/pull/new/feature/prominent-disclosure-background-location)

Verification (evidence, not assertions)

- flutter analyze — 0 issues
- flutter test — 209/209 pass (17 new)
- flutter build apk --debug --flavor dev --dart-define-from-file=.env.json --dart-define=FLAVOR=dev — built successfully
- Pre-commit hook ran format + analyze + functions Jest (63/63) + full Flutter suite — all green

What changed

- New lib/src/features/auth/presentation/prominent_disclosure_screen.dart — standalone Play-compliant disclosure screen, EN/SL copy from spec verbatim.
- lib/src/core/consent_service.dart — split requestLocation() into requestLocationWhenInUse() + requestLocationAlways(). Compound method removed so no future refactor can silently re-fuse the steps.
- lib/src/features/auth/presentation/permission_gate_screen.dart _onAccept() — foreground grant → push disclosure → if primary CTA tapped, request locationAlways. "Not now" completes onboarding with foreground-only location. grantConsent() runs in both branches.
- lib/src/core/translations.dart — 4 new keys in EN and SL blocks.
- 3 new test files pinning: disclosure copy (EN + SL), CTA return contract, no permission_handler leakage in the widget, ordering in _onAccept, and the ConsentService split contract.

Framing per your grep condition

Grep confirmed: only consent_service.dart:70 ever called Permission.locationAlways.request(), inside if (Platform.isIOS). Android never asked users for background location at runtime before this PR — the manifest permission was silently dormant. So on iOS it's a refactor; on Android it's new capability. Called out explicitly in the PR body.

Deliverables I could NOT produce (need you)

1. Screenshots (EN + SL) — requires a running emulator with the dev APK. The APK is at build/app/outputs/flutter-apk/app-dev-debug.apk; grab these before Play submission.
2. On-device confirmation that the OS ACCESS_BACKGROUND_LOCATION prompt only fires after tapping "Allow background location" and does not fire on "Not now" — still gated on B005-style device access.
3. PR creation — gh CLI missing on this machine. Open the URL above and paste the PR body I drafted above in the terminal (or I can output it again).

BLOCKING before Play submission

The 4 new strings are exact spec text, not brand-voice-agent-approved. Per your instruction, you must run them through brand-voice-agent before this ships. Not blocking merge to main, but blocking store submission.
Datum oddaje v Play Console:
Datum odobritve (ali še čakam):
Opombe:
```

---

## FAZA A — TEMELJNE ODLOČITVE
Vse spodaj mora biti odločeno, PREDEN se dokumenti popravijo ali koda spremeni, sicer se popravlja dvakrat.

## KORAK 1 — 🧑‍⚖️ FOUNDER
### Naslov: Pravno posvetovanje — celoten Art. 9/10 obseg v enem sestanku

**Kaj rešujemo:** Štiri odprta pravna vprašanja, ki jih ne smem sam razrešiti: (1) katera pravna podlaga pokriva spolno usmerjenost (gender+lookingFor) kot jedrni matching podatek, (2) ali kanabis spada pod GDPR čl. 9 (zdravje, privolitev deluje) ali čl. 10 (kazniva dejanja, privolitev NI veljavna podlaga za zasebno podjetje), (3) potrditev pristopa k politični pripadnosti, (4) ali je obvezen location consent checkbox pri registraciji skladen s "freely given" standardom.

**Kaj moraš narediti:** Rezerviraj sestanek z odvetnico/odvetnikom, specializiranim za GDPR v kontekstu obdelave občutljivih podatkov (ne splošno korporativno pravo). Predloži ji `TREMBLE_MASTER_COMPLIANCE_REPORT_06JUL2026.md`, sekcijo Del II. Pojasni dejansko delovanje kode za vsako od štirih točk (ne uganjuj namesto nje).

**Pričakovan rezultat:** Pisen odgovor na vsa štiri vprašanja, ki določa smer za korake 3, 13, 14, 23.

**Todoist:** `6h3JCC8m76XQPQ4P` (umbrella), `6h3j9q65vh3mG64P`, `6h3jHjr7Hf58G8pw`, `6h3c3FHcXV8HPc4P`

**Output (izpolni ti):**
```text
Datum sestanka: ni in ne bo, bo kasneje ko bomo imeli funds for it. 07.07.2026: opravljen prvi prehod z Gemini (extended thinking). 

Odgovor na spolno usmerjenost (katera čl. 9(2) podlaga): Vaša utemeljitev natančno zadene bistvo Smernic EDPB 05/2020 (zlasti točke 36 in naprej). Prepoved pogojevanja (conditionality) iz člena 7(4) in Uvodne izjave 43 je namenjena preprečevanju situacij, ko upravljavec od uporabnika izsiljuje privolitev za podatke, ki niso nujni za izvajanje storitve (npr. zahtevanje podatkov o lokaciji za uporabo aplikacije za svetilko, ali deljenje spolne usmerjenosti z oglaševalci, kot v primeru Grindr).

Pri aplikaciji Tremble sta spol in preferenca (koga iščeš) objektivno in intrinzično nujna za zagotavljanje same jedrne storitve (algoritem ujemanja). Posameznik ima še vedno svobodno izbiro: ali želi uporabljati aplikacijo za zmenke (ki logično in nujno potrebuje te podatke) ali pa se odloči, da storitve ne bo uporabljal.

Ker je zahteva po izrecni privolitvi po Členu 9(2)(a) tukaj obvezna zaradi narave podatka, pogojevanje dostopa do aplikacije s to privolitvijo ni nezakonito, pod strogim pogojem (ki ga že navajate), da se ta podatek ne bo nikoli uporabil za noben drug namen (npr. monetizacija, deljenje s tretjimi osebami, oglaševanje).

Naslednji korak v kodi: V consent_step.dart dodate ločen checkbox z besedilom (npr. "Izrecno soglašam z obdelavo mojega spola in preference za namene iskanja ujemanj."), ki ga mora uporabnik obkljukati, da lahko zaključi registracijo (blocking step).

Odgovor na kanabis (čl. 9 ali čl. 10, in če čl. 10 — ali obstaja pravna podlaga za obdelavo): Funkcionalnost v celoti odstranjena iz produkta. Odločitev sprejeta neodvisno od dokončne pravne klasifikacije (čl. 9 vs čl. 10), ker tveganje po čl. 10 v določenih ciljnih jurisdikcijah onemogoča varno privolitveno podlago za zasebno podjetje. Founder odločitev, 07.07.2026.

Odgovor na politično pripadnost: Polje v celoti odstranjeno iz produkta. Ni bilo uporabljeno v algoritmu ujemanja (0 referenc), po STRIP odločitvi za getPublicProfile tudi ne bi bilo več prikazano — brez preostalega funkcionalnega namena je odstranitev edina skladna z načelom minimizacije (čl. 5(1)(c)). Founder odločitev, 07.07.2026.

Odgovor na location consent: Dvojni pristop, ki ste ga predlagali, je izjemno eleganten in pravno najbolj robusten način za reševanje geolokacije v dating aplikacijah:

Ospredje (Foreground) - Člen 6(1)(b): Ko ima uporabnik aplikacijo odprto, je prikaz bližnjih oseb tisto, kar pogodba (Terms of Service) obljublja. Obdelava lokacije v tistem trenutku je strogo nujna za izvajanje te pogodbe. Sklicevanje na 6(1)(b) je tu absolutno legitimno.

Ozadje (Background Radar) - Člen 6(1)(a): Sledenje v ozadju, ko uporabnik telefona ne uporablja aktivno, predstavlja bistveno večji poseg v zasebnost. Težko bi ga ubranili kot "strogo nujnega za izvajanje pogodbe" (saj bi uporabnik lahko app preprosto odprl, ko želi pregledati okolico). Prehod na privolitev za ta specifičen del je edina varna pot. Zelo pomembno: uporabnik mora imeti možnost to privolitev zavrniti (ali preklicati), pri čemer mu aplikacija v ospredju še vedno normalno deluje.

Unbundling (Ločitev od ToS): To, da boste operacijsko dovoljenje za lokacijo in obvestilo premaknili v povsem ločen zaslon stran od _consentGiven (starost + ToS), popolnoma odpravlja kršitev člena 7(2) GDPR (prepoved združevanja privolitev s pogoji poslovanja).

Naslednji korak v kodi: Vključi se ta ločen "disclosure screen" za lokacijo (Kar tudi sovpada z zahtevami za Prominent Disclosure v Google Play Console - Korak 0).

Status implementacijskega načrta:
S tem sta dve največji pravni dilemi ("Spolna usmerjenost" in "Location consent") iz Koraka 1 razrešeni in imata utemeljeno pravno podlago.

Ker sta Politična pripadnost in Kanabis že bila rešena z odločitvijo o izbrisu iz produkta, ste zdaj uspešno zaprli celoten Korak 1. Vsi temeljni arhitekturni (founder) sklepi iz Faze A so sedaj sprejeti.

Priložen dokument/email pravnice (da/ne, kje shranjen): NE. Pravnica še ni bila formalno kontaktirana. Pripravljen je dokument "Navodila za pravno mnenje — Tremble, Člen 9 GDPR" ([pot do datoteke]), pripravljen za pošiljanje. Gemini prvi prehod shranjen v DPIA kot neuradna referenca, ni pravna podlaga.
```

---

## KORAK 2 — 🧑‍⚖️ FOUNDER
### Naslov: getPublicProfile — popravi kodo ali dokumentiraj razkritje

**Kaj rešujemo:** Koda trenutno vrača religion/ethnicity/politicalAffiliation vsakemu ujemanju. DPIA trdi nasprotno. Eno od dvoje mora popustiti.

**Kaj moraš narediti:** Odloči: (a) je bilo razkritje teh polj matchu namerno (kot "razlog za ujemanje", podobno OkCupid profilnim atributom), ali (b) je bug, ki ga popravimo. Če (a) — koraki 14, 23, 34 dobijo drugačno besedilo. Če (b) — korak 11 postane aktiven, koraki 14/23/34 odpadejo v tej obliki.

**Pričakovan rezultat:** Ena zapisana odločitev: STRIP (odstrani iz kode) ali KEEP+DISCLOSE (popravi dokumente).

**Todoist:** `6h3jFhxVHpRmph9P`
prompt:Izvajam Korak 2 in 11 iz implementacijskega načrta. Moja odločitev za getPublicProfile je STRIP.

Naloga:

Poišči funkcijo getPublicProfile v functions/src/users.functions.ts.

Iz objekta, ki ga funkcija vrača (response object), trajno odstrani polja: religion, ethnicity, gender in politicalAffiliation.

Preveri, ali se ta polja po spremembi še vedno pošiljajo na klient; če se, jih izloči iz User modela/interfacsa, ki se uporablja za serilizacijo JSON-a.

Testiranje: Posodobi ali ustvari regression test v functions/src/tests/users.test.ts, ki preverja, da getPublicProfile ob klicu z veljavnim matchId v JSON odgovoru nima teh polj (uporabi expect().not.toHaveProperty(...)).

Ohranjanje logike: Zagotovi, da zaledni algoritem za compatibility scoring (compatibility_calculator.ts) še vedno deluje z vsemi prej naštetimi polji (saj jih potrebujemo za calculateLifestyleScore), le klientu jih ne pošiljamo več.

Pred potrditvijo sprememb mi izpiši kratek seznam datotek, ki si jih spremenil, in potrdi, da testi prehajajo."
**Output (izpolni ti):**
```text
Odločitev: STRIP
Razlog: Podatka o verskem prepričanju in etnični pripadnosti sta ključna izključno za zaledni algoritem ujemanja (backend match logic). Ne bosta prikazana na profilni kartici ujemajočega se uporabnika, zato ju funkcija getPublicProfile ne sme vračati klientu.
Datum: 08.07.2026
```

---

## KORAK 3 — 🧑‍⚖️ FOUNDER
### Naslov: Politična pripadnost — izberi eno od treh poti

**Kaj rešujemo:** Polje se zbira, ni v scoringu, prikazuje se matchu. Trije možni pristopi: izbriši, vgradi v scoring (verjetno ne to, kar želiš), ali ohrani kot display atribut z lastnim consentom.

**Kaj moraš narediti:** Odloči, upoštevaj vhod iz koraka 1, če je pravnica komentirala politiko.

**Pričakovan rezultat:** Ena od treh poti izbrana, korak 12 se aktivira ali preskoči.

**Todoist:** `6h3JCCG8pC38rJhP`

**Output (izpolni ti):**
```text
Odločitev: IZBRIŠI
Razlog: Polje v celoti odstranjeno iz produkta. Ni bilo uporabljeno v algoritmu ujemanja (0 referenc), po STRIP odločitvi za getPublicProfile tudi ne bi bilo več prikazano — brez preostalega funkcionalnega namena je odstranitev edina skladna z načelom minimizacije (čl. 5(1)(c)). Founder odločitev, 07.07.2026.
Branch pushed. gh still isn't installed so PR must be opened via the URL in the push output.

---
Final summary

Branch: feature/remove-political-affiliation
Commit: 233fcea — 18 files changed, 156 insertions, 621 deletions
PR-create URL: [https://github.com/MartinD111/Tremble-DatingApp/pull/new/feature/remove-political-affiliation](https://github.com/MartinD111/Tremble-DatingApp/pull/new/feature/remove-political-affiliation)

Grep evidence (task-required)

Zero remaining references to politicalAffiliation, political_affiliation, or politics_ in lib/ or functions/src/, excluding the migration script:

aleksandarbojic@MacBook-Air-Aleksandar Pulse---Dating-app % grep -rn "politicalAffiliation|political_affiliation|politics_" lib functions/src \
    | grep -v "scripts/remove_political_affiliation" | wc -l
       0
aleksandarbojic@MacBook-Air-Aleksandar Pulse---Dating-app % 

Verification (evidence)

- flutter analyze — 0 issues
- flutter test — 207/207 pass (was 209; the 2 dropped are SliderNormalizer.labelForPolitical unit tests which no longer have a subject)
- cd functions && npm run build — clean
- cd functions && npm test — 63/63 pass across 8 suites
- Pre-commit hook (format + analyze + functions 63/63 + flutter 207/207) — all green

Migration script

- Location: functions/src/scripts/remove_political_affiliation.ts (compiles to functions/lib/scripts/remove_political_affiliation.js)
- Not imported by functions/src/index.ts → won't be deployed as a Cloud Function
- Modes: --dry-run (default) and --apply
- Batches at 400 writes/commit (under the 500-write Firestore cap)
- Never logs field values — only counts
- Refuses to run against am---dating-app without an explicit --i-know-this-is-prod flag

Dry-run against tremble-dev:
$ node ./lib/scripts/remove_political_affiliation.js --project=tremble-dev --dry-run
[migration] project=tremble-dev mode=DRY-RUN prodConfirmed=false
[migration] scanning users collection for fields: politicalAffiliation, politicalAffiliationPreference
[migration] scanned 0 user documents
[migration] 0 documents carry one or both target fields
[migration] DRY-RUN complete. Re-run with --apply to commit.
Zero documents on tremble-dev currently carry the field — the collection is empty or already clean. Script logic is verified; a no-op result is a legitimate outcome.

Explicit confirmation

- Migration NOT run against am---dating-app. Awaiting founder approval per task spec.
- To run against prod after your approval: node ./lib/scripts/remove_political_affiliation.js --project=am---dating-app --i-know-this-is-prod --dry-run first, then --apply.

Scope note

Task said "Remove EN+SL translation keys". I extended removal to all 9 locales because after the field is gone the keys are orphaned dead code in every locale. Called out in the commit body.
Datum: 07.07.2026
```

---

## KORAK 4 — 🧑‍⚖️ FOUNDER
### Naslov: Weekend Getaway — implementiraj enforcement ali umakni obljubo

**Kaj rešujemo:** ToS §7 obljublja avtomatsko časovno okno (pet 19h–ned 19h), koda tega ne izvaja. To je zdaj netočna pogodbena obljuba, ne le manjkajoča funkcija.

**Kaj moraš narediti:** Odloči: implementiraj backend enforcement (korak 15 se aktivira), ali odstrani časovno obljubo iz ToS in paywall copy (korak 15 odpade, korak 24 popravi ToS §7 ustrezno).

**Pričakovan rezultat:** Ena odločitev, ki določa ali korak 15 obstaja.

**Todoist:** `6h332RFRW946QWXw`

**Output (izpolni ti):**
```text
Odločitev: IMPLEMENTIRAJ ENFORCEMENT / ODSTRANI OBLJUBO
Razlog:
Datum:
```

---

## KORAK 5 — 🧑‍⚖️ FOUNDER
### Naslov: DPO — imenuj ali dokumentiraj, da ni obvezen

**Kaj rešujemo:** GDPR čl. 37 in ZVOP-2 čl. 45 verjetno zahtevata DPO zaradi sistematičnega spremljanja lokacije + posebnih kategorij. Co-founder ne more biti DPO (konflikt interesov).

**Kaj moraš narediti:** Odloči, ali imenuješ zunanjega DPO, ali dokumentiraš pravno utemeljitev, zakaj ni obvezen. Če imenuješ: objavi kontakt na spletu (korak 33) in javi Informacijskemu pooblaščencu v 8 dneh.

**Pričakovan rezultat:** Odločitev + (če imenovan) ime/kontakt DPO za ROPA (korak 26) in website (korak 33).

**Todoist:** `6h3j9qH3m3p543QP`

**Output (izpolni ti):**
```text
Odločitev: IMENUJEM DPO / NI OBVEZEN (pravna utemeljitev spodaj)
Ime/kontakt DPO (če imenovan):
IP obveščen dne (če imenovan):
Datum:
```

---

## KORAK 6 — 🧑‍⚖️ FOUNDER
### Naslov: Potrdi PostHog stanje na trembledating.com

**Kaj rešujemo:** DPA in Privacy Policy ne navajata PostHog, čeprav projektni kontekst omenja PostHog EU za website analitiko. Ni jasno, ali je dejansko live.

**Kaj moraš narediti:** Preveri Cloudflare Pages / website kodo — je PostHog inicializiran? Če da, v kakšnem načinu (cookies vključno ali cookieless)?

**Pričakovan rezultat:** Potrjeno dejansko stanje, ki določa vsebino korakov 25, 31.

**Todoist:** `6h3jFj2jfrw6VmVP`

**Output (izpolni ti):**
```text
PostHog aktiven: DA / NE
Če DA — način (cookies / cookieless):
Datum:
```

---

## FAZA B — KODA, NEODVISNA OD ZGORNJIH ODLOČITEV
Ti koraki nimajo pravne odvisnosti — lahko tečejo takoj, vzporedno s Fazo A.

## KORAK 7 — 🤖 CODE
### Naslov: Info.plist — počisti podvojene ključe + popravi Contacts string

**Kaj rešujemo:** NSCameraUsageDescription in NSPhotoLibrary* se pojavijo dvakrat. NSContactsUsageDescription trdi, da app ne dostopa do kontaktov — Privacy Policy §2.5 opisuje funkcijo (Anonymity Mode), ki jih bere.

**Kaj mora Codex narediti:** Odstrani podvojene ključe (obdrži boljše besedilo od dveh). Popravi Contacts string, da resnično opiše Anonymity Mode, ALI potrdi, da funkcija ne obstaja in odstrani permission + PP referenco.

**Pričakovan rezultat:** En ključ na permission, Contacts string se ujema z dejanskim vedenjem.

**Todoist:** `6h3p8gWpxpq7rWXw`

**Output (izpolni AI):**
```text
Status:
Datoteke spremenjene:
Ugotovitve (je Anonymity Mode dejansko implementiran?):
Testi (flutter analyze / test rezultat):
Blokerji:
```

---

## KORAK 8 — 🤖 CODE
### Naslov: Dodaj PrivacyInfo.xcprivacy manifest

**Kaj rešujemo:** Manjka od iOS 17.4 — avtomatska zavrnitev (ITMS-91053).

**Kaj mora Codex narediti:** Ustvari manifest z NSPrivacyCollectedDataTypes (lokacija, fotografije, ime, email, sensitive info) in NSPrivacyAccessedAPITypes (UserDefaults, FileTimestamp, SystemBootTime, DiskSpace). Dodaj v Xcode Runner target.

**Pričakovan rezultat:** Manifest prisoten in veljaven, xcodebuild archive uspe.

**Todoist:** `6h3grHhjVXFhMRJP`

**Output (izpolni AI):**
```text
Status:
Datoteka ustvarjena na:
Testi:
Blokerji:
```

---

## KORAK 9 — 🤖 CODE
### Naslov: Dodaj ITSAppUsesNonExemptEncryption

**Kaj rešujemo:** Manjka v Info.plist, vsak upload zahteva ročni compliance odgovor.

**Kaj mora Codex narediti:** Dodaj `<key>ITSAppUsesNonExemptEncryption</key><false/>` v Info.plist.

**Pričakovan rezultat:** Ključ prisoten, TestFlight upload ne zahteva ročnega vprašanja.

**Todoist:** `6h3grHqC22mCcccP`

**Output (izpolni AI):**
```text
Status:
Testi:
```

---

## KORAK 10 — 🤖 CODE
### Naslov: Uskladi proximity TTL (2h) med kodo in Firebase Console

**Kaj rešujemo:** UI besedilo obljublja 2h, ADR-002 pravi 2h, DPIA trdi 24h. Preveri, kaj Firebase Console dejansko izvaja.

**Kaj mora Codex narediti:** Preveri Firebase Console TTL policy za `proximity/{uid}` — ujemanje polja `geoHashExpiresAt` in vrednosti 2h. Popravi geo_service.dart, če se ne ujema.

**Pričakovan rezultat:** Koda, UI copy in Firebase Console vsi navajajo 2h.

**Todoist:** `6h332R4PwWhvrfxP`

**Output (izpolni AI):**
```text
Status:
Dejanska vrednost v Firebase Console pred popravkom:
Sprememba narejena:
Testi:
```

---

## KORAK 11 — 🤖 CODE *(pogojno — samo če je Korak 2 = STRIP)*
### Naslov: Odstrani religion/ethnicity/politicalAffiliation iz getPublicProfile

**Kaj rešujemo:** Art. 9 podatki se razkrivajo matchu brez razkritega namena v Privacy Policy.

**Kaj mora Codex narediti:** V `users.functions.ts` odstrani navedena polja iz response objekta funkcije getPublicProfile. Dodaj regression test, ki potrdi odsotnost.

**Pričakovan rezultat:** getPublicProfile ne vrača nobenega Art. 9 polja.

**Todoist:** `6h3jFhxVHpRmph9P`

**Preveri pred izvedbo:** Korak 2 Output = STRIP.
Before you do anything: 2. Arhiviraj dokaz (Zelo pomembno za IP) Koda, ki jo boš implementiral, je tvoj glavni dokaz pred Informacijskim pooblaščencem (IP), da tvoje besede v DPIA niso le "papirnata obramba". Kopijo testa, ki preverja odsotnost teh polj, shrani v mapi Tremble/docs/compliance-evidence/. To je tvoj "dokaz o tehničnem ukrepu".
**Output (izpolni AI):**
```text
Status:
Datoteke spremenjene:
Test dodan:
```

---

## KORAK 12 — 🤖 CODE *(pogojno — samo če je Korak 3 = OHRANI KOT DISPLAY+CONSENT)*
### Naslov: Implementiraj politicalAffiliationConsent

**Kaj rešujemo:** Ni consent mehanizma za politično pripadnost, čeprav se prikazuje matchu.

**Kaj mora Codex narediti:** Dodaj `politicalAffiliationConsent` (bool?, nullable) v AuthUser model, backend interface, in nov ločen consent checkbox v consent_step.dart z besedilom "shown on your profile to matches" (ne "used for matchmaking").

**Pričakovan rezultat:** Ločen, neblokirajoč consent za politiko, ki ne trdi napačnega namena.

**Todoist:** `6h3jHjhfQ2vH2wMP`

**Preveri pred izvedbo:** Korak 3 Output = IZBRIŠI, preskoči.

**Output (izpolni AI):**
```text
Status (izvedeno / preskočeno): PRESKOČENO — Korak 3 odločitev = IZBRIŠI, ne OHRANI KOT DISPLAY+CONSENT. Political affiliation odstranjen iz produkta v celoti (glej Korak 3 output in DPIA Placeholder 1). politicalAffiliationConsent se ne implementira, ker polja, na katerega bi se nanašal, ni več.
Datoteke spremenjene: N/A
Testi: N/A
```

---

## KORAK 12.1 — 🤖 CODE
### Naslov: Implementiraj izrecno privolitev za spol in preferenco iskanja

**Kaj rešujemo:** Podatka `gender` in `lookingFor` posredno razkrivata spolno usmerjenost (čl. 9 GDPR). Zbirata se v onboardingu, a nimata mehanizma izrecne privolitve (Člen 9(2)(a)), ki je obvezen, čeprav sta podatka nujna za algoritem ujemanja.

**Kaj mora Codex narediti:** V registracijski postopek (tam kjer se zbirata gender/lookingFor ali v `consent_step.dart`) dodaj obvezno (blocking) potrditveno polje. Besedilo mora jasno navajati: *"I explicitly consent to the processing of my gender and matching preferences solely for the purpose of finding matches."* Dodaj boolean polje `sexualOrientationConsent` v model in bazo.

**Pričakovan rezultat:** Shranjen in timestamp-an dokaz o izrecni privolitvi za obdelavo teh dveh polj pri vsakem uporabniku.

**Output (izpolni AI):**
```text
Status:
Datoteke spremenjene:
```

---

## KORAK 12.2 — 🤖 CODE
### Naslov: Popravi besedilo potrditve starosti na striktno "18+"

**Kaj rešujemo:** ZVOP-2 in GDPR za obdelavo posebnih vrst osebnih podatkov (čl. 9) v dating aplikacijah zahtevata strogo starostno mejo. Trenutno UI besedilo (verjetno "age of majority") je dvoumno in ne ščiti upravljavca ustrezno.

**Kaj mora Codex narediti:** V `consent_step.dart` popravi besedilo spremenljivke za potrditev starosti iz generičnega "I am of legal age / age of majority" v eksplicitno *"I am at least 18 years old"*. Posodobi prevode (EN in SL).

**Pričakovan rezultat:** Uporabnik eksplicitno potrdi, da je star 18 let ali več, ne pušča se prostora za lokalne interpretacije "polnoletnosti" pri 16 letih.

**Output (izpolni AI):**
```text
Status:
Datoteke spremenjene:
```

---

## KORAK 13 — 🤖 CODE *(pogojno — glede na Korak 1 pravni odgovor o kanabisu)*
### Naslov: Kanabis — implementiraj ločen consent ALI odstrani vprašanje

**Kaj rešujemo:** Ni consent mehanizma, združeno z nikotinom v eno polje, možna čl. 10 izpostavljenost.

**Kaj mora Codex narediti:**
- Če Korak 1 pravni odgovor = čl. 9 pot varna: implementiraj ločen `cannabisConsent`, disclaimer pred vprašanjem, ločeno polje od nicotineUse.
- Če Korak 1 pravni odgovor = čl. 10 ali negotovo: odstrani cannabis opcijo iz nicotine_step.dart popolnoma.

**Pričakovan rezultat:** Skladno stanje z Korak 1 pravnim odgovorom.

**Todoist:** `6h3jHjr7Hf58G8pw` + podtaski `6gq4M39XVH3VmXPw`

**Preveri pred izvedbo:** Korak 1 Output — kanabis odgovor.

**Output (izpolni AI):**
```text
Pot izbrana glede na Korak 1 (implementiraj / odstrani): ODSTRANI — founder odločitev sprejeta neodvisno od dokončnega pravnega mnenja, konzervativna izbira zaradi tveganja po čl. 10 GDPR v določenih ciljnih jurisdikcijah (glej Korak 1 output: "bomo izbrisali funkcijo").
Status: gh CLI isn't installed on this machine. Branch is pushed — I'll give you the URL and PR body to paste.

Branch pushed: feature/remove-cannabis → https://github.com/MartinD111/Tremble-DatingApp/pull/new/feature/remove-cannabis

Task summary

┌───────────────────────────────────┬────────────────────────────────────────────────────────────────────────────────────────────┐
│            Requirement            │                                           Status                                           │
├───────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────┤
│ Discovery grep                    │ ✅ Reported all file:line matches before touching code                                     │
├───────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────┤
│ Field shape confirmed             │ ✅ nicotineUse: List<String> (multi-select); cannabis stored as string "cannabis"          │
├───────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────┤
│ UI cannabis removal               │ ✅ nicotine_step.dart, edit_profile_screen.dart, settings_screen.dart                      │
├───────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────┤
│ Icon/comment cleanup              │ ✅ icon_utils.dart, auth_repository.dart:66                                                │
├───────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────┤
│ Backend Zod schema                │ ✅ Converted nicotineUseSchema to z.array(z.enum([cigarettes, vape, iqos, zyn, shisha]))   │
│                                   │ in both users.schema.ts and auth.schema.ts — cannabis actively rejected at API boundary    │
├───────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────┤
│ EN + SL translations removed      │ ✅ Extended to all 8 locales (same rationale as political-affiliation precedent)           │
├───────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────┤
│ Migration script                  │ ✅ functions/src/scripts/remove_cannabis.ts — --dry-run default,                           │
│                                   │ arrayContains+FieldValue.arrayRemove, prod guard --i-know-this-is-prod                     │
├───────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────┤
│ vape/iqos/cigarette/zyn/shisha    │ ✅ Product grid and enum values preserved                                                  │
│ untouched                         │                                                                                            │
├───────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────┤
│ flutter analyze                   │ ✅ 0 issues                                                                                │
├───────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────┤
│ flutter test                      │ ✅ 207/207                                                                                 │
├───────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────┤
│ flutter build apk --debug         │ ✅ built                                                                                   │
│ --flavor dev                      │                                                                                            │
├───────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────┤
│ functions/npm run build           │ ✅ 0 errors                                                                                │
├───────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────┤
│ functions/npm test                │ ✅ 63/63                                                                                   │
├───────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────┤
│ Migration NOT run on prod         │ ✅ Awaiting founder approval                                                               │
└───────────────────────────────────┴────────────────────────────────────────────────────────────────────────────────────────────┘

Final grep

lib/src/features/profile/presentation/edit_profile_screen.dart:121:
        ..addAll(user.nicotineUse.where((v) => v != 'cannabis'));
functions/src/scripts/remove_cannabis.ts: (script content — expected)

Only two intentional references remain: (1) a defensive load-time filter in edit_profile_screen.dart so pre-migration users can still save without a 400 from the new enum, and (2) the migration script itself.

Migration dry-run on tremble-dev

Not yet executed — I don't have Firebase Admin SDK credentials configured in this shell. Script is compiled (tsc clean) and ready. Please run:

cd functions && npm run build
node ./lib/scripts/remove_cannabis.js --project=tremble-dev --dry-run

That will output the number of user docs carrying "cannabis" in nicotineUse without modifying anything. If the count looks sane, re-run with --apply.

Explicit confirmation: migration script has NOT been run against am---dating-app. Prod run requires founder-approved invocation with --project=am---dating-app --i-know-this-is-prod --apply.

PR body

Since I can't create the PR (no gh CLI), open the URL above and paste the PR body from my previous message body (title: feat: remove cannabis from nicotineUse (GDPR Art. 10 risk mitigation)). Want me to install gh via Homebrew and re-attempt, or would you rather open the PR yourself?

Datoteke spremenjene (commit 2d88b9f na branchu feature/remove-cannabis):
  functions/src/__tests__/auth.test.ts
  functions/src/__tests__/users.test.ts
  functions/src/modules/auth/auth.schema.ts
  functions/src/modules/users/users.schema.ts
  functions/src/scripts/remove_cannabis.ts                                      [NEW]
  lib/src/core/translations.dart
  lib/src/core/utils/icon_utils.dart
  lib/src/features/auth/data/auth_repository.dart
  lib/src/features/auth/presentation/widgets/registration_steps/nicotine_step.dart
  lib/src/features/profile/presentation/edit_profile_screen.dart
  lib/src/features/settings/presentation/settings_screen.dart

Grep verifikacija (samo namerne reference ostanejo):
  lib/src/features/profile/presentation/edit_profile_screen.dart:121
      ..addAll(user.nicotineUse.where((v) => v != 'cannabis'));
      → obrambni filter za legacy podatke pred migracijo; pred-migracijski
        uporabniki lahko shranijo profil brez 400 zaradi novega enum-a.
  functions/src/scripts/remove_cannabis.ts
      → migracijska skripta sama; pričakovano.

Merge status: feature/remove-cannabis → main (fast-forward), pushed on origin/main.
```

---

## KORAK 14 — 🤖 CODE *(pogojno — samo če je Korak 2 = KEEP+DISCLOSE)*
### Naslov: Religion/ethnicity consent copy — dodaj razkritje "viden matchu"

**Kaj rešujemo:** Če se getPublicProfile ohrani, mora consent besedilo to razkriti.

**Kaj mora Codex narediti:** Dodaj stavek "This information may also be visible to users you match with, on your profile" v oba (religion/ethnicity) checkboxa, EN+SL.

**Pričakovan rezultat:** Consent besedilo se ujema z dejanskim razkritjem.

**Todoist:** `6h3jHm6rgRW49GPP`

**Preveri pred izvedbo:** Korak 2 Output = KEEP+DISCLOSE? Če STRIP, preskoči (korak 11 to že rešuje).

**Output (izpolni AI):**
```text
Status (izvedeno / preskočeno): PRESKOČENO — Korak 2 odločitev = STRIP, ne KEEP+DISCLOSE. Razkritje "viden matchu" je brezpredmetno, ker religion/ethnicity po Koraku 11 nista več vidna matchanemu uporabniku (glej DPIA Placeholder 2).
Besedilo dodano (EN): N/A
Besedilo dodano (SL): N/A
```

---

## KORAK 15 — 🤖 CODE *(pogojno — samo če je Korak 4 = IMPLEMENTIRAJ ENFORCEMENT)*
### Naslov: Weekend Getaway — implementiraj backend časovno okno

**Kaj rešujemo:** ToS obljublja avtomatsko okno pet 19h–ned 19h, ki ga koda ne izvaja.

**Kaj mora Codex narediti:** `processWeekendPasses` CF naj enforce-a časovno okno, prekliče entitlement izven njega.

**Pričakovan rezultat:** Weekend Pass se dejansko samodejno vklopi/izklopi po urniku.

**Preveri pred izvedbo:** Korak 4 Output = IMPLEMENTIRAJ? Če ODSTRANI OBLJUBO, preskoči — namesto tega korak 24 popravi ToS copy.

**Output (izpolni AI):**
```text
Status (izvedeno / preskočeno):
Datoteke spremenjene:
Testi:
```

---

## KORAK 16 — 🤖 CODE
### Naslov: Gym Mode — odstrani proximity gate na ročni aktivaciji

**Kaj rešujemo:** Backend zavrne ročno aktivacijo, če uporabnik ni fizično v telovadnici — izniči smisel ročne aktivacije.

**Kaj mora Codex narediti:** V `gym.functions.ts` (onGymModeActivate) odstrani haversine distance check. Ohrani lat/lng za prvo proximity iteracijo, a jih ne uporabi za gate.

**Pričakovan rezultat:** Ročna aktivacija uspe od koderkoli; geofence dwell service ostane kot samodejna nadgradnja.

**Todoist:** `6h3pjGP2jHCgcgWw`

**Output (izpolni AI):**
```text
Status:
Datoteke spremenjene:
Test posodobljen (gym.test.ts):
```

---

## KORAK 17 — 🤖 CODE
### Naslov: Map heatmap — realna geohash agregacija namesto mock podatkov

**Kaj rešujemo:** Heatmap krogi so naključno generirani in v produkciji sploh ne prikazani — mapa je prazna.

**Kaj mora Codex narediti:** Nov CF `getHeatmapDensity(precision, boundingBox)` z geohash-prefix agregacijo, k-anonymity gate (≥5 uporabnikov na celico), bucketiziran count, Upstash cache TTL 60s. Frontend zamenja mock generator s streamom iz endpointa, zoom mapira na precision.

**Pričakovan rezultat:** Realna, privacy-safe gostota v produkciji.

**Todoist:** `6h3pjGRx7rmV6hcw`

**Output (izpolni AI):**
```text
Status:
Nov endpoint:
K-anonymity test rezultat:
Cache implementiran (da/ne):
```

---

## KORAK 18 — 🤖 CODE
### Naslov: Event Mode — prestavi koordinate v Firestore

**Kaj rešujemo:** 3 lokacije so hardcoded, v produkciji se ne prikazujejo.

**Kaj mora Codex narediti:** Dodaj `location` (GeoPoint) polje v Firestore `events` dokumente. Odstrani hardcoded `_eventLocations` in `_isDev` gate v tremble_map_screen.dart.

**Pričakovan rezultat:** Event pini se prikazujejo v produkciji iz realnih podatkov.

**Todoist:** `6h3pjGpMqrpVHqFw`

**Output (izpolni AI):**
```text
Status:
Firestore dokumenti posodobljeni (da/ne):
```

---

## KORAK 19 — 🤖 CODE
### Naslov: Hobby lokalizacija — jezikovno-nevtralni ID-ji

**Kaj rešujemo:** Hobbiji mešajo SL/EN ne glede na jezik, ker so imena shranjena kot ključi. Matching primerja tekst — "Hiking" ≠ "Pohodništvo".

**Kaj mora Codex narediti:** Kanoničen seznam hobby ID-jev v hobby_data.dart, lokalizacijska tabela za prikaz, migracijska preslikava starih imen ob branju (parseHobbies), zamenjaj vse `hobby['name']` renderje s tr(id).

**Pričakovan rezultat:** Hobbiji dosledno v izbranem jeziku, matching deluje ne glede na jezik vnosa.

**Todoist:** `6h3pjGcGJPpWGrpw`

**Output (izpolni AI):**
```text
Status:
Migracija testirana proti obstoječim profilom (da/ne):
```

---

## KORAK 20 — 🤖 CODE
### Naslov: Registracijsko lokacijsko polje — prost tekst namesto selektorja

**Kaj rešujemo:** KP/LJ/ZG/Other nima funkcije, matching ne uporablja tega polja.

**Kaj mora Codex narediti:** Zamenjaj OptionPill selektor z navadnim TextField. Brez Places API, brez geocodinga.

**Pričakovan rezultat:** Prost tekst, manj podatka, en procesor manj v DPA (če se Places API tu odstrani).

**Todoist:** `6h3pjGjHpGwq9vCP`

**Output (izpolni AI):**
```text
Status:
Places API še uporabljen drugje (da/ne, kje):
```

---

## FAZA C — PAYWALL (po odločitvah A, pred finalno kodo)

## KORAK 21 — 🧑‍⚖️ FOUNDER
### Naslov: Pulse Intercept — določi tier (Free/Premium)

**Kaj rešujemo:** Koda tega jasno ne gate-a.

**Kaj moraš narediti:** Odloči Free ali Premium, glede na core-mechanic argument vs monetizacijski argument v master reportu Del V.

**Todoist:** `6h3pmrQ5wgFxRrCw`

**Output (izpolni ti):**
```text
Odločitev: FREE / PREMIUM
Razlog:
```

---

## KORAK 22 — 🤖 CODE
### Naslov: Paywall — uskladi oglaševane funkcije s kodo, prioritiziraj prave triggerje

**Kaj rešujemo:** Paywall oglašuje "unlimited geofence pings" in "advanced filtering matrix", ki v kodi ne obstajata. Hkrati skriva "see who waved" in "near-miss recap" — najmočnejša konverzijska trigger-ja.

**Kaj mora Codex narediti:** Za vsako oglaševano funkcijo potrdi obstoj gate-a v kodi — implementiraj manjkajoče ali odstrani iz paywalla. Premakni see-who-waved in near-miss v ospredje feature liste. Vgradi Korak 21 odločitev za Pulse Intercept.

**Pričakovan rezultat:** Paywall točno odraža kodo; močnejša trigger-ja v ospredju.

**Todoist:** `6h3pmrF84Cf6JVQP`, `6h3pmrHP7C6j6Cfw`

**Output (izpolni AI):**
```text
Status:
Funkcije odstranjene iz paywalla:
Funkcije implementirane:
Nov vrstni red feature liste:
```

---

## FAZA D — DOKUMENTI (enkratni prepis, po vseh zgornjih odločitvah)
Ne začni te faze, dokler koraki 1–20 niso zaključeni ali eksplicitno preskočeni z razlogom — sicer prepisuješ dokumente dvakrat.

## KORAK 23 — 📄 DOC
### Naslov: Popravi DPIA (enoten prepis)

**Kaj rešujemo:** DPIA vsebuje napačne trditve o TTL (24h namesto 2h), T3 mitigaciji (getPublicProfile), in politični privolitvi.

**Kaj moraš narediti:** Prepiši §3.2, §4.2 (T3), §8 skladno z izidi korakov 2, 10; §2.3 skladno z izidom koraka 1 (spolna usmerjenost, kanabis) in koraka 3 (politika).

**Pričakovan rezultat:** DPIA se v celoti ujema z dejansko kodo.

**Todoist:** povezano z `6h332R4PwWhvrfxP`, `6h3jFhxVHpRmph9P`

**Output (izpolni ti/pravnica):**
```text
Status:
Verzija dokumenta:
Datum:
```

---

## KORAK 24 — 📄 DOC
### Naslov: Finaliziraj ToS

**Kaj rešujemo:** §7 Weekend Getaway obljuba, §16 slovenska klavzula brez SL verzije, DSA kontaktne točke niso eksplicitno označene.

**Kaj moraš narediti:** Uskladi §7 z izidom koraka 4. Razreši §16 (dodaj SL verzijo ali popravi klavzulo). Dodaj eksplicitno "DSA Contact Points" sekcijo.

**Todoist:** `6h332RFRW946QWXw`, `6h3jFj7ppxRM7pWP`, `6h3j9qQVcqwXQjfP`

**Output (izpolni ti):**
```text
Status:
SL verzija ustvarjena (da/ne):
Datum:
```

---

## KORAK 25 — 📄 DOC
### Naslov: Finaliziraj Privacy Policy

**Kaj rešujemo:** §2.2 napačno trdi "voluntarily provided" za spolno usmerjenost; getPublicProfile razkritje ni omenjeno (če Korak 2 = KEEP); PostHog ni naveden.

**Kaj moraš narediti:** Popravi §2.2 skladno s Korakom 1 pravnim odgovorom. Dodaj razkritje matchu, če Korak 2 = KEEP+DISCLOSE. Dodaj PostHog v §6, če Korak 6 = aktiven.

**Todoist:** `6h3j9q65vh3mG64P`, `6h3jFhxVHpRmph9P`, `6h3jFj2jfrw6VmVP`

**Output (izpolni ti):**
```text
Status:
Datum:
```

---

## KORAK 26 — 📄 DOC
### Naslov: Dopolni DPA

**Kaj rešujemo:** Manjka matična številka, PostHog kot procesor (če aktiven), re-sign pod AMS Solutions.

**Kaj moraš narediti:** Dopolni matično številko. Dodaj PostHog v Prilogo 1, če Korak 6 = aktiven. Re-sign Google/Cloudflare/Upstash/Resend pod AMS Solutions.

**Todoist:** `6h3jFj5pQhxpm9xw`, `6h3jFj2jfrw6VmVP`, `6ggJGh4jFJGQ43mP`, `6ggJGhH3gv7wcjRP`, `6ggJGhPc3hc86Grw`, `6ggJGhVPgPGW5Qmw`

**Output (izpolni ti):**
```text
Matična številka dopolnjena (da/ne):
DPA re-signed: Google [ ] Cloudflare [ ] Upstash [ ] Resend [ ]
Datum:
```

---

## KORAK 27 — 📄 DOC
### Naslov: Konsolidiraj ROPA v en dokument

**Kaj rešujemo:** Vsebina obstaja raztresena po DPA/DPIA/PP.

**Kaj moraš narediti:** En xlsx/md dokument v obliki čl. 30(1), vključno z DPO kontaktom (Korak 5) in PostHog (Korak 6).

**Todoist:** `6h3j9qG7pC7jVX5P`

**Output (izpolni ti):**
```text
Status:
Datum:
```

---

## KORAK 28 — 📄 DOC
### Naslov: Napiši breach notification postopek + register

**Kaj rešujemo:** Manjka smer upravljavec→IP (72h) in upravljavec→posamezniki.

**Kaj moraš narediti:** 1-stranski postopek + prazna tabela registra kršitev.

**Todoist:** `6h3j9qhmmhXjHPPP`

**Output (izpolni ti):**
```text
Status:
Datum:
```

---

## KORAK 29 — 📄 DOC
### Naslov: DSA čl. 18 interni postopek

**Kaj rešujemo:** Manjka postopek za prijavo suma kaznivega dejanja organom pregona.

**Kaj moraš narediti:** 1-stranski interni postopek.

**Todoist:** `6h3j9qfCPj9VM4Qw`

**Output (izpolni ti):**
```text
Status:
Datum:
```

---

## KORAK 30 — 📄 DOC
### Naslov: DSA čl. 16 notice-and-action preverba

**Kaj rešujemo:** Preveri, ali obstoječi report flow izpolnjuje potrdilo o prejemu + obvestilo o odločitvi.

**Kaj moraš narediti:** Preveri safety.functions.ts reportUser proti čl. 16(4)/(5). Dodaj javno pot brez računa, če manjka.

**Todoist:** `6h3j9qR73JFM6Gmw`

**Output (izpolni ti/AI):**
```text
Status:
Manjkajoče elemente dodano:
```

---

## FAZA E — WEBSITE (po Fazi D)

## KORAK 31 — 🌐 WEB
### Naslov: Objavi DSA Contact Points stran

**Kaj rešujemo:** Kontaktni točki čl. 11/12 morata biti javno dostopni.

**Kaj moraš narediti:** Objavi sekcijo/stran na trembledating.com, EN+SL.

**Todoist:** `6h3j9qQVcqwXQjfP`

**Output (izpolni ti):**
```text
URL:
Datum:
```

---

## KORAK 32 — 🌐 WEB
### Naslov: Objavi slovensko različico ToS (ali popravi klavzulo)

**Kaj rešujemo:** §16 trdi SL izvirnik brez obstoječe SL verzije.

**Todoist:** `6h3jFj7ppxRM7pWP`

**Output (izpolni ti):**
```text
URL SL verzije (če ustvarjena):
Odločitev, če ne:
Datum:
```

---

## KORAK 33 — 🌐 WEB
### Naslov: Cookie consent banner za PostHog

**Kaj rešujemo:** Če PostHog nastavlja ne-nujne piškotke, je potreben opt-in banner.

**Preveri pred izvedbo:** Korak 6 Output = aktiven?

**Todoist:** `6h3jFj2jfrw6VmVP`

**Output (izpolni ti):**
```text
Status (izvedeno / ni potrebno):
Datum:
```

---

## KORAK 34 — 🌐 WEB
### Naslov: Objavi DPO kontakt (če imenovan)

**Preveri pred izvedbo:** Korak 5 Output = imenujem DPO?

**Output (izpolni ti):**
```text
Status (izvedeno / ni potrebno):
URL:
```

---

## FAZA F — STORE DEKLARACIJE (po Fazi A, lahko vzporedno s Fazo D/E)

## KORAK 35 — 🧑‍⚖️ FOUNDER
### Naslov: Apple Privacy Nutrition Labels + Google Play Data Safety

**Kaj rešujemo:** Morata točno odražati dejansko zbiranje, vključno s spolno usmerjenostjo in razkritjem matchu (odvisno od Koraka 2).

**Preveri pred izvedbo:** Koraki 1, 2, 3 morajo biti zaključeni — potrebuješ končno stanje kategorij.

**Todoist:** `6h3p8gg65JvGh8Ww`

**Output (izpolni ti):**
```text
Apple Privacy Labels izpolnjeno (da/ne):
Play Data Safety izpolnjeno (da/ne):
Datum:
```

---

## KORAK 36 — 🧑‍⚖️ FOUNDER
### Naslov: Preveri Sign in with Apple + in-app account deletion vizualno

**Todoist:** `6h3p8ghgxjG93xpP`

**Output (izpolni ti):**
```text
Oba gumba vidna in delujeta (da/ne):
```

---

## FAZA G — FINALNI BUILD IN VERIFIKACIJA

## KORAK 37 — 🤖 CODE
### Naslov: Nov iOS + Android build z vsemi popravki

**Preveri pred izvedbo:** Koraki 7–20, 22 zaključeni.

**Output (izpolni AI):**
```text
Build number iOS:
Build number Android:
flutter analyze / test rezultat:
```

---

## KORAK 38 — 🧑‍⚖️ FOUNDER
### Naslov: Re-registracija testnih računov + poln profil

**Output (izpolni ti):**
```text
Datum:
Oba računa izpolnjena do 3+ ujemajočih hobijev (da/ne):
```

---

## KORAK 39 — 🧑‍⚖️ FOUNDER + 🤖 CODE
### Naslov: Live scanProximityPairs smoke test

**Output (izpolni ti/AI):**
```text
Rezultat (proximity_events zapis potrjen, pairsNotified vrednost):
```

---

## KORAK 40 — 🧑‍⚖️ FOUNDER
### Naslov: Potrdi Korak 0 (Play Console) odobren

**Output (izpolni ti):**
```text
Odobreno (da/ne, datum):
```

---

## KORAK 41 — 🧑‍⚖️ FOUNDER
### Naslov: Submit v App Store / Play Store

**Output (izpolni ti):**
```text
Datum oddaje iOS:
Datum oddaje Android:
Status review:
```

---

## KORAK 42 — Vrni ta dokument Claude-u
Priloži izpolnjen plan + nov ZIP kode. Vprašanje: je Tremble pripravljen za launch?

---

## PO LAUNCHU — priporočeno, ne blokira (opcijsko izvedi po zgornjih 42 korakih)
- PII redaction sweep v CF logih (`6h3grJ2fC632cmxw`)
- Zod `.strict()` na vse onCall sheme (`6h3grJ6RcvMpmMpP`)
- MCP prod dostop test (`6h3Vg3PxfhH77MGP`)
- Branch protection na main (Martin)
- App Check fail-open na typo hardening
- 228 hardcoded hex → tokeni
- DMCA designated agent (`6ggJRF9g3WXp6fqw`), ko greš na US trg