//
//  CameraScannerView.swift
//  LemonMath
//

import SwiftUI
import AVFoundation
import Vision

struct CameraScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsManager: SettingsManager

    @StateObject private var cameraController = CameraController()
    @State private var capturedImage: UIImage?
    @State private var showProcessing = false
    @State private var detectedTextBounds: [CGRect] = []
    @State private var flashEnabled = false
    @State private var showGuide = true

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(controller: cameraController)
                .ignoresSafeArea()

            // Overlay
            VStack {
                // Top bar
                topBar

                Spacer()

                // Scanning guide frame
                if showGuide {
                    scanningGuide
                }

                Spacer()

                // Bottom controls
                bottomControls
            }

            // Text detection overlay
            ForEach(detectedTextBounds.indices, id: \.self) { index in
                Rectangle()
                    .stroke(LemonMathColors.accent, lineWidth: 2)
                    .frame(
                        width: detectedTextBounds[index].width,
                        height: detectedTextBounds[index].height
                    )
                    .position(
                        x: detectedTextBounds[index].midX,
                        y: detectedTextBounds[index].midY
                    )
            }

            // Processing overlay
            if showProcessing {
                ProcessingOverlayView()
            }
        }
        .onAppear {
            cameraController.startSession()
        }
        .onDisappear {
            cameraController.stopSession()
        }
        .fullScreenCover(item: $capturedImage) { image in
            ImageReviewView(image: image) { confirmed in
                if confirmed {
                    processImage(image)
                } else {
                    capturedImage = nil
                }
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Spacer()

            // Flash toggle
            Button {
                flashEnabled.toggle()
                cameraController.toggleFlash(flashEnabled)
            } label: {
                Image(systemName: flashEnabled ? "bolt.fill" : "bolt.slash")
                    .font(.title2)
                    .foregroundStyle(flashEnabled ? .yellow : .white)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding()
    }

    // MARK: - Scanning Guide
    private var scanningGuide: some View {
        VStack(spacing: 16) {
            // Guide frame
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [LemonMathColors.lemonYellow, LemonMathColors.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 300, height: 200)
                .overlay(
                    // Corner accents
                    ZStack {
                        CornerAccent().position(x: 20, y: 20)
                        CornerAccent().rotationEffect(.degrees(90)).position(x: 280, y: 20)
                        CornerAccent().rotationEffect(.degrees(270)).position(x: 20, y: 180)
                        CornerAccent().rotationEffect(.degrees(180)).position(x: 280, y: 180)
                    }
                )

            // Instructions
            Text("Position the math problem within the frame")
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
    }

    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Capture button
            Button {
                capturePhoto()
            } label: {
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 4)
                        .frame(width: 80, height: 80)

                    Circle()
                        .fill(.white)
                        .frame(width: 68, height: 68)

                    // Lemon icon
                    Image(systemName: "camera.fill")
                        .font(.title)
                        .foregroundStyle(LemonMathColors.accent)
                }
            }
            .accessibilityLabel("Capture photo")

            // Quick tips
            HStack(spacing: 20) {
                QuickTip(icon: "sun.max", text: "Good lighting")
                QuickTip(icon: "hand.draw", text: "Clear writing")
                QuickTip(icon: "square.dashed", text: "Full problem")
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }

    // MARK: - Methods
    private func capturePhoto() {
        settingsManager.triggerHapticFeedback(.medium)
        cameraController.capturePhoto { image in
            if let image = image {
                capturedImage = image
            }
        }
    }

    private func processImage(_ image: UIImage) {
        showProcessing = true
        appState.isProcessing = true

        Task {
            do {
                let coordinator = MathSolvingCoordinator.shared
                let problem = try await coordinator.solveMathProblem(
                    image: image,
                    language: settingsManager.selectedLanguage
                )

                await MainActor.run {
                    appState.currentProblem = problem
                    appState.isProcessing = false
                    showProcessing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    appState.isProcessing = false
                    showProcessing = false
                    // Handle error - could show alert
                    print("Error solving problem: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Corner Accent
struct CornerAccent: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(LemonMathColors.lemonYellow, style: StrokeStyle(lineWidth: 4, lineCap: .round))
    }
}

// MARK: - Quick Tip
struct QuickTip: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption2)
        }
        .foregroundStyle(.white.opacity(0.8))
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let controller: CameraController

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        DispatchQueue.main.async {
            controller.previewLayer.frame = view.bounds
            view.layer.addSublayer(controller.previewLayer)
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            controller.previewLayer.frame = uiView.bounds
        }
    }
}

