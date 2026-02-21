import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct ApolloTimelineProvider: TimelineProvider {
    private var defaults: UserDefaults { UserDefaults(suiteName: appGroupID) ?? .standard }

    func placeholder(in context: Context) -> ApolloEntry {
        ApolloEntry(date: Date(), volume: -24.0, isMuted: false, isDimmed: false, isMono: false, isConnected: true, deviceName: "Apollo")
    }

    func getSnapshot(in context: Context, completion: @escaping (ApolloEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ApolloEntry>) -> Void) {
        let entry = readEntry()
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30)))
        completion(timeline)
    }

    private func readEntry() -> ApolloEntry {
        let d = defaults
        return ApolloEntry(
            date: Date(),
            volume: d.double(forKey: "widgetVolume"),
            isMuted: d.bool(forKey: "widgetMuted"),
            isDimmed: d.bool(forKey: "widgetDimmed"),
            isMono: d.bool(forKey: "widgetMono"),
            isConnected: d.bool(forKey: "widgetConnected"),
            deviceName: d.string(forKey: "widgetDeviceName") ?? "Apollo"
        )
    }
}

// MARK: - Timeline Entry

struct ApolloEntry: TimelineEntry {
    let date: Date
    let volume: Double
    let isMuted: Bool
    let isDimmed: Bool
    let isMono: Bool
    let isConnected: Bool
    let deviceName: String

    var volumeDisplay: String {
        volume <= -95 ? "-\u{221E}" : String(format: "%.1f", volume)
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
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "dial.medium.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(entry.deviceName.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Circle()
                    .fill(entry.isConnected ? Color.green : Color.red)
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

            HStack(spacing: 6) {
                if entry.isMuted {
                    StatusPill(icon: "speaker.slash.fill", label: "Mute", isActive: true, activeColor: .red)
                }
                if entry.isDimmed {
                    StatusPill(icon: "speaker.minus.fill", label: "Dim", isActive: true, activeColor: .orange)
                }
                if entry.isMono {
                    StatusPill(icon: "rectangle.lefthalf.inset.filled.arrow.left", label: "Mono", isActive: true, activeColor: .purple)
                }
                if !entry.isMuted && !entry.isDimmed && !entry.isMono {
                    StatusPill(icon: "speaker.wave.2.fill", label: "Stereo", isActive: false, activeColor: .green)
                }
            }
        }
        .padding()
        .containerBackground(.regularMaterial, for: .widget)
    }

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "dial.medium.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(entry.deviceName.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
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

            VStack(spacing: 6) {
                StatusPill(
                    icon: "speaker.slash.fill",
                    label: "Mute",
                    isActive: entry.isMuted,
                    activeColor: .red
                )

                StatusPill(
                    icon: "speaker.minus.fill",
                    label: "Dim",
                    isActive: entry.isDimmed,
                    activeColor: .orange
                )

                StatusPill(
                    icon: "rectangle.lefthalf.inset.filled.arrow.left",
                    label: "Mono",
                    isActive: entry.isMono,
                    activeColor: .purple
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
        .description("Monitor your Apollo volume and status at a glance.")
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
    ApolloEntry(date: .now, volume: -24.0, isMuted: false, isDimmed: false, isMono: false, isConnected: true, deviceName: "Apollo Solo")
    ApolloEntry(date: .now, volume: -24.0, isMuted: true, isDimmed: false, isMono: false, isConnected: true, deviceName: "Apollo Solo")
}

#Preview(as: .systemMedium) {
    ApolloMonitorWidget()
} timeline: {
    ApolloEntry(date: .now, volume: -24.0, isMuted: false, isDimmed: true, isMono: false, isConnected: true, deviceName: "Apollo Solo")
}
