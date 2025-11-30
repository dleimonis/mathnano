//
//  HomeView.swift
//  LemonMath
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var historyManager: HistoryManager
    @EnvironmentObject var achievementManager: AchievementManager

    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var mascotBounce = false
    @State private var showTip = true
    @State private var currentTipIndex = 0

    private let tips = [
        "Tip: Write clearly for best results!",
        "Tip: Works with algebra, geometry, and calculus!",
        "Tip: Tap the mascot for a surprise!",
        "Tip: Share solutions with friends!",
        "Tip: Check history to revisit problems!"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        LemonMathColors.lemonLight.opacity(0.3),
                        Color.adaptiveBackground
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header with mascot
                        headerSection

                        // Quick stats
                        statsSection

                        // Main scan button
                        scanButtonSection

                        // Recent problems
                        recentProblemsSection

                        // Tips section
                        tipsSection

                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Lemon Math")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Show achievements
                    } label: {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(LemonMathColors.lemonDark)
                    }
                    .accessibilityLabel("Achievements")
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraScannerView()
            }
            .sheet(isPresented: $showPhotoLibrary) {
                PhotoLibraryPicker { image in
                    handleSelectedImage(image)
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Mascot
            MascotView(isAnimating: $mascotBounce)
                .frame(width: 120, height: 120)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        mascotBounce.toggle()
                    }
                    settingsManager.triggerHapticFeedback(.light)
                }

            Text("Ready to solve some math?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.adaptivePrimaryText)
                .multilineTextAlignment(.center)

            Text("Take a photo of any math problem and watch the magic happen!")
                .font(.subheadline)
                .foregroundStyle(Color.adaptiveSecondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Lemon Math mascot. Ready to solve math problems. Take a photo of any math problem and watch the magic happen.")
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Solved",
                value: "\(historyManager.totalProblemsSolved)",
                icon: "checkmark.circle.fill",
                color: LemonMathColors.success
            )

            StatCard(
                title: "Streak",
                value: "\(historyManager.currentStreak)",
                icon: "flame.fill",
                color: .orange
            )

            StatCard(
                title: "Badges",
                value: "\(achievementManager.unlockedCount)",
                icon: "trophy.fill",
                color: LemonMathColors.lemonDark
            )
        }
    }

    // MARK: - Scan Button Section
    private var scanButtonSection: some View {
        VStack(spacing: 16) {
            // Main scan button
            Button {
                showCamera = true
                settingsManager.triggerHapticFeedback(.medium)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.title2)

                    Text("Scan Problem")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(
                        colors: [LemonMathColors.accent, LemonMathColors.accentDark],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: LemonMathColors.accent.opacity(0.4), radius: 8, y: 4)
            }
            .accessibilityLabel("Scan Problem")
            .accessibilityHint("Opens camera to capture a math problem")

            // Secondary options
            HStack(spacing: 12) {
                SecondaryButton(
                    title: "Photo Library",
                    icon: "photo.on.rectangle",
                    action: {
                        showPhotoLibrary = true
                        settingsManager.triggerHapticFeedback(.light)
                    }
                )

                SecondaryButton(
                    title: "Type Problem",
                    icon: "keyboard",
                    action: {
                        // Navigate to text input
                        settingsManager.triggerHapticFeedback(.light)
                    }
                )
            }
        }
    }

    // MARK: - Recent Problems Section
    private var recentProblemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Problems")
                    .font(.headline)
                    .foregroundStyle(Color.adaptivePrimaryText)

                Spacer()

                if !historyManager.problems.isEmpty {
                    Button("See All") {
                        appState.currentTab = .history
                    }
                    .font(.subheadline)
                    .foregroundStyle(LemonMathColors.accent)
                }
            }

            if historyManager.problems.isEmpty {
                EmptyStateCard(
                    icon: "doc.text.magnifyingglass",
                    title: "No problems yet",
                    subtitle: "Scan your first math problem to get started!"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(historyManager.problems.prefix(3)) { problem in
                        RecentProblemCard(problem: problem)
                    }
                }
            }
        }
    }

    // MARK: - Tips Section
    private var tipsSection: some View {
        VStack(spacing: 8) {
            if showTip {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(LemonMathColors.lemonDark)

                    Text(tips[currentTipIndex])
                        .font(.subheadline)
                        .foregroundStyle(Color.adaptiveSecondaryText)

                    Spacer()

                    Button {
                        withAnimation {
                            currentTipIndex = (currentTipIndex + 1) % tips.count
                        }
                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(LemonMathColors.accent)
                    }
                }
                .padding()
                .background(Color.adaptiveCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Methods

    private func handleSelectedImage(_ image: UIImage) {
        // Process the selected image
        showPhotoLibrary = false
        // Navigate to processing view
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.adaptivePrimaryText)

            Text(title)
                .font(.caption)
                .foregroundStyle(Color.adaptiveSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct SecondaryButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(LemonMathColors.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.adaptiveCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LemonMathColors.accent.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(Color.adaptiveSecondaryText.opacity(0.5))

            Text(title)
                .font(.headline)
                .foregroundStyle(Color.adaptivePrimaryText)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.adaptiveSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RecentProblemCard: View {
    let problem: MathProblem

    var body: some View {
        HStack(spacing: 12) {
            // Problem type icon
            ZStack {
                Circle()
                    .fill(problem.problemType.color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: problem.problemType.icon)
                    .font(.title3)
                    .foregroundStyle(problem.problemType.color)
            }

            // Problem info
            VStack(alignment: .leading, spacing: 4) {
                Text(problem.problemText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.adaptivePrimaryText)
                    .lineLimit(1)

                Text(problem.formattedDate)
                    .font(.caption)
                    .foregroundStyle(Color.adaptiveSecondaryText)
            }

            Spacer()

            // Favorite indicator
            if problem.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
            }

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
    HomeView()
        .environmentObject(AppState())
        .environmentObject(SettingsManager())
        .environmentObject(HistoryManager())
        .environmentObject(AchievementManager())
}
