import Foundation
import Network

/// TCP client for communicating with Universal Audio Console via local socket
/// Protocol discovered via the cuefinger project: https://github.com/tschiemer/cuefinger
public class ApolloTCP {
    private var connection: NWConnection?
    private let host: String
    private let port: UInt16
    private let output: String

    public var onStatus: ((Bool, String) -> Void)?
    public var onValue: ((String, Double) -> Void)?

    public init(host: String = "127.0.0.1", port: UInt16 = 4710, output: String = "4") {
        self.host = host
        self.port = port
        self.output = output
        connect()
    }

    public func connect() {
        connection?.cancel()

        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!
        )
        connection = NWConnection(to: endpoint, using: .tcp)

        connection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.onStatus?(true, "Connected")
                self?.requestAllValues()
            case .failed(let error):
                self?.onStatus?(false, "Failed: \(error.localizedDescription)")
            case .waiting(let error):
                self?.onStatus?(false, "Waiting: \(error.localizedDescription)")
            case .cancelled:
                self?.onStatus?(false, "Disconnected")
            default:
                break
            }
        }

        connection?.start(queue: .global(qos: .userInteractive))
        startReceiving()
    }

    private func startReceiving() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, let message = String(data: data, encoding: .utf8) {
                self?.parseResponse(message)
            }

            if !isComplete && error == nil {
                self?.startReceiving()
            }
        }
    }

    private func parseResponse(_ message: String) {
        let separators = CharacterSet(charactersIn: "\0\n")

        for part in message.components(separatedBy: separators) {
            guard !part.isEmpty,
                  let data = part.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let path = json["path"] as? String,
                  let responseData = json["data"] as? [String: Any] else {
                continue
            }

            let pathComponents = path.split(separator: "/")
            guard let propertyName = pathComponents.last else { continue }

            if let properties = responseData["properties"] as? [String: Any],
               let valueProperty = properties["value"] as? [String: Any] {
                if let doubleValue = valueProperty["value"] as? Double {
                    onValue?(String(propertyName), doubleValue)
                } else if let boolValue = valueProperty["value"] as? Bool {
                    onValue?(String(propertyName), boolValue ? 1.0 : 0.0)
                }
            }
        }
    }

    private func send(_ command: String) {
        guard let data = (command + "\0").data(using: .utf8) else { return }
        connection?.send(content: data, completion: .idempotent)
    }

    public func requestAllValues() {
        let basePath = "/devices/0/outputs/\(output)"
        send("get \(basePath)/CRMonitorLevel")
        send("get \(basePath)/Mute")
        send("get \(basePath)/DimOn")
        send("get \(basePath)/MixToMono")
    }

    public func setVolume(dB: Double) {
        send("set /devices/0/outputs/\(output)/CRMonitorLevel/value/ \(dB)")
    }

    public func setMute(_ enabled: Bool) {
        send("set /devices/0/outputs/\(output)/Mute/value/ \(enabled)")
    }

    public func setDim(_ enabled: Bool) {
        send("set /devices/0/outputs/\(output)/DimOn/value/ \(enabled)")
    }

    public func setMono(_ enabled: Bool) {
        send("set /devices/0/outputs/\(output)/MixToMono/value/ \(enabled)")
    }
}
