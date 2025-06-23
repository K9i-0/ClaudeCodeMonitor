import Foundation
import UserNotifications
import AppKit

@MainActor
class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    private var lastNotificationPercentage: Double = 0
    private let notificationThresholds: [Double] = [70, 80, 90, 95]
    private let userDefaults = UserDefaults.standard
    private let notificationEnabledKey = "ClaudeUsageMonitor.notificationsEnabled"
    
    var isNotificationEnabled: Bool {
        get { userDefaults.bool(forKey: notificationEnabledKey) }
        set { userDefaults.set(newValue, forKey: notificationEnabledKey) }
    }
    
    override init() {
        super.init()
        requestNotificationPermission()
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知許可が得られました")
            } else if let error = error {
                print("通知許可エラー: \(error)")
            }
        }
    }
    
    func checkAndSendNotification(for percentage: Double, burnRate: Double, remainingTime: String) {
        guard isNotificationEnabled else { return }
        
        // 使用率が前回の通知時より下がった場合はリセット
        if percentage < lastNotificationPercentage - 5 {
            lastNotificationPercentage = 0
        }
        
        // 閾値を超えているかチェック
        for threshold in notificationThresholds {
            if percentage >= threshold && lastNotificationPercentage < threshold {
                sendUsageNotification(
                    percentage: percentage,
                    threshold: threshold,
                    burnRate: burnRate,
                    remainingTime: remainingTime
                )
                lastNotificationPercentage = percentage
                break
            }
        }
    }
    
    private func sendUsageNotification(percentage: Double, threshold: Double, burnRate: Double, remainingTime: String) {
        let content = UNMutableNotificationContent()
        
        // タイトルとボディを使用率に応じて設定
        switch threshold {
        case 95:
            content.title = "⚠️ 使用率が限界に近づいています"
            content.body = "現在の使用率: \(Int(percentage))%\n残り時間: \(remainingTime)"
            content.sound = .defaultCritical
        case 90:
            content.title = "🔥 使用率が非常に高い状態です"
            content.body = "現在の使用率: \(Int(percentage))%\n燃焼率: \(Int(burnRate)) tokens/分"
            content.sound = .default
        case 80:
            content.title = "⚡ 使用率が高くなっています"
            content.body = "現在の使用率: \(Int(percentage))%\nペースを調整することをお勧めします"
            content.sound = .default
        default:
            content.title = "📊 使用率が\(Int(threshold))%を超えました"
            content.body = "現在の使用率: \(Int(percentage))%"
            content.sound = nil
        }
        
        content.categoryIdentifier = "USAGE_ALERT"
        content.threadIdentifier = "claude-usage"
        
        // 通知アクションを追加
        content.userInfo = ["percentage": percentage]
        
        // 即座に通知を送信
        let request = UNNotificationRequest(
            identifier: "usage-\(Int(threshold))",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知送信エラー: \(error)")
            } else {
                print("通知を送信しました: \(Int(percentage))%")
            }
        }
    }
    
    func sendSessionResetNotification() {
        guard isNotificationEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "✨ セッションがリセットされました"
        content.body = "新しい5時間セッションが開始されました"
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
                print("セッションリセット通知エラー: \(error)")
            }
        }
        
        // 通知履歴をリセット
        lastNotificationPercentage = 0
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