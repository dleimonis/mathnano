//
//  ClaudeVerificationService.swift
//  LemonMath
//
//  Claude API service for solution verification and independent solving
//

import Foundation

// MARK: - Claude Verification Service

class ClaudeVerificationService {
    static let shared = ClaudeVerificationService()

    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let apiVersion = "2023-06-01"
    private let apiKey: String

    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // Verification settings
    private var settings: VerificationSettings {
        // Load from UserDefaults or use default
        if let data = UserDefaults.standard.data(forKey: "verificationSettings"),
           let saved = try? decoder.decode(VerificationSettings.self, from: data) {
            return saved
        }
        return .default
    }

    init() {
        // Load API key: First check UserDefaults (user-provided), then fall back to Info.plist
        let userProvidedKey = UserDefaults.standard.string(forKey: "claudeAPIKey") ?? ""
        let bundleKey = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String ?? ""
        self.apiKey = userProvidedKey.isEmpty ? bundleKey : userProvidedKey

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }

    /// Check if API key is configured
    var isConfigured: Bool {
        let userProvidedKey = UserDefaults.standard.string(forKey: "claudeAPIKey") ?? ""
        let bundleKey = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String ?? ""
        return !userProvidedKey.isEmpty || !bundleKey.isEmpty
    }

    /// Get the current API key (refreshed from storage)
    private var currentAPIKey: String {
        let userProvidedKey = UserDefaults.standard.string(forKey: "claudeAPIKey") ?? ""
        let bundleKey = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String ?? ""
        return userProvidedKey.isEmpty ? bundleKey : userProvidedKey
    }

    // MARK: - Public Methods

    /// Verify a solution from Gemini
    @MainActor
    func verifySolution(
        problem: String,
        geminiSolution: MathSolutionResponse,
        useOpus: Bool = false
    ) async throws -> VerificationResult {
        let model = useOpus ? ClaudeModel.opus : settings.defaultModel

        let prompt = buildVerificationPrompt(
            problem: problem,
            proposedSolution: geminiSolution.solution,
            proposedSteps: geminiSolution.steps
        )

        let response = try await performRequest(prompt: prompt, model: model)

        return try parseVerificationResponse(from: response)
    }

    /// Solve problem independently (for comparison)
    @MainActor
    func solveProblemIndependently(
        problem: String,
        problemType: String? = nil,
        useOpus: Bool = false
    ) async throws -> MathSolutionResponse {
        let model = useOpus ? ClaudeModel.opus : settings.defaultModel

        let prompt = buildSolvingPrompt(problem: problem, problemType: problemType)

        let response = try await performRequest(prompt: prompt, model: model)

        return try parseSolutionResponse(from: response)
    }

    /// Verify and compare with independent solution
    @MainActor
    func verifyWithComparison(
        problem: String,
        geminiSolution: MathSolutionResponse
    ) async throws -> (verification: VerificationResult, independentSolution: MathSolutionResponse?) {
        // Start with Sonnet for verification
        let verification = try await verifySolution(
            problem: problem,
            geminiSolution: geminiSolution,
            useOpus: false
        )

        // If verification finds issues or low confidence, get independent solution
        if !verification.isCorrect || verification.confidence < 0.7 {
            // Escalate to Opus for independent solving if enabled
            let useOpus = settings.escalateToOpus
            let independentSolution = try? await solveProblemIndependently(
                problem: problem,
                problemType: geminiSolution.problemType,
                useOpus: useOpus
            )
            return (verification, independentSolution)
        }

        return (verification, nil)
    }

    // MARK: - Private Methods

    private func buildVerificationPrompt(
        problem: String,
        proposedSolution: String,
        proposedSteps: [StepResponse]
    ) -> String {
        let stepsText = proposedSteps.map { step in
            "Step \(step.stepNumber): \(step.title)\n\(step.explanation)\n\(step.mathExpression)"
        }.joined(separator: "\n\n")

        return """
        You are a math verification expert. Your task is to verify the correctness of a proposed solution.

        PROBLEM:
        \(problem)

        PROPOSED SOLUTION:
        \(proposedSolution)

        PROPOSED STEPS:
        \(stepsText)

        VERIFICATION TASKS:
        1. Check if the proposed solution is mathematically correct
        2. Verify each step's logic and calculations
        3. Substitute the final answer back into the original problem to confirm
        4. Identify any errors in reasoning or calculation
        5. If incorrect, provide the correct solution

        Return a JSON object with this structure:
        {
            "isCorrect": true/false,
            "confidence": 0.95,
            "errors": ["list of errors found, if any"],
            "alternativeSolution": "correct solution if proposed is wrong, null otherwise",
            "verificationNotes": "explanation of verification process"
        }

        IMPORTANT: Return ONLY valid JSON, no markdown code blocks.
        """
    }

