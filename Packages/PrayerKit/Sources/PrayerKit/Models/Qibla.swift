import Foundation

/// Calculated Qibla direction and geographic distance from an observer's location to the Holy Kaaba in Makkah.
public struct Qibla: Codable, Equatable, Sendable {
    /// Holy Kaaba coordinates in Makkah al-Mukarramah.
    public static let kaabaLatitude: Double = 21.422487
    public static let kaabaLongitude: Double = 39.826206

    /// Coordinates of the observer.
    public let observer: Coordinates

    /// True heading bearing towards the Kaaba in degrees (0° to 360°, clockwise from true North).
    public let bearing: Double

    /// Great-circle geodesic distance to the Kaaba in kilometers.
    public let distanceKilometers: Double

    public init(observer: Coordinates, bearing: Double, distanceKilometers: Double) {
        self.observer = observer
        self.bearing = bearing
        self.distanceKilometers = distanceKilometers
    }

    /// Determines if a device heading is aligned with the Qibla within a specified angular tolerance (default 3°).
    public func isAligned(deviceHeading: Double, toleranceDegrees: Double = 3.0) -> Bool {
        let diff = abs(deltaAngle(deviceHeading: deviceHeading))
        return diff <= toleranceDegrees
    }

    /// Returns the shortest signed angular difference between the device heading and the Qibla bearing.
    /// Range: [-180°, +180°]. Negative means device should turn right, positive means turn left.
    public func deltaAngle(deviceHeading: Double) -> Double {
        var diff = bearing - deviceHeading
        while diff > 180.0 { diff -= 360.0 }
        while diff < -180.0 { diff += 360.0 }
        return diff
    }

    /// Formatted bearing string (e.g. "292° WNW").
    public var formattedBearing: String {
        let rounded = Int(bearing.rounded())
        return "\(rounded)° \(compassDirection(for: bearing))"
    }

    /// Formatted distance string (e.g. "7,142 km").
    public var formattedDistance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: distanceKilometers)) ?? "\(Int(distanceKilometers))"
        return "\(formatted) km"
    }

    private func compassDirection(for degrees: Double) -> String {
        let sectors = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                       "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((degrees + 11.25).truncatingRemainder(dividingBy: 360.0) / 22.5)
        guard index >= 0 && index < sectors.count else { return "N" }
        return sectors[index]
    }
}
