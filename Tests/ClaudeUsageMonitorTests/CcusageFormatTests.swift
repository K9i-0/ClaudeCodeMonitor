import XCTest
@testable import ClaudeCodeMonitor

/// Tests to ensure ccusage output format remains compatible
@MainActor
final class CcusageFormatTests: XCTestCase {
    // MARK: - JSON Structure Tests

    func testBlocksResponseFormat() throws {
        // Sample blocks response based on ccusage 15.3.0 format
        let sampleJSON = """
        {
          "blocks": [
            {
              "id": "2025-07-05T09:00:00.000Z",
              "startTime": "2025-07-05T09:00:00.000Z",
              "endTime": "2025-07-05T14:00:00.000Z",
              "actualEndTime": "2025-07-05T13:59:34.837Z",
              "isActive": false,
              "isGap": false,
              "entries": 547,
              "tokenCounts": {
                "inputTokens": 1677,
                "outputTokens": 33971,
                "cacheCreationInputTokens": 790511,
                "cacheReadInputTokens": 21795056
              },
              "totalTokens": 35648,
              "costUSD": 50.08764524999999,
              "models": ["claude-opus-4-20250514"],
              "burnRate": null,
              "projection": null
            }
          ]
        }
        """

        let data = sampleJSON.data(using: .utf8)!

        // Should decode without errors
        do {
            let response = try JSONDecoder().decode(BlocksResponse.self, from: data)

            // Verify structure
            XCTAssertEqual(response.blocks.count, 1)

            let firstBlock = response.blocks[0]
            XCTAssertEqual(firstBlock.id, "2025-07-05T09:00:00.000Z")
            XCTAssertEqual(firstBlock.startTime, "2025-07-05T09:00:00.000Z")
            XCTAssertEqual(firstBlock.endTime, "2025-07-05T14:00:00.000Z")
            XCTAssertEqual(firstBlock.isActive, false)
            XCTAssertEqual(firstBlock.isGap, false)
            XCTAssertEqual(firstBlock.entries, 547)
            XCTAssertEqual(firstBlock.totalTokens, 35_648)
            XCTAssertEqual(firstBlock.costUSD, 50.08764524999999)
            XCTAssertEqual(firstBlock.models, ["claude-opus-4-20250514"])

            // Token counts
            let tokenCounts = firstBlock.tokenCounts
            XCTAssertEqual(tokenCounts.inputTokens, 1_677)
            XCTAssertEqual(tokenCounts.outputTokens, 33_971)
            XCTAssertEqual(tokenCounts.cacheCreationInputTokens, 790_511)
            XCTAssertEqual(tokenCounts.cacheReadInputTokens, 21_795_056)
        } catch {
            XCTFail("Failed to decode blocks response: \(error)")
        }
    }

    func testDailyUsageResponseFormat() throws {
        // Sample daily usage response based on ccusage 15.3.0 format
        let sampleJSON = """
        {
          "daily": [
            {
              "date": "2025-07-01",
              "inputTokens": 1417,
              "outputTokens": 41856,
              "cacheCreationTokens": 1209574,
              "cacheReadTokens": 22519751,
              "totalTokens": 23772598,
              "totalCost": 59.61959400000004,
              "modelsUsed": ["claude-opus-4-20250514"],
              "modelBreakdowns": [
                {
                  "modelName": "claude-opus-4-20250514",
                  "inputTokens": 1417,
                  "outputTokens": 41856,
                  "cacheCreationTokens": 1209574,
                  "cacheReadTokens": 22519751,
                  "cost": 59.61959400000004
                }
              ]
            }
          ],
          "totals": {
            "inputTokens": 35009,
            "outputTokens": 873926,
            "cacheCreationTokens": 26108200,
            "cacheReadTokens": 639669139,
            "totalCost": 1489.1776713,
            "totalTokens": 666686274
          }
        }
        """

        let data = sampleJSON.data(using: .utf8)!

        // Should decode without errors
        do {
            let response = try JSONDecoder().decode(CcusageResponse.self, from: data)

            // Verify structure
            XCTAssertEqual(response.daily.count, 1)

            let firstDay = response.daily[0]
            XCTAssertEqual(firstDay.date, "2025-07-01")
            XCTAssertEqual(firstDay.inputTokens, 1_417)
            XCTAssertEqual(firstDay.outputTokens, 41_856)
            XCTAssertEqual(firstDay.cacheCreationTokens, 1_209_574)
            XCTAssertEqual(firstDay.cacheReadTokens, 22_519_751)
            XCTAssertEqual(firstDay.totalTokens, 23_772_598)
            XCTAssertEqual(firstDay.totalCost, 59.61959400000004)
            XCTAssertEqual(firstDay.modelsUsed, ["claude-opus-4-20250514"])

            // Model breakdown
            XCTAssertEqual(firstDay.modelBreakdowns.count, 1)
            let breakdown = firstDay.modelBreakdowns[0]
            XCTAssertEqual(breakdown.modelName, "claude-opus-4-20250514")
            XCTAssertEqual(breakdown.inputTokens, 1_417)

            // Totals
            let totals = response.totals
            XCTAssertEqual(totals.inputTokens, 35_009)
            XCTAssertEqual(totals.outputTokens, 873_926)
            XCTAssertEqual(totals.totalCost, 1_489.1776713)
        } catch {
            XCTFail("Failed to decode daily usage response: \(error)")
        }
    }

