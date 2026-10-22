import Foundation

/// State of an obligatory prayer for a given calendar day.
public enum DailyPrayerState: String, CaseIterable, Codable, Sendable {
    case pending
    case confirmed
    case selfReported
    case missed

    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .selfReported: return "Self-Reported"
        case .missed: return "Missed"
        }
    }

    public var sfSymbol: String {
        switch self {
        case .pending: return "circle"
        case .confirmed: return "checkmark.circle.fill"
        case .selfReported: return "hand.raised.circle.fill"
        case .missed: return "xmark.circle"
        }
    }
}

/// A privacy-preserving log record of a completed prayer session.
/// NOTE: In accordance with Apple privacy guidelines and Islamic privacy principles,
/// audio recordings and full transcripts are NEVER stored, uploaded, or logged.
/// Only the resulting verification scores and timestamps are recorded.
public struct PrayerRecord: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let prayer: Prayer
    public let scheduledTime: Date
    public let completedTime: Date?
    public let state: DailyPrayerState
    public let audioConfidence: Double?
    public let detectedRakahs: Int?
    public let targetRakahs: Int
    public let durationSeconds: TimeInterval?
    public let isSunnah: Bool
    public let notes: String?

    public init(
        id: UUID = UUID(),
        prayer: Prayer,
        scheduledTime: Date,
        completedTime: Date? = nil,
        state: DailyPrayerState = .pending,
        audioConfidence: Double? = nil,
        detectedRakahs: Int? = nil,
        targetRakahs: Int? = nil,
        durationSeconds: TimeInterval? = nil,
        isSunnah: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.prayer = prayer
        self.scheduledTime = scheduledTime
        self.completedTime = completedTime
        self.state = state
        self.audioConfidence = audioConfidence
        self.detectedRakahs = detectedRakahs
        self.targetRakahs = targetRakahs ?? prayer.obligatoryRakahCount
        self.durationSeconds = durationSeconds
        self.isSunnah = isSunnah
        self.notes = notes
    }

    /// Convenience factory for creating a record from a watch verification result.
    public static func fromVerificationResult(
        _ result: VerificationResult,
        scheduledTime: Date
    ) -> PrayerRecord {
        let state: DailyPrayerState
        switch result.status {
        case .confirmed:
            state = .confirmed
        case .selfReported:
            state = .selfReported
        case .partial, .notDetected:
            state = .pending // leaves it open or allows manual self-report
        }

        return PrayerRecord(
            prayer: result.prayer,
            scheduledTime: scheduledTime,
            completedTime: result.completedAt,
            state: state,
            audioConfidence: result.audioConfidence,
            detectedRakahs: result.detectedRakahCount,
            targetRakahs: result.expectedRakahCount,
            durationSeconds: result.durationSeconds
        )
    }
}
