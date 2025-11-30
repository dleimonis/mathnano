//
//  GeminiService.swift
//  LemonMath
//
//  Google Gemini API service for math problem solving
//

import Foundation
import UIKit

// MARK: - Gemini Service
class GeminiService {
    static let shared = GeminiService()

    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    private let model = "gemini-2.0-flash"  // Use Flash for cost efficiency
    private let apiKey: String

    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // Reference to usage manager for quota/rate limit checks
    private var usageManager: APIUsageManager {
        APIUsageManager.shared
    }

    init() {
        // Load API key: First check UserDefaults (user-provided), then fall back to Info.plist
        let userProvidedKey = UserDefaults.standard.string(forKey: "geminiAPIKey") ?? ""
        let bundleKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String ?? ""
        self.apiKey = userProvidedKey.isEmpty ? bundleKey : userProvidedKey

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }

    /// Check if API key is configured
    var isConfigured: Bool {
        let userProvidedKey = UserDefaults.standard.string(forKey: "geminiAPIKey") ?? ""
        let bundleKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String ?? ""
        return !userProvidedKey.isEmpty || !bundleKey.isEmpty
    }

    /// Get the current API key (refreshed from storage)
    private var currentAPIKey: String {
        let userProvidedKey = UserDefaults.standard.string(forKey: "geminiAPIKey") ?? ""
        let bundleKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String ?? ""
        return userProvidedKey.isEmpty ? bundleKey : userProvidedKey
    }

    // MARK: - Public Methods

