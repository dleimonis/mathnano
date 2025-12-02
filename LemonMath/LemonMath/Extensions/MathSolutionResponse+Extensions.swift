//
//  MathSolutionResponse+Extensions.swift
//  LemonMath
//
//  Extensions for converting MathSolutionResponse to MathProblem (Gemini-only flow)
//

import Foundation
import UIKit

extension MathSolutionResponse {
    /// Convert Gemini's MathSolutionResponse to MathProblem (without verification)
    func toMathProblem(
        originalImage: UIImage,
        language: SupportedLanguage
    ) -> MathProblem {
        // Convert steps
        let solutionSteps = steps.map { step in
            SolutionStep(
                stepNumber: step.stepNumber,
                title: step.title,
                explanation: step.explanation,
                mathExpression: step.mathExpression,
                hint: step.hint
            )
        }

        // Convert alternative methods
        let alternativeMethods = self.alternativeMethods.map { method in
            AlternativeMethod(
                name: method.name,
                description: method.description,
                steps: method.steps.map { step in
                    SolutionStep(
                        stepNumber: step.stepNumber,
                        title: step.title,
                        explanation: step.explanation,
                        mathExpression: step.mathExpression,
                        hint: step.hint
                    )
                },
                difficulty: mapDifficulty(method.difficulty)
            )
        }

        // Convert real world examples
        let realWorldExamples = self.realWorldExamples.map { example in
            RealWorldExample(
                title: example.title,
                scenario: example.scenario,
                application: example.application,
                icon: example.icon
            )
        }

        // Convert graph data if available
        let graphData = self.graphData.map { data in
            GraphData(
                type: mapGraphType(data.type),
                points: data.points.map { point in
                    GraphPoint(x: point[0], y: point[1])
                },
                xAxisLabel: data.xAxisLabel,
                yAxisLabel: data.yAxisLabel,
                title: data.title
            )
        }

        return MathProblem(
            originalImageData: originalImage.jpegData(compressionQuality: 0.8),
            problemText: recognizedText,
            problemType: mapProblemType(problemType),
            solvedImageData: nil,
            solution: solution,
            steps: solutionSteps,
            alternativeMethods: alternativeMethods,
            realWorldExamples: realWorldExamples,
            graphData: graphData,
            language: language,
            verificationStatus: .notVerified,
            verifiedBy: [.gemini],
            alternativeSolutions: nil,
            discrepancyNote: nil,
            confidence: confidence
        )
    }

    private func mapProblemType(_ typeString: String) -> ProblemType {
        switch typeString.lowercased() {
        case "algebra": return .algebra
        case "geometry": return .geometry
        case "calculus": return .calculus
        case "arithmetic": return .arithmetic
        case "trigonometry": return .trigonometry
        case "statistics": return .statistics
        case "linear_algebra", "linear algebra": return .linearAlgebra
        case "differential_equations", "differential equations": return .differentialEquations
        default: return .unknown
        }
    }

    private func mapDifficulty(_ difficultyString: String) -> AlternativeMethod.Difficulty {
        switch difficultyString.lowercased() {
        case "beginner", "easy": return .beginner
        case "intermediate", "medium": return .intermediate
        case "advanced", "hard": return .advanced
        default: return .intermediate
        }
    }

    private func mapGraphType(_ typeString: String) -> GraphData.GraphType {
        switch typeString.lowercased() {
        case "line": return .line
        case "scatter": return .scatter
        case "bar": return .bar
        case "area": return .area
        default: return .line
        }
    }
}
