//
//  SolutionView.swift
//  LemonMath
//

import SwiftUI

struct SolutionView: View {
    let problem: MathProblem
    let onDismiss: () -> Void

    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var historyManager: HistoryManager
    @EnvironmentObject var achievementManager: AchievementManager

    @State private var showAnimation = true
    @State private var animationProgress: CGFloat = 0
    @State private var showExplanation = false
    @State private var showShareSheet = false
    @State private var isFavorite: Bool
    @State private var showSparkles = false

    init(problem: MathProblem, onDismiss: @escaping () -> Void) {
        self.problem = problem
        self.onDismiss = onDismiss
        self._isFavorite = State(initialValue: problem.isFavorite)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.adaptiveBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Original problem section
                        originalProblemSection

                        // Animated solution section
                        solutionSection

                        // Quick answer
                        quickAnswerSection

                        // Action buttons
                        actionButtonsSection

                        // Step preview
                        stepPreviewSection
                    }
                    .padding()
                }

                // Sparkle overlay
                if showSparkles {
                    SparkleOverlayView()
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle("Solution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.adaptiveSecondaryText)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            toggleFavorite()
                        } label: {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundStyle(isFavorite ? .red : Color.adaptiveSecondaryText)
                        }

                        Button {
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(LemonMathColors.accent)
                        }
                    }
                }
            }
            .sheet(isPresented: $showExplanation) {
                ExplanationView(problem: problem)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(problem: problem)
            }
            .onAppear {
                startSolutionAnimation()
            }
        }
    }

    // MARK: - Original Problem Section
    private var originalProblemSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: problem.problemType.icon)
                    .foregroundStyle(problem.problemType.color)

                Text(problem.problemType.displayName)
                    .font(.subheadline)
                    .foregroundStyle(problem.problemType.color)

                Spacer()

                Text(problem.formattedDate)
                    .font(.caption)
                    .foregroundStyle(Color.adaptiveSecondaryText)
            }

            // Original image or text
            if let originalImage = problem.originalImage {
                Image(uiImage: originalImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Text(problem.problemText)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.adaptivePrimaryText)
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Solution Section
    private var solutionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundStyle(LemonMathColors.accent)

                Text("Solution")
                    .font(.headline)
                    .foregroundStyle(Color.adaptivePrimaryText)

                Spacer()

                if showAnimation {
                    ProgressView()
                        .tint(LemonMathColors.accent)
                }
            }

            // Animated solution display
            ZStack {
                if let solvedImage = problem.solvedImage {
                    AnimatedSolutionView(
                        image: solvedImage,
                        progress: animationProgress
                    )
                } else {
                    // Text-based solution with animation
                    AnimatedTextSolutionView(
                        solution: problem.solution,
                        progress: animationProgress
                    )
                }

                // Glowing ink effect overlay
                if showAnimation {
                    GlowingInkOverlay(progress: animationProgress)
                }
            }
            .frame(minHeight: 200)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LemonMathColors.accent.opacity(0.3), lineWidth: 1)
            )
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Quick Answer Section
    private var quickAnswerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Answer")
                .font(.subheadline)
                .foregroundStyle(Color.adaptiveSecondaryText)

            Text(problem.solution)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(LemonMathColors.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: [
                    LemonMathColors.accent.opacity(0.1),
                    LemonMathColors.lemonLight.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            ActionButton(
                title: "Explain",
                icon: "book.fill",
                color: LemonMathColors.accent
            ) {
                showExplanation = true
            }

            ActionButton(
                title: "Share",
                icon: "square.and.arrow.up",
                color: .blue
            ) {
                showShareSheet = true
            }

            ActionButton(
                title: "Challenge",
                icon: "person.2.fill",
                color: .purple
            ) {
                // Create friend challenge
            }
        }
    }

    // MARK: - Step Preview Section
    private var stepPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Solution Steps")
                    .font(.headline)
                    .foregroundStyle(Color.adaptivePrimaryText)

                Spacer()

                Button {
                    showExplanation = true
                } label: {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundStyle(LemonMathColors.accent)
                }
            }

            // Show first 2 steps as preview
            ForEach(Array(problem.steps.prefix(2))) { step in
                StepPreviewCard(step: step)
            }

            if problem.steps.count > 2 {
                Text("+ \(problem.steps.count - 2) more steps")
                    .font(.subheadline)
                    .foregroundStyle(Color.adaptiveSecondaryText)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.adaptiveCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Methods
    private func startSolutionAnimation() {
        let duration = settingsManager.animationSpeed.solutionAnimationDuration

        withAnimation(.easeInOut(duration: duration)) {
            animationProgress = 1.0
        }

        // Show sparkles at completion
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            showAnimation = false
            withAnimation {
                showSparkles = true
            }
            settingsManager.triggerSuccessHaptic()

            // Hide sparkles after a moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showSparkles = false
                }
            }
        }
    }

    private func toggleFavorite() {
        isFavorite.toggle()
        historyManager.toggleFavorite(problem)
        settingsManager.triggerHapticFeedback(.light)
    }
}

