import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var apollo: ApolloController
    @ObservedObject var discovery: NetworkDiscovery

    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("volumeStep") private var volumeStep = 3.0

    @State private var showManualAdd = false
    @State private var manualAddress = ""
    @State private var manualPort = "4710"

    var body: some View {
        TabView {
            connectionTab
                .tabItem { Label("Connection", systemImage: "network") }

            audioTab
                .tabItem { Label("Audio", systemImage: "speaker.wave.2") }

            generalTab
                .tabItem { Label("General", systemImage: "gearshape") }
        }
        .padding(20)
        .frame(width: 480, height: 400)
        .onAppear {
            discovery.startBrowsing()
        }
    }

    // MARK: - Connection Tab

    private var connectionTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Current connection status
            connectionStatusBanner
                .padding(.bottom, 12)

            // Discovered hosts list
            GroupBox {
                VStack(spacing: 0) {
                    discoveredHostsHeader
                    Divider()
                    hostList
                }
            }

            // Device & output pickers (when connected)
            if apollo.isConnected {
                GroupBox {
                    VStack(spacing: 12) {
                        devicePicker
                        if !apollo.outputs.isEmpty {
                            outputPicker
                        }
                    }
                    .padding(4)
                }
                .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Connection Status Banner

    private var connectionStatusBanner: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(connectionColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(apollo.isConnected ? "Connected" : "Not Connected")
                    .font(.system(size: 12, weight: .medium))

                Text(apollo.statusMessage)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if !apollo.isConnected {
                Button("Reconnect") {
                    apollo.reconnect()
                }
                .controlSize(.small)
            }
        }
        .padding(10)
        .background(connectionColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Host List

    private var discoveredHostsHeader: some View {
        HStack {
            Text("Available Hosts")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            Spacer()

            if discovery.isSearching {
                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.mini)
                    Text("Scanning…")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            } else {
                Button(action: { discovery.startBrowsing() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9))
                        Text("Scan")
                            .font(.system(size: 10))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var hostList: some View {
        VStack(spacing: 0) {
            // Localhost always first
            hostRow(UAHost.localhost)
            Divider()

            // Discovered + saved remote hosts
            let remoteHosts = allRemoteHosts
            if remoteHosts.isEmpty {
                emptyDiscoveryRow
            } else {
                ForEach(Array(remoteHosts.enumerated()), id: \.element.id) { index, host in
                    hostRow(host)
                    if index < remoteHosts.count - 1 {
                        Divider().padding(.leading, 40)
                    }
                }
            }

            Divider()

            // Manual add row
            manualAddRow
        }
    }

    private func hostRow(_ host: UAHost) -> some View {
        let isSelected = apollo.selectedHost.id == host.id

        return Button(action: {
            if !isSelected { apollo.connectToHost(host) }
        }) {
            HStack(spacing: 10) {
                Image(systemName: host.isLocalhost ? "desktopcomputer" : "network")
                    .font(.system(size: 13))
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 1) {
                    Text(host.displayName)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(.primary)

                    Text(host.isLocalhost ? "127.0.0.1" : host.address)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.blue)
                } else if !host.isLocalhost && host.isManual {
                    Button(action: { apollo.removeHost(host) }) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .help("Remove host")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.blue.opacity(0.06) : Color.clear)
    }

    private var emptyDiscoveryRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
                .frame(width: 20)

            Text(discovery.isSearching ? "Looking for UA Console on your network…" : "No remote hosts found")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
    }

    private var manualAddRow: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation { showManualAdd.toggle() } }) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(.blue)
                        .frame(width: 20)

                    Text("Add host manually…")
                        .font(.system(size: 11))
                        .foregroundStyle(.blue)

                    Spacer()

                    Image(systemName: showManualAdd ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showManualAdd {
                Divider().padding(.leading, 40)
                manualAddForm
            }
        }
    }

    private var manualAddForm: some View {
        HStack(spacing: 8) {
            TextField("IP address or hostname", text: $manualAddress)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11))

            TextField("Port", text: $manualPort)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11))
                .frame(width: 60)

            Button("Add") {
                let port = UInt16(manualPort) ?? 4710
                let host = UAHost(address: manualAddress, port: port, displayName: manualAddress, isManual: true)
                apollo.addHost(host)
                apollo.connectToHost(host)
                manualAddress = ""
                manualPort = "4710"
                withAnimation { showManualAdd = false }
            }
            .controlSize(.small)
            .disabled(manualAddress.isEmpty)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    // MARK: - Device & Output Pickers

    private var devicePicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Picker("Device", selection: Binding(
                get: { apollo.selectedDeviceId },
                set: { apollo.selectDevice($0) }
            )) {
                ForEach(apollo.devices) { device in
                    HStack {
                        Text(device.name)
                        if !device.isOnline {
                            Text("(offline)")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    .tag(device.id)
                }
            }
            .disabled(apollo.devices.isEmpty)

            if apollo.devices.isEmpty {
                Text("Enumerating devices…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var outputPicker: some View {
        Picker("Output", selection: Binding(
            get: { apollo.selectedOutputId },
            set: { apollo.selectOutput($0) }
        )) {
            ForEach(apollo.outputs) { output in
                Text(output.name).tag(output.id)
            }
        }
    }

    // MARK: - Helpers

    private var allRemoteHosts: [UAHost] {
        var hosts = apollo.knownHosts.filter { !$0.isLocalhost }
        for host in discovery.discoveredHosts {
            if !hosts.contains(where: { $0.address == host.address }) {
                hosts.append(host)
            }
        }
        return hosts
    }

    private var connectionColor: Color {
        switch apollo.connectionState {
        case .connected: .green
        case .connecting, .retrying, .enumerating: .orange
        case .disconnected: .red
        }
    }

    // MARK: - Audio Tab

    private var audioTab: some View {
        Form {
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

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }

                Text("Automatically start Apollo Monitor when you log in.")
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
