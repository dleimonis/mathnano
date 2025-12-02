//
//  VerificationModels.swift
//  LemonMath
//
//  Models for multi-LLM solution verification and reconciliation
//

import Foundation

// MARK: - Verification Status

enum VerificationStatus: String, Codable {
    case verified        // Both models agree
    case reconciled      // Disagreed but resolved
    case disputed        // Unresolved difference
    case needsReview     // Flagged for human review
    case notVerified     // Verification not performed
}

// MARK: - Solution Source

enum SolutionSource: String, Codable {
    case gemini
    case claude
    case human
}

// MARK: - Verification Result

struct VerificationResult: Codable {
    let isCorrect: Bool
    let confidence: Double
    let errors: [String]?
    let alternativeSolution: String?
    let verificationNotes: String?
    let verifiedBy: SolutionSource

    init(
        isCorrect: Bool,
        confidence: Double,
        errors: [String]? = nil,
        alternativeSolution: String? = nil,
        verificationNotes: String? = nil,
        verifiedBy: SolutionSource = .claude
    ) {
        self.isCorrect = isCorrect
        self.confidence = confidence
        self.errors = errors
        self.alternativeSolution = alternativeSolution
        self.verificationNotes = verificationNotes
        self.verifiedBy = verifiedBy
    }
}

// MARK: - Reconciled Solution

struct ReconciledSolution: Codable {
    let finalAnswer: String
    let confidence: Double
    let primarySource: SolutionSource
    let verificationStatus: VerificationStatus
    let discrepancies: [Discrepancy]?
    let steps: [SolutionStep]
    let reconciliationNotes: String?

    init(
        finalAnswer: String,
        confidence: Double,
        primarySource: SolutionSource,
        verificationStatus: VerificationStatus,
        discrepancies: [Discrepancy]? = nil,
        steps: [SolutionStep],
        reconciliationNotes: String? = nil
    ) {
        self.finalAnswer = finalAnswer
        self.confidence = confidence
        self.primarySource = primarySource
        self.verificationStatus = verificationStatus
        self.discrepancies = discrepancies
        self.steps = steps
        self.reconciliationNotes = reconciliationNotes
    }
}

// MARK: - Discrepancy

struct Discrepancy: Codable, Identifiable {
    let id: String
    let type: DiscrepancyType
    let geminiValue: String
    let claudeValue: String
    let description: String
    let severity: DiscrepancySeverity

    init(
        id: String = UUID().uuidString,
        type: DiscrepancyType,
        geminiValue: String,
        claudeValue: String,
        description: String,
        severity: DiscrepancySeverity
    ) {
        self.id = id
        self.type = type
        self.geminiValue = geminiValue
        self.claudeValue = claudeValue
        self.description = description
        self.severity = severity
    }
}

enum DiscrepancyType: String, Codable {
    case finalAnswer
    case intermediateStep
    case methodApproach
    case interpretation
}

enum DiscrepancySeverity: String, Codable {
    case critical       // Final answer differs
    case major          // Methodology differs significantly
    case minor          // Different approach, same result
    case trivial        // Formatting/notation differences
}

// Note: SolutionStep is defined in MathProblem.swift

// MARK: - Alternative Solution

struct AlternativeSolution: Codable, Identifiable {
    let id: String
    let source: SolutionSource
    let answer: String
    let confidence: Double
    let steps: [SolutionStep]
    let methodName: String?

    init(
        id: String = UUID().uuidString,
        source: SolutionSource,
        answer: String,
        confidence: Double,
        steps: [SolutionStep],
        methodName: String? = nil
    ) {
        self.id = id
        self.source = source
        self.answer = answer
        self.confidence = confidence
        self.steps = steps
        self.methodName = methodName
    }
}

// MARK: - Verification Settings

struct VerificationSettings: Codable {
    var enabled: Bool
    var defaultModel: ClaudeModel
    var escalateToOpus: Bool
    var escalationThreshold: Double
    var autoReconcile: Bool

    init(
        enabled: Bool = true,
        defaultModel: ClaudeModel = .sonnet,
        escalateToOpus: Bool = true,
        escalationThreshold: Double = 0.3,  // Escalate if confidence difference > 0.3
        autoReconcile: Bool = true
    ) {
        self.enabled = enabled
        self.defaultModel = defaultModel
        self.escalateToOpus = escalateToOpus
        self.escalationThreshold = escalationThreshold
        self.autoReconcile = autoReconcile
    }

    static let `default` = VerificationSettings()
}

// MARK: - Claude Model Selection

enum ClaudeModel: String, Codable {
    case sonnet = "claude-sonnet-4-5-20250514"
    case opus = "claude-opus-4-20250514"

    var costPer1MInputTokens: Double {
        switch self {
        case .sonnet: return 3.0
        case .opus: return 15.0
        }
    }

    var costPer1MOutputTokens: Double {
        switch self {
        case .sonnet: return 15.0
        case .opus: return 75.0
        }
    }

    var displayName: String {
        switch self {
        case .sonnet: return "Claude Sonnet 4.5 (Faster, cheaper)"
        case .opus: return "Claude Opus 4 (Most accurate)"
        }
    }
}
