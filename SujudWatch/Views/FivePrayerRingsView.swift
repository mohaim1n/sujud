import SwiftUI
import PrayerKit

/// Five prayer status rings/dots for Apple Watch displaying daily prayer fulfillment.
public struct FivePrayerRingsView: View {
    let prayerStates: [Prayer: DailyPrayerState]
    let currentPrayer: Prayer?

    public init(prayerStates: [Prayer: DailyPrayerState], currentPrayer: Prayer?) {
        self.prayerStates = prayerStates
        self.currentPrayer = currentPrayer
    }

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(Prayer.fivePrayers) { prayer in
                let state = prayerStates[prayer] ?? .pending
                let isCurrent = currentPrayer == prayer

                VStack(spacing: 4) {
                    ZStack {
                        // Outer pulse ring for current prayer
                        if isCurrent {
                            Circle()
                                .stroke(SujudTheme.primaryGreen.opacity(0.4), lineWidth: 1.5)
                                .frame(width: 24, height: 24)
                        }

                        // Status dot
                        Circle()
                            .fill(color(for: state))
                            .frame(width: 18, height: 18)
                            .overlay(
                                icon(for: state)
                            )
                    }

                    Text(prayerInitial(for: prayer))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isCurrent ? SujudTheme.primaryGreen : .secondary)
                }
            }
        }
    }

    private func color(for state: DailyPrayerState) -> Color {
        switch state {
        case .confirmed:
            return SujudTheme.primaryGreen
        case .selfReported:
            return Color(red: 46/255, green: 90/255, blue: 136/255)
        case .pending:
            return Color.white.opacity(0.15)
        case .missed:
            return Color.gray.opacity(0.3)
        }
    }

    @ViewBuilder
    private func icon(for state: DailyPrayerState) -> some View {
        switch state {
        case .confirmed:
            Image(systemName: "checkmark")
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(.white)
        case .selfReported:
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.white)
        case .pending:
            Circle()
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        case .missed:
            Image(systemName: "xmark")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private func prayerInitial(for prayer: Prayer) -> String {
        switch prayer {
        case .fajr: return "F"
        case .sunrise: return "S"
        case .dhuhr: return "D"
        case .asr: return "A"
        case .maghrib: return "M"
        case .isha: return "I"
        }
    }
}
