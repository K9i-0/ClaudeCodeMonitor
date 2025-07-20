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
        let version = Bundle.main.object(forInfoDictionaryKey: "CcusageVersion") as? String ?? ""
        let fallbackVersion = "15.3.0"
        
        // Debug時にInfo.plistが更新されていない場合のフォールバック
        if version.isEmpty {
            print("⚠️ [BundleConfiguration] CcusageVersion not found in Info.plist, using fallback: \(fallbackVersion)")
            return fallbackVersion
        }
        
        print("📦 [BundleConfiguration] Using ccusage version: \(version)")
        return version
    }
}
