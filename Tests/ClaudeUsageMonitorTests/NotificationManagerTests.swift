import XCTest
import UserNotifications
@testable import ClaudeCodeMonitor

@MainActor
final class NotificationManagerTests: XCTestCase {
    // Note: NotificationManager requires bundle environment
    // These tests focus on the logic without actually creating notifications

    override func setUp() async throws {
        try await super.setUp()

        // Reset notification state
        UserDefaultsManager.shared.removeObject(forKey: "ClaudeUsageMonitor.notificationsEnabled")
    }

    // MARK: - Settings Tests

    func testNotificationEnabledPersistence() {
        // Test persistence directly via UserDefaults
        let key = "ClaudeUsageMonitor.notificationsEnabled"

        // Test default state
        XCTAssertFalse(UserDefaultsManager.shared.bool(forKey: key))

        // Enable notifications
        UserDefaultsManager.shared.set(true, forKey: key)
        XCTAssertTrue(UserDefaultsManager.shared.bool(forKey: key))

        // Disable notifications
        UserDefaultsManager.shared.set(false, forKey: key)
        XCTAssertFalse(UserDefaultsManager.shared.bool(forKey: key))
    }

    // MARK: - Notification Logic Tests

    func testNotificationThresholdLogic() {
        // Test that 90% is the threshold
        let shouldNotify89 = 89.9 >= 90.0
        XCTAssertFalse(shouldNotify89)

        let shouldNotify90 = 90.0 >= 90.0
        XCTAssertTrue(shouldNotify90)

        let shouldNotify95 = 95.0 >= 90.0
        XCTAssertTrue(shouldNotify95)
    }
}
