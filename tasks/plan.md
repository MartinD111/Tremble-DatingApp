# Plan ID: 20260424-UI-Icon-Stability
Status: ✅ COMPLETE (2026-04-24)
Risk Level: LOW
Branch: main

1. OBJECTIVE — Fix broken launcher icons (monochrome), polish splash, fix radar pulse, matches title overlap, and remove tab scale animation.
2. SCOPE — `flutter_launcher_icons.yaml`, `radar_painter.dart`, `matches_screen.dart`, `home_screen.dart`, Android/iOS icon assets
3. STEPS — All complete:
    - BUILD-001: notification_service.dart const DarwinInitializationSettings fix (6cff719)
    - BUILD-002: proximity.functions.ts imageUrl key + haversineDistance removal (6cff719)
    - SPLASH-001: Replace white transparent splash source with rose icon at 50% canvas (aee4c18)
    - ICONS-001: Fix launcher icons — full-color source for image_path, padded rose for adaptive foreground (887abe3)
    - RADAR-001: maxRadius 0.45 → 0.5 (887abe3)
    - MATCHES-001: Padding(horizontal: 100) on title to prevent button overlap (887abe3)
    - ANIM-001: Remove ScaleTransition from AnimatedSwitcher, fade-only at 200 ms (887abe3)
4. VERIFICATION — flutter analyze: 0 issues. flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev: ✅
5. NEXT — Phase 10 TASK-10-03: Framing & Metadata. Run: `/gsd:execute-phase 10`

---

# Previous Plan: 20260418-security-ui-polish
Status: ✅ COMPLETE (2026-04-21)
Risk Level: MEDIUM
Branch: feature/security-ui-polish (merged main)

Objective: Enforce Firebase App Check + registration UI repair + i18n cleanup.
All phases complete. See lessons.md Rules #15–#34, debt.md D-36–D-38.
