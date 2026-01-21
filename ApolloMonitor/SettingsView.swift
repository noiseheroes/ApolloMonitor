import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("selectedOutput") private var selectedOutput = "4"
    @AppStorage("volumeStep") private var volumeStep = 3.0

    var body: some View {
        TabView {
            generalSettings
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            audioSettings
                .tabItem {
                    Label("Audio", systemImage: "speaker.wave.2")
                }
        }
        .padding(20)
        .frame(width: 400, height: 280)
    }

    // MARK: - General Settings

    private var generalSettings: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        setLaunchAtLogin(newValue)
                    }

                Text("Automatically start Apollo Monitor when you log in to your Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .padding(.vertical, 8)

            Section {
                LabeledContent("Version") {
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Build") {
                    Text(buildNumber)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Audio Settings

    private var audioSettings: some View {
        Form {
            Section {
                Picker("Monitor Output", selection: $selectedOutput) {
                    Text("Output 1-2").tag("0")
                    Text("Output 3-4").tag("1")
                    Text("Output 5-6 (Monitor)").tag("4")
                }
                .pickerStyle(.menu)

                Text("Select which output pair to control. Default is Monitor (5-6).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .padding(.vertical, 8)

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Volume Step")
                        Spacer()
                        Text("\(Int(volumeStep)) dB")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    Slider(value: $volumeStep, in: 1...10, step: 1)
                }

                Text("Amount to change volume with keyboard shortcuts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
        }
    }
}

#Preview {
    SettingsView()
}
