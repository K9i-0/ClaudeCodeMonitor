import Foundation

// Response structure for blocks endpoint
struct BlocksResponse: Codable {
    let blocks: [SessionBlock]
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
        // Auto-detect limit based on current usage
        if let session = activeSession {
            if session.totalTokens > Self.max5SessionTokenLimit {
                return Self.max20SessionTokenLimit
            } else if session.totalTokens > Self.proSessionTokenLimit {
                return Self.max5SessionTokenLimit
            }
        }
        return Self.proSessionTokenLimit
    }
    
    var sessionTokenPercentage: Double {
        guard let session = activeSession else { return 0 }
        return (Double(session.totalTokens) / Double(sessionTokenLimit)) * 100
    }
    
    var formattedSessionPercentage: String {
        return String(format: "%.1f%%", sessionTokenPercentage)
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
}