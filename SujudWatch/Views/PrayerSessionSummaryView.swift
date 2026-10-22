import SwiftUI
import PrayerKit

/// Short result summary screen displayed at the end of an Apple Watch prayer session.
public struct PrayerSessionSummaryView: View {
    let summary: VerificationResult
    var onDismiss: () -> Void

    public init(summary: VerificationResult, onDismiss: @escaping () -> Void) {
        self.summary = summary
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Status Icon & Badge
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: statusIcon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(statusColor)
                }
                .padding(.top, 4)

                Text(summary.status.displayName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(statusColor)

                Text(summary.prayer.englishName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()
                    .padding(.vertical, 2)

                // Metrics Grid
                VStack(spacing: 4) {
                    HStack {
                        Text("Rakahs")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(summary.detectedRakahCount) of \(summary.expectedRakahCount)")
                            .font(.caption2.bold())
                    }

                    HStack {
                        Text("Recitation Match")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(summary.audioConfidence * 100))%")
                            .font(.caption2.bold())
                    }

                    HStack {
                        Text("Duration")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formattedDuration(summary.durationSeconds))
                            .font(.caption2.bold())
                    }
                }
                .padding(.horizontal, 4)

                // Done Button
                Button {
                    onDismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(SujudTheme.primaryGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.horizontal, 6)
        }
    }

    private var statusColor: Color {
        switch summary.status {
        case .confirmed: return SujudTheme.primaryGreen
        case .partial: return SujudTheme.warmGold
        case .notDetected: return Color.gray
        case .selfReported: return Color(red: 46/255, green: 90/255, blue: 136/255)
        }
    }

    private var statusIcon: String {
        switch summary.status {
        case .confirmed: return "checkmark.seal.fill"
        case .partial: return "exclamationmark.triangle.fill"
        case .notDetected: return "questionmark.circle"
        case .selfReported: return "hand.raised.fill"
        }
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let sec = Int(seconds)
        let m = sec / 60
        let s = sec % 60
        if m > 0 {
            return "\(m)m \(s)s"
        } else {
            return "\(s)s"
        }
    }
}
