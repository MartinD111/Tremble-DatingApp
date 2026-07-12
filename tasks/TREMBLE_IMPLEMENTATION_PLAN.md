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
Odločitev: IMPLEMENTIRAJ ENFORCEMENT
Razlog: ker ne zelijo si vsi monthly memberships. postaja trend glede sovraztva za take stvari. nekateri bi rajši kupili 4x in preplačali but have control over it. mental game. a tudi časovno mora biti omejeno, ker ne greš ga žurati v petek ob 10am, ampak popoldne. tko da, it is what it is.
Datum: 10.07.2026
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
Odločitev: ZAČASNO NI OBVEZEN, glede na trenutni obseg (TestFlight Family+Friends,
<50 uporabnikov, ni javni launch). Pravna utemeljitev: prag "velikega obsega" po čl.
37(1)(b)/(c) verjetno ni dosežen pri trenutnem obsegu. TA ODLOČITEV JE ZAČASNA in mora
biti ponovno ocenjena pred javnim App Store/Play launchom, ko se obseg bistveno poveča.
Ni še formalno pravno potrjeno — Gemini prvi prehod, ne pravno mnenje.
Datum: 10.07.2026
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
PostHog aktiven: NE - nikakor da ga uspešno vzpostavim, tako da for now ne bo, ker ni nujen in ni še prioriteta.
Datum: 10.07.2026
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
Status: IZVEDENO in verificirano end-to-end. activateWeekendPass (edini write-site) že
kliče getNextWeekendWindow — Tuesday aktivacija shrani Fri19:00/Sun19:00, ne Tuesday+48h.
Ni bilo neusklajenega drugega writerja (RevenueCat/webhook še ne obstaja). Zabeleženo
kot memory za prihodnost: ko se doda plačilni entitlement layer, mora iti skozi isto
funkcijo, ne inline izračun.
Datoteke spremenjene: functions/src/modules/subscriptions/subscriptions.functions.ts
Testi: 10/10 novih + 77/77 skupaj
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

Tukaj so novi koraki za `TREMBLE_IMPLEMENTATION_PLAN.md`, v istem formatu kot obstoječi (43–50). Prilepi jih na konec, pred "PO LAUNCHU" sekcijo. Todoist taski so že ustvarjeni — vsak korak spodaj navaja svoj ID.

Glede buildov: če je Claude Code trdil, da je dal nov build, ko si mu povedal, da je star — to je njegova trditev, ne dokaz. Standard iz tvojih lastnih pravil ("agent self-reports require evidence") velja tudi tu. 400 na `updateProfile` z obeh platform ni dokaz, da build ni bil posodobljen — je lahko tudi star cache na napravi ali star Play/TestFlight release, ki še ni prišel skozi. Zato Korak 46 spodaj ni "ali si mu verjel", ampak konkreten grep/version-code preverbeni korak, ki traja 5 minut in zapre vprašanje enkrat za vselej.

---

## KORAK 43 — 🤖 CODE + 🧑‍⚖️ FOUNDER
### Naslov: Popravi stopBilling CF — billing kill-switch trenutno nefunkcionalen

**Kaj rešujemo:** Prod logi (11 jul) kažejo, da `stop-billing-10eur` crashira s `TypeError: Buffer.from(undefined)` na vsakem budget Pub/Sub sporočilu. Funkcija je pisana za gen1 background signature, deployana pa je kot CloudEvent (gen2) — payload je v `cloudEvent.data.message.data`, ne v `event.data`. Ker crashira pred parsiranjem, nikoli ne pride do primerjave stroškov z budgetom. Tvoj €10 kill-switch je popolnoma neaktiven.

**Kaj mora AI narediti:** Ta funkcija ni v repozitoriju — deployana je ročno prek GCP Console/gcloud, zato ni nič za Claude Code, dokler je ne prenesete v repo. Za zdaj: ročen deploy popravljene kode.

