import Foundation
import WatchConnectivity
import Combine
import PrayerKit

/// iOS host service managing bidirectional synchronization with paired Apple Watch via WatchConnectivity.
@MainActor
public final class WatchConnectivityManager: NSObject, ObservableObject {

    @Published public private(set) var isWatchPaired: Bool = false
    @Published public private(set) var isWatchAppInstalled: Bool = false
    @Published public private(set) var isReachable: Bool = false

    private var session: WCSession?
    private weak var historyStore: PrayerHistoryStore?
    private weak var notificationManager: NotificationManager?

    public init(
        historyStore: PrayerHistoryStore? = nil,
        notificationManager: NotificationManager? = nil
    ) {
        self.historyStore = historyStore
        self.notificationManager = notificationManager
        super.init()

        if WCSession.isSupported() {
            let session = WCSession.default
            self.session = session
            session.delegate = self
            session.activate()
        }
    }

    public func configureDependencies(historyStore: PrayerHistoryStore, notificationManager: NotificationManager) {
        self.historyStore = historyStore
        self.notificationManager = notificationManager
    }

    // MARK: - Outgoing Sync (iPhone -> Apple Watch)

    /// Pushes current calculation settings, coordinates, and prayer times to Apple Watch via Application Context.
    public func syncToWatch(
        coordinates: Coordinates,
        method: CalculationMethod,
        madhab: Madhab,
        adjustments: PrayerAdjustments,
        verificationConfig: VerificationConfig
    ) {
        guard let session = session, session.activationState == .activated, session.isWatchAppInstalled else {
            return
        }

        var context: [String: Any] = [
            "lat": coordinates.latitude,
            "lon": coordinates.longitude,
            "elevation": coordinates.elevation,
            "place": coordinates.placeName ?? "",
            "method": method.rawValue,
            "madhab": madhab.rawValue
        ]

        if let adjData = try? JSONEncoder().encode(adjustments) {
            context["adjustments"] = adjData
        }

        if let configData = try? JSONEncoder().encode(verificationConfig) {
            context["verificationConfig"] = configData
        }

        do {
            try session.updateApplicationContext(context)
        } catch {
            print("[WatchConnectivity] updateApplicationContext error: \(error.localizedDescription)")
        }
    }
}

// MARK: - WCSessionDelegate (iOS)

extension WatchConnectivityManager: WCSessionDelegate {

    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.isWatchPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isReachable = session.isReachable
        }
    }

    public func sessionDidBecomeInactive(_ session: WCSession) {}

    public func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session for switching paired watches
        session.activate()
    }

    public func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }

    // Incoming user info transfer from Watch (e.g. prayer record completed on wrist)
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let recordData = userInfo["prayerRecord"] as? Data,
              let record = try? JSONDecoder().decode(PrayerRecord.self, from: recordData) else {
            return
        }

        Task { @MainActor in
            // 1. Record prayer into history log
            self.historyStore?.addRecord(record)

            // 2. Cancel remaining escalating reminders for this prayer
            self.notificationManager?.cancelPendingReminders(for: record.prayer, on: record.scheduledTime)
        }
    }
}
