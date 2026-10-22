import Foundation
import Combine
import PrayerKit

/// Storage and metrics engine for prayer history records, streaks, and weekly/monthly fulfillment statistics.
@MainActor
public final class PrayerHistoryStore: ObservableObject {

    // MARK: - Published Properties

    @Published public private(set) var records: [PrayerRecord] = []
    @Published public private(set) var currentStreakDays: Int = 0
    @Published public private(set) var weeklyFulfillmentPercentage: Int = 0
    @Published public private(set) var monthlyFulfillmentPercentage: Int = 0

    private let storageKey = "com.sujud.prayerRecords"

    public init() {
        loadRecords()
        calculateMetrics()
    }

    // MARK: - Record Management

    public func addRecord(_ record: PrayerRecord) {
        records.removeAll { $0.id == record.id }
        records.insert(record, at: 0)
        saveRecords()
        calculateMetrics()
    }

    public func logManualPrayer(prayer: Prayer, scheduledTime: Date = Date()) {
        let record = PrayerRecord(
            prayer: prayer,
            scheduledTime: scheduledTime,
            completedTime: Date(),
            state: .selfReported,
            detectedRakahs: prayer.obligatoryRakahCount,
            targetRakahs: prayer.obligatoryRakahCount
        )
        addRecord(record)
    }

    public func clearAllHistory() {
        records.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
        calculateMetrics()
    }

    // MARK: - Metrics & Streaks

    private func calculateMetrics() {
        calculateStreak()
        calculateFulfillmentRates()
    }

    private func calculateStreak() {
        var calendar = Calendar.current
        calendar.timeZone = .current
        let today = calendar.startOfDay(for: Date())

        var streak = 0
        var checkDate = today

        // Check backwards day by day
        for _ in 0..<365 {
            let dayRecords = records.filter {
                calendar.isDate($0.scheduledTime, inSameDayAs: checkDate) &&
                ($0.state == .confirmed || $0.state == .selfReported)
            }

            // Count unique obligatory prayers completed on that day
            let completedPrayers = Set(dayRecords.map { $0.prayer })
            let obligatoryCompleted = Prayer.fivePrayers.filter { completedPrayers.contains($0) }

            if obligatoryCompleted.count == 5 {
                streak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDay
            } else if checkDate == today {
                // If today is still in progress, check yesterday before breaking streak
                guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = yesterday
            } else {
                break
            }
        }

        self.currentStreakDays = streak
    }

    private func calculateFulfillmentRates() {
        let calendar = Calendar.current
        let now = Date()

        // Last 7 days
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return }
        let weeklyCompleted = records.filter {
            $0.scheduledTime >= sevenDaysAgo && ($0.state == .confirmed || $0.state == .selfReported)
        }.count
        let totalWeeklyPossible = 7 * 5
        self.weeklyFulfillmentPercentage = min(100, Int((Double(weeklyCompleted) / Double(totalWeeklyPossible)) * 100))

        // Last 30 days
        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) else { return }
        let monthlyCompleted = records.filter {
            $0.scheduledTime >= thirtyDaysAgo && ($0.state == .confirmed || $0.state == .selfReported)
        }.count
        let totalMonthlyPossible = 30 * 5
        self.monthlyFulfillmentPercentage = min(100, Int((Double(monthlyCompleted) / Double(totalMonthlyPossible)) * 100))
    }

    // MARK: - Encouraging Missed Prayer Summary

    /// Gentle, non-shaming Islamic encouragement summarizing prayers needing attention.
    public func missedPrayersSummary() -> String {
        let missedCount = records.filter { $0.state == .missed }.count
        if missedCount == 0 {
            return "Alhamdulillah, all recorded prayers have been fulfilled."
        } else {
            return "May Allah accept your efforts and grant you ease in your prayers. Every new day is a fresh beginning."
        }
    }

    // MARK: - Persistence

    private func saveRecords() {
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let loaded = try? JSONDecoder().decode([PrayerRecord].self, from: data) {
            self.records = loaded
        }
    }
}
