import Foundation
import Combine

/// Main controller for Apollo Solo monitor controls
/// Manages volume, mute, dim, and mono states
public class ApolloController: ObservableObject {
    @Published public var volume: Double = 50 {
        didSet {
            guard !isReceiving, abs(oldValue - volume) > 0.3 else { return }
            tcp?.setVolume(dB: volumeToDB(volume))
        }
    }

    @Published public var isMuted = false
    @Published public var isDimmed = false
    @Published public var isMono = false
    @Published public var isConnected = false
    @Published public var statusMessage = "Connecting..."

    /// Formatted volume display string
    public var volumeDisplay: String {
        let dB = volumeToDB(volume)
        return dB <= -59 ? "-∞" : String(format: "%.1f", dB)
    }

    private var tcp: ApolloTCP?
    private var isReceiving = false

    public init() {
        setupTCPConnection()
    }

    private func setupTCPConnection() {
        tcp = ApolloTCP()

        tcp?.onStatus = { [weak self] connected, message in
            DispatchQueue.main.async {
                self?.isConnected = connected
                self?.statusMessage = message
            }
        }

        tcp?.onValue = { [weak self] property, value in
            DispatchQueue.main.async {
                self?.handleValueUpdate(property: property, value: value)
            }
        }
    }

    private func handleValueUpdate(property: String, value: Double) {
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
        tcp?.setMute(isMuted)
    }

    public func toggleDim() {
        isDimmed.toggle()
        tcp?.setDim(isDimmed)
    }

    public func toggleMono() {
        isMono.toggle()
        tcp?.setMono(isMono)
    }

    public func reconnect() {
        tcp?.connect()
    }

    // MARK: - Volume Conversion

    /// Convert slider value (0-100) to dB (-96 to 0)
    private func volumeToDB(_ sliderValue: Double) -> Double {
        if sliderValue <= 0 { return -96.0 }
        return (sliderValue / 100.0) * 60.0 - 60.0
    }

    /// Convert dB (-96 to 0) to slider value (0-100)
    private func dbToVolume(_ dB: Double) -> Double {
        if dB <= -90 { return 0 }
        return ((dB + 60.0) / 60.0) * 100.0
    }
}
