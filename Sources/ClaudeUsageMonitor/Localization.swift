import Foundation

// MARK: - Localization Helper
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}

// MARK: - Localization Keys
struct L10n {
    struct Tab {
        static let current = "tab.current".localized
        static let history = "tab.history".localized
    }
    
    struct Session {
        static let remaining = "session.remaining".localized
        static let tokens = "session.tokens".localized
        static let burnRate = "session.burnRate".localized
        static let tokensPerMin = "session.tokensPerMin".localized
        static let timeRemaining = "session.timeRemaining".localized
        static let cost = "session.cost".localized
        static let referenceValue = "session.referenceValue".localized
        static let noActiveSession = "session.noActiveSession".localized
        static let waitingForData = "session.waitingForData".localized
    }
    
    struct History {
        static let currentSession = "history.currentSession".localized
        static let pastSessions = "history.pastSessions".localized
        static func sessionDetails(tokens: String, from: String, to: String) -> String {
            return "history.sessionDetails".localized(with: tokens, from, to)
        }
        static let noHistory = "history.noHistory".localized
    }
    
    struct Plan {
        static let title = "plan.title".localized
        static let pro = "plan.pro".localized
        static let max5 = "plan.max5".localized
        static let max20 = "plan.max20".localized
    }
    
    struct Usage {
        static let today = "usage.today".localized
        static let thisMonth = "usage.thisMonth".localized
    }
    
    struct Action {
        static let refresh = "action.refresh".localized
        static let settings = "action.settings".localized
        static let quit = "action.quit".localized
    }
    
    struct Error {
        static let loadingData = "error.loadingData".localized
        static let dataFetchFailed = "error.dataFetchFailed".localized
        static let networkError = "error.networkError".localized
        static let unknown = "error.unknown".localized
    }
    
    struct Notification {
        static let highUsageTitle = "notification.highUsage.title".localized
        static func highUsageBody(percentage: Int, burnRate: Double) -> String {
            return "notification.highUsage.body".localized(with: percentage, burnRate)
        }
        static let sessionResetTitle = "notification.sessionReset.title".localized
        static let sessionResetBody = "notification.sessionReset.body".localized
    }
}