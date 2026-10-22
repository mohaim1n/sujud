import SwiftUI
import PrayerKit

/// Main Prayer Times screen displaying daily times, next prayer countdown, and calculation method controls.
public struct PrayerTimesView: View {
    @ObservedObject var viewModel: PrayerTimesViewModel
    @ObservedObject var locationManager: LocationManager

    @State private var showingMethodPicker: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    public init(viewModel: PrayerTimesViewModel, locationManager: LocationManager) {
        self.viewModel = viewModel
        self.locationManager = locationManager
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Location Permission Warning Banner (if denied)
                    if let error = locationManager.locationError {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(SujudTheme.warmGold)
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if locationManager.authorizationStatus == .notDetermined {
                                Button("Allow") {
                                    locationManager.requestAuthorization()
                                }
                                .font(.caption.bold())
                                .foregroundStyle(SujudTheme.primaryGreen)
                            }
                        }
                        .padding(14)
                        .background(SujudTheme.cardBackground(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                    }

                    // Next Prayer Hero Card
                    NextPrayerCardView(
                        viewModel: viewModel,
                        placeName: locationManager.placeName
                    )
                    .padding(.horizontal)

                    // Calculation Method Indicator Pill
                    HStack {
                        Button {
                            showingMethodPicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.caption2)
                                Text(viewModel.selectedMethod.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundStyle(SujudTheme.primaryGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(SujudTheme.primaryGreen.opacity(0.1))
                            .clipShape(Capsule())
                        }

                        Spacer()

                        // Asr Madhab Quick Toggle
                        Menu {
                            Button(Madhab.shafi.displayName) {
                                viewModel.selectedMadhab = .shafi
                            }
                            Button(Madhab.hanafi.displayName) {
                                viewModel.selectedMadhab = .hanafi
                            }
                        } label: {
                            Text(viewModel.selectedMadhab == .shafi ? "Shafi'i" : "Hanafi")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)

                    // Daily Prayer Schedule
                    if let times = viewModel.todayTimes {
                        VStack(spacing: 10) {
                            ForEach(Prayer.allCases) { prayer in
                                let time = times.time(for: prayer)
                                let isCurrent = viewModel.currentPrayer == prayer
                                let isNext = viewModel.nextPrayer?.prayer == prayer

                                PrayerRowView(
                                    prayer: prayer,
                                    time: time,
                                    isCurrent: isCurrent,
                                    isNext: isNext
                                )
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        ProgressView("Calculating prayer times...")
                            .padding(40)
                    }

                    // Bottom info notice
                    Text("Calculated on-device using local astronomical formulas. 30 days cached for offline use.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(colorScheme == .dark ? Color.black : SujudTheme.softBackground)
            .navigationTitle("Prayer Times")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingMethodPicker = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(SujudTheme.primaryGreen)
                    }
                }
            }
            .sheet(isPresented: $showingMethodPicker) {
                CalculationMethodPickerView(viewModel: viewModel)
            }
            .refreshable {
                viewModel.recalculateTimes()
            }
        }
    }
}

/// Sheet for selecting calculation method, Madhab, and safety adjustments.
struct CalculationMethodPickerView: View {
    @ObservedObject var viewModel: PrayerTimesViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Calculation Authority")) {
                    ForEach(CalculationMethod.allCases.filter { $0 != .custom }) { method in
                        Button {
                            viewModel.selectedMethod = method
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(method.displayName)
                                        .font(.body)
                                        .foregroundStyle(Color.primary)
                                    Text(method.methodDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if viewModel.selectedMethod == method {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(SujudTheme.primaryGreen)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Asr Calculation (Madhab)")) {
                    Picker("School of Jurisprudence", selection: $viewModel.selectedMadhab) {
                        ForEach(Madhab.allCases, id: \.self) { madhab in
                            Text(madhab.displayName).tag(madhab)
                        }
                    }
                }

                Section(header: Text("Safety Adjustments (Minutes)"), footer: Text("Add or subtract minutes to match your local mosque timetable.")) {
                    Stepper("Fajr: \(viewModel.adjustments.fajr > 0 ? "+" : "")\(viewModel.adjustments.fajr) min", value: $viewModel.adjustments.fajr, in: -30...30)
                    Stepper("Dhuhr: \(viewModel.adjustments.dhuhr > 0 ? "+" : "")\(viewModel.adjustments.dhuhr) min", value: $viewModel.adjustments.dhuhr, in: -30...30)
                    Stepper("Asr: \(viewModel.adjustments.asr > 0 ? "+" : "")\(viewModel.adjustments.asr) min", value: $viewModel.adjustments.asr, in: -30...30)
                    Stepper("Maghrib: \(viewModel.adjustments.maghrib > 0 ? "+" : "")\(viewModel.adjustments.maghrib) min", value: $viewModel.adjustments.maghrib, in: -30...30)
                    Stepper("Isha: \(viewModel.adjustments.isha > 0 ? "+" : "")\(viewModel.adjustments.isha) min", value: $viewModel.adjustments.isha, in: -30...30)
                }
            }
            .navigationTitle("Prayer Calculation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(SujudTheme.primaryGreen)
                }
            }
        }
    }
}