**Prompt (za Claude Code, ko dodaš funkcijo v repo pod `functions/src/scripts/stop-billing/`):**
```
V Tremble Firebase Functions projektu (functions/ folder, MartinD111/Tremble-DatingApp):

## Task
Prenesi obstoječo ročno deployano Cloud Function `stop-billing-10eur` (Pub/Sub trigger na
topic projects/am---dating-app/topics/budget-limit-reached) v repo pod
functions/src/scripts/stop-billing/index.ts, in popravi CloudEvent parsing bug.

## Context
Funkcija je pisana za gen1 background function signature (event.data = base64 string).
Deployana je kot gen2 CloudEvent function, kjer je pravi payload na
cloudEvent.data.message.data. Trenutno crashira na VSAKEM klicu z
TypeError [ERR_INVALID_ARG_TYPE]: Buffer.from(undefined), preden pride do primerjave
costAmount/budgetAmount. Rezultat: billing kill-switch nikoli ne sproži.

## Requirements
- Uporabi @google-cloud/billing SDK, CloudBillingClient
- Handler mora biti: exports.stopBilling = async (cloudEvent) => {...}
- Parsiraj cloudEvent.data.message.data (base64 → JSON), NE event.data
- Če ni data → log + return, ne crashaj
- Primerjaj costAmount z budgetAmount PRED kakršnim koli billing klicem
- Če costAmount <= budgetAmount → return brez akcije
- Šele nad pragom: getProjectBillingInfo → če billingEnabled → updateProjectBillingInfo
  z billingAccountName: '' (odklopi billing)
- Loguj cost/budget vrednosti na vsakem klicu (za observability, brez PII)
- Dodaj test, ki simulira CloudEvent shape in preveri: (a) sub-threshold → no-op,
  (b) over-threshold → billing disable klican, (c) manjkajoč data → no crash

## Restrictions
- Nikoli ne pushaj na main direktno
- Deploy ostane founder-action (glej spodaj), CF koda samo pripravljena za deploy

## Expected Output
Datoteka + test v repu, pripravljena za `firebase deploy --only functions:stopBilling`.
```

**Kaj moraš narediti ti (founder-action, po tem ko je koda pripravljena):**
1. Prenesi popravljeno kodo v GCP Console → Cloud Run functions → `stop-billing-10eur` → Edit source, ali `gcloud functions deploy`.
2. Preveri loge po deployu — pričakuj 200 namesto 500, in izpis `cost=X budget=Y`.
3. Odločitev: je €10 prag še vedno smiseln zdaj, ko aktivno testirate z več napravami? Funkcija ob sprožitvi odklopi billing za **cel** `am---dating-app`, kar ubije vse Cloud Functions sredi testa.

**Pričakovan rezultat:** Kill-switch dejansko deluje; ne crashira; prag potrjen kot nameren.

**Todoist:** `6h4rx2R9clCC3WvxGw`

**Output (izpolni ti):**
```text
Status:Committed cleanly (d580a9c) on feat/stop-billing-cf. Only the untouched TREMBLE_IMPLEMENTATION_PLAN.md from the prior session remains unstaged.

Summary

Branch: feat/stop-billing-cf
Commit: d580a9c feat(functions): add stopBilling CF with fixed CloudEvent parsing

Files:
- functions/src/scripts/stop-billing/index.ts — v2 onMessagePublished handler on topic budget-limit-reached, region europe-west1. Env-driven threshold STOP_BILLING_THRESHOLD_EUR with fallback to notification's budgetAmount.
- functions/src/__tests__/stop-billing.test.ts — 18 tests (sub/at/over threshold, already-disabled billing, env override up/down, missing & broken payload paths).
- functions/src/index.ts — exports stopBilling for firebase deploy --only functions:stopBilling.
- functions/package.json + package-lock.json — added @google-cloud/billing@^5.1.2.

Verification:
- npm run build → clean
- npm test → 10 suites / 95 tests pass (18 new + 77 existing regressions clean)
- eslint on new files → clean
- Flutter pre-commit hook → analyze + tests all pass

What broke in prod that this fixes: The manually-deployed CF used gen1 handler shape (event.data as base64 string) while GCP invoked it as a gen2 CloudEvent (payload at cloudEvent.data.message.data). Buffer.from(undefined) crashed on every alert before the cost/budget compare, so the €10 kill-switch never fired. New handler decodes event.data.message.data, guards every failure mode with a no-op + log, and only calls the Billing API after confirming costAmount > threshold.

What's still on you (founder-action per KORAK 43):
1. Deploy: from functions/, run firebase deploy --only functions:stopBilling (or gcloud). The old stop-billing-10eur will keep crashing until you either delete it or overwrite. Recommend deleting the old CF via GCP Console after the new one is verified — otherwise you have two subscribers on budget-limit-reached.
2. Threshold decision: default is still €10 from the budget config. If you want to raise it during active multi-device testing, set STOP_BILLING_THRESHOLD_EUR env var on the function (Console → Cloud Run → env vars) — no code redeploy needed to change it later.
3. Post-deploy: trigger a test alert (or wait for the next real one) and confirm logs show stopBilling: budget alert received with cost=X threshold=Y instead of a TypeError.

Next: want me to also add a blockers.md entry marking KORAK 43 as "code ready, awaiting deploy", or open a PR?

Datum deploya:
Prag potrjen (da/ne, nova vrednost če spremenjen):
```