// MARK: - Supporting Views

struct AnimatedSolutionView: View {
    let image: UIImage
    let progress: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .mask(
                    Rectangle()
                        .size(
                            width: geometry.size.width,
                            height: geometry.size.height * progress
                        )
                )
        }
    }
}

struct AnimatedTextSolutionView: View {
    let solution: String
    let progress: CGFloat

    var visibleCharacters: Int {
        Int(CGFloat(solution.count) * progress)
    }

    var body: some View {
        Text(String(solution.prefix(visibleCharacters)))
            .font(.system(.title3, design: .serif))
            .foregroundStyle(LemonMathColors.magicInkColor)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct GlowingInkOverlay: View {
    let progress: CGFloat
    @State private var glowOpacity: Double = 0.8

    var body: some View {
        GeometryReader { geometry in
            // Glowing pen tip effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            LemonMathColors.lemonYellow.opacity(glowOpacity),
                            LemonMathColors.lemonYellow.opacity(0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 30
                    )
                )
                .frame(width: 60, height: 60)
                .position(
                    x: geometry.size.width * 0.8,
                    y: geometry.size.height * progress
                )
                .blur(radius: 5)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                glowOpacity = 0.4
            }
        }
    }
}

struct SparkleOverlayView: View {
    @State private var sparkles: [AnimatedSparkle] = []

    var body: some View {
        ZStack {
            ForEach(sparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: sparkle.size))
                    .foregroundStyle(sparkle.color)
                    .position(sparkle.position)
                    .opacity(sparkle.opacity)
            }
        }
        .onAppear {
            generateSparkles()
            animateSparkles()
        }
    }

    private func generateSparkles() {
        sparkles = (0..<15).map { _ in
            AnimatedSparkle(
                position: CGPoint(
                    x: CGFloat.random(in: 50...350),
                    y: CGFloat.random(in: 100...600)
                ),
                size: CGFloat.random(in: 12...24),
                color: [LemonMathColors.lemonYellow, .white, LemonMathColors.accent].randomElement()!,
                opacity: 0
            )
        }
    }

    private func animateSparkles() {
        for index in sparkles.indices {
            let delay = Double(index) * 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.5)) {
                    sparkles[index].opacity = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeIn(duration: 0.5)) {
                        sparkles[index].opacity = 0
                    }
                }
            }
        }
    }
}

struct AnimatedSparkle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var color: Color
    var opacity: Double
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct StepPreviewCard: View {
    let step: SolutionStep

    var body: some View {
        HStack(spacing: 12) {
            // Step number
            ZStack {
                Circle()
                    .fill(LemonMathColors.accent)
                    .frame(width: 32, height: 32)

                Text("\(step.stepNumber)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.adaptivePrimaryText)

                Text(step.mathExpression)
                    .font(.caption)
                    .foregroundStyle(Color.adaptiveSecondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.adaptiveSecondaryText)
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    SolutionView(
        problem: MathProblem(
            problemText: "2x + 5 = 15",
            problemType: .algebra,
            solution: "x = 5",
            steps: [
                SolutionStep(stepNumber: 1, title: "Subtract 5", explanation: "Subtract 5 from both sides", mathExpression: "2x = 10"),
                SolutionStep(stepNumber: 2, title: "Divide by 2", explanation: "Divide both sides by 2", mathExpression: "x = 5")
            ]
        ),
        onDismiss: {}
    )
    .environmentObject(SettingsManager())
    .environmentObject(HistoryManager())
    .environmentObject(AchievementManager())
}
