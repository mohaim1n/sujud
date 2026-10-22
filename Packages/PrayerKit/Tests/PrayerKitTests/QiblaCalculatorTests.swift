import XCTest
@testable import PrayerKit

final class QiblaCalculatorTests: XCTestCase {

    var calculator: QiblaCalculator!
    var service: QiblaService!

    override func setUp() {
        super.setUp()
        calculator = QiblaCalculator()
        service = QiblaService(calculator: calculator)
    }

    // MARK: - Known Global Bearings

    func testNewYorkQiblaBearing() {
        // New York (40.7128° N, -74.0060° E)
        // Expected Qibla: approx 58.5° (ENE)
        let qibla = calculator.calculateQibla(for: Coordinates.newYork)
        XCTAssertEqual(qibla.bearing, 58.5, accuracy: 1.0, "New York Qibla should be approximately 58.5°")
        XCTAssertEqual(qibla.distanceKilometers, 10250.0, accuracy: 250.0)
    }

    func testLondonQiblaBearing() {
        // London (51.5074° N, -0.1278° E)
        // Expected Qibla: approx 118.9° (ESE)
        let qibla = calculator.calculateQibla(for: Coordinates.london)
        XCTAssertEqual(qibla.bearing, 118.9, accuracy: 1.0, "London Qibla should be approximately 118.9°")
        XCTAssertEqual(qibla.distanceKilometers, 4790.0, accuracy: 150.0)
    }

    func testKualaLumpurQiblaBearing() {
        // Kuala Lumpur (3.1390° N, 101.6869° E)
        // Expected Qibla: approx 292.9° (WNW)
        let qibla = calculator.calculateQibla(for: Coordinates.kualaLumpur)
        XCTAssertEqual(qibla.bearing, 292.9, accuracy: 1.0, "Kuala Lumpur Qibla should be approximately 292.9°")
        XCTAssertEqual(qibla.distanceKilometers, 7050.0, accuracy: 200.0)
    }

    func testSingaporeQiblaBearing() {
        // Singapore (1.3521° N, 103.8198° E)
        // Expected Qibla: approx 293.2° (WNW)
        let qibla = calculator.calculateQibla(for: Coordinates.singapore)
        XCTAssertEqual(qibla.bearing, 293.2, accuracy: 1.0, "Singapore Qibla should be approximately 293.2°")
    }

    // MARK: - Alignment Check (Within 3 Degrees)

    func testAlignmentDetection() {
        let qibla = calculator.calculateQibla(for: Coordinates.kualaLumpur)
        let targetBearing = qibla.bearing // ~292.9°

        // Exact alignment
        XCTAssertTrue(qibla.isAligned(deviceHeading: targetBearing, toleranceDegrees: 3.0))

        // Aligned within +2 degrees
        XCTAssertTrue(qibla.isAligned(deviceHeading: targetBearing + 2.0, toleranceDegrees: 3.0))

        // Aligned within -2 degrees
        XCTAssertTrue(qibla.isAligned(deviceHeading: targetBearing - 2.0, toleranceDegrees: 3.0))

        // Not aligned (+4 degrees)
        XCTAssertFalse(qibla.isAligned(deviceHeading: targetBearing + 4.0, toleranceDegrees: 3.0))

        // Not aligned (-4 degrees)
        XCTAssertFalse(qibla.isAligned(deviceHeading: targetBearing - 4.0, toleranceDegrees: 3.0))
    }

    // MARK: - Low-Pass Filter Smoothing

    func testSmoothHeadingFilter() {
        let currentHeading = 10.0
        let newRawHeading = 20.0
        let smoothed = service.smoothHeading(current: currentHeading, target: newRawHeading, factor: 0.20)
        XCTAssertEqual(smoothed, 12.0, accuracy: 0.01)

        // Wraparound test: 350° to 10° (crosses 0°)
        let wrapped = service.smoothHeading(current: 350.0, target: 10.0, factor: 0.50)
        XCTAssertEqual(wrapped, 0.0, accuracy: 0.01)
    }
}
