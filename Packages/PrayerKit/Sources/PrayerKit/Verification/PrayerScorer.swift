import Foundation

/// Protocol defining the contract for fusion prayer verification scoring.
public protocol PrayerScoringService: Sendable {
    func evaluate(
        prayer: Prayer,
        audioConfidence: Double,
        detectedRakahs: Int,
        expectedRakahs: Int,
        durationSeconds: TimeInterval,
        config: VerificationConfig
    ) -> VerificationResult

    func createSelfReportedResult(
        prayer: Prayer,
        durationSeconds: TimeInterval
    ) -> VerificationResult
}

/// Fusion engine combining on-device audio recitation recognition and motion postures.
public final class PrayerScorer: PrayerScoringService {

    public init() {}

    /// Evaluates multi-modal signals and computes the final verification verdict.
    public func evaluate(
        prayer: Prayer,
        audioConfidence: Double,
        detectedRakahs: Int,
        expectedRakahs: Int,
        durationSeconds: TimeInterval,
        config: VerificationConfig = .default
    ) -> VerificationResult {
        let audioPassed = audioConfidence >= config.minimumAudioConfidence
        let rakahRatio = Double(detectedRakahs) / max(1.0, Double(expectedRakahs))
        let rakahPassed = rakahRatio >= config.minimumRakahMatchRatio

        let status: VerificationStatus
        if audioPassed && rakahPassed {
            status = .confirmed
        } else if (audioPassed && detectedRakahs >= 1) || (rakahPassed && audioConfidence >= (config.minimumAudioConfidence * 0.5)) {
            status = .partial
        } else {
            status = .notDetected
        }

        return VerificationResult(
            prayer: prayer,
            status: status,
            audioConfidence: audioConfidence,
            detectedRakahCount: detectedRakahs,
            expectedRakahCount: expectedRakahs,
            durationSeconds: durationSeconds
        )
    }

    /// Creates a manual self-reported result when user confirms they prayed.
    public func createSelfReportedResult(
        prayer: Prayer,
        durationSeconds: TimeInterval
    ) -> VerificationResult {
        return VerificationResult(
            prayer: prayer,
            status: .selfReported,
            audioConfidence: 1.0,
            detectedRakahCount: prayer.obligatoryRakahCount,
            expectedRakahCount: prayer.obligatoryRakahCount,
            durationSeconds: durationSeconds
        )
    }
}
