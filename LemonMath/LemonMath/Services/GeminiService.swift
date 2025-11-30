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

        // Preprocess image for better handwriting recognition
        let preprocessor = ImagePreprocessor.shared
        let preprocessedImage = preprocessor.preprocessForMathNotation(image)

        // Analyze image quality
        let qualityAnalysis = preprocessedImage.analyzeQuality()

        guard let imageData = preprocessedImage.jpegData(compressionQuality: 0.85) else {
            throw GeminiError.invalidImage
        }

        let base64Image = imageData.base64EncodedString()

        // Build enhanced prompt for math problem solving
        let prompt = buildEnhancedMathSolvingPrompt(
            language: language,
            includeSteps: options.includeSteps,
            includeAlternatives: options.includeAlternatives,
            includeRealWorldExamples: options.includeRealWorldExamples,
            imageQuality: qualityAnalysis
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
            var mathResponse = try parseMathResponse(from: response, language: language)

            // If confidence is low, try with alternative preprocessing
            if mathResponse.confidence < 0.7 {
                if let retryResponse = try? await retryWithAlternativePreprocessing(
                    originalImage: image,
                    language: language,
                    options: options
                ) {
                    if retryResponse.confidence > mathResponse.confidence {
                        mathResponse = retryResponse
                    }
                }
            }

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

    /// Retry recognition with alternative preprocessing for unclear handwriting
    private func retryWithAlternativePreprocessing(
        originalImage: UIImage,
        language: SupportedLanguage,
        options: SolveOptions
    ) async throws -> MathSolutionResponse {
        let preprocessor = ImagePreprocessor.shared

        // Try high contrast variant
        let highContrastOptions = PreprocessingOptions(
            normalizeLighting: true,
            reduceNoise: true,
            noiseReductionLevel: 0.04,
            enhanceEdges: true,
            edgeEnhancementIntensity: 0.8,
            correctPerspective: false,
            normalizeLineThickness: true,
            enhanceContrast: true,
            contrastAmount: 1.5,
            applyAdaptiveThreshold: true
        )

        let enhancedImage = preprocessor.preprocessForHandwriting(originalImage, options: highContrastOptions)

        guard let imageData = enhancedImage.jpegData(compressionQuality: 0.85) else {
            throw GeminiError.invalidImage
        }

        let base64Image = imageData.base64EncodedString()

        let prompt = buildEnhancedMathSolvingPrompt(
            language: language,
            includeSteps: options.includeSteps,
            includeAlternatives: options.includeAlternatives,
            includeRealWorldExamples: options.includeRealWorldExamples,
            imageQuality: nil,
            isRetry: true
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
                temperature: 0.15,
                maxOutputTokens: 4096,
                responseMimeType: "application/json"
            )
        )

        let response: GeminiResponse = try await performRequest(request: request)
        return try parseMathResponse(from: response, language: language)
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

    /// Recognize text from a handwritten image with enhanced preprocessing
    @MainActor
    func recognizeHandwriting(
        image: UIImage,
        language: SupportedLanguage = .english
    ) async throws -> String {
        // Preprocess image for better handwriting recognition
        let preprocessor = ImagePreprocessor.shared
        let preprocessedImage = preprocessor.preprocessForMathNotation(image)

        guard let imageData = preprocessedImage.jpegData(compressionQuality: 0.9) else {
            throw GeminiError.invalidImage
        }

        let base64Image = imageData.base64EncodedString()
        let languageName = language == .greek ? "Greek" : "English"

        let prompt = """
        You are an expert at reading handwritten mathematical notation. Your task is to accurately transcribe all mathematical text, equations, and expressions from this image.

        HANDWRITING ANALYSIS GUIDELINES:
        1. Account for natural handwriting variations:
           - Slanted writing (italic-like appearance)
           - Inconsistent letter spacing
           - Variable stroke thickness (thin/thick lines)
           - Connected or overlapping characters

        2. Mathematical symbol recognition:
           - Distinguish between similar symbols: 0 vs O, 1 vs l vs I, x vs ×, - vs =
           - Recognize Greek letters: α, β, γ, θ, π, Σ, etc.
           - Identify operators: +, -, ×, ÷, =, ≠, <, >, ≤, ≥
           - Recognize grouping: parentheses (), brackets [], braces {}
           - Fractions: horizontal lines with numerator above and denominator below
           - Exponents and subscripts: smaller text positioned above or below

        3. Complex notation:
           - Integrals: ∫ with limits
           - Summations: Σ with bounds
           - Square roots: √ with radicand
           - Matrices and determinants
           - Limits: lim with subscript

        The text may be in \(languageName).

        OUTPUT FORMAT:
        Return ONLY the recognized mathematical text/equations.
        Use standard ASCII-compatible notation:
        - x^2 for squared
        - sqrt(x) for square root
        - sum(i=1 to n) for summation
        - int(a to b) for integral
        - frac(a, b) for fractions
        - pi, theta, alpha for Greek letters

        If parts are unclear, provide your best interpretation with [?] marking uncertain portions.
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

    /// Enhanced handwriting recognition with multiple preprocessing attempts
    @MainActor
    func recognizeHandwritingWithRetry(
        image: UIImage,
        language: SupportedLanguage = .english,
        maxRetries: Int = 2
    ) async throws -> HandwritingRecognitionResult {
        let preprocessor = ImagePreprocessor.shared
        let variants = preprocessor.createPreprocessingVariants(image)

        var bestResult: (text: String, confidence: Double)? = nil

        for (index, variant) in variants.prefix(maxRetries + 1).enumerated() {
            do {
                let text = try await recognizeHandwritingVariant(
                    image: variant.image,
                    language: language,
                    variantDescription: variant.description
                )

                // Estimate confidence based on result characteristics
                let confidence = estimateRecognitionConfidence(text: text)

                if bestResult == nil || confidence > bestResult!.confidence {
                    bestResult = (text, confidence)
                }

                // If confidence is high enough, return early
                if confidence >= 0.85 {
                    break
                }
            } catch {
                // Continue to next variant on error
                if index == variants.count - 1 {
                    throw error
                }
            }
        }

        guard let result = bestResult else {
            throw GeminiError.invalidResponse
        }

        return HandwritingRecognitionResult(
            recognizedText: result.text,
            confidence: result.confidence,
            hasUncertainParts: result.text.contains("[?]")
        )
    }

    private func recognizeHandwritingVariant(
        image: UIImage,
        language: SupportedLanguage,
        variantDescription: String
    ) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw GeminiError.invalidImage
        }

        let base64Image = imageData.base64EncodedString()
        let languageName = language == .greek ? "Greek" : "English"

        let prompt = """
        Transcribe all mathematical text and equations from this image. Language: \(languageName).
        Image has been preprocessed with: \(variantDescription).

        Handle handwriting variations: slant, spacing, stroke thickness.
        Use ASCII notation: x^2, sqrt(x), frac(a,b), sum(), int().
        Mark unclear parts with [?].

        Return ONLY the transcribed math content.
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

        return text
    }

    private func estimateRecognitionConfidence(text: String) -> Double {
        var confidence = 1.0

        // Reduce confidence for uncertain parts
        let uncertainCount = text.components(separatedBy: "[?]").count - 1
        confidence -= Double(uncertainCount) * 0.1

        // Reduce confidence for very short results (might be incomplete)
        if text.count < 5 {
            confidence -= 0.2
        }

        // Reduce confidence for results with many special error indicators
        if text.contains("unclear") || text.contains("cannot read") {
            confidence -= 0.3
        }

        return max(0.1, min(1.0, confidence))
    }

    // MARK: - Private Methods

    /// Enhanced prompt builder with handwriting-specific guidance
    private func buildEnhancedMathSolvingPrompt(
        language: SupportedLanguage,
        includeSteps: Bool,
        includeAlternatives: Bool,
        includeRealWorldExamples: Bool,
        imageQuality: ImageQualityAnalysis?,
        isRetry: Bool = false
    ) -> String {
        let languageName = language == .greek ? "Greek" : "English"

        var qualityContext = ""
        if let quality = imageQuality {
            if quality.brightnessScore < 0.4 {
                qualityContext += "Note: Image appears dark. Look carefully for faint strokes.\n"
            }
            if quality.contrastScore < 0.5 {
                qualityContext += "Note: Low contrast image. Pay extra attention to light pencil marks.\n"
            }
            if quality.sharpnessScore < 0.5 {
                qualityContext += "Note: Image may be slightly blurry. Use context to interpret unclear characters.\n"
            }
        }

        let retryContext = isRetry ? """

        IMPORTANT: This is a retry with enhanced image processing. The previous attempt had low confidence.
        Please be extra careful in interpreting the handwriting and use mathematical context to resolve ambiguities.
        """ : ""

        return """
        You are an expert math tutor with exceptional skill at reading handwritten mathematics.
        Analyze this image and solve the math problem shown. Respond in \(languageName).
        \(qualityContext)\(retryContext)

        HANDWRITING RECOGNITION GUIDELINES:
        1. Handle natural handwriting variations:
           - Slanted/italic writing style
           - Inconsistent letter and symbol spacing
           - Variable stroke thickness (thin pencil to thick marker)
           - Connected or overlapping characters
           - Rushed or cursive-style writing

        2. Distinguish similar-looking symbols:
           - Numbers: 0 vs O, 1 vs l vs I vs |, 2 vs Z, 5 vs S, 6 vs b, 8 vs B, 9 vs g
           - Variables: x vs ×, n vs h, u vs v, a vs α
           - Operators: - (minus) vs — (bar) vs = (equals)
           - Greek: θ vs 0, π vs n, Σ vs E, μ vs u

        3. Recognize complex mathematical structures:
           - Fractions with horizontal bars
           - Exponents and subscripts (smaller, positioned text)
           - Square roots and nth roots
           - Integrals, summations, limits
           - Matrices and determinants
           - Piecewise functions

        4. Use mathematical context:
           - Variable naming conventions (x, y, z for unknowns; a, b, c for constants)
           - Equation structure (LHS = RHS)
           - Common patterns (quadratic formula, derivatives, etc.)

        Return a JSON object with this exact structure:
        {
            "recognizedText": "the math problem as text (use proper notation: x^2, sqrt(), frac(a,b))",
            "problemType": "algebra|geometry|calculus|arithmetic|trigonometry|statistics|linear_algebra|differential_equations|unknown",
            "solution": "the final answer",
            "confidence": 0.95,
            "recognitionNotes": "any notes about unclear parts or interpretation choices",
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

        CONFIDENCE SCORING:
        - 0.9-1.0: Crystal clear, no ambiguity
        - 0.7-0.9: Minor uncertainties resolved by context
        - 0.5-0.7: Some ambiguous characters, reasonable interpretation made
        - Below 0.5: Significant portions unclear, best guess provided

        Be thorough but concise. Make explanations clear for students.
        """
    }

    private func buildMathSolvingPrompt(
        language: SupportedLanguage,
        includeSteps: Bool,
        includeAlternatives: Bool,
        includeRealWorldExamples: Bool
    ) -> String {
        return buildEnhancedMathSolvingPrompt(
            language: language,
            includeSteps: includeSteps,
            includeAlternatives: includeAlternatives,
            includeRealWorldExamples: includeRealWorldExamples,
            imageQuality: nil
        )
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
    let recognitionNotes: String?
    let steps: [GeminiStep]
    let alternativeMethods: [GeminiAlternativeMethod]?
    let realWorldExamples: [GeminiRealWorldExample]?
}

// MARK: - Handwriting Recognition Result
struct HandwritingRecognitionResult {
    let recognizedText: String
    let confidence: Double
    let hasUncertainParts: Bool

    var confidenceDescription: String {
        switch confidence {
        case 0.9...1.0: return "Very High"
        case 0.7..<0.9: return "High"
        case 0.5..<0.7: return "Medium"
        case 0.3..<0.5: return "Low"
        default: return "Very Low"
        }
    }
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
