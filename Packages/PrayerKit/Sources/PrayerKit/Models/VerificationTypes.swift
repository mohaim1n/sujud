import Foundation

/// Posture state in the sequence of an Islamic prayer rakah detected by accelerometer and device motion.
public enum MotionPosture: String, CaseIterable, Codable, Sendable {
    /// Standing upright (Qiyam) - Apple Watch on wrist vertical/hanging or folded at chest.
    case standing
    /// Bowing at waist ~90 degrees (Ruku) - Device pitch / gravity orientation tilts forward.
    case ruku
    /// Upright standing after bowing (I'tidal / Qawmah).
    case standingAfterRuku
    /// Prostration with forehead on floor (Sujud) - Forearms and wrists on prayer mat, watch horizontal facing down/flat.
    case sujud1
    /// Sitting between prostrations (Jalsah / Iftirash).
    case sittingBetweenSujud
    /// Second prostration of the rakah (Sujud 2).
    case sujud2
    /// Sitting for Tashahhud or pause between rakahs (Qa'dah).
    case sittingTashahhud

    public var displayName: String {
        switch self {
        case .standing, .standingAfterRuku:
            return "Standing (Qiyam)"
        case .ruku:
            return "Bowing (Ruku)"
        case .sujud1, .sujud2:
            return "Prostration (Sujud)"
        case .sittingBetweenSujud, .sittingTashahhud:
            return "Sitting (Jalsah)"
        }
    }
}

/// The verification outcome of a prayer session.
public enum VerificationStatus: String, CaseIterable, Codable, Sendable {
    /// Verified by high audio confidence and correct rakah posture sequence.
    case confirmed
    /// Partial match (e.g. correct rakahs but low audio, or whispered recitation with correct movement).
    case partial
    /// Neither audio nor motion passed threshold.
    case notDetected
    /// Manually confirmed by user tapping "I prayed" (sensor miss or quiet environment).
    case selfReported

    public var displayName: String {
        switch self {
        case .confirmed: return "Confirmed"
        case .partial: return "Partially Verified"
        case .notDetected: return "Not Detected"
        case .selfReported: return "Self-Reported"
        }
    }

    public var badgeColorHex: String {
        switch self {
        case .confirmed: return "#0B6E5B" // Deep Islamic Emerald Green
        case .partial: return "#C48208"   // Warm Ochre
        case .notDetected: return "#8C9290" // Neutral Grey
        case .selfReported: return "#2E5A88" // Slate Blue
        }
    }
}

/// Verification scoring thresholds and configuration parameters.
public struct VerificationConfig: Codable, Equatable, Sendable {
    /// Minimum Arabic recitation confidence threshold (0.0 to 1.0) to pass audio check. Default: 0.60.
    public var minimumAudioConfidence: Double

    /// Minimum rakah completion ratio (e.g. 1.0 means all rakahs must be detected). Default: 1.0.
    public var minimumRakahMatchRatio: Double

    /// Acceleration threshold in g's for detecting posture transitions.
    public var motionSensitivityG: Double

    /// Minimum duration (in seconds) required in Sujud to consider it a valid prostration (prevents false positives from arm swings).
    public var minimumSujudDurationSeconds: Double

    public init(
        minimumAudioConfidence: Double = 0.60,
        minimumRakahMatchRatio: Double = 1.0,
        motionSensitivityG: Double = 0.15,
        minimumSujudDurationSeconds: Double = 2.0
    ) {
        self.minimumAudioConfidence = minimumAudioConfidence
        self.minimumRakahMatchRatio = minimumRakahMatchRatio
        self.motionSensitivityG = motionSensitivityG
        self.minimumSujudDurationSeconds = minimumSujudDurationSeconds
    }

    public static let `default` = VerificationConfig()
}

/// Structured summary outcome produced at the end of a live prayer session.
public struct VerificationResult: Codable, Equatable, Sendable {
    public let prayer: Prayer
    public let status: VerificationStatus
    public let audioConfidence: Double
    public let detectedRakahCount: Int
    public let expectedRakahCount: Int
    public let durationSeconds: TimeInterval
    public let completedAt: Date

    public init(
        prayer: Prayer,
        status: VerificationStatus,
        audioConfidence: Double,
        detectedRakahCount: Int,
        expectedRakahCount: Int,
        durationSeconds: TimeInterval,
        completedAt: Date = Date()
    ) {
        self.prayer = prayer
        self.status = status
        self.audioConfidence = audioConfidence
        self.detectedRakahCount = detectedRakahCount
        self.expectedRakahCount = expectedRakahCount
        self.durationSeconds = durationSeconds
        self.completedAt = completedAt
    }
}
