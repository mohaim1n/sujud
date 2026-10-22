import Foundation

/// Represents one of the Islamic prayer times throughout the day.
public enum Prayer: String, CaseIterable, Codable, Sendable, Identifiable {
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha

    public var id: String { rawValue }

    /// Standard English display name.
    public var englishName: String {
        switch self {
        case .fajr: return "Fajr"
        case .sunrise: return "Sunrise"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }

    /// Arabic script name.
    public var arabicName: String {
        switch self {
        case .fajr: return "الفجر"
        case .sunrise: return "الشروق"
        case .dhuhr: return "الظهر"
        case .asr: return "العصر"
        case .maghrib: return "المغرب"
        case .isha: return "العشاء"
        }
    }

    /// Bahasa Melayu display name.
    public var malayName: String {
        switch self {
        case .fajr: return "Subuh"
        case .sunrise: return "Syuruk"
        case .dhuhr: return "Zohor"
        case .asr: return "Asar"
        case .maghrib: return "Maghrib"
        case .isha: return "Isyak"
        }
    }

    /// Localized name according to the specified locale identifier or system default.
    public func localizedName(locale: Locale = .current) -> String {
        let languageCode = locale.language.languageCode?.identifier.lowercased() ?? "en"
        switch languageCode {
        case "ar":
            return arabicName
        case "ms", "id":
            return malayName
        default:
            return englishName
        }
    }

    /// Required number of obligatory (fard) rakahs for this prayer.
    public var obligatoryRakahCount: Int {
        switch self {
        case .fajr: return 2
        case .sunrise: return 0
        case .dhuhr: return 4
        case .asr: return 4
        case .maghrib: return 3
        case .isha: return 4
        }
    }

    /// Whether this event is one of the five obligatory daily prayers.
    public var isObligatory: Bool {
        return self != .sunrise
    }

    /// The list of only the 5 obligatory prayers.
    public static var fivePrayers: [Prayer] {
        return [.fajr, .dhuhr, .asr, .maghrib, .isha]
    }

    /// SF Symbol icon suitable for watchOS and iOS.
    public var sfSymbolName: String {
        switch self {
        case .fajr: return "sun.horizon.fill"
        case .sunrise: return "sunrise.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "sun.and.horizon.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.stars.fill"
        }
    }
}
