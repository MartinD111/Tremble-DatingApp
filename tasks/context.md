## Session State — 2026-05-09
- Active Task: iOS Physical Device Deployment
- Environment: Dev
- Modified Files: ios/Runner.xcodeproj/project.pbxproj, ios/Runner/AppDelegate.swift
- Open Problems: None for deployment. LEGAL (Blocks RevenueCat)
- System Status: Build passing / Device deployment ready

## Session Handoff
- Completed:
    - Added dev and prod flavors to Xcode Build Configurations.
    - Updated Ruby script to dynamically manage Firebase config per flavor.
    - Synchronized all iOS target Bundle Identifiers (Runner, ImageNotification, TrembleRadarWidgetExtension) for dev provisioning profiles (`com.pulse.dev.aleks`).
    - Resolved Swift compiler errors in `AppDelegate.swift` for `CFNotificationName`.
- In Progress: iOS Physical Device Testing
- Blocked: None for current task.
- Next Action: Run application on physical device and test Radar / Gym Mode.
