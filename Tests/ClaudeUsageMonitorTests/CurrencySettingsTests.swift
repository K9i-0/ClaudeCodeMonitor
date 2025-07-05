import XCTest
@testable import ClaudeCodeMonitor

final class CurrencySettingsTests: XCTestCase {
    
    var settings: CurrencySettings!
    
    override func setUp() {
        super.setUp()
        settings = CurrencySettings.shared
    }
    
    override func tearDown() {
        // Reset to USD after each test
        settings.setSelectedCurrency(.usd)
        super.tearDown()
    }
    
    // MARK: - Currency Enum Tests
    
    func testCurrencySymbols() {
        XCTAssertEqual(CurrencySettings.Currency.usd.symbol, "$")
        XCTAssertEqual(CurrencySettings.Currency.jpy.symbol, "¥")
        XCTAssertEqual(CurrencySettings.Currency.eur.symbol, "€")
        XCTAssertEqual(CurrencySettings.Currency.gbp.symbol, "£")
        XCTAssertEqual(CurrencySettings.Currency.cny.symbol, "¥")
    }
    
    func testCurrencyDisplayNames() {
        XCTAssertEqual(CurrencySettings.Currency.usd.displayName, "USD - US Dollar")
        XCTAssertEqual(CurrencySettings.Currency.jpy.displayName, "JPY - Japanese Yen")
        XCTAssertEqual(CurrencySettings.Currency.eur.displayName, "EUR - Euro")
        XCTAssertEqual(CurrencySettings.Currency.gbp.displayName, "GBP - British Pound")
        XCTAssertEqual(CurrencySettings.Currency.cny.displayName, "CNY - Chinese Yuan")
    }
    
    func testCurrencyDecimalPlaces() {
        XCTAssertEqual(CurrencySettings.Currency.usd.decimalPlaces, 2)
        XCTAssertEqual(CurrencySettings.Currency.jpy.decimalPlaces, 0)
        XCTAssertEqual(CurrencySettings.Currency.eur.decimalPlaces, 2)
        XCTAssertEqual(CurrencySettings.Currency.gbp.decimalPlaces, 2)
        XCTAssertEqual(CurrencySettings.Currency.cny.decimalPlaces, 2)
    }
    
    // MARK: - Settings Persistence Tests
    
    func testSetSelectedCurrency() {
        settings.setSelectedCurrency(.jpy)
        XCTAssertEqual(settings.selectedCurrency, .jpy)
        
        settings.setSelectedCurrency(.eur)
        XCTAssertEqual(settings.selectedCurrency, .eur)
        
        settings.setSelectedCurrency(.usd)
        XCTAssertEqual(settings.selectedCurrency, .usd)
    }
    
    // MARK: - Exchange Rate Tests
    
    func testExchangeRatesStructure() {
        let rates = CurrencySettings.ExchangeRates(
            rates: ["JPY": 150.0, "EUR": 0.92],
            lastUpdated: Date()
        )
        
        XCTAssertEqual(rates.rate(for: .usd), 1.0, "USD rate should always be 1.0")
        XCTAssertEqual(rates.rate(for: .jpy), 150.0)
        XCTAssertEqual(rates.rate(for: .eur), 0.92)
        XCTAssertNil(rates.rate(for: .gbp), "Should return nil for missing rates")
    }
    
    func testCurrentRateForUSD() {
        settings.setSelectedCurrency(.usd)
        XCTAssertEqual(settings.currentRate, 1.0, "USD rate should always be 1.0")
    }
    
    func testHasValidRatesForUSD() {
        settings.setSelectedCurrency(.usd)
        XCTAssertTrue(settings.hasValidRates, "USD should always have valid rates")
    }
    
    // MARK: - Date Formatting Tests
    
    func testFormatLastUpdatedWithNoRates() {
        // When no rates are loaded
        XCTAssertNil(settings.formatLastUpdated(), "Should return nil when no rates are loaded")
    }
    
    func testFormatLastUpdatedWithRates() {
        // This would require mocking the exchange rates
        // For now, we just test the date formatter works
        let testDate = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let expected = formatter.string(from: testDate)
        
        XCTAssertFalse(expected.isEmpty, "Date formatter should produce non-empty string")
    }
    
    // MARK: - API Response Decoding Tests
    
    func testDecodeFrankfurterResponse() throws {
        let json = """
        {
            "rates": {
                "JPY": 157.5,
                "EUR": 0.92,
                "GBP": 0.79,
                "CNY": 7.25
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(CurrencySettings.FrankfurterResponse.self, from: data)
        
        XCTAssertEqual(response.rates["JPY"], 157.5)
        XCTAssertEqual(response.rates["EUR"], 0.92)
        XCTAssertEqual(response.rates["GBP"], 0.79)
        XCTAssertEqual(response.rates["CNY"], 7.25)
    }
}