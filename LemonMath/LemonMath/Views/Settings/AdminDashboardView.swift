//
//  AdminDashboardView.swift
//  LemonMath
//
//  Admin dashboard for monitoring API usage and controlling quotas
//

import SwiftUI
import Charts

struct AdminDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var usageManager = APIUsageManager.shared
    @EnvironmentObject var settingsManager: SettingsManager

    @State private var selectedPeriod: AnalyticsPeriod = .today
    @State private var showQuotaEditor = false
    @State private var showRateLimitEditor = false
    @State private var adminKey = ""
    @State private var isAuthenticated = false
    @State private var showAuthError = false

    var body: some View {
        NavigationStack {
            Group {
                if isAuthenticated {
                    dashboardContent
                } else {
                    authenticationView
                }
            }
            .navigationTitle("Admin Dashboard")
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

    // MARK: - Authentication View
    private var authenticationView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundStyle(LemonMathColors.accent)

            Text("Admin Access Required")
                .font(.title2)
                .fontWeight(.bold)

            Text("Enter your admin key to access the dashboard")
                .font(.subheadline)
                .foregroundStyle(Color.adaptiveSecondaryText)
                .multilineTextAlignment(.center)

            SecureField("Admin Key", text: $adminKey)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)

            Button {
                authenticate()
            } label: {
                Text("Unlock")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LemonMathColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
        }
        .alert("Authentication Failed", isPresented: $showAuthError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Invalid admin key. Please try again.")
        }
    }

    // MARK: - Dashboard Content
    private var dashboardContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Current Status
                statusSection

                // Usage Overview
                usageOverviewSection

                // Quota Management
                quotaSection

                // Analytics
                analyticsSection

                // Rate Limiting
                rateLimitSection

                // Actions
                actionsSection
            }
            .padding()
        }
        .background(Color.adaptiveBackground)
        .sheet(isPresented: $showQuotaEditor) {
            QuotaEditorView(adminKey: adminKey)
        }
        .sheet(isPresented: $showRateLimitEditor) {
            RateLimitEditorView(adminKey: adminKey)
        }
    }

    // MARK: - Status Section
    private var statusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Current Status")
                    .font(.headline)
                Spacer()

                // Status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(usageManager.isRateLimited ? .red : .green)
                        .frame(width: 10, height: 10)

                    Text(usageManager.isRateLimited ? "Rate Limited" : "Active")
                        .font(.caption)
                        .foregroundStyle(usageManager.isRateLimited ? .red : .green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    (usageManager.isRateLimited ? Color.red : Color.green).opacity(0.1)
                )
                .clipShape(Capsule())
            }

            // Quota tier
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quota Tier")
                        .font(.caption)
                        .foregroundStyle(Color.adaptiveSecondaryText)

                    Text(usageManager.userQuota.tier.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(usageManager.userQuota.tier.color)
                }

                Spacer()

                if usageManager.isRateLimited, let resetTime = usageManager.rateLimitResetTime {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Resets in")
                            .font(.caption)
                            .foregroundStyle(Color.adaptiveSecondaryText)

                        Text(resetTime, style: .relative)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Usage Overview Section
    private var usageOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Usage Overview")
                .font(.headline)

            let remaining = usageManager.getRemainingQuota()

            // Daily usage
            UsageProgressBar(
                title: "Daily",
                used: usageManager.currentUsage.dailyRequests,
                limit: remaining.dailyLimit,
                color: .blue
            )

            // Monthly usage
            UsageProgressBar(
                title: "Monthly",
                used: usageManager.currentUsage.monthlyRequests,
                limit: remaining.monthlyLimit,
                color: .purple
            )

            // Token usage
            HStack {
                VStack(alignment: .leading) {
                    Text("Tokens Used")
                        .font(.caption)
                        .foregroundStyle(Color.adaptiveSecondaryText)
                    Text("\(usageManager.currentUsage.totalTokensUsed)")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Success Rate")
                        .font(.caption)
                        .foregroundStyle(Color.adaptiveSecondaryText)

                    let total = usageManager.currentUsage.totalRequests
                    let success = usageManager.currentUsage.successfulRequests
                    let rate = total > 0 ? Double(success) / Double(total) * 100 : 0

                    Text(String(format: "%.1f%%", rate))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(rate > 90 ? .green : (rate > 70 ? .orange : .red))
                }
            }
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Quota Section
    private var quotaSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quota Settings")
                    .font(.headline)

                Spacer()

                Button {
                    showQuotaEditor = true
                } label: {
                    Text("Edit")
                        .font(.subheadline)
                        .foregroundStyle(LemonMathColors.accent)
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                GridRow {
                    Text("Daily Limit")
                        .foregroundStyle(Color.adaptiveSecondaryText)
                    Text("\(usageManager.userQuota.dailyLimit)")
                        .fontWeight(.medium)
                }

                GridRow {
                    Text("Monthly Limit")
                        .foregroundStyle(Color.adaptiveSecondaryText)
                    Text("\(usageManager.userQuota.monthlyLimit)")
                        .fontWeight(.medium)
                }

                GridRow {
                    Text("Tokens/Month")
                        .foregroundStyle(Color.adaptiveSecondaryText)
                    Text("\(usageManager.userQuota.tokensPerMonth)")
                        .fontWeight(.medium)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Analytics Section
    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Analytics")
                    .font(.headline)

                Spacer()

                Picker("Period", selection: $selectedPeriod) {
                    ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            let analytics = usageManager.getAnalytics(for: selectedPeriod)

            // Request type breakdown
            if !analytics.requestsByType.isEmpty {
                Chart {
                    ForEach(Array(analytics.requestsByType.keys), id: \.self) { type in
                        BarMark(
                            x: .value("Type", type.displayName),
                            y: .value("Count", analytics.requestsByType[type] ?? 0)
                        )
                        .foregroundStyle(colorForRequestType(type))
                    }
                }
                .frame(height: 150)
            } else {
                Text("No data for this period")
                    .font(.subheadline)
                    .foregroundStyle(Color.adaptiveSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }

            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                AnalyticCard(title: "Requests", value: "\(analytics.totalRequests)", icon: "arrow.up.arrow.down")
                AnalyticCard(title: "Tokens", value: "\(analytics.totalTokensUsed)", icon: "bitcoinsign.circle")
                AnalyticCard(title: "Avg Tokens", value: "\(analytics.averageTokensPerRequest)", icon: "chart.bar")
                AnalyticCard(title: "Peak Hour", value: analytics.peakHour != nil ? "\(analytics.peakHour!):00" : "N/A", icon: "clock")
            }
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Rate Limit Section
    private var rateLimitSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Rate Limiting")
                    .font(.headline)

                Spacer()

                Button {
                    showRateLimitEditor = true
                } label: {
                    Text("Configure")
                        .font(.subheadline)
                        .foregroundStyle(LemonMathColors.accent)
                }
            }

            Text("Controls how many requests can be made within time windows")
                .font(.caption)
                .foregroundStyle(Color.adaptiveSecondaryText)

            // Current limits would be shown here
            // In production, these would be fetched from the manager
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                usageManager.resetDailyUsage()
                settingsManager.triggerHapticFeedback()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Daily Counter")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                _ = usageManager.clearUsageData(adminKey: adminKey)
                settingsManager.triggerHapticFeedback()
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear All Usage Data")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundStyle(.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                exportReport()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Usage Report")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(LemonMathColors.accent.opacity(0.1))
                .foregroundStyle(LemonMathColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Methods
    private func authenticate() {
        // In production, validate against secure backend
        // For demo, accept any non-empty key
        if !adminKey.isEmpty {
            UserDefaults.standard.set(adminKey, forKey: "adminAPIKey")
            isAuthenticated = true
        } else {
            showAuthError = true
        }
    }

    private func colorForRequestType(_ type: RequestType) -> Color {
        switch type {
        case .solve: return .blue
        case .explain: return .green
        case .generateImage: return .purple
        case .recognize: return .orange
        }
    }

    private func exportReport() {
        if let report = usageManager.exportUsageReport(adminKey: adminKey) {
            // In production, convert to JSON and share
            print("Report generated: \(report)")
        }
    }
}

// MARK: - Usage Progress Bar
struct UsageProgressBar: View {
    let title: String
    let used: Int
    let limit: Int
    let color: Color

    var progress: Double {
        guard limit > 0 else { return 0 }
        return min(Double(used) / Double(limit), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Color.adaptiveSecondaryText)

                Spacer()

                Text("\(used) / \(limit)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(progress > 0.9 ? .red : color)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Analytic Card
struct AnalyticCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(LemonMathColors.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color.adaptiveSecondaryText)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.adaptiveBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Quota Editor View
struct QuotaEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let adminKey: String

    @State private var selectedTier: QuotaTier = .free
    @State private var dailyLimit: String = "20"
    @State private var monthlyLimit: String = "200"
    @State private var tokensPerMonth: String = "10000"

    var body: some View {
        NavigationStack {
            Form {
                Section("Quota Tier") {
                    Picker("Tier", selection: $selectedTier) {
                        ForEach([QuotaTier.free, .premium, .unlimited], id: \.self) { tier in
                            Text(tier.displayName).tag(tier)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Limits") {
                    TextField("Daily Limit", text: $dailyLimit)
                        .keyboardType(.numberPad)

                    TextField("Monthly Limit", text: $monthlyLimit)
                        .keyboardType(.numberPad)

                    TextField("Tokens per Month", text: $tokensPerMonth)
                        .keyboardType(.numberPad)
                }

                Section {
                    Button("Apply Preset") {
                        applyPreset()
                    }
                }
            }
            .navigationTitle("Edit Quota")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveQuota() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func applyPreset() {
        switch selectedTier {
        case .free:
            dailyLimit = "20"
            monthlyLimit = "200"
            tokensPerMonth = "10000"
        case .premium:
            dailyLimit = "100"
            monthlyLimit = "2000"
            tokensPerMonth = "100000"
        case .unlimited:
            dailyLimit = "999999"
            monthlyLimit = "999999"
            tokensPerMonth = "999999"
        }
    }

    @MainActor private func saveQuota() {
        let quota = UserQuota(
            tier: selectedTier,
            dailyLimit: Int(dailyLimit) ?? 20,
            monthlyLimit: Int(monthlyLimit) ?? 200,
            tokensPerMonth: Int(tokensPerMonth) ?? 10000,
            features: selectedTier == .unlimited ? Set(PremiumFeature.allCases) : []
        )
        _ = APIUsageManager.shared.updateQuota(quota, adminKey: adminKey)
        dismiss()
    }
}

// MARK: - Rate Limit Editor View
struct RateLimitEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let adminKey: String

    @State private var perMinute: String = "10"
    @State private var perHour: String = "100"
    @State private var perDay: String = "500"

    var body: some View {
        NavigationStack {
            Form {
                Section("Rate Limits") {
                    HStack {
                        Text("Per Minute")
                        Spacer()
                        TextField("", text: $perMinute)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("Per Hour")
                        Spacer()
                        TextField("", text: $perHour)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("Per Day")
                        Spacer()
                        TextField("", text: $perDay)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                Section(footer: Text("Lower limits help prevent abuse and control costs.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Rate Limits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveLimits() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    @MainActor private func saveLimits() {
        _ = APIUsageManager.shared.setRateLimits(
            perMinute: Int(perMinute) ?? 10,
            perHour: Int(perHour) ?? 100,
            perDay: Int(perDay) ?? 500,
            adminKey: adminKey
        )
        dismiss()
    }
}

#Preview {
    AdminDashboardView()
        .environmentObject(SettingsManager())
}
