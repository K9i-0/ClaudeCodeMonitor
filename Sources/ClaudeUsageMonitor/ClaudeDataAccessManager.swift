import Foundation
import AppKit

@MainActor
class ClaudeDataAccessManager: ObservableObject {
    @Published var hasAccess = false
    @Published var claudePath: String?
    
    private let bookmarkKey = "ClaudeDataFolderBookmark"
    
    init() {
        print("[ClaudeDataAccess] Initializing...")
        checkExistingAccess()
        print("[ClaudeDataAccess] Initial hasAccess: \(hasAccess), claudePath: \(claudePath ?? "nil")")
    }
    
    /// Check if we have existing access via saved path or bookmark
    func checkExistingAccess() {
        // First try to load saved path
        if let savedPath = UserDefaults.standard.string(forKey: "claudeDataPath") {
            print("[ClaudeDataAccess] Found saved path: \(savedPath)")
            // Verify the path still exists and has projects subdirectory
            let url = URL(fileURLWithPath: savedPath)
            let projectsURL = url.appendingPathComponent("projects")
            
            if FileManager.default.fileExists(atPath: projectsURL.path) {
                claudePath = savedPath
                hasAccess = true
                print("[ClaudeDataAccess] Path is valid, access restored")
                return
            } else {
                print("[ClaudeDataAccess] Saved path no longer valid")
                // Clear invalid path
                UserDefaults.standard.removeObject(forKey: "claudeDataPath")
            }
        }
        
        // Legacy bookmark support
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            print("[ClaudeDataAccess] No existing bookmark found")
            return
        }
        
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData,
                            options: .withSecurityScope,
                            relativeTo: nil,
                            bookmarkDataIsStale: &isStale)
            
            if isStale {
                print("[ClaudeDataAccess] Bookmark is stale, need to request access again")
                hasAccess = false
                return
            }
            
            // Start accessing the security-scoped resource
            if url.startAccessingSecurityScopedResource() {
                claudePath = url.path
                hasAccess = true
                print("[ClaudeDataAccess] Successfully accessed Claude data at: \(url.path)")
                
                // We'll stop accessing when the app terminates
                // In a real app, you might want to manage this more carefully
            } else {
                print("[ClaudeDataAccess] Failed to access security-scoped resource")
                hasAccess = false
            }
        } catch {
            print("[ClaudeDataAccess] Error resolving bookmark: \(error)")
            hasAccess = false
        }
    }
    
    /// Request access to Claude data folder
    func requestAccess() async -> Bool {
        print("[ClaudeDataAccess] Requesting folder access...")
        
        // Pause event monitor to prevent popover from closing
        await MainActor.run {
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.pauseEventMonitor()
            }
        }
        
        return await withCheckedContinuation { continuation in
            FolderAccessHelper.requestFolderAccess { [weak self] url in
                guard let self = self else {
                    continuation.resume(returning: false)
                    return
                }
                
                // Resume event monitor after dialog is closed
                Task { @MainActor in
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.resumeEventMonitor()
                    }
                }
                
                guard let url = url else {
                    print("[ClaudeDataAccess] User cancelled folder selection")
                    continuation.resume(returning: false)
                    return
                }
                
                print("[ClaudeDataAccess] User selected: \(url.path)")
                
                Task {
                    let success = await self.processSelectedFolder(url)
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    private func processSelectedFolder(_ url: URL) async -> Bool {
        
        // Verify this is a Claude data folder by checking for projects subdirectory
        let projectsURL = url.appendingPathComponent("projects")
        let fileManager = FileManager.default
        
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: projectsURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            print("[ClaudeDataAccess] Selected folder doesn't contain 'projects' subdirectory: \(url.path)")
            print("[ClaudeDataAccess] Looking for: \(projectsURL.path)")
            // Show error alert with more detail
            let errorMessage = """
            \(L10n.invalidClaudeFolder)
            
            Selected: \(url.path)
            Expected: ~/.claude (with projects subdirectory)
            """
            await showError(message: errorMessage)
            return false
        }
        
        // Start accessing the resource BEFORE creating bookmark
        // Note: startAccessingSecurityScopedResource returns false for non-security-scoped URLs,
        // which is normal for user-selected folders via NSOpenPanel
        let startedAccess = url.startAccessingSecurityScopedResource()
        print("[ClaudeDataAccess] Started security-scoped access: \(startedAccess)")
        print("[ClaudeDataAccess] URL: \(url.path)")
        
        // Don't fail if startAccessingSecurityScopedResource returns false
        // as it's expected for regular file URLs from NSOpenPanel
        
        // For App Sandbox, we'll simply save the path and rely on the server
        // to access the files with CLAUDE_CONFIG_DIR environment variable
        claudePath = url.path
        hasAccess = true
        
        // Save the path to UserDefaults (not as bookmark, just as string)
        UserDefaults.standard.set(url.path, forKey: "claudeDataPath")
        UserDefaults.standard.synchronize()
        
        print("[ClaudeDataAccess] Successfully saved path: \(url.path)")
        print("[ClaudeDataAccess] hasAccess is now: \(hasAccess)")
        
        // Stop accessing if we started it
        if startedAccess {
            url.stopAccessingSecurityScopedResource()
        }
        
        return true
    }
    
    /// Show error alert
    private func showError(message: String) async {
        await MainActor.run {
            let alert = NSAlert()
            alert.messageText = L10n.error
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: L10n.ok)
            
            alert.runModal()
        }
    }
    
    /// Reset access (for testing or if user wants to change folder)
    func resetAccess() {
        print("[ClaudeDataAccess] Resetting access...")
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        UserDefaults.standard.removeObject(forKey: "claudeDataPath")
        UserDefaults.standard.synchronize()
        
        if let path = claudePath {
            URL(fileURLWithPath: path).stopAccessingSecurityScopedResource()
        }
        claudePath = nil
        hasAccess = false
    }
}