import Foundation

enum UpdateChannel: String, CaseIterable {
    case stable = "stable"
    case dev = "dev"
    
    var displayName: String {
        switch self {
        case .stable:
            return L10n.Update.stableChannel
        case .dev:
            return L10n.Update.devChannel
        }
    }
    
    var appcastURL: String {
        switch self {
        case .stable:
            return "https://github.com/K9i-0/ClaudeCodeMonitor/releases/latest/download/appcast.xml"
        case .dev:
            return "https://github.com/K9i-0/ClaudeCodeMonitor/releases/latest/download/appcast-dev.xml"
        }
    }
    
    var description: String {
        switch self {
        case .stable:
            return L10n.Update.stableChannelDescription
        case .dev:
            return L10n.Update.devChannelDescription
        }
    }
    
    static func fromVersion(_ version: String) -> UpdateChannel {
        // If version contains "-dev", it's a dev channel
        return version.contains("-dev") ? .dev : .stable
    }
}