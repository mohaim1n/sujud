import Foundation

/// Notification sound options for prayer reminders and adhan.
public enum NotificationSoundOption: String, CaseIterable, Codable, Sendable, Identifiable {
    case adhanShort
    case gentleChime
    case standardBeep
    case hapticOnly

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .adhanShort: return "Takbir & Adhan (Short)"
        case .gentleChime: return "Gentle Chime"
        case .standardBeep: return "Standard Alert"
        case .hapticOnly: return "Haptic / Vibration Only"
        }
    }

    /// Associated audio asset file name (or nil for default/haptic).
    public var soundFileName: String? {
        switch self {
        case .adhanShort: return "adhan_short.aiff"
        case .gentleChime: return "chime_gentle.aiff"
        case .standardBeep: return nil // System default alert
        case .hapticOnly: return nil
        }
    }
}

/// Boundary rule defining when the Isha prayer window ends.
public enum IshaWindowEndRule: String, CaseIterable, Codable, Sendable {
    /// Islamic Midnight: midpoint between Maghrib and tomorrow's Fajr (recommended).
    case islamicMidnight
    /// One-third of the night.
    case oneThirdOfNight
    /// Continues until tomorrow's Fajr begins.
    case untilFajr

    public var displayName: String {
        switch self {
        case .islamicMidnight: return "Islamic Midnight (Midpoint to Fajr)"
        case .oneThirdOfNight: return "First Third of the Night"
        case .untilFajr: return "Until Fajr Adhan"
        }
    }
}

/// Supported app localization languages.
public enum AppLanguage: String, CaseIterable, Codable, Sendable, Identifiable {
    case system
    case english
    case malay
    case arabic

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system: return "System Default"
        case .english: return "English"
        case .malay: return "Bahasa Melayu"
        case .arabic: return "العربية (Arabic)"
        }
    }

    public var languageCode: String? {
        switch self {
        case .system: return nil
        case .english: return "en"
        case .malay: return "ms"
        case .arabic: return "ar"
        }
    }

    public var isRightToLeft: Bool {
        return self == .arabic
    }
}

/// Complete persisted user settings state.
public struct UserSettingsState: Codable, Equatable, Sendable {
    // Notifications
    public var notificationsEnabled: Bool
    public var notifyFajr: Bool
    public var notifySunrise: Bool
    public var notifyDhuhr: Bool
    public var notifyAsr: Bool
    public var notifyMaghrib: Bool
    public var notifyIsha: Bool

    // Escalating Reminders
    public var escalatingRemindersEnabled: Bool
    public var escalatingIntervalsMinutes: [Int]
    public var ishaWindowEndRule: IshaWindowEndRule

    // Sound & Appearance
    public var soundOption: NotificationSoundOption
    public var appLanguage: AppLanguage

    // Verification Thresholds
    public var verificationConfig: VerificationConfig

    // Privacy & Consent
    public var hasAgreedToPrivacyConsent: Bool

    public init(
        notificationsEnabled: Bool = true,
        notifyFajr: Bool = true,
        notifySunrise: Bool = false,
        notifyDhuhr: Bool = true,
        notifyAsr: Bool = true,
        notifyMaghrib: Bool = true,
        notifyIsha: Bool = true,
        escalatingRemindersEnabled: Bool = true,
        escalatingIntervalsMinutes: [Int] = [15, 30, 60],
        ishaWindowEndRule: IshaWindowEndRule = .islamicMidnight,
        soundOption: NotificationSoundOption = .adhanShort,
        appLanguage: AppLanguage = .system,
        verificationConfig: VerificationConfig = .default,
        hasAgreedToPrivacyConsent: Bool = false
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.notifyFajr = notifyFajr
        self.notifySunrise = notifySunrise
        self.notifyDhuhr = notifyDhuhr
        self.notifyAsr = notifyAsr
        self.notifyMaghrib = notifyMaghrib
        self.notifyIsha = notifyIsha
        self.escalatingRemindersEnabled = escalatingRemindersEnabled
        self.escalatingIntervalsMinutes = escalatingIntervalsMinutes
        self.ishaWindowEndRule = ishaWindowEndRule
        self.soundOption = soundOption
        self.appLanguage = appLanguage
        self.verificationConfig = verificationConfig
        self.hasAgreedToPrivacyConsent = hasAgreedToPrivacyConsent
    }

    public static let `default` = UserSettingsState()

    public func isPrayerEnabled(_ prayer: Prayer) -> Bool {
        switch prayer {
        case .fajr: return notifyFajr
        case .sunrise: return notifySunrise
        case .dhuhr: return notifyDhuhr
        case .asr: return notifyAsr
        case .maghrib: return notifyMaghrib
        case .isha: return notifyIsha
        }
    }
}
