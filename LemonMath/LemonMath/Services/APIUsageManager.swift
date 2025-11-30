//
//  APIUsageManager.swift
//  LemonMath
//
//  Admin controls for API token usage, rate limiting, and usage tracking
//

import Foundation
import SwiftUI
import Combine

// MARK: - API Usage Manager
@MainActor
class APIUsageManager: ObservableObject {
    static let shared = APIUsageManager()

    // MARK: - Published Properties
    @Published var currentUsage: UsageStats = UsageStats()
    @Published var userQuota: UserQuota = UserQuota.defaultQuota
    @Published var isRateLimited = false
    @Published var rateLimitResetTime: Date?

    // MARK: - Private Properties
    private let storageKey = "apiUsageData"
    private let quotaStorageKey = "userQuota"
    private let adminConfigKey = "adminConfig"

    private var usageHistory: [UsageRecord] = []
    private var requestTimestamps: [Date] = []

    // Rate limiting configuration
    private var maxRequestsPerMinute: Int = 10
    private var maxRequestsPerHour: Int = 100
    private var maxRequestsPerDay: Int = 500

    // MARK: - Initialization
    private init() {
        loadUsageData()
        loadQuotaConfig()
        cleanupOldRecords()
    }

    // MARK: - Public Methods

    /// Check if user can make an API request
    func canMakeRequest() -> RequestPermission {
        // Check daily quota
        if currentUsage.dailyRequests >= userQuota.dailyLimit {
            return .denied(reason: .dailyQuotaExceeded)
        }

        // Check monthly quota
        if currentUsage.monthlyRequests >= userQuota.monthlyLimit {
            return .denied(reason: .monthlyQuotaExceeded)
        }

        // Check rate limiting
        let now = Date()
        cleanupRequestTimestamps()

        let requestsLastMinute = requestTimestamps.filter {
            now.timeIntervalSince($0) < 60
        }.count

        let requestsLastHour = requestTimestamps.filter {
            now.timeIntervalSince($0) < 3600
        }.count

        if requestsLastMinute >= maxRequestsPerMinute {
            isRateLimited = true
            rateLimitResetTime = Date().addingTimeInterval(60)
            return .denied(reason: .rateLimited(resetIn: 60))
        }

        if requestsLastHour >= maxRequestsPerHour {
            isRateLimited = true
            rateLimitResetTime = Date().addingTimeInterval(3600)
            return .denied(reason: .rateLimited(resetIn: 3600))
        }

        // Check if user has premium/unlimited access
        if userQuota.tier == .unlimited {
            return .allowed
        }

        return .allowed
    }

    /// Record an API request
    func recordRequest(type: RequestType, tokensUsed: Int = 0, success: Bool = true) {
        let now = Date()

        // Add to timestamps for rate limiting
        requestTimestamps.append(now)

        // Create usage record
        let record = UsageRecord(
            timestamp: now,
            requestType: type,
            tokensUsed: tokensUsed,
            success: success
        )
        usageHistory.append(record)

        // Update stats
        currentUsage.totalRequests += 1
        currentUsage.dailyRequests += 1
        currentUsage.monthlyRequests += 1
        currentUsage.totalTokensUsed += tokensUsed

        if success {
            currentUsage.successfulRequests += 1
        } else {
            currentUsage.failedRequests += 1
        }

        // Update by type
        switch type {
        case .solve:
            currentUsage.solveRequests += 1
        case .explain:
            currentUsage.explainRequests += 1
        case .generateImage:
            currentUsage.imageGenerationRequests += 1
        case .recognize:
            currentUsage.recognitionRequests += 1
        }

        currentUsage.lastRequestTime = now

        saveUsageData()
    }

    /// Get remaining quota
    func getRemainingQuota() -> RemainingQuota {
        RemainingQuota(
            dailyRemaining: max(0, userQuota.dailyLimit - currentUsage.dailyRequests),
            monthlyRemaining: max(0, userQuota.monthlyLimit - currentUsage.monthlyRequests),
            dailyLimit: userQuota.dailyLimit,
            monthlyLimit: userQuota.monthlyLimit
        )
    }