    /// Analyze a math problem image and get solution
    @MainActor
    func solveMathProblem(
        image: UIImage,
        language: SupportedLanguage = .english,
        options: SolveOptions = .default
    ) async throws -> MathSolutionResponse {
        // Check quota and rate limits first
        let permission = usageManager.canMakeRequest()
        guard permission.isAllowed else {
            if case .denied(let reason) = permission {
                throw GeminiError.quotaExceeded(reason.message)
            }
            throw GeminiError.quotaExceeded("Request not allowed")
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.invalidImage
        }

        let base64Image = imageData.base64EncodedString()

        // Build the prompt for math problem solving
        let prompt = buildMathSolvingPrompt(
            language: language,
            includeSteps: options.includeSteps,
            includeAlternatives: options.includeAlternatives,
            includeRealWorldExamples: options.includeRealWorldExamples
        )

        let request = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [
                        GeminiPart(text: prompt),
                        GeminiPart(inlineData: GeminiInlineData(
                            mimeType: "image/jpeg",
                            data: base64Image
                        ))
                    ]
                )
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.1,  // Low temperature for math accuracy
                maxOutputTokens: 4096,
                responseMimeType: "application/json"
            )
        )

        do {
            let response: GeminiResponse = try await performRequest(request: request)

            // Parse the structured response
            let mathResponse = try parseMathResponse(from: response, language: language)

            // Record successful request
            await MainActor.run {
                usageManager.recordRequest(
                    type: .solve,
                    tokensUsed: response.usageMetadata?.totalTokenCount ?? RequestType.solve.tokenCost,
                    success: true
                )
            }

            return mathResponse
        } catch {
            // Record failed request
            await MainActor.run {
                usageManager.recordRequest(
                    type: .solve,
                    tokensUsed: 0,
                    success: false
                )
            }
            throw error
        }
    }

    /// Get detailed explanation for a specific step or concept
    @MainActor
    func getDetailedExplanation(
        problem: String,
        step: String? = nil,
        language: SupportedLanguage = .english
    ) async throws -> DetailedExplanationResponse {
        let permission = usageManager.canMakeRequest()
        guard permission.isAllowed else {
            if case .denied(let reason) = permission {
                throw GeminiError.quotaExceeded(reason.message)
            }
            throw GeminiError.quotaExceeded("Request not allowed")
        }

        let prompt = buildExplanationPrompt(problem: problem, step: step, language: language)

        let request = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [GeminiPart(text: prompt)]
                )
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.3,
                maxOutputTokens: 2048,
                responseMimeType: "application/json"
            )
        )

        do {
            let response: GeminiResponse = try await performRequest(request: request)
            let explanationResponse = try parseExplanationResponse(from: response)

            await MainActor.run {
                usageManager.recordRequest(
                    type: .explain,
                    tokensUsed: response.usageMetadata?.totalTokenCount ?? RequestType.explain.tokenCost,
                    success: true
                )
            }

            return explanationResponse
        } catch {
            await MainActor.run {
                usageManager.recordRequest(
                    type: .explain,
                    tokensUsed: 0,
                    success: false
                )
            }
            throw error
        }
    }

    /// Recognize text from a handwritten image
    @MainActor
    func recognizeHandwriting(
        image: UIImage,
        language: SupportedLanguage = .english
    ) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw GeminiError.invalidImage
        }

        let base64Image = imageData.base64EncodedString()
        let languageName = language == .greek ? "Greek" : "English"

        let prompt = """
        Extract and transcribe all mathematical text, equations, and expressions from this image.
        The text may be in \(languageName).

        Return ONLY the recognized text/equations, preserving mathematical notation.
        Use standard mathematical symbols (e.g., ^2 for squared, sqrt() for square root).
        """

        let request = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [
                        GeminiPart(text: prompt),
                        GeminiPart(inlineData: GeminiInlineData(
                            mimeType: "image/jpeg",
                            data: base64Image
                        ))
                    ]
                )
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.1,
                maxOutputTokens: 1024
            )
        )

        let response: GeminiResponse = try await performRequest(request: request)

        guard let text = response.candidates?.first?.content.parts.first?.text else {
            throw GeminiError.invalidResponse
        }

        await MainActor.run {
            usageManager.recordRequest(
                type: .recognize,
                tokensUsed: response.usageMetadata?.totalTokenCount ?? RequestType.recognize.tokenCost,
                success: true
            )
        }

        return text
    }

    // MARK: - Private Methods

    private func buildMathSolvingPrompt(
        language: SupportedLanguage,
        includeSteps: Bool,
        includeAlternatives: Bool,
        includeRealWorldExamples: Bool
    ) -> String {
        let languageName = language == .greek ? "Greek" : "English"

        return """
        You are a math tutor analyzing a handwritten or printed math problem.

        Analyze the image and solve the math problem shown. Respond in \(languageName).

        Return a JSON object with this exact structure:
        {
            "recognizedText": "the math problem as text",
            "problemType": "algebra|geometry|calculus|arithmetic|trigonometry|statistics|unknown",
            "solution": "the final answer",
            "confidence": 0.95,
            "steps": [
                {
                    "stepNumber": 1,
                    "title": "Step title",
                    "explanation": "What we're doing and why",
                    "mathExpression": "The mathematical work",
                    "hint": "A helpful tip (optional)",
                    "conceptUsed": "Mathematical concept being applied (optional)"
                }
            ]\(includeAlternatives ? """
            ,
            "alternativeMethods": [
                {
                    "name": "Method name",
                    "description": "When to use this method",
                    "difficulty": "beginner|intermediate|advanced",
                    "steps": [same format as above]
                }
            ]
            """ : "")\(includeRealWorldExamples ? """
            ,
            "realWorldExamples": [
                {
                    "title": "Example title",
                    "scenario": "Real-world situation",
                    "application": "How this math applies",
                    "icon": "SF Symbol name like dollarsign.circle or car.fill"
                }
            ]
            """ : "")
        }

        Be thorough but concise. Make explanations clear for students.
        If you cannot read the problem clearly, set confidence below 0.5 and explain in the solution field.
        """
    }

    private func buildExplanationPrompt(
        problem: String,
        step: String?,
        language: SupportedLanguage
    ) -> String {
        let languageName = language == .greek ? "Greek" : "English"
        let stepContext = step.map { "Specifically explain this step: \($0)" } ?? ""

        return """
        Provide a detailed explanation for this math problem in \(languageName):

        Problem: \(problem)
        \(stepContext)

        Return a JSON object:
        {
            "steps": [
                {
                    "stepNumber": 1,
                    "title": "Step title",
                    "detailedExplanation": "Thorough explanation",
                    "visualAid": "Description of helpful diagram (optional)",
                    "commonMistakes": ["mistake 1", "mistake 2"],
                    "tips": ["tip 1", "tip 2"]
                }
            ],
            "concepts": [
                {
                    "name": "Concept name",
                    "description": "What it is",
                    "formula": "Mathematical formula if applicable",
                    "examples": ["example 1", "example 2"]
                }
            ],
            "relatedProblems": [
                {
                    "problemText": "Similar practice problem",
                    "difficulty": "easy|medium|hard"
                }
            ]
        }
        """
    }

    private func performRequest<T: Decodable>(request: GeminiRequest) async throws -> T {
        let key = currentAPIKey
        guard !key.isEmpty else {
            throw GeminiError.missingAPIKey
        }

        guard let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(key)") else {
            throw GeminiError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 400:
            if let errorResponse = try? decoder.decode(GeminiErrorResponse.self, from: data) {
                throw GeminiError.apiError(errorResponse.error.message)
            }
            throw GeminiError.badRequest
        case 401, 403:
            throw GeminiError.unauthorized
        case 429:
            throw GeminiError.rateLimited
        case 500...599:
            throw GeminiError.serverError
        default:
            if let errorResponse = try? decoder.decode(GeminiErrorResponse.self, from: data) {
                throw GeminiError.apiError(errorResponse.error.message)
            }
            throw GeminiError.unknown
        }
    }

    private func parseMathResponse(from response: GeminiResponse, language: SupportedLanguage) throws -> MathSolutionResponse {
        guard let text = response.candidates?.first?.content.parts.first?.text else {
            throw GeminiError.invalidResponse
        }

        // Clean the response - remove markdown code blocks if present
        let cleanedText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw GeminiError.invalidResponse
        }

        do {
            let parsed = try decoder.decode(GeminiMathResult.self, from: jsonData)
            return MathSolutionResponse(
                problemId: UUID().uuidString,
                recognizedText: parsed.recognizedText,
                problemType: parsed.problemType,
                solution: parsed.solution,
                solutionImageBase64: nil,
                steps: parsed.steps.map { step in
                    StepResponse(
                        stepNumber: step.stepNumber,
                        title: step.title,
                        explanation: step.explanation,
                        mathExpression: step.mathExpression,
                        hint: step.hint,
                        conceptUsed: step.conceptUsed
                    )
                },
                alternativeMethods: (parsed.alternativeMethods ?? []).map { method in
                    AlternativeMethodResponse(
                        name: method.name,
                        description: method.description,
                        steps: method.steps.map { step in
                            StepResponse(
                                stepNumber: step.stepNumber,
                                title: step.title,
                                explanation: step.explanation,
                                mathExpression: step.mathExpression,
                                hint: step.hint,
                                conceptUsed: step.conceptUsed
                            )
                        },
                        difficulty: method.difficulty
                    )
                },
                realWorldExamples: (parsed.realWorldExamples ?? []).map { example in
                    RealWorldExampleResponse(
                        title: example.title,
                        scenario: example.scenario,
                        application: example.application,
                        icon: example.icon
                    )
                },
                graphData: nil,
                confidence: parsed.confidence,
                processingTimeMs: 0
            )
        } catch {
            // If JSON parsing fails, try to extract basic info
            throw GeminiError.parseError("Failed to parse math solution: \(error.localizedDescription)")
        }
    }

    private func parseExplanationResponse(from response: GeminiResponse) throws -> DetailedExplanationResponse {
        guard let text = response.candidates?.first?.content.parts.first?.text else {
            throw GeminiError.invalidResponse
        }

        let cleanedText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw GeminiError.invalidResponse
        }

        let parsed = try decoder.decode(GeminiExplanationResult.self, from: jsonData)

        return DetailedExplanationResponse(
            steps: parsed.steps.map { step in
                DetailedStepResponse(
                    stepNumber: step.stepNumber,
                    title: step.title,
                    detailedExplanation: step.detailedExplanation,
                    visualAid: step.visualAid,
                    commonMistakes: step.commonMistakes,
                    tips: step.tips
                )
            },
            concepts: parsed.concepts.map { concept in
                ConceptResponse(
                    name: concept.name,
                    description: concept.description,
                    formula: concept.formula,
                    examples: concept.examples
                )
            },
            relatedProblems: parsed.relatedProblems.map { problem in
                RelatedProblemResponse(
                    problemText: problem.problemText,
                    difficulty: problem.difficulty
                )
            }
        )
    }
}

