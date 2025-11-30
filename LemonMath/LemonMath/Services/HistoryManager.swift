//
//  HistoryManager.swift
//  LemonMath
//

import Foundation
import SwiftUI
import Combine

// MARK: - History Manager
@MainActor
class HistoryManager: ObservableObject {
    @Published var problems: [MathProblem] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    @Published var selectedFilter: HistoryFilter = .all
    @Published var sortOrder: SortOrder = .newest

    private let storageKey = "mathProblemHistory"
    private let maxHistoryItems = 500

    var filteredProblems: [MathProblem] {
        var result = problems

        // Apply search filter
        if !searchQuery.isEmpty {
            result = result.filter { problem in
                problem.problemText.localizedCaseInsensitiveContains(searchQuery) ||
                problem.solution.localizedCaseInsensitiveContains(searchQuery) ||
                problem.problemType.displayName.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .type(let problemType):
            result = result.filter { $0.problemType == problemType }
        case .today:
            result = result.filter { Calendar.current.isDateInToday($0.createdAt) }
        case .thisWeek:
            result = result.filter {
                Calendar.current.isDate($0.createdAt, equalTo: Date(), toGranularity: .weekOfYear)
            }
        }

        // Apply sort order
        switch sortOrder {
        case .newest:
            result.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            result.sort { $0.createdAt < $1.createdAt }
        case .alphabetical:
            result.sort { $0.problemText < $1.problemText }
        case .mostShared:
            result.sort { $0.sharedCount > $1.sharedCount }
        }

        return result
    }

    var problemsByDate: [DateSection] {
        let grouped = Dictionary(grouping: filteredProblems) { problem in
            Calendar.current.startOfDay(for: problem.createdAt)
        }

        return grouped.map { DateSection(date: $0.key, problems: $0.value) }
            .sorted { $0.date > $1.date }
    }

    var totalProblemsSolved: Int {
        problems.count
    }

    var favoriteCount: Int {
        problems.filter { $0.isFavorite }.count
    }

    var problemTypeStats: [ProblemType: Int] {
        Dictionary(grouping: problems, by: { $0.problemType })
            .mapValues { $0.count }
    }

    var currentStreak: Int {
        calculateStreak()
    }

    // MARK: - Initialization

    init() {
        loadProblems()
    }

    // MARK: - Public Methods

    func addProblem(_ problem: MathProblem) {
        problems.insert(problem, at: 0)

        // Trim history if needed
        if problems.count > maxHistoryItems {
            problems = Array(problems.prefix(maxHistoryItems))
        }

        saveProblems()
    }

    func deleteProblem(_ problem: MathProblem) {
        problems.removeAll { $0.id == problem.id }
        saveProblems()
    }

    func deleteProblems(at offsets: IndexSet) {
        let problemsToDelete = offsets.map { filteredProblems[$0] }
        problems.removeAll { problem in
            problemsToDelete.contains { $0.id == problem.id }
        }
        saveProblems()
    }

    func toggleFavorite(_ problem: MathProblem) {
        if let index = problems.firstIndex(where: { $0.id == problem.id }) {
            problems[index].isFavorite.toggle()
            saveProblems()
        }
    }

    func updateNotes(for problem: MathProblem, notes: String) {
        if let index = problems.firstIndex(where: { $0.id == problem.id }) {
            problems[index].userNotes = notes.isEmpty ? nil : notes
            saveProblems()
        }
    }

    func incrementShareCount(for problem: MathProblem) {
        if let index = problems.firstIndex(where: { $0.id == problem.id }) {
            problems[index].sharedCount += 1
            saveProblems()
        }
    }

    func clearHistory() {
        problems.removeAll()
        saveProblems()
    }

    func exportHistory() -> Data? {
        try? JSONEncoder().encode(problems)
    }

    func importHistory(from data: Data) -> Bool {
        guard let imported = try? JSONDecoder().decode([MathProblem].self, from: data) else {
            return false
        }

        // Merge with existing, avoiding duplicates
        for problem in imported {
            if !problems.contains(where: { $0.id == problem.id }) {
                problems.append(problem)
            }
        }

        problems.sort { $0.createdAt > $1.createdAt }
        saveProblems()
        return true
    }

    // MARK: - Private Methods

    private func loadProblems() {
        isLoading = true
        defer { isLoading = false }

        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([MathProblem].self, from: data) else {
            return
        }

        problems = decoded
    }

    private func saveProblems() {
        guard let data = try? JSONEncoder().encode(problems) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func calculateStreak() -> Int {
        guard !problems.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedDates = Set(problems.map { calendar.startOfDay(for: $0.createdAt) })
            .sorted(by: >)

        guard let firstDate = sortedDates.first else { return 0 }

        // Check if the streak is current (includes today or yesterday)
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        guard firstDate >= yesterday else { return 0 }

        var streak = 1
        var previousDate = firstDate

        for date in sortedDates.dropFirst() {
            let expectedPreviousDay = calendar.date(byAdding: .day, value: -1, to: previousDate)!
            if date == expectedPreviousDay {
                streak += 1
                previousDate = date
            } else {
                break
            }
        }

        return streak
    }
}

// MARK: - Supporting Types

enum HistoryFilter: Equatable, Identifiable {
    case all
    case favorites
    case type(ProblemType)
    case today
    case thisWeek

    var id: String {
        switch self {
        case .all: return "all"
        case .favorites: return "favorites"
        case .type(let type): return "type_\(type.rawValue)"
        case .today: return "today"
        case .thisWeek: return "thisWeek"
        }
    }

    var displayName: String {
        switch self {
        case .all: return String(localized: "All")
        case .favorites: return String(localized: "Favorites")
        case .type(let type): return type.displayName
        case .today: return String(localized: "Today")
        case .thisWeek: return String(localized: "This Week")
        }
    }

    var icon: String {
        switch self {
        case .all: return "tray.full"
        case .favorites: return "heart.fill"
        case .type(let type): return type.icon
        case .today: return "sun.max"
        case .thisWeek: return "calendar"
        }
    }
}

enum SortOrder: String, CaseIterable, Identifiable {
    case newest
    case oldest
    case alphabetical
    case mostShared

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .newest: return String(localized: "Newest First")
        case .oldest: return String(localized: "Oldest First")
        case .alphabetical: return String(localized: "Alphabetical")
        case .mostShared: return String(localized: "Most Shared")
        }
    }

    var icon: String {
        switch self {
        case .newest: return "arrow.down.circle"
        case .oldest: return "arrow.up.circle"
        case .alphabetical: return "textformat.abc"
        case .mostShared: return "square.and.arrow.up"
        }
    }
}

struct DateSection: Identifiable {
    let id = UUID()
    let date: Date
    let problems: [MathProblem]

    var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return String(localized: "Today")
        } else if calendar.isDateInYesterday(date) {
            return String(localized: "Yesterday")
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}
