//
//  OnboardingView.swift
//  LemonMath
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsManager: SettingsManager

    @State private var currentPage = 0
    @State private var mascotScale: CGFloat = 0.5
    @State private var mascotOpacity: Double = 0

    private let pages = OnboardingPage.allPages

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    LemonMathColors.lemonLight,
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Bottom section
                VStack(spacing: 24) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? LemonMathColors.accent : LemonMathColors.accent.opacity(0.3))
                                .frame(width: index == currentPage ? 12 : 8, height: index == currentPage ? 12 : 8)
                                .animation(.spring(), value: currentPage)
                        }
                    }

                    // Buttons
                    HStack(spacing: 16) {
                        // Skip button (not on last page)
                        if currentPage < pages.count - 1 {
                            Button {
                                completeOnboarding()
                            } label: {
                                Text("Skip")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.adaptiveSecondaryText)
                            }
                        }

                        Spacer()

                        // Next/Get Started button
                        Button {
                            if currentPage < pages.count - 1 {
                                withAnimation {
                                    currentPage += 1
                                }
                            } else {
                                completeOnboarding()
                            }
                            settingsManager.triggerHapticFeedback(.light)
                        } label: {
                            HStack {
                                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                                    .fontWeight(.semibold)

                                Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "sparkles")
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(LemonMathColors.accent)
                            .clipShape(Capsule())
                            .shadow(color: LemonMathColors.accent.opacity(0.4), radius: 8, y: 4)
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func completeOnboarding() {
        withAnimation(.spring()) {
            appState.isOnboardingComplete = true
        }
        settingsManager.triggerSuccessHaptic()
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let features: [OnboardingFeature]
    let color: Color

    struct OnboardingFeature: Identifiable {
        let id = UUID()
        let icon: String
        let text: String
    }

    static let allPages: [OnboardingPage] = [
        OnboardingPage(
            icon: "camera.viewfinder",
            title: "Scan Any Math Problem",
            subtitle: "Point your camera at handwritten or printed math problems",
            features: [
                OnboardingFeature(icon: "checkmark.circle.fill", text: "Algebra, Geometry, Calculus"),
                OnboardingFeature(icon: "checkmark.circle.fill", text: "Handwriting recognition"),
                OnboardingFeature(icon: "checkmark.circle.fill", text: "Sloppy handwriting? No problem!")
            ],
            color: LemonMathColors.accent
        ),
        OnboardingPage(
            icon: "wand.and.stars",
            title: "Watch the Magic Happen",
            subtitle: "See your solution appear with beautiful animations",
            features: [
                OnboardingFeature(icon: "sparkles", text: "Animated handwriting effect"),
                OnboardingFeature(icon: "sparkles", text: "Glowing ink magic"),
                OnboardingFeature(icon: "sparkles", text: "Under 10 seconds!")
            ],
            color: .purple
        ),
        OnboardingPage(
            icon: "book.fill",
            title: "Understand Every Step",
            subtitle: "Learn the 'why' and 'how' with detailed explanations",
            features: [
                OnboardingFeature(icon: "list.number", text: "Step-by-step breakdowns"),
                OnboardingFeature(icon: "arrow.triangle.branch", text: "Alternative methods"),
                OnboardingFeature(icon: "globe", text: "Real-world examples")
            ],
            color: .blue
        ),
        OnboardingPage(
            icon: "trophy.fill",
            title: "Learn & Have Fun",
            subtitle: "Track your progress and challenge friends",
            features: [
                OnboardingFeature(icon: "flame.fill", text: "Build solving streaks"),
                OnboardingFeature(icon: "person.2.fill", text: "Challenge friends"),
                OnboardingFeature(icon: "star.fill", text: "Unlock achievements")
            ],
            color: .orange
        )
    ]
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage

    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -30
    @State private var featuresOpacity: Double = 0
    @State private var featureOffsets: [CGFloat] = [50, 50, 50]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                page.color.opacity(0.3),
                                page.color.opacity(0)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                // Icon background
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 120, height: 120)

                // Icon
                Image(systemName: page.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(page.color)
            }
            .scaleEffect(iconScale)
            .rotationEffect(.degrees(iconRotation))

            // Title
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.adaptivePrimaryText)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(Color.adaptiveSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Features
            VStack(spacing: 16) {
                ForEach(Array(page.features.enumerated()), id: \.element.id) { index, feature in
                    HStack(spacing: 12) {
                        Image(systemName: feature.icon)
                            .font(.title3)
                            .foregroundStyle(page.color)
                            .frame(width: 30)

                        Text(feature.text)
                            .font(.subheadline)
                            .foregroundStyle(Color.adaptivePrimaryText)

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .offset(x: index < featureOffsets.count ? featureOffsets[index] : 0)
                    .opacity(featuresOpacity)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .onAppear {
            animateIn()
        }
    }

    private func animateIn() {
        // Icon animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            iconScale = 1.0
            iconRotation = 0
        }

        // Features animation
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            featuresOpacity = 1.0
        }

        for index in featureOffsets.indices {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4 + Double(index) * 0.1)) {
                featureOffsets[index] = 0
            }
        }
    }
}

// MARK: - Language Selection (Optional first-time setup)
struct LanguageSelectionView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "globe")
                    .font(.system(size: 48))
                    .foregroundStyle(LemonMathColors.accent)

                Text("Choose Your Language")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("You can change this later in Settings")
                    .font(.subheadline)
                    .foregroundStyle(Color.adaptiveSecondaryText)
            }

            // Language options
            VStack(spacing: 12) {
                ForEach(SupportedLanguage.allCases) { language in
                    Button {
                        settingsManager.selectedLanguage = language
                        onComplete()
                    } label: {
                        HStack {
                            Text(language.flag)
                                .font(.title)

                            Text(language.displayName)
                                .font(.headline)
                                .foregroundStyle(Color.adaptivePrimaryText)

                            Spacer()

                            if settingsManager.selectedLanguage == language {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(LemonMathColors.accent)
                            }
                        }
                        .padding()
                        .background(
                            settingsManager.selectedLanguage == language
                                ? LemonMathColors.accent.opacity(0.1)
                                : Color.adaptiveCardBackground
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding(.top, 60)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
        .environmentObject(SettingsManager())
}
