import SwiftUI
import PrayerKit

/// Calm, distraction-free Apple Watch prayer session screen.
public struct ActivePrayerSessionView: View {
    @StateObject private var sessionViewModel: PrayerSessionViewModel
    @Environment(\.dismiss) private var dismiss

    var onSessionFinished: ((VerificationResult) -> Void)?

    public init(
        prayer: Prayer,
        onSessionFinished: ((VerificationResult) -> Void)? = nil
    ) {
        _sessionViewModel = StateObject(wrappedValue: PrayerSessionViewModel(prayer: prayer))
        self.onSessionFinished = onSessionFinished
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if sessionViewModel.isCompleted, let summary = sessionViewModel.sessionSummary {
                PrayerSessionSummaryView(summary: summary) {
                    onSessionFinished?(summary)
                    dismiss()
                }
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        // Header: Prayer Name and Privacy Listening Indicator
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(sessionViewModel.prayer.englishName.uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(SujudTheme.warmGold)
                                Text(sessionViewModel.prayer.arabicName)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            // Visible Microphone Indicator (Apple Privacy Requirement)
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(sessionViewModel.isListening ? SujudTheme.primaryGreen : Color.gray)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(sessionViewModel.isListening ? (1.0 + CGFloat(sessionViewModel.audioPulseLevel) * 0.4) : 1.0)
                                    .animation(.easeInOut(duration: 0.15), value: sessionViewModel.audioPulseLevel)

                                Image(systemName: "waveform")
                                    .font(.system(size: 10))
                                    .foregroundStyle(sessionViewModel.isListening ? SujudTheme.primaryGreen : .secondary)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .padding(.top, 2)

                        Spacer(minLength: 4)

                        // Central Rakah Counter
                        VStack(spacing: 2) {
                            Text("RAKAH")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)

                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\(sessionViewModel.detectedRakahs)")
                                    .font(.system(size: 38, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                Text("/ \(sessionViewModel.targetRakahs)")
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }

                            // Current Detected Posture
                            Text(sessionViewModel.currentPosture.displayName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(SujudTheme.primaryGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(SujudTheme.primaryGreen.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 2)

                        // Elapsed Time
                        Text(formattedTime(sessionViewModel.elapsedTimeSeconds))
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.secondary)

                        Spacer(minLength: 4)

                        // Primary Action: Finish Prayer
                        Button {
                            sessionViewModel.completeSession()
                        } label: {
                            Text("Finish Prayer")
                                .font(.system(size: 14, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(SujudTheme.primaryGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)

                        // Secondary Action: Manual "I Prayed" Override
                        Button {
                            sessionViewModel.selfReportSession()
                        } label: {
                            Text("I Prayed (Manual)")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                    }
                    .padding(.horizontal, 6)
                }
            }
        }
        .onAppear {
            sessionViewModel.startSession()
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
