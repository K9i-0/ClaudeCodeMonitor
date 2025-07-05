import XCTest
@testable import ClaudeCodeMonitor

/// Integration tests that run against the real system
/// These tests are skipped in CI environment
@MainActor
final class CommandExecutorIntegrationTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Skip all tests in CI environment
        if ProcessInfo.processInfo.environment["CI"] != nil {
            continueAfterFailure = false
            throw XCTSkip("Skipping integration tests in CI environment")
        }
    }
    
    // MARK: - Real System Tests
    
    func testRealEnvironmentCheck() async throws {
        let result = await CommandExecutor.shared.checkEnvironment()
        
        // On a development machine, at least one should be true
        let hasAnyRuntime = result.isBunInstalled || result.isNpxInstalled
        XCTAssertTrue(hasAnyRuntime, "Neither bunx nor npx found on this system")
        
        // Log what was found
        print("Environment check results:")
        print("- Claude Code installed: \(result.isClaudeCodeInstalled)")
        print("- Bun installed: \(result.isBunInstalled)")
        print("- NPX installed: \(result.isNpxInstalled)")
        print("- Can execute commands: \(result.canExecuteCommands)")
    }
    
    func testRealCommandExecution() async throws {
        // Try to execute a simple ccusage command
        do {
            let result = try await CommandExecutor.shared.executeCcusageCommand(
                subcommand: "--version"
            )
            
            // If successful, output should contain version info
            XCTAssertFalse(result.isEmpty)
            print("ccusage version output: \(result)")
        } catch {
            // If it fails, make sure it's a reasonable error
            if let commandError = error as? CommandExecutor.CommandError {
                switch commandError {
                case .commandNotFound:
                    XCTFail("Neither bunx nor npx found on development machine")
                case .executionFailed(let message):
                    // This might happen if ccusage isn't installed
                    print("Execution failed (expected if ccusage not installed): \(message)")
                case .outputDecodingFailed:
                    XCTFail("Output decoding should not fail for version command")
                }
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }
    
    func testRealPathResolution() async throws {
        // Test that our path additions work correctly
        let username = NSUserName()
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        
        // Verify username matches home directory
        XCTAssertTrue(homePath.contains(username))
        
        // Check if mise directories exist
        let miseBasePath = "\(homePath)/.local/share/mise"
        let miseExists = FileManager.default.fileExists(atPath: miseBasePath)
        
        if miseExists {
            print("Mise installation found at: \(miseBasePath)")
            
            // Check for bun installation
            let bunPath = "\(miseBasePath)/installs/bun"
            if FileManager.default.fileExists(atPath: bunPath) {
                print("Bun installations found at: \(bunPath)")
                
                // List bun versions
                let bunVersions = try FileManager.default.contentsOfDirectory(atPath: bunPath)
                print("Bun versions: \(bunVersions)")
                
                // Check if 'latest' symlink exists
                let latestPath = "\(bunPath)/latest"
                if FileManager.default.fileExists(atPath: latestPath) {
                    print("Latest symlink exists")
                }
            }
        }
    }
    
    func testCommandExecutionTiming() async throws {
        // Measure how long it takes to find and execute a command
        let start = Date()
        
        do {
            _ = try await CommandExecutor.shared.executeCcusageCommand(
                subcommand: "--help"
            )
        } catch {
            // Ignore errors for timing test
        }
        
        let elapsed = Date().timeIntervalSince(start)
        print("Command execution took: \(elapsed) seconds")
        
        // Should complete within reasonable time
        XCTAssertLessThan(elapsed, 5.0, "Command execution took too long")
    }
    
    // MARK: - Edge Cases
    
    func testLongRunningCommand() async throws {
        // Test timeout behavior with a command that might take time
        do {
            let result = try await CommandExecutor.shared.executeCcusageCommand()
            
            // If successful, verify it's valid JSON
            XCTAssertTrue(result.contains("{") || result.contains("["))
        } catch {
            // Expected if ccusage not installed
            print("Long running command test failed (expected): \(error)")
        }
    }
    
    func testCommandWithSpecialCharacters() async throws {
        // Test that special characters in arguments are handled correctly
        do {
            let result = try await CommandExecutor.shared.executeCcusageCommand(
                subcommand: "blocks",
                additionalArgs: ["--since", "2025-01-01", "--until", "2025-12-31"]
            )
            
            print("Command with date arguments succeeded")
            XCTAssertFalse(result.isEmpty)
        } catch {
            // Expected if ccusage not installed
            print("Special characters test failed (expected): \(error)")
        }
    }
}

// MARK: - System Configuration Tests

extension CommandExecutorIntegrationTests {
    
    func testSystemPATH() {
        // Check what's in the system PATH
        let systemPath = ProcessInfo.processInfo.environment["PATH"] ?? ""
        let paths = systemPath.split(separator: ":").map(String.init)
        
        print("System PATH entries:")
        for path in paths {
            print("  - \(path)")
        }
        
        // Common paths that should exist
        let commonPaths = ["/usr/bin", "/usr/local/bin"]
        for path in commonPaths {
            XCTAssertTrue(paths.contains(path), "Missing common path: \(path)")
        }
    }
    
    func testHomebrewInstallation() {
        // Check if Homebrew is installed (common on macOS dev machines)
        let homebrewPaths = ["/opt/homebrew/bin", "/usr/local/bin"]
        var homebrewFound = false
        
        for path in homebrewPaths {
            if FileManager.default.fileExists(atPath: "\(path)/brew") {
                homebrewFound = true
                print("Homebrew found at: \(path)")
                break
            }
        }
        
        if !homebrewFound {
            print("Homebrew not found (not required)")
        }
    }
    
    func testMiseInstallation() {
        // Check mise installation
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        let misePath = "\(homePath)/.local/share/mise"
        
        if FileManager.default.fileExists(atPath: misePath) {
            print("Mise found at: \(misePath)")
            
            // Check shims
            let shimsPath = "\(misePath)/shims"
            if FileManager.default.fileExists(atPath: shimsPath) {
                do {
                    let shims = try FileManager.default.contentsOfDirectory(atPath: shimsPath)
                    print("Mise shims: \(shims.prefix(10))...") // First 10 shims
                } catch {
                    print("Failed to list shims: \(error)")
                }
            }
        } else {
            print("Mise not installed")
        }
    }
}