import SwiftUI

struct SettingsTabView: View {
    @EnvironmentObject var monitor: UsageMonitor
    @StateObject private var languageSettings = LanguageSettings.shared
    // @State private var notificationEnabled = Bundle.main.bundleIdentifier != nil ? NotificationManager.shared.isNotificationEnabled : false

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

            Spacer()
        }
    }
}
