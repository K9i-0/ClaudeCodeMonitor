import Foundation
import Combine

// MARK: - Usage Monitoring Protocol
@MainActor
protocol UsageMonitoring: AnyObject {
    var usageData: UsageData { get }
    var isLoading: Bool { get }
    var error: ClaudeMonitorError? { get }

    func startMonitoring()
    func stopMonitoring()
    func fetchUsageData()
    func formatTokens(_ tokens: Int) -> String
    func formatCost(_ cost: Double) -> String
    func setUserPlan(_ plan: String)
    func getUserPlan() -> String
}

// MARK: - Command Execution Protocol
protocol CommandExecuting {
    func executeCommand(_ command: String, arguments: [String]) async throws -> Data
}

// MARK: - Network Service Protocol
protocol NetworkService {
    func fetchUsageData(from url: URL) async throws -> CcusageResponse
    func fetchSessionData(from url: URL) async throws -> BlocksResponse
}

// MARK: - Storage Protocol
protocol UserPreferences {
    func save(_ value: String, forKey key: String)
    func load(forKey key: String) -> String?
    func remove(forKey key: String)
}

// MARK: - Default Implementations
extension UserDefaults: UserPreferences {
    func save(_ value: String, forKey key: String) {
        set(value, forKey: key)
    }

    func load(forKey key: String) -> String? {
        string(forKey: key)
    }

    func remove(forKey key: String) {
        removeObject(forKey: key)
    }
}

// MARK: - Network Service Implementation
class DefaultNetworkService: NetworkService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchUsageData(from url: URL) async throws -> CcusageResponse {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeMonitorError.networkError("無効なレスポンス")
        }

        guard httpResponse.statusCode == 200 else {
            throw ClaudeMonitorError.networkError("ステータスコード: \(httpResponse.statusCode)")
        }

        do {
            return try JSONDecoder().decode(CcusageResponse.self, from: data)
        } catch {
            throw ClaudeMonitorError.parsingError("CcusageResponseのデコードに失敗: \(error.localizedDescription)")
        }
    }

    func fetchSessionData(from url: URL) async throws -> BlocksResponse {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeMonitorError.networkError("無効なレスポンス")
        }

        guard httpResponse.statusCode == 200 else {
            throw ClaudeMonitorError.networkError("ステータスコード: \(httpResponse.statusCode)")
        }

        do {
            return try JSONDecoder().decode(BlocksResponse.self, from: data)
        } catch {
            throw ClaudeMonitorError.parsingError("BlocksResponseのデコードに失敗: \(error.localizedDescription)")
        }
    }
}

// MARK: - Command Executor Implementation
class ProcessCommandExecutor: CommandExecuting {
    func executeCommand(_ command: String, arguments: [String]) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let pipe = Pipe()

            process.executableURL = URL(fileURLWithPath: command)
            process.arguments = arguments
            process.standardOutput = pipe
            process.standardError = pipe

            process.terminationHandler = { process in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()

                if process.terminationStatus == 0 {
                    continuation.resume(returning: data)
                } else {
                    let errorOutput = String(data: data, encoding: .utf8) ?? "Unknown error"
                    let message = "Exit code: \(process.terminationStatus), Output: \(errorOutput)"
                    continuation.resume(
                        throwing: ClaudeMonitorError.commandExecutionError(message)
                    )
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing:
                    ClaudeMonitorError.commandExecutionError("プロセスの起動に失敗: \(error.localizedDescription)")
                )
            }
        }
    }
}
