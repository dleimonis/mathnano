//
//  LemonMathApp.swift
//  LemonMath
//
//  A magical math problem solver with cute animations and helpful explanations
//

import SwiftUI

@main
struct LemonMathApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var achievementManager = AchievementManager()

    init() {
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(settingsManager)
                .environmentObject(historyManager)
                .environmentObject(achievementManager)
                .preferredColorScheme(settingsManager.colorScheme)
                .environment(\.locale, Locale(identifier: settingsManager.selectedLanguage.code))
        }
    }

    private func setupAppearance() {
        // Configure global UI appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(LemonMathColors.background)
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(LemonMathColors.primaryText)]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(LemonMathColors.primaryText)]

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(LemonMathColors.background)

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

// MARK: - App State
@MainActor
class AppState: ObservableObject {
    @Published var isOnboardingComplete: Bool {
        didSet {
            UserDefaults.standard.set(isOnboardingComplete, forKey: "isOnboardingComplete")
        }
    }
    @Published var currentTab: AppTab = .home
    @Published var isProcessing = false
    @Published var currentProblem: MathProblem?
    @Published var showAchievementUnlock: Achievement?

    init() {
        self.isOnboardingComplete = UserDefaults.standard.bool(forKey: "isOnboardingComplete")
    }
}

enum AppTab: String, CaseIterable {
    case home
    case history
    case settings

    var title: String {
        switch self {
        case .home: return String(localized: "Home")
        case .history: return String(localized: "History")
        case .settings: return String(localized: "Settings")
        }
    }

    var icon: String {
        switch self {
        case .home: return "wand.and.stars"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape.fill"
        }
    }
}
