import Foundation

// チャートデータ構造
struct ChartData: Identifiable {
    let id = UUID()
    let time: Date
    let value: Double
}