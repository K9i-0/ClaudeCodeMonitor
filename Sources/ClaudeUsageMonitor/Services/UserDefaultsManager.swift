import Foundation

/// Manages UserDefaults with different suites for Debug/Release builds
enum UserDefaultsManager {
    private static let suiteName: String = {
        #if DEBUG
        return "com.k9i.ClaudeCodeMonitor.debug"
        #else
        return "com.k9i.ClaudeCodeMonitor"
        #endif
    }()

    private static let releaseSuiteName = "com.k9i.ClaudeCodeMonitor"

    static var shared: UserDefaults {
        return UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
    }

    /// Read-only access to release settings for migration
    static var releaseDefaults: UserDefaults? {
        #if DEBUG
        return UserDefaults(suiteName: releaseSuiteName)
        #else
        return nil
        #endif
    }
}
