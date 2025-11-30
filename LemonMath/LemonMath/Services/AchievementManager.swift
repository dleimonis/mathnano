//
//  AchievementManager.swift
//  LemonMath
//

import Foundation
import SwiftUI
import Combine

// MARK: - Achievement Manager
@MainActor
class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var recentlyUnlocked: Achievement?

    private let storageKey = "achievements"
    private var problemTypesSolved: Set<ProblemType> = []
    private var languagesUsed: Set<SupportedLanguage> = []

    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    var totalCount: Int {
        achievements.count
    }

    var progressPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }

    var achievementsByCategory: [AchievementCategory: [Achievement]] {
        Dictionary(grouping: achievements, by: { $0.category })
    }

    // MARK: - Initialization

    init() {
        loadAchievements()
        loadTrackedData()
    }

    // MARK: - Public Methods

    func recordProblemSolved(type: ProblemType, language: SupportedLanguage) {
        // Track problem type for explorer achievement
        problemTypesSolved.insert(type)
        saveTrackedData()

        // Update problems solved achievements
        updateProgress(for: "first_problem", increment: 1)
        updateProgress(for: "problem_solver_10", increment: 1)
        updateProgress(for: "problem_solver_50", increment: 1)
        updateProgress(for: "problem_solver_100", increment: 1)
        updateProgress(for: "problem_solver_500", increment: 1)

        // Update category mastery achievements
        switch type {
        case .algebra:
            updateProgress(for: "algebra_master", increment: 1)
        case .calculus:
            updateProgress(for: "calculus_master", increment: 1)
        case .geometry:
            updateProgress(for: "geometry_master", increment: 1)
        default:
            break
        }

        // Update explorer achievement
        updateProgress(for: "try_all_types", setValue: problemTypesSolved.count)

        // Track language usage
        languagesUsed.insert(language)
        saveTrackedData()
        updateProgress(for: "multi_language", setValue: languagesUsed.count)

        saveAchievements()
    }

    func recordShare() {
        updateProgress(for: "first_share", increment: 1)
        updateProgress(for: "share_10", increment: 1)
        saveAchievements()
    }

    func recordDailyUsage() {
        // This should be called once per day
        let streakKey = "currentStreak"
        let lastUseDateKey = "lastUseDate"

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastUseDateData = UserDefaults.standard.object(forKey: lastUseDateKey) as? Date {
            let lastUseDate = calendar.startOfDay(for: lastUseDateData)

            if lastUseDate == today {
                // Already recorded today
                return
            }

            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if lastUseDate == yesterday {
                // Continue streak
                let currentStreak = UserDefaults.standard.integer(forKey: streakKey) + 1
                UserDefaults.standard.set(currentStreak, forKey: streakKey)
                updateStreakAchievements(streak: currentStreak)
            } else {
                // Streak broken, reset
                UserDefaults.standard.set(1, forKey: streakKey)
                updateStreakAchievements(streak: 1)
            }
        } else {
            // First use
            UserDefaults.standard.set(1, forKey: streakKey)
            updateStreakAchievements(streak: 1)
        }

        UserDefaults.standard.set(today, forKey: lastUseDateKey)
        saveAchievements()
    }

    func getAchievement(by id: String) -> Achievement? {
        achievements.first { $0.id == id }
    }

    func resetAchievements() {
        achievements = Achievement.allAchievements
        problemTypesSolved.removeAll()
        languagesUsed.removeAll()
        UserDefaults.standard.removeObject(forKey: "currentStreak")
        UserDefaults.standard.removeObject(forKey: "lastUseDate")
        saveAchievements()
        saveTrackedData()
    }

    // MARK: - Private Methods

    private func updateProgress(for achievementId: String, increment: Int = 0, setValue: Int? = nil) {
        guard let index = achievements.firstIndex(where: { $0.id == achievementId }) else { return }

        if let value = setValue {
            achievements[index].progress = value
        } else {
            achievements[index].progress += increment
        }

        // Check if newly unlocked
        if achievements[index].isComplete && !achievements[index].isUnlocked {
            achievements[index].isUnlocked = true
            achievements[index].unlockedAt = Date()
            recentlyUnlocked = achievements[index]

            // Haptic feedback for unlock
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    private func updateStreakAchievements(streak: Int) {
        updateProgress(for: "streak_3", setValue: min(streak, 3))
        updateProgress(for: "streak_7", setValue: min(streak, 7))
        updateProgress(for: "streak_30", setValue: min(streak, 30))
    }

    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded

            // Merge with any new achievements that might have been added
            for defaultAchievement in Achievement.allAchievements {
                if !achievements.contains(where: { $0.id == defaultAchievement.id }) {
                    achievements.append(defaultAchievement)
                }
            }
        } else {
            achievements = Achievement.allAchievements
        }
    }

    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadTrackedData() {
        if let typesData = UserDefaults.standard.data(forKey: "problemTypesSolved"),
           let types = try? JSONDecoder().decode(Set<ProblemType>.self, from: typesData) {
            problemTypesSolved = types
        }

        if let languagesData = UserDefaults.standard.data(forKey: "languagesUsed"),
           let languages = try? JSONDecoder().decode(Set<SupportedLanguage>.self, from: languagesData) {
            languagesUsed = languages
        }
    }

    private func saveTrackedData() {
        if let typesData = try? JSONEncoder().encode(problemTypesSolved) {
            UserDefaults.standard.set(typesData, forKey: "problemTypesSolved")
        }

        if let languagesData = try? JSONEncoder().encode(languagesUsed) {
            UserDefaults.standard.set(languagesData, forKey: "languagesUsed")
        }
    }
}
