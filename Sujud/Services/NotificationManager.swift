import Foundation
import UserNotifications
import Combine
import UIKit
import PrayerKit

/// Central manager for time-sensitive prayer adhan notifications and escalating reminders.
@MainActor
public final class NotificationManager: NSObject, ObservableObject {

    // MARK: - Notification Constants

    public static let prayerCategoryIdentifier = "SUJUD_PRAYER_CATEGORY"
    public static let startPrayerActionIdentifier = "SUJUD_START_PRAYER_ACTION"
    public static let snooze10ActionIdentifier = "SUJUD_SNOOZE_10_ACTION"

    // MARK: - Published Properties

    @Published public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published public var settings: UserSettingsState {
        didSet {
            saveSettings()
        }
    }

    // Event broadcast when user taps "Start Prayer" action button on a notification
    public var onStartPrayerFromNotification: ((Prayer) -> Void)?

    // MARK: - Private Properties

    private let center = UNUserNotificationCenter.current()
    private let settingsStorageKey = "com.sujud.userSettings"

    public override init() {
        if let data = UserDefaults.standard.data(forKey: settingsStorageKey),
           let loaded = try? JSONDecoder().decode(UserSettingsState.self, from: data) {
            self.settings = loaded
        } else {
            self.settings = .default
        }

        super.init()
        self.center.delegate = self

        Task {
            await checkAuthorization()
            setupNotificationCategories()
        }
    }

    // MARK: - Authorization

