import XCTest
@testable import ClaudeCodeMonitor

final class CommandExecutorSyncTests: XCTestCase {
    
    @MainActor
    func testCheckEnvironmentSync() async throws {
        // Test that sync check returns same result as async check
        let syncResult = CommandExecutor.shared.checkEnvironmentSync()
        let asyncResult = await CommandExecutor.shared.checkEnvironment()
        
        // Both should return the same values
        XCTAssertEqual(syncResult.isClaudeCodeInstalled, asyncResult.isClaudeCodeInstalled)
        XCTAssertEqual(syncResult.isBunInstalled, asyncResult.isBunInstalled)
        XCTAssertEqual(syncResult.isNpxInstalled, asyncResult.isNpxInstalled)
        XCTAssertEqual(syncResult.canExecuteCommands, asyncResult.canExecuteCommands)
    }
    
    @MainActor
    func testCheckEnvironmentSyncPerformance() {
        // Test that sync check completes quickly
        measure {
            _ = CommandExecutor.shared.checkEnvironmentSync()
        }
    }
}