    /// Reset daily usage (called at midnight)
    func resetDailyUsage() {
        currentUsage.dailyRequests = 0
        isRateLimited = false
        rateLimitResetTime = nil
        saveUsageData()
    }

    /// Reset monthly usage (called at start of month)
    func resetMonthlyUsage() {
        currentUsage.monthlyRequests = 0
        saveUsageData()
    }

    /// Get usage analytics
    func getAnalytics(for period: AnalyticsPeriod) -> UsageAnalytics {
        let now = Date()
        let filteredRecords: [UsageRecord]

        switch period {
        case .today:
            filteredRecords = usageHistory.filter { Calendar.current.isDateInToday($0.timestamp) }
        case .week:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
            filteredRecords = usageHistory.filter { $0.timestamp >= weekAgo }
        case .month:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!
            filteredRecords = usageHistory.filter { $0.timestamp >= monthAgo }
        case .all:
            filteredRecords = usageHistory
        }

        let totalRequests = filteredRecords.count
        let successRate = totalRequests > 0
            ? Double(filteredRecords.filter { $0.success }.count) / Double(totalRequests)
            : 0

        let requestsByType = Dictionary(grouping: filteredRecords, by: { $0.requestType })
            .mapValues { $0.count }

        let totalTokens = filteredRecords.reduce(0) { $0 + $1.tokensUsed }

        // Calculate hourly distribution
        var hourlyDistribution: [Int: Int] = [:]
        for record in filteredRecords {
            let hour = Calendar.current.component(.hour, from: record.timestamp)
            hourlyDistribution[hour, default: 0] += 1
        }

        return UsageAnalytics(
            period: period,
            totalRequests: totalRequests,
            successRate: successRate,
            requestsByType: requestsByType,
            totalTokensUsed: totalTokens,
            averageTokensPerRequest: totalRequests > 0 ? totalTokens / totalRequests : 0,
            hourlyDistribution: hourlyDistribution,
            peakHour: hourlyDistribution.max(by: { $0.value < $1.value })?.key
        )
    }

    // MARK: - Admin Methods

    /// Update user quota (admin only)
    func updateQuota(_ newQuota: UserQuota, adminKey: String) -> Bool {
        guard validateAdminKey(adminKey) else { return false }

        userQuota = newQuota
        saveQuotaConfig()
        return true
    }

    /// Set rate limits (admin only)
    func setRateLimits(perMinute: Int, perHour: Int, perDay: Int, adminKey: String) -> Bool {
        guard validateAdminKey(adminKey) else { return false }

        maxRequestsPerMinute = perMinute
        maxRequestsPerHour = perHour
        maxRequestsPerDay = perDay
        saveAdminConfig()
        return true
    }

    /// Clear all usage data (admin only)
    func clearUsageData(adminKey: String) -> Bool {
        guard validateAdminKey(adminKey) else { return false }

        currentUsage = UsageStats()
        usageHistory.removeAll()
        requestTimestamps.removeAll()
        isRateLimited = false
        rateLimitResetTime = nil
        saveUsageData()
        return true
    }

    /// Export usage report (admin only)
    func exportUsageReport(adminKey: String) -> UsageReport? {
        guard validateAdminKey(adminKey) else { return nil }

        return UsageReport(
            generatedAt: Date(),
            stats: currentUsage,
            quota: userQuota,
            history: usageHistory,
            analytics: getAnalytics(for: .all)
        )
    }

    /// Apply remote configuration from server
    func applyRemoteConfig(_ config: RemoteAPIConfig) {
        userQuota = config.quota
        maxRequestsPerMinute = config.rateLimits.perMinute
        maxRequestsPerHour = config.rateLimits.perHour
        maxRequestsPerDay = config.rateLimits.perDay
        saveQuotaConfig()
        saveAdminConfig()
    }

    // MARK: - Private Methods

