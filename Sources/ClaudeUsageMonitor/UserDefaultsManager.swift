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
    
    static var shared: UserDefaults {
        return UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
    }
}