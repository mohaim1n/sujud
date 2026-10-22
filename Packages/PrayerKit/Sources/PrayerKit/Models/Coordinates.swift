import Foundation

/// Geographic coordinates for prayer time and Qibla calculation.
public struct Coordinates: Codable, Equatable, Sendable, Hashable {
    public let latitude: Double
    public let longitude: Double
    public let elevation: Double
    public let placeName: String?

    public init(
        latitude: Double,
        longitude: Double,
        elevation: Double = 0.0,
        placeName: String? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.placeName = placeName
    }

    /// Well-known coordinate presets for verification and unit testing.
    public static let makkah = Coordinates(
        latitude: 21.422487,
        longitude: 39.826206,
        elevation: 277.0,
        placeName: "Makkah al-Mukarramah, Saudi Arabia"
    )

    public static let kualaLumpur = Coordinates(
        latitude: 3.1390,
        longitude: 101.6869,
        elevation: 22.0,
        placeName: "Kuala Lumpur, Malaysia"
    )

    public static let singapore = Coordinates(
        latitude: 1.3521,
        longitude: 103.8198,
        elevation: 15.0,
        placeName: "Singapore"
    )

    public static let london = Coordinates(
        latitude: 51.5074,
        longitude: -0.1278,
        elevation: 11.0,
        placeName: "London, United Kingdom"
    )

    public static let newYork = Coordinates(
        latitude: 40.7128,
        longitude: -74.0060,
        elevation: 10.0,
        placeName: "New York, USA"
    )

    public static let cairo = Coordinates(
        latitude: 30.0444,
        longitude: 31.2357,
        elevation: 23.0,
        placeName: "Cairo, Egypt"
    )

    public static let karachi = Coordinates(
        latitude: 24.8607,
        longitude: 67.0011,
        elevation: 8.0,
        placeName: "Karachi, Pakistan"
    )
}
