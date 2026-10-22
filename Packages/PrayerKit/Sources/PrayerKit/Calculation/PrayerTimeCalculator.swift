import Foundation

/// High-precision astronomical engine calculating the daily Islamic prayer times.
public final class PrayerTimeCalculator: Sendable {

    public init() {}

    /// Calculates prayer times for a specified date, coordinates, and configuration parameters.
    public func calculateTimes(
        for date: Date,
        coordinates: Coordinates,
        parameters: CalculationParameters,
        timeZone: TimeZone = .current
    ) -> PrayerTimes {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 2026
        let month = components.month ?? 1
        let day = components.day ?? 1

        // Initial Julian Day at Greenwich noon (12:00 UTC)
        let jd = AstronomicalMath.julianDay(year: year, month: month, day: day, hour: 12.0)
        let solar = SolarCoordinates(julianDay: jd)

        // Solar transit (approximate Dhuhr base) in UTC hours
        let transitUtcHours = 12.0 - (solar.equationOfTime / 60.0) - (coordinates.longitude / 15.0)

        // Sunrise & Sunset solar altitude angle
        // -0.8333° standard (34 arcmin refraction + 16 arcmin semi-diameter)
        // Elevation correction: -0.0347 * sqrt(h)
        let elevationAdjustment = coordinates.elevation > 0 ? (0.0347 * sqrt(coordinates.elevation)) : 0.0
        let sunriseAltitude = -0.8333 - elevationAdjustment

        // Hour angle for sunrise/sunset
        let sunriseHourAngle = solar.hourAngle(
            forAltitude: sunriseAltitude,
            latitude: coordinates.latitude
        ) ?? 90.0

        let sunriseUtcHours = transitUtcHours - (sunriseHourAngle / 15.0)
        let sunsetUtcHours = transitUtcHours + (sunriseHourAngle / 15.0)
        let nightDurationHours = 24.0 - (sunsetUtcHours - sunriseUtcHours)

        // 1. Dhuhr (solar transit + safety margin)
        let dhuhrUtcHours = transitUtcHours + (Double(parameters.dhuhrSafetyMinutes) / 60.0)

        // 2. Asr (shadow calculation)
        let asrHourAngle = solar.asrHourAngle(
            shadowMultiplier: parameters.madhab.shadowMultiplier,
            latitude: coordinates.latitude
        ) ?? (sunriseHourAngle * 0.5)
        let asrUtcHours = transitUtcHours + (asrHourAngle / 15.0)

        // 3. Maghrib
        let maghribUtcHours: Double
        if let interval = parameters.maghribIntervalMinutes {
            maghribUtcHours = sunsetUtcHours + (Double(interval) / 60.0)
        } else {
            maghribUtcHours = sunsetUtcHours
        }

        // 4. Fajr
        let fajrUtcHours: Double
        if let fajrAngleVal = solar.hourAngle(forAltitude: -parameters.fajrAngle, latitude: coordinates.latitude) {
            fajrUtcHours = transitUtcHours - (fajrAngleVal / 15.0)
        } else {
            // High-latitude fallback
            fajrUtcHours = applyHighLatitudeRule(
                rule: parameters.highLatitudeRule,
                nightDuration: nightDurationHours,
                angle: parameters.fajrAngle,
                baseTime: sunriseUtcHours,
                isMorning: true
            )
        }

        // 5. Isha
        let ishaUtcHours: Double
        if let interval = parameters.ishaIntervalMinutes {
            ishaUtcHours = maghribUtcHours + (Double(interval) / 60.0)
        } else if let ishaAngle = parameters.ishaAngle,
                  let ishaHourAngleVal = solar.hourAngle(forAltitude: -ishaAngle, latitude: coordinates.latitude) {
            ishaUtcHours = transitUtcHours + (ishaHourAngleVal / 15.0)
        } else {
            let angle = parameters.ishaAngle ?? 18.0
            ishaUtcHours = applyHighLatitudeRule(
                rule: parameters.highLatitudeRule,
                nightDuration: nightDurationHours,
                angle: angle,
                baseTime: sunsetUtcHours,
                isMorning: false
            )
        }

        // Convert UTC decimal hours into Date instances
        var fajrDate = dateFromUtcHours(fajrUtcHours, on: date, calendar: calendar)
        var sunriseDate = dateFromUtcHours(sunriseUtcHours, on: date, calendar: calendar)
        var dhuhrDate = dateFromUtcHours(dhuhrUtcHours, on: date, calendar: calendar)
        var asrDate = dateFromUtcHours(asrUtcHours, on: date, calendar: calendar)
        var maghribDate = dateFromUtcHours(maghribUtcHours, on: date, calendar: calendar)
        var ishaDate = dateFromUtcHours(ishaUtcHours, on: date, calendar: calendar)

        // Apply custom safety minute adjustments
        fajrDate = fajrDate.addingTimeInterval(Double(parameters.adjustments.fajr * 60))
        sunriseDate = sunriseDate.addingTimeInterval(Double(parameters.adjustments.sunrise * 60))
        dhuhrDate = dhuhrDate.addingTimeInterval(Double(parameters.adjustments.dhuhr * 60))
        asrDate = asrDate.addingTimeInterval(Double(parameters.adjustments.asr * 60))
        maghribDate = maghribDate.addingTimeInterval(Double(parameters.adjustments.maghrib * 60))
        ishaDate = ishaDate.addingTimeInterval(Double(parameters.adjustments.isha * 60))

        return PrayerTimes(
            date: calendar.startOfDay(for: date),
            coordinates: coordinates,
            parameters: parameters,
            timeZone: timeZone,
            fajr: fajrDate,
            sunrise: sunriseDate,
            dhuhr: dhuhrDate,
            asr: asrDate,
            maghrib: maghribDate,
            isha: ishaDate
        )
    }

    // MARK: - High Latitude Fallback Helper

    private func applyHighLatitudeRule(
        rule: HighLatitudeRule,
        nightDuration: Double,
        angle: Double,
        baseTime: Double,
        isMorning: Bool
    ) -> Double {
        let nightFraction: Double
        switch rule {
        case .middleOfTheNight:
            nightFraction = 1.0 / 2.0
        case .seventhOfTheNight:
            nightFraction = 1.0 / 7.0
        case .twilightAngle:
            nightFraction = angle / 60.0
        }

        let portion = nightDuration * nightFraction
        if isMorning {
            return baseTime - portion
        } else {
            return baseTime + portion
        }
    }

    // MARK: - UTC Hours to Date Conversion

    private func dateFromUtcHours(_ utcHours: Double, on date: Date, calendar: Calendar) -> Date {
        let normalizedHours = AstronomicalMath.normalizeHours(utcHours)
        let totalSeconds = Int((normalizedHours * 3600.0).rounded())

        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        var gmtCalendar = Calendar(identifier: .gregorian)
        gmtCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let targetComponents = calendar.dateComponents([.year, .month, .day], from: date)

        var dateComponents = DateComponents()
        dateComponents.year = targetComponents.year
        dateComponents.month = targetComponents.month
        dateComponents.day = targetComponents.day
        dateComponents.hour = hours
        dateComponents.minute = minutes
        dateComponents.second = seconds

        return gmtCalendar.date(from: dateComponents) ?? date
    }
}
