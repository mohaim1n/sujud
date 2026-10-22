import Foundation

/// Mathematical and astronomical utilities implementing Jean Meeus algorithms.
public enum AstronomicalMath {
    /// Degrees to radians conversion factor.
    public static let degToRad: Double = .pi / 180.0
    /// Radians to degrees conversion factor.
    public static let radToDeg: Double = 180.0 / .pi

    /// Normalizes an angle in degrees into the range [0, 360).
    public static func normalizeDegrees(_ degrees: Double) -> Double {
        var result = degrees.truncatingRemainder(dividingBy: 360.0)
        if result < 0 {
            result += 360.0
        }
        return result
    }

    /// Normalizes hours into the range [0, 24).
    public static func normalizeHours(_ hours: Double) -> Double {
        var result = hours.truncatingRemainder(dividingBy: 24.0)
        if result < 0 {
            result += 24.0
        }
        return result
    }

    /// Trigonometric sine of an angle in degrees.
    public static func sinDeg(_ degrees: Double) -> Double {
        return sin(degrees * degToRad)
    }

    /// Trigonometric cosine of an angle in degrees.
    public static func cosDeg(_ degrees: Double) -> Double {
        return cos(degrees * degToRad)
    }

    /// Trigonometric tangent of an angle in degrees.
    public static func tanDeg(_ degrees: Double) -> Double {
        return tan(degrees * degToRad)
    }

    /// Inverse sine returning degrees.
    public static func asinDeg(_ value: Double) -> Double {
        return asin(max(-1.0, min(1.0, value))) * radToDeg
    }

    /// Inverse cosine returning degrees.
    public static func acosDeg(_ value: Double) -> Double {
        return acos(max(-1.0, min(1.0, value))) * radToDeg
    }

    /// Inverse tangent returning degrees.
    public static func atanDeg(_ value: Double) -> Double {
        return atan(value) * radToDeg
    }

    /// Two-argument inverse tangent returning degrees in range [0, 360).
    public static func atan2Deg(y: Double, x: Double) -> Double {
        return normalizeDegrees(atan2(y, x) * radToDeg)
    }

    /// Calculates Julian Day from Gregorian calendar date components at UTC.
    public static func julianDay(year: Int, month: Int, day: Int, hour: Double = 0.0) -> Double {
        var y = year
        var m = month

        if m <= 2 {
            y -= 1
            m += 12
        }

        let a = floor(Double(y) / 100.0)
        let b = 2.0 - a + floor(a / 4.0)

        let jd = floor(365.25 * Double(y + 4716)) +
                 floor(30.6001 * Double(m + 1)) +
                 Double(day) + b - 1524.5 + (hour / 24.0)
        return jd
    }

    /// Julian Century from J2000.0 epoch.
    public static func julianCentury(julianDay: Double) -> Double {
        return (julianDay - 2451545.0) / 36525.0
    }
}
