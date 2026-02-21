import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 0) {
            // App Icon and Name
            header
                .padding(.top, 30)
                .padding(.bottom, 20)

            Divider()
                .padding(.horizontal, 30)

            // Description
            description
                .padding(.vertical, 20)

            Divider()
                .padding(.horizontal, 30)

            // Credits
            credits
                .padding(.vertical, 20)

            Spacer()

            // Footer
            footer
                .padding(.bottom, 20)
        }
        .frame(width: 360, height: 420)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 80, height: 80)
                .cornerRadius(16)

            Text("Apollo Monitor")
                .font(.system(size: 22, weight: .semibold))

            Text("Version \(appVersion) (\(buildNumber))")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Description

    private var description: some View {
        VStack(spacing: 8) {
            Text("Native macOS menu bar app for controlling Universal Audio Apollo monitor output.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
    }

    // MARK: - Credits

    private var credits: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CREDITS")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.tertiary)
                .tracking(1)

            VStack(alignment: .leading, spacing: 8) {
                creditRow(
                    title: "Protocol Discovery",
                    detail: "cuefinger by @franqulator",
                    url: "https://github.com/franqulator/cuefinger"
                )

                creditRow(
                    title: "Development",
                    detail: "Noise Heroes",
                    url: "https://github.com/noiseheroes"
                )

                creditRow(
                    title: "AI Assistant",
                    detail: "Claude by Anthropic",
                    url: "https://claude.ai"
                )
            }
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func creditRow(title: String, detail: String, url: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .frame(width: 110, alignment: .leading)

            Button(action: { openURL(url) }) {
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 8) {
            Button(action: { openURL("https://github.com/noiseheroes/ApolloMonitor") }) {
                HStack(spacing: 4) {
                    Image(systemName: "star")
                        .font(.system(size: 11))
                    Text("Star on GitHub")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.1))
                .foregroundStyle(.blue)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)

            Text("Made with ♥ for the audio community")
                .font(.system(size: 10))
                .foregroundStyle(.quaternary)
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

#Preview {
    AboutView()
}
