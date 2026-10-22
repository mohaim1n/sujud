import Foundation
import CoreLocation
import Combine
import UIKit
import PrayerKit

/// Central location and device heading manager for Sujud.
/// Handles permission requests, reverse geocoding, significant location updates, and compass headings.
@MainActor
public final class LocationManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published public private(set) var coordinates: Coordinates?
    @Published public private(set) var placeName: String = "Detecting location..."
    @Published public private(set) var countryCode: String?
    @Published public private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public private(set) var locationError: String?

    // Heading (Compass)
    @Published public private(set) var currentHeading: Double = 0.0
    @Published public private(set) var headingAccuracy: Double = -1.0
    @Published public private(set) var isHeadingAvailable: Bool = false
    @Published public private(set) var requiresCalibration: Bool = false

    // MARK: - Private Properties

    private let clManager: CLLocationManager
    private let geocoder = CLGeocoder()
    private let qiblaService = QiblaService()
    private var lastRawHeading: Double = 0.0
    private var smoothedHeading: Double = 0.0
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .rigid)

    // Storage for offline cached location
    private let cachedLocationKey = "com.sujud.cachedLocation"
    private let cachedPlaceNameKey = "com.sujud.cachedPlaceName"
    private let cachedCountryCodeKey = "com.sujud.cachedCountryCode"

    public override init() {
        self.clManager = CLLocationManager()
        super.init()

        self.clManager.delegate = self
        self.clManager.desiredAccuracy = kCLLocationAccuracyKilometer
        self.clManager.distanceFilter = 1000.0 // 1 km movement threshold to save battery
        self.clManager.headingFilter = 0.5     // Update heading on 0.5 degree changes
        self.isHeadingAvailable = CLLocationManager.headingAvailable()

        // Load offline cached coordinates immediately
        loadCachedLocation()

        // Sync initial authorization
        self.authorizationStatus = clManager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            clManager.startUpdatingLocation()
            if isHeadingAvailable {
                clManager.startUpdatingHeading()
            }
        }
    }

    // MARK: - Public Actions

    /// Requests standard "When In Use" location authorization.
    public func requestAuthorization() {
        if authorizationStatus == .notDetermined {
            clManager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            locationError = "Location access was denied. Please enable location permissions in Settings for accurate prayer times."
        }
    }

    /// Starts device compass heading updates.
    public func startHeadingUpdates() {
        guard isHeadingAvailable else { return }
        clManager.startUpdatingHeading()
    }

    /// Stops heading updates when user leaves the Qibla screen to preserve battery.
    public func stopHeadingUpdates() {
        guard isHeadingAvailable else { return }
        clManager.stopUpdatingHeading()
    }

    /// Triggers alignment haptic feedback once when user achieves Kaaba alignment.
    public func triggerAlignmentHaptic() {
        hapticGenerator.prepare()
        hapticGenerator.impactOccurred()
    }

    // MARK: - Offline Storage

    private func saveCachedLocation(coords: Coordinates, place: String, country: String?) {
        UserDefaults.standard.set(coords.latitude, forKey: "\(cachedLocationKey).lat")
        UserDefaults.standard.set(coords.longitude, forKey: "\(cachedLocationKey).lon")
        UserDefaults.standard.set(coords.elevation, forKey: "\(cachedLocationKey).elev")
        UserDefaults.standard.set(place, forKey: cachedPlaceNameKey)
        if let country = country {
            UserDefaults.standard.set(country, forKey: cachedCountryCodeKey)
        }
    }

    private func loadCachedLocation() {
        let lat = UserDefaults.standard.double(forKey: "\(cachedLocationKey).lat")
        let lon = UserDefaults.standard.double(forKey: "\(cachedLocationKey).lon")
        let elev = UserDefaults.standard.double(forKey: "\(cachedLocationKey).elev")
        let place = UserDefaults.standard.string(forKey: cachedPlaceNameKey)
        let country = UserDefaults.standard.string(forKey: cachedCountryCodeKey)

        if lat != 0.0 || lon != 0.0 {
            let cached = Coordinates(latitude: lat, longitude: lon, elevation: elev, placeName: place)
            self.coordinates = cached
            self.placeName = place ?? "Saved Location"
            self.countryCode = country
        } else {
            // Default initial location: Makkah al-Mukarramah
            self.coordinates = Coordinates.makkah
            self.placeName = "Makkah al-Mukarramah"
            self.countryCode = "SA"
        }
    }

    // MARK: - Reverse Geocoding

    private func reverseGeocode(location: CLLocation) {
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            Task { @MainActor in
                if let error = error {
                    self.locationError = error.localizedDescription
                    return
                }

                if let placemark = placemarks?.first {
                    let city = placemark.locality ?? placemark.subAdministrativeArea ?? placemark.administrativeArea
                    let country = placemark.country
                    let countryCode = placemark.isoCountryCode

                    var formattedName = ""
                    if let city = city, let country = country {
                        formattedName = "\(city), \(country)"
                    } else if let country = country {
                        formattedName = country
                    } else {
                        formattedName = String(format: "%.4f°, %.4f°", location.coordinate.latitude, location.coordinate.longitude)
                    }

                    self.placeName = formattedName
                    self.countryCode = countryCode

                    let newCoords = Coordinates(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        elevation: location.altitude,
                        placeName: formattedName
                    )
                    self.coordinates = newCoords
                    self.saveCachedLocation(coords: newCoords, place: formattedName, country: countryCode)
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            self.locationError = nil
            manager.startUpdatingLocation()
            if isHeadingAvailable {
                manager.startUpdatingHeading()
            }
        case .denied, .restricted:
            self.locationError = "Location permission is disabled. Using saved location."
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }

        let newCoords = Coordinates(
            latitude: latest.coordinate.latitude,
            longitude: latest.coordinate.longitude,
            elevation: latest.altitude,
            placeName: placeName
        )
        self.coordinates = newCoords
        self.locationError = nil

        reverseGeocode(location: latest)
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.locationError = error.localizedDescription
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Prefer trueHeading (calibrated with geographic declination); fall back to magneticHeading
        let targetHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading

        // Track calibration accuracy: negative indicates calibration error, > 15° means high interference
        self.headingAccuracy = newHeading.headingAccuracy
        self.requiresCalibration = newHeading.headingAccuracy < 0 || newHeading.headingAccuracy > 15.0

        // Smooth heading using low-pass circular filter
        smoothedHeading = qiblaService.smoothHeading(current: smoothedHeading, target: targetHeading, factor: 0.22)
        self.currentHeading = smoothedHeading
    }

    public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
}
