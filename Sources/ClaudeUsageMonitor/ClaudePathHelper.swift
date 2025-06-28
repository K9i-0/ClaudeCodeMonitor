import Foundation

struct ClaudePathHelper {
    /// Get the expected Claude data paths in order of preference
    static func getExpectedPaths() -> [URL] {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        return [
            homeURL.appendingPathComponent(".claude"),
            homeURL.appendingPathComponent(".config/claude")
        ]
    }
    
    /// Find the first existing Claude data path
    static func findExistingClaudePath() -> URL? {
        let paths = getExpectedPaths()
        let fileManager = FileManager.default
        
        for path in paths {
            let projectsPath = path.appendingPathComponent("projects")
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: projectsPath.path, isDirectory: &isDirectory),
               isDirectory.boolValue {
                return path
            }
        }
        
        return nil
    }
}