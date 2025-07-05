import Foundation

/// Manages currency settings and exchange rates for the app
@MainActor
final class CurrencySettings: ObservableObject {
    static let shared = CurrencySettings()
    
    // MARK: - Types
    
    enum Currency: String, CaseIterable, Codable {
        case usd = "USD"
        case jpy = "JPY"
        case eur = "EUR"
        case gbp = "GBP"
        case cny = "CNY"
        
        var symbol: String {
            switch self {
            case .usd: return "$"
            case .jpy: return "¥"
            case .eur: return "€"
            case .gbp: return "£"
            case .cny: return "¥"
            }
        }
        
        var displayName: String {
            switch self {
            case .usd: return "USD - US Dollar"
            case .jpy: return "JPY - Japanese Yen"
            case .eur: return "EUR - Euro"
            case .gbp: return "GBP - British Pound"
            case .cny: return "CNY - Chinese Yuan"
            }
        }
        
        /// Number of decimal places to display for this currency
        var decimalPlaces: Int {
            switch self {
            case .jpy: return 0  // JPY doesn't use decimal places
            default: return 2
            }
        }
    }
    
    struct ExchangeRates: Codable {
        let rates: [String: Double]
        let lastUpdated: Date
        
        func rate(for currency: Currency) -> Double? {
            guard currency != .usd else { return 1.0 }
            return rates[currency.rawValue]
        }
    }
    
    struct FrankfurterResponse: Codable {
        let rates: [String: Double]
    }
    
    // MARK: - Properties
    
    @Published private(set) var selectedCurrency: Currency = .usd
    @Published private(set) var exchangeRates: ExchangeRates?
    @Published private(set) var isLoadingRates = false
    @Published private(set) var ratesFetchError: String?
    
    private let userDefaults = UserDefaultsManager.shared
    private let cacheExpirationHours: TimeInterval = 24
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let selectedCurrency = "selectedCurrency"
        static let cachedRates = "cachedExchangeRates"
    }
    
    // MARK: - Initialization
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    /// Set the selected currency
    func setSelectedCurrency(_ currency: Currency) {
        selectedCurrency = currency
        saveSettings()
    }
    
    /// Fetch exchange rates from Frankfurter API
    func fetchExchangeRates() async {
        // Check cache first
        if let cached = exchangeRates,
           Date().timeIntervalSince(cached.lastUpdated) < cacheExpirationHours * 3600 {
            return // Use cached rates
        }
        
        isLoadingRates = true
        ratesFetchError = nil
        
        do {
            let rates = try await fetchRatesFromAPI()
            exchangeRates = ExchangeRates(rates: rates, lastUpdated: Date())
            saveRatesToCache()
            ratesFetchError = nil
        } catch {
            ratesFetchError = error.localizedDescription
            // Keep using cached rates if available, otherwise USD only
        }
        
        isLoadingRates = false
    }
    
    /// Get the exchange rate for the selected currency
    var currentRate: Double {
        guard selectedCurrency != .usd else { return 1.0 }
        return exchangeRates?.rate(for: selectedCurrency) ?? 1.0
    }
    
    /// Check if we have valid exchange rates
    var hasValidRates: Bool {
        selectedCurrency == .usd || exchangeRates?.rate(for: selectedCurrency) != nil
    }
    
    /// Format a date for display
    func formatLastUpdated() -> String? {
        guard let lastUpdated = exchangeRates?.lastUpdated else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastUpdated)
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        // Load selected currency
        if let currencyString = userDefaults.string(forKey: Keys.selectedCurrency),
           let currency = Currency(rawValue: currencyString) {
            selectedCurrency = currency
        }
        
        // Load cached rates
        if let data = userDefaults.data(forKey: Keys.cachedRates),
           let cached = try? JSONDecoder().decode(ExchangeRates.self, from: data) {
            exchangeRates = cached
        }
    }
    
    private func saveSettings() {
        userDefaults.set(selectedCurrency.rawValue, forKey: Keys.selectedCurrency)
    }
    
    private func saveRatesToCache() {
        guard let rates = exchangeRates,
              let data = try? JSONEncoder().encode(rates) else { return }
        userDefaults.set(data, forKey: Keys.cachedRates)
    }
    
    private func fetchRatesFromAPI() async throws -> [String: Double] {
        let currencies = Currency.allCases
            .filter { $0 != .usd }
            .map { $0.rawValue }
            .joined(separator: ",")
        
        guard let url = URL(string: "https://api.frankfurter.app/latest?from=USD&to=\(currencies)") else {
            throw URLError(.badURL)
        }
        
        let request = URLRequest(url: url, timeoutInterval: 5.0)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
        
        return response.rates
    }
}