---

## KORAK 44 — 🤖 CODE
### Naslov: CROSSING_PATHS notifikacija — arhitekturno nemogoča v ozadju na obeh platformah

**Kaj rešujemo:** Live BLE test (11 jul) je zapisal `proximity_events` dokument, a nihče ni videl vidnega obvestila. To ni test failure — je arhitekturna napaka, potrjena grepom proti kodi:
- Android: `sendCrossingPaths` pošlje data-only FCM (brez `notification` bloka). Data-only sporočilo v ozadju Android sam od sebe ne prikaže ničesar — edina display logika (`_showForegroundNotification`) teče samo v foregroundu.
- iOS: uporablja `apns.alert-body-loc-key`, ki se razrešuje proti native `Localizable.strings` datoteki — ta ne obstaja (samo `InfoPlist.strings`). APNs zato alert tiho zavrže.
- `pairsNotified` se inkrementira ne glede na to, ali je bil push dejansko poslan — metrika je nezanesljiva.

**Kaj mora Codex narediti:**
```
V Tremble projektu (MartinD111/Tremble-DatingApp) popravi arhitekturno napako, zaradi
katere CROSSING_PATHS notifikacija ni nikoli vidna uporabniku v ozadju.

## Task
Odloči in implementiraj eno od dveh arhitektur:
(a) CF pošlje poln FCM notification payload (title/body v jeziku prejemnika iz
    users doc polja `language`), namesto data-only + loc-key
(b) Ostane data-only; Flutter background message handler zgradi lokalno notifikacijo
    prek flutter_local_notifications iz data payloada (konsistentno z obstoječim
    silent-notif vzorcem za Gym/Run mode)

Priporočilo: (a) je enostavnejši in bolj zanesljiv na obeh platformah — brez tega
CF že pozna prejemnikov jezik (users doc), loc-key sistem pa je bil očitno nikoli
testiran end-to-end na napravi.

## Context
functions/src/modules/proximity/proximity.functions.ts, funkcija sendCrossingPaths,
pošilja data-only FCM z apns.alert-body-loc-key: notify_nearby_body_rich. Ta loc-key
se mora razrešiti proti native iOS bundlu (Localizable.strings), ki v ios/Runner ne
obstaja — obstajajo samo InfoPlist.strings datoteke. lib/src/core/notification_service.dart
_showForegroundNotification (vrstica ~358) zahteva message.notification!, kar
pomeni da teče izključno, ko je notification blok prisoten IN app v foregroundu.

## Requirements
- Če izbereš pot (a): CF prevede title/body v users.language (fallback EN), pošlje
  poln notification blok. Odstrani loc-key referenc na iOS strani, če postanejo
  odveč.
- Če izbereš pot (b): implementiraj Android in iOS background message handler,
  ki iz data payloada zgradi lokalno notifikacijo (flutter_local_notifications),
  z enako channel/importance logiko kot obstoječi foreground handler.
- Popravi metriko: pairsNotified naj šteje dejansko uspešne send-e (Promise.allSettled
  rezultate), ne optimistični increment pred pošiljanjem.
- Test: mock FCM send, preveri da notification vsebuje pravilen title/body za
  testni jezik, in da pairsNotified odraža dejanski uspeh/neuspeh.

## Build & restrictions
- flutter test + functions npm test zeleno; tsc čist; flutter analyze 0 issues
- Ne spreminjaj Info.plist brez founder odobritve — nove Localizable.strings
  datoteke so dovoljene, a jasno označi v PR
- Feature branch → PR, naslov [PLAN-ID: 20260712-fix-crossing-paths-visibility],
  telo mora vsebovati "Verification checklist", "unit tests", "integration tests",
  "security scan"

## Files likely affected
functions/src/modules/proximity/proximity.functions.ts
lib/src/core/notification_service.dart
ios/Runner/*.lproj/Localizable.strings (če pot b ali fix loc-key)
test/...

## Expected output
Uporabnik v ozadju (app zaprta ali v Gym/Run modu ustrezno) dejansko vidi push
notifikacijo ob CROSSING_PATHS eventu, na obeh platformah.
```

