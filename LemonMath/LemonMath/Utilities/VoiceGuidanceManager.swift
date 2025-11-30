//
//  VoiceGuidanceManager.swift
//  LemonMath
//

import Foundation
import AVFoundation

// MARK: - Voice Guidance Manager
class VoiceGuidanceManager: ObservableObject {
    static let shared = VoiceGuidanceManager()

    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false

    private var currentLanguage: SupportedLanguage = .english

    private init() {
        setupAudioSession()
    }

    // MARK: - Setup

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    // MARK: - Public Methods

    func setLanguage(_ language: SupportedLanguage) {
        currentLanguage = language
    }

    func speak(_ text: String, priority: SpeechPriority = .normal) {
        guard !text.isEmpty else { return }

        if priority == .high {
            synthesizer.stopSpeaking(at: .immediate)
        } else if synthesizer.isSpeaking {
            return
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: currentLanguage.code)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func speakSolution(_ problem: MathProblem) {
        var text = ""

        switch currentLanguage {
        case .english:
            text = "Problem: \(problem.problemText). Solution: \(problem.solution)."
            if !problem.steps.isEmpty {
                text += " Here are the steps: "
                for step in problem.steps {
                    text += "Step \(step.stepNumber): \(step.title). \(step.explanation). "
                }
            }
        case .greek:
            text = "Πρόβλημα: \(problem.problemText). Λύση: \(problem.solution)."
            if !problem.steps.isEmpty {
                text += " Εδώ είναι τα βήματα: "
                for step in problem.steps {
                    text += "Βήμα \(step.stepNumber): \(step.title). \(step.explanation). "
                }
            }
        }

        speak(text)
    }

    func speakStep(_ step: SolutionStep) {
        switch currentLanguage {
        case .english:
            speak("Step \(step.stepNumber): \(step.title). \(step.explanation)")
        case .greek:
            speak("Βήμα \(step.stepNumber): \(step.title). \(step.explanation)")
        }
    }

    func speakAchievementUnlocked(_ achievement: Achievement) {
        switch currentLanguage {
        case .english:
            speak("Achievement unlocked! \(achievement.title). \(achievement.description)", priority: .high)
        case .greek:
            speak("Επίτευγμα ξεκλειδώθηκε! \(achievement.title). \(achievement.description)", priority: .high)
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .word)
    }

    func resume() {
        synthesizer.continueSpeaking()
    }

    enum SpeechPriority {
        case normal
        case high
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension VoiceGuidanceManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}
