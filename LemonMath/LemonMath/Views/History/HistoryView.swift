//
//  HistoryView.swift
//  LemonMath
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var historyManager: HistoryManager
    @EnvironmentObject var settingsManager: SettingsManager

    @State private var showFilterSheet = false
    @State private var showSortSheet = false
    @State private var selectedProblem: MathProblem?
    @State private var showDeleteConfirmation = false
    @State private var problemToDelete: MathProblem?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()

                if historyManager.problems.isEmpty {
                    emptyState
                } else {
                    problemsList
                }
            }
            .navigationTitle("History")
            .searchable(
                text: $historyManager.searchQuery,
                prompt: "Search problems..."
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        // Filter button
                        Menu {
                            filterMenu
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundStyle(
                                    historyManager.selectedFilter == .all
                                        ? Color.adaptiveSecondaryText
                                        : LemonMathColors.accent
                                )
                        }

                        // Sort button
                        Menu {
                            sortMenu
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundStyle(Color.adaptiveSecondaryText)
                        }
                    }
                }
            }
            .sheet(item: $selectedProblem) { problem in
                SolutionView(problem: problem) {
                    selectedProblem = nil
                }
            }
            .alert("Delete Problem", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let problem = problemToDelete {
                        historyManager.deleteProblem(problem)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this problem from your history?")
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 24) {
            MiniMascotView(size: 80)

            Text("No History Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.adaptivePrimaryText)

            Text("Solve your first problem and it will appear here!")
                .font(.body)
                .foregroundStyle(Color.adaptiveSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Quick stats
            HStack(spacing: 24) {
                VStack {
                    Text("0")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(LemonMathColors.accent)
                    Text("Solved")
                        .font(.caption)
                        .foregroundStyle(Color.adaptiveSecondaryText)
                }

                VStack {
                    Text("0")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                    Text("Day Streak")
                        .font(.caption)
                        .foregroundStyle(Color.adaptiveSecondaryText)
                }
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Problems List
    private var problemsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Stats header
                statsHeader

                // Active filter indicator
                if historyManager.selectedFilter != .all {
                    filterIndicator
                }

                // Problems grouped by date
                ForEach(historyManager.problemsByDate) { section in
                    Section {
                        ForEach(section.problems) { problem in
                            ProblemHistoryCard(
                                problem: problem,
                                onTap: {
                                    selectedProblem = problem
                                },
                                onFavorite: {
                                    historyManager.toggleFavorite(problem)
                                    settingsManager.triggerHapticFeedback(.light)
                                },
                                onDelete: {
                                    problemToDelete = problem
                                    showDeleteConfirmation = true
                                }
                            )
                        }
                    } header: {
                        HStack {
                            Text(section.formattedDate)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.adaptiveSecondaryText)

                            Spacer()

                            Text("\(section.problems.count) problem\(section.problems.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(Color.adaptiveSecondaryText.opacity(0.7))
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Stats Header
    private var statsHeader: some View {
        HStack(spacing: 16) {
            StatBadge(
                value: "\(historyManager.totalProblemsSolved)",
                label: "Total",
                icon: "checkmark.circle.fill",
                color: LemonMathColors.accent
            )

            StatBadge(
                value: "\(historyManager.currentStreak)",
                label: "Streak",
                icon: "flame.fill",
                color: .orange
            )

            StatBadge(
                value: "\(historyManager.favoriteCount)",
                label: "Favorites",
                icon: "heart.fill",
                color: .red
            )
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Filter Indicator
    private var filterIndicator: some View {
        HStack {
            Image(systemName: historyManager.selectedFilter.icon)
                .foregroundStyle(LemonMathColors.accent)

            Text("Filtered: \(historyManager.selectedFilter.displayName)")
                .font(.subheadline)
                .foregroundStyle(Color.adaptivePrimaryText)

            Spacer()

            Button {
                historyManager.selectedFilter = .all
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.adaptiveSecondaryText)
            }
        }
        .padding()
        .background(LemonMathColors.accent.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Filter Menu
    @ViewBuilder
    private var filterMenu: some View {
        Section("Time") {
            Button {
                historyManager.selectedFilter = .all
            } label: {
                Label("All Problems", systemImage: "tray.full")
            }

            Button {
                historyManager.selectedFilter = .today
            } label: {
                Label("Today", systemImage: "sun.max")
            }

            Button {
                historyManager.selectedFilter = .thisWeek
            } label: {
                Label("This Week", systemImage: "calendar")
            }
        }

        Section("Special") {
            Button {
                historyManager.selectedFilter = .favorites
            } label: {
                Label("Favorites", systemImage: "heart.fill")
            }
        }

        Section("Problem Type") {
            ForEach(ProblemType.allCases, id: \.self) { type in
                Button {
                    historyManager.selectedFilter = .type(type)
                } label: {
                    Label(type.displayName, systemImage: type.icon)
                }
            }
        }
    }

    // MARK: - Sort Menu
    @ViewBuilder
    private var sortMenu: some View {
        ForEach(SortOrder.allCases) { order in
            Button {
                historyManager.sortOrder = order
            } label: {
                HStack {
                    Label(order.displayName, systemImage: order.icon)
                    if historyManager.sortOrder == order {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.adaptivePrimaryText)

            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.adaptiveSecondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Problem History Card
struct ProblemHistoryCard: View {
    let problem: MathProblem
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Thumbnail or type icon
                ZStack {
                    if let image = problem.originalImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(problem.problemType.color.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: problem.problemType.icon)
                                    .font(.title2)
                                    .foregroundStyle(problem.problemType.color)
                            )
                    }
                }

                // Problem info
                VStack(alignment: .leading, spacing: 6) {
                    Text(problem.problemText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.adaptivePrimaryText)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text(problem.problemType.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(problem.problemType.color.opacity(0.2))
                            .foregroundStyle(problem.problemType.color)
                            .clipShape(Capsule())

                        Text(problem.formattedDate)
                            .font(.caption)
                            .foregroundStyle(Color.adaptiveSecondaryText)
                    }

                    // Answer preview
                    Text("= \(problem.solution)")
                        .font(.caption)
                        .foregroundStyle(LemonMathColors.accent)
                }

                Spacer()

                // Actions
                VStack(spacing: 8) {
                    Button(action: onFavorite) {
                        Image(systemName: problem.isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(problem.isFavorite ? .red : Color.adaptiveSecondaryText)
                    }

                    if problem.sharedCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption2)
                            Text("\(problem.sharedCount)")
                                .font(.caption2)
                        }
                        .foregroundStyle(Color.adaptiveSecondaryText)
                    }
                }
            }
            .padding()
            .background(Color.adaptiveCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onFavorite()
            } label: {
                Label(
                    problem.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: problem.isFavorite ? "heart.slash" : "heart"
                )
            }

            Button {
                // Share
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                onFavorite()
            } label: {
                Label(
                    problem.isFavorite ? "Unfavorite" : "Favorite",
                    systemImage: problem.isFavorite ? "heart.slash" : "heart"
                )
            }
            .tint(problem.isFavorite ? .gray : .red)
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(HistoryManager())
        .environmentObject(SettingsManager())
        .environmentObject(AchievementManager())
}
