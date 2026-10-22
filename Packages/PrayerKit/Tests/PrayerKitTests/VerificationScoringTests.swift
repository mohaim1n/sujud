import XCTest
@testable import PrayerKit

final class VerificationScoringTests: XCTestCase {

    var scorer: PrayerScorer!
    var config: VerificationConfig!

    override func setUp() {
        super.setUp()
        scorer = PrayerScorer()
        config = VerificationConfig(
            minimumAudioConfidence: 0.60,
            minimumRakahMatchRatio: 1.0,
            motionSensitivityG: 0.15,
            minimumSujudDurationSeconds: 1.0 // lowered for fast unit test
        )
    }

    // MARK: - Dual-Signal Fusion Evaluation

    func testConfirmedVerdictWhenBothPass() {
        // Fajr requires 2 rakahs
        let result = scorer.evaluate(
            prayer: .fajr,
            audioConfidence: 0.85,
            detectedRakahs: 2,
            expectedRakahs: 2,
            durationSeconds: 180,
            config: config
        )

        XCTAssertEqual(result.status, .confirmed)
        XCTAssertEqual(result.detectedRakahCount, 2)
        XCTAssertEqual(result.audioConfidence, 0.85)
    }

    func testPartialVerdictWhenAudioLowButRakahsMatch() {
        // Whispered prayer with correct motion
        let result = scorer.evaluate(
            prayer: .dhuhr,
            audioConfidence: 0.35, // Below 0.60, but >= 0.30
            detectedRakahs: 4,
            expectedRakahs: 4,
            durationSeconds: 300,
            config: config
        )

        XCTAssertEqual(result.status, .partial)
    }

    func testPartialVerdictWhenAudioHighButIncompleteRakahs() {
        // High audio recitation but only 1 of 4 rakahs detected
        let result = scorer.evaluate(
            prayer: .dhuhr,
            audioConfidence: 0.90,
            detectedRakahs: 1,
            expectedRakahs: 4,
            durationSeconds: 120,
            config: config
        )

        XCTAssertEqual(result.status, .partial)
    }

    func testNotDetectedVerdictWhenBothFail() {
        let result = scorer.evaluate(
            prayer: .asr,
            audioConfidence: 0.10,
            detectedRakahs: 0,
            expectedRakahs: 4,
            durationSeconds: 30,
            config: config
        )

        XCTAssertEqual(result.status, .notDetected)
    }

    func testManualSelfReportedOverride() {
        let result = scorer.createSelfReportedResult(
            prayer: .maghrib,
            durationSeconds: 240
        )

        XCTAssertEqual(result.status, .selfReported)
        XCTAssertEqual(result.detectedRakahCount, 3)
        XCTAssertEqual(result.expectedRakahCount, 3)
    }

    // MARK: - Posture Detector State Machine Simulation

    func testSimulatedRakahSequenceDetection() {
        let detector = PostureDetector(config: config)
        var completedRakahs = 0

        detector.onRakahCompleted = { count in
            completedRakahs = count
        }

        var t: TimeInterval = 1000.0

        // Helper to push a sequence of samples
        func feedPosture(pitchRad: Double, gravY: Double, gravZ: Double, userAcc: Double, duration: TimeInterval) {
            let steps = Int(duration * 25.0) // 25 Hz
            for _ in 0..<steps {
                t += (1.0 / 25.0)
                let sample = MotionSample(
                    timestamp: t,
                    gravityX: 0.0,
                    gravityY: gravY,
                    gravityZ: gravZ,
                    pitch: pitchRad,
                    roll: 0.0,
                    yaw: 0.0,
                    userAccelerationMagnitude: userAcc
                )
                detector.processSample(sample)
            }
        }

        // --- Rakah 1 ---
        // 1. Standing (Qiyam): pitch 0°, gravity Y -0.9, quiet
        feedPosture(pitchRad: 0.0, gravY: -0.9, gravZ: 0.0, userAcc: 0.05, duration: 3.0)
        XCTAssertEqual(detector.posture, .standing)

        // 2. Bowing (Ruku): pitch -75° (-1.3 rad), quiet
        feedPosture(pitchRad: -1.3, gravY: -0.2, gravZ: -0.8, userAcc: 0.05, duration: 2.0)
        XCTAssertEqual(detector.posture, .ruku)

        // 3. Upright (I'tidal): pitch 0°
        feedPosture(pitchRad: 0.0, gravY: -0.9, gravZ: 0.0, userAcc: 0.05, duration: 1.5)
        XCTAssertEqual(detector.posture, .standingAfterRuku)

        // 4. Sujud 1: Forearms flat, gravity Z -0.9, pitch 0°, quiet for 2 sec
        feedPosture(pitchRad: 0.0, gravY: 0.0, gravZ: -0.9, userAcc: 0.02, duration: 2.0)
        XCTAssertEqual(detector.posture, .sujud1)

        // 5. Jalsah (sitting between sujud): torso upright, gravity Y -0.8
        feedPosture(pitchRad: 0.1, gravY: -0.8, gravZ: -0.1, userAcc: 0.05, duration: 1.5)
        XCTAssertEqual(detector.posture, .sittingBetweenSujud)

        // 6. Sujud 2: Forearms flat, gravity Z -0.9
        feedPosture(pitchRad: 0.0, gravY: 0.0, gravZ: -0.9, userAcc: 0.02, duration: 2.0)
        XCTAssertEqual(detector.posture, .sujud2)

        // 7. Rise back to standing (completing 1st rakah)
        feedPosture(pitchRad: 0.0, gravY: -0.9, gravZ: 0.0, userAcc: 0.05, duration: 1.5)
        XCTAssertEqual(detector.posture, .standing)
        XCTAssertEqual(completedRakahs, 1, "Completed 1st rakah should be recognized")
        XCTAssertEqual(detector.rakahCount, 1)
    }
}
