import SwiftUI

struct MonitorView: View {
    @ObservedObject var apollo: ApolloController

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().padding(.horizontal, 16)
            volumeSection
            Divider().padding(.horizontal, 16).padding(.top, 12)
            controlButtons
            Divider().padding(.horizontal, 16)
            footer
        }
        .frame(width: 280)
        .background(.regularMaterial)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "dial.medium.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("APOLLO SOLO")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(1.2)

            Spacer()

            connectionIndicator
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var connectionIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(apollo.isConnected ? Color.green : Color.orange)
                .frame(width: 6, height: 6)

            if apollo.isConnected {
                Text("MONITOR")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Volume Section

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
    }

    private var volumeSlider: some View {
        VStack(spacing: 4) {
            Slider(value: $apollo.volume, in: 0...100)
                .tint(.blue)

            HStack {
                Text("-∞")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.quaternary)
                Spacer()
                Text("0 dB")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.quaternary)
            }
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

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text(apollo.statusMessage)
                .font(.system(size: 9))
                .foregroundStyle(.quaternary)

            Spacer()

            Button(action: apollo.reconnect) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 10))
                    .foregroundStyle(.quaternary)
            }
            .buttonStyle(.plain)
            .opacity(apollo.isConnected ? 0.4 : 1)
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
    }
}

#Preview {
    MonitorView(apollo: ApolloController())
}
