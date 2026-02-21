import Foundation
import Combine
import AppKit
import WidgetKit

/// Connection state for the UI
public enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case retrying(attempt: Int)
    case connected
    case enumerating
}

/// Main controller for Apollo monitor controls
/// Manages connection, device enumeration, and monitor state
public class ApolloController: ObservableObject {

    // MARK: - Monitor State

    @Published public var volume: Double = 50 {
        didSet {
            guard !isReceiving, abs(oldValue - volume) > 0.3 else { return }
            tcp?.set("\(basePath)/CRMonitorLevel", value: volumeToDB(volume))
            syncToWidget()
        }
    }

    @Published public var isMuted = false {
        didSet { if !isReceiving { syncToWidget() } }
    }
    @Published public var isDimmed = false {
        didSet { if !isReceiving { syncToWidget() } }
    }
    @Published public var isMono = false {
        didSet { if !isReceiving { syncToWidget() } }
    }

    // MARK: - Connection State

    @Published public var isConnected = false {
        didSet { syncToWidget() }
    }
    @Published public var connectionState: ConnectionState = .disconnected
    @Published public var statusMessage = "Disconnected"

    // MARK: - Device Enumeration

    @Published public var devices: [UADevice] = []
    @Published public var outputs: [UAOutput] = []
    @Published public var selectedHost: UAHost = .localhost
    @Published public var selectedDeviceId: String = "0"
    @Published public var selectedOutputId: String = "4"
    @Published public var deviceName: String = "Apollo"

    // MARK: - Host Management

    @Published public var knownHosts: [UAHost] = [.localhost]

    // MARK: - Computed

    public var volumeDisplay: String {
        let dB = volumeToDB(volume)
        return dB <= -95 ? "-\u{221E}" : String(format: "%.1f", dB)
    }

    var basePath: String {
        "/devices/\(selectedDeviceId)/outputs/\(selectedOutputId)"
    }

    // MARK: - Private

    private var tcp: ApolloTCP?
    private var isReceiving = false
    private var pendingDeviceCount = 0
    private var pendingOutputEnumeration = false

    // UA software identifiers
    private static let uaMixerEngineBundleID = "com.uaudio.engine"
    private static let uaConsoleBundleID = "com.uaudio.console"
    private static let uaConsolePaths = [
        "/Applications/Universal Audio/UA Mixer Engine.app",
        "/Applications/UA Mixer Engine.app",
        "/Applications/Universal Audio/UA Console.app",
        "/Applications/UA Console.app"
    ]

    // MARK: - Init

    public init() {
        loadPersistedState()
        connectToHost(selectedHost)
    }

    // MARK: - Connection

    /// Connect to a specific host
    public func connectToHost(_ host: UAHost) {
        tcp?.disconnect()
        devices = []
        outputs = []

        selectedHost = host
        connectionState = .connecting
        statusMessage = "Connecting to \(host.displayName)…"

        if host.isLocalhost {
            ensureUARunningAndConnect(host)
        } else {
            startTCPConnection(host: host.address, port: host.port)
        }

        savePersistedState()
    }

    /// Manual reconnect from UI
    public func reconnect() {
        tcp?.resetReconnectCounter()
        connectToHost(selectedHost)
    }

    /// Change the selected device (re-subscribes to its outputs)
    public func selectDevice(_ deviceId: String) {
        guard deviceId != selectedDeviceId else { return }
        selectedDeviceId = deviceId

        if let device = devices.first(where: { $0.id == deviceId }) {
            deviceName = device.name
        }

        outputs = []
        tcp?.get("/devices/\(deviceId)/outputs")
        pendingOutputEnumeration = true

        savePersistedState()
    }

    /// Change the selected output (re-subscribes to its values)
    public func selectOutput(_ outputId: String) {
        guard outputId != selectedOutputId else { return }
        selectedOutputId = outputId
        subscribeToMonitorValues()
        savePersistedState()
    }

    // MARK: - Host Management

    public func addHost(_ host: UAHost) {
        guard !knownHosts.contains(where: { $0.id == host.id }) else { return }
        knownHosts.append(host)
        saveHosts()
    }

