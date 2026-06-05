# Tremble — The Proximity Discovery Experience

Tremble is a next-generation mobile platform engineered by **AMS Solutions d.o.o.** It focuses on high-fidelity proximity matching, designed to bridge the gap between digital discovery and real-world interaction through a "tool-first" philosophy.

---

## 🎯 Vision

The current dating landscape is saturated with endless digital noise and low-intent communication. Tremble is built on the principle of **Intentional Presence**. It minimizes screen time and prioritizes physical activity, facilitating real-life connections that happen naturally while you live your life.

## ✨ Core Mechanics

*   **Activity-Based Discovery:** Purpose-built modes for **Run Club** and **Gym Mode** that adapt the app's behavior to your environment and focus.
*   **The "Momentum" Rule:** A strict 10-minute Window of Action (TTL). High-intent signals are ephemeral; you either act in the moment or the opportunity is moved to history.
*   **Silent Interaction:** During physical activities (like running), Tremble stays in the background, protecting your focus while silently logging potential matches for a post-activity **Recap**.
*   **Dynamic Recap UI:** A high-performance, glassmorphic summary of active opportunities and a historical log of missed encounters.
*   **Tiered Transparency:** Profile visibility respects user subscription levels, ensuring a premium experience for dedicated users while maintaining privacy.

## 🛠️ Technology

Tremble is built using a modern, scalable stack designed for global performance:
*   **Frontend:** Cross-platform Flutter implementation with Riverpod state management.
*   **Backend:** Firebase Auth, Firestore, Cloud Functions in `europe-west1`, Cloudflare R2 avatar storage, Upstash Redis, and Resend email.
*   **Intelligence:** Agentic development orchestration, ensuring rapid deployment and extreme code reliability.

## 🚦 Development

This repository is governed by MPC. Read `tasks/context.md` and `tasks/blockers.md` before code changes.

Run the app with the checked-in Dart define file:

```bash
flutter run --dart-define-from-file=.env.json
```

Local commits should pass `.git/hooks/pre-commit`, which runs Flutter format, analyze, tests with `FLAVOR=dev`, and backend lint/build/tests.

## Local Setup — Required Files

The following files are gitignored and must be obtained separately before the project compiles:

- lib/src/core/firebase_options_dev.dart  → generate with: flutterfire configure --project=tremble-dev
- lib/src/core/firebase_options_prod.dart → generate with: flutterfire configure --project=am---dating-app
- android/app/google-services.json        → download from Firebase console (tremble-dev or am---dating-app)
- ios/Runner/GoogleService-Info.plist      → download from Firebase console

Without these files, flutter run will fail with import errors.

## 🔒 Security & Privacy

We take user privacy seriously. Tremble utilizes localized on-device processing (Native Motion Services) for activity detection. Encounter summaries are scoped and minimized, F12 interactions expire after 10 minutes, and the product follows a zero-chat policy: no free-text chatrooms.

---

© 2026 **AMS Solutions d.o.o.** All rights reserved.
