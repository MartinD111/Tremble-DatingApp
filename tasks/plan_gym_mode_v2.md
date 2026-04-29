# Plan: F10 — Nadgradnja Gym Moda (Dvojna logika)

**Plan ID:** 20260429-gym-mode-refinements  
**Risk Level:** MEDIUM  
**Founder Approval:** NO (Logika na vrhu obstoječih funkcij)  
**Branch:** feature/gym-mode-refinements  

---

## 1. OBJECTIVE
Uvesti dvojno logiko aktivacije Gym Moda:
1. **Avtomatska zaznava + obvestilo:** Obvestilo po 10 minutah zadrževanja v radiusu fitnesa.
2. **Ročna aktivacija:** Preko dumbbell ikone s pojavnim dialogom.
Zagotoviti ustrezen onboarding korak ob prvem vnosu lokacije in trajno nastavitev v meniju.

---

## 2. SCOPE
- **Spremenjene datoteke:**
  - `lib/src/features/profile/presentation/edit_profile_screen.dart` (ali onboarding flow za vnos fitnesa)
  - `lib/src/features/settings/presentation/settings_screen.dart` (nov toggle)
  - `lib/src/core/background_service.dart` (ali ustrezna background geofence logika)
  - `lib/src/features/dashboard/presentation/home_screen.dart` (dumbbell ikona)
- **Brez sprememb:** Že implementirane backend Cloud funkcije (`onGymModeActivate`, `onGymModeDeactivate`).

---

## 3. STEPS

### Step 1: Onboarding / Prvi vnos lokacije fitnesa
- Ob prvem vnosu lokacije za gym prikaži privlačen GlassCard dialog: *"Te obvestimo ob prihodu v fitnes?"*
- Možnosti: *Omogoči* / *Zavrni*.
- V Firestore profil uporabnika shrani polje `gymNotificationsEnabled` (boolean).

### Step 2: Nastavitve (Settings Screen)
- V nastavitve aplikacije dodaj preklopni gumb (Switch) za polje `gymNotificationsEnabled`.
- Nastavitev mora biti vedno dostopna za naknadne spremembe.

### Step 3: Background Dwell Timer (10 min)
- Prilagodi geofence oz. background location servis:
  - Ko uporabnik vstopi v radius fitnesa (200m) IN je `gymNotificationsEnabled == true`:
  - Sproži timer za 10 minut.
  - Če uporabnik po 10 minutah še vedno ostaja znotraj radiusa, pošlji lokalno push obvestilo: *"Si v [Ime Fitnesa]. Vklopiš Gym Mode?"*

### Step 4: Ročna aktivacija (Dumbbell ikona)
- Če je obveščanje zavrnjeno (ali uporabnik želi ročni vklop), deluje zgolj zaznava lokacije brez obvestil.
- Ob kliku na dumbbell ikono v dashboardu se prikaže prijazen GlassCard pojavni dialog: *"Ali želiš aktivirati gym mode?"*
- Ob potrditvi se sproži obstoječi `onGymModeActivate` klic.

---

## 4. RISKS & TRADEOFFS
- **Battery drain:** Dwell timer v ozadju zahteva previdnost pri intervalih preverjanja lokacije.
- **State sync:** Nastavitev mora biti pravilno sinhronizirana med lokalnim stanjem in Firestore bazo.

---

## 5. VERIFICATION
- [ ] **UAT 1:** Test onboarding dialoga ob shranjevanju fitnesa.
- [ ] **UAT 2:** Simulacija 10 min bivanja v fitnesu (z vklopljenimi obvestili) -> Prejem push-a.
- [ ] **UAT 3:** Klik na dumbbell -> Prikaz dialoga *"Ali želiš aktivirati gym mode?"*.
- [ ] Zagon `flutter analyze` brez napak.
