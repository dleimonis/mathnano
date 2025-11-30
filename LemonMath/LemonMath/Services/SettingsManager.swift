//
//  SettingsManager.swift
//  LemonMath
//

import Foundation
import SwiftUI
import Combine

// MARK: - Settings Manager
@MainActor
class SettingsManager: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedLanguage: SupportedLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: Keys.language)
        }
    }

    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: Keys.darkMode)
        }
    }

    @Published var useSystemAppearance: Bool {
        didSet {
            UserDefaults.standard.set(useSystemAppearance, forKey: Keys.systemAppearance)
        }
    }

    @Published var isVoiceGuidanceEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isVoiceGuidanceEnabled, forKey: Keys.voiceGuidance)
        }
    }

    @Published var useLargeText: Bool {
        didSet {
            UserDefaults.standard.set(useLargeText, forKey: Keys.largeText)
        }
    }

    @Published var textSizeMultiplier: Double {
        didSet {
            UserDefaults.standard.set(textSizeMultiplier, forKey: Keys.textSizeMultiplier)
        }
    }

    @Published var isHapticFeedbackEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isHapticFeedbackEnabled, forKey: Keys.hapticFeedback)
        }
    }

    @Published var animationSpeed: AnimationSpeed {
        didSet {
            UserDefaults.standard.set(animationSpeed.rawValue, forKey: Keys.animationSpeed)
        }
    }

    @Published var isOfflineModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isOfflineModeEnabled, forKey: Keys.offlineMode)
        }
    }

    @Published var autoSaveProblems: Bool {
        didSet {
            UserDefaults.standard.set(autoSaveProblems, forKey: Keys.autoSave)
        }
    }

    @Published var privacyMode: PrivacyMode {
        didSet {
            UserDefaults.standard.set(privacyMode.rawValue, forKey: Keys.privacyMode)
        }
    }

    @Published var showNotifications: Bool {
        didSet {
            UserDefaults.standard.set(showNotifications, forKey: Keys.notifications)
        }
    }

    @Published var dailyReminderTime: Date {
        didSet {
            UserDefaults.standard.set(dailyReminderTime, forKey: Keys.reminderTime)
        }
    }

    @Published var showStepByStepByDefault: Bool {
        didSet {
            UserDefaults.standard.set(showStepByStepByDefault, forKey: Keys.stepByStepDefault)
        }
    }

    @Published var preferredExportFormat: ExportFormat {
        didSet {
            UserDefaults.standard.set(preferredExportFormat.rawValue, forKey: Keys.exportFormat)
        }
    }

    // MARK: - Computed Properties

    var colorScheme: ColorScheme? {
        if useSystemAppearance {
            return nil
        }
        return isDarkMode ? .dark : .light
    }

    var effectiveTextSize: CGFloat {
        let baseSize: CGFloat = useLargeText ? 20 : 16
        return baseSize * textSizeMultiplier
    }

    // MARK: - Keys

    private enum Keys {
        static let language = "selectedLanguage"
        static let darkMode = "isDarkMode"
        static let systemAppearance = "useSystemAppearance"
        static let voiceGuidance = "isVoiceGuidanceEnabled"
        static let largeText = "useLargeText"
        static let textSizeMultiplier = "textSizeMultiplier"
        static let hapticFeedback = "isHapticFeedbackEnabled"
        static let animationSpeed = "animationSpeed"
        static let offlineMode = "isOfflineModeEnabled"
        static let autoSave = "autoSaveProblems"
        static let privacyMode = "privacyMode"
        static let notifications = "showNotifications"
        static let reminderTime = "dailyReminderTime"
        static let stepByStepDefault = "showStepByStepByDefault"
        static let exportFormat = "preferredExportFormat"
    }

    // MARK: - Initialization

    init() {
        let defaults = UserDefaults.standard

        // Load saved settings or use defaults
        if let languageCode = defaults.string(forKey: Keys.language),
           let language = SupportedLanguage(rawValue: languageCode) {
            self.selectedLanguage = language
        } else {
            self.selectedLanguage = .english
        }

        self.isDarkMode = defaults.bool(forKey: Keys.darkMode)
        self.useSystemAppearance = defaults.object(forKey: Keys.systemAppearance) as? Bool ?? true
        self.isVoiceGuidanceEnabled = defaults.bool(forKey: Keys.voiceGuidance)
        self.useLargeText = defaults.bool(forKey: Keys.largeText)
        self.textSizeMultiplier = defaults.object(forKey: Keys.textSizeMultiplier) as? Double ?? 1.0
        self.isHapticFeedbackEnabled = defaults.object(forKey: Keys.hapticFeedback) as? Bool ?? true
        self.animationSpeed = AnimationSpeed(rawValue: defaults.string(forKey: Keys.animationSpeed) ?? "") ?? .normal
        self.isOfflineModeEnabled = defaults.bool(forKey: Keys.offlineMode)
        self.autoSaveProblems = defaults.object(forKey: Keys.autoSave) as? Bool ?? true
        self.privacyMode = PrivacyMode(rawValue: defaults.string(forKey: Keys.privacyMode) ?? "") ?? .standard
        self.showNotifications = defaults.object(forKey: Keys.notifications) as? Bool ?? true
        self.dailyReminderTime = defaults.object(forKey: Keys.reminderTime) as? Date ?? Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
        self.showStepByStepByDefault = defaults.object(forKey: Keys.stepByStepDefault) as? Bool ?? true
        self.preferredExportFormat = ExportFormat(rawValue: defaults.string(forKey: Keys.exportFormat) ?? "") ?? .pdf
    }

    // MARK: - Methods

    func resetToDefaults() {
        selectedLanguage = .english
        isDarkMode = false
        useSystemAppearance = true
        isVoiceGuidanceEnabled = false
        useLargeText = false
        textSizeMultiplier = 1.0
        isHapticFeedbackEnabled = true
        animationSpeed = .normal
        isOfflineModeEnabled = false
        autoSaveProblems = true
        privacyMode = .standard
        showNotifications = true
        dailyReminderTime = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
        showStepByStepByDefault = true
        preferredExportFormat = .pdf
    }

    func triggerHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isHapticFeedbackEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    func triggerSuccessHaptic() {
        guard isHapticFeedbackEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Supporting Enums

enum AnimationSpeed: String, CaseIterable, Identifiable {
    case slow
    case normal
    case fast

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .slow: return String(localized: "Slow")
        case .normal: return String(localized: "Normal")
        case .fast: return String(localized: "Fast")
        }
    }

    var duration: Double {
        switch self {
        case .slow: return 1.5
        case .normal: return 1.0
        case .fast: return 0.5
        }
    }

    var solutionAnimationDuration: Double {
        switch self {
        case .slow: return 12.0
        case .normal: return 8.0
        case .fast: return 4.0
        }
    }
}

enum PrivacyMode: String, CaseIterable, Identifiable {
    case minimal
    case standard
    case maximum

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .minimal: return String(localized: "Minimal")
        case .standard: return String(localized: "Standard")
        case .maximum: return String(localized: "Maximum Privacy")
        }
    }

    var description: String {
        switch self {
        case .minimal:
            return String(localized: "Basic analytics for app improvement")
        case .standard:
            return String(localized: "No personal data uploaded, local processing when possible")
        case .maximum:
            return String(localized: "Full offline mode, no data leaves your device")
        }
    }

    var allowsCloudProcessing: Bool {
        self != .maximum
    }

    var allowsAnalytics: Bool {
        self == .minimal
    }
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case pdf
    case image
    case markdown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .image: return String(localized: "Image")
        case .markdown: return "Markdown"
        }
    }

    var icon: String {
        switch self {
        case .pdf: return "doc.fill"
        case .image: return "photo.fill"
        case .markdown: return "doc.plaintext.fill"
        }
    }

    var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .image: return "png"
        case .markdown: return "md"
        }
    }
}
