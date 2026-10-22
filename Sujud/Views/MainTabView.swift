import SwiftUI
import PrayerKit

/// Root navigation interface hosting the four primary tabs: Prayer Times, Qibla, History, and Settings.
public struct MainTabView: View {
    @StateObject private var locationManager: LocationManager
    @StateObject private var prayerTimesViewModel: PrayerTimesViewModel
    @StateObject private var qiblaViewModel: QiblaViewModel
    @StateObject private var notificationManager: NotificationManager
    @StateObject private var historyStore: PrayerHistoryStore

    @State private var selectedTab: TabItem = .prayerTimes
    @State private var showingPrivacyConsent: Bool = false

    public enum TabItem: Hashable {
        case prayerTimes
        case qibla
        case history
        case settings
    }

    public init() {
        let lm = LocationManager()
        let nm = NotificationManager()
        let hs = PrayerHistoryStore()
        _locationManager = StateObject(wrappedValue: lm)
        _notificationManager = StateObject(wrappedValue: nm)
        _historyStore = StateObject(wrappedValue: hs)
        _prayerTimesViewModel = StateObject(wrappedValue: PrayerTimesViewModel(locationManager: lm))
        _qiblaViewModel = StateObject(wrappedValue: QiblaViewModel(locationManager: lm))
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            PrayerTimesView(
                viewModel: prayerTimesViewModel,
                locationManager: locationManager
            )
            .tabItem {
                Label("Prayer Times", systemImage: "clock.fill")
            }
            .tag(TabItem.prayerTimes)

            QiblaCompassView(
                viewModel: qiblaViewModel,
                locationManager: locationManager
            )
            .tabItem {
                Label("Qibla", systemImage: "safari.fill")
            }
            .tag(TabItem.qibla)

            HistoryView(historyStore: historyStore)
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
                .tag(TabItem.history)

            SettingsView(
                prayerTimesViewModel: prayerTimesViewModel,
                notificationManager: notificationManager
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(TabItem.settings)
        }
        .tint(SujudTheme.primaryGreen)
        .onAppear {
            checkConsentAndNotifications()
        }
        .onChange(of: prayerTimesViewModel.cachedMonthTimes) { _, times in
            if !times.isEmpty && notificationManager.settings.notificationsEnabled {
                notificationManager.scheduleNotifications(using: times)
            }
        }
        .sheet(isPresented: $showingPrivacyConsent) {
            PrivacyConsentView(isPresented: $showingPrivacyConsent) {
                notificationManager.settings.hasAgreedToPrivacyConsent = true
                notificationManager.saveSettings()
                Task {
                    _ = await notificationManager.requestAuthorization()
                    if !prayerTimesViewModel.cachedMonthTimes.isEmpty {
                        notificationManager.scheduleNotifications(using: prayerTimesViewModel.cachedMonthTimes)
                    }
                }
            }
        }
    }

    private func checkConsentAndNotifications() {
        if !notificationManager.settings.hasAgreedToPrivacyConsent {
            showingPrivacyConsent = true
        }

        notificationManager.onStartPrayerFromNotification = { prayer in
            selectedTab = .prayerTimes
        }
    }
}
