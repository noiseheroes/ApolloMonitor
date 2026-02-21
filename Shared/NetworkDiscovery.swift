import Foundation
import Network

/// Discovers UA Console instances on the local network via Bonjour
public class NetworkDiscovery: ObservableObject {
    @Published public var discoveredHosts: [UAHost] = []
    @Published public var isSearching = false

    private var browser: NWBrowser?
    private var resolveConnections: [NWConnection] = []
    private let resolveQueue = DispatchQueue(label: "com.noiseheroes.discovery.resolve")

    public init() {}

    /// Start browsing for UA Mixer Engine Bonjour services
    public func startBrowsing() {
        stopBrowsing()

        DispatchQueue.main.async {
            self.discoveredHosts = []
        }

        let params = NWParameters()
        params.includePeerToPeer = true
        browser = NWBrowser(for: .bonjour(type: "_uamixer._tcp", domain: nil), using: params)

        browser?.browseResultsChangedHandler = { [weak self] results, _ in
            self?.handleBrowseResults(results)
        }

        browser?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.isSearching = true
                case .failed, .cancelled:
                    self?.isSearching = false
                default:
                    break
                }
            }
        }

        browser?.start(queue: .global(qos: .utility))

        // Auto-stop after 10 seconds
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.stopBrowsing()
        }
    }

    /// Stop browsing and clean up all connections
    public func stopBrowsing() {
        browser?.cancel()
        browser = nil
        resolveQueue.sync {
            resolveConnections.forEach { $0.cancel() }
            resolveConnections.removeAll()
        }
        DispatchQueue.main.async {
            self.isSearching = false
        }
    }

    private func handleBrowseResults(_ results: Set<NWBrowser.Result>) {
        for result in results {
            switch result.endpoint {
            case .service(let name, _, _, _):
                resolveEndpoint(result.endpoint, serviceName: name)
            default:
                break
            }
        }
    }

    /// Resolve a Bonjour service endpoint to get the actual IP address
    private func resolveEndpoint(_ endpoint: NWEndpoint, serviceName: String) {
        let connection = NWConnection(to: endpoint, using: .tcp)

        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                if let remotePath = connection.currentPath,
                   let remoteEndpoint = remotePath.remoteEndpoint,
                   case .hostPort(let host, let port) = remoteEndpoint {

                    let hostString = "\(host)"
                    let portValue = port.rawValue

                    // Skip localhost
                    if hostString == "127.0.0.1" || hostString == "::1" { return }

                    let uaHost = UAHost(
                        address: hostString,
                        port: portValue,
                        displayName: serviceName,
                        isManual: false
                    )

                    DispatchQueue.main.async {
                        if !self.discoveredHosts.contains(where: { $0.address == hostString }) {
                            self.discoveredHosts.append(uaHost)
                        }
                    }
                }
                connection.cancel()
                self.removeConnection(connection)

            case .failed, .cancelled:
                self.removeConnection(connection)

            default:
                break
            }
        }

        connection.start(queue: .global(qos: .utility))
        resolveQueue.sync {
            resolveConnections.append(connection)
        }
    }

    private func removeConnection(_ connection: NWConnection) {
        resolveQueue.sync {
            resolveConnections.removeAll { $0 === connection }
        }
    }
}
