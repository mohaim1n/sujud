import SwiftUI
import PrayerKit

/// Individual row presenting a single prayer time in the daily schedule.
public struct PrayerRowView: View {
    let prayer: Prayer
    let time: Date
    let isCurrent: Bool
    let isNext: Bool

    @Environment(\.colorScheme) private var colorScheme

    public init(prayer: Prayer, time: Date, isCurrent: Bool, isNext: Bool) {
        self.prayer = prayer
        self.time = time
        self.isCurrent = isCurrent
        self.isNext = isNext
    }

    public var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 44, height: 44)

                Image(systemName: prayer.sfSymbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconForegroundColor)
            }

            // Names
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(prayer.englishName)
                        .font(.system(size: 17, weight: isCurrent || isNext ? .bold : .medium))
                        .foregroundStyle(textColor)

                    if prayer == .sunrise {
                        Text("Shuruq")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else if isCurrent {
                        Text("NOW")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(SujudTheme.primaryGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(SujudTheme.primaryGreen.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                Text(prayer.arabicName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Scheduled Time
            Text(formattedTime(time))
                .font(.system(size: 19, weight: isCurrent || isNext ? .bold : .medium, design: .rounded))
                .foregroundStyle(textColor)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(rowBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isCurrent ? SujudTheme.primaryGreen.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
    }

    private var textColor: Color {
        if prayer == .sunrise {
            return .secondary
        }
        return isCurrent ? SujudTheme.primaryGreen : Color.primary
    }

    private var iconBackgroundColor: Color {
        if isCurrent {
            return SujudTheme.primaryGreen.opacity(0.15)
        } else if isNext {
            return SujudTheme.warmGold.opacity(0.15)
        } else if prayer == .sunrise {
            return Color.gray.opacity(0.1)
        } else {
            return colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
        }
    }

    private var iconForegroundColor: Color {
        if isCurrent {
            return SujudTheme.primaryGreen
        } else if isNext {
            return SujudTheme.warmGold
        } else if prayer == .sunrise {
            return Color.orange.opacity(0.8)
        } else {
            return SujudTheme.primaryGreen
        }
    }

    private var rowBackgroundColor: Color {
        if isCurrent {
            return SujudTheme.primaryGreen.opacity(0.06)
        }
        return SujudTheme.cardBackground(for: colorScheme)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
