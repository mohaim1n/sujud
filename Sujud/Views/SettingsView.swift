import SwiftUI
import PrayerKit

/// Comprehensive settings interface for prayer calculations, adhan sounds, escalating notifications, languages, and privacy.
public struct SettingsView: View {
    @ObservedObject var prayerTimesViewModel: PrayerTimesViewModel
    @ObservedObject var notificationManager: NotificationManager

    @State private var showingConsentSheet: Bool = false
    @State private var showingDeleteAlert: Bool = false
    @State private var showingCalculationMethodSheet: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    public init(
        prayerTimesViewModel: PrayerTimesViewModel,
        notificationManager: NotificationManager
    ) {
        self.prayerTimesViewModel = prayerTimesViewModel
        self.notificationManager = notificationManager
    }

    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - 1. Prayer Calculations Section
                Section(header: Text("Prayer Calculation & Jurisprudence")) {
                    Button {
                        showingCalculationMethodSheet = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Calculation Authority")
                                    .foregroundStyle(Color.primary)
                                Text(prayerTimesViewModel.selectedMethod.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Picker("Asr School (Madhab)", selection: $prayerTimesViewModel.selectedMadhab) {
                        ForEach(Madhab.allCases, id: \.self) { madhab in
                            Text(madhab.displayName).tag(madhab)
                        }
                    }

                    NavigationLink("Manual Minute Adjustments") {
                        PrayerAdjustmentsFormView(viewModel: prayerTimesViewModel)
                    }
                }

                // MARK: - 2. Time-Sensitive Notifications & Adhan
                Section(
                    header: Text("Notifications & Adhan"),
                    footer: Text("Time-sensitive alerts break through Focus modes (Do Not Disturb) to ensure you hear the Adhan on time.")
                ) {
                    Toggle("Enable Prayer Notifications", isOn: $notificationManager.settings.notificationsEnabled)
                        .tint(SujudTheme.primaryGreen)
                        .onChange(of: notificationManager.settings.notificationsEnabled) { _, enabled in
                            if enabled {
                                Task {
                                    _ = await notificationManager.requestAuthorization()
                                    rescheduleAll()
                                }
                            } else {
                                rescheduleAll()
                            }
                        }

                    if notificationManager.settings.notificationsEnabled {
                        Picker("Notification Sound", selection: $notificationManager.settings.soundOption) {
                            ForEach(NotificationSoundOption.allCases) { sound in
                                Text(sound.displayName).tag(sound)
                            }
                        }
                        .onChange(of: notificationManager.settings.soundOption) { _, _ in
                            rescheduleAll()
                        }

                        // Per-Prayer Notification Toggles
                        DisclosureGroup("Individual Prayers") {
                            Toggle("Fajr (Subuh)", isOn: $notificationManager.settings.notifyFajr)
                            Toggle("Sunrise (Syuruk)", isOn: $notificationManager.settings.notifySunrise)
                            Toggle("Dhuhr (Zohor)", isOn: $notificationManager.settings.notifyDhuhr)
                            Toggle("Asr (Asar)", isOn: $notificationManager.settings.notifyAsr)
                            Toggle("Maghrib", isOn: $notificationManager.settings.notifyMaghrib)
                            Toggle("Isha (Isyak)", isOn: $notificationManager.settings.notifyIsha)
                        }
                        .tint(SujudTheme.primaryGreen)
                        .onChange(of: notificationManager.settings.notifyFajr) { _, _ in rescheduleAll() }
                        .onChange(of: notificationManager.settings.notifyDhuhr) { _, _ in rescheduleAll() }
                        .onChange(of: notificationManager.settings.notifyAsr) { _, _ in rescheduleAll() }
                        .onChange(of: notificationManager.settings.notifyMaghrib) { _, _ in rescheduleAll() }
                        .onChange(of: notificationManager.settings.notifyIsha) { _, _ in rescheduleAll() }
                    }
                }

                // MARK: - 3. Escalating Reminders
                if notificationManager.settings.notificationsEnabled {
                    Section(
                        header: Text("Escalating Reminders"),
                        footer: Text("If a prayer is not confirmed or logged, Sujud sends gentle escalating reminders before the prayer window expires.")
                    ) {
                        Toggle("Escalating Reminders", isOn: $notificationManager.settings.escalatingRemindersEnabled)
                            .tint(SujudTheme.primaryGreen)
                            .onChange(of: notificationManager.settings.escalatingRemindersEnabled) { _, _ in
                                rescheduleAll()
                            }

                        if notificationManager.settings.escalatingRemindersEnabled {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Reminder Intervals")
                                    .font(.subheadline)
                                Text("Alert at 15m, 30m, and 60m after Adhan (or until window ends)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)

                            Picker("Isha Window End", selection: $notificationManager.settings.ishaWindowEndRule) {
                                ForEach(IshaWindowEndRule.allCases, id: \.self) { rule in
                                    Text(rule.displayName).tag(rule)
                                }
                            }
                            .onChange(of: notificationManager.settings.ishaWindowEndRule) { _, _ in
                                rescheduleAll()
                            }
                        }
                    }
                }

                // MARK: - 4. Language & Layout
                Section(header: Text("Language & Layout")) {
                    Picker("App Language", selection: $notificationManager.settings.appLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                }

                // MARK: - 5. Apple Watch Verification Thresholds
                Section(
                    header: Text("Watch Verification Sensitivity"),
                    footer: Text("Adjust the sensitivity for Arabic recitation fuzzy matching and Sujud hold duration.")
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recitation Match Threshold")
                            Spacer()
                            Text("\(Int(notificationManager.settings.verificationConfig.minimumAudioConfidence * 100))%")
                                .foregroundStyle(SujudTheme.primaryGreen)
                                .fontWeight(.semibold)
                        }

                        Slider(
                            value: $notificationManager.settings.verificationConfig.minimumAudioConfidence,
                            in: 0.40...0.90,
                            step: 0.05
                        )
                        .tint(SujudTheme.primaryGreen)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Min Sujud Duration")
                            Spacer()
                            Text(String(format: "%.1f sec", notificationManager.settings.verificationConfig.minimumSujudDurationSeconds))
                                .foregroundStyle(SujudTheme.primaryGreen)
                                .fontWeight(.semibold)
                        }

                        Slider(
                            value: $notificationManager.settings.verificationConfig.minimumSujudDurationSeconds,
                            in: 1.0...4.0,
                            step: 0.5
                        )
                        .tint(SujudTheme.primaryGreen)
                    }
                    .padding(.vertical, 4)
                }

                // MARK: - 6. Privacy & Data Deletion
                Section(header: Text("Privacy & Data Sovereignity")) {
                    Button {
                        showingConsentSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "shield.lefthalf.filled")
                                .foregroundStyle(SujudTheme.primaryGreen)
                            Text("Review Privacy Principles")
                                .foregroundStyle(Color.primary)
                        }
                    }

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete All Stored Data & Logs")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingCalculationMethodSheet) {
                CalculationMethodPickerView(viewModel: prayerTimesViewModel)
            }
            .sheet(isPresented: $showingConsentSheet) {
                PrivacyConsentView(isPresented: $showingConsentSheet) {}
            }
            .alert("Delete All Data?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    notificationManager.deleteAllData()
                    prayerTimesViewModel.recalculateTimes()
                }
            } message: {
                Text("This permanently deletes all cached locations, calculation overrides, prayer logs, and cancels all scheduled adhan notifications.")
            }
        }
    }

    private func rescheduleAll() {
        if !prayerTimesViewModel.cachedMonthTimes.isEmpty {
            notificationManager.scheduleNotifications(using: prayerTimesViewModel.cachedMonthTimes)
        }
    }
}

