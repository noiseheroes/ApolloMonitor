import Foundation
import Network

/// Response types from the UA Console TCP protocol
public enum UAResponse {
    case value(path: String, property: String, doubleValue: Double)
    case boolValue(path: String, property: String, boolValue: Bool)
    case stringValue(path: String, property: String, stringValue: String)
    case children(path: String, ids: [String])
}

/// TCP client for communicating with Universal Audio Console
/// Protocol: JSON over null-terminated strings on port 4710
public class ApolloTCP {
    private var connection: NWConnection?
    private let host: String
    private let port: UInt16

    // Thread safety — all mutable state goes through this queue
    private let stateQueue = DispatchQueue(label: "com.noiseheroes.ApolloTCP.state")

    // Receive buffer for handling TCP fragmentation
    private var receiveBuffer = Data()

    // Auto-reconnect
    private var reconnectTimer: DispatchSourceTimer?
    private var reconnectAttempt = 0
    private let maxReconnectDelay: TimeInterval = 10
    private var intentionalDisconnect = false

    // Keep-alive
    private var keepAliveTimer: DispatchSourceTimer?
    private let keepAliveInterval: TimeInterval = 30

    public var onResponse: ((UAResponse) -> Void)?
    public var onStatus: ((Bool, String) -> Void)?
    public var onDisconnected: (() -> Void)?

    private var _isConnected = false
    public var isConnected: Bool {
        stateQueue.sync { _isConnected }
    }

    public init(host: String = "127.0.0.1", port: UInt16 = 4710) {
        self.host = host
        self.port = port
    }

    // MARK: - Connection

    public func connect() {
        cancelReconnectTimer()

        // Detach and cancel old connection before creating new one
        let oldConn = stateQueue.sync { () -> NWConnection? in
            let old = connection
            connection = nil
            _isConnected = false
            receiveBuffer = Data()
            intentionalDisconnect = false
            return old
        }
        oldConn?.cancel()

        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!
        )
        let conn = NWConnection(to: endpoint, using: .tcp)

        conn.stateUpdateHandler = { [weak self, weak conn] state in
            guard let self, let conn else { return }
            // Ignore events from stale connections
            guard self.stateQueue.sync(execute: { self.connection === conn }) else { return }

            switch state {
            case .ready:
                self.stateQueue.sync {
                    self._isConnected = true
                    self.reconnectAttempt = 0
                }
                self.onStatus?(true, "Connected to \(self.host)")
                self.startKeepAlive()
            case .failed:
                self.handleDisconnection("Connection failed — Is UA Console running?")
            case .waiting:
                self.handleDisconnection("UA Console not reachable on \(self.host):\(self.port)")
            case .preparing:
                self.onStatus?(false, "Connecting to \(self.host):\(self.port)…")
            default:
                break
            }
        }

