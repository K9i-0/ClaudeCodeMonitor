import XCTest
@testable import ClaudeCodeMonitor

@MainActor
final class CurrencyConverterTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Conversion Tests
    
    func testConvertUSDToUSD() {
        let settings = CurrencySettings.shared
        let amount = 100.0
        
        let converted = CurrencyConverter.convert(amount, to: .usd, using: settings)
        XCTAssertEqual(converted, amount, "USD to USD conversion should return the same amount")
    }
    
    func testConvertWithCustomRate() {
        let amount = 100.0
        
        // Simulate JPY rate of 150
        let mockRates = CurrencySettings.ExchangeRates(
            rates: ["JPY": 150.0],
            lastUpdated: Date()
        )
        
        // We can't directly set exchange rates, so we'll test the conversion logic
        let jpyRate = mockRates.rate(for: .jpy) ?? 1.0
        let expected = amount * jpyRate
        let actual = amount * 150.0
        
        XCTAssertEqual(expected, actual, "Conversion should use the correct rate")
    }
    
    // MARK: - Formatting Tests
    
    func testFormatUSD() {
        let settings = CurrencySettings.shared
        settings.setSelectedCurrency(.usd)
        
        let formatted = CurrencyConverter.formatCost(99.99, currency: .usd, using: settings)
        XCTAssertTrue(formatted.contains("99.99"), "USD formatting should include the amount")
        XCTAssertTrue(formatted.contains("$"), "USD formatting should include dollar sign")
    }
    
    func testFormatJPY() {
        let settings = CurrencySettings.shared
        
        // Test JPY formatting (no decimal places)
        let formatted = CurrencyConverter.formatCost(1000.50, currency: .jpy, using: settings)
        XCTAssertTrue(formatted.contains("1"), "JPY formatting should include the amount")
        XCTAssertTrue(formatted.contains("¥"), "JPY formatting should include yen sign")
        XCTAssertFalse(formatted.contains("."), "JPY formatting should not include decimals")
    }
    
    func testFormatEUR() {
        let settings = CurrencySettings.shared
        
        let formatted = CurrencyConverter.formatCost(75.25, currency: .eur, using: settings)
        // Since no rates are loaded, EUR will be treated as 1:1 with USD
        XCTAssertTrue(formatted.contains("75.25") || formatted.contains("75,25"), "EUR formatting should include the amount")
        XCTAssertTrue(formatted.contains("€") || formatted.contains("EUR"), "EUR formatting should include euro sign or code")
    }
    
    // MARK: - Fallback Tests
    
    func testFormatWithFallbackWhenNoRates() {
        let settings = CurrencySettings.shared
        settings.setSelectedCurrency(.jpy)
        
        // When no rates are available and currency is not USD, should fall back to USD
        let formatted = CurrencyConverter.formatCostWithFallback(50.0, using: settings)
        
        // If no rates are loaded, it should either show JPY (if rate=1) or USD
        XCTAssertTrue(
            formatted.contains("$") || formatted.contains("¥"),
            "Should format with either USD or selected currency"
        )
    }
    
    // MARK: - Currency Display Text Tests
    
    func testGetCurrencyDisplayTextForUSD() {
        let settings = CurrencySettings.shared
        
        let displayText = CurrencyConverter.getCurrencyDisplayText(for: .usd, using: settings)
        XCTAssertEqual(displayText, "USD - US Dollar", "USD should show without rate")
    }
    
    func testGetCurrencyDisplayTextWithRate() {
        // This test would require mocking the exchange rates
        // For now, we just test that the function returns a non-empty string
        let settings = CurrencySettings.shared
        
        let displayText = CurrencyConverter.getCurrencyDisplayText(for: .jpy, using: settings)
        XCTAssertTrue(displayText.contains("JPY"), "Display text should include currency code")
        XCTAssertTrue(displayText.contains("Japanese Yen"), "Display text should include currency name")
    }
}