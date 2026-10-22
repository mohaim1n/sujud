import Foundation
import Combine
import WatchKit
import PrayerKit

/// Coordinates an active prayer session combining extended runtime, motion posture detection, audio matching, and fusion scoring.
@MainActor
public final class PrayerSessionViewModel: ObservableObject {

    // MARK: - Published State

    @Published public let prayer: Prayer
    @Published public let targetRakahs: Int
    @Published public private(set) var currentPosture: MotionPosture = .standing
    @Published public private(set) var detectedRakahs: Int = 0
    @Published public private(set) var elapsedTimeSeconds: Int = 0
    @Published public private(set) var isListening: Bool = false
    @Published public private(set) var audioConfidence: Double = 0.0
    @Published public private(set) var audioPulseLevel: Float = 0.0
    @Published public private(set) var sessionSummary: VerificationResult?
    @Published public private(set) var isCompleted: Bool = false

    // MARK: - Subservices

    public let motionManager: WatchMotionManager
    public let audioRecognizer: AudioRecitationRecognizer
    private let runtimeService = WatchExtendedRuntimeService()
    private let scorer = PrayerScorer()

    private var sessionTimer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private let config: VerificationConfig

    public init(prayer: Prayer, config: VerificationConfig = .default) {
        self.prayer = prayer
        self.targetRakahs = prayer.obligatoryRakahCount
        self.config = config
        self.motionManager = WatchMotionManager(config: config)
        self.audioRecognizer = AudioRecitationRecognizer()

        setupBindings()
    }

    private func setupBindings() {
        motionManager.$currentPosture
            .receive(on: RunLoop.main)
            .assign(to: &$currentPosture)

        motionManager.$completedRakahs
            .receive(on: RunLoop.main)
            .assign(to: &$detectedRakahs)

        audioRecognizer.$isListening
            .receive(on: RunLoop.main)
            .assign(to: &$isListening)

        audioRecognizer.$recitationConfidence
            .receive(on: RunLoop.main)
            .assign(to: &$audioConfidence)

        audioRecognizer.$audioPowerLevel
            .receive(on: RunLoop.main)
            .assign(to: &$audioPulseLevel)
    }

    // MARK: - Session Lifecycle

    /// Begins the prayer session: launches extended runtime, motion sensors, and audio recognition.
    public func startSession() {
        elapsedTimeSeconds = 0
        isCompleted = false
        sessionSummary = nil

        // Keep watchOS running with wrist down
        runtimeService.startSession()

        // Start motion and audio engines
        motionManager.startTracking()
        audioRecognizer.startListening()

        // Start 1-second elapsed timer
        sessionTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.elapsedTimeSeconds += 1
            }

        WKInterfaceDevice.current().play(.start)
    }

    /// Completes the session normally and evaluates multi-modal fusion verification.
    public func completeSession() {
        stopAllSensors()

        let result = scorer.evaluate(
            prayer: prayer,
            audioConfidence: audioConfidence,
            detectedRakahs: detectedRakahs,
            expectedRakahs: targetRakahs,
            durationSeconds: TimeInterval(elapsedTimeSeconds),
            config: config
        )

        self.sessionSummary = result
        self.isCompleted = true

        if result.status == .confirmed {
            WKInterfaceDevice.current().play(.success)
        } else {
            WKInterfaceDevice.current().play(.notification)
        }
    }

    /// Manual "I prayed" override action: instantly scores as self-reported without penalizing sensor misses.
    public func selfReportSession() {
        stopAllSensors()

        let result = scorer.createSelfReportedResult(
            prayer: prayer,
            durationSeconds: TimeInterval(max(10, elapsedTimeSeconds))
        )

        self.sessionSummary = result
        self.isCompleted = true
        WKInterfaceDevice.current().play(.success)
    }

    private func stopAllSensors() {
        sessionTimer?.cancel()
        sessionTimer = nil

        motionManager.stopTracking()
        audioRecognizer.stopListening()
        runtimeService.stopSession()
    }
}
