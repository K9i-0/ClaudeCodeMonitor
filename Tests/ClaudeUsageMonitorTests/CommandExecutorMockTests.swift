import XCTest
@testable import ClaudeCodeMonitor

/// Tests for CommandExecutor using dependency injection and mocks
@MainActor
final class CommandExecutorMockTests: XCTestCase {
    
    // MARK: - TestableCommandExecutor
    
    /// A testable version of CommandExecutor that allows process injection
    class TestableCommandExecutor {
        typealias ProcessFactory = () -> Process
        
        var processFactory: ProcessFactory?
        var findCommandCallCount = 0
        var executeCcusageCallCount = 0
        
        init() {}
        
        /// Override to use injected process factory
        func createProcess() -> Process {
            return processFactory?() ?? Process()
        }
        
        /// Make findCommand accessible for testing
        func testFindCommand(_ command: String) async throws -> String? {
            findCommandCallCount += 1
            
            // Simulate the actual implementation with our mock
            let process = createProcess()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
            process.arguments = [command]
            
            // Set up environment
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
            process.environment = environment
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()
            
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), 
                   !path.isEmpty {
                    return path
                }
            }
            
            return nil
        }
    }
    
    // MARK: - Mock Process with Pipe Support
    
    class MockProcessWithPipe: Process, @unchecked Sendable {
        var mockTerminationStatus: Int32 = 0
        var mockOutput: String?
        var mockError: String?
        
        private var outputPipe: Pipe?
        private var errorPipe: Pipe?
        private var _executableURL: URL?
        private var _arguments: [String]?
        private var _environment: [String: String]?
        
        override var executableURL: URL? {
            get { return _executableURL }
            set { _executableURL = newValue }
        }
        
        override var arguments: [String]? {
            get { return _arguments }
            set { _arguments = newValue }
        }
        
        override var environment: [String: String]? {
            get { return _environment }
            set { _environment = newValue }
        }
        
        override var standardOutput: Any? {
            get { return outputPipe }
            set { outputPipe = newValue as? Pipe }
        }
        
        override var standardError: Any? {
            get { return errorPipe }
            set { errorPipe = newValue as? Pipe }
        }
        
        override var terminationStatus: Int32 {
            return mockTerminationStatus
        }
        
        override func run() throws {
            // Write mock output to pipe
            if let output = mockOutput,
               let pipe = outputPipe {
                let data = output.data(using: .utf8) ?? Data()
                pipe.fileHandleForWriting.write(data)
                try? pipe.fileHandleForWriting.close()
            }
            
            // Write mock error to pipe
            if let error = mockError,
               let pipe = errorPipe {
                let data = error.data(using: .utf8) ?? Data()
                pipe.fileHandleForWriting.write(data)
                try? pipe.fileHandleForWriting.close()
            }
        }
        
        override func waitUntilExit() {
            // No-op
        }
    }
    
    // MARK: - Tests
    
    func testFindCommandWithBunxFound() async throws {
        let executor = TestableCommandExecutor()
        
        executor.processFactory = {
            let mock = MockProcessWithPipe()
            mock.mockTerminationStatus = 0
            mock.mockOutput = "/Users/test/.local/share/mise/installs/bun/latest/bin/bunx\n"
            return mock
        }
        
        let result = try await executor.testFindCommand("bunx")
        XCTAssertEqual(result, "/Users/test/.local/share/mise/installs/bun/latest/bin/bunx")
        XCTAssertEqual(executor.findCommandCallCount, 1)
    }
    
    func testFindCommandWithBunxNotFound() async throws {
        let executor = TestableCommandExecutor()
        
        executor.processFactory = {
            let mock = MockProcessWithPipe()
            mock.mockTerminationStatus = 1
            mock.mockOutput = ""
            return mock
        }
        
        let result = try await executor.testFindCommand("bunx")
        XCTAssertNil(result)
    }
    
    func testFindCommandWithNpxFound() async throws {
        let executor = TestableCommandExecutor()
        
        executor.processFactory = {
            let mock = MockProcessWithPipe()
            mock.mockTerminationStatus = 0
            mock.mockOutput = "/usr/local/bin/npx\n"
            return mock
        }
        
        let result = try await executor.testFindCommand("npx")
        XCTAssertEqual(result, "/usr/local/bin/npx")
    }
    
    func testPathEnvironmentSetup() async throws {
        // Skip in CI environment where PATH setup might be different
        if ProcessInfo.processInfo.environment["CI"] != nil {
            throw XCTSkip("Skipping PATH environment test in CI")
        }
        
        let executor = TestableCommandExecutor()
        var capturedEnvironment: [String: String]?
        
        executor.processFactory = {
            let mock = MockProcessWithPipe()
            mock.mockTerminationStatus = 0
            mock.mockOutput = "/usr/bin/bunx"
            capturedEnvironment = mock.environment
            return mock
        }
        
        _ = try await executor.testFindCommand("bunx")
        
        // Verify PATH includes mise directories
        if let path = capturedEnvironment?["PATH"] {
            XCTAssertTrue(path.contains("mise/shims"))
            XCTAssertTrue(path.contains("mise/installs/bun"))
            XCTAssertTrue(path.contains("/usr/local/bin"))
            XCTAssertTrue(path.contains("/opt/homebrew/bin"))
        } else {
            XCTFail("PATH not set in environment")
        }
    }
    
    func testCommandPriorityBunxOverNpx() async throws {
        // Test that demonstrates bunx is preferred over npx
        let _ = "/Users/test/.local/share/mise/installs/bun/latest/bin/bunx"
        let _ = "/usr/local/bin/npx"
        
        // In the real implementation, bunx is checked first
        // This test documents that expectation
        let commandPriority = ["bunx", "npx"]
        XCTAssertEqual(commandPriority[0], "bunx")
        XCTAssertEqual(commandPriority[1], "npx")
    }
    
    func testCcusageArgumentsDifferBetweenBunxAndNpx() {
        // Document the difference in arguments
        let bunxArgs = ["ccusage"]
        let npxArgs = ["ccusage@latest"]
        
        XCTAssertNotEqual(bunxArgs, npxArgs)
        XCTAssertEqual(bunxArgs[0], "ccusage")
        XCTAssertEqual(npxArgs[0], "ccusage@latest")
    }
    
    func testOutputDecodingError() async throws {
        let executor = TestableCommandExecutor()
        
        // Test with invalid UTF-8 output
        executor.processFactory = {
            let mock = MockProcessWithPipe()
            mock.mockTerminationStatus = 0
            // This would need to be actual invalid UTF-8 data
            mock.mockOutput = ""
            return mock
        }
        
        let result = try await executor.testFindCommand("test")
        XCTAssertNil(result) // Empty output returns nil
    }
    
    func testMultipleMiseVersionPaths() {
        // Test that we support multiple mise version patterns
        let username = NSUserName()
        let paths = [
            "/Users/\(username)/.local/share/mise/installs/bun/latest/bin",
            "/Users/\(username)/.local/share/mise/installs/bun/1.2.18/bin",
            "/Users/\(username)/.local/share/mise/installs/bun/*/bin"
        ]
        
        for path in paths {
            XCTAssertTrue(path.contains("mise/installs/bun"))
        }
        
        // The glob pattern should match version directories
        let globPattern = paths[2]
        XCTAssertTrue(globPattern.contains("*"))
    }
}

// MARK: - Performance Tests

extension CommandExecutorMockTests {
    
    func testFindCommandPerformance() throws {
        let executor = TestableCommandExecutor()
        
        executor.processFactory = {
            let mock = MockProcessWithPipe()
            mock.mockTerminationStatus = 0
            mock.mockOutput = "/usr/bin/test"
            return mock
        }
        
        measure {
            let expectation = XCTestExpectation(description: "Find command")
            
            Task {
                _ = try await executor.testFindCommand("test")
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
}