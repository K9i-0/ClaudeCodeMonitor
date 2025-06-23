import Foundation
import SwiftUI

// MARK: - Localization Helper
extension String {
    var localized: String {
        let languageCode = LanguageSettings.shared.effectiveLanguageCode()
        
        // Try to get the bundle for the specific language
        if let path = Bundle.module.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return NSLocalizedString(self, bundle: bundle, comment: "")
        }
        
        // Fallback to module bundle
        return NSLocalizedString(self, bundle: .module, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        let languageCode = LanguageSettings.shared.effectiveLanguageCode()
        
        // Try to get the bundle for the specific language
        if let path = Bundle.module.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return String(format: NSLocalizedString(self, bundle: bundle, comment: ""), arguments: arguments)
        }
        
        // Fallback to module bundle
        return String(format: NSLocalizedString(self, bundle: .module, comment: ""), arguments: arguments)
    }
}

// MARK: - Localization Keys
// Note: These are computed properties to ensure they reflect language changes
struct L10n {
    struct Tab {
        static var current: String { "tab.current".localized }
        static var history: String { "tab.history".localized }
    }
    
    struct Session {
        static var remaining: String { "session.remaining".localized }
        static var remainingTokens: String { "session.remainingTokens".localized }
        static var tokens: String { "session.tokens".localized }
        static var burnRate: String { "session.burnRate".localized }
        static var tokensPerMin: String { "session.tokensPerMin".localized }
        static var timeRemaining: String { "session.timeRemaining".localized }
        static var timeUntilReset: String { "session.timeUntilReset".localized }
        static var cost: String { "session.cost".localized }
        static var referenceValue: String { "session.referenceValue".localized }
        static var noActiveSession: String { "session.noActiveSession".localized }
        static var waitingForData: String { "session.waitingForData".localized }
        static var highUsageWarning: String { "session.highUsageWarning".localized }
        static func used(percentage: String) -> String {
            return "session.used".localized(with: percentage)
        }
        static func resetTime(time: String) -> String {
            return "session.resetTime".localized(with: time)
        }
        static var sessionDetails: String { "session.sessionDetails".localized }
        static var plan: String { "session.plan".localized }
        static var startTime: String { "session.startTime".localized }
        static var endTime: String { "session.endTime".localized }
        static var elapsedTime: String { "session.elapsedTime".localized }
        static var startWorkingMessage: String { "session.startWorkingMessage".localized }
    }
    
    struct History {
        static var usageSummary: String { "history.usageSummary".localized }
        static var currentSession: String { "history.currentSession".localized }
        static var pastSessions: String { "history.pastSessions".localized }
        static func sessionDetails(tokens: String, from: String, to: String) -> String {
            return "history.sessionDetails".localized(with: tokens, from, to)
        }
        static var noHistory: String { "history.noHistory".localized }
        static func tokensFormat(tokens: String) -> String {
            return "history.tokensFormat".localized(with: tokens)
        }
        static var referenceNote: String { "history.referenceNote".localized }
        static var time: String { "history.time".localized }
        static var tokens: String { "history.tokens".localized }
        static var noData: String { "history.noData".localized }
    }
    
    struct Plan {
        static var title: String { "plan.title".localized }
        static var pro: String { "plan.pro".localized }
        static var max5: String { "plan.max5".localized }
        static var max20: String { "plan.max20".localized }
    }
    
    struct Usage {
        static var today: String { "usage.today".localized }
        static var thisMonth: String { "usage.thisMonth".localized }
        static var usage: String { "usage.usage".localized }
        static func percentage(percent: Int) -> String {
            return "usage.percentage".localized(with: percent)
        }
    }
    
    struct Action {
        static var refresh: String { "action.refresh".localized }
        static var settings: String { "action.settings".localized }
        static var quit: String { "action.quit".localized }
        static var close: String { "action.close".localized }
        static var quitApp: String { "action.quitApp".localized }
    }
    
    struct Error {
        static var loadingData: String { "error.loadingData".localized }
        static var dataFetchFailed: String { "error.dataFetchFailed".localized }
        static var networkError: String { "error.networkError".localized }
        static var unknown: String { "error.unknown".localized }
    }
    
    struct Settings {
        static var planSelection: String { "settings.planSelection".localized }
        static var notificationSettings: String { "settings.notificationSettings".localized }
        static var enableUsageNotifications: String { "settings.enableUsageNotifications".localized }
        static var notificationDescription: String { "settings.notificationDescription".localized }
        static var languageSettings: String { "settings.languageSettings".localized }
        static var useSystemLanguage: String { "settings.useSystemLanguage".localized }
        static var selectLanguage: String { "settings.selectLanguage".localized }
        static var languageChangeTitle: String { "settings.languageChangeTitle".localized }
        static var languageChangeMessage: String { "settings.languageChangeMessage".localized }
        static var restartButton: String { "settings.restartButton".localized }
        static var cancelButton: String { "settings.cancelButton".localized }
    }
    
    struct Language {
        static var system: String { "language.system".localized }
        static var english: String { "language.english".localized }
        static var japanese: String { "language.japanese".localized }
    }
    
    struct Notification {
        static var highUsageTitle: String { "notification.highUsage.title".localized }
        static func highUsageBody(percentage: Int, burnRate: Double) -> String {
            return "notification.highUsage.body".localized(with: percentage, burnRate)
        }
        static func highUsageBodyDetailed(percentage: Int, timeRemaining: String, burnRate: Int) -> String {
            return "notification.highUsage.bodyDetailed".localized(with: percentage, timeRemaining, burnRate)
        }
        static var sessionResetTitle: String { "notification.sessionReset.title".localized }
        static var sessionResetBody: String { "notification.sessionReset.body".localized }
        static var sessionResetBodyDetailed: String { "notification.sessionReset.bodyDetailed".localized }
        static var permissionGranted: String { "notification.permissionGranted".localized }
        static func permissionError(error: String) -> String {
            return "notification.permissionError".localized(with: error)
        }
        static var sent90Percent: String { "notification.sent90Percent".localized }
        static func sendError(error: String) -> String {
            return "notification.sendError".localized(with: error)
        }
        static func sessionResetError(error: String) -> String {
            return "notification.sessionResetError".localized(with: error)
        }
    }
    
    struct Time {
        static func hoursMinutes(hours: Int, minutes: Int) -> String {
            return "time.hoursMinutes".localized(with: hours, minutes)
        }
        static func minutes(minutes: Int) -> String {
            return "time.minutes".localized(with: minutes)
        }
    }
    
    struct Status {
        static func lastUpdated(time: String) -> String {
            return "status.lastUpdated".localized(with: time)
        }
        static var loading: String { "status.loading".localized }
        static var noActiveSession: String { "status.noActiveSession".localized }
        static func usageFormat(usage: Double, cost: Double, burnRate: Double, timeRemaining: String) -> String {
            return "status.usageFormat".localized(with: usage, cost, burnRate, timeRemaining)
        }
    }
}