    public func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge, .criticalAlert]
            let granted = try await center.requestAuthorization(options: options)
            await checkAuthorization()
            return granted
        } catch {
            await checkAuthorization()
            return false
        }
    }

    public func checkAuthorization() async {
        let notificationSettings = await center.notificationSettings()
        self.authorizationStatus = notificationSettings.authorizationStatus
    }

    // MARK: - Category & Action Registration

    private func setupNotificationCategories() {
        let startAction = UNNotificationAction(
            identifier: Self.startPrayerActionIdentifier,
            title: "Start Prayer",
            options: [.foreground],
            icon: UNNotificationActionIcon(systemImageName: "play.fill")
        )

        let snoozeAction = UNNotificationAction(
            identifier: Self.snooze10ActionIdentifier,
            title: "Remind me in 10m",
            options: [],
            icon: UNNotificationActionIcon(systemImageName: "clock.arrow.circlepath")
        )

        let prayerCategory = UNNotificationCategory(
            identifier: Self.prayerCategoryIdentifier,
            actions: [startAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([prayerCategory])
    }

    // MARK: - Scheduling Engine

    /// Schedules full prayer notifications and escalating reminders for a 7-day window.
    public func scheduleNotifications(using prayerTimesList: [PrayerTimes]) {
        guard settings.notificationsEnabled else {
            center.removeAllPendingNotificationRequests()
            return
        }

        // Clean existing schedule before queuing fresh schedule
        center.removeAllPendingNotificationRequests()

        let now = Date()
        let upcomingDays = prayerTimesList.prefix(7)

        for dayTimes in upcomingDays {
            for prayer in Prayer.allCases {
                // Check if user has this prayer notification enabled
                guard settings.isPrayerEnabled(prayer) else { continue }

                let prayerTime = dayTimes.time(for: prayer)
                let window = dayTimes.prayerWindow(for: prayer)

                // 1. Initial Adhan Notification (at exact prayer start)
                if prayerTime > now {
                    scheduleAdhanNotification(for: prayer, at: prayerTime)
                }

                // 2. Escalating Reminders (e.g. +15m, +30m, +60m)
                if settings.escalatingRemindersEnabled && prayer != .sunrise {
                    scheduleEscalatingReminders(
                        for: prayer,
                        startTime: prayerTime,
                        windowEnd: window.end,
                        referenceNow: now
                    )
                }
            }
        }
    }

    private func scheduleAdhanNotification(for prayer: Prayer, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "\(prayer.englishName) Adhan (\(prayer.arabicName))"
        content.body = "The \(prayer.englishName) prayer window is now open. Tap to start your verified prayer session."
        content.categoryIdentifier = Self.prayerCategoryIdentifier
        content.interruptionLevel = .timeSensitive

        // Configure sound
        if let soundName = settings.soundOption.soundFileName {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
        } else if settings.soundOption == .hapticOnly {
            content.sound = nil
        } else {
            content.sound = .default
        }

        content.userInfo = [
            "prayer": prayer.rawValue,
            "scheduledTime": date.timeIntervalSince1970,
            "type": "adhan"
        ]

        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "sujud_adhan_\(prayer.rawValue)_\(Int(date.timeIntervalSince1970))",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    private func scheduleEscalatingReminders(
        for prayer: Prayer,
        startTime: Date,
        windowEnd: Date,
        referenceNow: Date
    ) {
        for minutes in settings.escalatingIntervalsMinutes {
            let reminderDate = startTime.addingTimeInterval(Double(minutes * 60))

            // Enforce window bounds: do not schedule if reminder falls in the past or after the prayer window ends
            guard reminderDate > referenceNow && reminderDate < windowEnd else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = "\(prayer.englishName) Reminder (\(minutes)m passed)"
            content.body = "You have not yet logged \(prayer.englishName). The prayer window closes soon."
            content.categoryIdentifier = Self.prayerCategoryIdentifier
            content.interruptionLevel = .timeSensitive

            if settings.soundOption == .hapticOnly {
                content.sound = nil
            } else {
                content.sound = .default
            }

            content.userInfo = [
                "prayer": prayer.rawValue,
                "scheduledTime": startTime.timeIntervalSince1970,
                "type": "escalating",
                "offsetMinutes": minutes
            ]

            let triggerComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: reminderDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

            let request = UNNotificationRequest(
                identifier: "sujud_remind_\(prayer.rawValue)_\(minutes)m_\(Int(startTime.timeIntervalSince1970))",
                content: content,
                trigger: trigger
            )

            center.add(request)
        }
    }

    /// Cancels remaining escalating reminders for a prayer once confirmed or self-reported.
    public func cancelPendingReminders(for prayer: Prayer, on scheduledDate: Date) {
        let timestamp = Int(scheduledDate.timeIntervalSince1970)
        var identifiersToCancel: [String] = []

        for minutes in settings.escalatingIntervalsMinutes {
            identifiersToCancel.append("sujud_remind_\(prayer.rawValue)_\(minutes)m_\(timestamp)")
        }

        center.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
    }

    /// Schedules a one-time 10-minute snooze reminder.
    public func scheduleSnooze10(for prayer: Prayer) {
        let content = UNMutableNotificationContent()
        content.title = "\(prayer.englishName) Snooze Reminder"
        content.body = "10 minutes have elapsed. Ready to perform \(prayer.englishName)?"
        content.categoryIdentifier = Self.prayerCategoryIdentifier
        content.interruptionLevel = .timeSensitive
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: false)
        let request = UNNotificationRequest(
            identifier: "sujud_snooze_\(prayer.rawValue)_\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    // MARK: - Data Management

    public func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsStorageKey)
        }
    }

    public func deleteAllData() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()

        // Reset settings
        settings = .default
        saveSettings()

        // Clear cached coordinates and adjustments
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Display banner and play sound even if app is active
        completionHandler([.banner, .sound, .list])
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        guard let prayerRaw = userInfo["prayer"] as? String,
              let prayer = Prayer(rawValue: prayerRaw) else {
            completionHandler()
            return
        }

        switch response.actionIdentifier {
        case Self.startPrayerActionIdentifier:
            // Broadcast intent to begin prayer session
            onStartPrayerFromNotification?(prayer)

        case Self.snooze10ActionIdentifier:
            scheduleSnooze10(for: prayer)

        default:
            break
        }

        completionHandler()
    }
}
