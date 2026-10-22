import Foundation

/// Protocol for calculating and caching prayer times across iOS and watchOS.
public protocol PrayerTimeServiceProtocol: Sendable {
    func prayerTimes(
        for date: Date,
        coordinates: Coordinates,
        parameters: CalculationParameters,
        timeZone: TimeZone
    ) -> PrayerTimes

    func prayerTimesRange(
        startDate: Date,
        days: Int,
        coordinates: Coordinates,
        parameters: CalculationParameters,
        timeZone: TimeZone
    ) -> [PrayerTimes]

    func nextUpcomingPrayer(
        from referenceDate: Date,
        coordinates: Coordinates,
        parameters: CalculationParameters,
        timeZone: TimeZone
    ) -> (prayer: Prayer, time: Date)
}

/// Thread-safe service for computing, caching, and serving daily prayer times.
public final class PrayerTimeService: PrayerTimeServiceProtocol {

    private let calculator: PrayerTimeCalculator

    public init(calculator: PrayerTimeCalculator = PrayerTimeCalculator()) {
        self.calculator = calculator
    }

    /// Computes prayer times for a single date.
    public func prayerTimes(
        for date: Date,
        coordinates: Coordinates,
        parameters: CalculationParameters,
        timeZone: TimeZone = .current
    ) -> PrayerTimes {
        return calculator.calculateTimes(
            for: date,
            coordinates: coordinates,
            parameters: parameters,
            timeZone: timeZone
        )
    }

    /// Pre-calculates and caches a multi-day window (e.g. 30 days) to guarantee offline availability.
    public func prayerTimesRange(
        startDate: Date,
        days: Int = 30,
        coordinates: Coordinates,
        parameters: CalculationParameters,
        timeZone: TimeZone = .current
    ) -> [PrayerTimes] {
        var results: [PrayerTimes] = []
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        for dayOffset in 0..<max(1, days) {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else {
                continue
            }
            let times = calculator.calculateTimes(
                for: targetDate,
                coordinates: coordinates,
                parameters: parameters,
                timeZone: timeZone
            )
            results.append(times)
        }
        return results
    }

    /// Finds the next upcoming prayer, seamlessly rolling over to tomorrow's Fajr if tonight's Isha has passed.
    public func nextUpcomingPrayer(
        from referenceDate: Date = Date(),
        coordinates: Coordinates,
        parameters: CalculationParameters,
        timeZone: TimeZone = .current
    ) -> (prayer: Prayer, time: Date) {
        let todayTimes = prayerTimes(
            for: referenceDate,
            coordinates: coordinates,
            parameters: parameters,
            timeZone: timeZone
        )

        if let upcoming = todayTimes.nextPrayer(at: referenceDate) {
            return upcoming
        }

        // Past today's Isha -> roll over to tomorrow's Fajr
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate.addingTimeInterval(86400)
        let tomorrowTimes = prayerTimes(
            for: tomorrow,
            coordinates: coordinates,
            parameters: parameters,
            timeZone: timeZone
        )
        return (.fajr, tomorrowTimes.fajr)
    }
}
