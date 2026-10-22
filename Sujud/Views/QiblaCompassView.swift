import SwiftUI
import PrayerKit

/// Interactive Qibla Compass view providing smooth bearing rotation, alignment haptics, and calibration warnings.
public struct QiblaCompassView: View {
    @ObservedObject var viewModel: QiblaViewModel
    @ObservedObject var locationManager: LocationManager

    @Environment(\.colorScheme) private var colorScheme

    public init(viewModel: QiblaViewModel, locationManager: LocationManager) {
        self.viewModel = viewModel
        self.locationManager = locationManager
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.black : SujudTheme.softBackground)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header Status
                    VStack(spacing: 6) {
                        if viewModel.isAligned {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                Text("ALIGNED WITH THE KAABA")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(SujudTheme.alignmentGreen)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(SujudTheme.alignmentGreen.opacity(0.12))
                            .clipShape(Capsule())
                            .transition(.scale.combined(with: .opacity))
                        } else {
                            Text(alignmentInstructionText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let qibla = viewModel.qibla {
                            Text(qibla.formattedBearing)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(viewModel.isAligned ? SujudTheme.alignmentGreen : Color.primary)
                                .contentTransition(.numericText())
                        }
                    }
                    .padding(.top, 16)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.isAligned)

                    Spacer()

                    // Compass Graphic
                    ZStack {
                        // Outer Static Bezel
                        Circle()
                            .stroke(
                                viewModel.isAligned ? SujudTheme.alignmentGreen : (colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08)),
                                lineWidth: viewModel.isAligned ? 5 : 3
                            )
                            .frame(width: 300, height: 300)
                            .animation(.easeInOut(duration: 0.25), value: viewModel.isAligned)

                        // Subtle Glowing Halo when Aligned
                        if viewModel.isAligned {
                            Circle()
                                .fill(SujudTheme.alignmentGreen.opacity(0.12))
                                .frame(width: 310, height: 310)
                                .blur(radius: 10)
                                .transition(.opacity)
                        }

                        // Rotating Compass Dial (Turns with device heading so North is true North)
                        RotatingDialView(currentHeading: viewModel.currentHeading)
                            .frame(width: 280, height: 280)

                        // Qibla Indicator Needle (Points directly towards Makkah)
                        if let qibla = viewModel.qibla {
                            QiblaNeedleView(
                                needleAngle: qibla.bearing - viewModel.currentHeading,
                                isAligned: viewModel.isAligned
                            )
                            .frame(width: 280, height: 280)
                        }

                        // Center Pivot Cap
                        Circle()
                            .fill(viewModel.isAligned ? SujudTheme.alignmentGreen : SujudTheme.primaryGreen)
                            .frame(width: 18, height: 18)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                            .shadow(radius: 2)
                    }
                    .padding(.vertical, 8)

                    Spacer()

                    // Distance and Calibration Banner
                    VStack(spacing: 12) {
                        if let qibla = viewModel.qibla {
                            HStack(spacing: 6) {
                                Image(systemName: "safari.fill")
                                    .foregroundStyle(SujudTheme.primaryGreen)
                                Text("\(qibla.formattedDistance) to Makkah al-Mukarramah")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Calibration & Metal Interference Warning
                        if viewModel.requiresCalibration {
                            HStack(spacing: 10) {
                                Image(systemName: "figure.walk.motion")
                                    .foregroundStyle(SujudTheme.warmGold)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Calibrate Compass")
                                        .font(.caption.bold())
                                    Text("Wave phone in a figure-8 motion. Avoid nearby metal cases or magnets.")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(12)
                            .background(SujudTheme.cardBackground(for: colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Qibla Finder")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.onAppear()
            }
            .onDisappear {
                viewModel.onDisappear()
            }
        }
    }

    private var alignmentInstructionText: String {
        let diff = viewModel.angleDifference
        if abs(diff) <= 3.0 {
            return "Aligned"
        } else if diff > 0 {
            return "Turn right \(Int(diff.rounded()))°"
        } else {
            return "Turn left \(Int(abs(diff).rounded()))°"
        }
    }
}

// MARK: - Rotating Dial View

struct RotatingDialView: View {
    let currentHeading: Double

    var body: some View {
        ZStack {
            // Ticks around the circle
            ForEach(0..<72) { tick in
                Rectangle()
                    .fill(tick % 18 == 0 ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: tick % 18 == 0 ? 2.5 : 1, height: tick % 18 == 0 ? 12 : 6)
                    .offset(y: -126)
                    .rotationEffect(.degrees(Double(tick) * 5))
            }

            // Cardinal Labels: N, E, S, W
            Text("N")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.red)
                .offset(y: -108)

            Text("E")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .offset(x: 108)

            Text("S")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .offset(y: 108)

            Text("W")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .offset(x: -108)
        }
        .rotationEffect(.degrees(-currentHeading))
        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.85), value: currentHeading)
    }
}

// MARK: - Qibla Pointer Needle

struct QiblaNeedleView: View {
    let needleAngle: Double
    let isAligned: Bool

    var body: some View {
        ZStack {
            // Kaaba Direction Pointer
            VStack(spacing: 0) {
                // Kaaba Icon Head
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isAligned ? SujudTheme.alignmentGreen : SujudTheme.primaryGreen)
                        .frame(width: 32, height: 32)
                        .shadow(color: (isAligned ? SujudTheme.alignmentGreen : SujudTheme.primaryGreen).opacity(0.4), radius: 6, x: 0, y: 3)

                    // Miniature Kaaba gold band
                    VStack(spacing: 3) {
                        Rectangle()
                            .fill(SujudTheme.warmGold)
                            .frame(width: 24, height: 3)
                        Spacer()
                    }
                    .padding(4)
                }
                .offset(y: -128)

                // Pointer shaft
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                isAligned ? SujudTheme.alignmentGreen : SujudTheme.primaryGreen,
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4, height: 70)
                    .offset(y: -85)
            }
        }
        .rotationEffect(.degrees(needleAngle))
        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.85), value: needleAngle)
    }
}
