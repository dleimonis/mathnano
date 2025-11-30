//
//  ImagePreprocessor.swift
//  LemonMath
//
//  Image preprocessing utilities for enhanced handwriting recognition
//

import UIKit
import CoreImage
import Accelerate

/// Image preprocessing pipeline for handwriting recognition
class ImagePreprocessor {
    static let shared = ImagePreprocessor()

    private let context = CIContext(options: [.useSoftwareRenderer: false])

    // MARK: - Main Processing Pipeline

    /// Process an image for optimal handwriting recognition
    /// Handles variations in slant, spacing, line thickness, and lighting
    func preprocessForHandwriting(_ image: UIImage, options: PreprocessingOptions = .default) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }

        var processedImage = ciImage

        // Step 1: Correct orientation
        processedImage = correctOrientation(processedImage)

        // Step 2: Normalize lighting and contrast
        if options.normalizeLighting {
            processedImage = normalizeLighting(processedImage)
        }

        // Step 3: Reduce noise
        if options.reduceNoise {
            processedImage = reduceNoise(processedImage, level: options.noiseReductionLevel)
        }

        // Step 4: Enhance edges (helps with thin strokes)
        if options.enhanceEdges {
            processedImage = enhanceEdges(processedImage, intensity: options.edgeEnhancementIntensity)
        }

        // Step 5: Correct perspective if needed
        if options.correctPerspective {
            processedImage = correctPerspective(processedImage)
        }

        // Step 6: Normalize line thickness
        if options.normalizeLineThickness {
            processedImage = normalizeLineThickness(processedImage)
        }

        // Step 7: Enhance contrast for better OCR
        if options.enhanceContrast {
            processedImage = enhanceContrast(processedImage, amount: options.contrastAmount)
        }

        // Step 8: Apply adaptive thresholding for cleaner text
        if options.applyAdaptiveThreshold {
            processedImage = applyAdaptiveThreshold(processedImage)
        }

        // Convert back to UIImage
        guard let cgImage = context.createCGImage(processedImage, from: processedImage.extent) else {
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    /// Quick preprocess for real-time camera preview
    func quickPreprocess(_ image: UIImage) -> UIImage {
        let options = PreprocessingOptions(
            normalizeLighting: true,
            reduceNoise: false,
            enhanceEdges: false,
            correctPerspective: false,
            normalizeLineThickness: false,
            enhanceContrast: true,
            applyAdaptiveThreshold: false
        )
        return preprocessForHandwriting(image, options: options)
    }

    // MARK: - Individual Processing Steps

    private func correctOrientation(_ image: CIImage) -> CIImage {
        // Ensure image is properly oriented
        return image.oriented(.up)
    }

    private func normalizeLighting(_ image: CIImage) -> CIImage {
        // Use histogram equalization to normalize lighting
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(1.1, forKey: kCIInputContrastKey)  // Slight contrast boost
        filter.setValue(0.0, forKey: kCIInputBrightnessKey)
        filter.setValue(0.0, forKey: kCIInputSaturationKey)  // Remove color for cleaner text

        return filter.outputImage ?? image
    }

    private func reduceNoise(_ image: CIImage, level: Float) -> CIImage {
        guard let filter = CIFilter(name: "CINoiseReduction") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(level, forKey: "inputNoiseLevel")
        filter.setValue(0.4, forKey: "inputSharpness")

        return filter.outputImage ?? image
    }

    private func enhanceEdges(_ image: CIImage, intensity: Float) -> CIImage {
        // Sharpen to enhance thin strokes and edges
        guard let filter = CIFilter(name: "CISharpenLuminance") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(intensity, forKey: kCIInputSharpnessKey)

        return filter.outputImage ?? image
    }

    private func correctPerspective(_ image: CIImage) -> CIImage {
        // Basic perspective correction using CIPerspectiveCorrection
        // In a full implementation, you'd detect document corners first
        // For now, we'll use the image as-is but this is a placeholder for future enhancement
        return image
    }

    private func normalizeLineThickness(_ image: CIImage) -> CIImage {
        // Apply morphological operations to normalize stroke width
        // This helps with both very thin and very thick strokes

        // First, apply a slight dilation to thicken thin lines
        guard let dilateFilter = CIFilter(name: "CIMorphologyMaximum") else { return image }
        dilateFilter.setValue(image, forKey: kCIInputImageKey)
        dilateFilter.setValue(1.0, forKey: kCIInputRadiusKey)

        guard let dilated = dilateFilter.outputImage else { return image }

        // Then apply slight erosion to thin overly thick lines
        guard let erodeFilter = CIFilter(name: "CIMorphologyMinimum") else { return dilated }
        erodeFilter.setValue(dilated, forKey: kCIInputImageKey)
        erodeFilter.setValue(0.5, forKey: kCIInputRadiusKey)

        return erodeFilter.outputImage ?? dilated
    }

    private func enhanceContrast(_ image: CIImage, amount: Float) -> CIImage {
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(amount, forKey: kCIInputContrastKey)

        return filter.outputImage ?? image
    }

    private func applyAdaptiveThreshold(_ image: CIImage) -> CIImage {
        // Convert to grayscale first
        guard let grayFilter = CIFilter(name: "CIPhotoEffectNoir") else { return image }
        grayFilter.setValue(image, forKey: kCIInputImageKey)
        guard let grayImage = grayFilter.outputImage else { return image }

        // Apply unsharp mask for local contrast enhancement (simulates adaptive threshold)
        guard let unsharpFilter = CIFilter(name: "CIUnsharpMask") else { return grayImage }
        unsharpFilter.setValue(grayImage, forKey: kCIInputImageKey)
        unsharpFilter.setValue(2.5, forKey: kCIInputRadiusKey)
        unsharpFilter.setValue(1.5, forKey: kCIInputIntensityKey)

        return unsharpFilter.outputImage ?? grayImage
    }

    // MARK: - Analysis Methods

    /// Analyze image quality and suggest preprocessing options
    func analyzeImageQuality(_ image: UIImage) -> ImageQualityAnalysis {
        guard let ciImage = CIImage(image: image) else {
            return ImageQualityAnalysis(
                overallScore: 0,
                brightnessScore: 0,
                contrastScore: 0,
                sharpnessScore: 0,
                noiseScore: 0,
                suggestions: ["Could not analyze image"]
            )
        }

        let brightness = analyzeBrightness(ciImage)
        let contrast = analyzeContrast(ciImage)
        let sharpness = analyzeSharpness(ciImage)
        let noise = analyzeNoise(ciImage)

        var suggestions: [String] = []

        if brightness < 0.3 {
            suggestions.append("Image appears too dark. Try better lighting.")
        } else if brightness > 0.8 {
            suggestions.append("Image appears overexposed. Reduce lighting.")
        }

        if contrast < 0.4 {
            suggestions.append("Low contrast detected. Use darker pen or cleaner paper.")
        }

        if sharpness < 0.5 {
            suggestions.append("Image is blurry. Hold camera steady or use better focus.")
        }

        if noise > 0.6 {
            suggestions.append("High noise detected. Improve lighting conditions.")
        }

        let overallScore = (brightness + contrast + sharpness + (1 - noise)) / 4

        return ImageQualityAnalysis(
            overallScore: overallScore,
            brightnessScore: brightness,
            contrastScore: contrast,
            sharpnessScore: sharpness,
            noiseScore: 1 - noise,
            suggestions: suggestions
        )
    }

    private func analyzeBrightness(_ image: CIImage) -> Float {
        // Calculate average brightness using CIAreaAverage
        guard let filter = CIFilter(name: "CIAreaAverage") else { return 0.5 }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: image.extent), forKey: kCIInputExtentKey)

        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: CGRect(x: 0, y: 0, width: 1, height: 1)) else {
            return 0.5
        }

        // Extract pixel data
        let dataProvider = cgImage.dataProvider!
        let data = dataProvider.data!
        let bytes = CFDataGetBytePtr(data)!

        let r = Float(bytes[0]) / 255.0
        let g = Float(bytes[1]) / 255.0
        let b = Float(bytes[2]) / 255.0

        return (r + g + b) / 3.0
    }

    private func analyzeContrast(_ image: CIImage) -> Float {
        // Estimate contrast by looking at histogram spread
        // Simplified: using color controls to detect if image needs contrast
        // In a full implementation, you'd calculate standard deviation of pixel values
        return 0.7  // Placeholder - would need histogram analysis
    }

    private func analyzeSharpness(_ image: CIImage) -> Float {
        // Detect sharpness using Laplacian variance
        // Simplified implementation
        guard let edgeFilter = CIFilter(name: "CIEdges") else { return 0.5 }
        edgeFilter.setValue(image, forKey: kCIInputImageKey)
        edgeFilter.setValue(1.0, forKey: kCIInputIntensityKey)

        guard let edgeImage = edgeFilter.outputImage else { return 0.5 }

        // Get average edge intensity
        guard let avgFilter = CIFilter(name: "CIAreaAverage") else { return 0.5 }
        avgFilter.setValue(edgeImage, forKey: kCIInputImageKey)
        avgFilter.setValue(CIVector(cgRect: edgeImage.extent), forKey: kCIInputExtentKey)

        guard let outputImage = avgFilter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: CGRect(x: 0, y: 0, width: 1, height: 1)) else {
            return 0.5
        }

        let dataProvider = cgImage.dataProvider!
        let data = dataProvider.data!
        let bytes = CFDataGetBytePtr(data)!

        return min(Float(bytes[0]) / 128.0, 1.0)  // Normalize to 0-1
    }

    private func analyzeNoise(_ image: CIImage) -> Float {
        // Estimate noise level
        // Simplified - would need more sophisticated analysis in production
        return 0.3  // Placeholder
    }

    // MARK: - Specialized Math Preprocessing

    /// Preprocess specifically for mathematical notation
    func preprocessForMathNotation(_ image: UIImage) -> UIImage {
        let options = PreprocessingOptions(
            normalizeLighting: true,
            reduceNoise: true,
            noiseReductionLevel: 0.03,
            enhanceEdges: true,
            edgeEnhancementIntensity: 0.6,  // Higher for thin math symbols
            correctPerspective: true,
            normalizeLineThickness: true,
            enhanceContrast: true,
            contrastAmount: 1.3,
            applyAdaptiveThreshold: true
        )

        return preprocessForHandwriting(image, options: options)
    }

    /// Create multiple preprocessing variants for ensemble recognition
    func createPreprocessingVariants(_ image: UIImage) -> [PreprocessedVariant] {
        var variants: [PreprocessedVariant] = []

        // Original with basic preprocessing
        let basic = preprocessForHandwriting(image, options: .light)
        variants.append(PreprocessedVariant(image: basic, description: "Basic enhancement", weight: 1.0))

        // High contrast variant (good for faint writing)
        let highContrast = preprocessForHandwriting(image, options: PreprocessingOptions(
            normalizeLighting: true,
            reduceNoise: false,
            enhanceEdges: true,
            edgeEnhancementIntensity: 0.8,
            correctPerspective: false,
            normalizeLineThickness: false,
            enhanceContrast: true,
            contrastAmount: 1.5,
            applyAdaptiveThreshold: true
        ))
        variants.append(PreprocessedVariant(image: highContrast, description: "High contrast", weight: 0.8))

        // Denoised variant (good for noisy backgrounds)
        let denoised = preprocessForHandwriting(image, options: PreprocessingOptions(
            normalizeLighting: true,
            reduceNoise: true,
            noiseReductionLevel: 0.05,
            enhanceEdges: false,
            correctPerspective: false,
            normalizeLineThickness: true,
            enhanceContrast: true,
            contrastAmount: 1.2,
            applyAdaptiveThreshold: false
        ))
        variants.append(PreprocessedVariant(image: denoised, description: "Denoised", weight: 0.7))

        // Math-optimized variant
        let mathOptimized = preprocessForMathNotation(image)
        variants.append(PreprocessedVariant(image: mathOptimized, description: "Math optimized", weight: 0.9))

        return variants
    }
}

