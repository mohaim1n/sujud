import Foundation

/// Centralized localization dictionary supporting English, Bahasa Melayu, and Arabic.
public enum PrayerLocalizer {

    public static func string(for key: String, language: AppLanguage = .system) -> String {
        let code: String
        if let langCode = language.languageCode {
            code = langCode
        } else {
            code = Locale.current.language.languageCode?.identifier.lowercased() ?? "en"
        }

        switch code {
        case "ar":
            return arabicStrings[key] ?? englishStrings[key] ?? key
        case "ms", "id":
            return malayStrings[key] ?? englishStrings[key] ?? key
        default:
            return englishStrings[key] ?? key
        }
    }

    private static let englishStrings: [String: String] = [
        "app_name": "Sujud",
        "tagline": "Salah Companion",
        "next_prayer": "Next Prayer",
        "aligned_kaaba": "Aligned with the Kaaba",
        "turn_left": "Turn left",
        "turn_right": "Turn right",
        "start_prayer": "Start Prayer",
        "finish_prayer": "Finish Prayer",
        "i_prayed": "I Prayed",
        "rakah": "Rakah",
        "confirmed": "Confirmed",
        "partial": "Partially Verified",
        "self_reported": "Self-Reported",
        "missed": "Missed"
    ]

    private static let malayStrings: [String: String] = [
        "app_name": "Sujud",
        "tagline": "Teman Solat Anda",
        "next_prayer": "Solat Seterusnya",
        "aligned_kaaba": "Menghadap Kiblat",
        "turn_left": "Pusing ke kiri",
        "turn_right": "Pusing ke kanan",
        "start_prayer": "Mula Solat",
        "finish_prayer": "Selesai Solat",
        "i_prayed": "Saya Telah Solat",
        "rakah": "Rakaat",
        "confirmed": "Disahkan",
        "partial": "Separa Sah",
        "self_reported": "Dilapor Sendiri",
        "missed": "Terlepas"
    ]

    private static let arabicStrings: [String: String] = [
        "app_name": "سجود",
        "tagline": "رفيق الصلاة",
        "next_prayer": "الصلاة القادمة",
        "aligned_kaaba": "في اتجاه القبلة",
        "turn_left": "استدر يساراً",
        "turn_right": "استدر يميناً",
        "start_prayer": "بدء الصلاة",
        "finish_prayer": "إنهاء الصلاة",
        "i_prayed": "صليت",
        "rakah": "ركعة",
        "confirmed": "مؤكدة",
        "partial": "مؤكدة جزئياً",
        "self_reported": "مسجلة يدوياً",
        "missed": "فائتة"
    ]
}
