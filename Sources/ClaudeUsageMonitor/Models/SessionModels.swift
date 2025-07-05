import Foundation

// Response structure for blocks endpoint
struct BlocksResponse: Codable {
    let blocks: [SessionBlock]
}

// Response structure for session endpoint
struct SessionResponse: Codable {
    let sessions: [SessionData]
    let totals: SessionTotals
}

struct SessionData: Codable {
    let sessionId: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let totalTokens: Int
    let totalCost: Double
    let lastActivity: String
    let modelsUsed: [String]
    let modelBreakdowns: [ModelBreakdown]
}

struct SessionTotals: Codable {
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let totalTokens: Int
    let totalCost: Double
}

struct ModelBreakdown: Codable {
    let modelName: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let totalTokens: Int?
    let totalCost: Double?
    let cost: Double?

    // Provide cost accessor for compatibility
    var actualCost: Double {
        return cost ?? totalCost ?? 0.0
    }
}

struct SessionBlock: Codable {
    let id: String
    let startTime: String
    let endTime: String
    let actualEndTime: String?
    let isActive: Bool
    let isGap: Bool
    let entries: Int
    let tokenCounts: TokenCounts
    let totalTokens: Int
    let costUSD: Double
    let models: [String]
    let burnRate: BurnRate?
    let projection: Projection?
}

struct TokenCounts: Codable {
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationInputTokens: Int
    let cacheReadInputTokens: Int

    /// Billable tokens (input + output only)
    var billableTokens: Int {
        return inputTokens + outputTokens
    }
}

struct BurnRate: Codable {
    let tokensPerMinute: Double
    let costPerHour: Double
}

struct Projection: Codable {
    let totalTokens: Int
    let totalCost: Double
    let remainingMinutes: Int
}

// Extended UsageData for session-based monitoring
extension UsageData {
    // Session-based limits
    static let proSessionTokenLimit: Int = 7_000
    static let max5SessionTokenLimit: Int = 35_000
    static let max20SessionTokenLimit: Int = 140_000

    var sessionTokenLimit: Int {
        // 保存されたプランタイプがあればそれを使用
        if let planType = detectedPlanType {
            switch planType {
            case "Max20":
                return Self.max20SessionTokenLimit
            case "Max5":
                return Self.max5SessionTokenLimit
            default:
                return Self.proSessionTokenLimit
            }
        }

        // 過去の最大使用量から判定
        if historicalMaxTokens > Self.max5SessionTokenLimit {
            return Self.max20SessionTokenLimit
        } else if historicalMaxTokens > Self.proSessionTokenLimit {
            return Self.max5SessionTokenLimit
        }

        // 現在のセッション使用量からも判定（フォールバック）
        if let session = activeSession {
            if session.totalTokens > Self.max5SessionTokenLimit {
                return Self.max20SessionTokenLimit
            } else if session.totalTokens > Self.proSessionTokenLimit {
                return Self.max5SessionTokenLimit
            }
        }

        return Self.proSessionTokenLimit
    }

    var detectedPlan: String {
        // 保存されたプランタイプがあればそれを使用
        if let planType = detectedPlanType {
            return planType
        }

        // 過去の最大使用量から判定
        if historicalMaxTokens > Self.max5SessionTokenLimit {
            return "Max20"
        } else if historicalMaxTokens > Self.proSessionTokenLimit {
            return "Max5"
        }

        // 現在のセッション使用量からも判定（フォールバック）
        if let session = activeSession {
            if session.totalTokens > Self.max5SessionTokenLimit {
                return "Max20"
            } else if session.totalTokens > Self.proSessionTokenLimit {
                return "Max5"
            }
        }

        // デフォルトはPro
        return "Pro"
    }

    var planDescription: String {
        switch detectedPlan {
        case "Max20":
            return "Max20 (140K tokens/session)"
        case "Max5":
            return "Max5 (35K tokens/session)"
        default:
            return "Pro (7K tokens/session)"
        }
    }

    var formattedSessionPercentage: String {
        return String(format: "%.1f%%", sessionUsagePercentage)
    }

    var sessionRemainingTime: String {
        guard let session = activeSession,
              let projection = session.projection else { return "N/A" }

        let hours = projection.remainingMinutes / 60
        let minutes = projection.remainingMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // Share text用のシンプルな残り時間表示
    var sessionRemainingTimeForShare: String {
        guard let session = activeSession,
              let projection = session.projection else { return "N/A" }

        let totalMinutes = projection.remainingMinutes
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        // 英語環境かどうかを判定
        let isEnglish = LanguageSettings.shared.effectiveLanguageCode() == "en"

        if hours > 0 {
            if minutes == 0 {
                return isEnglish ? "\(hours)h" : "\(hours)時間"
            } else {
                return isEnglish ? "\(hours)h \(minutes)m" : "\(hours)時間\(minutes)分"
            }
        } else if minutes > 1 {
            return isEnglish ? "\(minutes)m" : "\(minutes)分"
        } else if minutes == 1 {
            // 1分以下の場合は秒で表示
            return isEnglish ? "60s" : "60秒"
        } else {
            return isEnglish ? "Soon" : "まもなく"
        }
    }

    var sessionBurnRate: String {
        guard let session = activeSession,
              let burnRate = session.burnRate else { return "0" }

        return String(format: "%.1f", burnRate.tokensPerMinute)
    }

    var sessionCostPerHour: String {
        guard let session = activeSession,
              let burnRate = session.burnRate else { return "$0.00" }

        return String(format: "$%.2f", burnRate.costPerHour)
    }

    var isOverLimit: Bool {
        guard let session = activeSession else { return false }
        return session.totalTokens > sessionTokenLimit
    }

    /// Session usage percentage
    var sessionUsagePercentage: Double {
        guard let session = activeSession else { return 0 }
        return (Double(session.totalTokens) / Double(sessionTokenLimit)) * 100
    }

    /// Remaining session tokens
    var remainingSessionTokens: Int {
        guard let session = activeSession else { return sessionTokenLimit }
        return max(0, sessionTokenLimit - session.totalTokens)
    }
}

// MARK: - Session Block Convertible Protocol
protocol SessionBlockConvertible {
    func toSessionBlock() -> SessionBlock
}

extension SessionBlock: SessionBlockConvertible {
    func toSessionBlock() -> SessionBlock {
        return self
    }
}
