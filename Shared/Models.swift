import Foundation

// MARK: - App Group

/// App Group identifier for sharing data between app and widget
public let appGroupID = "group.com.noiseheroes.ApolloMonitor"

/// UserDefaults backed by the shared App Group container
public let sharedDefaults = UserDefaults(suiteName: appGroupID) ?? .standard

// MARK: - Models

/// A UA Console host reachable on the network
public struct UAHost: Identifiable, Codable, Hashable {
    public var id: String { "\(address):\(port)" }
    public let address: String
    public let port: UInt16
    public var displayName: String
    public var isManual: Bool

    public init(address: String, port: UInt16 = 4710, displayName: String, isManual: Bool = false) {
        self.address = address
        self.port = port
        self.displayName = displayName
        self.isManual = isManual
    }

    public static let localhost = UAHost(
        address: "127.0.0.1",
        port: 4710,
        displayName: "This Mac",
        isManual: false
    )

    public var isLocalhost: Bool {
        address == "127.0.0.1" || address == "localhost"
    }
}

/// A UA audio device connected to a host
public struct UADevice: Identifiable, Hashable {
    public let id: String
    public var name: String
    public var isOnline: Bool

    public init(id: String, name: String = "Unknown Device", isOnline: Bool = false) {
        self.id = id
        self.name = name
        self.isOnline = isOnline
    }

    public static func == (lhs: UADevice, rhs: UADevice) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// An output pair on a device
public struct UAOutput: Identifiable, Hashable {
    public let id: String
    public var name: String

    public init(id: String, name: String = "") {
        self.id = id
        self.name = name.isEmpty ? "Output \(id)" : name
    }

    public static func == (lhs: UAOutput, rhs: UAOutput) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
