//
//  OfflineModeManager.swift
//  LemonMath
//

import Foundation
import UIKit
import Vision
import CoreML

// MARK: - Offline Mode Manager
class OfflineModeManager: ObservableObject {
    static let shared = OfflineModeManager()

    @Published var isOffline = false
    @Published var lastOnlineCheck: Date?

    private let basicEquationPatterns: [String: String] = [
        // Simple arithmetic
        #"(\d+)\s*\+\s*(\d+)"#: "addition",
        #"(\d+)\s*-\s*(\d+)"#: "subtraction",
        #"(\d+)\s*[*×]\s*(\d+)"#: "multiplication",
        #"(\d+)\s*[/÷]\s*(\d+)"#: "division",

        // Simple algebra
        #"(\d*)x\s*\+\s*(\d+)\s*=\s*(\d+)"#: "linear_equation",
        #"(\d*)x\s*-\s*(\d+)\s*=\s*(\d+)"#: "linear_equation_minus",
    ]

    private init() {
        checkConnectivity()
    }

    // MARK: - Connectivity

    func checkConnectivity() {
        // In a real app, this would check actual network status
        // For now, we'll simulate it
        lastOnlineCheck = Date()
    }

    // MARK: - Basic OCR (Offline)

    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OfflineError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                continuation.resume(returning: recognizedStrings.joined(separator: " "))
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US", "el-GR"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Basic Equation Solving (Offline)

    func solveBasicEquation(_ equation: String) throws -> BasicSolution {
        let cleanEquation = equation.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to match patterns
        for (pattern, type) in basicEquationPatterns {
            if let result = try? solveWithPattern(cleanEquation, pattern: pattern, type: type) {
                return result
            }
        }

        throw OfflineError.unsupportedEquation
    }

    private func solveWithPattern(_ equation: String, pattern: String, type: String) throws -> BasicSolution {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            throw OfflineError.patternError
        }

        let range = NSRange(equation.startIndex..., in: equation)
        guard let match = regex.firstMatch(in: equation, options: [], range: range) else {
            throw OfflineError.noMatch
        }

        switch type {
        case "addition":
            let num1 = extractNumber(from: equation, match: match, group: 1)
            let num2 = extractNumber(from: equation, match: match, group: 2)
            let result = num1 + num2
            return BasicSolution(
                answer: "\(Int(result))",
                steps: [
                    BasicStep(description: "Add the two numbers", expression: "\(Int(num1)) + \(Int(num2)) = \(Int(result))")
                ],
                type: .arithmetic
            )

        case "subtraction":
            let num1 = extractNumber(from: equation, match: match, group: 1)
            let num2 = extractNumber(from: equation, match: match, group: 2)
            let result = num1 - num2
            return BasicSolution(
                answer: "\(Int(result))",
                steps: [
                    BasicStep(description: "Subtract the second number from the first", expression: "\(Int(num1)) - \(Int(num2)) = \(Int(result))")
                ],
                type: .arithmetic
            )

        case "multiplication":
            let num1 = extractNumber(from: equation, match: match, group: 1)
            let num2 = extractNumber(from: equation, match: match, group: 2)
            let result = num1 * num2
            return BasicSolution(
                answer: "\(Int(result))",
                steps: [
                    BasicStep(description: "Multiply the two numbers", expression: "\(Int(num1)) × \(Int(num2)) = \(Int(result))")
                ],
                type: .arithmetic
            )

        case "division":
            let num1 = extractNumber(from: equation, match: match, group: 1)
            let num2 = extractNumber(from: equation, match: match, group: 2)
            guard num2 != 0 else {
                throw OfflineError.divisionByZero
            }
            let result = num1 / num2
            let isWhole = result.truncatingRemainder(dividingBy: 1) == 0
            return BasicSolution(
                answer: isWhole ? "\(Int(result))" : String(format: "%.2f", result),
                steps: [
                    BasicStep(description: "Divide the first number by the second", expression: "\(Int(num1)) ÷ \(Int(num2)) = \(isWhole ? "\(Int(result))" : String(format: "%.2f", result))")
                ],
                type: .arithmetic
            )

        case "linear_equation":
            let coefficient = match.range(at: 1).location != NSNotFound ? extractNumber(from: equation, match: match, group: 1) : 1
            let constant = extractNumber(from: equation, match: match, group: 2)
            let result = extractNumber(from: equation, match: match, group: 3)
            let x = (result - constant) / coefficient
            return BasicSolution(
                answer: "x = \(Int(x))",
                steps: [
                    BasicStep(description: "Subtract \(Int(constant)) from both sides", expression: "\(Int(coefficient))x = \(Int(result - constant))"),
                    BasicStep(description: "Divide both sides by \(Int(coefficient))", expression: "x = \(Int(x))")
                ],
                type: .algebra
            )

        case "linear_equation_minus":
            let coefficient = match.range(at: 1).location != NSNotFound ? extractNumber(from: equation, match: match, group: 1) : 1
            let constant = extractNumber(from: equation, match: match, group: 2)
            let result = extractNumber(from: equation, match: match, group: 3)
            let x = (result + constant) / coefficient
            return BasicSolution(
                answer: "x = \(Int(x))",
                steps: [
                    BasicStep(description: "Add \(Int(constant)) to both sides", expression: "\(Int(coefficient))x = \(Int(result + constant))"),
                    BasicStep(description: "Divide both sides by \(Int(coefficient))", expression: "x = \(Int(x))")
                ],
                type: .algebra
            )

        default:
            throw OfflineError.unsupportedEquation
        }
    }

    private func extractNumber(from string: String, match: NSTextCheckingResult, group: Int) -> Double {
        guard let range = Range(match.range(at: group), in: string) else {
            return 1 // Default coefficient
        }
        let numString = String(string[range])
        return Double(numString) ?? 1
    }
}

// MARK: - Supporting Types

struct BasicSolution {
    let answer: String
    let steps: [BasicStep]
    let type: BasicSolutionType
}

struct BasicStep {
    let description: String
    let expression: String
}

enum BasicSolutionType {
    case arithmetic
    case algebra
}

enum OfflineError: LocalizedError {
    case invalidImage
    case unsupportedEquation
    case patternError
    case noMatch
    case divisionByZero

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Could not process the image"
        case .unsupportedEquation:
            return "This equation type is not supported in offline mode"
        case .patternError:
            return "Pattern matching error"
        case .noMatch:
            return "Could not recognize the equation"
        case .divisionByZero:
            return "Cannot divide by zero"
        }
    }
}

// MARK: - Extension to convert BasicSolution to MathProblem

extension BasicSolution {
    func toMathProblem(originalText: String) -> MathProblem {
        MathProblem(
            problemText: originalText,
            problemType: type == .arithmetic ? .arithmetic : .algebra,
            solution: answer,
            steps: steps.enumerated().map { index, step in
                SolutionStep(
                    stepNumber: index + 1,
                    title: step.description,
                    explanation: step.description,
                    mathExpression: step.expression
                )
            }
        )
    }
}
