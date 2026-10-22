import Foundation

/// Represents the instantaneous solar position (declination, transit, equation of time) for a given Julian Day.
public struct SolarCoordinates: Sendable {
    /// Declination of the sun in degrees.
    public let declination: Double

    /// Right ascension of the sun in degrees.
    public let rightAscension: Double

    /// Apparent sidereal time at Greenwich in degrees.
    public let apparentSiderealTime: Double

    /// Equation of time in minutes.
    public let equationOfTime: Double

    public init(julianDay: Double) {
        let t = AstronomicalMath.julianCentury(julianDay: julianDay)

        // Geometric Mean Longitude of the Sun (Meeus 25.2)
        let l0 = AstronomicalMath.normalizeDegrees(280.46646 + t * (36000.76983 + t * 0.0003032))

        // Mean Anomaly of the Sun (Meeus 25.3)
        let m = AstronomicalMath.normalizeDegrees(357.52911 + t * (35999.05029 - t * 0.0001537))

        // Eccentricity of the Earth's orbit (Meeus 25.4)
        let e = 0.016708634 - t * (0.000042037 + t * 0.0000001267)

        // Sun's Equation of the Center (Meeus 25.5)
        let c = AstronomicalMath.sinDeg(m) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
                AstronomicalMath.sinDeg(2.0 * m) * (0.019993 - 0.000101 * t) +
                AstronomicalMath.sinDeg(3.0 * m) * 0.000289

        // Sun's True Longitude
        let sunTrueLongitude = l0 + c

        // Sun's Apparent Longitude (corrected for nutation and aberration)
        let omega = 125.04 - 1934.136 * t
        let lambda = sunTrueLongitude - 0.00569 - 0.00478 * AstronomicalMath.sinDeg(omega)

        // Mean Obliquity of the Ecliptic (Meeus 22.2)
        let seconds = 21.448 - t * (46.8150 + t * (0.00059 - t * 0.001813))
        let eps0 = 23.0 + (26.0 + (seconds / 60.0)) / 60.0

        // Corrected Obliquity
        let epsilon = eps0 + 0.00256 * AstronomicalMath.cosDeg(omega)

        // Declination delta (Meeus 25.7)
        let sinDelta = AstronomicalMath.sinDeg(epsilon) * AstronomicalMath.sinDeg(lambda)
        self.declination = AstronomicalMath.asinDeg(sinDelta)

        // Right Ascension alpha (Meeus 25.6)
        let alpha = AstronomicalMath.atan2Deg(
            y: AstronomicalMath.cosDeg(epsilon) * AstronomicalMath.sinDeg(lambda),
            x: AstronomicalMath.cosDeg(lambda)
        )
        self.rightAscension = alpha

        // Mean Sidereal Time at Greenwich (Meeus 12.4)
        let theta0 = 280.46061837 + 360.98564736629 * (julianDay - 2451545.0) +
                     t * t * (0.000387933 - t / 38710000.0)
        self.apparentSiderealTime = AstronomicalMath.normalizeDegrees(theta0)

        // Equation of Time in minutes: EoT = (L0 - alpha) / 15 * 60
        var diff = l0 - alpha
        if diff > 180.0 { diff -= 360.0 }
        if diff < -180.0 { diff += 360.0 }
        self.equationOfTime = diff * 4.0
    }

    /// Computes the hour angle (in degrees) for a target solar altitude angle above/below the horizon.
    /// Returns nil if the sun does not reach the specified altitude at this latitude (e.g. midnight sun or polar night).
    public func hourAngle(forAltitude angle: Double, latitude: Double) -> Double? {
        let sinAngle = AstronomicalMath.sinDeg(angle)
        let sinLat = AstronomicalMath.sinDeg(latitude)
        let cosLat = AstronomicalMath.cosDeg(latitude)
        let sinDec = AstronomicalMath.sinDeg(declination)
        let cosDec = AstronomicalMath.cosDeg(declination)

        let cosH = (sinAngle - sinLat * sinDec) / (cosLat * cosDec)
        guard cosH >= -1.0 && cosH <= 1.0 else {
            return nil
        }
        return AstronomicalMath.acosDeg(cosH)
    }

    /// Hour angle for Asr prayer based on shadow multiplier (1 for Shafi, 2 for Hanafi).
    public func asrHourAngle(shadowMultiplier: Double, latitude: Double) -> Double? {
        // Shadow ratio: arccot(t + tan(|lat - dec|))
        let latDecDiff = abs(latitude - declination)
        let tanLatDecDiff = AstronomicalMath.tanDeg(latDecDiff)
        let cotAngle = shadowMultiplier + tanLatDecDiff
        let asrAltitude = AstronomicalMath.atanDeg(1.0 / cotAngle)
        return hourAngle(forAltitude: asrAltitude, latitude: latitude)
    }
}
