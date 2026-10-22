import Foundation

/// Calculated prayer times for a specific calendar day, geographic location, and calculation method.
public struct PrayerTimes: Codable, Equatable, Sendable {
    public let date: Date
    public let coordinates: Coordinates
    public let parameters: CalculationParameters
    public let timeZone: TimeZone

    public let fajr: Date
    public let sunrise: Date
    public let dhuhr: Date
    public let asr: Date
    public let maghrib: Date
    public let isha: Date

    public init(
        date: Date,
        coordinates: Coordinates,
        parameters: CalculationParameters,
        timeZone: TimeZone = .current,
        fajr: Date,
        sunrise: Date,
        dhuhr: Date,
        asr: Date,
        maghrib: Date,
        isha: Date
    ) {
        self.date = date
        self.coordinates = coordinates
        self.parameters = parameters
        self.timeZone = timeZone
        self.fajr = fajr
        self.sunrise = sunrise
        self.dhuhr = dhuhr
        self.asr = asr
        self.maghrib = maghrib
        self.isha = isha
    }

    /// Access the time for any specific prayer.
    public func time(for prayer: Prayer) -> Date {
        switch prayer {
        case .fajr: return fajr
        case .sunrise: return sunrise
        case .dhuhr: return dhuhr
        case .asr: return asr
        case .maghrib: return maghrib
        case .isha: return isha
        }
    }

    /// Identifies the active prayer at the given date/time, or nil if before Fajr or after Isha.
    public func currentPrayer(at date: Date = Date()) -> Prayer? {
        if date >= isha {
            return .isha
        } else if date >= maghrib {
            return .maghrib
        } else if date >= asr {
            return .asr
        } else if date >= dhuhr {
            return .dhuhr
        } else if date >= sunrise {
            return .sunrise
        } else if date >= fajr {
            return .fajr
        } else {
            return nil
        }
    }

    /// Returns the next upcoming prayer event along with its exact time.
    public func nextPrayer(at date: Date = Date()) -> (prayer: Prayer, time: Date)? {
        if date < fajr {
            return (.fajr, fajr)
        } else if date < sunrise {
            return (.sunrise, sunrise)
        } else if date < dhuhr {
            return (.dhuhr, dhuhr)
        } else if date < asr {
            return (.asr, asr)
        } else if date < maghrib {
            return (.maghrib, maghrib)
        } else if date < isha {
            return (.isha, isha)
        } else {
            // Beyond today's Isha, next prayer is tomorrow's Fajr (handled by service layer)
            return nil
        }
    }

    /// The time window for performing a prayer before it becomes missed.
    /// Fajr -> Sunrise
    /// Dhuhr -> Asr
    /// Asr -> Maghrib
    /// Maghrib -> Isha
    /// Isha -> Midnight (or tomorrow's Fajr)
    public func prayerWindow(for prayer: Prayer) -> (start: Date, end: Date) {
        switch prayer {
        case .fajr:
            return (fajr, sunrise)
        case .sunrise:
            return (sunrise, dhuhr)
        case .dhuhr:
            return (dhuhr, asr)
        case .asr:
            return (asr, maghrib)
        case .maghrib:
            return (maghrib, isha)
        case .isha:
            // Standard Islamic midnight: midpoint between sunset and tomorrow's sunrise,
            // or conservatively midpoint between Maghrib and Fajr
            let nightDuration = abs(fajr.addingTimeInterval(86400).timeIntervalSince(maghrib))
            let islamicMidnight = maghrib.addingTimeInterval(nightDuration / 2.0)
            return (isha, islamicMidnight)
        }
    }

    /// Formats the Islamic Hijri calendar date representation for this prayer date.
    public func hijriDateString(locale: Locale = .current) -> String {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = locale
        calendar.timeZone = timeZone

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Formats a clean countdown string (e.g. "2h 15m" or "42m") to the next prayer.
    public func countdownString(from referenceDate: Date = Date()) -> String? {
        guard let next = nextPrayer(at: referenceDate) else { return nil }
        let diff = max(0, Int(next.time.timeIntervalSince(referenceDate)))
        let hours = diff / 3600
        let minutes = (diff % 3600) / 60
        let seconds = diff % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
}