    private func validateAdminKey(_ key: String) -> Bool {
        // In production, this would validate against a secure backend
        // For now, we check against stored admin key
        let storedKey = UserDefaults.standard.string(forKey: "adminAPIKey") ?? ""
        return !storedKey.isEmpty && key == storedKey
    }

    private func cleanupRequestTimestamps() {
        let cutoff = Date().addingTimeInterval(-3600) // Keep last hour
        requestTimestamps.removeAll { $0 < cutoff }
    }

    private func cleanupOldRecords() {
        // Keep only last 30 days of records
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        usageHistory.removeAll { $0.timestamp < cutoff }
        saveUsageData()
    }

    private func loadUsageData() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(UsageStorageData.self, from: data) {
            currentUsage = decoded.stats
            usageHistory = decoded.history

            // Check if we need to reset daily/monthly counters
            let calendar = Calendar.current
            if let lastRequest = currentUsage.lastRequestTime {
                if !calendar.isDateInToday(lastRequest) {
                    resetDailyUsage()
                }

                let lastMonth = calendar.component(.month, from: lastRequest)
                let currentMonth = calendar.component(.month, from: Date())
                if lastMonth != currentMonth {
                    resetMonthlyUsage()
                }
            }
        }
    }

    private func saveUsageData() {
        let storageData = UsageStorageData(stats: currentUsage, history: usageHistory)
        if let data = try? JSONEncoder().encode(storageData) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadQuotaConfig() {
        if let data = UserDefaults.standard.data(forKey: quotaStorageKey),
           let decoded = try? JSONDecoder().decode(UserQuota.self, from: data) {
            userQuota = decoded
        }
    }

    private func saveQuotaConfig() {
        if let data = try? JSONEncoder().encode(userQuota) {
            UserDefaults.standard.set(data, forKey: quotaStorageKey)
        }
    }

    private func saveAdminConfig() {
        let config = AdminConfig(
            maxRequestsPerMinute: maxRequestsPerMinute,
            maxRequestsPerHour: maxRequestsPerHour,
            maxRequestsPerDay: maxRequestsPerDay
        )
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: adminConfigKey)
        }
    }
}

// MARK: - Supporting Types

struct UsageStats: Codable {
    var totalRequests: Int = 0
    var dailyRequests: Int = 0
    var monthlyRequests: Int = 0
    var successfulRequests: Int = 0
    var failedRequests: Int = 0
    var totalTokensUsed: Int = 0
    var solveRequests: Int = 0
    var explainRequests: Int = 0
    var imageGenerationRequests: Int = 0
    var recognitionRequests: Int = 0
    var lastRequestTime: Date?
}

struct UsageRecord: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let requestType: RequestType
    let tokensUsed: Int
    let success: Bool

    init(timestamp: Date, requestType: RequestType, tokensUsed: Int, success: Bool) {
        self.id = UUID()
        self.timestamp = timestamp
        self.requestType = requestType
        self.tokensUsed = tokensUsed
        self.success = success
    }
}

enum RequestType: String, Codable, CaseIterable {
    case solve
    case explain
    case generateImage
    case recognize

    var displayName: String {
        switch self {
        case .solve: return "Solve Problem"
        case .explain: return "Get Explanation"
        case .generateImage: return "Generate Image"
        case .recognize: return "Recognize Text"
        }
    }

    var tokenCost: Int {
        switch self {
        case .solve: return 100
        case .explain: return 50
        case .generateImage: return 200
        case .recognize: return 30
        }
    }
}

struct UserQuota: Codable {
    var tier: QuotaTier
    var dailyLimit: Int
    var monthlyLimit: Int
    var tokensPerMonth: Int
    var features: Set<PremiumFeature>

    static let defaultQuota = UserQuota(
        tier: .free,
        dailyLimit: 20,
        monthlyLimit: 200,
        tokensPerMonth: 10000,
        features: []
    )

    static let premiumQuota = UserQuota(
        tier: .premium,
        dailyLimit: 100,
        monthlyLimit: 2000,
        tokensPerMonth: 100000,
        features: [.offlineMode, .priorityProcessing, .advancedExplanations]
    )

