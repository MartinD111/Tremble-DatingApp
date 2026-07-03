# ADR-005: iOS Rich Push Implementation (Notification Service Extension)

## Status
Accepted

## Context
Tremble relies on push notifications to signal user interactions ("Waves"). To improve UX and align with the "Rich Interface" requirement, we need to display the sender's profile photo directly in the notification tray on iOS. By default, iOS cannot display remote image URLs in notifications without an extension.

## Decision
We have implemented an **iOS Notification Service Extension** named `ImageNotification`.

## Details
- **Logic**: The extension intercepts incoming FCM notifications, downloads the image from the `fcm_options.image` URL, and attaches it as a `UNNotificationAttachment`.
- **Targeting**: A separate native target has been added to the Xcode project with its own `Bundle ID` (`com.pulse.ImageNotification` and `tremble.dating.app.ImageNotification`).
- **Target SDK**: iOS 15.0 to match the main Runner app.

## Consequences
- **Build Complexity**: `pod install` must now manage a separate target for the extension.
- **Xcode project**: `objectVersion` in `project.pbxproj` is fixed at **63** for compatibility across build environments.
- **Testing**: Requires physical hardware for verification as the iOS Simulator has limited support for Notification Extensions.
