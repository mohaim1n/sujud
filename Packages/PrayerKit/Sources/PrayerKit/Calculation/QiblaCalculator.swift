import Foundation

/// Mathematical calculator for Qibla bearing (direction to the Kaaba) and distance.
public final class QiblaCalculator: Sendable {

    /// Coordinates of the Holy Kaaba in Makkah al-Mukarramah.
    public static let kaabaCoordinates = Coordinates(
        latitude: Qibla.kaabaLatitude,
        longitude: Qibla.kaabaLongitude,
        placeName: "Holy Kaaba, Makkah"
    )

    public init() {}

    /// Calculates the Qibla bearing and distance for a given observer's coordinates.
    public func calculateQibla(for observer: Coordinates) -> Qibla {
        let lat1 = observer.latitude * AstronomicalMath.degToRad
        let lon1 = observer.longitude * AstronomicalMath.degToRad
        let lat2 = Qibla.kaabaLatitude * AstronomicalMath.degToRad
        let lon2 = Qibla.kaabaLongitude * AstronomicalMath.degToRad

        let deltaLon = lon2 - lon1

        // Great-circle forward azimuth formula:
        // y = sin(dLon) * cos(lat2)
        // x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)

        var bearing = atan2(y, x) * AstronomicalMath.radToDeg
        bearing = AstronomicalMath.normalizeDegrees(bearing)

        // Haversine geodesic distance in kilometers:
        let deltaLat = lat2 - lat1
        let a = sin(deltaLat / 2.0) * sin(deltaLat / 2.0) +
                cos(lat1) * cos(lat2) * sin(deltaLon / 2.0) * sin(deltaLon / 2.0)
        let c = 2.0 * atan2(sqrt(a), sqrt(max(0, 1.0 - a)))
        let earthRadiusKm = 6371.0
        let distance = earthRadiusKm * c

        return Qibla(
            observer: observer,
            bearing: bearing,
            distanceKilometers: distance
        )
    }
}
