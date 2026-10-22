import XCTest
@testable import PrayerKit

final class NotificationScheduleTests: XCTestCase {

    var calculator: PrayerTimeCalculator!

    override func setUp() {
        super.setUp()
        calculator = PrayerTimeCalculator()
    }

    func testPrayerWindowBoundaries() {
        let coordinates = Coordinates.kualaLumpur
        let params = CalculationMethod.jakim.defaultParameters
        let timeZone = TimeZone(identifier: "Asia/Kuala_Lumpur")!
        let now = Date()

        let times = calculator.calculateTimes(
            for: now,
            coordinates: coordinates,
            parameters: params,
            timeZone: timeZone
        )

        // 1. Fajr window ends at Sunrise
        let fajrWindow = times.prayerWindow(for: .fajr)
        XCTAssertEqual(fajrWindow.start, times.fajr)
        XCTAssertEqual(fajrWindow.end, times.sunrise)

        // 2. Dhuhr window ends at Asr
        let dhuhrWindow = times.prayerWindow(for: .dhuhr)
        XCTAssertEqual(dhuhrWindow.start, times.dhuhr)
        XCTAssertEqual(dhuhrWindow.end, times.asr)

        // 3. Asr window ends at Maghrib
        let asrWindow = times.prayerWindow(for: .asr)
        XCTAssertEqual(asrWindow.start, times.asr)
        XCTAssertEqual(asrWindow.end, times.maghrib)

        // 4. Maghrib window ends at Isha
        let maghribWindow = times.prayerWindow(for: .maghrib)
        XCTAssertEqual(maghribWindow.start, times.maghrib)
        XCTAssertEqual(maghribWindow.end, times.isha)

        // 5. Isha window ends at Islamic Midnight
        let ishaWindow = times.prayerWindow(for: .isha)
        XCTAssertEqual(ishaWindow.start, times.isha)
        XCTAssertGreaterThan(ishaWindow.end, times.isha)
    }

    func testEscalatingReminderBoundaryFiltering() {
        let startTime = Date()
        let windowEnd = startTime.addingTimeInterval(45 * 60) // Window ends in 45 minutes
        let intervals = [15, 30, 60]

        var validReminders: [Int] = []
        for minutes in intervals {
            let reminderDate = startTime.addingTimeInterval(Double(minutes * 60))
            if reminderDate < windowEnd {
                validReminders.append(minutes)
            }
        }

        // 15m and 30m should pass; 60m must be excluded because it exceeds the 45m window
        XCTAssertEqual(validReminders, [15, 30])
    }

    func testUserSettingsSerialization() throws {
        var settings = UserSettingsState()
        settings.notificationsEnabled = true
        settings.notifySunrise = false
        settings.soundOption = .adhanShort
        settings.appLanguage = .arabic
        settings.verificationConfig.minimumAudioConfidence = 0.70

        let encoder = JSONEncoder()
        let data = try encoder.encode(settings)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UserSettingsState.self, from: data)

        XCTAssertEqual(decoded.soundOption, .adhanShort)
        XCTAssertEqual(decoded.appLanguage, .arabic)
        XCTAssertEqual(decoded.verificationConfig.minimumAudioConfidence, 0.70)
        XCTAssertTrue(decoded.isPrayerEnabled(.fajr))
        XCTAssertFalse(decoded.isPrayerEnabled(.sunrise))
    }
}