    static let unlimitedQuota = UserQuota(
        tier: .unlimited,
        dailyLimit: Int.max,
        monthlyLimit: Int.max,
        tokensPerMonth: Int.max,
        features: Set(PremiumFeature.allCases)
    )
}

enum QuotaTier: String, Codable {
    case free
    case premium
    case unlimited

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        case .unlimited: return "Unlimited"
        }
    }

    var color: Color {
        switch self {
        case .free: return .gray
        case .premium: return .orange
        case .unlimited: return .purple
        }
    }
}

enum PremiumFeature: String, Codable, CaseIterable {
    case offlineMode
    case priorityProcessing
    case advancedExplanations
    case noAds
    case exportPDF
    case customThemes

    var displayName: String {
        switch self {
        case .offlineMode: return "Offline Mode"
        case .priorityProcessing: return "Priority Processing"
        case .advancedExplanations: return "Advanced Explanations"
        case .noAds: return "No Ads"
        case .exportPDF: return "Export to PDF"
        case .customThemes: return "Custom Themes"
        }
    }
}

struct RemainingQuota {
    let dailyRemaining: Int
    let monthlyRemaining: Int
    let dailyLimit: Int
    let monthlyLimit: Int

    var dailyPercentUsed: Double {
        guard dailyLimit > 0 else { return 0 }
        return 1.0 - (Double(dailyRemaining) / Double(dailyLimit))
    }

    var monthlyPercentUsed: Double {
        guard monthlyLimit > 0 else { return 0 }
        return 1.0 - (Double(monthlyRemaining) / Double(monthlyLimit))
    }
}

enum RequestPermission {
    case allowed
    case denied(reason: DenialReason)

    var isAllowed: Bool {
        if case .allowed = self { return true }
        return false
    }
}

enum DenialReason {
    case dailyQuotaExceeded
    case monthlyQuotaExceeded
    case rateLimited(resetIn: TimeInterval)
    case accountSuspended
    case maintenanceMode

    var message: String {
        switch self {
        case .dailyQuotaExceeded:
            return "You've reached your daily limit. Come back tomorrow!"
        case .monthlyQuotaExceeded:
            return "Monthly quota exceeded. Upgrade to Premium for more."
        case .rateLimited(let resetIn):
            let minutes = Int(resetIn / 60)
            return "Too many requests. Please wait \(minutes) minute\(minutes == 1 ? "" : "s")."
        case .accountSuspended:
            return "Your account has been suspended. Contact support."
        case .maintenanceMode:
            return "Service is under maintenance. Please try again later."
        }
    }
}

enum AnalyticsPeriod: String, CaseIterable {
    case today
    case week
    case month
    case all

    var displayName: String {
        switch self {
        case .today: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        case .all: return "All Time"
        }
    }
}

struct UsageAnalytics {
    let period: AnalyticsPeriod
    let totalRequests: Int
    let successRate: Double
    let requestsByType: [RequestType: Int]
    let totalTokensUsed: Int
    let averageTokensPerRequest: Int
    let hourlyDistribution: [Int: Int]
    let peakHour: Int?
}

struct UsageReport: Codable {
    let generatedAt: Date
    let stats: UsageStats
    let quota: UserQuota
    let history: [UsageRecord]
    let analytics: UsageAnalyticsCodable
}

struct UsageAnalyticsCodable: Codable {
    let totalRequests: Int
    let successRate: Double
    let totalTokensUsed: Int
}

struct UsageStorageData: Codable {
    let stats: UsageStats
    let history: [UsageRecord]
}

struct AdminConfig: Codable {
    let maxRequestsPerMinute: Int
    let maxRequestsPerHour: Int
    let maxRequestsPerDay: Int
}

struct RemoteAPIConfig: Codable {
    let quota: UserQuota
    let rateLimits: RateLimits
    let maintenanceMode: Bool
    let minAppVersion: String?

    struct RateLimits: Codable {
        let perMinute: Int
        let perHour: Int
        let perDay: Int
    }
}
