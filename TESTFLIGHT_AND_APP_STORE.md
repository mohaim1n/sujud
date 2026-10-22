# Sujud (Salah Companion) — TestFlight & App Store Deployment Guide

This document contains the complete App Store review answers, privacy nutritional label declarations, and manual Xcode release checklist for **Sujud**.

---

## 1. App Store Privacy "Nutritional Labels" Questionnaire

When completing the **App Privacy** section in App Store Connect:

### Q1: Do you or your third-party partners collect data from this app?
* **Answer:** **Yes** (Location only, for local offline astronomical calculations).

### Q2: Data Types Collected:
#### 1. Location (Coarse & Precise Location)
* **Collected?** Yes.
* **Usage:** App Functionality (calculating accurate local prayer times and great-circle Qibla bearing to Makkah).
* **Linked to User Identity?** **No**. Location is processed locally on-device and stored only in local device `UserDefaults`. It is never uploaded to any remote server.
* **Used for Tracking?** **No**. Sujud contains zero ad networks, third-party analytics, or IDFA trackers.

#### 2. Audio Data & Speech Recognition
* **Collected?** **No**.
* **App Store Explanation:** Microphone audio is captured strictly into volatile RAM during an active prayer session initiated by the user. Audio buffers are evaluated in-memory for Arabic prayer phrases and immediately discarded. No audio files or transcripts are ever written to disk or transmitted over the network.

#### 3. Motion & Fitness Data
* **Collected?** **No**.
* **App Store Explanation:** Apple Watch accelerometer and gyroscope sensors are processed on-device in real-time to detect Ruku (bowing) and Sujud (prostration) posture transitions. Sensor data is never saved, uploaded, or linked to user identity.

#### 4. Contact Info, Identifiers, Purchases, Diagnostics
* **Collected?** **No**. There are no user accounts, no subscriptions, no ads, and no tracking.

---

## 2. Review Notes for Apple App Store Reviewers

Copy and paste this message into the **Review Notes** field in App Store Connect:

> **Dear Apple Review Team,**
>
> Sujud is an offline, privacy-first Islamic prayer companion for iPhone and Apple Watch.
>
> 1. **No Account Required:** The app requires no login, no backend registration, and no tracking. All features work immediately upon launch.
> 2. **Microphone & Speech Recognition Usage:** In accordance with our privacy design, microphone access is requested strictly for on-device Arabic recitation matching during active prayer sessions initiated by the user. Audio buffers are processed purely in-memory via `AVAudioEngine` and `SFSpeechRecognizer` (with `requiresOnDeviceRecognition = true`) and are never written to disk, saved, or uploaded. A visible pulsing listening indicator is present throughout the session.
> 3. **Apple Watch Extended Runtime Session:** When the user begins a prayer session, a `WKExtendedRuntimeSession` is started so sensor tracking continues naturally while the user's wrist is downward in Ruku or resting on the prayer mat in Sujud.
> 4. **Location Usage:** CoreLocation coordinates are used strictly to calculate local astronomical solar angles and the Qibla bearing. 30 days of prayer times are pre-cached so the app works reliably in airplane mode.
>
> Thank you for your review.

---

## 3. TestFlight Build & Release Checklist

Follow these manual steps in Xcode before submitting your archive:

### Step 1: Set Bundle Identifiers & Development Team
1. In Xcode, select the root **Sujud** project in the Project Navigator.
2. Under **Signing & Capabilities**:
   - Set your **Development Team** for all targets:
     - `Sujud` (iOS App): `com.yourteam.sujud`
     - `SujudWatch` (watchOS App): `com.yourteam.sujud.watchkitapp`
     - `SujudWidgets` (Widget Extension): `com.yourteam.sujud.widgets`

### Step 2: Configure App Groups
1. On each of the three targets (`Sujud`, `SujudWatch`, `SujudWidgets`):
   - Under **Signing & Capabilities** > **App Groups**, ensure the group container `group.com.yourteam.sujud` is checked and active.

### Step 3: Configure Capabilities
1. **Main App (`Sujud`)**:
   - **Time-Sensitive Notifications**: Enabled (for prayer adhan alerts to break through Focus modes).
   - **Background Modes**: Remote notifications / Background fetch.
2. **Watch App (`SujudWatch`)**:
   - Verify `WKBackgroundModes` in `Info.plist` includes `mindfulness` and `physical-therapy` for `WKExtendedRuntimeSession`.

### Step 4: Archive and Upload
1. Select the **Any iOS Device (arm64)** scheme for the `Sujud` target.
2. Select **Product** > **Archive**.
3. In the Xcode Organizer, click **Distribute App** > **App Store Connect** > **Upload**.
4. Once processed in App Store Connect, invite internal testers in the **TestFlight** tab.
