import SwiftUI
import PrayerKit

/// Hero card highlighting the next upcoming prayer with live countdown and progress.
public struct NextPrayerCardView: View {
    @ObservedObject var viewModel: PrayerTimesViewModel
    let placeName: String

    public init(viewModel: PrayerTimesViewModel, placeName: String) {
        self.viewModel = viewModel
        self.placeName = placeName
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Location and Hijri Date
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundStyle(SujudTheme.warmGold)
                        Text(placeName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }
                    
                    Text(viewModel.hijriDateString)
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.85))
                }

                Spacer()

                if let current = viewModel.currentPrayer {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(SujudTheme.warmGold)
                            .frame(width: 6, height: 6)
                        Text(current.englishName.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(SujudTheme.warmGold)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            // Next Prayer Spotlight
            if let next = viewModel.nextPrayer {
                VStack(alignment: .leading, spacing: 6) {
                    Text(next.prayer.arabicName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.9))

                    HStack(alignment: .firstTextBaseline) {
                        Text(next.prayer.englishName)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Spacer()

                        Text(formattedTime(next.time))
                            .font(.system(size: 30, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    // Live Countdown Pill
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text("in \(viewModel.countdownString)")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Text(next.prayer == .sunrise ? "Sunrise" : "Upcoming prayer")
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.75))
                    }
                    .foregroundStyle(SujudTheme.warmGold)
                    .padding(.top, 4)

                    // Window Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 5)

                            Capsule()
                                .fill(SujudTheme.warmGold)
                                .frame(width: max(8, geo.size.width * viewModel.currentWindowProgress), height: 5)
                        }
                    }
                    .frame(height: 5)
                    .padding(.top, 8)
                }
            } else {
                Text("All prayers completed for today")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [
                    SujudTheme.primaryGreen,
                    SujudTheme.deepForest
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: SujudTheme.primaryGreen.opacity(0.25), radius: 14, x: 0, y: 8)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
