import Foundation

enum AppLanguage: String, CaseIterable {
    case system = "system"
    case english = "en"
    case japanese = "ja"

    var displayName: String {
        // In CI environment, return raw values to avoid localization issues
        guard ProcessInfo.processInfo.environment["CI"] == nil else {
            switch self {
            case .system:
                return "System"
            case .english:
                return "English"
            case .japanese:
                return "Japanese"
            }
        }

        switch self {
        case .system:
            return L10n.Language.system
        case .english:
            return L10n.Language.english
        case .japanese:
            return L10n.Language.japanese
        }
    }

    var languageCode: String? {
        switch self {
        case .system:
            return nil
        case .english:
            return "en"
        case .japanese:
            return "ja"
        }
    }
}

class LanguageSettings: ObservableObject {
    static let shared = LanguageSettings()

    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaultsManager.shared.set(currentLanguage.rawValue, forKey: "AppLanguage")
            applyLanguage()
        }
    }

    private init() {
        let savedLanguage = UserDefaultsManager.shared.string(forKey: "AppLanguage") ?? AppLanguage.system.rawValue
        self.currentLanguage = AppLanguage(rawValue: savedLanguage) ?? .system
        applyLanguage()
    }

    private func applyLanguage() {
        if let languageCode = currentLanguage.languageCode {
            UserDefaultsManager.shared.set([languageCode], forKey: "AppleLanguages")
        } else {
            UserDefaultsManager.shared.removeObject(forKey: "AppleLanguages")
        }
        UserDefaultsManager.shared.synchronize()
    }

    func effectiveLanguageCode() -> String {
        if let code = currentLanguage.languageCode {
            return code
        }
        return Bundle.main.preferredLocalizations.first ?? "en"
    }
}
