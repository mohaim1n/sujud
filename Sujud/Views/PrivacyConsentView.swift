import SwiftUI
import PrayerKit

/// Clear privacy consent screen presented before initial sensor / audio session activation.
public struct PrivacyConsentView: View {
    @Binding var isPresented: Bool
    var onConsentGranted: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    public init(isPresented: Binding<Bool>, onConsentGranted: @escaping () -> Void) {
        self._isPresented = isPresented
        self.onConsentGranted = onConsentGranted
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header Icon
                    ZStack {
                        Circle()
                            .fill(SujudTheme.primaryGreen.opacity(0.12))
                            .frame(width: 80, height: 80)

                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(SujudTheme.primaryGreen)
                    }
                    .padding(.top, 20)

                    // Title & Introduction
                    VStack(spacing: 8) {
                        Text("Your Privacy in Salah")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)

                        Text("Sujud is built to honor your sacred space. Every calculation and sensor verification runs strictly on your device.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }

                    // Four Privacy Pillars
                    VStack(spacing: 20) {
                        PrivacyFeatureRow(
                            iconName: "waveform.slash",
                            title: "Zero Audio Storage or Uploads",
                            description: "Audio is captured only during a prayer session you start yourself, processed purely in memory for Arabic recitation matching, and instantly discarded. Transcripts and audio files are never stored or uploaded."
                        )

                        PrivacyFeatureRow(
                            iconName: "figure.walk.motion",
                            title: "On-Device Posture Sensing",
                            description: "Accelerometer and gyroscope data from Apple Watch stay entirely on your wrist to recognize Ruku and Sujud sequences."
                        )

                        PrivacyFeatureRow(
                            iconName: "location.slash.fill",
                            title: "Private Offline Times & Qibla",
                            description: "Your location is used solely to compute local astronomical angles and the initial bearing to Makkah. Times are cached 30 days ahead so the app works in airplane mode."
                        )

                        PrivacyFeatureRow(
                            iconName: "trash.circle.fill",
                            title: "Complete Data Erasure",
                            description: "You have complete sovereignty over your data. A single tap erases all local history, cached locations, and settings at any time."
                        )
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 24)

                    // Primary Consent Button
                    Button {
                        isPresented = false
                        onConsentGranted()
                    } label: {
                        Text("I Understand & Consent")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(SujudTheme.primaryGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
            .background(colorScheme == .dark ? Color.black : SujudTheme.softBackground)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PrivacyFeatureRow: View {
    let iconName: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 22))
                .foregroundStyle(SujudTheme.primaryGreen)
                .frame(width: 32)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primary)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
        }
    }
}
