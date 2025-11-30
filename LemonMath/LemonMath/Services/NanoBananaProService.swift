//
//  NanoBananaProService.swift
//  LemonMath
//
//  API service for communicating with Nano Banana Pro model
//

import Foundation
import UIKit

// MARK: - Nano Banana Pro Service
class NanoBananaProService {
    static let shared = NanoBananaProService()

    private let baseURL = "https://api.nanobananapro.ai/v1"
    private let apiKey: String

    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        // Load API key from configuration
        self.apiKey = Bundle.main.object(forInfoDictionaryKey: "NANO_BANANA_PRO_API_KEY") as? String ?? ""

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)

        decoder.keyDecodingStrategy = .convertFromSnakeCase
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - Public Methods

    /// Analyze a math problem image and get solution
    func solveMathProblem(
        image: UIImage,
        language: SupportedLanguage = .english,
        options: SolveOptions = .default
    ) async throws -> MathSolutionResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NanoBananaError.invalidImage
        }

        let base64Image = imageData.base64EncodedString()

        let request = MathSolveRequest(
            image: base64Image,
            language: language.code,
            includeSteps: options.includeSteps,
            includeAlternatives: options.includeAlternatives,
            includeRealWorldExamples: options.includeRealWorldExamples,
            generateHandwritingStyle: options.generateHandwritingStyle,
            graphsEnabled: options.graphsEnabled
        )

        return try await performRequest(
            endpoint: "/solve",
            method: .post,
            body: request
        )
    }

    /// Generate a handwritten solution image
    func generateSolutionImage(
        solution: String,
        style: HandwritingStyle = .default,
        options: ImageGenerationOptions = .default
    ) async throws -> UIImage {
        let request = ImageGenerationRequest(
            solution: solution,
            style: style.rawValue,
            width: options.width,
            height: options.height,
            backgroundColor: options.backgroundColor,
            inkColor: options.inkColor,
            animationFrames: options.animationFrames
        )

        let response: ImageGenerationResponse = try await performRequest(
            endpoint: "/generate-image",
            method: .post,
            body: request
        )

        guard let imageData = Data(base64Encoded: response.imageBase64),
              let image = UIImage(data: imageData) else {
            throw NanoBananaError.invalidResponse
        }

        return image
    }

    /// Recognize handwritten text from image
    func recognizeHandwriting(
        image: UIImage,
        language: SupportedLanguage = .english
    ) async throws -> HandwritingRecognitionResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw NanoBananaError.invalidImage
        }

        let base64Image = imageData.base64EncodedString()

        let request = HandwritingRecognitionRequest(
            image: base64Image,
            language: language.code,
            enhanceContrast: true,
            correctOrientation: true
        )

        return try await performRequest(
            endpoint: "/recognize",
            method: .post,
            body: request
        )
    }

    /// Get step-by-step explanation for a problem
    func getDetailedExplanation(
        problemId: String,
        language: SupportedLanguage = .english
    ) async throws -> DetailedExplanationResponse {
        let request = ExplanationRequest(
            problemId: problemId,
            language: language.code,
            includeGraphs: true,
            includeInteractive: true
        )

        return try await performRequest(
            endpoint: "/explain",
            method: .post,
            body: request
        )
    }

    /// Check API health status
    func checkHealth() async throws -> Bool {
        let response: HealthResponse = try await performRequest(
            endpoint: "/health",
            method: .get,
            body: Optional<EmptyBody>.none
        )
        return response.status == "healthy"
    }

    // MARK: - Private Methods

    private func performRequest<T: Decodable, B: Encodable>(
        endpoint: String,
        method: HTTPMethod,
        body: B?
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NanoBananaError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("LemonMath-iOS/1.0", forHTTPHeaderField: "User-Agent")

        if let body = body {
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NanoBananaError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 401:
            throw NanoBananaError.unauthorized
        case 429:
            throw NanoBananaError.rateLimited
        case 500...599:
            throw NanoBananaError.serverError
        default:
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw NanoBananaError.apiError(errorResponse.message)
            }
            throw NanoBananaError.unknown
        }
    }
}

// MARK: - Request/Response Models

struct MathSolveRequest: Encodable {
    let image: String
    let language: String
    let includeSteps: Bool
    let includeAlternatives: Bool
    let includeRealWorldExamples: Bool
    let generateHandwritingStyle: Bool
    let graphsEnabled: Bool
}

struct MathSolutionResponse: Decodable {
    let problemId: String
    let recognizedText: String
    let problemType: String
    let solution: String
    let solutionImageBase64: String?
    let steps: [StepResponse]
    let alternativeMethods: [AlternativeMethodResponse]
    let realWorldExamples: [RealWorldExampleResponse]
    let graphData: GraphDataResponse?
    let confidence: Double
    let processingTimeMs: Int
}

struct StepResponse: Decodable {
    let stepNumber: Int
    let title: String
    let explanation: String
    let mathExpression: String
    let hint: String?
    let conceptUsed: String?
}

struct AlternativeMethodResponse: Decodable {
    let name: String
    let description: String
    let steps: [StepResponse]
    let difficulty: String
}

struct RealWorldExampleResponse: Decodable {
    let title: String
    let scenario: String
    let application: String
    let icon: String
}

