import SwiftUI
#if canImport(Sparkle)
import Sparkle
#endif

struct SettingsTabView: View {
    @EnvironmentObject var monitor: UsageMonitor
    @StateObject private var languageSettings = LanguageSettings.shared
    @StateObject private var currencySettings = CurrencySettings.shared
    // @State private var notificationEnabled = Bundle.main.bundleIdentifier != nil ? NotificationManager.shared.isNotificationEnabled : false
    @State private var latestVersion: String?
    @State private var isCheckingForUpdates = false
    @State private var updateCheckError: String?
    @State private var latestStableVersion: String?
    @State private var latestDevVersion: String?
    #if canImport(Sparkle)
        #if DEBUG
        // Get updater from AppDelegate in debug builds
        private var updater: SPUUpdater? {
            if let appDelegate = NSApplication.shared.delegate as? AppDelegate,
               let controller = appDelegate.value(forKey: "updaterController") as? SPUStandardUpdaterController {
                return controller.updater
            }
            return nil
        }
        #else
        private let updater = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil).updater
        #endif
    #else
    private var updater: AnyObject? {
        return nil
    }
    #endif

    let plans = [
        ("Pro", "7,000 tokens/session", L10n.Plan.pro),
        ("Max5", "35,000 tokens/session", L10n.Plan.max5),
        ("Max20", "140,000 tokens/session", L10n.Plan.max20)
    ]

    var body: some View {
        VStack(spacing: 20) {
            // Plan selection section
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.Settings.planSelection)
                    .font(.system(size: 16, weight: .semibold))

                VStack(spacing: 8) {
                    ForEach(plans, id: \.0) { plan in
                        Button(action: {
                            monitor.setUserPlan(plan.0)
                        }) {
                            HStack {
                                Image(systemName: monitor.getUserPlan() == plan.0 ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(monitor.getUserPlan() == plan.0 ? .accentColor : .secondary)
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(plan.2)
                                        .font(.system(size: 14, weight: .medium))
                                    Text(plan.1)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(monitor.getUserPlan() == plan.0 ? Color.accentColor.opacity(0.1) : Color.clear)
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }

            Divider()

            // Language settings section
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.Settings.languageSettings)
                    .font(.system(size: 16, weight: .semibold))

                VStack(spacing: 8) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Button(action: {
                            languageSettings.currentLanguage = language
                        }) {
                            HStack {
                                Image(systemName: languageSettings.currentLanguage == language
                                    ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(languageSettings.currentLanguage == language
                                        ? .accentColor : .secondary)
                                    .frame(width: 20)

                                Text(language.displayName)
                                    .font(.system(size: 14))

                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(languageSettings.currentLanguage == language
                                ? Color.accentColor.opacity(0.1) : Color.clear)
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }

            Divider()

            // Currency settings section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(L10n.Settings.currencySettings)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Spacer()
                    
                    if currencySettings.isLoadingRates {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                }

                VStack(spacing: 8) {
                    ForEach(CurrencySettings.Currency.allCases, id: \.self) { currency in
                        Button(action: {
                            currencySettings.setSelectedCurrency(currency)
                        }) {
                            HStack {
                                Image(systemName: currencySettings.selectedCurrency == currency
                                    ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(currencySettings.selectedCurrency == currency
                                        ? .accentColor : .secondary)
                                    .frame(width: 20)

                                Text(CurrencyConverter.getCurrencyDisplayText(for: currency, using: currencySettings))
                                    .font(.system(size: 14))

                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(currencySettings.selectedCurrency == currency
                                ? Color.accentColor.opacity(0.1) : Color.clear)
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Show exchange rate info
                if let lastUpdated = currencySettings.formatLastUpdated() {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text(L10n.Settings.lastUpdated(date: lastUpdated))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
                
                if currencySettings.ratesFetchError != nil {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                        Text(L10n.Settings.rateFetchFailed)
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                    }
                    .padding(.top, 4)
                }
            }

            // 通知機能は初回リリースでは無効化
            /*
            Divider()
            
            // Notification settings section
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.Settings.notificationSettings)
                    .font(.system(size: 16, weight: .semibold))
                
                Toggle(isOn: $notificationEnabled) {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(notificationEnabled ? .blue : .secondary)
                        Text(L10n.Settings.enableUsageNotifications)
                            .font(.system(size: 14))
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .onChange(of: notificationEnabled) { newValue in
                    if Bundle.main.bundleIdentifier != nil {
                        NotificationManager.shared.isNotificationEnabled = newValue
                        if newValue {
                            NotificationManager.shared.requestNotificationPermission()
                        }
                    }
                }
                
                if notificationEnabled {
                    Text(L10n.Settings.notificationDescription)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 26)
                }
            }
            */

            // Show update settings in release builds or when testing Sparkle
            #if DEBUG
            Divider()
            
            // Update settings section
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.Update.settings)
                    .font(.system(size: 16, weight: .semibold))

                // Current version
                let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
                HStack {
                    Text(L10n.Update.currentVersion(version: currentVersion))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    #if DEBUG
                    Text("(Debug)")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                    #endif
                }
                
                // Latest version info
                if isCheckingForUpdates {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Checking for updates...")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else if let error = updateCheckError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Spacer()
                    }
                } else if let latest = latestVersion {
                    HStack {
                        Text("Latest: \(latest)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                Spacer()
                    .frame(height: 4)
                
                // Update channel selection
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Update.updateChannel)
                        .font(.system(size: 14, weight: .medium))
                    
                    ForEach(UpdateChannel.allCases, id: \.self) { channel in
                        Button(action: {
                            selectUpdateChannel(channel)
                        }) {
                            HStack {
                                Image(systemName: UserDefaults.standard.updateChannel == channel ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(UserDefaults.standard.updateChannel == channel ? .accentColor : .secondary)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(channel.displayName)
                                            .font(.system(size: 14, weight: .medium))
                                        if channel == .stable {
                                            Text(L10n.Update.recommended)
                                                .font(.system(size: 11))
                                                .foregroundColor(.green)
                                        }
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Text(channel.description)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                        
                                        if channel == .stable && latestStableVersion != nil {
                                            Text("•")
                                                .foregroundColor(.secondary.opacity(0.5))
                                            Text(L10n.Update.latestVersion(version: latestStableVersion!))
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        } else if channel == .dev && latestDevVersion != nil {
                                            Text("•")
                                                .foregroundColor(.secondary.opacity(0.5))
                                            Text(L10n.Update.latestVersion(version: latestDevVersion!))
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(UserDefaults.standard.updateChannel == channel ? Color.accentColor.opacity(0.1) : Color.clear)
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.bottom, 8)

                // Check for updates button
                Button(action: {
                    #if DEBUG
                    if let updater = updater {
                        updater.checkForUpdates()
                    } else {
                        // In Debug mode without updater, manually check appcast
                        checkLatestVersion()
                    }
                    #else
                    updater.checkForUpdates()
                    #endif
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14))
                        Text(L10n.Update.checkForUpdates)
                            .font(.system(size: 14))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())

                // Automatic updates toggle
                Toggle(isOn: .init(
                    get: { 
                        #if DEBUG
                        updater?.automaticallyChecksForUpdates ?? false
                        #else
                        updater.automaticallyChecksForUpdates
                        #endif
                    },
                    set: { 
                        #if DEBUG
                        updater?.automaticallyChecksForUpdates = $0
                        #else
                        updater.automaticallyChecksForUpdates = $0
                        #endif
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.Update.automaticUpdates)
                            .font(.system(size: 14))
                        Text(L10n.Update.automaticUpdatesDescription)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            }
            #else
            Divider()
            
            // Update settings section
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.Update.settings)
                    .font(.system(size: 16, weight: .semibold))

                // Current version
                let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
                HStack {
                    Text(L10n.Update.currentVersion(version: currentVersion))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    #if DEBUG
                    Text("(Debug)")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                    #endif
                }
                
                // Latest version info
                if isCheckingForUpdates {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Checking for updates...")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else if let error = updateCheckError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Spacer()
                    }
                } else if let latest = latestVersion {
                    HStack {
                        Text("Latest: \(latest)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                Spacer()
                    .frame(height: 4)
                
                // Update channel selection
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Update.updateChannel)
                        .font(.system(size: 14, weight: .medium))
                    
                    ForEach(UpdateChannel.allCases, id: \.self) { channel in
                        Button(action: {
                            selectUpdateChannel(channel)
                        }) {
                            HStack {
                                Image(systemName: UserDefaults.standard.updateChannel == channel ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(UserDefaults.standard.updateChannel == channel ? .accentColor : .secondary)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(channel.displayName)
                                            .font(.system(size: 14, weight: .medium))
                                        if channel == .stable {
                                            Text(L10n.Update.recommended)
                                                .font(.system(size: 11))
                                                .foregroundColor(.green)
                                        }
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Text(channel.description)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                        
                                        if channel == .stable && latestStableVersion != nil {
                                            Text("•")
                                                .foregroundColor(.secondary.opacity(0.5))
                                            Text(L10n.Update.latestVersion(version: latestStableVersion!))
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        } else if channel == .dev && latestDevVersion != nil {
                                            Text("•")
                                                .foregroundColor(.secondary.opacity(0.5))
                                            Text(L10n.Update.latestVersion(version: latestDevVersion!))
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(UserDefaults.standard.updateChannel == channel ? Color.accentColor.opacity(0.1) : Color.clear)
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.bottom, 8)

                // Check for updates button
                Button(action: {
                    if updater != nil {
                        updater.checkForUpdates()
                    } else {
                        // Fallback: manually check appcast
                        checkLatestVersion()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14))
                        Text(L10n.Update.checkForUpdates)
                            .font(.system(size: 14))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())

                // Automatic updates toggle
                Toggle(isOn: .init(
                    get: { updater.automaticallyChecksForUpdates },
                    set: { updater.automaticallyChecksForUpdates = $0 }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.Update.automaticUpdates)
                            .font(.system(size: 14))
                        Text(L10n.Update.automaticUpdatesDescription)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            }
            #endif

            #if DEBUG
            Divider()

            // Debug section
            VStack(alignment: .leading, spacing: 12) {
                Text("Debug")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.orange)

                Button(action: {
                    // Show EnvironmentSetupView in a new window
                    let window = NSWindow(
                        contentRect: NSRect(x: 0, y: 0, width: 480, height: 400),
                        styleMask: [.titled, .closable, .resizable],
                        backing: .buffered,
                        defer: false
                    )
                    window.title = "Environment Setup (Debug)"
                    window.contentView = NSHostingView(rootView: EnvironmentSetupView())
                    window.center()
                    window.makeKeyAndOrderFront(nil)
                }) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 14))
                        Text("Show Environment Setup View")
                            .font(.system(size: 14))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
            #endif

            Spacer()
        }
        .onAppear {
            fetchLatestVersions()
        }
    }
    
    private func selectUpdateChannel(_ channel: UpdateChannel) {
        UserDefaults.standard.updateChannel = channel
        
        // Notify AppDelegate to update Sparkle configuration
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.updateChannelChanged(to: channel)
        }
        
        // Re-fetch latest versions when channel changes
        fetchLatestVersions()
    }
    
    private func checkLatestVersion() {
        isCheckingForUpdates = true
        updateCheckError = nil
        latestVersion = nil
        
        let channel = UserDefaults.standard.updateChannel
        guard let url = URL(string: channel.appcastURL) else {
            updateCheckError = "Invalid feed URL"
            isCheckingForUpdates = false
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                // Parse XML to find latest version
                let parser = XMLParser(data: data)
                let delegate = AppcastParserDelegate()
                parser.delegate = delegate
                
                if parser.parse(), let version = delegate.latestVersion {
                    await MainActor.run {
                        self.latestVersion = version
                        self.isCheckingForUpdates = false
                    }
                } else {
                    await MainActor.run {
                        self.updateCheckError = "Failed to parse update feed"
                        self.isCheckingForUpdates = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.updateCheckError = "Network error"
                    self.isCheckingForUpdates = false
                }
            }
        }
    }
    
    private func fetchLatestVersions() {
        print("🔄 Starting to fetch latest versions...")
        
        // Fetch stable version
        Task {
            await fetchLatestVersion(for: .stable) { version in
                self.latestStableVersion = version
                print("📦 Stable version set to: \(version ?? "nil")")
            }
        }
        
        // Fetch dev version
        Task {
            await fetchLatestVersion(for: .dev) { version in
                self.latestDevVersion = version
                print("📦 Dev version set to: \(version ?? "nil")")
            }
        }
    }
    
    private func fetchLatestVersion(for channel: UpdateChannel, completion: @escaping (String?) -> Void) async {
        guard let url = URL(string: channel.appcastURL) else {
            print("❌ Invalid URL for channel \(channel): \(channel.appcastURL)")
            completion(nil)
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Fetching \(channel) version from: \(url)")
                print("📡 Response status: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    print("❌ HTTP error: \(httpResponse.statusCode)")
                    await MainActor.run {
                        completion(nil)
                    }
                    return
                }
            }
            
            let parser = XMLParser(data: data)
            let delegate = AppcastParserDelegate()
            parser.delegate = delegate
            
            if parser.parse(), let version = delegate.latestVersion {
                print("✅ Found \(channel) version: \(version)")
                await MainActor.run {
                    completion(version)
                }
            } else {
                print("❌ Failed to parse XML for \(channel)")
                // デバッグ用: XMLの最初の部分を表示
                if let xmlString = String(data: data.prefix(500), encoding: .utf8) {
                    print("XML preview: \(xmlString)")
                }
                await MainActor.run {
                    completion(nil)
                }
            }
        } catch {
            print("❌ Error fetching \(channel) version: \(error)")
            await MainActor.run {
                completion(nil)
            }
        }
    }
}

// Simple XML parser to extract version from appcast
private class AppcastParserDelegate: NSObject, XMLParserDelegate {
    var latestVersion: String?
    private var currentElement = ""
    private var foundItem = false
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "item" {
            foundItem = true
        } else if elementName == "enclosure" && foundItem {
            // Extract version from sparkle:shortVersionString or sparkle:version
            if let version = attributeDict["sparkle:shortVersionString"] ?? attributeDict["sparkle:version"] {
                latestVersion = version
                parser.abortParsing() // Stop after finding first item
            }
        }
    }
}
