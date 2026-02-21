import SwiftUI

struct MonitorView: View {
    @ObservedObject var apollo: ApolloController

    var onOpenSettings: () -> Void = {}
    var onOpenAbout: () -> Void = {}
    var onQuit: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().padding(.horizontal, 16)

            if apollo.isConnected {
                connectedContent
            } else {
                disconnectedContent
            }

            Divider().padding(.horizontal, 16)
            footer
        }
        .frame(width: 280)
        .background(.regularMaterial)
    }

    // MARK: - Connected Content

    private var connectedContent: some View {
        VStack(spacing: 0) {
            volumeSection
            Divider().padding(.horizontal, 16).padding(.top, 12)
            controlButtons
        }
    }

    // MARK: - Disconnected Content

    private var disconnectedContent: some View {
        VStack(spacing: 16) {
            Spacer()

            disconnectedIcon

            VStack(spacing: 6) {
                Text(disconnectedTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(apollo.statusMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 220)
            }

            if case .retrying = apollo.connectionState {
                retryingIndicator
            } else {
                connectButton
            }

            Spacer()
        }
        .padding(.vertical, 20)
        .frame(minHeight: 220)
    }

    private var disconnectedIcon: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.1))
                .frame(width: 56, height: 56)

            Image(systemName: disconnectedIconName)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.orange)
        }
    }

    private var disconnectedTitle: String {
        switch apollo.connectionState {
        case .connecting, .enumerating:
            return "Connecting…"
        case .retrying:
            return "Reconnecting…"
        default:
            return "Not Connected"
        }
    }

    private var disconnectedIconName: String {
        switch apollo.connectionState {
        case .connecting, .retrying, .enumerating:
            return "arrow.triangle.2.circlepath"
        default:
            return "bolt.horizontal.circle"
        }
    }

    private var retryingIndicator: some View {
        VStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)

            Button("Try Now") {
                apollo.reconnect()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.blue)
        }
    }

    private var connectButton: some View {
        Button(action: apollo.reconnect) {
            HStack(spacing: 6) {
                Image(systemName: "power")
                    .font(.system(size: 11, weight: .semibold))
                Text("Connect")
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Connect to Apollo")
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "dial.medium.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(apollo.deviceName.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(1.2)
                .lineLimit(1)

            Spacer()

            connectionIndicator
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(apollo.deviceName), \(apollo.isConnected ? "connected" : "disconnected")")
    }

    private var connectionIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(connectionDotColor)
                .frame(width: 6, height: 6)
                .accessibilityHidden(true)

            if apollo.isConnected {
                Text("MONITOR")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var connectionDotColor: Color {
        switch apollo.connectionState {
        case .connected: .green
        case .connecting, .retrying, .enumerating: .orange
        case .disconnected: .red
        }
    }

    // MARK: - Volume

    private var volumeSection: some View {
        VStack(spacing: 4) {
            volumeDisplay
            volumeSlider
        }
    }

    private var volumeDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(apollo.volumeDisplay)
                .font(.system(size: 52, weight: .ultraLight, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .contentTransition(.numericText())

            Text("dB")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.tertiary)
                .offset(y: -8)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Volume: \(apollo.volumeDisplay) decibels")
    }

    private var volumeSlider: some View {
        VStack(spacing: 4) {
            Slider(value: $apollo.volume, in: 0...100)
                .tint(.blue)
                .accessibilityLabel("Monitor Volume")
                .accessibilityValue("\(apollo.volumeDisplay) dB")

            HStack {
                Text("-\u{221E}")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.quaternary)
                Spacer()
                Text("0 dB")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.quaternary)
            }
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: 10) {
            ControlButton(
                icon: apollo.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                label: "Mute",
                isActive: apollo.isMuted,
                activeColor: .red,
                action: apollo.toggleMute
            )

            ControlButton(
                icon: "speaker.minus.fill",
                label: apollo.isDimmed ? "Dim -17" : "Dim",
                isActive: apollo.isDimmed,
                activeColor: .orange,
                action: apollo.toggleDim
            )

            ControlButton(
                icon: "rectangle.lefthalf.inset.filled.arrow.left",
                label: "Mono",
                isActive: apollo.isMono,
                activeColor: .purple,
                action: apollo.toggleMono
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Footer (settings, reconnect, quit)

    private var footer: some View {
        HStack(spacing: 0) {
            // Status text
            VStack(alignment: .leading, spacing: 2) {
                Text(apollo.statusMessage)
                    .font(.system(size: 9))
                    .foregroundStyle(.quaternary)
                    .lineLimit(1)

                if !apollo.selectedHost.isLocalhost {
                    Text(apollo.selectedHost.displayName)
                        .font(.system(size: 8))
                        .foregroundStyle(.quaternary)
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                Button(action: apollo.reconnect) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                }
                .buttonStyle(.plain)
                .help("Reconnect")

                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                }
                .buttonStyle(.plain)
                .help("Settings")

                Menu {
                    Button("About Apollo Monitor", action: onOpenAbout)
                    Divider()
                    Button("Quit", action: onQuit)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 16)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

// MARK: - Control Button

struct ControlButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isActive ? activeColor.opacity(0.15) : Color.primary.opacity(0.04))
                        .frame(width: 76, height: 42)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isActive ? activeColor.opacity(0.3) : Color.clear, lineWidth: 1)
                        )

                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(isActive ? activeColor : .secondary)
                }

                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isActive ? activeColor : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label), \(isActive ? "on" : "off")")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

#Preview {
    MonitorView(apollo: ApolloController())
}