    // MARK: - Field Existence Tests

    func testRequiredFieldsInBlockResponse() throws {
        // Minimal valid block response
        let minimalJSON = """
        {
          "blocks": [{
            "id": "2025-07-05T09:00:00.000Z",
            "startTime": "2025-07-05T09:00:00.000Z",
            "endTime": "2025-07-05T14:00:00.000Z",
            "actualEndTime": null,
            "isActive": false,
            "isGap": false,
            "entries": 1,
            "tokenCounts": {
              "inputTokens": 100,
              "outputTokens": 500,
              "cacheCreationInputTokens": 0,
              "cacheReadInputTokens": 0
            },
            "totalTokens": 600,
            "costUSD": 1.5,
            "models": ["claude-3-5-sonnet"],
            "burnRate": null,
            "projection": null
          }]
        }
        """

        let data = minimalJSON.data(using: .utf8)!

        // Should decode successfully with all required fields
        XCTAssertNoThrow(try JSONDecoder().decode(BlocksResponse.self, from: data))
    }

    func testRequiredFieldsInDailyUsageResponse() throws {
        // Minimal valid daily usage response
        let minimalJSON = """
        {
          "daily": [{
            "date": "2025-07-01",
            "inputTokens": 1000,
            "outputTokens": 2000,
            "cacheCreationTokens": 0,
            "cacheReadTokens": 0,
            "totalTokens": 3000,
            "totalCost": 5.0,
            "modelsUsed": ["claude-3-5-sonnet"],
            "modelBreakdowns": [{
              "modelName": "claude-3-5-sonnet",
              "inputTokens": 1000,
              "outputTokens": 2000,
              "cacheCreationTokens": 0,
              "cacheReadTokens": 0,
              "cost": 5.0
            }]
          }],
          "totals": {
            "inputTokens": 1000,
            "outputTokens": 2000,
            "cacheCreationTokens": 0,
            "cacheReadTokens": 0,
            "totalCost": 5.0,
            "totalTokens": 3000
          }
        }
        """

        let data = minimalJSON.data(using: .utf8)!

        // Should decode successfully with all required fields
        XCTAssertNoThrow(try JSONDecoder().decode(CcusageResponse.self, from: data))
    }

    // MARK: - Breaking Change Detection Tests

    func testBlockResponseMissingRequiredField() {
        // Test various missing fields to ensure they would cause decoding errors
        let missingFieldTests = [
            // Missing 'blocks' wrapper
            """
            [{
              "id": "2025-07-05T09:00:00.000Z",
              "startTime": "2025-07-05T09:00:00.000Z",
              "endTime": "2025-07-05T14:00:00.000Z",
              "actualEndTime": null,
              "isActive": false,
              "isGap": false,
              "entries": 1,
              "tokenCounts": {
                "inputTokens": 100,
                "outputTokens": 500,
                "cacheCreationInputTokens": 0,
                "cacheReadInputTokens": 0
              },
              "totalTokens": 600,
              "costUSD": 1.5,
              "models": ["claude-3-5-sonnet"],
              "burnRate": null,
              "projection": null
            }]
            """,
            // Missing 'id'
            """
            {
              "blocks": [{
                "startTime": "2025-07-05T09:00:00.000Z",
                "endTime": "2025-07-05T14:00:00.000Z",
                "actualEndTime": null,
                "isActive": false,
                "isGap": false,
                "entries": 1,
                "tokenCounts": {
                  "inputTokens": 100,
                  "outputTokens": 500,
                  "cacheCreationInputTokens": 0,
                  "cacheReadInputTokens": 0
                },
                "totalTokens": 600,
                "costUSD": 1.5,
                "models": ["claude-3-5-sonnet"],
                "burnRate": null,
                "projection": null
              }]
            }
            """,
            // Missing 'tokenCounts'
            """
            {
              "blocks": [{
                "id": "2025-07-05T09:00:00.000Z",
                "startTime": "2025-07-05T09:00:00.000Z",
                "endTime": "2025-07-05T14:00:00.000Z",
                "actualEndTime": null,
                "isActive": false,
                "isGap": false,
                "entries": 1,
                "totalTokens": 600,
                "costUSD": 1.5,
                "models": ["claude-3-5-sonnet"],
                "burnRate": null,
                "projection": null
              }]
            }
            """
        ]

        for json in missingFieldTests {
            let data = json.data(using: .utf8)!

            // Should fail to decode when required fields are missing
            XCTAssertThrowsError(try JSONDecoder().decode(BlocksResponse.self, from: data))
        }
    }

