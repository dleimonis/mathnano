//
//  ReconciliationEngine.swift
//  LemonMath
//
//  Engine for reconciling solutions from multiple LLMs (Gemini + Claude)
//

import Foundation

// MARK: - Reconciliation Engine

class ReconciliationEngine {
    static let shared = ReconciliationEngine()

    private let claudeService = ClaudeVerificationService.shared
    private let settings: VerificationSettings

    init() {
        // Load settings from UserDefaults or use default
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "verificationSettings"),
           let saved = try? decoder.decode(VerificationSettings.self, from: data) {
            self.settings = saved
        } else {
            self.settings = .default
        }
    }

    // MARK: - Public Methods

    /// Reconcile Gemini solution with Claude verification
    @MainActor
    func reconcile(
        problem: String,
        geminiResult: MathSolutionResponse
    ) async throws -> ReconciledSolution {
        // Check if verification is enabled
        guard settings.enabled else {
            return createUnverifiedSolution(from: geminiResult)
        }

        // Check if Claude API is configured
        guard claudeService.isConfigured else {
            return createUnverifiedSolution(from: geminiResult)
        }

        // Step 1: Verify Gemini's solution with Claude
        let (verification, independentSolution) = try await claudeService.verifyWithComparison(
            problem: problem,
            geminiSolution: geminiResult
        )

        // Step 2: Analyze verification result
        if verification.isCorrect && verification.confidence >= 0.8 {
            // Gemini solution is correct and verified
            return ReconciledSolution(
                finalAnswer: geminiResult.solution,
                confidence: min(geminiResult.confidence, verification.confidence),
                primarySource: .gemini,
                verificationStatus: .verified,
                discrepancies: nil,
                steps: convertToSolutionSteps(geminiResult.steps),
                reconciliationNotes: "Solution verified by Claude \(settings.defaultModel.rawValue)"
            )
        }

        // Step 3: Handle disagreement
        if let claudeSolution = independentSolution {
            return try await handleDisagreement(
                problem: problem,
                geminiResult: geminiResult,
                claudeResult: claudeSolution,
                verification: verification
            )
        }

        // Step 4: Low confidence but no alternative - return with warning
        return ReconciledSolution(
            finalAnswer: geminiResult.solution,
            confidence: verification.confidence,
            primarySource: .gemini,
            verificationStatus: .needsReview,
            discrepancies: verification.errors?.map { error in
                Discrepancy(
                    type: .finalAnswer,
                    geminiValue: geminiResult.solution,
                    claudeValue: "unknown",
                    description: error,
                    severity: .major
                )
            },
            steps: convertToSolutionSteps(geminiResult.steps),
            reconciliationNotes: "Verification incomplete. Confidence: \(verification.confidence)"
        )
    }

    // MARK: - Private Methods

    private func createUnverifiedSolution(from gemini: MathSolutionResponse) -> ReconciledSolution {
        return ReconciledSolution(
            finalAnswer: gemini.solution,
            confidence: gemini.confidence,
            primarySource: .gemini,
            verificationStatus: .notVerified,
            discrepancies: nil,
            steps: convertToSolutionSteps(gemini.steps),
            reconciliationNotes: "Verification disabled or Claude API not configured"
        )
    }

    private func handleDisagreement(
        problem: String,
        geminiResult: MathSolutionResponse,
        claudeResult: MathSolutionResponse,
        verification: VerificationResult
    ) async throws -> ReconciledSolution {
        // Compare solutions
        let discrepancies = identifyDiscrepancies(
            gemini: geminiResult,
            claude: claudeResult
        )

        // Determine severity
        let hasCriticalDiscrepancy = discrepancies.contains { $0.severity == .critical }

        if hasCriticalDiscrepancy {
            // Solutions differ significantly - check if we should escalate to Opus
            if settings.escalateToOpus && settings.defaultModel == .sonnet {
                return try await escalateToOpus(
                    problem: problem,
                    geminiResult: geminiResult,
                    claudeResult: claudeResult,
                    discrepancies: discrepancies
                )
            }

            // Return disputed solution with both options
            return ReconciledSolution(
                finalAnswer: selectBestSolution(
                    gemini: geminiResult,
                    claude: claudeResult,
                    verification: verification
                ),
                confidence: 0.5,  // Low confidence due to disagreement
                primarySource: claudeResult.confidence > geminiResult.confidence ? .claude : .gemini,
                verificationStatus: .disputed,
                discrepancies: discrepancies,
                steps: claudeResult.confidence > geminiResult.confidence ?
                    convertToSolutionSteps(claudeResult.steps) :
                    convertToSolutionSteps(geminiResult.steps),
                reconciliationNotes: """
                    Models disagree on the solution.
                    Gemini: \(geminiResult.solution) (confidence: \(geminiResult.confidence))
                    Claude: \(claudeResult.solution) (confidence: \(claudeResult.confidence))
                    """
            )
        }

        // Minor discrepancies - use higher confidence solution
        let useClaude = claudeResult.confidence > geminiResult.confidence
        return ReconciledSolution(
            finalAnswer: useClaude ? claudeResult.solution : geminiResult.solution,
            confidence: useClaude ? claudeResult.confidence : geminiResult.confidence,
            primarySource: useClaude ? .claude : .gemini,
            verificationStatus: .reconciled,
            discrepancies: discrepancies,
            steps: useClaude ?
                convertToSolutionSteps(claudeResult.steps) :
                convertToSolutionSteps(geminiResult.steps),
            reconciliationNotes: "Minor differences resolved in favor of higher confidence solution"
        )
    }

    private func escalateToOpus(
        problem: String,
        geminiResult: MathSolutionResponse,
        claudeResult: MathSolutionResponse,
        discrepancies: [Discrepancy]
    ) async throws -> ReconciledSolution {
        // Get Opus opinion as tiebreaker
        let opusSolution = try await claudeService.solveProblemIndependently(
            problem: problem,
            problemType: geminiResult.problemType,
            useOpus: true
        )

        // Compare Opus with both solutions
        let opusMatchesGemini = normalizeSolution(opusSolution.solution) == normalizeSolution(geminiResult.solution)
        let opusMatchesClaude = normalizeSolution(opusSolution.solution) == normalizeSolution(claudeResult.solution)

        if opusMatchesGemini {
            return ReconciledSolution(
                finalAnswer: geminiResult.solution,
                confidence: (geminiResult.confidence + opusSolution.confidence) / 2,
                primarySource: .gemini,
                verificationStatus: .reconciled,
                discrepancies: discrepancies,
                steps: convertToSolutionSteps(geminiResult.steps),
                reconciliationNotes: "Opus confirmed Gemini's solution"
            )
        } else if opusMatchesClaude {
            return ReconciledSolution(
                finalAnswer: claudeResult.solution,
                confidence: (claudeResult.confidence + opusSolution.confidence) / 2,
                primarySource: .claude,
                verificationStatus: .reconciled,
                discrepancies: discrepancies,
                steps: convertToSolutionSteps(claudeResult.steps),
                reconciliationNotes: "Opus confirmed Claude's solution"
            )
        } else {
            // Opus has a third different answer - use Opus as highest authority
            return ReconciledSolution(
                finalAnswer: opusSolution.solution,
                confidence: opusSolution.confidence,
                primarySource: .claude,
                verificationStatus: .reconciled,
                discrepancies: discrepancies,
                steps: convertToSolutionSteps(opusSolution.steps),
                reconciliationNotes: "Three-way disagreement resolved by Opus"
            )
        }
    }

    private func identifyDiscrepancies(
        gemini: MathSolutionResponse,
        claude: MathSolutionResponse
    ) -> [Discrepancy] {
        var discrepancies: [Discrepancy] = []

        // Check final answer
        if normalizeSolution(gemini.solution) != normalizeSolution(claude.solution) {
            discrepancies.append(
                Discrepancy(
                    type: .finalAnswer,
                    geminiValue: gemini.solution,
                    claudeValue: claude.solution,
                    description: "Final answers differ",
                    severity: .critical
                )
            )
        }

        // Check problem interpretation
        if gemini.recognizedText != claude.recognizedText {
            discrepancies.append(
                Discrepancy(
                    type: .interpretation,
                    geminiValue: gemini.recognizedText,
                    claudeValue: claude.recognizedText,
                    description: "Different problem interpretations",
                    severity: .major
                )
            )
        }

        // Check number of steps (methodology difference)
        if abs(gemini.steps.count - claude.steps.count) > 2 {
            discrepancies.append(
                Discrepancy(
                    type: .methodApproach,
                    geminiValue: "\(gemini.steps.count) steps",
                    claudeValue: "\(claude.steps.count) steps",
                    description: "Significantly different solution approaches",
                    severity: .minor
                )
            )
        }

        return discrepancies
    }

    private func selectBestSolution(
        gemini: MathSolutionResponse,
        claude: MathSolutionResponse,
        verification: VerificationResult
    ) -> String {
        // If verification explicitly says Gemini is wrong and provides alternative
        if !verification.isCorrect, let alternative = verification.alternativeSolution {
            return alternative
        }

        // Otherwise, use higher confidence
        return claude.confidence > gemini.confidence ? claude.solution : gemini.solution
    }

    private func normalizeSolution(_ solution: String) -> String {
        // Normalize solution for comparison (remove whitespace, convert fractions to decimals, etc.)
        let cleaned = solution
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "x=", with: "")
            .replacingOccurrences(of: "y=", with: "")

        // Try to convert fractions to decimals for comparison
        if cleaned.contains("/") {
            let parts = cleaned.components(separatedBy: "/")
            if parts.count == 2,
               let num = Double(parts[0]),
               let den = Double(parts[1]),
               den != 0 {
                return String(format: "%.4f", num / den)
            }
        }

        return cleaned
    }

    private func convertToSolutionSteps(_ steps: [StepResponse]) -> [SolutionStep] {
        return steps.map { step in
            SolutionStep(
                stepNumber: step.stepNumber,
                title: step.title,
                explanation: step.explanation,
                mathExpression: step.mathExpression,
                hint: step.hint,
                conceptUsed: step.conceptUsed
            )
        }
    }

    // MARK: - Settings Management

    func updateSettings(_ newSettings: VerificationSettings) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(newSettings) {
            UserDefaults.standard.set(encoded, forKey: "verificationSettings")
        }
    }

    func getSettings() -> VerificationSettings {
        return settings
    }
}
