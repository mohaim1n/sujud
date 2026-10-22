import Foundation
import WatchKit

/// Manages WKExtendedRuntimeSession on Apple Watch to keep the app active and processing sensors with the wrist down.
@MainActor
public final class WatchExtendedRuntimeService: NSObject, ObservableObject {

    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var sessionError: String?

    private var session: WKExtendedRuntimeSession?

    public var onSessionDidStart: (() -> Void)?
    public var onSessionDidInvalidate: ((WKExtendedRuntimeSessionInvalidationReason) -> Void)?

    public override init() {
        super.init()
    }

    /// Starts an extended runtime session for active prayer.
    public func startSession() {
        guard session == nil || session?.state == .invalid else { return }

        let newSession = WKExtendedRuntimeSession()
        newSession.delegate = self
        self.session = newSession
        newSession.start()
        self.isRunning = true
    }

    /// Ends the extended runtime session.
    public func stopSession() {
        guard let session = session, session.state == .running else { return }
        session.invalidate()
        self.session = nil
        self.isRunning = false
    }
}

// MARK: - WKExtendedRuntimeSessionDelegate

extension WatchExtendedRuntimeService: WKExtendedRuntimeSessionDelegate {

    public func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Task { @MainActor in
            self.isRunning = true
            self.sessionError = nil
            self.onSessionDidStart?()
        }
    }

    public func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Task { @MainActor in
            self.sessionError = "Prayer session duration reached platform limit."
        }
    }

    public func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {
        Task { @MainActor in
            self.isRunning = false
            self.session = nil
            if let error = error {
                self.sessionError = error.localizedDescription
            }
            self.onSessionDidInvalidate?(reason)
        }
    }
}
