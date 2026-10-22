import Foundation

/// Motion sensor data packet representing device acceleration and orientation.
public struct MotionSample: Sendable {
    public let timestamp: TimeInterval
    /// Gravitational acceleration along X, Y, Z axes in G's (-1.0 to 1.0).
    public let gravityX: Double
    public let gravityY: Double
    public let gravityZ: Double
    /// Euler attitude angles in radians.
    public let pitch: Double
    public let roll: Double
    public let yaw: Double
    /// User acceleration (dynamic movement) magnitude.
    public let userAccelerationMagnitude: Double

    public init(
        timestamp: TimeInterval,
        gravityX: Double,
        gravityY: Double,
        gravityZ: Double,
        pitch: Double,
        roll: Double,
        yaw: Double,
        userAccelerationMagnitude: Double
    ) {
        self.timestamp = timestamp
        self.gravityX = gravityX
        self.gravityY = gravityY
        self.gravityZ = gravityZ
        self.pitch = pitch
        self.roll = roll
        self.yaw = yaw
        self.userAccelerationMagnitude = userAccelerationMagnitude
    }
}

/// Rule-based finite state machine detecting prayer postures and completed rakahs.
/// Designed with protocol abstraction so it can be swapped or augmented with a Core ML classifier later.
public final class PostureDetector: @unchecked Sendable {

    private let config: VerificationConfig
    private var currentPosture: MotionPosture = .standing
    private var postureStartTime: TimeInterval = 0
    private var currentRakahPostures: [MotionPosture] = []
    private var completedRakahCount: Int = 0

    // Callback on posture transition
    public var onPostureChanged: (@Sendable (MotionPosture, Int) -> Void)?
    public var onRakahCompleted: (@Sendable (Int) -> Void)?

    public init(config: VerificationConfig = .default) {
        self.config = config
    }

    /// Resets the detector for a new prayer session.
    public func reset() {
        currentPosture = .standing
        postureStartTime = 0
        currentRakahPostures = [.standing]
        completedRakahCount = 0
    }

    /// Returns the currently detected posture.
    public var posture: MotionPosture {
        return currentPosture
    }

    /// Returns total number of completed rakahs in the current session.
    public var rakahCount: Int {
        return completedRakahCount
    }

    /// Feeds a new motion sample (expected at 25-50 Hz from CMMotionManager).
    public func processSample(_ sample: MotionSample) {
        if postureStartTime == 0 {
            postureStartTime = sample.timestamp
        }

        let durationInCurrentPosture = sample.timestamp - postureStartTime
        let detectedPosture = classifySample(sample)

        guard detectedPosture != currentPosture else {
            return
        }

        // Enforce minimum hold time in Sujud to reject transient wrist swings
        if (currentPosture == .sujud1 || currentPosture == .sujud2) &&
            durationInCurrentPosture < config.minimumSujudDurationSeconds {
            return
        }

        // State machine progression
        advancePostureState(to: detectedPosture, at: sample.timestamp)
    }

    // MARK: - Posture Classification Rules

    private func classifySample(_ sample: MotionSample) -> MotionPosture {
        // Apple Watch on wrist:
        // When standing upright with arms at chest (Takbir/Qiyam) or at sides:
        // Gravity Y or Z aligns with body vertical axis.
        // In Ruku (bowing forward ~90°):
        // Upper torso tilts forward ~60°-90°. Gravity vector shifts strongly in pitch/Z.
        // In Sujud (prostrating on floor):
        // Forearms and palms touch the ground. Watch face sits approximately horizontal or slightly tilted down.
        // Gravity Z is near -1.0 or +1.0 (flat), pitch is close to 0°, user acceleration is steady and quiet.

        let pitchDeg = sample.pitch * AstronomicalMath.radToDeg
        let isQuiet = sample.userAccelerationMagnitude < config.motionSensitivityG

        // Sujud: Forearm flat on the ground, wrists down
        if isQuiet && abs(pitchDeg) < 30.0 && (abs(sample.gravityZ) > 0.65 || abs(sample.gravityY) > 0.65) {
            if currentPosture == .sittingBetweenSujud || currentPosture == .standingAfterRuku {
                return currentPosture == .standingAfterRuku ? .sujud1 : .sujud2
            }
        }

        // Ruku: Torso bowed forward ~60° to 90°
        if isQuiet && pitchDeg < -45.0 && pitchDeg > -110.0 {
            if currentPosture == .standing {
                return .ruku
            }
        }

        // Sitting (Jalsah / Tashahhud): Torso upright, hands resting on thighs, wrists slightly tilted
        if isQuiet && pitchDeg > -30.0 && pitchDeg < 35.0 && sample.gravityY < -0.6 {
            if currentPosture == .sujud1 {
                return .sittingBetweenSujud
            } else if currentPosture == .sujud2 {
                return .sittingTashahhud
            }
        }

        // Default or upright standing
        if pitchDeg > -25.0 && pitchDeg < 45.0 {
            if currentPosture == .ruku {
                return .standingAfterRuku
            }
            return .standing
        }

        return currentPosture
    }

    private func advancePostureState(to newPosture: MotionPosture, at timestamp: TimeInterval) {
        let previous = currentPosture
        currentPosture = newPosture
        postureStartTime = timestamp
        currentRakahPostures.append(newPosture)

        // Check for completed Rakah sequence:
        // Standing -> Ruku -> Standing -> Sujud 1 -> Sitting -> Sujud 2
        if previous == .sujud2 && (newPosture == .standing || newPosture == .sittingTashahhud) {
            completedRakahCount += 1
            currentRakahPostures.removeAll()
            onRakahCompleted?(completedRakahCount)
        }

        onPostureChanged?(newPosture, completedRakahCount)
    }
}
