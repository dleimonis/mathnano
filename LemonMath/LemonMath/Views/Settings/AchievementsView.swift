//
//  AchievementsView.swift
//  LemonMath
//

import SwiftUI

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var achievementManager: AchievementManager
    @EnvironmentObject var settingsManager: SettingsManager

    @State private var selectedCategory: AchievementCategory?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Overall progress
                    progressHeader

                    // Category filter
                    categoryFilter

                    // Achievements list
                    achievementsList
                }
                .padding()
            }
            .background(Color.adaptiveBackground)
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.adaptiveSecondaryText)
                    }
                }
            }
        }
    }

    // MARK: - Progress Header
    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Trophy icon
            ZStack {
                Circle()
                    .fill(LemonMathColors.lemonYellow.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(LemonMathColors.lemonDark)
            }

            // Progress text
            VStack(spacing: 4) {
                Text("\(achievementManager.unlockedCount) of \(achievementManager.totalCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.adaptivePrimaryText)

                Text("Achievements Unlocked")
                    .font(.subheadline)
                    .foregroundStyle(Color.adaptiveSecondaryText)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.adaptiveSecondaryText.opacity(0.2))
                        .frame(height: 8)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [LemonMathColors.lemonYellow, LemonMathColors.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * achievementManager.progressPercentage, height: 8)
                }
            }
            .frame(height: 8)

            Text("\(Int(achievementManager.progressPercentage * 100))% Complete")
                .font(.caption)
                .foregroundStyle(Color.adaptiveSecondaryText)
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    title: "All",
                    icon: "square.grid.2x2",
                    color: LemonMathColors.accent,
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation {
                        selectedCategory = nil
                    }
                }

                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.displayName,
                        icon: categoryIcon(for: category),
                        color: category.color,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }

    private func categoryIcon(for category: AchievementCategory) -> String {
        switch category {
        case .problemsSolved: return "checkmark.circle"
        case .streaks: return "flame"
        case .sharing: return "square.and.arrow.up"
        case .exploration: return "map"
        case .mastery: return "star"
        }
    }

    // MARK: - Achievements List
    private var achievementsList: some View {
        let filteredAchievements = selectedCategory == nil
            ? achievementManager.achievements
            : achievementManager.achievements.filter { $0.category == selectedCategory }

        return LazyVStack(spacing: 12) {
            ForEach(filteredAchievements, id: \.id) { achievement in
                AchievementCard(achievement: achievement)
            }
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
            }
            .foregroundStyle(isSelected ? .white : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? color : color.opacity(0.1))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement
    @State private var showDetails = false

    var body: some View {
        Button {
            withAnimation {
                showDetails.toggle()
            }
        } label: {
            VStack(spacing: 0) {
                // Main card content
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(achievement.isUnlocked
                                ? achievement.category.color.opacity(0.2)
                                : Color.gray.opacity(0.1))
                            .frame(width: 56, height: 56)

                        if achievement.isUnlocked {
                            Image(systemName: achievement.icon)
                                .font(.title2)
                                .foregroundStyle(achievement.category.color)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.title3)
                                .foregroundStyle(.gray)
                        }
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(achievement.title)
                            .font(.headline)
                            .foregroundStyle(achievement.isUnlocked
                                ? Color.adaptivePrimaryText
                                : Color.adaptiveSecondaryText)

                        Text(achievement.description)
                            .font(.subheadline)
                            .foregroundStyle(Color.adaptiveSecondaryText)
                            .lineLimit(showDetails ? nil : 1)
                    }

                    Spacer()

                    // Progress or checkmark
                    if achievement.isUnlocked {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundStyle(achievement.category.color)
                    } else {
                        VStack(spacing: 2) {
                            Text("\(achievement.progress)")
                                .font(.headline)
                                .foregroundStyle(achievement.category.color)
                            Text("/\(achievement.requirement)")
                                .font(.caption)
                                .foregroundStyle(Color.adaptiveSecondaryText)
                        }
                    }
                }
                .padding()

                // Progress bar for locked achievements
                if !achievement.isUnlocked {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 4)

                            Rectangle()
                                .fill(achievement.category.color)
                                .frame(width: geometry.size.width * achievement.progressPercentage, height: 4)
                        }
                    }
                    .frame(height: 4)
                }

                // Expanded details
                if showDetails && achievement.isUnlocked, let unlockedAt = achievement.unlockedAt {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()

                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(Color.adaptiveSecondaryText)

                            Text("Unlocked on \(unlockedAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(Color.adaptiveSecondaryText)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .background(Color.adaptiveCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        achievement.isUnlocked
                            ? achievement.category.color.opacity(0.3)
                            : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Achievement Unlock View (Overlay)
struct AchievementUnlockView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var sparkleRotation: Double = 0

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Achievement card
            VStack(spacing: 24) {
                // Sparkles around trophy
                ZStack {
                    ForEach(0..<8) { i in
                        Image(systemName: "sparkle")
                            .font(.title)
                            .foregroundStyle(.yellow)
                            .offset(y: -70)
                            .rotationEffect(.degrees(Double(i) * 45 + sparkleRotation))
                    }

                    // Trophy with glow
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        achievement.category.color.opacity(0.5),
                                        achievement.category.color.opacity(0)
                                    ],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)

                        Circle()
                            .fill(achievement.category.color.opacity(0.2))
                            .frame(width: 100, height: 100)

                        Image(systemName: achievement.icon)
                            .font(.system(size: 44))
                            .foregroundStyle(achievement.category.color)
                    }
                }

                // Title
                Text("Achievement Unlocked!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                // Achievement info
                VStack(spacing: 8) {
                    Text(achievement.title)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(achievement.description)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                // Dismiss button
                Button {
                    onDismiss()
                } label: {
                    Text("Awesome!")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(achievement.category.color)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "2C2C2E"))
            )
            .padding(24)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }

            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
        }
    }
}

#Preview {
    AchievementsView()
        .environmentObject(AchievementManager())
        .environmentObject(SettingsManager())
}
