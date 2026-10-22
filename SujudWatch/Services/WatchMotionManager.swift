import Foundation
import CoreMotion
import Combine
import PrayerKit

/// Real-time Apple Watch motion sensor processor running at 30 Hz for Rakah posture sequence detection.
@MainActor
public final class WatchMotionManager: ObservableObject {

    // MARK: - Published Properties

    @Published public private(set) var currentPosture: MotionPosture = .standing
    @Published public private(set) var completedRakahs: Int = 0
    @Published public private(set) var isTracking: Bool = false
    @Published public private(set) var diagnosticLogs: [String] = []

    // Sensor Readouts for Developer Diagnostics
    @Published public private(set) var currentPitchDegrees: Double = 0.0
    @Published public private(set) var currentGravityZ: Double = 0.0
    @Published public private(set) var currentAccelerationMagnitude: Double = 0.0

    // MARK: - Private Properties

    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    private let postureDetector: PostureDetector
    private let maxLogEntries = 60

    public init(config: VerificationConfig = .default) {
        self.postureDetector = PostureDetector(config: config)
        self.queue.name = "com.sujud.motionQueue"
        self.queue.qualityOfService = .userInteractive

        setupDetectorCallbacks()
    }

    private func setupDetectorCallbacks() {
        postureDetector.onPostureChanged = { [weak self] newPosture, rakahs in
            Task { @MainActor in
                self?.currentPosture = newPosture
                self?.logEvent("Posture transitioned: \(newPosture.displayName) (Rakah: \(rakahs))")
            }
        }

        postureDetector.onRakahCompleted = { [weak self] count in
            Task { @MainActor in
                self?.completedRakahs = count
                self?.logEvent(">>> Rakah \(count) COMPLETED <<<")
            }
        }
    }

    // MARK: - Public Control

    /// Starts device motion sampling at 30 Hz.
    public func startTracking() {
        guard motionManager.isDeviceMotionAvailable else {
            logEvent("Error: Device motion unavailable on this hardware.")
            return
        }

        postureDetector.reset()
        diagnosticLogs.removeAll()
        completedRakahs = 0
        currentPosture = .standing
        isTracking = true

        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0 // 30 Hz
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else { return }

            let userAcc = motion.userAcceleration
            let accMag = sqrt(userAcc.x * userAcc.x + userAcc.y * userAcc.y + userAcc.z * userAcc.z)
            let pitchDeg = motion.attitude.pitch * AstronomicalMath.radToDeg

            let sample = MotionSample(
                timestamp: motion.timestamp,
                gravityX: motion.gravity.x,
                gravityY: motion.gravity.y,
                gravityZ: motion.gravity.z,
                pitch: motion.attitude.pitch,
                roll: motion.attitude.roll,
                yaw: motion.attitude.yaw,
                userAccelerationMagnitude: accMag
            )

            // Feed to posture detector state machine
            self.postureDetector.processSample(sample)

            Task { @MainActor in
                self.currentPitchDegrees = pitchDeg
                self.currentGravityZ = motion.gravity.z
                self.currentAccelerationMagnitude = accMag
            }
        }

        logEvent("Motion tracking started at 30 Hz.")
    }

    /// Stops device motion updates and releases sensors.
    public func stopTracking() {
        guard isTracking else { return }
        motionManager.stopDeviceMotionUpdates()
        isTracking = false
        logEvent("Motion tracking stopped. Total rakahs: \(completedRakahs).")
    }

    // MARK: - Diagnostics Logger

    private func logEvent(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SS"
        let timestamp = formatter.string(from: Date())
        let line = "[\(timestamp)] \(message)"

        diagnosticLogs.append(line)
        if diagnosticLogs.count > maxLogEntries {
            diagnosticLogs.removeFirst(diagnosticLogs.count - maxLogEntries)
        }
    }
}
