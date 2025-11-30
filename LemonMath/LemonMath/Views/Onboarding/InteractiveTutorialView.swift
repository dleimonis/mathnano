//
//  InteractiveTutorialView.swift
//  LemonMath
//
//  A brief, skippable interactive tutorial for first-time users
//

import SwiftUI

struct InteractiveTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsManager: SettingsManager

    @State private var currentStep = 0
    @State private var isAnimating = false
    @State private var showSkipConfirmation = false

    let onComplete: () -> Void

    private let tutorialSteps = TutorialStep.allSteps

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with skip button
                header

                // Tutorial content
                TabView(selection: $currentStep) {
                    ForEach(Array(tutorialSteps.enumerated()), id: \.offset) { index, step in
                        TutorialStepView(step: step, isActive: currentStep == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom navigation
                bottomNavigation
            }
        }
        .alert("Skip Tutorial?", isPresented: $showSkipConfirmation) {
            Button("Continue Learning", role: .cancel) {}
            Button("Skip") {
                completeTutorial()
            }
        } message: {
            Text("You can always access the tutorial later from Settings.")
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            // Progress indicator
            HStack(spacing: 4) {
                ForEach(0..<tutorialSteps.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index <= currentStep ? LemonMathColors.accent : Color.white.opacity(0.3))
                        .frame(width: index == currentStep ? 24 : 8, height: 4)
                        .animation(.spring(), value: currentStep)
                }
            }

            Spacer()

            // Skip button
            Button {
                showSkipConfirmation = true
            } label: {
                Text("Skip")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }

    // MARK: - Bottom Navigation
    private var bottomNavigation: some View {
        HStack {
            // Back button
            if currentStep > 0 {
                Button {
                    withAnimation {
                        currentStep -= 1
                    }
                    settingsManager.triggerHapticFeedback(.light)
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
            }

            Spacer()

            // Next/Done button
            Button {
                if currentStep < tutorialSteps.count - 1 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    completeTutorial()
                }
                settingsManager.triggerHapticFeedback(.medium)
            } label: {
                HStack {
                    Text(currentStep < tutorialSteps.count - 1 ? "Next" : "Start Solving!")
                        .fontWeight(.semibold)
                    Image(systemName: currentStep < tutorialSteps.count - 1 ? "chevron.right" : "sparkles")
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(LemonMathColors.accent)
                .clipShape(Capsule())
            }
        }
        .padding()
        .padding(.bottom, 20)
    }

    private func completeTutorial() {
        settingsManager.triggerSuccessHaptic()
        onComplete()
        dismiss()
    }
}

// MARK: - Tutorial Step Model
struct TutorialStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let animationType: TutorialAnimationType
    let tipText: String?

    enum TutorialAnimationType {
        case scanDemo
        case processingDemo
        case solutionDemo
        case explainDemo
        case shareDemo
    }

    static let allSteps: [TutorialStep] = [
        TutorialStep(
            title: "1. Capture Your Problem",
            description: "Point your camera at any handwritten or printed math problem. Frame it clearly within the guide box.",
            animationType: .scanDemo,
            tipText: "Tip: Good lighting helps get better results!"
        ),
        TutorialStep(
            title: "2. Watch the Magic",
            description: "Our AI analyzes your problem and generates a beautiful animated solution in matching handwriting style.",
            animationType: .processingDemo,
            tipText: "Solutions appear in under 10 seconds!"
        ),
        TutorialStep(
            title: "3. See Your Solution",
            description: "Watch as the solution appears with a magical writing animation. The answer is highlighted clearly.",
            animationType: .solutionDemo,
            tipText: nil
        ),
        TutorialStep(
            title: "4. Understand Every Step",
            description: "Tap 'Explain' to see detailed step-by-step breakdowns, alternative methods, and real-world examples.",
            animationType: .explainDemo,
            tipText: "Learning the 'why' makes you smarter!"
        ),
        TutorialStep(
            title: "5. Share & Challenge",
            description: "Share solutions with friends as images or PDFs, or challenge them to solve the same problem!",
            animationType: .shareDemo,
            tipText: nil
        )
    ]
}

