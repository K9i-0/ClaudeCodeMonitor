import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var monitor: UsageMonitor
    @Environment(\.presentationMode) var presentationMode
    @State private var notificationEnabled = NotificationManager.shared.isNotificationEnabled
    
    let plans = [
        ("Pro", "7,000 tokens/session"),
        ("Max5", "35,000 tokens/session"),
        ("Max20", "140,000 tokens/session")
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("プラン選択")
                .font(.headline)
                .padding(.top)
            
            VStack(spacing: 8) {
                ForEach(plans, id: \.0) { plan in
                    Button(action: {
                        monitor.setUserPlan(plan.0)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: monitor.getUserPlan() == plan.0 ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(monitor.getUserPlan() == plan.0 ? .accentColor : .secondary)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(plan.0)
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
            .padding(.horizontal)
            
            Divider()
            
            // 通知設定
            VStack(alignment: .leading, spacing: 8) {
                Text("通知設定")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                Toggle(isOn: $notificationEnabled) {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(notificationEnabled ? .blue : .secondary)
                        Text("使用率通知を有効にする")
                            .font(.system(size: 13))
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .onChange(of: notificationEnabled) { newValue in
                    NotificationManager.shared.isNotificationEnabled = newValue
                    if newValue {
                        NotificationManager.shared.requestNotificationPermission()
                    }
                }
                
                if notificationEnabled {
                    Text("70%, 80%, 90%, 95%で通知します")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 26)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button("閉じる") {
                presentationMode.wrappedValue.dismiss()
            }
            .keyboardShortcut(.escape)
            .padding(.bottom)
        }
        .frame(width: 300, height: 340)
    }
}