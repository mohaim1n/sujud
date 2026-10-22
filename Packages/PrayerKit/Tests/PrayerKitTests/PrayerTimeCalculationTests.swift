import XCTest
@testable import PrayerKit

final class PrayerTimeCalculationTests: XCTestCase {

    var calculator: PrayerTimeCalculator!

    override func setUp() {
        super.setUp()
        calculator = PrayerTimeCalculator()
    }

    // MARK: - Test City 1: Kuala Lumpur, Malaysia (JAKIM Method)

    func testKualaLumpurJakimTimes() {
        // Date: 2026-03-15
        // Coordinates: Lat 3.1390 N, Lon 101.6869 E
        // JAKIM standard: Fajr 20°, Isha 18°, Shafi, +2 min adjustments
        let timeZone = TimeZone(identifier: "Asia/Kuala_Lumpur")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 15
        components.hour = 12
        let testDate = calendar.date(from: components)!

        let coordinates = Coordinates.kualaLumpur
        let params = CalculationMethod.jakim.defaultParameters

        let times = calculator.calculateTimes(
            for: testDate,
            coordinates: coordinates,
            parameters: params,
            timeZone: timeZone
        )

        // Helper to extract (hour, minute) in target timezone
        func timeOfDay(from date: Date) -> (hour: Int, minute: Int) {
            let comp = calendar.dateComponents([.hour, .minute], from: date)
            return (comp.hour ?? 0, comp.minute ?? 0)
        }

        let fajr = timeOfDay(from: times.fajr)
        let sunrise = timeOfDay(from: times.sunrise)
        let dhuhr = timeOfDay(from: times.dhuhr)
        let asr = timeOfDay(from: times.asr)
        let maghrib = timeOfDay(from: times.maghrib)
        let isha = timeOfDay(from: times.isha)

        // Official JAKIM benchmarks for Kuala Lumpur on mid-March:
        // Subuh: ~06:05 (±2m)
        // Syuruk: ~07:18 (±2m)
        // Zohor: ~13:25 (±2m)
        // Asar: ~16:29 (±2m)
        // Maghrib: ~19:26 (±2m)
        // Isyak: ~20:35 (±2m)

        let fajrTotalMinutes = fajr.hour * 60 + fajr.minute
        let dhuhrTotalMinutes = dhuhr.hour * 60 + dhuhr.minute
        let maghribTotalMinutes = maghrib.hour * 60 + maghrib.minute

        XCTAssertEqual(fajr.hour, 6, "Fajr in KL should be in the 6 AM hour")
        XCTAssertTrue((5...15).contains(fajr.minute), "Fajr should be ~06:05-06:10, got: \(fajr.hour):\(fajr.minute)")

        XCTAssertEqual(dhuhr.hour, 13, "Dhuhr in KL should be at 1 PM")
        XCTAssertTrue((20...30).contains(dhuhr.minute), "Dhuhr should be ~13:25, got: \(dhuhr.hour):\(dhuhr.minute)")

        XCTAssertEqual(maghrib.hour, 19, "Maghrib in KL should be at 7 PM")
        XCTAssertTrue((20...30).contains(maghrib.minute), "Maghrib should be ~19:26, got: \(maghrib.hour):\(maghrib.minute)")

        XCTAssertEqual(isha.hour, 20, "Isha in KL should be at 8 PM")
        XCTAssertTrue((30...40).contains(isha.minute), "Isha should be ~20:35, got: \(isha.hour):\(isha.minute)")

        // Order check
        XCTAssertLessThan(fajrTotalMinutes, dhuhrTotalMinutes)
        XCTAssertLessThan(dhuhrTotalMinutes, maghribTotalMinutes)
    }

    // MARK: - Test City 2: Makkah al-Mukarramah, Saudi Arabia (Umm al-Qura Method)

    func testMakkahUmmAlQuraTimes() {
        // Date: 2026-03-15
        // Coordinates: Lat 21.4225 N, Lon 39.8262 E
        // Umm al-Qura: Fajr 18.5°, Isha 90 min interval after Maghrib
        let timeZone = TimeZone(identifier: "Asia/Riyadh")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 15
        components.hour = 12
        let testDate = calendar.date(from: components)!

        let coordinates = Coordinates.makkah
        let params = CalculationMethod.ummAlQura.defaultParameters

        let times = calculator.calculateTimes(
            for: testDate,
            coordinates: coordinates,
            parameters: params,
            timeZone: timeZone
        )

        // Verify Umm al-Qura's exact rule: Isha must be precisely 90 minutes after Maghrib
        let ishaMaghribDiffMinutes = Int(times.isha.timeIntervalSince(times.maghrib) / 60.0)
        XCTAssertEqual(ishaMaghribDiffMinutes, 90, "Umm al-Qura Isha must be exactly 90 minutes after Maghrib")

        let dhuhrComp = calendar.dateComponents([.hour, .minute], from: times.dhuhr)
        XCTAssertEqual(dhuhrComp.hour, 12, "Dhuhr in Makkah is around 12:25-12:35 PM")

        let maghribComp = calendar.dateComponents([.hour, .minute], from: times.maghrib)
        XCTAssertEqual(maghribComp.hour, 18, "Maghrib in Makkah mid-March is around 18:25-18:35")
    }

    // MARK: - Test City 3: London, UK (Muslim World League Method)

    func testLondonMuslimWorldLeagueTimes() {
        // Date: 2026-06-15 (Summer solstice proximity - high latitude)
        let timeZone = TimeZone(identifier: "Europe/London")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 15
        components.hour = 12
        let testDate = calendar.date(from: components)!

        let coordinates = Coordinates.london
        let params = CalculationMethod.muslimWorldLeague.defaultParameters

        let times = calculator.calculateTimes(
            for: testDate,
            coordinates: coordinates,
            parameters: params,
            timeZone: timeZone
        )

        // Ensure chronological progression
        XCTAssertLessThan(times.fajr, times.sunrise)
        XCTAssertLessThan(times.sunrise, times.dhuhr)
        XCTAssertLessThan(times.dhuhr, times.asr)
        XCTAssertLessThan(times.asr, times.maghrib)
        XCTAssertLessThan(times.maghrib, times.isha)
    }

    // MARK: - Test 30-Day Range Precalculation

    func testThirtyDayRangeCalculation() {
        let service = PrayerTimeService(calculator: calculator)
        let timesList = service.prayerTimesRange(
            startDate: Date(),
            days: 30,
            coordinates: Coordinates.kualaLumpur,
            parameters: CalculationMethod.jakim.defaultParameters,
            timeZone: TimeZone(identifier: "Asia/Kuala_Lumpur")!
        )

        XCTAssertEqual(timesList.count, 30, "Should generate exactly 30 days of pre-calculated prayer times")
        for i in 0..<29 {
            XCTAssertLessThan(timesList[i].date, timesList[i+1].date)
        }
    }
}