**Pričakovan rezultat:** Vidna notifikacija deluje na obeh platformah; pairsNotified pove resnico.

**Todoist:** `6h4rx2JH52hFHxQw`

**Preveri pred izvedbo:** Ni odvisen od drugih korakov, lahko teče takoj.

**Output (izpolni AI):**
```text
Izbrana pot (a/b):
Datoteke spremenjene:
Testi:
```

---

## KORAK 45 — 🤖 CODE
### Naslov: Manjkajoč translation key 'prefer_not_to_say'

**Kaj rešujemo:** UI prikazuje surov ključ `prefer_not_to_say` namesto prevoda — ključ ne obstaja v `translations.dart` v nobenem locale, klicano pa je iz `religion_step.dart` in `ethnicity_step.dart`.

**Prompt:**
```
V lib/src/core/translations.dart dodaj manjkajoč ključ 'prefer_not_to_say' v VSE
locale bloke (EN, SL, in ostale obstoječe — preveri točno število blokov z grep pred
in po spremembi, mora se ujemati).

EN: "Prefer not to say"
SL: "Raje ne bi povedal/a"

Za ostale locale (preveri, kateri dejansko obstajajo v datoteki) uporabi smiselni
prevod ali angleški fallback, če prevoda ni na voljo.

Requirements:
- flutter analyze 0 issues, flutter test zeleno
- grep -c "'prefer_not_to_say'" translations.dart pred/po commit sporočilu, da je
  število ključev enako številu locale blokov
- Feature branch → PR, [PLAN-ID: 20260712-fix-prefer-not-to-say-translation],
  telo vsebuje zahtevane fraze
```

**Pričakovan rezultat:** UI prikaže preveden tekst v vseh jezikih.

**Todoist:** `6h4rx2VJmmW7XjHP`

**Output (izpolni AI):**
```text
Status:
Locale-i pokriti:
```

---

## KORAK 46 — 🧑‍⚖️ FOUNDER
### Naslov: Neodvisno potrdi verzijo builda na obeh testnih napravah (ne zaupaj agentovi trditvi)

**Kaj rešujemo:** Claude Code je trdil, da je bil nov build deployan, ko si opozoril na star build. To je njegova trditev — evidence standard iz tvojih lastnih pravil zahteva grep/log/screenshot dokaz, ne agentovo besedo. `updateProfile` 400 na obeh platformah (Android IN iOS) med live testom je signal, ki mu je vredno slediti do dna, ne prezreti.

**Kaj moraš narediti:**
1. **Android**: Nastavitve telefona → Aplikacije → Tremble → preveri version/build number v app info, ALI v aplikaciji sami (Settings screen, če obstaja verzija). Primerjaj z versionCode iz zadnjega AAB builda (67.8MB, `e99e41c`). Play Console → Internal testing → Release → preveri točen versionCode objavljenega releasa.
2. **iOS**: TestFlight app na iPhonu → Tremble → preveri "Build" številko na dnu. Mora pisati **15**, ne 14. Če piše 14, App Store Connect processing ni zaključen ali ni bil dodan v External skupino.
3. Če je verzija pravilna na obeh, a je 400 vseeno prišel: to pomeni bug v novi kodi (regresija strict scheme na legitimnem novem clientu) — drugačen in resnejši problem, ker bi pomenilo da tudi pravi novi uporabniki ne morejo posodobiti profila. Preveri natančno request body iz loga (`requestSize: 4805` za updateProfile 09:46:43 — kaj je bilo v njem, ki ga je Zod zavrnil).
4. Če je verzija napačna: force-update / reinstall prek pravega internal testing / TestFlight linka, ne prek starega APK-ja na disku.

**Pričakovan rezultat:** En trden odgovor — je bil problem stara naprava ali nova regresija — z verzijsko številko kot dokazom, ne s "Claude je rekel".

**Todoist:** `6h4rx2M8RfPF9QmP`

