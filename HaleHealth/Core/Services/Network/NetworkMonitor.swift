import Combine
import Foundation
import Network

/// Observable reachability flag. Phase 1 wires it into `AppState` so any feature
/// can react to connectivity; Phase 2 uses it to gate retries and queue writes.
@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.halehealthindia.app.network-monitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor in
                self?.isConnected = connected
            }
        }
        monitor.start(queue: queue)
    }
}
