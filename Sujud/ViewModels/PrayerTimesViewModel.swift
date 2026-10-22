import Foundation
import Combine
import SwiftUI
import PrayerKit

/// ViewModel managing accurate daily prayer times, 30-day offline cache, method selection, and countdowns.
@MainActor
public final class PrayerTimesViewModel: ObservableObject {

    // MARK: - Published State

    @Published public private(set) var todayTimes: PrayerTimes?
    @Published public private(set) var nextPrayer: (prayer: Prayer, time: Date)?
    @Published public private(set) var currentPrayer: Prayer?
    @Published public private(set) var countdownString: String = "--:--"
    @Published public private(set) var hijriDateString: String = ""
    @Published public private(set) var cachedMonthTimes: [PrayerTimes] = []

    // User Preferences
    @Published public var selectedMethod: CalculationMethod {
        didSet {
            UserDefaults.standard.set(selectedMethod.rawValue, forKey: "com.sujud.selectedMethod")
            recalculateTimes()
        }
    }

    @Published public var selectedMadhab: Madhab {
        didSet {
            UserDefaults.standard.set(selectedMadhab.rawValue, forKey: "com.sujud.selectedMadhab")
            recalculateTimes()
        }
    }

    @Published public var adjustments: PrayerAdjustments {
        didSet {
            if let encoded = try? JSONEncoder().encode(adjustments) {
                UserDefaults.standard.set(encoded, forKey: "com.sujud.adjustments")
            }
            recalculateTimes()
        }
    }

    // MARK: - Private Dependencies

    private let prayerTimeService: PrayerTimeServiceProtocol
    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    private var countdownTimer: AnyCancellable?
    private var hasAutoSuggestedMethod: Bool = false

    public init(
        locationManager: LocationManager,
        prayerTimeService: PrayerTimeServiceProtocol = PrayerTimeService()
    ) {
        self.locationManager = locationManager
        self.prayerTimeService = prayerTimeService

        // Load saved preferences or defaults
        let savedMethodRaw = UserDefaults.standard.string(forKey: "com.sujud.selectedMethod") ?? CalculationMethod.muslimWorldLeague.rawValue
        self.selectedMethod = CalculationMethod(rawValue: savedMethodRaw) ?? .muslimWorldLeague

        let savedMadhabRaw = UserDefaults.standard.string(forKey: "com.sujud.selectedMadhab") ?? Madhab.shafi.rawValue
        self.selectedMadhab = Madhab(rawValue: savedMadhabRaw) ?? .shafi

        if let data = UserDefaults.standard.data(forKey: "com.sujud.adjustments"),
           let loaded = try? JSONDecoder().decode(PrayerAdjustments.self, from: data) {
            self.adjustments = loaded
        } else {
            self.adjustments = .zero
        }

        self.hasAutoSuggestedMethod = UserDefaults.standard.bool(forKey: "com.sujud.hasAutoSuggestedMethod")

        setupSubscriptions()
        startCountdownTimer()
    }

    // MARK: - Subscriptions & Lifecycle

    private func setupSubscriptions() {
        // Observe location coordinate changes
        locationManager.$coordinates
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.recalculateTimes()
            }
            .store(in: &cancellables)

        // Auto-suggest method from detected country code once
        locationManager.$countryCode
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] code in
                guard let self = self, !self.hasAutoSuggestedMethod else { return }
                let suggested = CalculationMethod.suggested(forCountryCode: code)
                self.selectedMethod = suggested
                self.hasAutoSuggestedMethod = true
                UserDefaults.standard.set(true, forKey: "com.sujud.hasAutoSuggestedMethod")
            }
            .store(in: &cancellables)
    }

    private func startCountdownTimer() {
        countdownTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                self?.updateCountdown(now: now)
            }
    }

    // MARK: - Recalculation Engine

    public func recalculateTimes() {
        guard let coordinates = locationManager.coordinates else { return }

        var params = selectedMethod.defaultParameters
        params.madhab = selectedMadhab
        params.adjustments = adjustments

        let now = Date()
        let today = prayerTimeService.prayerTimes(
            for: now,
            coordinates: coordinates,
            parameters: params,
            timeZone: .current
        )

        self.todayTimes = today
        self.hijriDateString = today.hijriDateString()
        self.currentPrayer = today.currentPrayer(at: now)
        self.nextPrayer = prayerTimeService.nextUpcomingPrayer(
            from: now,
            coordinates: coordinates,
            parameters: params,
            timeZone: .current
        )

        // Cache 30-day range for offline reliability
        self.cachedMonthTimes = prayerTimeService.prayerTimesRange(
            startDate: now,
            days: 30,
            coordinates: coordinates,
            parameters: params,
            timeZone: .current
        )

        updateCountdown(now: now)
    }

    private func updateCountdown(now: Date) {
        guard let next = nextPrayer else {
            countdownString = "--:--"
            return
        }

        let diff = Int(next.time.timeIntervalSince(now))
        if diff <= 0 {
            // Prayer time arrived, recalculate next prayer
            recalculateTimes()
            return
        }

        let hours = diff / 3600
        let minutes = (diff % 3600) / 60
        let seconds = diff % 60

        if hours > 0 {
            countdownString = String(format: "%dh %02dm", hours, minutes)
        } else {
            countdownString = String(format: "%02dm %02ds", minutes, seconds)
        }
    }

    /// Progress percentage (0.0 to 1.0) of the current prayer window.
    public var currentWindowProgress: Double {
        guard let today = todayTimes, let next = nextPrayer else { return 0.0 }
        let now = Date()

        // Find current prayer start
        let previousPrayerTime: Date
        if let current = currentPrayer {
            previousPrayerTime = today.time(for: current)
        } else {
            // Before Fajr: window is from midnight or yesterday's Isha
            previousPrayerTime = today.fajr.addingTimeInterval(-3600 * 4)
        }

        let totalDuration = next.time.timeIntervalSince(previousPrayerTime)
        guard totalDuration > 0 else { return 0.0 }
        let elapsed = now.timeIntervalSince(previousPrayerTime)
        return min(1.0, max(0.0, elapsed / totalDuration))
    }
}
