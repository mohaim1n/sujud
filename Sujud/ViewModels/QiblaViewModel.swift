import Foundation
import Combine
import SwiftUI
import PrayerKit

/// ViewModel managing Qibla direction, alignment detection, haptics, and compass animation.
@MainActor
public final class QiblaViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published public private(set) var qibla: Qibla?
    @Published public private(set) var isAligned: Bool = false
    @Published public private(set) var angleDifference: Double = 0.0
    @Published public private(set) var currentHeading: Double = 0.0
    @Published public private(set) var requiresCalibration: Bool = false

    // MARK: - Private Properties

    private let locationManager: LocationManager
    private let qiblaService: QiblaServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var wasAlignedLastFrame: Bool = false

    public init(
        locationManager: LocationManager,
        qiblaService: QiblaServiceProtocol = QiblaService()
    ) {
        self.locationManager = locationManager
        self.qiblaService = qiblaService

        setupSubscriptions()
    }

    private func setupSubscriptions() {
        // Observe coordinates to recalculate fixed bearing & distance
        locationManager.$coordinates
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] coords in
                guard let self = self else { return }
                self.qibla = self.qiblaService.qibla(for: coords)
                self.updateAlignmentState()
            }
            .store(in: &cancellables)

        // Observe continuous heading updates
        locationManager.$currentHeading
            .receive(on: RunLoop.main)
            .sink { [weak self] heading in
                guard let self = self else { return }
                self.currentHeading = heading
                self.updateAlignmentState()
            }
            .store(in: &cancellables)

        // Observe calibration warnings
        locationManager.$requiresCalibration
            .receive(on: RunLoop.main)
            .assign(to: &$requiresCalibration)
    }

    // MARK: - Lifecycle

    public func onAppear() {
        locationManager.startHeadingUpdates()
        if let coords = locationManager.coordinates {
            self.qibla = qiblaService.qibla(for: coords)
        }
        updateAlignmentState()
    }

    public func onDisappear() {
        locationManager.stopHeadingUpdates()
    }

    // MARK: - Alignment Logic

    private func updateAlignmentState() {
        guard let qibla = qibla else {
            isAligned = false
            angleDifference = 0.0
            return
        }

        let delta = qibla.deltaAngle(deviceHeading: currentHeading)
        self.angleDifference = delta

        let currentlyAligned = abs(delta) <= 3.0
        self.isAligned = currentlyAligned

        // Trigger haptic precisely on positive edge transition (unaligned -> aligned)
        if currentlyAligned && !wasAlignedLastFrame {
            locationManager.triggerAlignmentHaptic()
        }
        wasAlignedLastFrame = currentlyAligned
    }

    /// Shortest angle to rotate the Qibla needle relative to top of device screen.
    public var needleRotationDegrees: Double {
        guard let qibla = qibla else { return 0.0 }
        return qibla.bearing - currentHeading
    }
}
