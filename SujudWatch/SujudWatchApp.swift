import SwiftUI
import WatchKit
import PrayerKit

@main
struct SujudWatchApp: App {
    @StateObject private var watchViewModel = WatchPrayerViewModel()

    var body: some Scene {
        WindowGroup {
            WatchHomeView(viewModel: watchViewModel)
        }
    }
}
