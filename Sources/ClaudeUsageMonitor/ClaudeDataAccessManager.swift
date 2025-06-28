import Foundation
import AppKit

@MainActor
class ClaudeDataAccessManager: ObservableObject {
    @Published var hasAccess = false
    @Published var claudePath: String?
    
    private let bookmarkKey = "ClaudeDataFolderBookmark"
    
    init() {
        checkExistingAccess()
    }
    
    /// Check if we have existing access via bookmark
    func checkExistingAccess() {
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
        
        return await withCheckedContinuation { continuation in
            FolderAccessHelper.requestFolderAccess { [weak self] url in
                guard let self = self, let url = url else {
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
            print("[ClaudeDataAccess] Selected folder doesn't contain 'projects' subdirectory")
            // Show error alert
            await showError(message: L10n.invalidClaudeFolder)
            return false
        }
        
        // Start accessing the resource BEFORE creating bookmark
        let startedAccess = url.startAccessingSecurityScopedResource()
        print("[ClaudeDataAccess] Started security-scoped access: \(startedAccess)")
        
        guard startedAccess else {
            print("[ClaudeDataAccess] Failed to start accessing security-scoped resource")
            await showError(message: L10n.failedToSaveAccess)
            return false
        }
        
        // Create security-scoped bookmark while access is active
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope,
                                                   includingResourceValuesForKeys: nil,
                                                   relativeTo: nil)
            
            // Save bookmark to UserDefaults
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
            UserDefaults.standard.synchronize() // Force save
            
            claudePath = url.path
            hasAccess = true
            print("[ClaudeDataAccess] Successfully saved access to: \(url.path)")
            print("[ClaudeDataAccess] hasAccess is now: \(hasAccess)")
            
            // Don't stop accessing here - keep it active for the session
            return true
        } catch {
            print("[ClaudeDataAccess] Error creating bookmark: \(error)")
            await showError(message: L10n.failedToSaveAccess)
            return false
        }
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
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        if let path = claudePath {
            URL(fileURLWithPath: path).stopAccessingSecurityScopedResource()
        }
        claudePath = nil
        hasAccess = false
    }
}