    public func removeHost(_ host: UAHost) {
        guard host.id != UAHost.localhost.id else { return }
        knownHosts.removeAll { $0.id == host.id }
        saveHosts()
    }

    public func mergeDiscoveredHosts(_ discovered: [UAHost]) {
        for host in discovered {
            if !knownHosts.contains(where: { $0.address == host.address }) {
                knownHosts.append(host)
            }
        }
        saveHosts()
    }

    // MARK: - TCP Setup

    private func startTCPConnection(host: String, port: UInt16) {
        tcp = ApolloTCP(host: host, port: port)

        tcp?.onStatus = { [weak self] connected, message in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isConnected = connected
                self.statusMessage = message

                if connected {
                    self.connectionState = .enumerating
                    self.startDeviceEnumeration()
                } else if message.contains("Retrying") {
                    if let range = message.range(of: "attempt "),
                       let num = Int(message[range.upperBound...].prefix(while: { $0.isNumber })) {
                        self.connectionState = .retrying(attempt: num)
                    }
                } else if message.contains("Connecting") {
                    self.connectionState = .connecting
                } else {
                    self.connectionState = .disconnected
                }
            }
        }

        tcp?.onResponse = { [weak self] response in
            DispatchQueue.main.async {
                self?.handleResponse(response)
            }
        }

        tcp?.onDisconnected = { [weak self] in
            DispatchQueue.main.async {
                self?.connectionState = .retrying(attempt: 1)
                self?.devices = []
                self?.outputs = []
            }
        }

