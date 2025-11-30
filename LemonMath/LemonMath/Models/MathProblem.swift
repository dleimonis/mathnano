//
//  MathProblem.swift
//  LemonMath
//

import Foundation
import SwiftUI

// MARK: - Math Problem Model
struct MathProblem: Identifiable, Codable, Equatable {
    let id: UUID
    let originalImageData: Data?
    let problemText: String
    let problemType: ProblemType
    let solvedImageData: Data?
    let solution: String
    let steps: [SolutionStep]
    let alternativeMethods: [AlternativeMethod]
    let realWorldExamples: [RealWorldExample]
    let graphData: GraphData?
    let createdAt: Date
    let language: SupportedLanguage
    var isFavorite: Bool
    var userNotes: String?
    var sharedCount: Int

    init(
        id: UUID = UUID(),
        originalImageData: Data? = nil,
        problemText: String,
        problemType: ProblemType,
        solvedImageData: Data? = nil,
        solution: String,
        steps: [SolutionStep] = [],
        alternativeMethods: [AlternativeMethod] = [],
        realWorldExamples: [RealWorldExample] = [],
        graphData: GraphData? = nil,
        createdAt: Date = Date(),
        language: SupportedLanguage = .english,
        isFavorite: Bool = false,
        userNotes: String? = nil,
        sharedCount: Int = 0
    ) {
        self.id = id
        self.originalImageData = originalImageData
        self.problemText = problemText
        self.problemType = problemType
        self.solvedImageData = solvedImageData
        self.solution = solution
        self.steps = steps
        self.alternativeMethods = alternativeMethods
        self.realWorldExamples = realWorldExamples
        self.graphData = graphData
        self.createdAt = createdAt
        self.language = language
        self.isFavorite = isFavorite
        self.userNotes = userNotes
        self.sharedCount = sharedCount
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    var originalImage: UIImage? {
        guard let data = originalImageData else { return nil }
        return UIImage(data: data)
    }

    var solvedImage: UIImage? {
        guard let data = solvedImageData else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - Problem Type
enum ProblemType: String, Codable, CaseIterable {
    case algebra
    case geometry
    case calculus
    case trigonometry
    case statistics
    case linearAlgebra
    case numberTheory
    case arithmetic
    case unknown

    var displayName: String {
        switch self {
        case .algebra: return String(localized: "Algebra")
        case .geometry: return String(localized: "Geometry")
        case .calculus: return String(localized: "Calculus")
        case .trigonometry: return String(localized: "Trigonometry")
        case .statistics: return String(localized: "Statistics")
        case .linearAlgebra: return String(localized: "Linear Algebra")
        case .numberTheory: return String(localized: "Number Theory")
        case .arithmetic: return String(localized: "Arithmetic")
        case .unknown: return String(localized: "Math")
        }
    }

    var icon: String {
        switch self {
        case .algebra: return "x.squareroot"
        case .geometry: return "triangle"
        case .calculus: return "function"
        case .trigonometry: return "angle"
        case .statistics: return "chart.bar"
        case .linearAlgebra: return "square.grid.3x3"
        case .numberTheory: return "number"
        case .arithmetic: return "plus.forwardslash.minus"
        case .unknown: return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .algebra: return LemonMathColors.algebraColor
        case .geometry: return LemonMathColors.geometryColor
        case .calculus: return LemonMathColors.calculusColor
        case .trigonometry: return LemonMathColors.trigColor
        case .statistics: return LemonMathColors.statsColor
        case .linearAlgebra: return LemonMathColors.linearAlgebraColor
        case .numberTheory: return LemonMathColors.numberTheoryColor
        case .arithmetic: return LemonMathColors.arithmeticColor
        case .unknown: return LemonMathColors.accent
        }
    }
}

// MARK: - Solution Step
struct SolutionStep: Identifiable, Codable, Equatable {
    let id: UUID
    let stepNumber: Int
    let title: String
    let explanation: String
    let mathExpression: String
    let hint: String?
    let conceptUsed: String?

    init(
        id: UUID = UUID(),
        stepNumber: Int,
        title: String,
        explanation: String,
        mathExpression: String,
        hint: String? = nil,
        conceptUsed: String? = nil
    ) {
        self.id = id
        self.stepNumber = stepNumber
        self.title = title
        self.explanation = explanation
        self.mathExpression = mathExpression
        self.hint = hint
        self.conceptUsed = conceptUsed
    }
}

// MARK: - Alternative Method
struct AlternativeMethod: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let description: String
    let steps: [SolutionStep]
    let difficulty: Difficulty

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        steps: [SolutionStep],
        difficulty: Difficulty
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.steps = steps
        self.difficulty = difficulty
    }

    enum Difficulty: String, Codable {
        case beginner
        case intermediate
        case advanced

        var displayName: String {
            switch self {
            case .beginner: return String(localized: "Beginner")
            case .intermediate: return String(localized: "Intermediate")
            case .advanced: return String(localized: "Advanced")
            }
        }

        var color: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .orange
            case .advanced: return .red
            }
        }
    }
}

// MARK: - Real World Example
struct RealWorldExample: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let scenario: String
    let application: String
    let icon: String

    init(
        id: UUID = UUID(),
        title: String,
        scenario: String,
        application: String,
        icon: String = "lightbulb"
    ) {
        self.id = id
        self.title = title
        self.scenario = scenario
        self.application = application
        self.icon = icon
    }
}

// MARK: - Graph Data
struct GraphData: Codable, Equatable {
    let type: GraphType
    let points: [GraphPoint]
    let xAxisLabel: String
    let yAxisLabel: String
    let title: String

    enum GraphType: String, Codable {
        case line
        case scatter
        case bar
        case area
    }
}

struct GraphPoint: Codable, Equatable {
    let x: Double
    let y: Double
    let label: String?

    init(x: Double, y: Double, label: String? = nil) {
        self.x = x
        self.y = y
        self.label = label
    }
}

// MARK: - Supported Languages
enum SupportedLanguage: String, Codable, CaseIterable, Identifiable {
    case english = "en"
    case greek = "el"

    var id: String { rawValue }

    var code: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .greek: return "Ελληνικά"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .greek: return "🇬🇷"
        }
    }
}