    func testDailyUsageResponseMissingRequiredField() {
        // Test various missing fields to ensure they would cause decoding errors
        let missingFieldTests = [
            // Missing 'daily' wrapper
            """
            {
              "totals": {
                "inputTokens": 1000,
                "outputTokens": 2000,
                "cacheCreationTokens": 0,
                "cacheReadTokens": 0,
                "totalCost": 5.0,
                "totalTokens": 3000
              }
            }
            """,
            // Missing 'date' in daily
            """
            {
              "daily": [{
                "inputTokens": 1000,
                "outputTokens": 2000,
                "cacheCreationTokens": 0,
                "cacheReadTokens": 0,
                "totalTokens": 3000,
                "totalCost": 5.0,
                "modelsUsed": ["claude-3-5-sonnet"],
                "modelBreakdowns": []
              }],
              "totals": {
                "inputTokens": 1000,
                "outputTokens": 2000,
                "cacheCreationTokens": 0,
                "cacheReadTokens": 0,
                "totalCost": 5.0,
                "totalTokens": 3000
              }
            }
            """,
            // Missing 'totals' entirely
            """
            {
              "daily": [{
                "date": "2025-07-01",
                "inputTokens": 1000,
                "outputTokens": 2000,
                "cacheCreationTokens": 0,
                "cacheReadTokens": 0,
                "totalTokens": 3000,
                "totalCost": 5.0,
                "modelsUsed": ["claude-3-5-sonnet"],
                "modelBreakdowns": []
              }]
            }
            """
        ]

        for json in missingFieldTests {
            let data = json.data(using: .utf8)!

            // Should fail to decode when required fields are missing
            XCTAssertThrowsError(try JSONDecoder().decode(CcusageResponse.self, from: data))
        }
    }

    // MARK: - Integration Test

    func testRealCcusageOutput() async throws {
        // Skip in CI environment
        if ProcessInfo.processInfo.environment["CI"] != nil {
            throw XCTSkip("Skipping real ccusage test in CI")
        }

        // Try to execute actual ccusage command
        do {
            let executor = CommandExecutor.shared

            // Test blocks command
            let blocksOutput = try await executor.executeCcusageCommand(
                subcommand: "blocks",
                additionalArgs: ["--json", "--limit", "1"]
            )

            let blocksData = blocksOutput.data(using: .utf8)!
            let blocksResponse = try JSONDecoder().decode(BlocksResponse.self, from: blocksData)
            XCTAssertFalse(blocksResponse.blocks.isEmpty)

            // Test daily usage command
            let dailyOutput = try await executor.executeCcusageCommand(
                additionalArgs: ["--json", "--limit", "1"]
            )

            let dailyData = dailyOutput.data(using: .utf8)!
            let ccusageResponse = try JSONDecoder().decode(CcusageResponse.self, from: dailyData)
            XCTAssertFalse(ccusageResponse.daily.isEmpty)
            XCTAssertNotNil(ccusageResponse.totals)
        } catch CommandExecutor.CommandError.commandNotFound {
            throw XCTSkip("ccusage not available")
        } catch {
            // Other errors should fail the test
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Version Pinning Test

    func testCcusageVersionPinning() {
        // Verify that package.json contains the expected version
        let expectedVersion = "15.3.0"

        // Read package.json to verify version
        let packageJsonPath = #file.replacingOccurrences(
            of: "Tests/ClaudeUsageMonitorTests/CcusageFormatTests.swift",
            with: "package.json"
        )

        do {
            let content = try String(contentsOfFile: packageJsonPath)
            let data = content.data(using: .utf8)!

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dependencies = json["dependencies"] as? [String: String],
               let ccusageVersion = dependencies["ccusage"] {
                XCTAssertEqual(ccusageVersion, expectedVersion,
                             "package.json should specify ccusage version \(expectedVersion)")
            } else {
                XCTFail("Failed to parse package.json")
            }
        } catch {
            XCTFail("Failed to read package.json: \(error)")
        }

        // Also verify that CommandExecutor uses BundleConfiguration
        let commandExecutorPath = #file.replacingOccurrences(
            of: "Tests/ClaudeUsageMonitorTests/CcusageFormatTests.swift",
            with: "Sources/ClaudeUsageMonitor/Services/CommandExecutor.swift"
        )

        do {
            let content = try String(contentsOfFile: commandExecutorPath)
            XCTAssertTrue(content.contains("BundleConfiguration.ccusageVersion"),
                         "CommandExecutor should use BundleConfiguration.ccusageVersion")
        } catch {
            XCTFail("Failed to read CommandExecutor.swift: \(error)")
        }
    }
}

// MARK: - Test Helpers

extension CcusageFormatTests {
    /// Helper to verify that a JSON structure matches our expected format
    func verifyJSONStructure<T: Decodable>(_ jsonString: String, type: T.Type) -> Bool {
        guard let data = jsonString.data(using: .utf8) else { return false }

        do {
            _ = try JSONDecoder().decode(type, from: data)
            return true
        } catch {
            return false
        }
    }

    /// Helper to test partial JSON (for breaking change detection)
    func testPartialDecode<T: Decodable>(_ jsonString: String, type: T.Type) throws {
        let data = jsonString.data(using: .utf8)!
        _ = try JSONDecoder().decode(type, from: data)
    }
}
