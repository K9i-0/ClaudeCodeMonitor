import Foundation

@MainActor
class CommandExecutor {
    static let shared = CommandExecutor()

    private init() {}

    enum CommandError: LocalizedError {
        case commandNotFound(String)
        case executionFailed(String)
        case outputDecodingFailed

        var errorDescription: String? {
            switch self {
            case .commandNotFound(let command):
                return L10n.Error.commandNotFound(command: command)
            case .executionFailed(let message):
                return L10n.Error.commandExecutionFailed(message: message)
            case .outputDecodingFailed:
                return L10n.Error.outputDecodingFailed
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .commandNotFound:
                return L10n.Error.Recovery.installNodeOrBun
            case .executionFailed:
                return L10n.Error.Recovery.checkCommandInstallation
            case .outputDecodingFailed:
                return L10n.Error.Recovery.updateCcusage
            }
        }
    }

    private func findCommand(_ command: String) async throws -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = [command]

        // Set up environment with additional paths
        var environment = ProcessInfo.processInfo.environment
        let existingPath = environment["PATH"] ?? ""
        let additionalPaths = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            "/Users/\(NSUserName())/.local/share/mise/shims",
            "/Users/\(NSUserName())/.local/share/mise/installs/bun/latest/bin",
            "/Users/\(NSUserName())/.local/share/mise/installs/bun/*/bin",
            "/Users/\(NSUserName())/.bun/bin",
            "/usr/bin"
        ].joined(separator: ":")
        environment["PATH"] = "\(additionalPaths):\(existingPath)"
        task.environment = environment

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
                return path
            }
        }

        return nil
    }

    func executeCcusageCommand(subcommand: String? = nil, additionalArgs: [String] = []) async throws -> String {
        var command: String
        var ccusageArgs: [String] = []

        // Try bunx first
        if let bunxPath = try await findCommand("bunx") {
            print("[CommandExecutor] Found bunx at: \(bunxPath)")
            command = bunxPath
            ccusageArgs.append("ccusage@\(BundleConfiguration.ccusageVersion)")
        }
        // Fall back to npx
        else if let npxPath = try await findCommand("npx") {
            print("[CommandExecutor] Found npx at: \(npxPath)")
            command = npxPath
            ccusageArgs.append("ccusage@\(BundleConfiguration.ccusageVersion)")
        }
        // Neither found
        else {
            print("[CommandExecutor] Neither bunx nor npx found in PATH")
            throw CommandError.commandNotFound("bunx/npx")
        }

        // Add subcommand if provided
        if let subcommand = subcommand {
            ccusageArgs.append(subcommand)
        }

        // Add JSON flag and any additional arguments
        ccusageArgs.append("--json")
        ccusageArgs.append(contentsOf: additionalArgs)

        print("[CommandExecutor] Executing: \(command) \(ccusageArgs.joined(separator: " "))")

        // Execute the command
        let task = Process()
        task.executableURL = URL(fileURLWithPath: command)
        task.arguments = ccusageArgs

        // Set up environment
        var environment = ProcessInfo.processInfo.environment
        let existingPath = environment["PATH"] ?? ""
        // Add common Node.js/Bun installation paths
        let additionalPaths = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            "/Users/\(NSUserName())/.local/share/mise/shims",
            "/Users/\(NSUserName())/.bun/bin",
            "/usr/bin"
        ].joined(separator: ":")
        environment["PATH"] = "\(additionalPaths):\(existingPath)"
        task.environment = environment

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        try task.run()
        task.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        if task.terminationStatus != 0 {
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            print("[CommandExecutor] Command failed with status \(task.terminationStatus): \(errorMessage)")
            throw CommandError.executionFailed(errorMessage)
        }

        guard let output = String(data: outputData, encoding: .utf8) else {
            print("[CommandExecutor] Failed to decode command output")
            throw CommandError.outputDecodingFailed
        }

        return output
    }

    func checkEnvironment() async -> EnvironmentCheckResult {
        var result = EnvironmentCheckResult()

        // Check Claude Code
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let claudePath = homeDirectory.appendingPathComponent(".claude")
        let projectsPath = claudePath.appendingPathComponent("projects")
        result.isClaudeCodeInstalled = FileManager.default.fileExists(atPath: projectsPath.path)

        // Check bunx
        result.isBunInstalled = (try? await findCommand("bunx")) != nil

        // Check npx
        result.isNpxInstalled = (try? await findCommand("npx")) != nil

        result.canExecuteCommands = result.isBunInstalled || result.isNpxInstalled

        return result
    }

    // Synchronous environment check for startup
    nonisolated func checkEnvironmentSync() -> EnvironmentCheckResult {
        var result = EnvironmentCheckResult()

        // Check Claude Code
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let claudePath = homeDirectory.appendingPathComponent(".claude")
        let projectsPath = claudePath.appendingPathComponent("projects")
        result.isClaudeCodeInstalled = FileManager.default.fileExists(atPath: projectsPath.path)

        // Check bunx - synchronous check using which command
        result.isBunInstalled = findCommandSync("bunx") != nil

        // Check npx - synchronous check using which command
        result.isNpxInstalled = findCommandSync("npx") != nil

        result.canExecuteCommands = result.isBunInstalled || result.isNpxInstalled

        return result
    }

    private nonisolated func findCommandSync(_ command: String) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = [command]

        // Set up environment with additional paths
        var environment = ProcessInfo.processInfo.environment
        let existingPath = environment["PATH"] ?? ""
        let additionalPaths = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            "/Users/\(NSUserName())/.local/share/mise/shims",
            "/Users/\(NSUserName())/.local/share/mise/installs/bun/latest/bin",
            "/Users/\(NSUserName())/.local/share/mise/installs/bun/*/bin",
            "/Users/\(NSUserName())/.bun/bin",
            "/usr/bin"
        ].joined(separator: ":")
        environment["PATH"] = "\(additionalPaths):\(existingPath)"
        task.environment = environment

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
                    return path
                }
            }
        } catch {
            // Command failed
        }

        return nil
    }
}

struct EnvironmentCheckResult {
    var isClaudeCodeInstalled = false
    var isBunInstalled = false
    var isNpxInstalled = false
    var canExecuteCommands = false
}
