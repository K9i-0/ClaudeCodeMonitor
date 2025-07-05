import Foundation

enum BundleConfiguration {
    static var bundleIdentifier: String {
        #if DEBUG
        return "com.k9i.ClaudeCodeMonitor.debug"
        #else
        return "com.k9i.ClaudeCodeMonitor"
        #endif
    }

    static var appName: String {
        #if DEBUG
        return "ClaudeCodeMonitor-Debug"
        #else
        return "ClaudeCodeMonitor"
        #endif
    }

    static var ccusageVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: "CcusageVersion") as? String ?? ""
    }
}
