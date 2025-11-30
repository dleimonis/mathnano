//
//  ContentView.swift
//  LemonMath
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var achievementManager: AchievementManager

    var body: some View {
        Group {
            if !appState.isOnboardingComplete {
                OnboardingView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isOnboardingComplete)
        .overlay {
            // Achievement unlock overlay
            if let achievement = appState.showAchievementUnlock {
                AchievementUnlockView(achievement: achievement) {
                    withAnimation {
                        appState.showAchievementUnlock = nil
                    }
                }
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsManager: SettingsManager

    @AppStorage("hasSeenScanningTutorial") private var hasSeenScanningTutorial = false
    @State private var showTutorial = false

    var body: some View {
        TabView(selection: $appState.currentTab) {
            HomeView()
                .tabItem {
                    Label(AppTab.home.title, systemImage: AppTab.home.icon)
                }
                .tag(AppTab.home)

            HistoryView()
                .tabItem {
                    Label(AppTab.history.title, systemImage: AppTab.history.icon)
                }
                .tag(AppTab.history)

            SettingsView()
                .tabItem {
                    Label(AppTab.settings.title, systemImage: AppTab.settings.icon)
                }
                .tag(AppTab.settings)
        }
        .tint(LemonMathColors.accent)
        .onAppear {
            setupTabBarAppearance()
            // Show tutorial for first-time users after a brief delay
            if !hasSeenScanningTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showTutorial = true
                }
            }
        }
        .fullScreenCover(isPresented: $showTutorial) {
            InteractiveTutorialView {
                hasSeenScanningTutorial = true
            }
            .environmentObject(settingsManager)
        }
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(LemonMathColors.cardBackground)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(SettingsManager())
        .environmentObject(HistoryManager())
        .environmentObject(AchievementManager())
}