        stateQueue.sync { connection = conn }
        conn.start(queue: .global(qos: .userInteractive))
        startReceiving(on: conn)
    }

    public func disconnect() {
        cancelReconnectTimer()
        stopKeepAlive()
        let conn = stateQueue.sync { () -> NWConnection? in
            let c = connection
            connection = nil
            intentionalDisconnect = true
            _isConnected = false
            receiveBuffer = Data()
            return c
        }
        conn?.cancel()
    }

    // MARK: - Protocol Commands

    public func get(_ path: String) {
        send("get \(path)")
    }

    public func set(_ path: String, value: Any) {
        send("set \(path)/value/ \(value)")
    }

    public func subscribe(_ path: String) {
        send("subscribe \(path)")
    }

    // MARK: - Reconnection

    private func handleDisconnection(_ message: String) {
        let wasConnected = stateQueue.sync { () -> Bool in
            let was = _isConnected
            _isConnected = false
            return was
        }
        stopKeepAlive()
        onStatus?(false, message)

        if wasConnected {
            onDisconnected?()
        }

        scheduleReconnect()
    }

    public func scheduleReconnect() {
        let intentional = stateQueue.sync { intentionalDisconnect }
        guard !intentional else { return }
        cancelReconnectTimer()

        let attempt = stateQueue.sync { () -> Int in
            reconnectAttempt += 1
            return reconnectAttempt
        }
        let delay = min(pow(2.0, Double(attempt - 1)), maxReconnectDelay)

        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        timer.schedule(deadline: .now() + delay)
        timer.setEventHandler { [weak self] in
            self?.connect()
        }
        timer.resume()
        stateQueue.sync { reconnectTimer = timer }

        onStatus?(false, "Retrying in \(Int(delay))s… (attempt \(attempt))")
    }

    public func resetReconnectCounter() {
        stateQueue.sync { reconnectAttempt = 0 }
    }

    private func cancelReconnectTimer() {
        let timer = stateQueue.sync { () -> DispatchSourceTimer? in
            let t = reconnectTimer
            reconnectTimer = nil
            return t
        }
        timer?.cancel()
    }

    // MARK: - Keep-Alive

    private func startKeepAlive() {
        stopKeepAlive()
        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        timer.schedule(deadline: .now() + keepAliveInterval, repeating: keepAliveInterval)
        timer.setEventHandler { [weak self] in
            guard let self, self.isConnected else { return }
            self.send("get /devices")
        }
        timer.resume()
        stateQueue.sync { keepAliveTimer = timer }
    }

    private func stopKeepAlive() {
        let timer = stateQueue.sync { () -> DispatchSourceTimer? in
            let t = keepAliveTimer
            keepAliveTimer = nil
            return t
        }
        timer?.cancel()
    }

    // MARK: - Receiving (with fragmentation buffer)

    private func startReceiving(on conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            // Ignore data from stale connections
            guard self.stateQueue.sync(execute: { self.connection === conn }) else { return }

            if let data = data {
                self.bufferAndProcess(data)
            }

            if isComplete || error != nil {
                self.handleDisconnection("Connection lost — reconnecting…")
                return
            }

            self.startReceiving(on: conn)
        }
    }

    /// Append data to buffer, extract complete null-terminated messages, parse them
    private func bufferAndProcess(_ data: Data) {
        stateQueue.sync { receiveBuffer.append(data) }

        // Extract complete messages (separated by 0x00)
        while true {
            let buffer = stateQueue.sync { receiveBuffer }
            guard let nullIndex = buffer.firstIndex(of: 0x00) else { break }

            let messageData = buffer[buffer.startIndex..<nullIndex]
            stateQueue.sync {
                receiveBuffer = Data(buffer[buffer.index(after: nullIndex)...])
            }

            if let message = String(data: messageData, encoding: .utf8), !message.isEmpty {
                parseSingleResponse(message)
            }
        }
    }

    /// Parse a single JSON response (no splitting needed — already extracted from buffer)
    private func parseSingleResponse(_ message: String) {
        // Strip any remaining newlines
        let cleaned = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty,
              let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let path = json["path"] as? String else {
            return
        }

        // Response with structured data object
        if let responseData = json["data"] as? [String: Any] {
            // Children (e.g., get /devices → {"children": {"0": {}, "1": {}}})
            if let children = responseData["children"] as? [String: Any] {
                let ids = Array(children.keys).sorted()
                onResponse?(.children(path: path, ids: ids))
            }

            // Properties
            if let properties = responseData["properties"] as? [String: Any] {
                for (propName, propData) in properties {
                    guard let propDict = propData as? [String: Any] else { continue }
                    if let innerValue = propDict["value"] {
                        emitValue(path: path, property: propName, rawValue: innerValue)
                    }
                }
            }

            // No properties or children — structured but simple
            if !responseData.keys.contains("properties") && !responseData.keys.contains("children") {
                let pathComponents = path.split(separator: "/")
                if let propertyName = pathComponents.last {
                    emitFromRaw(path: path, property: String(propertyName), json: json)
                }
            }
        } else {
            // Direct scalar value (subscribe push: {"path": "...", "data": true})
            let pathComponents = path.split(separator: "/")
            if let propertyName = pathComponents.last {
                emitFromRaw(path: path, property: String(propertyName), json: json)
            }
        }
    }

    private func emitFromRaw(path: String, property: String, json: [String: Any]) {
        if let val = json["data"] as? Double {
            onResponse?(.value(path: path, property: property, doubleValue: val))
        } else if let val = json["data"] as? Bool {
            onResponse?(.boolValue(path: path, property: property, boolValue: val))
        } else if let val = json["data"] as? String {
            onResponse?(.stringValue(path: path, property: property, stringValue: val))
        }
    }

    private func emitValue(path: String, property: String, rawValue: Any) {
        if let doubleVal = rawValue as? Double {
            onResponse?(.value(path: path, property: property, doubleValue: doubleVal))
        } else if let boolVal = rawValue as? Bool {
            onResponse?(.boolValue(path: path, property: property, boolValue: boolVal))
        } else if let stringVal = rawValue as? String {
            onResponse?(.stringValue(path: path, property: property, stringValue: stringVal))
        }
    }

    // MARK: - Sending

    private func send(_ command: String) {
        guard let data = (command + "\0").data(using: .utf8) else { return }
        let conn = stateQueue.sync { connection }
        conn?.send(content: data, completion: .contentProcessed { [weak self] error in
            if error != nil {
                self?.handleDisconnection("Send failed — reconnecting…")
            }
        })
    }
}
