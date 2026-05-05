import WidgetKit
import SwiftUI
import AppIntents

/// The AppIntent that handles the radar toggle from the lock screen or home screen widget.
/// Updates the shared RadarStateBridge and triggers a widget timeline refresh.
@available(iOS 17.0, *)
struct RadarToggleIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Radar"
    static var description = IntentDescription("Turns the proximity radar on or off.")

    func perform() async throws -> some IntentResult {
        // Toggle the state in shared UserDefaults via the bridge
        RadarStateBridge.isActive = !RadarStateBridge.isActive
        
        // Refresh the widget timeline so the UI updates immediately
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
    }
}

struct RadarEntry: TimelineEntry {
    let date: Date
    let isActive: Bool
}

struct RadarTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> RadarEntry {
        RadarEntry(date: Date(), isActive: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (RadarEntry) -> ()) {
        let entry = RadarEntry(date: Date(), isActive: RadarStateBridge.isActive)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = RadarEntry(date: Date(), isActive: RadarStateBridge.isActive)
        // We don't need periodic refreshes; RadarStateBridge.isActive setter 
        // and RadarToggleIntent will trigger manual reloads.
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct TrembleRadarWidgetView: View {
    var entry: RadarEntry

    var body: some View {
        VStack(spacing: 8) {
            // Radar Icon with Pulse effect
            ZStack {
                Circle()
                    .fill(Color(hex: "F4436C").opacity(entry.isActive ? 0.2 : 0.05))
                    .frame(width: 44, height: 44)
                
                if entry.isActive {
                    Circle()
                        .stroke(Color(hex: "F4436C").opacity(0.5), lineWidth: 1)
                        .frame(width: 54, height: 54)
                }
                
                Image(systemName: entry.isActive ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "F4436C"))
            }
            
            Text(entry.isActive ? "Radar On" : "Radar Off")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .containerBackground(for: .widget) {
            Color.clear // Uses system default or parent background
        }
    }
}

@main
struct TrembleRadarWidget: Widget {
    let kind: String = "TrembleRadarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RadarTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                Button(intent: RadarToggleIntent()) {
                    TrembleRadarWidgetView(entry: entry)
                }
                .buttonStyle(.plain)
            } else {
                TrembleRadarWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Tremble Radar")
        .description("Quickly toggle your proximity radar.")
        .supportedFamilies([.accessoryCircular, .systemSmall])
    }
}

// MARK: - Helpers
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
