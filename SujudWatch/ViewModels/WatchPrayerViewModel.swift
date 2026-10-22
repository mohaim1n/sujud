import Foundation
import Combine
import SwiftUI
import PrayerKit

/// ViewModel driving the Apple Watch companion home screen, countdowns, and prayer ring states.
@MainActor
public final class WatchPrayerViewModel: ObservableObject {

    // MARK: - Published State

    @Published public private(set) var todayTimes: PrayerTimes?
    @Published public private(set) var nextPrayer: (prayer: Prayer, time: Date)?
    @Published public private(set) var currentPrayer: Prayer?
    @Published public private(set) var countdownString: String = "--:--"
    @Published public private(set) var prayerStates: [Prayer: DailyPrayerState] = [
        .fajr: .pending,
        .dhuhr: .pending,
        .asr: .pending,
        .maghrib: .pending,
        .isha: .pending
    ]

    @Published public var activeSessionPrayer: Prayer?
    @Published public var isSessionActive: Bool = false

    // MARK: - Dependencies

    private let prayerTimeService: PrayerTimeServiceProtocol
    private var coordinates: Coordinates
    private var calculationParameters: CalculationParameters
    private var countdownTimer: AnyCancellable?

    public init(
        prayerTimeService: PrayerTimeServiceProtocol = PrayerTimeService(),
        initialCoordinates: Coordinates = Coordinates.makkah,
        parameters: CalculationParameters = CalculationMethod.muslimWorldLeague.defaultParameters
    ) {
        self.prayerTimeService = prayerTimeService
        self.coordinates = initialCoordinates
        self.calculationParameters = parameters

        loadLocalCache()
        recalculateTimes()
        startCountdownTimer()
    }

    // MARK: - Recalculation

    public func recalculateTimes() {
        let now = Date()
        let times = prayerTimeService.prayerTimes(
            for: now,
            coordinates: coordinates,
            parameters: calculationParameters,
            timeZone: .current
        )

        self.todayTimes = times
        self.currentPrayer = times.currentPrayer(at: now)
        self.nextPrayer = prayerTimeService.nextUpcomingPrayer(
            from: now,
            coordinates: coordinates,
            parameters: calculationParameters,
            timeZone: .current
        )

        updateCountdown(now: now)
        evaluateMissedPrayers(now: now, times: times)
    }

    private func startCountdownTimer() {
        countdownTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                self?.updateCountdown(now: now)
            }
    }

    private func updateCountdown(now: Date) {
        guard let next = nextPrayer else {
            countdownString = "--:--"
            return
        }

        let diff = Int(next.time.timeIntervalSince(now))
        if diff <= 0 {
            recalculateTimes()
            return
        }

        let hours = diff / 3600
        let minutes = (diff % 3600) / 60
        let seconds = diff % 60

        if hours > 0 {
            countdownString = "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            countdownString = "\(minutes)m"
        } else {
            countdownString = "\(seconds)s"
        }
    }

    private func evaluateMissedPrayers(now: Date, times: PrayerTimes) {
        for prayer in Prayer.fivePrayers {
            let window = times.prayerWindow(for: prayer)
            // If window has expired and state is still pending, mark as missed
            if now > window.end && prayerStates[prayer] == .pending {
                prayerStates[prayer] = .missed
            }
        }
    }

    // MARK: - Prayer Actions

    public func markSelfReported(for prayer: Prayer) {
        prayerStates[prayer] = .selfReported
        saveLocalStates()
    }

    public func markConfirmed(for prayer: Prayer) {
        prayerStates[prayer] = .confirmed
        saveLocalStates()
    }

    // MARK: - State Persistence

    private func saveLocalStates() {
        var dict: [String: String] = [:]
        for (k, v) in prayerStates {
            dict[k.rawValue] = v.rawValue
        }
        UserDefaults.standard.set(dict, forKey: "com.sujud.watch.prayerStates")
    }

    private func loadLocalCache() {
        if let dict = UserDefaults.standard.dictionary(forKey: "com.sujud.watch.prayerStates") as? [String: String] {
            var loaded: [Prayer: DailyPrayerState] = [:]
            for (k, v) in dict {
                if let prayer = Prayer(rawValue: k), let state = DailyPrayerState(rawValue: v) {
                    loaded[prayer] = state
                }
            }
            if !loaded.isEmpty {
                self.prayerStates = loaded
            }
        }
    }

    /// Syncs updated configuration received from iPhone via WatchConnectivity.
    public func updateConfiguration(coordinates: Coordinates, parameters: CalculationParameters) {
        self.coordinates = coordinates
        self.calculationParameters = parameters
        recalculateTimes()
    }
}