// MARK: - Gemini API Request/Response Models

struct GeminiRequest: Encodable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig?

    init(contents: [GeminiContent], generationConfig: GeminiGenerationConfig? = nil) {
        self.contents = contents
        self.generationConfig = generationConfig
    }
}

struct GeminiContent: Encodable {
    let parts: [GeminiPart]
}

struct GeminiPart: Encodable {
    let text: String?
    let inlineData: GeminiInlineData?

    init(text: String) {
        self.text = text
        self.inlineData = nil
    }

    init(inlineData: GeminiInlineData) {
        self.text = nil
        self.inlineData = inlineData
    }
}

struct GeminiInlineData: Encodable {
    let mimeType: String
    let data: String

    enum CodingKeys: String, CodingKey {
        case mimeType = "mime_type"
        case data
    }
}

struct GeminiGenerationConfig: Encodable {
    let temperature: Double?
    let maxOutputTokens: Int?
    let responseMimeType: String?

    init(temperature: Double? = nil, maxOutputTokens: Int? = nil, responseMimeType: String? = nil) {
        self.temperature = temperature
        self.maxOutputTokens = maxOutputTokens
        self.responseMimeType = responseMimeType
    }
}

struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]?
    let usageMetadata: GeminiUsageMetadata?
}

struct GeminiCandidate: Decodable {
    let content: GeminiResponseContent
}

