import Foundation
import AVFoundation
import SwiftUI

@Observable
public final class TTSEngineService: NSObject, @unchecked Sendable {
    public static let shared = TTSEngineService()

    // MARK: - Observable State
    public var isPlaying: Bool = false
    public var isPaused: Bool = false
    public var currentWordRange: NSRange?
    public var currentText: String = ""
    public var currentBookTitle: String = ""
    public var currentChapterTitle: String = ""
    public var selectedLanguageCode: String = "en-US"
    public var selectedVoiceId: String {
        get { selectedLanguageCode }
        set { selectVoice(id: newValue) }
    }
    public var selectedVoiceName: String = "Samantha"
    public var speechRate: Float = AVSpeechUtteranceDefaultSpeechRate
    public var speechPitch: Float = 1.0
    public var availableVoices: [TTSVoiceOption] = []

    // MARK: - Internal Synthesizer
    @ObservationIgnored
    private let synthesizer = AVSpeechSynthesizer()

    @ObservationIgnored
    private var currentUtterance: AVSpeechUtterance?

    override private init() {
        super.init()
        self.synthesizer.delegate = self
        setupAudioSession()
        loadStandardVoices()
    }

    public func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .allowBluetoothHFP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("TTSEngineService setupAudioSession: \(error.localizedDescription)")
        }
    }

    /// Pre-configures verified high-quality voice profiles statically to prevent
    /// triggering the Apple iOS simulator VoiceServices container decoding bug.
    public func loadStandardVoices() {
        self.availableVoices = [
            TTSVoiceOption(
                id: "en-US",
                name: "Samantha",
                language: "en-US",
                regionName: "United States",
                qualityDescription: "Natural Studio",
                gender: "Female",
                flag: "🇺🇸"
            ),
            TTSVoiceOption(
                id: "en-GB",
                name: "Daniel",
                language: "en-GB",
                regionName: "United Kingdom",
                qualityDescription: "Enhanced Studio",
                gender: "Male",
                flag: "🇬🇧"
            ),
            TTSVoiceOption(
                id: "en-AU",
                name: "Karen",
                language: "en-AU",
                regionName: "Australia",
                qualityDescription: "Natural Studio",
                gender: "Female",
                flag: "🇦🇺"
            ),
            TTSVoiceOption(
                id: "en-IE",
                name: "Moira",
                language: "en-IE",
                regionName: "Ireland",
                qualityDescription: "Natural Studio",
                gender: "Female",
                flag: "🇮🇪"
            ),
            TTSVoiceOption(
                id: "en-IN",
                name: "Rishi",
                language: "en-IN",
                regionName: "India",
                qualityDescription: "Natural Studio",
                gender: "Male",
                flag: "🇮🇳"
            ),
            TTSVoiceOption(
                id: "en-ZA",
                name: "Tessa",
                language: "en-ZA",
                regionName: "South Africa",
                qualityDescription: "Natural Studio",
                gender: "Female",
                flag: "🇿🇦"
            ),
            TTSVoiceOption(
                id: "fr-FR",
                name: "Thomas",
                language: "fr-FR",
                regionName: "France",
                qualityDescription: "Natural Studio",
                gender: "Male",
                flag: "🇫🇷"
            ),
            TTSVoiceOption(
                id: "es-ES",
                name: "Monica",
                language: "es-ES",
                regionName: "Spain",
                qualityDescription: "Natural Studio",
                gender: "Female",
                flag: "🇪🇸"
            ),
            TTSVoiceOption(
                id: "de-DE",
                name: "Anna",
                language: "de-DE",
                regionName: "Germany",
                qualityDescription: "Natural Studio",
                gender: "Female",
                flag: "🇩🇪"
            )
        ]

        if let savedLang = UserDefaults.standard.string(forKey: "selectedLanguageCode"), !savedLang.isEmpty {
            self.selectedLanguageCode = savedLang
        } else {
            self.selectedLanguageCode = "en-US"
        }
    }

    // MARK: - Live Speech Narration

    public func speak(text: String, bookTitle: String = "Audiobook", chapterTitle: String = "Chapter") {
        setupAudioSession()
        stop()

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        self.currentText = trimmed
        self.currentBookTitle = bookTitle
        self.currentChapterTitle = chapterTitle

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = 0.05

        if let voice = AVSpeechSynthesisVoice(language: selectedLanguageCode) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        self.currentUtterance = utterance
        self.isPlaying = true
        self.isPaused = false

        synthesizer.speak(utterance)
    }

    public func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
            self.isPaused = true
            self.isPlaying = false
        }
    }

    public func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            self.isPaused = false
            self.isPlaying = true
        }
    }

    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else if isPaused {
            resume()
        }
    }

    public func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        self.isPlaying = false
        self.isPaused = false
        self.currentWordRange = nil
    }

    public func selectVoice(id: String) {
        self.selectedLanguageCode = id
        UserDefaults.standard.set(id, forKey: "selectedLanguageCode")
        if isPlaying {
            speak(text: currentText, bookTitle: currentBookTitle, chapterTitle: currentChapterTitle)
        }
    }

    public func previewVoice(_ option: TTSVoiceOption) {
        synthesizer.stopSpeaking(at: .immediate)
        setupAudioSession()
        let sample = "Hello! I am \(option.name), your personalized narrator for AudioBy."
        let utterance = AVSpeechUtterance(string: sample)
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        if let voice = AVSpeechSynthesisVoice(language: option.id) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        synthesizer.speak(utterance)
    }
}

// MARK: - AVSpeechSynthesizerDelegate for Live Word Synchronization
extension TTSEngineService: AVSpeechSynthesizerDelegate {
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.currentWordRange = characterRange
        }
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.isPaused = false
            self.currentWordRange = nil
        }
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPaused = true
            self.isPlaying = false
        }
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPaused = false
            self.isPlaying = true
        }
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.isPaused = false
            self.currentWordRange = nil
        }
    }
}
