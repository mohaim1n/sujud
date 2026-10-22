import Foundation

/// Recognized Islamic authorities and calculation methods for prayer times.
public enum CalculationMethod: String, CaseIterable, Codable, Sendable, Identifiable {
    case jakim
    case muis
    case muslimWorldLeague
    case ummAlQura
    case isna
    case egyptian
    case karachi
    case custom

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .jakim:
            return "JAKIM (Malaysia)"
        case .muis:
            return "Muis (Singapore)"
        case .muslimWorldLeague:
            return "Muslim World League (MWL)"
        case .ummAlQura:
            return "Umm al-Qura (Makkah, Saudi Arabia)"
        case .isna:
            return "ISNA (Islamic Society of North America)"
        case .egyptian:
            return "Egyptian General Authority of Survey"
        case .karachi:
            return "University of Islamic Sciences, Karachi"
        case .custom:
            return "Custom Parameters"
        }
    }

    /// Descriptive explanation of the angles and conventions used.
    public var methodDescription: String {
        switch self {
        case .jakim:
            return "Fajr at 20°, Isha at 18°. Used officially throughout Malaysia with +2 min safety adjustments."
        case .muis:
            return "Fajr at 20°, Isha at 18°. Standard for the Islamic Religious Council of Singapore."
        case .muslimWorldLeague:
            return "Fajr at 18°, Isha at 17°. Widely used in Europe, Far East, and parts of the Americas."
        case .ummAlQura:
            return "Fajr at 18.5°, Isha fixed at 90 minutes after Maghrib (120 minutes in Ramadan)."
        case .isna:
            return "Fajr at 15°, Isha at 15°. Common standard in the United States and Canada."
        case .egyptian:
            return "Fajr at 19.5°, Isha at 17.5°. Standard across Egypt, North Africa, and parts of the Levant."
        case .karachi:
            return "Fajr at 18°, Isha at 18°. Standard in Pakistan, India, Bangladesh, and Afghanistan."
        case .custom:
            return "User-configured angles, intervals, and adjustments."
        }
    }

    /// Generates the default parameters for this calculation method.
    public var defaultParameters: CalculationParameters {
        switch self {
        case .jakim:
            return CalculationParameters(
                fajrAngle: 20.0,
                ishaAngle: 18.0,
                madhab: .shafi,
                highLatitudeRule: .middleOfTheNight,
                adjustments: PrayerAdjustments(fajr: 0, sunrise: 0, dhuhr: 2, asr: 2, maghrib: 2, isha: 2),
                dhuhrSafetyMinutes: 2
            )
        case .muis:
            return CalculationParameters(
                fajrAngle: 20.0,
                ishaAngle: 18.0,
                madhab: .shafi,
                highLatitudeRule: .middleOfTheNight,
                adjustments: PrayerAdjustments(fajr: 0, sunrise: 0, dhuhr: 2, asr: 2, maghrib: 2, isha: 2),
                dhuhrSafetyMinutes: 2
            )
        case .muslimWorldLeague:
            return CalculationParameters(
                fajrAngle: 18.0,
                ishaAngle: 17.0,
                madhab: .shafi,
                highLatitudeRule: .middleOfTheNight,
                adjustments: .zero,
                dhuhrSafetyMinutes: 1
            )
        case .ummAlQura:
            return CalculationParameters(
                fajrAngle: 18.5,
                ishaAngle: nil,
                ishaIntervalMinutes: 90,
                madhab: .shafi,
                highLatitudeRule: .middleOfTheNight,
                adjustments: .zero,
                dhuhrSafetyMinutes: 1
            )
        case .isna:
            return CalculationParameters(
                fajrAngle: 15.0,
                ishaAngle: 15.0,
                madhab: .shafi,
                highLatitudeRule: .middleOfTheNight,
                adjustments: .zero,
                dhuhrSafetyMinutes: 1
            )
        case .egyptian:
            return CalculationParameters(
                fajrAngle: 19.5,
                ishaAngle: 17.5,
                madhab: .shafi,
                highLatitudeRule: .middleOfTheNight,
                adjustments: .zero,
                dhuhrSafetyMinutes: 1
            )
        case .karachi:
            return CalculationParameters(
                fajrAngle: 18.0,
                ishaAngle: 18.0,
                madhab: .hanafi,
                highLatitudeRule: .middleOfTheNight,
                adjustments: .zero,
                dhuhrSafetyMinutes: 1
            )
        case .custom:
            return CalculationParameters(
                fajrAngle: 18.0,
                ishaAngle: 18.0,
                madhab: .shafi,
                highLatitudeRule: .middleOfTheNight,
                adjustments: .zero,
                dhuhrSafetyMinutes: 1
            )
        }
    }

    /// Automatically suggests the most appropriate method given an ISO 3166-1 alpha-2 country code.
    public static func suggested(forCountryCode countryCode: String) -> CalculationMethod {
        switch countryCode.uppercased() {
        case "MY":
            return .jakim
        case "SG":
            return .muis
        case "SA", "AE", "KW", "BH", "QA", "OM", "YE":
            return .ummAlQura
        case "US", "CA":
            return .isna
        case "EG", "SD", "LY", "TN", "DZ", "MA", "SY", "JO", "LB", "PS":
            return .egyptian
        case "PK", "IN", "BD", "AF":
            return .karachi
        default:
            return .muslimWorldLeague
        }
    }
}