**Output (izpolni ti):**
```text
Android version code na napravi:
Android version code v Play Console release:
iOS TestFlight build number na napravi:
Ujemanje (da/ne):
Če ne ujema: akcija izvedena:
Če ujema, a 400 vseeno: root cause najden:
```

---

## KORAK 47 — 🧑‍⚖️ FOUNDER
### Naslov: R2 + Redis čiščenje po ročnem brisanju računov (Firebase Console delete ne pokrije vsega)

**Kaj rešujemo:** Console "Delete account" briše samo Firebase Auth zapis in karkoli si ročno počistil v Firestore. Ne sproži `deleteUserAccount` Cloud Function, ki bi počistila R2 fotografije in Redis ključe. Za štiri izbrisane račune (Aleksandar, Martin, wyattminer, lyndahart) sta bila 11. jul ob 11:46 dokazano generirana presigned upload URL-ja in fotografiji dejansko uploadani v R2.

**Kaj moraš narediti:**
1. Cloudflare dashboard → R2 → `media.trembledating.com` bucket → poišči in izbriši prefixe `users/{uid}/` za vse 4 UID-je:
   - `sxkX6dMYD2XLzSxUvSV7bGACgwH3`
   - `wjpkaTKNOuNyQ9FKAJjAFS5ZpjE3`
   - `z3jMpBhXS3gHOThW6uYR91Z...` (dokončaj UID iz Firebase Console screenshotov, ki so bili predhodno vidni)
   - `dK5MfsZi6oVf5CykywBWGaV...` (isto)
2. Upstash Redis dashboard → preveri, ali obstajajo `encounter_count:*` ključi za te uparjene UID-je (90-dnevni TTL, ne bodo izginili sami). Po potrditvi, da ni drugih aktivnih testnih podatkov, razmisli o `FLUSHDB` na dev/test namespace.
3. Firestore Console → ročno preveri prazne kolekcije: `users`, `proximity`, `proximity_events`, `waves`, `matches`, `rateLimits`, `notifications`.

**Zakaj je to pomembno, ne samo pospravljanje:** trditev "kot da se je zgodil GDPR delete" mora dejansko pomeniti popoln delete. Delna izbrisa (Firestore da, R2 ne) je natanko vrsta razkoraka med izjavo in stanjem, ki ga tvoj lastni compliance report iz 6. julija označuje kot oteževalno okoliščino pri regulatornem pregledu — ista logika, drug primer.

**Todoist:** `6h4rx2WHvf5728Xw`

**Output (izpolni ti):**
```text
R2 prefixi izbrisani (4/4 da/ne):
Redis preverjen (da/ne):
Firestore kolekcije potrjeno prazne (da/ne):
Datum:
```

---

## KORAK 48 — 🧑‍⚖️ FOUNDER (Martin)
### Naslov: GitHub Environment "founder-approval" — branch protection ni dovolj

**Kaj rešujemo:** Screenshot potrjuje, da je branch protection rule na `main` zdaj ustvarjena. To je ločeno od CI gate ⑦ "Founder Approval", ki referencira GitHub Environment z imenom `founder-approval` — ta environment ne obstaja. Dokler ne obstaja z nastavljenim required reviewerjem, GitHub izvede job brez zaščite (auto-pass) za vsak PR, ne glede na tveganje. Branch protection sama po sebi tega ne popravi — je drug mehanizem.

**Kaj mora Martin narediti (potreben je Owner dostop, ki ga Aleksandar nima):**
1. GitHub repo → Settings → Environments → New environment → ime točno `founder-approval` (ujemati se mora s tem, kar `ci.yml` referencira).
2. V nastavitvah environmenta: Required reviewers → dodaj Martin in/ali Aleksandar.
3. Preveri v `.github/workflows/ci.yml`, da job ⑦ dejansko cilja `environment: founder-approval` (ime mora biti eksaktno enako).

**Dodatno, nujno preveriti (glej Korak 49 spodaj):** main HEAD je pokazal 3/8 zelenih checkov kmalu po tem, ko je bila branch protection nastavljena. To je nenavadno — ali gre za isti "chore: coverage" avtomatski commit vzorec, ki se je že pojavil prej (glej memory), ali za nekaj novega.

**Todoist:** `6h4mGfW5FjMhvGmw` (obstoječ task, dodan komentar 11. jul)

