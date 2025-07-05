import Foundation
import SwiftUI

// MARK: - Date Extensions
extension Date {
    /// ISO8601フォーマットの時刻を表示用の時刻文字列に変換
    static func formatTime(from isoString: String, format: String = "HH:mm") -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else {
            return isoString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = format
        displayFormatter.timeZone = TimeZone.current
        return displayFormatter.string(from: date)
    }

    /// 経過時間を取得
    static func getElapsedTime(from startTimeString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let startDate = formatter.date(from: startTimeString) else {
            return "N/A"
        }

        let elapsed = Date().timeIntervalSince(startDate)
        let hours = Int(elapsed) / 3_600
        let minutes = (Int(elapsed) % 3_600) / 60

        if hours > 0 {
            return L10n.Time.hoursMinutes(hours: hours, minutes: minutes)
        } else {
            return L10n.Time.minutes(minutes: minutes)
        }
    }

    /// フォーマット済み時刻文字列を返す
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }
    
    /// ユーザーフレンドリーな日時表示（今日、明日、曜日など）
    static func formatUserFriendlyDateTime(from isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Try multiple formats
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: isoString)
        
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: isoString)
        }
        
        if date == nil {
            // Try with basic format
            formatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone, .withColonSeparatorInTimeZone]
            date = formatter.date(from: isoString)
        }
        
        guard let date = date else {
            print("Failed to parse date: \(isoString)")
            return formatTime(from: isoString, format: "MM/dd HH:mm")
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.timeZone = TimeZone.current
        displayFormatter.locale = Locale.current
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            // Use localized "Today"
            displayFormatter.doesRelativeDateFormatting = true
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            let result = displayFormatter.string(from: date)
            // Extract time part and prepend "Today"
            if let timeRange = result.range(of: " ") {
                let timePart = String(result[timeRange.upperBound...])
                return "\(L10n.Time.today) \(timePart)"
            }
            return result
        } else if calendar.isDateInTomorrow(date) {
            // Use localized "Tomorrow"
            displayFormatter.dateFormat = "HH:mm"
            let time = displayFormatter.string(from: date)
            return "\(L10n.Time.tomorrow) \(time)"
        } else {
            // Check if within next 7 days
            let daysDiff = calendar.dateComponents([.day], from: now, to: date).day ?? 0
            
            if daysDiff > 0 && daysDiff <= 7 {
                // Show weekday name
                displayFormatter.dateFormat = "E HH:mm"
            } else {
                // Show date
                displayFormatter.dateFormat = "MM/dd HH:mm"
            }
            
            return displayFormatter.string(from: date)
        }
    }
}

// MARK: - Color Extensions
extension Color {
    /// 使用率に基づいた色を返す
    static func usageColor(for percentage: Double) -> Color {
        switch percentage {
        case 90...:
            return .red
        case 75..<90:
            return .orange
        case 50..<75:
            return .blue
        default:
            return .blue
        }
    }

    /// 使用率に基づいたグラデーションを返す
    static func usageGradient(for percentage: Double) -> LinearGradient {
        if percentage > 90 {
            return LinearGradient(colors: [.red, .pink], startPoint: .leading, endPoint: .trailing)
        } else if percentage > 70 {
            return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        } else if percentage > 50 {
            return LinearGradient(colors: [.yellow, .green], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
        }
    }

    /// プログレスバー用のグラデーション
    static func progressGradient(for percentage: Double) -> LinearGradient {
        return usageGradient(for: percentage)
    }
}

// MARK: - SF Symbols
struct SFSymbols {
    static func getSFSymbol(for percentage: Double) -> String {
        switch percentage {
        case 90...:
            return "exclamationmark.triangle.fill"
        case 75..<90:
            return "bolt.fill"
        case 50..<75:
            return "flame.fill"
        default:
            return "circle.fill"
        }
    }
}

// MARK: - Number Formatting
struct NumberFormatters {
    /// 標準的なトークンフォーマッター
    static let tokenFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        return formatter
    }()

    /// 通貨フォーマッター
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    /// パーセントフォーマッター
    static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    /// コンパクト数値フォーマッター
    static let compactNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        // Manual K/M formatting since compactDecimal is not available in all locales
        return formatter
    }()

    /// トークン数をフォーマット（K/M表記）
    static func formatTokens(_ tokens: Int) -> String {
        if tokens >= 1_000_000 {
            return String(format: "%.1fM", Double(tokens) / 1_000_000)
        } else if tokens >= 1_000 {
            return String(format: "%.1fK", Double(tokens) / 1_000)
        } else {
            return "\(tokens)"
        }
    }

    /// コストをフォーマット（ドル記号付き）
    static func formatCost(_ cost: Double) -> String {
        return String(format: "$%.2f", cost)
    }

    /// 軸ラベル用の値フォーマット
    static func formatAxisValue(_ value: Double) -> String {
        if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        }
        return String(format: "%.0f", value)
    }
}

// MARK: - Error Types
enum ClaudeMonitorError: LocalizedError {
    case networkError(String)
    case parsingError(String)
    case commandExecutionError(String)
    case fileNotFound(String)
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "ネットワークエラー: \(message)"
        case .parsingError(let message):
            return "データ解析エラー: \(message)"
        case .commandExecutionError(let message):
            return "コマンド実行エラー: \(message)"
        case .fileNotFound(let path):
            return "ファイルが見つかりません: \(path)"
        case .unknownError(let message):
            return "不明なエラー: \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "インターネット接続を確認してください"
        case .parsingError:
            return "ccusageが最新バージョンであることを確認してください"
        case .commandExecutionError:
            return "Node.jsまたはBunが正しくインストールされているか確認してください"
        case .fileNotFound:
            return "必要なファイルが存在することを確認してください"
        case .unknownError:
            return "アプリを再起動してもう一度お試しください"
        }
    }
}

// MARK: - Constants
struct Constants {
    struct Timing {
        static let refreshInterval: TimeInterval = 300 // 5分
        static let animationDuration: Double = 0.3
        static let longAnimationDuration: Double = 0.5
        static let serverRestartDelay: TimeInterval = 2.0
        static let serverHealthCheckInterval: TimeInterval = 30.0
        static let serverStartupRetryDelay: TimeInterval = 2.0
        static let dataAccessWaitTime: TimeInterval = 2.0
    }

    struct Server {
        static let serverStartupRetryCount = 5
        static let nodeMemoryLimit = 128 // MB
    }

    struct UI {
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 10
        static let padding: CGFloat = 16
        static let smallPadding: CGFloat = 12
        static let shadowRadius: CGFloat = 3
        static let shadowOpacity: Double = 0.1
    }

    struct TokenLimits {
        static let pro = 7_000
        static let max5 = 35_000
        static let max20 = 140_000
    }
}

// MARK: - ViewModifiers
struct CardStyle: ViewModifier {
    let cornerRadius: CGFloat
    let padding: CGFloat
    @Environment(\.colorScheme)
    var colorScheme

    init(cornerRadius: CGFloat = Constants.UI.cornerRadius, padding: CGFloat = Constants.UI.padding) {
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                        radius: Constants.UI.shadowRadius,
                        x: 0,
                        y: 2
                    )
            )
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = Constants.UI.cornerRadius, padding: CGFloat = Constants.UI.padding) -> some View {
        self.modifier(CardStyle(cornerRadius: cornerRadius, padding: padding))
    }
}
