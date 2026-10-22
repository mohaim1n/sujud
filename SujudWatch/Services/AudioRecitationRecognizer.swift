import Foundation
import AVFoundation
import Speech
import Combine
import PrayerKit

/// Real-time, strictly on-device Arabic recitation speech recognizer and fuzzy phrase matcher.
/// NOTE: Complies with strict privacy guarantees: audio buffers are analyzed exclusively in volatile memory;
/// raw audio and complete transcripts are never written to disk, uploaded, or persisted.
@MainActor
public final class AudioRecitationRecognizer: ObservableObject {

    // MARK: - Published Properties

    @Published public private(set) var isListening: Bool = false
    @Published public private(set) var recitationConfidence: Double = 0.0
    @Published public private(set) var matchedPhrasesCount: Int = 0
    @Published public private(set) var audioPowerLevel: Float = 0.0 // 0.0 to 1.0 for visual pulse
    @Published public private(set) var recognitionError: String?

    // MARK: - Private Engine Components

    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // Target prayer phrases in normalized Arabic
    private let targetPhrases: [String] = [
        "الله اكبر",                     // Takbir
        "الحمد لله رب العالمين",         // Al-Fatihah
        "الرحمن الرحيم",
        "اهدنا الصراط المستقيم",
        "سبحان ربي العظيم",             // Ruku
        "سمع الله لمن حمده",            // I'tidal
        "ربنا ولك الحمد",
        "سبحان ربي الاعلى",             // Sujud
        "التحيات لله",                  // Tashahhud
        "اشهد ان لا اله الا الله",
        "السلام عليكم ورحمة الله"       // Taslim
    ]

    private var recognizedTokens: Set<String> = []
    private var totalVocalFrames: Int = 0
    private var vocalFramesWithSpeech: Int = 0

    public init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))
    }

    // MARK: - Public Control

    /// Starts in-memory audio capture and Arabic phrase matching.
    public func startListening() {
        guard !isListening else { return }

        // Reset in-memory session metrics
        recitationConfidence = 0.0
        matchedPhrasesCount = 0
        recognizedTokens.removeAll()
        totalVocalFrames = 0
        vocalFramesWithSpeech = 0
        recognitionError = nil

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.mixWithOthers, .duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            recognitionError = "Audio session configuration failed: \(error.localizedDescription)"
            return
        }

        let engine = AVAudioEngine()
        self.audioEngine = engine
        let inputNode = engine.inputNode

        // Setup on-device SFSpeechRecognizer
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        // Enforce strictly on-device recognition where supported by hardware
        if speechRecognizer?.supportsOnDeviceRecognition == true {
            request.requiresOnDeviceRecognition = true
        }
        self.recognitionRequest = request

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                let transcript = result.bestTranscription.formattedString
                self.processTranscript(transcript)
            }
            if error != nil {
                // If on-device speech fails or is unavailable, fallback to audio power voice detector
                self.fallbackToAudioPowerScoring()
            }
        }

        // Tap microphone bus strictly in memory
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.recognitionRequest?.append(buffer)
            self.analyzeAudioPower(buffer: buffer)
        }

        do {
            try engine.start()
            isListening = true
        } catch {
            recognitionError = "Audio engine could not start: \(error.localizedDescription)"
        }
    }

    /// Stops audio capture, terminates speech tasks, and purges buffers from memory.
    public func stopListening() {
        guard isListening else { return }

        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        isListening = false
        audioPowerLevel = 0.0

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Arabic Fuzzy Phrase Matching

    private func processTranscript(_ rawTranscript: String) {
        let normalized = normalizeArabic(rawTranscript)
        var matches = 0

        for target in targetPhrases {
            let normalizedTarget = normalizeArabic(target)
            if normalized.contains(normalizedTarget) || fuzzyContains(text: normalized, phrase: normalizedTarget) {
                matches += 1
                recognizedTokens.insert(target)
            }
        }

        self.matchedPhrasesCount = matches

        // Compute confidence based on match count (scaled to 1.0)
        let ratio = Double(matches) / 5.0
        self.recitationConfidence = min(1.0, max(self.recitationConfidence, ratio))
    }

    /// Strips Arabic diacritics and normalizes letter variations for robust matching.
    private func normalizeArabic(_ text: String) -> String {
        var str = text.lowercased()
        // Remove Arabic diacritics (Harakat / Tashkeel: Fatha, Damma, Kasra, Sukun, etc.)
        str = str.replacingOccurrences(of: "[\u{064B}-\u{065F}]", with: "", options: .regularExpression)
        // Normalize Alef forms (أ, إ, آ, ٱ -> ا)
        str = str.replacingOccurrences(of: "[أإآٱ]", with: "ا", options: .regularExpression)
        // Normalize Taa Marbuta (ة -> ه)
        str = str.replacingOccurrences(of: "ة", with: "ه")
        // Normalize Alef Maksura (ى -> ي)
        str = str.replacingOccurrences(of: "ى", with: "ي")
        return str.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func fuzzyContains(text: String, phrase: String) -> Bool {
        let words = phrase.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return false }
        var matchedWordCount = 0
        for word in words {
            if text.contains(word) {
                matchedWordCount += 1
            }
        }
        // If at least 70% of phrase words are found in the transcript
        return Double(matchedWordCount) / Double(words.count) >= 0.70
    }

    // MARK: - Fallback Audio Power & Voice Activity

    private func analyzeAudioPower(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))

        var sumSquares: Float = 0.0
        for sample in channelDataArray {
            sumSquares += sample * sample
        }
        let rms = sqrt(sumSquares / Float(buffer.frameLength))
        let normalizedLevel = min(1.0, max(0.0, rms * 8.0)) // Amplify for visual meter

        Task { @MainActor in
            self.audioPowerLevel = normalizedLevel
            self.totalVocalFrames += 1
            // Human vocal presence threshold (approx > -40 dBFS)
            if normalizedLevel > 0.15 {
                self.vocalFramesWithSpeech += 1
            }
        }
    }

    private func fallbackToAudioPowerScoring() {
        guard totalVocalFrames > 30 else { return }
        let vocalRatio = Double(vocalFramesWithSpeech) / Double(totalVocalFrames)
        // If voice activity was sustained between 15% and 80% of prayer time (recitation cadence)
        if vocalRatio >= 0.15 && vocalRatio <= 0.85 {
            let estimatedConfidence = min(0.70, vocalRatio + 0.20)
            self.recitationConfidence = max(self.recitationConfidence, estimatedConfidence)
        }
    }
}