        tcp?.connect()
    }

    // MARK: - Device Enumeration

    private func startDeviceEnumeration() {
        statusMessage = "Enumerating devices…"
        devices = []
        outputs = []
        pendingDeviceCount = 0
        tcp?.get("/devices")
    }

    // MARK: - Response Handling

    private func handleResponse(_ response: UAResponse) {
        switch response {
        case .children(let path, let ids):
            if path == "/devices" {
                handleDeviceList(ids)
            } else if path.hasSuffix("/outputs") {
                handleOutputList(path: path, ids: ids)
            }

        case .stringValue(let path, let property, let value):
            if property == "DeviceName" {
                handleDeviceNameUpdate(path: path, value: value)
            } else if property == "Name" {
                handleOutputNameUpdate(path: path, value: value)
            }

        case .boolValue(let path, let property, let value):
            if property == "DeviceOnline" {
                handleDeviceOnlineUpdate(path: path, online: value)
            } else {
                handleMonitorBoolUpdate(property: property, value: value)
            }

        case .value(_, let property, let doubleValue):
            handleMonitorValueUpdate(property: property, value: doubleValue)
        }
    }

    private func handleDeviceList(_ ids: [String]) {
        pendingDeviceCount = ids.count
        for id in ids {
            let device = UADevice(id: id)
            if !devices.contains(where: { $0.id == id }) {
                devices.append(device)
            }
            tcp?.get("/devices/\(id)")
            tcp?.subscribe("/devices/\(id)/DeviceOnline")
        }

        if ids.isEmpty {
            statusMessage = "No devices found"
            connectionState = .connected
        }
    }

    /// Match device name by path (e.g. "/devices/0" or "/devices/0/DeviceName")
    private func handleDeviceNameUpdate(path: String, value: String) {
        let parts = path.split(separator: "/")
        guard parts.count >= 2, parts[0] == "devices" else { return }
        let deviceId = String(parts[1])

        if let idx = devices.firstIndex(where: { $0.id == deviceId }) {
            devices[idx].name = value
            pendingDeviceCount -= 1

            if pendingDeviceCount <= 0 {
                finishDeviceEnumeration()
            }
        }
    }

    /// Match output name by path (e.g. "/devices/0/outputs/4" or "/devices/0/outputs/4/Name")
    private func handleOutputNameUpdate(path: String, value: String) {
        let parts = path.split(separator: "/")
        guard let outputsIdx = parts.firstIndex(of: "outputs"),
              outputsIdx + 1 < parts.count else { return }
        let outputId = String(parts[outputsIdx + 1])

        if let idx = outputs.firstIndex(where: { $0.id == outputId }) {
            outputs[idx].name = value.isEmpty ? "Output \(outputId)" : value
        }
    }

    private func handleDeviceOnlineUpdate(path: String, online: Bool) {
        let parts = path.split(separator: "/")
        guard parts.count >= 2, parts[0] == "devices" else { return }
        let deviceId = String(parts[1])

        if let idx = devices.firstIndex(where: { $0.id == deviceId }) {
            devices[idx].isOnline = online
        }
    }

    private func finishDeviceEnumeration() {
        // Auto-select: prefer last used, then first online, then first
        let lastId = selectedDeviceId
        if let _ = devices.first(where: { $0.id == lastId && $0.isOnline }) {
            // Keep current selection
        } else if let firstOnline = devices.first(where: { $0.isOnline }) {
            selectedDeviceId = firstOnline.id
        } else if let first = devices.first {
            selectedDeviceId = first.id
        }

        if let device = devices.first(where: { $0.id == selectedDeviceId }) {
            deviceName = device.name
        }

        tcp?.get("/devices/\(selectedDeviceId)/outputs")
        pendingOutputEnumeration = true
    }

    private func handleOutputList(path: String, ids: [String]) {
        guard pendingOutputEnumeration else { return }
        pendingOutputEnumeration = false

        // Create outputs with default names — protocol will update via Name property
        outputs = ids.map { UAOutput(id: $0, name: "Output \($0)") }

        // Query name for each output
        for id in ids {
            tcp?.get("/devices/\(selectedDeviceId)/outputs/\(id)")
        }

        // Auto-select: prefer last used, then "4" (monitor), then first
        let lastId = selectedOutputId
        if outputs.contains(where: { $0.id == lastId }) {
            // Keep current selection
        } else if outputs.contains(where: { $0.id == "4" }) {
            selectedOutputId = "4"
        } else if let first = outputs.first {
            selectedOutputId = first.id
        }

        connectionState = .connected
        statusMessage = "Connected — \(deviceName)"
        subscribeToMonitorValues()
        savePersistedState()
    }

    // MARK: - Subscribe & Monitor Values

    private func subscribeToMonitorValues() {
        let props = ["CRMonitorLevel", "Mute", "DimOn", "MixToMono"]
        for prop in props {
            tcp?.subscribe("\(basePath)/\(prop)")
            tcp?.get("\(basePath)/\(prop)")
        }
    }

    private func handleMonitorValueUpdate(property: String, value: Double) {
        isReceiving = true
        defer { isReceiving = false }

        switch property {
        case "CRMonitorLevel":
            volume = dbToVolume(value)
        case "Mute":
            isMuted = value != 0
        case "DimOn":
            isDimmed = value != 0
        case "MixToMono":
            isMono = value != 0
        default:
            break
        }

        syncToWidget()
    }

    private func handleMonitorBoolUpdate(property: String, value: Bool) {
        isReceiving = true
        defer { isReceiving = false }

        switch property {
        case "Mute":
            isMuted = value
        case "DimOn":
            isDimmed = value
        case "MixToMono":
            isMono = value
        default:
            break
        }

        syncToWidget()
    }

    // MARK: - Public Actions

    public func increaseVolume(by step: Double = 3) {
        volume = min(100, volume + step)
    }

    public func decreaseVolume(by step: Double = 3) {
        volume = max(0, volume - step)
    }

    public func toggleMute() {
        isMuted.toggle()
        tcp?.set("\(basePath)/Mute", value: isMuted)
    }

    public func toggleDim() {
        isDimmed.toggle()
        tcp?.set("\(basePath)/DimOn", value: isDimmed)
    }

    public func toggleMono() {
        isMono.toggle()
        tcp?.set("\(basePath)/MixToMono", value: isMono)
    }

    // MARK: - UA Software Launch (localhost only)

    private func ensureUARunningAndConnect(_ host: UAHost) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let launched = self?.launchUAMixerEngineIfNeeded() ?? false
            let delay: TimeInterval = launched ? 2.0 : 0

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self?.startTCPConnection(host: host.address, port: host.port)
            }
        }
    }

    private func isUARunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains { app in
            guard let bundleID = app.bundleIdentifier else { return false }
            return bundleID == Self.uaMixerEngineBundleID
                || bundleID == Self.uaConsoleBundleID
                || bundleID.hasPrefix("com.uaudio.")
        }
    }

    @discardableResult
    private func launchUAMixerEngineIfNeeded() -> Bool {
        if isUARunning() { return false }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = false
        config.hides = true

        for bundleID in [Self.uaMixerEngineBundleID, Self.uaConsoleBundleID] {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                NSWorkspace.shared.openApplication(at: url, configuration: config)
                DispatchQueue.main.async {
                    self.statusMessage = "Starting UA Mixer Engine…"
                }
                return true
            }
        }

        for path in Self.uaConsolePaths {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: path) {
                NSWorkspace.shared.openApplication(at: url, configuration: config)
                DispatchQueue.main.async {
                    self.statusMessage = "Starting UA software…"
                }
                return true
            }
        }

        return false
    }

    // MARK: - Persistence

    private func loadPersistedState() {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: "savedHosts"),
           let hosts = try? JSONDecoder().decode([UAHost].self, from: data) {
            knownHosts = hosts
            if !knownHosts.contains(where: { $0.isLocalhost }) {
                knownHosts.insert(.localhost, at: 0)
            }
        }

        if let address = defaults.string(forKey: "lastHostAddress") {
            let port = UInt16(defaults.integer(forKey: "lastHostPort"))
            let portValue = port > 0 ? port : 4710
            let name = defaults.string(forKey: "lastHostName") ?? address

            selectedHost = knownHosts.first(where: { $0.address == address && $0.port == portValue })
                ?? UAHost(address: address, port: portValue, displayName: name, isManual: true)
        }

        selectedDeviceId = defaults.string(forKey: "lastDeviceId") ?? "0"
        selectedOutputId = defaults.string(forKey: "lastOutputId") ?? "4"
    }

    private func savePersistedState() {
        let defaults = UserDefaults.standard
        defaults.set(selectedHost.address, forKey: "lastHostAddress")
        defaults.set(Int(selectedHost.port), forKey: "lastHostPort")
        defaults.set(selectedHost.displayName, forKey: "lastHostName")
        defaults.set(selectedDeviceId, forKey: "lastDeviceId")
        defaults.set(selectedOutputId, forKey: "lastOutputId")
    }

    private func saveHosts() {
        if let data = try? JSONEncoder().encode(knownHosts) {
            UserDefaults.standard.set(data, forKey: "savedHosts")
        }
    }

    // MARK: - Widget Sync (App Group)

    private func syncToWidget() {
        sharedDefaults.set(volumeToDB(volume), forKey: "widgetVolume")
        sharedDefaults.set(isMuted, forKey: "widgetMuted")
        sharedDefaults.set(isDimmed, forKey: "widgetDimmed")
        sharedDefaults.set(isMono, forKey: "widgetMono")
        sharedDefaults.set(isConnected, forKey: "widgetConnected")
        sharedDefaults.set(deviceName, forKey: "widgetDeviceName")
        sharedDefaults.set(Date().timeIntervalSince1970, forKey: "widgetLastUpdate")

        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Volume Conversion (full -96 to 0 dB range, quadratic curve)

    private func volumeToDB(_ sliderValue: Double) -> Double {
        if sliderValue <= 0 { return -96.0 }
        if sliderValue >= 100 { return 0.0 }
        let normalized = sliderValue / 100.0
        let curved = pow(normalized, 2.0)
        return curved * 96.0 - 96.0
    }

    private func dbToVolume(_ dB: Double) -> Double {
        if dB <= -96 { return 0 }
        if dB >= 0 { return 100 }
        let normalized = (dB + 96.0) / 96.0
        return sqrt(normalized) * 100.0
    }
}