// MARK: - Tutorial Step View
struct TutorialStepView: View {
    let step: TutorialStep
    let isActive: Bool

    @State private var animationPhase = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animation area
            tutorialAnimation
                .frame(height: 280)

            // Content
            VStack(spacing: 16) {
                Text(step.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(step.description)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if let tip = step.tipText {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(LemonMathColors.lemonYellow)

                        Text(tip)
                            .font(.subheadline)
                            .italic()
                            .foregroundStyle(LemonMathColors.lemonYellow)
                    }
                    .padding()
                    .background(LemonMathColors.lemonYellow.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Spacer()
            Spacer()
        }
        .onAppear {
            if isActive {
                startAnimation()
            }
        }
        .onChange(of: isActive) { oldValue, newValue in
            if newValue {
                animationPhase = 0
                startAnimation()
            }
        }
    }

    // MARK: - Tutorial Animations
    @ViewBuilder
    private var tutorialAnimation: some View {
        switch step.animationType {
        case .scanDemo:
            ScanDemoAnimation(phase: animationPhase)
        case .processingDemo:
            ProcessingDemoAnimation(phase: animationPhase)
        case .solutionDemo:
            SolutionDemoAnimation(phase: animationPhase)
        case .explainDemo:
            ExplainDemoAnimation(phase: animationPhase)
        case .shareDemo:
            ShareDemoAnimation(phase: animationPhase)
        }
    }

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                animationPhase = (animationPhase + 1) % 4
            }
        }
    }
}

// MARK: - Scan Demo Animation
struct ScanDemoAnimation: View {
    let phase: Int
    @State private var scanLineOffset: CGFloat = -100

    var body: some View {
        ZStack {
            // Phone mockup
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 180, height: 240)

            // Camera viewfinder
            RoundedRectangle(cornerRadius: 12)
                .stroke(LemonMathColors.lemonYellow, lineWidth: 2)
                .frame(width: 140, height: 100)

            // Math problem in frame
            VStack(spacing: 4) {
                Text("2x + 5 = 15")
                    .font(.system(size: 20, design: .serif))
                    .foregroundStyle(.white)
            }
            .offset(y: phase % 2 == 0 ? -5 : 5)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: phase)

            // Scanning line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            LemonMathColors.accent.opacity(0),
                            LemonMathColors.accent,
                            LemonMathColors.accent.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 140, height: 3)
                .offset(y: scanLineOffset)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                scanLineOffset = 100
            }
        }
    }
}

// MARK: - Processing Demo Animation
struct ProcessingDemoAnimation: View {
    let phase: Int
    @State private var rotation: Double = 0
    @State private var sparkleScale: CGFloat = 0.8

    var body: some View {
        ZStack {
            // Rotating gears/processing indicator
            ForEach(0..<3) { i in
                Circle()
                    .stroke(LemonMathColors.accent.opacity(0.3), lineWidth: 3)
                    .frame(width: CGFloat(80 + i * 40), height: CGFloat(80 + i * 40))
                    .rotationEffect(.degrees(rotation * (i % 2 == 0 ? 1 : -1)))
            }

            // Center mascot
            MiniMascotView(size: 60)
                .scaleEffect(sparkleScale)

            // Floating sparkles
            ForEach(0..<6) { i in
                Image(systemName: "sparkle")
                    .font(.title2)
                    .foregroundStyle(LemonMathColors.lemonYellow)
                    .offset(y: -90)
                    .rotationEffect(.degrees(Double(i) * 60 + rotation))
            }

            // Progress text
            Text("Solving...")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .offset(y: 80)
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                sparkleScale = 1.1
            }
        }
    }
}

// MARK: - Solution Demo Animation
struct SolutionDemoAnimation: View {
    let phase: Int
    @State private var revealProgress: CGFloat = 0

