import WidgetKit
import SwiftUI

// MARK: - Shared State
/// Access radar state from App Group UserDefaults (shared with main app)
struct RadarStateManager {
  private static let appGroup: String = {
    #if FLAVOR_DEV
      return "group.com.pulse.radar"
    #else
      return "group.tremble.dating.app.radar"
    #endif
  }()

  private static let key = "radarActive"

  static var isActive: Bool {
    get {
      let defaults = UserDefaults(suiteName: appGroup) ?? UserDefaults.standard
      return defaults.bool(forKey: key)
    }
    set {
      let defaults = UserDefaults(suiteName: appGroup) ?? UserDefaults.standard
      defaults.set(newValue, forKey: key)
      defaults.synchronize()
      // Notify main app via Darwin notification
      CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName("app.tremble.radar.changed" as NSString),
        nil,
        nil,
        true
      )
      // Reload widget
      WidgetCenter.shared.reloadAllTimelines()
    }
  }
}

// MARK: - App Intent (Lock Screen Widget Toggle)
struct RadarToggleIntent: AppIntent {
  static var title: LocalizedStringResource = "Toggle Radar"
  static var openAppWhenRun = false

  func perform() async throws -> some IntentResult {
    RadarStateManager.isActive = !RadarStateManager.isActive
    return .result()
  }
}

// MARK: - Timeline Entry
struct RadarEntry: TimelineEntry {
  let date: Date
  let isActive: Bool
}

// MARK: - Timeline Provider
struct RadarProvider: TimelineProvider {
  func placeholder(in context: Context) -> RadarEntry {
    RadarEntry(date: Date(), isActive: false)
  }

  func getSnapshot(in context: Context, completion: @escaping (RadarEntry) -> Void) {
    let entry = RadarEntry(date: Date(), isActive: RadarStateManager.isActive)
    completion(entry)
  }

  func getTimelines(completion: @escaping (Timeline<RadarEntry>) -> Void) {
    let entry = RadarEntry(date: Date(), isActive: RadarStateManager.isActive)
    // Single entry; reload when main app changes state
    let timeline = Timeline(entries: [entry], policy: .never)
    completion(timeline)
  }
}

// MARK: - Widget Views
struct RadarWidgetEntryView: View {
  var entry: RadarProvider.Entry

  var body: some View {
    ZStack {
      // Background
      ContainerRelativeShape()
        .fill(Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.12, alpha: 1) : UIColor(white: 0.96, alpha: 1) }))

      // Content
      VStack(spacing: 0) {
        // Lock screen (accessory families)
        if #available(iOSApplicationExtension 16.1, *) {
          accessoryContent
        } else {
          // Fallback for iOS 16.0
          standardContent
        }
      }
    }
  }

  @ViewBuilder
  private var accessoryContent: some View {
    Button(intent: RadarToggleIntent()) {
      ZStack {
        // Outer ring
        Circle()
          .fill(Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.2, alpha: 1) : UIColor(white: 0.9, alpha: 1) }))

        // Inner circle with icon
        Circle()
          .fill(entry.isActive ? Color(#colorLiteral(red: 0.957, green: 0.263, blue: 0.424, alpha: 1.0)) : Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.4, alpha: 1) : UIColor(white: 0.7, alpha: 1) }))
          .padding(3)

        Image(systemName: "dot.radiowaves.left.and.right")
          .font(.system(size: 10, weight: .semibold))
          .foregroundColor(.white)
      }
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private var standardContent: some View {
    // Home screen widget (systemSmall for iOS 16.0)
    VStack(spacing: 8) {
      Image(systemName: "dot.radiowaves.left.and.right")
        .font(.system(size: 20, weight: .semibold))
        .foregroundColor(entry.isActive ? Color(#colorLiteral(red: 0.957, green: 0.263, blue: 0.424, alpha: 1.0)) : Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.4, alpha: 1) : UIColor(white: 0.7, alpha: 1) }))

      Text(entry.isActive ? "Radar On" : "Radar Off")
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.9, alpha: 1) : UIColor(white: 0.1, alpha: 1) }))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .containerBackground(for: .widget) {
      Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.12, alpha: 1) : UIColor(white: 0.96, alpha: 1) })
    }
  }
}

// MARK: - Widget Definition
struct TrembleRadarWidget: Widget {
  let kind: String = "TrembleRadarWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: RadarProvider()) { entry in
      RadarWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Radar Toggle")
    .description("Quick access to turn your radar on or off")
    .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
  }
}

// MARK: - Widget Bundle
@main
struct TrembleRadarWidgetBundle: WidgetBundle {
  var body: some Widget {
    TrembleRadarWidget()
  }
}