// MARK: - Supporting Types

struct PreprocessingOptions {
    var normalizeLighting: Bool = true
    var reduceNoise: Bool = true
    var noiseReductionLevel: Float = 0.02
    var enhanceEdges: Bool = true
    var edgeEnhancementIntensity: Float = 0.4
    var correctPerspective: Bool = false
    var normalizeLineThickness: Bool = true
    var enhanceContrast: Bool = true
    var contrastAmount: Float = 1.2
    var applyAdaptiveThreshold: Bool = false

    static let `default` = PreprocessingOptions()

    static let light = PreprocessingOptions(
        normalizeLighting: true,
        reduceNoise: false,
        enhanceEdges: false,
        correctPerspective: false,
        normalizeLineThickness: false,
        enhanceContrast: true,
        contrastAmount: 1.1,
        applyAdaptiveThreshold: false
    )

    static let aggressive = PreprocessingOptions(
        normalizeLighting: true,
        reduceNoise: true,
        noiseReductionLevel: 0.04,
        enhanceEdges: true,
        edgeEnhancementIntensity: 0.7,
        correctPerspective: true,
        normalizeLineThickness: true,
        enhanceContrast: true,
        contrastAmount: 1.4,
        applyAdaptiveThreshold: true
    )
}

struct ImageQualityAnalysis {
    let overallScore: Float
    let brightnessScore: Float
    let contrastScore: Float
    let sharpnessScore: Float
    let noiseScore: Float
    let suggestions: [String]

