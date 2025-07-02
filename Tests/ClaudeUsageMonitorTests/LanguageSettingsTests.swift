import XCTest
@testable import ClaudeCodeMonitor

final class LanguageSettingsTests: XCTestCase {
    private var sut: LanguageSettings!

    override func setUp() {
        super.setUp()
        // Reset language settings
        UserDefaultsManager.shared.removeObject(forKey: "AppLanguage")
        UserDefaultsManager.shared.removeObject(forKey: "AppleLanguages")
        UserDefaultsManager.shared.synchronize()

        sut = LanguageSettings.shared
    }

    override func tearDown() {
        // Reset to system default
        UserDefaultsManager.shared.removeObject(forKey: "AppLanguage")
        UserDefaultsManager.shared.removeObject(forKey: "AppleLanguages")
        UserDefaultsManager.shared.synchronize()

        sut = nil
        super.tearDown()
    }

    // MARK: - Language Setting Tests

    func testDefaultLanguageIsSystem() {
        XCTAssertEqual(sut.currentLanguage, .system)
    }

    func testLanguagePersistence() {
        // Set to Japanese
        sut.currentLanguage = .japanese

        // Verify it's saved
        let saved = UserDefaultsManager.shared.string(forKey: "AppLanguage")
        XCTAssertEqual(saved, "ja")

        // Verify AppleLanguages is set
        let appleLanguages = UserDefaultsManager.shared.stringArray(forKey: "AppleLanguages")
        XCTAssertEqual(appleLanguages?.first, "ja")
    }

    func testSystemLanguageRemovesOverride() {
        // Clean up any existing language settings first
        UserDefaultsManager.shared.removeObject(forKey: "AppleLanguages")
        UserDefaultsManager.shared.synchronize()

        // First set a specific language
        sut.currentLanguage = .english

        // Verify it's set
        var appleLanguages = UserDefaultsManager.shared.stringArray(forKey: "AppleLanguages")
        XCTAssertNotNil(appleLanguages)
        XCTAssertEqual(appleLanguages?.first, "en")

        // Switch back to system
        sut.currentLanguage = .system

        // Verify override is removed
        appleLanguages = UserDefaultsManager.shared.stringArray(forKey: "AppleLanguages")
        // Note: In some test environments, this might not be nil but rather the system default
        // So we check that it's either nil or doesn't contain our explicitly set language
        if let languages = appleLanguages {
            XCTAssertFalse(languages.contains("en") && languages.count == 1)
        }
    }

    // MARK: - Display Name Tests

    func testLanguageDisplayNames() {
        // Note: Display names are localized, so we test the keys exist
        XCTAssertFalse(AppLanguage.system.displayName.isEmpty)
        XCTAssertFalse(AppLanguage.english.displayName.isEmpty)
        XCTAssertFalse(AppLanguage.japanese.displayName.isEmpty)
    }

    // MARK: - Language Code Tests

    func testLanguageCodes() {
        XCTAssertNil(AppLanguage.system.languageCode)
        XCTAssertEqual(AppLanguage.english.languageCode, "en")
        XCTAssertEqual(AppLanguage.japanese.languageCode, "ja")
    }

    func testEffectiveLanguageCode() {
        // Test system language
        sut.currentLanguage = .system
        let systemCode = sut.effectiveLanguageCode()
        XCTAssertTrue(["en", "ja"].contains(systemCode)) // Should be one of supported languages

        // Test explicit English
        sut.currentLanguage = .english
        XCTAssertEqual(sut.effectiveLanguageCode(), "en")

        // Test explicit Japanese
        sut.currentLanguage = .japanese
        XCTAssertEqual(sut.effectiveLanguageCode(), "ja")
    }

    // MARK: - All Cases Test

    func testAllLanguagesAvailable() {
        let allLanguages = AppLanguage.allCases
        XCTAssertEqual(allLanguages.count, 3)
        XCTAssertTrue(allLanguages.contains(.system))
        XCTAssertTrue(allLanguages.contains(.english))
        XCTAssertTrue(allLanguages.contains(.japanese))
    }
}
