import Foundation

/// Utility class for converting USD amounts to other currencies
enum CurrencyConverter {
    
    /// Simple format function without MainActor for use in data models
    static func simpleFormatCost(_ usdAmount: Double) -> String {
        return String(format: "$%.2f", usdAmount)
    }
    
    /// Convert USD amount to the selected currency
    @MainActor
    static func convert(_ usdAmount: Double, to currency: CurrencySettings.Currency, using settings: CurrencySettings) -> Double {
        guard currency != .usd else { return usdAmount }
        
        let rate = settings.currentRate
        return usdAmount * rate
    }
    
    /// Format a cost value in the selected currency
    @MainActor
    static func formatCost(_ usdAmount: Double, currency: CurrencySettings.Currency, using settings: CurrencySettings) -> String {
        let convertedAmount = convert(usdAmount, to: currency, using: settings)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        formatter.currencySymbol = currency.symbol
        formatter.maximumFractionDigits = currency.decimalPlaces
        formatter.minimumFractionDigits = currency.decimalPlaces
        
        // For Japanese Yen and Chinese Yuan, use locale-specific formatting
        switch currency {
        case .jpy:
            formatter.locale = Locale(identifier: "ja_JP")
        case .cny:
            formatter.locale = Locale(identifier: "zh_CN")
        default:
            break
        }
        
        return formatter.string(from: NSNumber(value: convertedAmount)) ?? "\(currency.symbol)\(convertedAmount)"
    }
    
    /// Format a cost value with fallback to USD if conversion fails
    @MainActor
    static func formatCostWithFallback(_ usdAmount: Double, using settings: CurrencySettings) -> String {
        let currency = settings.selectedCurrency
        
        // If no valid rates and not USD, fall back to USD
        if !settings.hasValidRates && currency != .usd {
            return String(format: "$%.2f", usdAmount)
        }
        
        return formatCost(usdAmount, currency: currency, using: settings)
    }
    
    /// Get display text for currency with optional rate info
    @MainActor
    static func getCurrencyDisplayText(for currency: CurrencySettings.Currency, using settings: CurrencySettings) -> String {
        guard currency != .usd else { return currency.displayName }
        
        if let rate = settings.exchangeRates?.rate(for: currency) {
            return "\(currency.displayName) (\(String(format: "%.2f", rate)))"
        } else {
            return currency.displayName
        }
    }
}