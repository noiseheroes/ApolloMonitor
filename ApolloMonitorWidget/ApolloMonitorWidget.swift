import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct ApolloTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ApolloEntry {
        ApolloEntry(date: Date(), volume: -24.0, isMuted: false, isConnected: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (ApolloEntry) -> Void) {
        let entry = ApolloEntry(date: Date(), volume: -24.0, isMuted: false, isConnected: true)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ApolloEntry>) -> Void) {
        // For now, use static data - in a real implementation,
        // you'd use App Groups to share data with the main app
        let entry = ApolloEntry(date: Date(), volume: -24.0, isMuted: false, isConnected: true)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60)))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct ApolloEntry: TimelineEntry {
    let date: Date
    let volume: Double
    let isMuted: Bool
    let isConnected: Bool

    var volumeDisplay: String {
        volume <= -59 ? "-∞" : String(format: "%.1f", volume)
    }
}

// MARK: - Widget Views

struct ApolloMonitorWidgetEntryView: View {
    var entry: ApolloTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    private var smallWidget: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "dial.medium.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("APOLLO")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Circle()
                    .fill(entry.isConnected ? Color.green : Color.orange)
                    .frame(width: 6, height: 6)
            }

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(entry.volumeDisplay)
                    .font(.system(size: 36, weight: .ultraLight, design: .rounded))
                    .monospacedDigit()
                Text("dB")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if entry.isMuted {
                Label("MUTED", systemImage: "speaker.slash.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .containerBackground(.regularMaterial, for: .widget)
    }

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "dial.medium.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("APOLLO SOLO")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(.secondary)

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(entry.volumeDisplay)
                        .font(.system(size: 44, weight: .ultraLight, design: .rounded))
                        .monospacedDigit()
                    Text("dB")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.tertiary)
                }

                Text("Monitor Level")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(spacing: 8) {
                StatusPill(
                    icon: "speaker.slash.fill",
                    label: "Mute",
                    isActive: entry.isMuted,
                    activeColor: .red
                )

                StatusPill(
                    icon: entry.isConnected ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                    label: entry.isConnected ? "Connected" : "Offline",
                    isActive: entry.isConnected,
                    activeColor: .green
                )
            }
        }
        .padding()
        .containerBackground(.regularMaterial, for: .widget)
    }
}

struct StatusPill: View {
    let icon: String
    let label: String
    let isActive: Bool
    let activeColor: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
            Text(label)
                .font(.system(size: 9, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isActive ? activeColor.opacity(0.15) : Color.primary.opacity(0.05))
        .foregroundStyle(isActive ? activeColor : .secondary)
        .clipShape(Capsule())
    }
}

// MARK: - Widget Configuration

struct ApolloMonitorWidget: Widget {
    let kind: String = "ApolloMonitorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ApolloTimelineProvider()) { entry in
            ApolloMonitorWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Apollo Monitor")
        .description("Monitor your Apollo Solo volume and status.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct ApolloMonitorWidgetBundle: WidgetBundle {
    var body: some Widget {
        ApolloMonitorWidget()
    }
}

#Preview(as: .systemSmall) {
    ApolloMonitorWidget()
} timeline: {
    ApolloEntry(date: .now, volume: -24.0, isMuted: false, isConnected: true)
    ApolloEntry(date: .now, volume: -24.0, isMuted: true, isConnected: true)
}

#Preview(as: .systemMedium) {
    ApolloMonitorWidget()
} timeline: {
    ApolloEntry(date: .now, volume: -24.0, isMuted: false, isConnected: true)
}