    private func buildSolvingPrompt(problem: String, problemType: String?) -> String {
        let typeHint = problemType.map { "Problem type: \($0)" } ?? ""

        return """
        You are an expert math tutor. Solve this math problem step-by-step.

        PROBLEM:
        \(problem)
        \(typeHint)

        REQUIREMENTS:
        1. Solve the problem completely and correctly
        2. Show all steps with clear explanations
        3. Verify your answer by substitution
        4. Use proper mathematical notation

        Return a JSON object with this structure:
        {
            "recognizedText": "the math problem",
            "problemType": "algebra|geometry|calculus|arithmetic|trigonometry|statistics|unknown",
            "solution": "the final answer",
            "confidence": 0.95,
            "steps": [
                {
                    "stepNumber": 1,
                    "title": "Step title",
                    "explanation": "What we're doing and why",
                    "mathExpression": "The mathematical work",
                    "hint": "Optional helpful tip"
                }
            ]
        }

        IMPORTANT: Return ONLY valid JSON, no markdown code blocks. Always verify your answer.
        """
    }

    private func performRequest(prompt: String, model: ClaudeModel) async throws -> ClaudeResponse {
        let key = currentAPIKey
        guard !key.isEmpty else {
            throw ClaudeError.missingAPIKey
        }

        guard let url = URL(string: baseURL) else {
            throw ClaudeError.invalidURL
        }

        let request = ClaudeRequest(
            model: model.rawValue,
            maxTokens: 4096,
            messages: [
                ClaudeMessage(role: "user", content: prompt)
            ],
            temperature: 0.3
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(key, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try decoder.decode(ClaudeResponse.self, from: data)
        case 400:
            throw ClaudeError.badRequest
        case 401, 403:
            throw ClaudeError.unauthorized
        case 429:
            throw ClaudeError.rateLimited
        case 500...599:
            throw ClaudeError.serverError
        default:
            if let errorResponse = try? decoder.decode(ClaudeErrorResponse.self, from: data) {
                throw ClaudeError.apiError(errorResponse.error.message)
            }
            throw ClaudeError.unknown
        }
    }

    private func parseVerificationResponse(from response: ClaudeResponse) throws -> VerificationResult {
        guard let content = response.content.first?.text else {
            throw ClaudeError.invalidResponse
        }

        // Clean the response - remove markdown code blocks if present
        let cleanedText = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw ClaudeError.invalidResponse
        }

        return try decoder.decode(VerificationResult.self, from: jsonData)
    }

    private func parseSolutionResponse(from response: ClaudeResponse) throws -> MathSolutionResponse {
        guard let content = response.content.first?.text else {
            throw ClaudeError.invalidResponse
        }

        let cleanedText = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw ClaudeError.invalidResponse
        }

        let parsed = try decoder.decode(ClaudeMathResult.self, from: jsonData)

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
                    conceptUsed: nil
                )
            },
            alternativeMethods: [],
            realWorldExamples: [],
            graphData: nil,
            confidence: parsed.confidence,
            processingTimeMs: 0
        )
    }
}

// MARK: - Claude API Request/Response Models

struct ClaudeRequest: Encodable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]
    let temperature: Double?

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
        case temperature
    }
}

struct ClaudeMessage: Encodable {
    let role: String
    let content: String
}

struct ClaudeResponse: Decodable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContent]
    let model: String
    let usage: ClaudeUsage?
}

struct ClaudeContent: Decodable {
    let type: String
    let text: String?
}

struct ClaudeUsage: Decodable {
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

struct ClaudeErrorResponse: Decodable {
    let error: ClaudeErrorDetail
}

struct ClaudeErrorDetail: Decodable {
    let type: String
    let message: String
}

struct ClaudeMathResult: Decodable {
    let recognizedText: String
    let problemType: String
    let solution: String
    let confidence: Double
    let steps: [ClaudeStep]
}

struct ClaudeStep: Decodable {
    let stepNumber: Int
    let title: String
    let explanation: String
    let mathExpression: String
    let hint: String?
}

// MARK: - Errors

enum ClaudeError: LocalizedError {
    case invalidURL
    case invalidResponse
    case missingAPIKey
    case unauthorized
    case rateLimited
    case serverError
    case badRequest
    case apiError(String)
    case parseError(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Claude API URL"
        case .invalidResponse:
            return "Invalid response from Claude"
        case .missingAPIKey:
            return "Claude API key is not configured. Please add your API key in Settings."
        case .unauthorized:
            return "Claude API key is invalid or expired"
        case .rateLimited:
            return "Too many requests to Claude. Please try again later"
        case .serverError:
            return "Claude server is temporarily unavailable"
        case .badRequest:
            return "Invalid request to Claude"
        case .apiError(let message):
            return message
        case .parseError(let message):
            return message
        case .unknown:
            return "An unknown error occurred with Claude"
        }
    }
}