    var body: some View {
        ZStack {
            // Paper background
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .frame(width: 200, height: 150)
                .shadow(color: .black.opacity(0.3), radius: 10)

            VStack(alignment: .leading, spacing: 12) {
                // Problem
                Text("2x + 5 = 15")
                    .font(.system(size: 18, design: .serif))
                    .foregroundStyle(.black)

                // Solution appearing with animation
                HStack(spacing: 0) {
                    Text("x = 5")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(LemonMathColors.accent)
                }
                .mask(
                    Rectangle()
                        .size(width: 100 * revealProgress, height: 30)
                )

                // Checkmark
                if revealProgress > 0.9 {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(LemonMathColors.success)
                        Text("Solved!")
                            .font(.caption)
                            .foregroundStyle(LemonMathColors.success)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding()

            // Glowing pen effect
            if revealProgress < 1 {
                Circle()
                    .fill(LemonMathColors.lemonYellow.opacity(0.6))
                    .frame(width: 20, height: 20)
                    .blur(radius: 8)
                    .offset(x: -60 + (120 * revealProgress), y: 30)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                revealProgress = 1.0
            }
        }
    }
}

// MARK: - Explain Demo Animation
struct ExplainDemoAnimation: View {
    let phase: Int
    @State private var expandedStep = 0

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<3) { index in
                HStack(spacing: 12) {
                    // Step number
                    ZStack {
                        Circle()
                            .fill(index <= expandedStep ? LemonMathColors.accent : Color.gray.opacity(0.3))
                            .frame(width: 28, height: 28)

                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }

                    // Step content
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stepTitles[index])
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)

                        if index <= expandedStep {
                            Text(stepExpressions[index])
                                .font(.caption2)
                                .foregroundStyle(LemonMathColors.accent)
                        }
                    }

                    Spacer()

                    if index <= expandedStep {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundStyle(LemonMathColors.success)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(width: 220)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                withAnimation {
                    expandedStep = (expandedStep + 1) % 4
                }
            }
        }
    }

    private let stepTitles = ["Subtract 5 from both sides", "Simplify", "Divide by 2"]
    private let stepExpressions = ["2x = 10", "2x = 10", "x = 5"]
}

// MARK: - Share Demo Animation
struct ShareDemoAnimation: View {
    let phase: Int
    @State private var shareOffset: CGFloat = 0
    @State private var showIcons = false

    var body: some View {
        ZStack {
            // Document
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .frame(width: 120, height: 160)
                .shadow(color: .black.opacity(0.2), radius: 8)
                .offset(y: shareOffset)

            // Content on document
            VStack {
                Text("x = 5")
                    .font(.headline)
                    .foregroundStyle(LemonMathColors.accent)
            }
            .offset(y: shareOffset)

            // Share icons appearing
            if showIcons {
                HStack(spacing: 24) {
                    ForEach(shareIcons.indices, id: \.self) { index in
                        Image(systemName: shareIcons[index])
                            .font(.title2)
                            .foregroundStyle(shareColors[index])
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .offset(y: -100)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                shareOffset = -20
            }
            withAnimation(.spring().delay(0.5)) {
                showIcons = true
            }
        }
    }

    private let shareIcons = ["message.fill", "envelope.fill", "square.and.arrow.up"]
    private let shareColors: [Color] = [.green, .blue, LemonMathColors.accent]
}

// MARK: - First Time Tutorial Trigger
struct FirstTimeTutorialCheck: ViewModifier {
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @State private var showTutorial = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasSeenTutorial {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showTutorial = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showTutorial) {
                InteractiveTutorialView {
                    hasSeenTutorial = true
                }
            }
    }
}

extension View {
    func checkFirstTimeTutorial() -> some View {
        modifier(FirstTimeTutorialCheck())
    }
}

#Preview {
    InteractiveTutorialView(onComplete: {})
        .environmentObject(SettingsManager())
}
