import SwiftUI
import PrayerKit

/// Prayer history view showing consistent prayer streaks, weekly and monthly views, and respectful records.
public struct HistoryView: View {
    @ObservedObject var historyStore: PrayerHistoryStore
    @Environment(\.colorScheme) private var colorScheme

    public init(historyStore: PrayerHistoryStore) {
        self.historyStore = historyStore
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Consistency Streak Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("CONSISTENCY STREAK")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(SujudTheme.warmGold)

                                Text("\(historyStore.currentStreakDays) Days")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            }

                            Spacer()

                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 54, height: 54)

                                Image(systemName: "flame.fill")
                                    .font(.title2)
                                    .foregroundStyle(SujudTheme.warmGold)
                            }
                        }

                        // Weekly and Monthly Metrics
                        HStack(spacing: 16) {
                            MetricPill(
                                title: "7-Day Fulfillment",
                                value: "\(historyStore.weeklyFulfillmentPercentage)%"
                            )
                            MetricPill(
                                title: "30-Day Fulfillment",
                                value: "\(historyStore.monthlyFulfillmentPercentage)%"
                            )
                        }

                        // Gentle Encouragement Notice
                        Text(historyStore.missedPrayersSummary())
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.85))
                            .padding(.top, 4)
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [SujudTheme.primaryGreen, SujudTheme.deepForest],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .padding(.horizontal)

                    // Recent Prayer Records List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Prayer Logs")
                            .font(.headline)
                            .padding(.horizontal)

                        if historyStore.records.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.tertiary)
                                Text("No prayer logs yet")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("When you complete prayers on your Apple Watch or self-report, records appear here.")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(SujudTheme.cardBackground(for: colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(historyStore.records.prefix(30)) { record in
                                    PrayerRecordRowView(record: record)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(colorScheme == .dark ? Color.black : SujudTheme.softBackground)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.75))
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PrayerRecordRowView: View {
    let record: PrayerRecord
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: record.prayer.sfSymbolName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(SujudTheme.primaryGreen)
                .frame(width: 36, height: 36)
                .background(SujudTheme.primaryGreen.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(record.prayer.englishName)
                        .font(.system(size: 16, weight: .semibold))
                    Text("(\(record.prayer.arabicName))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(formattedDate(record.completedTime ?? record.scheduledTime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(stateColor)
                        .frame(width: 6, height: 6)
                    Text(record.state.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(stateColor)
                }

                if let rakahs = record.detectedRakahs {
                    Text("\(rakahs) Rakahs")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(SujudTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var stateColor: Color {
        switch record.state {
        case .confirmed: return SujudTheme.primaryGreen
        case .selfReported: return Color(red: 46/255, green: 90/255, blue: 136/255)
        case .pending: return Color.gray
        case .missed: return Color.red.opacity(0.8)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
