import SwiftUI
import Sparkle

struct SettingsTabView: View {
    @EnvironmentObject var monitor: UsageMonitor
    @StateObject private var languageSettings = LanguageSettings.shared
    @StateObject private var currencySettings = CurrencySettings.shared
    // @State private var notificationEnabled = Bundle.main.bundleIdentifier != nil ? NotificationManager.shared.isNotificationEnabled : false
    private let updater = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil).updater

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

            Divider()

            // Update settings section
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.Update.settings)
                    .font(.system(size: 16, weight: .semibold))

                // Current version
                HStack {
                    Text(L10n.Update.currentVersion(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.bottom, 4)

                // Check for updates button
                Button(action: {
                    updater.checkForUpdates()
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
    }
}
