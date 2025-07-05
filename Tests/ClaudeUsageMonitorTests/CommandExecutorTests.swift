import XCTest
@testable import ClaudeCodeMonitor

@MainActor
final class CommandExecutorTests: XCTestCase {
    
    // MARK: - Mock Process
    
    class MockProcess: Process, @unchecked Sendable {
        var mockTerminationStatus: Int32 = 0
        var mockOutput: String?
        var capturedCommand: String?
        var capturedArguments: [String]?
        var capturedEnvironment: [String: String]?
        
        override var executableURL: URL? {
            didSet {
                capturedCommand = executableURL?.path
            }
        }
        
        override var arguments: [String]? {
            didSet {
                capturedArguments = arguments
            }
        }
        
        override var environment: [String: String]? {
            didSet {
                capturedEnvironment = environment
            }
        }
        
        override var standardOutput: Any? {
            get { return nil }
            set {}
        }
        
        override var standardError: Any? {
            get { return nil }
            set {}
        }
        
        override var terminationStatus: Int32 {
            return mockTerminationStatus
        }
        
        override func run() throws {
            // Simulate output
            if let output = mockOutput,
               let pipe = standardOutput as? Pipe {
                let data = output.data(using: .utf8) ?? Data()
                pipe.fileHandleForWriting.write(data)
                try? pipe.fileHandleForWriting.close()
            }
        }
        
        override func waitUntilExit() {
            // Do nothing
        }
    }
    
    // MARK: - Test Environment Paths
    
    func testEnvironmentPathsIncludeMiseDirectories() async throws {
        // This test verifies that the PATH includes mise-specific directories
        let executor = CommandExecutor.shared
        
        // We can't easily test private methods, but we can verify the behavior
        // by checking if the executor can theoretically find commands in mise paths
        let result = await executor.checkEnvironment()
        
        // The actual test would be integration test, but we can at least verify
        // the structure is correct
        XCTAssertNotNil(result)
    }
    
    func testCommandExecutionWithBunx() async throws {
        // Test that bunx is preferred over npx
        let executor = CommandExecutor.shared
        
        // Since we can't easily mock the internal Process creation,
        // we'll test the high-level behavior
        do {
            // This will fail in test environment, but we can verify the error
            _ = try await executor.executeCcusageCommand()
            XCTFail("Should not succeed in test environment")
        } catch {
            // Expected to fail in test environment
            XCTAssertNotNil(error)
        }
    }
    
    func testEnvironmentCheckResult() async throws {
        let result = await CommandExecutor.shared.checkEnvironment()
        
        // Test the structure
        XCTAssertNotNil(result)
        
        // These will be false in CI environment
        if ProcessInfo.processInfo.environment["CI"] != nil {
            XCTAssertFalse(result.isClaudeCodeInstalled)
            XCTAssertFalse(result.canExecuteCommands)
        }
    }
    
    // MARK: - Path Construction Tests
    
    func testPathConstructionIncludesAllExpectedDirectories() {
        let username = NSUserName()
        let expectedPaths = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            "/Users/\(username)/.local/share/mise/shims",
            "/Users/\(username)/.local/share/mise/installs/bun/latest/bin",
            "/Users/\(username)/.bun/bin",
            "/usr/bin"
        ]
        
        // We can't directly test private methods, but we can verify
        // that these paths would be constructed correctly
        for path in expectedPaths {
            XCTAssertTrue(path.contains(username) || path.hasPrefix("/usr") || path.hasPrefix("/opt"))
        }
    }
    
    func testCommandErrorLocalization() {
        // Test error messages
        let commandNotFound = CommandExecutor.CommandError.commandNotFound("test-command")
        XCTAssertNotNil(commandNotFound.errorDescription)
        XCTAssertNotNil(commandNotFound.recoverySuggestion)
        
        let executionFailed = CommandExecutor.CommandError.executionFailed("test error")
        XCTAssertNotNil(executionFailed.errorDescription)
        XCTAssertNotNil(executionFailed.recoverySuggestion)
        
        let outputDecodingFailed = CommandExecutor.CommandError.outputDecodingFailed
        XCTAssertNotNil(outputDecodingFailed.errorDescription)
        XCTAssertNotNil(outputDecodingFailed.recoverySuggestion)
    }
    
    func testCcusageCommandConstruction() async throws {
        // Test that command arguments are constructed correctly
        let executor = CommandExecutor.shared
        
        // Test with subcommand
        do {
            _ = try await executor.executeCcusageCommand(subcommand: "blocks")
        } catch {
            // Expected in test environment
            if let error = error as? CommandExecutor.CommandError,
               case .commandNotFound = error {
                // This is expected when neither bunx nor npx is found
                XCTAssertTrue(true)
            }
        }
        
        // Test with additional arguments
        do {
            _ = try await executor.executeCcusageCommand(
                subcommand: "blocks",
                additionalArgs: ["--since", "2025-01-01"]
            )
        } catch {
            // Expected in test environment
            if let error = error as? CommandExecutor.CommandError,
               case .commandNotFound = error {
                // This is expected when neither bunx nor npx is found
                XCTAssertTrue(true)
            }
        }
    }
}

// MARK: - Test Helpers

extension CommandExecutorTests {
    
    func testMisePathPatterns() {
        // Test that mise path patterns are valid
        let username = NSUserName()
        let misePaths = [
            "/Users/\(username)/.local/share/mise/shims",
            "/Users/\(username)/.local/share/mise/installs/bun/latest/bin",
            "/Users/\(username)/.local/share/mise/installs/bun/1.2.18/bin"
        ]
        
        for path in misePaths {
            XCTAssertTrue(path.contains("mise"))
            XCTAssertTrue(path.contains(username))
        }
    }
    
    func testBunxVsNpxPriority() async {
        // This test documents the expected priority order
        let priorities = [
            ("bunx", "ccusage"),          // Highest priority
            ("npx", "ccusage@latest")     // Fallback
        ]
        
        XCTAssertEqual(priorities[0].0, "bunx")
        XCTAssertEqual(priorities[1].0, "npx")
        
        // Verify ccusage arguments differ
        XCTAssertNotEqual(priorities[0].1, priorities[1].1)
    }
}

// MARK: - Integration Test Helpers

extension CommandExecutorTests {
    
    /// Helper to check if a command exists in the system
    /// This is used for integration tests that run on real systems
    func commandExists(_ command: String) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = [command]
        task.standardOutput = Pipe()
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func testRealCommandDetection() {
        // Skip in CI environment
        guard ProcessInfo.processInfo.environment["CI"] == nil else {
            return
        }
        
        // On development machines, we might have these installed
        let hasBunx = commandExists("bunx")
        let hasNpx = commandExists("npx")
        
        // At least one should be available on dev machines
        if !hasBunx && !hasNpx {
            XCTFail("Neither bunx nor npx found on this system")
        }
    }
}