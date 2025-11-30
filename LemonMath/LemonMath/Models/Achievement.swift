//
//  Achievement.swift
//  LemonMath
//

import Foundation
import SwiftUI

// MARK: - Achievement Model
struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let requirement: Int
    var progress: Int
    var isUnlocked: Bool
    var unlockedAt: Date?

    var progressPercentage: Double {
        min(Double(progress) / Double(requirement), 1.0)
    }

    var isComplete: Bool {
        progress >= requirement
    }

    static func == (lhs: Achievement, rhs: Achievement) -> Bool {
        lhs.id == rhs.id
    }
}

enum AchievementCategory: String, Codable, CaseIterable {
    case problemsSolved
    case streaks
    case sharing
    case exploration
    case mastery

    var displayName: String {
        switch self {
        case .problemsSolved: return String(localized: "Problem Solver")
        case .streaks: return String(localized: "Consistency")
        case .sharing: return String(localized: "Social")
        case .exploration: return String(localized: "Explorer")
        case .mastery: return String(localized: "Mastery")
        }
    }

    var color: Color {
        switch self {
        case .problemsSolved: return LemonMathColors.accent
        case .streaks: return .orange
        case .sharing: return .pink
        case .exploration: return .purple
        case .mastery: return .yellow
        }
    }
}

// MARK: - Default Achievements
extension Achievement {
    static let allAchievements: [Achievement] = [
        // Problems Solved
        Achievement(
            id: "first_problem",
            title: String(localized: "First Steps"),
            description: String(localized: "Solve your first math problem"),
            icon: "star.fill",
            category: .problemsSolved,
            requirement: 1,
            progress: 0,
            isUnlocked: false
        ),
        Achievement(
            id: "problem_solver_10",
            title: String(localized: "Getting Started"),
            description: String(localized: "Solve 10 math problems"),
            icon: "flame.fill",
            category: .problemsSolved,
            requirement: 10,
            progress: 0,
            isUnlocked: false
        ),
        Achievement(
            id: "problem_solver_50",
            title: String(localized: "Math Enthusiast"),
            description: String(localized: "Solve 50 math problems"),
            icon: "bolt.fill",
            category: .problemsSolved,
            requirement: 50,
            progress: 0,
            isUnlocked: false
        ),
        Achievement(
            id: "problem_solver_100",
            title: String(localized: "Math Wizard"),
            description: String(localized: "Solve 100 math problems"),
            icon: "wand.and.stars",
            category: .problemsSolved,
            requirement: 100,
            progress: 0,
            isUnlocked: false
        ),
        Achievement(
            id: "problem_solver_500",
            title: String(localized: "Math Master"),
            description: String(localized: "Solve 500 math problems"),
            icon: "crown.fill",
            category: .problemsSolved,
            requirement: 500,
            progress: 0,
            isUnlocked: false
        ),

        // Streaks
        Achievement(
            id: "streak_3",
            title: String(localized: "On a Roll"),
            description: String(localized: "Use the app 3 days in a row"),
            icon: "flame",
            category: .streaks,
            requirement: 3,
            progress: 0,
            isUnlocked: false
        ),
        Achievement(
            id: "streak_7",
            title: String(localized: "Week Warrior"),
            description: String(localized: "Use the app 7 days in a row"),
            icon: "calendar",
            category: .streaks,
            requirement: 7,
            progress: 0,
            isUnlocked: false
        ),
        Achievement(
            id: "streak_30",
            title: String(localized: "Monthly Maven"),
            description: String(localized: "Use the app 30 days in a row"),
            icon: "calendar.badge.checkmark",
            category: .streaks,
            requirement: 30,
            progress: 0,
            isUnlocked: false
        ),

        // Sharing
        Achievement(
            id: "first_share",
            title: String(localized: "Sharing is Caring"),
            description: String(localized: "Share your first solution"),
            icon: "square.and.arrow.up",
            category: .sharing,
            requirement: 1,
            progress: 0,
            isUnlocked: false
        ),
        Achievement(
            id: "share_10",
            title: String(localized: "Social Butterfly"),
            description: String(localized: "Share 10 solutions"),
            icon: "paperplane.fill",
            category: .sharing,
            requirement: 10,
            progress: 0,
            isUnlocked: false
        ),

        // Exploration
        Achievement(
            id: "try_all_types",
            title: String(localized: "Explorer"),
            description: String(localized: "Solve problems from all math categories"),
            icon: "map.fill",
            category: .exploration,
            requirement: 8,
            progress: 0,
            isUnlocked: false
        ),
        Achievement(
            id: "multi_language",
            title: String(localized: "Polyglot"),
            description: String(localized: "Use the app in multiple languages"),
            icon: "globe",
            category: .exploration,
            requirement: 2,
            progress: 0,
            isUnlocked: false
        ),

        // Mastery
        Achievement(
            id: "algebra_master",
            title: String(localized: "Algebra Ace"),
            description: String(localized: "Solve 25 algebra problems"),
            icon: "x.squareroot",
            category: .mastery,
            requirement: 25,
            progress: 0,
            isUnlocked: false
        ),
        Achievement(
            id: "calculus_master",
            title: String(localized: "Calculus Champion"),
            description: String(localized: "Solve 25 calculus problems"),
            icon: "function",
            category: .mastery,
            requirement: 25,
            progress: 0,
            isUnlocked: false
        ),
        Achievement(
            id: "geometry_master",
            title: String(localized: "Geometry Genius"),
            description: String(localized: "Solve 25 geometry problems"),
            icon: "triangle.fill",
            category: .mastery,
            requirement: 25,
            progress: 0,
            isUnlocked: false
        ),
    ]
}

// MARK: - Challenge Model
struct FriendChallenge: Identifiable, Codable {
    let id: UUID
    let challengerName: String
    let problem: MathProblem
    let createdAt: Date
    var isCompleted: Bool
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        challengerName: String,
        problem: MathProblem,
        createdAt: Date = Date(),
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.challengerName = challengerName
        self.problem = problem
        self.createdAt = createdAt
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}
