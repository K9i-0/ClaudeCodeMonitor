import SwiftUI

struct CurrentSessionView: View {
    let session: SessionBlock
    let monitor: UsageMonitor
    @Environment(\.colorScheme)
    var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            // 残りトークン数を大きく表示（カード風デザイン）
            VStack(spacing: 8) {
                Text(L10n.Session.remainingTokens)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(monitor.formatTokens(monitor.usageData.sessionTokenLimit - session.totalTokens))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(progressGradient)
                        .accessibilityLabel(
                            "\(L10n.Session.remaining) " +
                            "\(monitor.formatTokens(monitor.usageData.sessionTokenLimit - session.totalTokens)) " +
                            "\(L10n.Session.tokens)"
                        )
                    Text(L10n.Session.tokens)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }

                // プログレスバー（改善版）
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Capsule()
                            .fill(Color(NSColor.separatorColor).opacity(0.3))
                            .frame(height: 10)

                        // Progress
                        Capsule()
                            .fill(progressGradient)
                            .frame(
                                width: min(
                                    geometry.size.width,
                                    geometry.size.width * (monitor.usageData.sessionUsagePercentage / 100)
                                ),
                                height: 10
                            )
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8),
                                value: monitor.usageData.sessionUsagePercentage
                            )

                        // Glow effect for high usage
                        if monitor.usageData.sessionUsagePercentage > 80 {
                            Capsule()
                                .fill(Color.red.opacity(0.3))
                                .frame(
                                    width: min(
                                        geometry.size.width,
                                        geometry.size.width * (monitor.usageData.sessionUsagePercentage / 100)
                                    ),
                                    height: 10
                                )
                                .blur(radius: 8)
                        }
                    }
                }
                .frame(height: 10)
                .accessibilityElement()
                .accessibilityLabel(L10n.Usage.usage)
                .accessibilityValue(L10n.Usage.percentage(percent: Int(monitor.usageData.sessionUsagePercentage)))
                .accessibilityAddTraits(.updatesFrequently)

                HStack {
                    HStack(spacing: 4) {
                        Text(L10n.Session.used(percentage: monitor.usageData.formattedSessionPercentage))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(L10n.Session.tokensConsumed(tokens: monitor.formatTokens(session.totalTokens)))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if monitor.usageData.sessionUsagePercentage > 90 {
                        Label(L10n.Session.highUsageWarning, systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            )

            // メトリクスカード
            HStack(spacing: 12) {
                // リセットまでの時間
                VStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.blue)
                    Text(L10n.Session.timeUntilReset)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(monitor.usageData.sessionRemainingTime)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.1))
                )

                // 消費速度
                VStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.orange)
                    Text(L10n.Session.burnRate)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("\(monitor.usageData.sessionBurnRate) \(L10n.Session.tokensPerMin)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.orange)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.1))
                )
            }

            // セッションコスト（改善版）
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Session.cost)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("$")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.green)
                        Text(String(format: "%.2f", session.costUSD))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                }

                Spacer()

                // プラン情報
                VStack(alignment: .trailing, spacing: 4) {
                    Text(monitor.usageData.planDescription)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.15))
                        )
                    Text(L10n.Session.resetTime(time: formatSessionEndTime(session.endTime)))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
    }

    @MainActor
    private var progressGradient: LinearGradient {
        return Color.usageGradient(for: monitor.usageData.sessionUsagePercentage)
    }

    private func formatTime(_ timeString: String) -> String {
        return Date.formatTime(from: timeString)
    }
    
    private func formatSessionEndTime(_ timeString: String) -> String {
        return Date.formatUserFriendlyDateTime(from: timeString)
    }

    private func getElapsedTime(from startTimeString: String) -> String {
        return Date.getElapsedTime(from: startTimeString)
    }
}