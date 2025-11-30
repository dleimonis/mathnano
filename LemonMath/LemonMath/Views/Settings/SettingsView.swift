//
//  SettingsView.swift
//  LemonMath
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var historyManager: HistoryManager
    @EnvironmentObject var achievementManager: AchievementManager

    @State private var showLanguagePicker = false
    @State private var showResetConfirmation = false
    @State private var showClearHistoryConfirmation = false
    @State private var showAchievements = false
    @State private var showTutorial = false
    @State private var showAdminDashboard = false
    @State private var showAPIKeySheet = false
    @State private var showPrivacyPolicy = false
    @State private var themeTransitionProgress: CGFloat = 0

    @StateObject private var usageManager = APIUsageManager.shared
    @AppStorage("geminiAPIKey") private var storedAPIKey = ""
    @AppStorage("adminAPIKey") private var storedAdminKey = ""

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background for theme transition
                ThemeTransitionBackground(isDarkMode: settingsManager.isDarkMode)

                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Profile / Stats section
                        profileSection

                        // Usage quota section
                        usageQuotaSection

                        // API Configuration section
                        apiConfigSection

                        // Appearance section
                        appearanceSection

                        // Accessibility section
                        accessibilitySection

                        // Language section
                        languageSection

                        // Privacy section
                        privacySection

                        // Data section
                        dataSection

                        // About section
                        aboutSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAchievements) {
                AchievementsView()
            }
            .sheet(isPresented: $showAdminDashboard) {
                AdminDashboardView()
                    .environmentObject(settingsManager)
            }
            .sheet(isPresented: $showAPIKeySheet) {
                APIKeyConfigView(apiKey: $storedAPIKey)
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .fullScreenCover(isPresented: $showTutorial) {
                InteractiveTutorialView {
                    // Tutorial completed
                }
                .environmentObject(settingsManager)
            }
            .alert("Reset Settings", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    settingsManager.resetToDefaults()
                }
            } message: {
                Text("This will reset all settings to their default values.")
            }
            .alert("Clear History", isPresented: $showClearHistoryConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    historyManager.clearHistory()
                }
            } message: {
                Text("This will permanently delete all your problem history.")
            }
        }
    }

    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(spacing: 16) {
            // Stats overview
            HStack(spacing: 20) {
                StatCircle(
                    value: historyManager.totalProblemsSolved,
                    label: "Solved",
                    color: LemonMathColors.accent
                )

                StatCircle(
                    value: historyManager.currentStreak,
                    label: "Day Streak",
                    color: .orange
                )

                StatCircle(
                    value: achievementManager.unlockedCount,
                    label: "Badges",
                    color: .purple
                )
            }

            // View achievements button
            Button {
                showAchievements = true
            } label: {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)

                    Text("View All Achievements")
                        .foregroundStyle(Color.adaptivePrimaryText)

                    Spacer()

                    Text("\(achievementManager.unlockedCount)/\(achievementManager.totalCount)")
                        .font(.subheadline)
                        .foregroundStyle(Color.adaptiveSecondaryText)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.adaptiveSecondaryText)
                }
                .padding()
                .background(Color.adaptiveCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Usage Quota Section
    private var usageQuotaSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("API Usage")
                    .font(.headline)
                    .foregroundStyle(Color.adaptivePrimaryText)

                Spacer()

                // Tier badge
                Text(usageManager.userQuota.tier.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(usageManager.userQuota.tier.color)
                    .clipShape(Capsule())
            }

            // Daily usage bar
            let remaining = usageManager.getRemainingQuota()

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Today")
                        .font(.subheadline)
                        .foregroundStyle(Color.adaptiveSecondaryText)
                    Spacer()
                    Text("\(remaining.dailyRemaining) left")
                        .font(.subheadline)
                        .foregroundStyle(remaining.dailyRemaining < 5 ? .red : Color.adaptivePrimaryText)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(remaining.dailyPercentUsed > 0.9 ? Color.red : LemonMathColors.accent)
                            .frame(width: geometry.size.width * remaining.dailyPercentUsed)
                    }
                }
                .frame(height: 8)
            }

            // Admin dashboard button (only shows if admin has previously authenticated)
            if !storedAdminKey.isEmpty {
                Button {
                    showAdminDashboard = true
                } label: {
                    HStack {
                        Image(systemName: "gearshape.2.fill")
                            .foregroundStyle(.purple)

                        Text("Admin Dashboard")
                            .foregroundStyle(Color.adaptivePrimaryText)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.adaptiveSecondaryText)
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - API Configuration Section
    private var apiConfigSection: some View {
        SettingsSection(title: "API Configuration", icon: "key.fill") {
            Button {
                showAPIKeySheet = true
            } label: {
                HStack {
                    Image(systemName: storedAPIKey.isEmpty ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(storedAPIKey.isEmpty ? .orange : .green)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gemini API Key")
                            .foregroundStyle(Color.adaptivePrimaryText)

                        Text(storedAPIKey.isEmpty ? "Not configured" : "Key configured")
                            .font(.caption)
                            .foregroundStyle(Color.adaptiveSecondaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.adaptiveSecondaryText)
                }
                .padding()
            }

            if storedAPIKey.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)

                    Text("Get your free API key from Google AI Studio")
                        .font(.caption)
                        .foregroundStyle(Color.adaptiveSecondaryText)
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Appearance Section
    private var appearanceSection: some View {
        SettingsSection(title: "Appearance", icon: "paintbrush.fill") {
            // Theme toggle with animation
            AnimatedThemeToggle(
                isDarkMode: $settingsManager.isDarkMode,
                useSystemAppearance: $settingsManager.useSystemAppearance
            )

            SettingsRow(icon: "circle.lefthalf.filled", title: "Use System Appearance") {
                Toggle("", isOn: $settingsManager.useSystemAppearance)
                    .labelsHidden()
                    .tint(LemonMathColors.accent)
            }

            SettingsRow(icon: "hare.fill", title: "Animation Speed") {
                Picker("", selection: $settingsManager.animationSpeed) {
                    ForEach(AnimationSpeed.allCases) { speed in
                        Text(speed.displayName).tag(speed)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
        }
    }

    // MARK: - Accessibility Section
    private var accessibilitySection: some View {
        SettingsSection(title: "Accessibility", icon: "accessibility") {
            SettingsRow(icon: "textformat.size", title: "Large Text") {
                Toggle("", isOn: $settingsManager.useLargeText)
                    .labelsHidden()
                    .tint(LemonMathColors.accent)
            }

            if settingsManager.useLargeText {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text Size")
                        .font(.subheadline)
                        .foregroundStyle(Color.adaptiveSecondaryText)

                    HStack {
                        Text("A")
                            .font(.caption)
                        Slider(value: $settingsManager.textSizeMultiplier, in: 1.0...1.5, step: 0.1)
                            .tint(LemonMathColors.accent)
                        Text("A")
                            .font(.title3)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            SettingsRow(icon: "speaker.wave.2.fill", title: "Voice Guidance") {
                Toggle("", isOn: $settingsManager.isVoiceGuidanceEnabled)
                    .labelsHidden()
                    .tint(LemonMathColors.accent)
            }

            SettingsRow(icon: "iphone.radiowaves.left.and.right", title: "Haptic Feedback") {
                Toggle("", isOn: $settingsManager.isHapticFeedbackEnabled)
                    .labelsHidden()
                    .tint(LemonMathColors.accent)
            }
        }
    }

    // MARK: - Language Section
    private var languageSection: some View {
        SettingsSection(title: "Language", icon: "globe") {
            ForEach(SupportedLanguage.allCases) { language in
                Button {
                    withAnimation {
                        settingsManager.selectedLanguage = language
                    }
                    settingsManager.triggerHapticFeedback(.light)
                } label: {
                    HStack {
                        Text(language.flag)
                            .font(.title2)

                        Text(language.displayName)
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
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Privacy Section
    private var privacySection: some View {
        SettingsSection(title: "Privacy", icon: "lock.shield.fill") {
            SettingsRow(icon: "icloud.slash", title: "Offline Mode") {
                Toggle("", isOn: $settingsManager.isOfflineModeEnabled)
                    .labelsHidden()
                    .tint(LemonMathColors.accent)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Privacy Level")
                    .font(.subheadline)
                    .foregroundStyle(Color.adaptiveSecondaryText)

                Picker("", selection: $settingsManager.privacyMode) {
                    ForEach(PrivacyMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text(settingsManager.privacyMode.description)
                    .font(.caption)
                    .foregroundStyle(Color.adaptiveSecondaryText)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Data Section
    private var dataSection: some View {
        SettingsSection(title: "Data", icon: "externaldrive.fill") {
            SettingsRow(icon: "square.and.arrow.down", title: "Auto-save Problems") {
                Toggle("", isOn: $settingsManager.autoSaveProblems)
                    .labelsHidden()
                    .tint(LemonMathColors.accent)
            }

            Button {
                // Export history
            } label: {
                SettingsRowButton(
                    icon: "square.and.arrow.up",
                    title: "Export History",
                    color: .blue
                )
            }

            Button {
                showClearHistoryConfirmation = true
            } label: {
                SettingsRowButton(
                    icon: "trash",
                    title: "Clear History",
                    color: .red
                )
            }

            Button {
                showResetConfirmation = true
            } label: {
                SettingsRowButton(
                    icon: "arrow.counterclockwise",
                    title: "Reset All Settings",
                    color: .orange
                )
            }
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle.fill") {
            // Replay Tutorial button
            Button {
                showTutorial = true
            } label: {
                SettingsRowButton(
                    icon: "play.circle.fill",
                    title: "Replay Tutorial",
                    color: LemonMathColors.accent
                )
            }

            SettingsRow(icon: "number", title: "Version") {
                Text("1.0.0")
                    .foregroundStyle(Color.adaptiveSecondaryText)
            }
            .onLongPressGesture(minimumDuration: 3) {
                // Secret access to admin dashboard for initial setup
                // Long press version for 3 seconds to access
                showAdminDashboard = true
            }

            Button {
                // Rate app
            } label: {
                SettingsRowButton(
                    icon: "star.fill",
                    title: "Rate Lemon Math",
                    color: .yellow
                )
            }

            Button {
                // Feedback
            } label: {
                SettingsRowButton(
                    icon: "envelope.fill",
                    title: "Send Feedback",
                    color: LemonMathColors.accent
                )
            }

            Button {
                showPrivacyPolicy = true
            } label: {
                SettingsRowButton(
                    icon: "doc.text.fill",
                    title: "Privacy Policy",
                    color: .gray
                )
            }
        }
    }
}

// MARK: - API Key Configuration View
struct APIKeyConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var apiKey: String
    @State private var inputKey = ""
    @State private var showKey = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(LemonMathColors.accent)

                        Text("Gemini API Key")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Enter your Google Gemini API key to enable AI-powered math solving.")
                            .font(.subheadline)
                            .foregroundStyle(Color.adaptiveSecondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // API Key Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack {
                            if showKey {
                                TextField("Enter your API key", text: $inputKey)
                                    .textContentType(.password)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .focused($isInputFocused)
                            } else {
                                SecureField("Enter your API key", text: $inputKey)
                                    .textContentType(.password)
                                    .focused($isInputFocused)
                            }

                            Button {
                                showKey.toggle()
                            } label: {
                                Image(systemName: showKey ? "eye.slash" : "eye")
                                    .foregroundStyle(Color.adaptiveSecondaryText)
                            }
                        }
                        .padding()
                        .background(Color.adaptiveCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isInputFocused ? LemonMathColors.accent : Color.clear, lineWidth: 2)
                        )
                    }

                    // Instructions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How to get your API key:")
                            .font(.headline)

                        InstructionRow(number: 1, text: "Go to Google AI Studio")
                        InstructionRow(number: 2, text: "Sign in with your Google account")
                        InstructionRow(number: 3, text: "Click \"Get API Key\" in the left menu")
                        InstructionRow(number: 4, text: "Create a new API key or copy existing one")
                        InstructionRow(number: 5, text: "Paste the key above")

                        Link(destination: URL(string: "https://aistudio.google.com/apikey")!) {
                            HStack {
                                Image(systemName: "safari")
                                Text("Open Google AI Studio")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                    .background(Color.adaptiveCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Pricing info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "dollarsign.circle")
                                .foregroundStyle(.green)
                            Text("Free Tier Available")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Text("Google offers a free tier with 15 requests/minute. Perfect for personal use!")
                            .font(.caption)
                            .foregroundStyle(Color.adaptiveSecondaryText)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("API Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        apiKey = inputKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(inputKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            inputKey = apiKey
        }
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(LemonMathColors.accent)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.adaptivePrimaryText)
        }
    }
}

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Last updated: November 2025")
                        .font(.caption)
                        .foregroundStyle(Color.adaptiveSecondaryText)

                    PolicySection(title: "Introduction") {
                        Text("Lemon Math (\"the App\") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.")
                    }

                    PolicySection(title: "Information We Collect") {
                        VStack(alignment: .leading, spacing: 12) {
                            PolicyBullet(text: "Images: Photos of math problems you scan are sent to Google's Gemini AI for analysis. Images are not stored on our servers.")
                            PolicyBullet(text: "Usage Data: We collect anonymous usage statistics to improve the app experience.")
                            PolicyBullet(text: "API Key: If you provide your own Gemini API key, it is stored locally on your device.")
                            PolicyBullet(text: "Problem History: Solved problems are stored locally on your device for your convenience.")
                        }
                    }

                    PolicySection(title: "How We Use Your Information") {
                        VStack(alignment: .leading, spacing: 12) {
                            PolicyBullet(text: "To provide math problem solving services")
                            PolicyBullet(text: "To display your problem history")
                            PolicyBullet(text: "To improve app functionality")
                            PolicyBullet(text: "To provide step-by-step explanations")
                        }
                    }

                    PolicySection(title: "Third-Party Services") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("The App uses Google Gemini AI to analyze math problems. When you scan a problem:")
                                .foregroundStyle(Color.adaptivePrimaryText)
                            PolicyBullet(text: "Your image is sent to Google's servers for processing")
                            PolicyBullet(text: "Google's privacy policy applies to this data")
                            PolicyBullet(text: "We recommend reviewing Google's AI privacy practices")

                            Link(destination: URL(string: "https://ai.google.dev/gemini-api/terms")!) {
                                Text("View Google Gemini API Terms")
                                    .font(.subheadline)
                                    .foregroundStyle(LemonMathColors.accent)
                            }
                        }
                    }

                    PolicySection(title: "Data Storage") {
                        VStack(alignment: .leading, spacing: 12) {
                            PolicyBullet(text: "All problem history is stored locally on your device")
                            PolicyBullet(text: "Your API key is stored securely in the app's local storage")
                            PolicyBullet(text: "We do not maintain external servers for user data")
                            PolicyBullet(text: "Deleting the app removes all locally stored data")
                        }
                    }

                    PolicySection(title: "Your Rights") {
                        VStack(alignment: .leading, spacing: 12) {
                            PolicyBullet(text: "Delete your problem history at any time in Settings")
                            PolicyBullet(text: "Remove your API key at any time")
                            PolicyBullet(text: "Use offline mode to prevent data transmission")
                            PolicyBullet(text: "Request information about your data by contacting us")
                        }
                    }

                    PolicySection(title: "Children's Privacy") {
                        Text("The App is designed to be educational and safe for users of all ages. We do not knowingly collect personal information from children under 13 without parental consent.")
                    }

                    PolicySection(title: "Changes to This Policy") {
                        Text("We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy in the app with an updated date.")
                    }

                    PolicySection(title: "Contact Us") {
                        Text("If you have questions about this Privacy Policy, please contact us at: support@lemonmath.app")
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PolicySection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.adaptivePrimaryText)

            content()
                .font(.subheadline)
                .foregroundStyle(Color.adaptiveSecondaryText)
        }
    }
}

struct PolicyBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(LemonMathColors.accent)
            Text(text)
        }
    }
}

// MARK: - Theme Transition Background
struct ThemeTransitionBackground: View {
    let isDarkMode: Bool
    @State private var animationProgress: CGFloat = 0

    var body: some View {
        ZStack {
            // Light mode background
            Color.adaptiveBackground
                .ignoresSafeArea()

            // Animated circle reveal for theme change
            Circle()
                .fill(isDarkMode ? Color(hex: "1C1C1E") : Color(hex: "F8F9FA"))
                .scaleEffect(animationProgress * 3)
                .opacity(animationProgress > 0 ? 1 : 0)
                .ignoresSafeArea()
        }
        .onChange(of: isDarkMode) { oldValue, newValue in
            // Reset and animate
            animationProgress = 0
            withAnimation(.easeInOut(duration: 0.5)) {
                animationProgress = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animationProgress = 0
            }
        }
    }
}

// MARK: - Animated Theme Toggle
struct AnimatedThemeToggle: View {
    @Binding var isDarkMode: Bool
    @Binding var useSystemAppearance: Bool

    @State private var sunRotation: Double = 0
    @State private var moonOffset: CGFloat = 0

    var body: some View {
        HStack {
            // Sun/Moon icon with animation
            ZStack {
                // Sun
                Image(systemName: "sun.max.fill")
                    .font(.title)
                    .foregroundStyle(.yellow)
                    .rotationEffect(.degrees(sunRotation))
                    .opacity(isDarkMode ? 0 : 1)
                    .scaleEffect(isDarkMode ? 0.5 : 1)

                // Moon
                Image(systemName: "moon.fill")
                    .font(.title)
                    .foregroundStyle(.purple)
                    .offset(x: moonOffset)
                    .opacity(isDarkMode ? 1 : 0)
                    .scaleEffect(isDarkMode ? 1 : 0.5)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(isDarkMode ? "Dark Mode" : "Light Mode")
                    .font(.headline)
                    .foregroundStyle(Color.adaptivePrimaryText)

                Text("Tap to switch theme")
                    .font(.caption)
                    .foregroundStyle(Color.adaptiveSecondaryText)
            }

            Spacer()

            // Toggle with custom styling
            ZStack {
                Capsule()
                    .fill(isDarkMode ? Color.purple.opacity(0.3) : LemonMathColors.lemonYellow.opacity(0.3))
                    .frame(width: 60, height: 32)

                Circle()
                    .fill(isDarkMode ? .purple : LemonMathColors.lemonYellow)
                    .frame(width: 26, height: 26)
                    .offset(x: isDarkMode ? 14 : -14)
                    .shadow(radius: 2)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isDarkMode.toggle()
                    useSystemAppearance = false

                    // Animate icons
                    if isDarkMode {
                        moonOffset = 0
                    } else {
                        sunRotation += 180
                    }
                }
            }
            .disabled(useSystemAppearance)
            .opacity(useSystemAppearance ? 0.5 : 1)
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            // Start sun rotation animation
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                sunRotation = 360
            }
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(LemonMathColors.accent)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.adaptivePrimaryText)
            }

            VStack(spacing: 1) {
                content()
            }
            .background(Color.adaptiveCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Settings Row
struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let trailing: () -> Content

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color.adaptiveSecondaryText)
                .frame(width: 24)

            Text(title)
                .foregroundStyle(Color.adaptivePrimaryText)

            Spacer()

            trailing()
        }
        .padding()
    }
}

// MARK: - Settings Row Button
struct SettingsRowButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(title)
                .foregroundStyle(Color.adaptivePrimaryText)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.adaptiveSecondaryText)
        }
        .padding()
    }
}

// MARK: - Stat Circle
struct StatCircle: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)

                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 60, height: 60)

                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.adaptiveSecondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
        .environmentObject(HistoryManager())
        .environmentObject(AchievementManager())
}
