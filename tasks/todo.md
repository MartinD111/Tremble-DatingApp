# Tremble - Production Tasks

## Phase 9: Monitoring & Release (Pending)
- [ ] Enable Crashlytics in Firebase Console
- [ ] Register iOS/Android apps in Firebase AppCheck console
- [ ] Enable AppCheck enforcement
- [ ] Set Production Firebase secrets: `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `RESEND_API_KEY`
- [ ] Prepare Production release checklist

## Subagent / Parallel Tasks (To Delegate)
- [x] Verify iOS build compiles locally (requires CocoaPods/Xcode setup check)
- [ ] Verify Android build compiles locally
- [ ] Code review of Cloud Functions for any missed security gaps before production

## Phase 1: Discovery (Current)
- [x] Align with Product Owner on exact V1 launch features
- [x] Outline outstanding dependencies (Apple Dev Account, Play Console, Domain)
- [ ] Create a separate "Dev" Firebase Project to protect Prod data
- [ ] Set up simple landing page for Privacy Policy & GDPR on the purchased domain
