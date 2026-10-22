import Foundation
import WatchConnectivity
import Combine
import PrayerKit

/// watchOS service managing bidirectional synchronization with paired iPhone via WatchConnectivity.
@MainActor
public final class WatchConnectivityReceiver: NSObject, ObservableObject {

    @Published public private(set) var isReachable: Bool = false
    private var session: WCSession?
    private weak var watchViewModel: WatchPrayerViewModel?

    public init(watchViewModel: WatchPrayerViewModel? = nil) {
        self.watchViewModel = watchViewModel
        super.init()

        if WCSession.isSupported() {
            let session = WCSession.default
            self.session = session
            session.delegate = self
            session.activate()
        }
    }

    public func configureViewModel(_ vm: WatchPrayerViewModel) {
        self.watchViewModel = vm
    }

    // MARK: - Outgoing (Apple Watch -> iPhone)

    /// Queues completed prayer verification record for guaranteed background delivery to iPhone.
    public func sendRecordToPhone(_ record: PrayerRecord) {
        guard let session = session, session.activationState == .activated else { return }

        guard let recordData = try? JSONEncoder().encode(record) else { return }
        session.transferUserInfo(["prayerRecord": recordData])
    }
}

// MARK: - WCSessionDelegate (watchOS)

extension WatchConnectivityReceiver: WCSessionDelegate {

    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }

    public func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }

    // Incoming context update from iPhone (calculation parameters, coordinates)
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let lat = applicationContext["lat"] as? Double,
              let lon = applicationContext["lon"] as? Double,
              let methodRaw = applicationContext["method"] as? String,
              let method = CalculationMethod(rawValue: methodRaw) else {
            return
        }

        let elev = applicationContext["elevation"] as? Double ?? 0.0
        let place = applicationContext["place"] as? String

        let coords = Coordinates(latitude: lat, longitude: lon, elevation: elev, placeName: place)

        var params = method.defaultParameters
        if let madhabRaw = applicationContext["madhab"] as? String,
           let madhab = Madhab(rawValue: madhabRaw) {
            params.madhab = madhab
        }

        if let adjData = applicationContext["adjustments"] as? Data,
           let adjustments = try? JSONDecoder().decode(PrayerAdjustments.self, from: adjData) {
            params.adjustments = adjustments
        }

        Task { @MainActor in
            self.watchViewModel?.updateConfiguration(coordinates: coords, parameters: params)
        }
    }
}
