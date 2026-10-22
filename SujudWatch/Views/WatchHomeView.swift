import SwiftUI
import PrayerKit

/// Main Apple Watch home interface displaying today's 5 prayer rings, next prayer countdown, and session launcher.
public struct WatchHomeView: View {
    @ObservedObject var viewModel: WatchPrayerViewModel

    public init(viewModel: WatchPrayerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Five Rings / Dots Indicator
                    FivePrayerRingsView(
                        prayerStates: viewModel.prayerStates,
                        currentPrayer: viewModel.currentPrayer
                    )
                    .padding(.top, 4)

                    Divider()
                        .padding(.horizontal)

                    // Next Prayer Spotlight
                    if let next = viewModel.nextPrayer {
                        VStack(spacing: 2) {
                            Text(next.prayer.arabicName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(SujudTheme.warmGold)

                            Text(next.prayer.englishName)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            HStack(spacing: 4) {
                                Text(formattedTime(next.time))
                                    .fontWeight(.medium)
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text("in \(viewModel.countdownString)")
                                    .foregroundStyle(SujudTheme.warmGold)
                                    .fontWeight(.semibold)
                            }
                            .font(.system(size: 13))
                        }
                        .padding(.vertical, 4)

                        // Primary Action: Start Prayer Session
                        Button {
                            viewModel.activeSessionPrayer = next.prayer
                            viewModel.isSessionActive = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                    .font(.caption2)
                                Text("Start Prayer")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(SujudTheme.primaryGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)

                        // Secondary Action: Manual "I Prayed" Button
                        Button {
                            viewModel.markSelfReported(for: next.prayer)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption2)
                                Text("I Prayed (Self-Report)")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: "moon.stars.fill")
                                .font(.title3)
                                .foregroundStyle(SujudTheme.warmGold)
                            Text("All prayers fulfilled")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 16)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 8)
            }
            .sheet(isPresented: $viewModel.isSessionActive) {
                if let prayer = viewModel.activeSessionPrayer {
                    ActivePrayerSessionView(prayer: prayer) { result in
                        if result.status == .confirmed {
                            viewModel.markConfirmed(for: prayer)
                        } else if result.status == .selfReported {
                            viewModel.markSelfReported(for: prayer)
                        }
                    }
                }
            }
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
