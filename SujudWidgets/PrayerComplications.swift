import WidgetKit
import SwiftUI
import PrayerKit

/// Provider generating timeline entries for watchOS Complications and iOS Widgets.
public struct PrayerTimelineProvider: TimelineProvider {

    private let prayerTimeService = PrayerTimeService()

    public func placeholder(in context: Context) -> PrayerTimelineEntry {
        PrayerTimelineEntry(
            date: Date(),
            nextPrayer: .fajr,
            nextPrayerTime: Date().addingTimeInterval(3600),
            currentPrayer: nil
        )
    }

    public func getSnapshot(in context: Context, completion: @escaping (PrayerTimelineEntry) -> Void) {
        let entry = PrayerTimelineEntry(
            date: Date(),
            nextPrayer: .asr,
            nextPrayerTime: Date().addingTimeInterval(1800),
            currentPrayer: .dhuhr
        )
        completion(entry)
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerTimelineEntry>) -> Void) {
        let now = Date()
        let coordinates = Coordinates.makkah // default fallback or read from AppGroup
        let parameters = CalculationMethod.muslimWorldLeague.defaultParameters

        let todayTimes = prayerTimeService.prayerTimes(
            for: now,
            coordinates: coordinates,
            parameters: parameters,
            timeZone: .current
        )

        var entries: [PrayerTimelineEntry] = []

        // Generate timeline entries for today's prayers
        for prayer in Prayer.allCases {
            let pTime = todayTimes.time(for: prayer)
            let entry = PrayerTimelineEntry(
                date: pTime,
                nextPrayer: prayer,
                nextPrayerTime: pTime,
                currentPrayer: todayTimes.currentPrayer(at: pTime)
            )
            entries.append(entry)
        }

        // Schedule next reload after Isha
        let reloadDate = todayTimes.isha.addingTimeInterval(3600)
        let timeline = Timeline(entries: entries, policy: .after(reloadDate))
        completion(timeline)
    }
}

public struct PrayerTimelineEntry: TimelineEntry {
    public let date: Date
    public let nextPrayer: Prayer
    public let nextPrayerTime: Date
    public let currentPrayer: Prayer?
}

/// The main Widget and Watch Complication implementation.
public struct PrayerComplicationWidget: Widget {
    public let kind: String = "SujudPrayerComplication"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimelineProvider()) { entry in
            PrayerComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Next Prayer")
        .description("Shows the next upcoming prayer time and live countdown on your Apple Watch face.")
        #if os(watchOS)
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ])
        #else
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .systemSmall,
            .systemMedium
        ])
        #endif
    }
}

public struct PrayerComplicationEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: PrayerTimelineEntry

    public var body: some View {
        switch family {
        case .accessoryCircular:
            CircularComplicationView(entry: entry)
        case .accessoryRectangular:
            RectangularComplicationView(entry: entry)
        case .accessoryInline:
            InlineComplicationView(entry: entry)
        #if os(watchOS)
        case .accessoryCorner:
            CornerComplicationView(entry: entry)
        #endif
        #if os(iOS)
        case .systemSmall:
            SystemSmallWidgetView(entry: entry)
        case .systemMedium:
            SystemMediumWidgetView(entry: entry)
        #endif
        default:
            CircularComplicationView(entry: entry)
        }
    }
}

// MARK: - Complication Family Views

struct CircularComplicationView: View {
    let entry: PrayerTimelineEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: entry.nextPrayer.sfSymbolName)
                    .font(.caption)
                    .foregroundStyle(SujudTheme.warmGold)
                Text(entry.nextPrayer.englishName.prefix(3).uppercased())
                    .font(.system(size: 10, weight: .bold))
                Text(entry.nextPrayerTime, style: .time)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct RectangularComplicationView: View {
    let entry: PrayerTimelineEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: entry.nextPrayer.sfSymbolName)
                .font(.title3)
                .foregroundStyle(SujudTheme.warmGold)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(entry.nextPrayer.englishName)
                        .font(.headline)
                    Text("(\(entry.nextPrayer.arabicName))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text(entry.nextPrayerTime, style: .time)
                        .fontWeight(.semibold)
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(entry.nextPrayerTime, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(SujudTheme.warmGold)
                }
            }
        }
    }
}

struct InlineComplicationView: View {
    let entry: PrayerTimelineEntry

    var body: some View {
        Text("\(entry.nextPrayer.englishName) \(entry.nextPrayerTime, style: .time)")
    }
}

#if os(watchOS)
struct CornerComplicationView: View {
    let entry: PrayerTimelineEntry

    var body: some View {
        Image(systemName: entry.nextPrayer.sfSymbolName)
            .foregroundStyle(SujudTheme.warmGold)
            .widgetLabel {
                Text("\(entry.nextPrayer.englishName) \(entry.nextPrayerTime, style: .time)")
            }
    }
}
#endif

#if os(iOS)
struct SystemSmallWidgetView: View {
    let entry: PrayerTimelineEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: entry.nextPrayer.sfSymbolName)
                    .foregroundStyle(SujudTheme.warmGold)
                Spacer()
                Text("NEXT")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
            }

            Spacer()

            Text(entry.nextPrayer.arabicName)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.85))

            Text(entry.nextPrayer.englishName)
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text(entry.nextPrayerTime, style: .time)
                .font(.title3)
                .foregroundStyle(SujudTheme.warmGold)
        }
        .padding()
        .containerBackground(SujudTheme.deepForest, for: .widget)
    }
}

struct SystemMediumWidgetView: View {
    let entry: PrayerTimelineEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.nextPrayer.arabicName)
                    .font(.headline)
                    .foregroundStyle(SujudTheme.warmGold)
                Text(entry.nextPrayer.englishName)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text(entry.nextPrayerTime, style: .time)
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.9))
                Text("in \(entry.nextPrayerTime, style: .relative)")
                    .font(.caption)
                    .foregroundStyle(SujudTheme.warmGold)
            }
            Spacer()
            Image(systemName: entry.nextPrayer.sfSymbolName)
                .font(.system(size: 48))
                .foregroundStyle(SujudTheme.primaryGreen)
        }
        .padding()
        .containerBackground(SujudTheme.deepForest, for: .widget)
    }
}
#endif
