import WidgetKit
import SwiftUI

struct RadarEntry: TimelineEntry {
    let date: Date
    let isActive: Bool
}

struct RadarTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> RadarEntry {
        RadarEntry(date: Date(), isActive: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (RadarEntry) -> ()) {
        let entry = RadarEntry(date: Date(), isActive: true)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = RadarEntry(date: Date(), isActive: true)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct TrembleRadarWidgetView: View {
    var entry: RadarEntry

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [Color(hex: "1A1A18"), Color(hex: "2A2A28")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Radar Pulse Circles
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color(hex: "F4436C").opacity(0.3), lineWidth: 1)
                    .scaleEffect(entry.isActive ? 1.0 : 0.8)
                    .opacity(entry.isActive ? 1.0 : 0)
                    .frame(width: CGFloat(40 + i * 30), height: CGFloat(40 + i * 30))
            }
            
            VStack {
                Spacer()
                
                // Main Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "F4436C").opacity(0.15))
                        .frame(width: 50, height: 50)
                        .blur(radius: 5)
                    
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(Color(hex: "F4436C"))
                        .shadow(color: Color(hex: "F4436C").opacity(0.5), radius: 10)
                }
                
                Spacer()
                
                // Text Label
                Text("TREMBLE RADAR")
                    .font(.system(size: 10, weight: .black))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 12)
            }
            
            // Glassmorphic Overlay
            RoundedRectangle(cornerRadius: 0)
                .fill(.white.opacity(0.03))
                .blur(radius: 1)
        }
        .containerBackground(for: .widget) {
            Color(hex: "1A1A18")
        }
    }
}

@main
struct TrembleRadarWidget: Widget {
    let kind: String = "TrembleRadarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RadarTimelineProvider()) { entry in
            TrembleRadarWidgetView(entry: entry)
        }
        .configurationDisplayName("Tremble Radar")
        .description("Visual proximity radar for your lock screen.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
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