**Output (izpolni Martin/ti):**
```text
Environment "founder-approval" ustvarjen (da/ne):
Required reviewer nastavljen (kdo):
ci.yml referenca potrjena ujemanje (da/ne):
Datum:
```

---

## KORAK 49 — 🤖 CODE (preiskava, ne fix)
### Naslov: Zakaj main HEAD kaže 3/8 checkov kmalu po branch protection setupu

**Kaj rešujemo:** Screenshot GitHub Branches strani kaže main na 3/8 check status, timestamp ~49 minut pred zajemom, kmalu po tem ko je branch protection rule nastavljena. Če je branch protection dejansko aktivna in zahteva vseh 8 checkov, ne bi smelo biti mogoče, da nekaj s 3/8 pristane na main — razen če (a) protection ne zahteva vseh 8 kot "required", samo prikazuje status, ali (b) je šlo za direct push pred aktivacijo pravila, ali (c) gre za znan vzorec avtomatskih "chore: coverage" commitov, ki so se v preteklosti že pojavili z isto značilnostjo (padli CI).

**Prompt:**
```
V repozitoriju MartinD111/Tremble-DatingApp preišči zadnji commit na main:

git log -1 --format="%H %an %ae %s %ci" main
git show --stat HEAD

Nato preveri branch protection konfiguracijo prek GitHub API ali UI:
- Kateri checki so označeni kot "required" v protection rule za main?
- Je "Require branches to be up to date before merging" vklopljeno?
- Je "Include administrators" vklopljeno (če ne, lahko Owner/Admin obide pravilo)?

Primerjaj s prejšnjim znanim vzorcem: 4 zaporedni avtomatski "chore: coverage"
commiti direktno na main, 3/4 s padlim CI (omenjeno v prejšnji seji, vir ni bil
identificiran). Ugotovi, ali je zadnji commit tega tipa.

Poročaj: avtor commita, ali je šel skozi PR ali direct push, kateri checki so
manjkali/padli, in ali branch protection rule dejansko blokira te primere ali ne.
Ne popravljaj ničesar — samo diagnoza.
```

**Pričakovan rezultat:** Jasen odgovor, ali je nova branch protection dejansko efektivna, ali ima isto luknjo kot prej.

**Todoist:** *(ni še ustvarjen — ustvarim, ko potrdiš prioriteto; naravno se navezuje na 6h4mGfW5FjMhvGmw)*

**Output (izpolni AI):**
```text
Zadnji commit avtor:
Pot na main (PR / direct push):
Required checks v protection rule:
Include administrators (da/ne):
Diagnoza:
```

---

## KORAK 50 — 🧑‍⚖️ FOUNDER
### Naslov: Preveri, ali so "random računi" Google pre-launch report boti

**Kaj rešujemo:** Štirje neznani računi (`wyattminer.16607@gm...`, `martin.dumanic@gmail...` — pozor, to je verjetno Martin sam, ne bot, `lyndahart.02127@gmai...`, in tvoj) v Firebase Authentication. Google Play avtomatsko poganja pre-launch report bote na vsak internal/closed testing upload — prijavijo se z generičnimi testnimi Google računi in crawlajo app. Vzorec imen (naključno ime + številke) je konsistenten s tem. Ni nujno vdor, ampak potrjuje pomembnejšo stvar: neznani (tudi če so boti) so uspešno prišli skozi celoten registracijski flow na produkciji.

**Kaj moraš narediti:**
1. Play Console → tvoj app → Release → Testing → Pre-launch reports → preveri, ali je report tekel okoli 11. jul, in ali se UID-ji/imena ujemajo.
2. Če se ujemajo: potrjeno kot pričakovano Google vedenje, brez nadaljnje akcije razen tega, da se zavedaš, da je prod dostopen komurkoli z linkom do internal testing (to je po designu za internal testing, a vredno je vedeti).
3. Če se NE ujemajo: eskaliraj — to bi pomenilo, da je nekdo zunaj tvojega testerskega kroga našel in registriral na produkcijski app pred javnim launchom.

**Todoist:** *(founder-only preverba, ni potreben avtonomen task — če eskalira v točko 3, ustvari nov p1 task)*

**Output (izpolni ti):**
```text
Pre-launch report najden za ta datum (da/ne):
UID-ji ujemanje (da/ne):
Zaključek:
```