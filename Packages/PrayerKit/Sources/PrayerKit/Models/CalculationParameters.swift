import Foundation

/// Jurisprudential school (Madhab) determining the shadow ratio for Asr prayer.
public enum Madhab: String, CaseIterable, Codable, Sendable {
    /// Shafi'i, Maliki, Hanbali and Ja'fari: Asr begins when the shadow of an object equals its length plus the noon shadow.
    case shafi
    /// Hanafi: Asr begins when the shadow of an object equals twice its length plus the noon shadow.
    case hanafi

    public var shadowMultiplier: Double {
        switch self {
        case .shafi: return 1.0
        case .hanafi: return 2.0
        }
    }

    public var displayName: String {
        switch self {
        case .shafi: return "Standard (Shafi'i, Maliki, Hanbali)"
        case .hanafi: return "Hanafi"
        }
    }
}

/// Rule used in high-latitude regions where sun does not dip below twilight angle.
public enum HighLatitudeRule: String, CaseIterable, Codable, Sendable {
    case middleOfTheNight
    case seventhOfTheNight
    case twilightAngle

    public var displayName: String {
        switch self {
        case .middleOfTheNight: return "Middle of the Night (1/2)"
        case .seventhOfTheNight: return "One Seventh of the Night (1/7)"
        case .twilightAngle: return "Angle-Based Ratio"
        }
    }
}

/// Manual minute adjustments for each prayer time to align with local mosque timetables.
public struct PrayerAdjustments: Codable, Equatable, Sendable, Hashable {
    public var fajr: Int
    public var sunrise: Int
    public var dhuhr: Int
    public var asr: Int
    public var maghrib: Int
    public var isha: Int

    public init(
        fajr: Int = 0,
        sunrise: Int = 0,
        dhuhr: Int = 0,
        asr: Int = 0,
        maghrib: Int = 0,
        isha: Int = 0
    ) {
        self.fajr = fajr
        self.sunrise = sunrise
        self.dhuhr = dhuhr
        self.asr = asr
        self.maghrib = maghrib
        self.isha = isha
    }

    public static let zero = PrayerAdjustments()

    public func adjustment(for prayer: Prayer) -> Int {
        switch prayer {
        case .fajr: return fajr
        case .sunrise: return sunrise
        case .dhuhr: return dhuhr
        case .asr: return asr
        case .maghrib: return maghrib
        case .isha: return isha
        }
    }
}

/// Complete parameter configuration for calculating prayer times.
public struct CalculationParameters: Codable, Equatable, Sendable {
    /// Solar depression angle below the horizon for Fajr in degrees.
    public var fajrAngle: Double

    /// Solar depression angle below the horizon for Isha in degrees (used if ishaIntervalMinutes is nil).
    public var ishaAngle: Double?

    /// Fixed interval in minutes after Maghrib for Isha (e.g., 90 minutes for Umm al-Qura).
    public var ishaIntervalMinutes: Int?

    /// Fixed interval in minutes after sunset for Maghrib (if nil, calculated at astronomical sunset).
    public var maghribIntervalMinutes: Int?

    /// School of jurisprudence for Asr shadow length.
    public var madhab: Madhab

    /// High latitude fallback rule.
    public var highLatitudeRule: HighLatitudeRule

    /// Safety and local adjustments added to each prayer time.
    public var adjustments: PrayerAdjustments

    /// Safety margin added past solar transit for Dhuhr (typically 1 to 2 minutes).
    public var dhuhrSafetyMinutes: Int

    public init(
        fajrAngle: Double,
        ishaAngle: Double? = nil,
        ishaIntervalMinutes: Int? = nil,
        maghribIntervalMinutes: Int? = nil,
        madhab: Madhab = .shafi,
        highLatitudeRule: HighLatitudeRule = .middleOfTheNight,
        adjustments: PrayerAdjustments = .zero,
        dhuhrSafetyMinutes: Int = 1
    ) {
        self.fajrAngle = fajrAngle
        self.ishaAngle = ishaAngle
        self.ishaIntervalMinutes = ishaIntervalMinutes
        self.maghribIntervalMinutes = maghribIntervalMinutes
        self.madhab = madhab
        self.highLatitudeRule = highLatitudeRule
        self.adjustments = adjustments
        self.dhuhrSafetyMinutes = dhuhrSafetyMinutes
    }
}