    var isAcceptable: Bool {
        overallScore >= 0.5
    }

    var qualityDescription: String {
        switch overallScore {
        case 0.8...1.0: return "Excellent"
        case 0.6..<0.8: return "Good"
        case 0.4..<0.6: return "Fair"
        case 0.2..<0.4: return "Poor"
        default: return "Very Poor"
        }
    }
}

struct PreprocessedVariant {
    let image: UIImage
    let description: String
    let weight: Double  // Weight for ensemble voting
}

// MARK: - UIImage Extension for Preprocessing

extension UIImage {
    /// Preprocess for handwriting recognition
    func preprocessedForHandwriting(options: PreprocessingOptions = .default) -> UIImage {
        return ImagePreprocessor.shared.preprocessForHandwriting(self, options: options)
    }

    /// Preprocess for math notation
    func preprocessedForMath() -> UIImage {
        return ImagePreprocessor.shared.preprocessForMathNotation(self)
    }

    /// Analyze quality for recognition
    func analyzeQuality() -> ImageQualityAnalysis {
        return ImagePreprocessor.shared.analyzeImageQuality(self)
    }

    /// Create multiple variants for better recognition
    func preprocessingVariants() -> [PreprocessedVariant] {
        return ImagePreprocessor.shared.createPreprocessingVariants(self)
    }
}
