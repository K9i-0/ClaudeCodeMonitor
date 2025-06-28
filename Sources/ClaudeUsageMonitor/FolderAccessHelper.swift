import Foundation
import AppKit

@MainActor
class FolderAccessHelper {
    static func requestFolderAccess(completion: @escaping (URL?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.title = L10n.selectClaudeDataFolder
        openPanel.message = L10n.claudeDataFolderMessage
        openPanel.prompt = L10n.select
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.showsHiddenFiles = true
        
        // Set default directory to home
        openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        
        // Make sure panel is key and front
        openPanel.makeKeyAndOrderFront(nil)
        openPanel.level = .modalPanel
        
        openPanel.begin { response in
            if response == .OK {
                completion(openPanel.url)
            } else {
                completion(nil)
            }
        }
    }
}