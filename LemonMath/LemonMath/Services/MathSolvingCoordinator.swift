//
//  MathSolvingCoordinator.swift
//  LemonMath
//
//  Orchestrates the complete math solving pipeline:
//  Image -> Gemini Solution -> Claude Verification -> Reconciliation -> MathProblem
//

import Foundation
import UIKit

// MARK: - Math Solving Coordinator

class MathSolvingCoordinator {
    static let shared = MathSolvingCoordinator()

    private let geminiService = GeminiService.shared
    private let reconciliationEngine = ReconciliationEngine.shared

    // MARK: - Public Methods

    /// Complete solving pipeline with verification
    @MainActor
    func solveMathProblem(
        image: UIImage,
        language: SupportedLanguage = .english,
        options: SolveOptions = .default
    ) async throws -> MathProblem {
        // Step 1: Solve with Gemini
        let geminiResult = try await geminiService.solveMathProblem(
            image: image,
            language: language,
            options: options
        )

        // Step 2: Check if verification is enabled and Claude is configured
        let verificationEnabled = UserDefaults.standard.bool(forKey: "verificationEnabled")
        let claudeConfigured = ClaudeVerificationService.shared.isConfigured

        if verificationEnabled && claudeConfigured {
            // Step 3: Verify and reconcile with Claude
            do {
                let reconciled = try await reconciliationEngine.reconcile(
                    problem: geminiResult.recognizedText,
                    geminiResult: geminiResult
                )

                // Step 4: Convert reconciled solution to MathProblem
                return reconciled.toMathProblem(
                    originalImage: image,
                    geminiResult: geminiResult,
                    language: language
                )
            } catch {
                // If Claude verification fails, fall back to Gemini-only
                print("Verification failed: \(error.localizedDescription). Using Gemini result.")
                return geminiResult.toMathProblem(
                    originalImage: image,
                    language: language
                )
            }
        } else {
            // Verification disabled or Claude not configured - use Gemini only
            return geminiResult.toMathProblem(
                originalImage: image,
                language: language
            )
        }
    }

    /// Solve without verification (faster, Gemini only)
    @MainActor
    func solveMathProblemFast(
        image: UIImage,
        language: SupportedLanguage = .english,
        options: SolveOptions = .default
    ) async throws -> MathProblem {
        let geminiResult = try await geminiService.solveMathProblem(
            image: image,
            language: language,
            options: options
        )

        return geminiResult.toMathProblem(
            originalImage: image,
            language: language
        )
    }
}

// Note: SolveOptions is defined in NanoBananaProService.swift
