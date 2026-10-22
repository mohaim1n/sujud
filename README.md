# Sujud (سجود) — Native Salah Companion for iPhone & Apple Watch

> **A native SwiftUI app for iPhone and Apple Watch that helps a Muslim pray all five daily prayers (Fajr, Dhuhr, Asr, Maghrib, Isha) on time. The Apple Watch reminds you, listens, and senses movement during prayer to verify completed rakahs.**

---

## 🌟 Highlights

- **100% On-Device & Offline**: No accounts, no third-party backends, no tracking. Everything computes locally.
- **Apple Watch Multi-Modal Verification**:
  - **Motion Signal**: 30 Hz CoreMotion posture state machine (`Standing` $\to$ `Ruku` $\to$ `Sujud 1` $\to$ `Sitting` $\to$ `Sujud 2`) detecting completed rakahs with `WKExtendedRuntimeSession` (runs with wrist down).
  - **Audio Signal**: In-memory `AVAudioEngine` + `SFSpeechRecognizer` (`ar-SA`, `requiresOnDeviceRecognition = true`) fuzzy matching key prayer phrases (Takbir, Al-Fatihah, Tasbih, Tashahhud, Taslim).
  - **Fusion Scoring**: Confirms prayer only when both audio confidence and detected rakah count match.
  - **Manual Override**: "I Prayed" button instantly logs the prayer as self-reported so a sensor miss never blocks you.
- **Accurate Astronomical Prayer Times**: High-precision Jean Meeus algorithms in `PrayerKit` supporting:
  - JAKIM (Malaysia)
  - Muis (Singapore)
  - Muslim World League (MWL)
  - Umm al-Qura (Makkah, Saudi Arabia)
  - ISNA (North America)
  - Egyptian General Authority of Survey
  - University of Islamic Sciences, Karachi
  - Asr Jurisprudence (Shafi'i/Maliki/Hanbali vs. Hanafi shadow ratios)
  - High-latitude rules & per-prayer safety minute adjustments
- **Interactive Qibla Finder**: Great-circle bearing and geodesic distance to the Holy Kaaba ($21.4225^\circ\text{ N}, 39.8262^\circ\text{ E}$) with smooth circular low-pass filtering and haptic alignment feedback within $\pm 3^\circ$.
- **Time-Sensitive Adhan Reminders**: Escalating notifications (+15m, +30m, +60m) that break through Focus modes, automatically bounded by each prayer's closing window.
- **WidgetKit & Complications**: Lock screen widgets and Apple Watch complications (`accessoryCircular`, `accessoryRectangular`, `accessoryInline`, `accessoryCorner`).
- **WatchConnectivity**: Automatic bidirectional sync between iPhone and Apple Watch with independent offline watch operation.

---

## 🏗️ Architecture & Project Structure

Built with Swift 5.9+, SwiftUI, MVVM, async/await, and protocol-based services:

```
Sujud/
├── Packages/
│   └── PrayerKit/                              # Core Astronomical & Verification Framework
│       ├── Package.swift
│       ├── Sources/PrayerKit/
│       │   ├── Calculation/                    # Astronomical math, Solar coords, Qibla math
│       │   ├── Models/                         # Prayer, Qibla, Settings, Record, Verification types
│       │   ├── Services/                       # Offline caching, Qibla service, Localizer
│       │   └── Verification/                   # Posture FSM detector & Dual-signal Scorer
│       └── Tests/PrayerKitTests/               # Unit test suites (MWL, JAKIM, Umm al-Qura, Qibla, FSM)
├── Sujud/                                      # iOS Application Target
│   ├── Info.plist & Sujud.entitlements
│   ├── SujudApp.swift
│   ├── Services/                               # CoreLocation, Notifications, History, WatchConnectivity
│   ├── Theme/                                  # SujudTheme (Emerald, Forest, Gold, Alignment Green)
│   ├── ViewModels/                             # PrayerTimesViewModel, QiblaViewModel
│   └── Views/                                  # MainTabView, PrayerTimesView, QiblaCompassView, HistoryView, SettingsView
├── SujudWatch/                                 # watchOS Application Target
│   ├── Info.plist & SujudWatch.entitlements
│   ├── SujudWatchApp.swift
│   ├── Services/                               # AudioRecitationRecognizer, WatchMotionManager, ExtendedRuntime, WatchReceiver
│   ├── ViewModels/                             # WatchPrayerViewModel, PrayerSessionViewModel
│   └── Views/                                  # WatchHomeView, FivePrayerRingsView, ActivePrayerSessionView, SummaryView
└── SujudWidgets/                               # WidgetKit & Apple Watch Complications Extension
    ├── Info.plist & SujudWidgets.entitlements
    ├── SujudWidgetsBundle.swift
    └── PrayerComplications.swift
```

---

## 🔒 Privacy Principles

1. **In-Memory Audio Processing Only**: Audio buffers are processed purely in volatile RAM and immediately discarded. No audio recordings or transcripts are ever saved, logged, or uploaded.
2. **On-Device Posture Sensing**: Motion data never leaves your Apple Watch.
3. **No Tracking, Ads, or Accounts**: No third-party SDKs, no IDFA, no analytics.
4. **Data Sovereignty**: Complete data deletion with a single tap in Settings.

---

## 🚀 Getting Started

1. Open Xcode 15+ on macOS.
2. Open the `Sujud` directory or add `Packages/PrayerKit` to your Xcode workspace.
3. Select the `Sujud` scheme for iOS or `SujudWatch` for watchOS.
4. Build and run (**Cmd + R**).
