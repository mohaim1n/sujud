import Foundation

/// Protocol for Qibla calculation and heading smoothing.
public protocol QiblaServiceProtocol: Sendable {
    func qibla(for coordinates: Coordinates) -> Qibla
    func smoothHeading(current: Double, target: Double, factor: Double) -> Double
}

/// Service providing Qibla direction, distance, and low-pass filtered compass rotation.
public final class QiblaService: QiblaServiceProtocol {

    private let calculator: QiblaCalculator

    public init(calculator: QiblaCalculator = QiblaCalculator()) {
        self.calculator = calculator
    }

    /// Calculates Qibla direction and distance from observer location.
    public func qibla(for coordinates: Coordinates) -> Qibla {
        return calculator.calculateQibla(for: coordinates)
    }

    /// Applies a low-pass filter across circular degrees to eliminate compass jitter while ensuring shortest-path wrap.
    /// - Parameters:
    ///   - current: Current smoothed heading angle in degrees.
    ///   - target: New raw heading sample from CoreLocation.
    ///   - factor: Filter alpha factor between 0.0 (no change) and 1.0 (immediate jump). Typically 0.15 - 0.25.
    public func smoothHeading(current: Double, target: Double, factor: Double = 0.20) -> Double {
        var diff = target - current
        // Handle 0° / 360° boundary wraparound
        while diff > 180.0 { diff -= 360.0 }
        while diff < -180.0 { diff += 360.0 }

        let smoothed = current + (diff * factor)
        return AstronomicalMath.normalizeDegrees(smoothed)
    }
}