struct GraphDataResponse: Decodable {
    let type: String
    let points: [[Double]]
    let xAxisLabel: String
    let yAxisLabel: String
    let title: String
}

struct ImageGenerationRequest: Encodable {
    let solution: String
    let style: String
    let width: Int
    let height: Int
    let backgroundColor: String
    let inkColor: String
    let animationFrames: Int
}

struct ImageGenerationResponse: Decodable {
    let imageBase64: String
    let animationFrames: [String]?
}

struct HandwritingRecognitionRequest: Encodable {
    let image: String
    let language: String
    let enhanceContrast: Bool
    let correctOrientation: Bool
}

struct HandwritingRecognitionResponse: Decodable {
    let recognizedText: String
    let confidence: Double
    let boundingBoxes: [BoundingBoxResponse]
    let language: String
}

struct BoundingBoxResponse: Decodable {
    let text: String
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

struct ExplanationRequest: Encodable {
    let problemId: String
    let language: String
    let includeGraphs: Bool
    let includeInteractive: Bool
}

struct DetailedExplanationResponse: Decodable {
    let steps: [DetailedStepResponse]
    let concepts: [ConceptResponse]
    let relatedProblems: [RelatedProblemResponse]
}

struct DetailedStepResponse: Decodable {
    let stepNumber: Int
    let title: String
    let detailedExplanation: String
    let visualAid: String?
    let commonMistakes: [String]
    let tips: [String]
}

struct ConceptResponse: Decodable {
    let name: String
    let description: String
    let formula: String?
    let examples: [String]
}

struct RelatedProblemResponse: Decodable {
    let problemText: String
    let difficulty: String
}

struct HealthResponse: Decodable {
    let status: String
    let version: String
}

struct ErrorResponse: Decodable {
    let message: String
    let code: String?
}

struct EmptyBody: Encodable {}

// MARK: - Supporting Types

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

struct SolveOptions {
    var includeSteps: Bool
    var includeAlternatives: Bool
    var includeRealWorldExamples: Bool
    var generateHandwritingStyle: Bool
    var graphsEnabled: Bool

    static let `default` = SolveOptions(
        includeSteps: true,
        includeAlternatives: true,
        includeRealWorldExamples: true,
        generateHandwritingStyle: true,
        graphsEnabled: true
    )
}

struct ImageGenerationOptions {
    var width: Int
    var height: Int
    var backgroundColor: String
    var inkColor: String
    var animationFrames: Int

    static let `default` = ImageGenerationOptions(
        width: 800,
        height: 600,
        backgroundColor: "#FFFFFF",
        inkColor: "#1A237E",
        animationFrames: 30
    )
}

enum HandwritingStyle: String {
    case `default` = "default"
    case neat = "neat"
    case casual = "casual"
    case academic = "academic"
    case childlike = "childlike"
}

// MARK: - Errors

enum NanoBananaError: LocalizedError {
    case invalidURL
    case invalidImage
    case invalidResponse
    case unauthorized
    case rateLimited
    case serverError
    case networkError
    case apiError(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidImage:
            return "Could not process the image"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "API key is invalid or expired"
        case .rateLimited:
            return "Too many requests. Please try again later"
        case .serverError:
            return "Server is temporarily unavailable"
        case .networkError:
            return "Network connection error"
        case .apiError(let message):
            return message
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - Response Extensions

extension MathSolutionResponse {
    func toMathProblem(originalImage: UIImage?, language: SupportedLanguage) -> MathProblem {
        let solutionImageData: Data?
        if let base64 = solutionImageBase64,
           let data = Data(base64Encoded: base64) {
            solutionImageData = data
        } else {
            solutionImageData = nil
        }

        let problemType = ProblemType(rawValue: self.problemType) ?? .unknown

        return MathProblem(
            originalImageData: originalImage?.jpegData(compressionQuality: 0.8),
            problemText: recognizedText,
            problemType: problemType,
            solvedImageData: solutionImageData,
            solution: solution,
            steps: steps.map { step in
                SolutionStep(
                    stepNumber: step.stepNumber,
                    title: step.title,
                    explanation: step.explanation,
                    mathExpression: step.mathExpression,
                    hint: step.hint,
                    conceptUsed: step.conceptUsed
                )
            },
            alternativeMethods: alternativeMethods.map { method in
                AlternativeMethod(
                    name: method.name,
                    description: method.description,
                    steps: method.steps.map { step in
                        SolutionStep(
                            stepNumber: step.stepNumber,
                            title: step.title,
                            explanation: step.explanation,
                            mathExpression: step.mathExpression,
                            hint: step.hint,
                            conceptUsed: step.conceptUsed
                        )
                    },
                    difficulty: AlternativeMethod.Difficulty(rawValue: method.difficulty) ?? .intermediate
                )
            },
            realWorldExamples: realWorldExamples.map { example in
                RealWorldExample(
                    title: example.title,
                    scenario: example.scenario,
                    application: example.application,
                    icon: example.icon
                )
            },
            graphData: graphData.map { data in
                GraphData(
                    type: GraphData.GraphType(rawValue: data.type) ?? .line,
                    points: data.points.map { GraphPoint(x: $0[0], y: $0[1]) },
                    xAxisLabel: data.xAxisLabel,
                    yAxisLabel: data.yAxisLabel,
                    title: data.title
                )
            },
            language: language
        )
    }
}
