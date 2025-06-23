import Foundation
import UserNotifications
import AppKit

@MainActor
class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    private var hasNotified90Percent: Bool = false
    private let userDefaults = UserDefaults.standard
    private let notificationEnabledKey = "ClaudeUsageMonitor.notificationsEnabled"
    private var currentSessionId: String? = nil
    
    var isNotificationEnabled: Bool {
        get { userDefaults.bool(forKey: notificationEnabledKey) }
        set { userDefaults.set(newValue, forKey: notificationEnabledKey) }
    }
    
    override init() {
        super.init()
        // CI環境では初期化しない
        guard ProcessInfo.processInfo.environment["CI"] == nil else { return }
        
        // アプリバンドルから実行されている場合のみ通知を初期化
        if Bundle.main.bundleIdentifier != nil {
            requestNotificationPermission()
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print(L10n.Notification.permissionGranted)
            } else if let error = error {
                print(L10n.Notification.permissionError(error: error.localizedDescription))
            }
        }
    }
    
    func checkAndSendNotification(for percentage: Double, burnRate: Double, remainingTime: String, sessionId: String? = nil) {
        guard isNotificationEnabled else { return }
        guard Bundle.main.bundleIdentifier != nil else { return }
        
        // セッションが変わったらリセット
        if sessionId != currentSessionId {
            hasNotified90Percent = false
            currentSessionId = sessionId
        }
        
        // 90%を超えており、まだ通知していない場合のみ通知
        if percentage >= 90 && !hasNotified90Percent {
            sendUsageNotification(
                percentage: percentage,
                burnRate: burnRate,
                remainingTime: remainingTime
            )
            hasNotified90Percent = true
        }
    }
    
    private func sendUsageNotification(percentage: Double, burnRate: Double, remainingTime: String) {
        let content = UNMutableNotificationContent()
        
        content.title = L10n.Notification.highUsageTitle
        content.body = L10n.Notification.highUsageBodyDetailed(percentage: Int(percentage), timeRemaining: remainingTime, burnRate: Int(burnRate))
        content.sound = .default
        content.categoryIdentifier = "USAGE_ALERT"
        content.threadIdentifier = "claude-usage"
        
        // 通知アクションを追加
        content.userInfo = ["percentage": percentage]
        
        // 即座に通知を送信
        let request = UNNotificationRequest(
            identifier: "usage-90",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print(L10n.Notification.sendError(error: error.localizedDescription))
            } else {
                print(L10n.Notification.sent90Percent)
            }
        }
    }
    
    func sendSessionResetNotification() {
        guard isNotificationEnabled else { return }
        guard Bundle.main.bundleIdentifier != nil else { return }
        
        let content = UNMutableNotificationContent()
        content.title = L10n.Notification.sessionResetTitle
        content.body = L10n.Notification.sessionResetBodyDetailed
        content.sound = .default
        content.categoryIdentifier = "SESSION_RESET"
        content.threadIdentifier = "claude-usage"
        
        let request = UNNotificationRequest(
            identifier: "session-reset",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print(L10n.Notification.sessionResetError(error: error.localizedDescription))
            }
        }
        
        // 通知履歴をリセット
        hasNotified90Percent = false
        currentSessionId = nil
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               willPresent notification: UNNotification, 
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // アプリがフォアグラウンドでも通知を表示
        completionHandler([.banner, .sound])
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               didReceive response: UNNotificationResponse, 
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        // 通知をクリックした時の処理
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            // メインウィンドウを表示
            Task { @MainActor in
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        completionHandler()
    }
}