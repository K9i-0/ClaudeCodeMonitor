import Foundation

extension UserDefaults {
    private enum Keys {
        static let updateChannel = "UpdateChannel"
    }
    
    var updateChannel: UpdateChannel {
        get {
            guard let rawValue = string(forKey: Keys.updateChannel),
                  let channel = UpdateChannel(rawValue: rawValue) else {
                // Auto-detect based on current version
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                return UpdateChannel.fromVersion(version)
            }
            return channel
        }
        set {
            set(newValue.rawValue, forKey: Keys.updateChannel)
        }
    }
}