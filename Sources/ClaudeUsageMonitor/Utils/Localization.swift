import Foundation
import SwiftUI

// MARK: - Resource Bundle Helper
struct ResourceBundle {
    static let current: Bundle = {
        let bundleName = "ClaudeCodeMonitor_ClaudeCodeMonitor.bundle"

        // Try different possible locations in order of preference
        let candidates = [
            // 1. macOS app bundle structure (production)
            Bundle.main.bundleURL
                .appendingPathComponent("Contents/Resources/\(bundleName)"),

            // 2. Same directory as executable (SwiftPM default behavior)
            Bundle.main.bundleURL
                .appendingPathComponent(bundleName),

            // 3. Parent directory (some development scenarios)
            Bundle.main.bundleURL
                .deletingLastPathComponent()
                .appendingPathComponent(bundleName)
        ]

        // Try each candidate path
        for candidate in candidates {
            if let bundle = Bundle(url: candidate) {
                return bundle
            }
        }

        // Fallback: use main bundle
        return Bundle.main
    }()
}

// MARK: - Localization Helper
extension String {
    var localized: String {
        // In CI environment, return the key itself to avoid Bundle.module issues
        guard ProcessInfo.processInfo.environment["CI"] == nil else {
            return self
        }

        let languageCode = LanguageSettings.shared.effectiveLanguageCode()
        let resourceBundle = ResourceBundle.current

        // Try to get the bundle for the specific language
        if let path = resourceBundle.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return NSLocalizedString(self, bundle: bundle, comment: "")
        }

        // Fallback to module bundle
        return NSLocalizedString(self, bundle: resourceBundle, comment: "")
    }

    func localized(with arguments: CVarArg...) -> String {
        // In CI environment, return formatted string with key to avoid Bundle.module issues
        guard ProcessInfo.processInfo.environment["CI"] == nil else {
            return String(format: self, arguments: arguments)
        }

        let languageCode = LanguageSettings.shared.effectiveLanguageCode()
        let resourceBundle = ResourceBundle.current

        // Try to get the bundle for the specific language
        if let path = resourceBundle.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return String(format: NSLocalizedString(self, bundle: bundle, comment: ""), arguments: arguments)
        }

        // Fallback to module bundle
        return String(format: NSLocalizedString(self, bundle: resourceBundle, comment: ""), arguments: arguments)
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
        static func tokensConsumed(tokens: String) -> String {
            return "session.tokensConsumed".localized(with: tokens)
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
        static var monthSummary: String { "history.monthSummary".localized }
        static var total: String { "history.total".localized }
        static var dailyAverage: String { "history.dailyAverage".localized }
        static var peak: String { "history.peak".localized }
        static var today: String { "history.today".localized }
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
        static var installClaudeCode: String { "action.installClaudeCode".localized }
        static var installBun: String { "action.installBun".localized }
        static var installNode: String { "action.installNode".localized }
        static var checkAgain: String { "action.checkAgain".localized }
    }

    struct Error {
        static var loadingData: String { "error.loadingData".localized }
        static var dataFetchFailed: String { "error.dataFetchFailed".localized }
        static var networkError: String { "error.networkError".localized }
        static var unknown: String { "error.unknown".localized }
        static func commandNotFound(command: String) -> String {
            return "error.commandNotFound".localized(with: command)
        }
        static func commandExecutionFailed(message: String) -> String {
            return "error.commandExecutionFailed".localized(with: message)
        }
        static var outputDecodingFailed: String { "error.outputDecodingFailed".localized }

        struct Recovery {
            static var installNodeOrBun: String { "error.recovery.installNodeOrBun".localized }
            static var checkCommandInstallation: String { "error.recovery.checkCommandInstallation".localized }
            static var updateCcusage: String { "error.recovery.updateCcusage".localized }
        }
    }

    struct Settings {
        static var planSelection: String { "settings.planSelection".localized }
        static var notificationSettings: String { "settings.notificationSettings".localized }
        static var enableUsageNotifications: String { "settings.enableUsageNotifications".localized }
        static var notificationDescription: String { "settings.notificationDescription".localized }
        static var languageSettings: String { "settings.languageSettings".localized }
        static var useSystemLanguage: String { "settings.useSystemLanguage".localized }
        static var selectLanguage: String { "settings.selectLanguage".localized }
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
        static var today: String { "time.today".localized }
        static var tomorrow: String { "time.tomorrow".localized }
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

    // General
    static var ok: String { "ok".localized }
    static var error: String { "error".localized }
    static var select: String { "select".localized }

    // Environment setup
    struct Environment {
        static var setupRequired: String { "environment.setupRequired".localized }
        static var allRequirementsMet: String { "environment.allRequirementsMet".localized }
        static var pleaseRestart: String { "environment.pleaseRestart".localized }
        static var debugRestartNote: String { "environment.debugRestartNote".localized }
        static var nodeOrBunRequired: String { "environment.nodeOrBunRequired".localized }
        static var afterInstallation: String { "environment.afterInstallation".localized }
        static var installed: String { "environment.installed".localized }
        static var optional: String { "environment.optional".localized }
    }

    // Claude Data Access
    static var selectClaudeDataFolder: String { "selectClaudeDataFolder".localized }
    static var claudeDataFolderMessage: String { "claudeDataFolderMessage".localized }
    static var invalidClaudeFolder: String { "invalidClaudeFolder".localized }
    static var failedToSaveAccess: String { "failedToSaveAccess".localized }

    // Share Text
    struct Share {
        static var hashtags: String { "share.hashtags".localized }

        struct CurrentSession {
            static var consuming: String { "share.currentSession.consuming".localized }
            static var resetIn: String { "share.currentSession.resetIn".localized }
            static var noSession: String { "share.currentSession.noSession".localized }
        }

        struct History {
            static var title: String { "share.history.title".localized }
            static var today: String { "share.history.today".localized }
            static var month: String { "share.history.month".localized }
        }
    }
}