struct GeminiResponseContent: Decodable {
    let parts: [GeminiResponsePart]
}

struct GeminiResponsePart: Decodable {
    let text: String?
}

struct GeminiUsageMetadata: Decodable {
    let promptTokenCount: Int?
    let candidatesTokenCount: Int?
    let totalTokenCount: Int?
}

struct GeminiErrorResponse: Decodable {
    let error: GeminiErrorDetail
}

struct GeminiErrorDetail: Decodable {
    let code: Int
    let message: String
    let status: String?
}

// MARK: - Parsed Response Models

struct GeminiMathResult: Decodable {
    let recognizedText: String
    let problemType: String
    let solution: String
    let confidence: Double
    let steps: [GeminiStep]
    let alternativeMethods: [GeminiAlternativeMethod]?
    let realWorldExamples: [GeminiRealWorldExample]?
}

struct GeminiStep: Decodable {
    let stepNumber: Int
    let title: String
    let explanation: String
    let mathExpression: String
    let hint: String?
    let conceptUsed: String?
}

struct GeminiAlternativeMethod: Decodable {
    let name: String
    let description: String
    let difficulty: String
    let steps: [GeminiStep]
}

struct GeminiRealWorldExample: Decodable {
    let title: String
    let scenario: String
    let application: String
    let icon: String
}

struct GeminiExplanationResult: Decodable {
    let steps: [GeminiDetailedStep]
    let concepts: [GeminiConcept]
    let relatedProblems: [GeminiRelatedProblem]
}

struct GeminiDetailedStep: Decodable {
    let stepNumber: Int
    let title: String
    let detailedExplanation: String
    let visualAid: String?
    let commonMistakes: [String]
    let tips: [String]
}

struct GeminiConcept: Decodable {
    let name: String
    let description: String
    let formula: String?
    let examples: [String]
}

struct GeminiRelatedProblem: Decodable {
    let problemText: String
    let difficulty: String
}

// MARK: - Errors

enum GeminiError: LocalizedError {
    case invalidURL
    case invalidImage
    case invalidResponse
    case missingAPIKey
    case unauthorized
    case rateLimited
    case serverError
    case networkError
    case badRequest
    case apiError(String)
    case parseError(String)
    case quotaExceeded(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidImage:
            return "Could not process the image"
        case .invalidResponse:
            return "Invalid response from server"
        case .missingAPIKey:
            return "Gemini API key is not configured. Please add your API key in Settings."
        case .unauthorized:
            return "API key is invalid or expired"
        case .quotaExceeded(let message):
            return message
        case .rateLimited:
            return "Too many requests. Please try again later"
        case .serverError:
            return "Server is temporarily unavailable"
        case .networkError:
            return "Network connection error"
        case .badRequest:
            return "Invalid request"
        case .apiError(let message):
            return message
        case .parseError(let message):
            return message
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