// MARK: - Camera Controller
class CameraController: NSObject, ObservableObject {
    let captureSession = AVCaptureSession()
    let previewLayer: AVCaptureVideoPreviewLayer
    private let photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?

    override init() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        super.init()
        setupSession()
    }

    private func setupSession() {
        captureSession.sessionPreset = .photo

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
    }

    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }

    func toggleFlash(_ enabled: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }

        try? device.lockForConfiguration()
        device.torchMode = enabled ? .on : .off
        device.unlockForConfiguration()
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        captureCompletion = completion

        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            captureCompletion?(nil)
            return
        }
        captureCompletion?(image)
    }
}

// MARK: - Image Review View
struct ImageReviewView: View {
    let image: UIImage
    let onConfirm: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var cropRect: CGRect = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                // Image preview
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding()

                // Instructions
                Text("Is the problem clearly visible?")
                    .font(.headline)
                    .foregroundStyle(.white)

                // Action buttons
                HStack(spacing: 40) {
                    Button {
                        onConfirm(false)
                        dismiss()
                    } label: {
                        VStack {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title)
                            Text("Retake")
                                .font(.caption)
                        }
                        .foregroundStyle(.white)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        onConfirm(true)
                        dismiss()
                    } label: {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                            Text("Use Photo")
                                .font(.caption)
                        }
                        .foregroundStyle(.white)
                        .padding()
                        .background(LemonMathColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Processing Overlay
struct ProcessingOverlayView: View {
    @State private var progress: Double = 0
    @State private var sparkleAngle: Double = 0
    @State private var statusText = "Analyzing image..."

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                // Animated mascot with sparkles
                ZStack {
                    // Rotating sparkles
                    ForEach(0..<6) { i in
                        Image(systemName: "sparkle")
                            .font(.title)
                            .foregroundStyle(LemonMathColors.lemonYellow)
                            .offset(y: -60)
                            .rotationEffect(.degrees(Double(i) * 60 + sparkleAngle))
                    }

                    MiniMascotView(size: 80)
                }

                // Progress bar
                VStack(spacing: 12) {
                    Text(statusText)
                        .font(.headline)
                        .foregroundStyle(.white)

                    ProgressView(value: progress)
                        .progressViewStyle(LemonProgressStyle())
                        .frame(width: 200)
                }

                Text("Working on your solution...")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Sparkle rotation
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            sparkleAngle = 360
        }

        // Progress simulation
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if progress < 0.95 {
                progress += 0.02
                updateStatusText()
            } else {
                timer.invalidate()
            }
        }
    }

    private func updateStatusText() {
        if progress < 0.3 {
            statusText = "Analyzing image..."
        } else if progress < 0.5 {
            statusText = "Recognizing handwriting..."
        } else if progress < 0.7 {
            statusText = "Solving problem..."
        } else if progress < 0.9 {
            statusText = "Generating solution..."
        } else {
            statusText = "Almost done..."
        }
    }
}

struct LemonProgressStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 10)

                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [LemonMathColors.lemonYellow, LemonMathColors.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * (configuration.fractionCompleted ?? 0), height: 10)
            }
        }
        .frame(height: 10)
    }
}

// MARK: - Photo Library Picker
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageSelected: (UIImage) -> Void

        init(onImageSelected: @escaping (UIImage) -> Void) {
            self.onImageSelected = onImageSelected
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImageSelected(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - UIImage Identifiable Extension
extension UIImage: @retroactive Identifiable {
    public var id: UUID { UUID() }
}

#Preview {
    CameraScannerView()
        .environmentObject(AppState())
        .environmentObject(SettingsManager())
}