/// Standalone sub-form for tuning minute adjustments for each prayer.
struct PrayerAdjustmentsFormView: View {
    @ObservedObject var viewModel: PrayerTimesViewModel

    var body: some View {
        Form {
            Section(footer: Text("Adjust minutes positively (+) or negatively (-) to synchronize with your local masjid timetable.")) {
                Stepper("Fajr: \(viewModel.adjustments.fajr > 0 ? "+" : "")\(viewModel.adjustments.fajr) min", value: $viewModel.adjustments.fajr, in: -30...30)
                Stepper("Sunrise: \(viewModel.adjustments.sunrise > 0 ? "+" : "")\(viewModel.adjustments.sunrise) min", value: $viewModel.adjustments.sunrise, in: -30...30)
                Stepper("Dhuhr: \(viewModel.adjustments.dhuhr > 0 ? "+" : "")\(viewModel.adjustments.dhuhr) min", value: $viewModel.adjustments.dhuhr, in: -30...30)
                Stepper("Asr: \(viewModel.adjustments.asr > 0 ? "+" : "")\(viewModel.adjustments.asr) min", value: $viewModel.adjustments.asr, in: -30...30)
                Stepper("Maghrib: \(viewModel.adjustments.maghrib > 0 ? "+" : "")\(viewModel.adjustments.maghrib) min", value: $viewModel.adjustments.maghrib, in: -30...30)
                Stepper("Isha: \(viewModel.adjustments.isha > 0 ? "+" : "")\(viewModel.adjustments.isha) min", value: $viewModel.adjustments.isha, in: -30...30)
            }
        }
        .navigationTitle("Minute Adjustments")
        .navigationBarTitleDisplayMode(.inline)
    }
}
