// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import Deferred
import os.log

extension FileManager {
    public enum Folder: String {
        case cookie = "/Cookies"
        case webSiteData = "/WebKit/WebsiteData"
    }
    public typealias FolderLockObj = (folder: Folder, lock: Bool)
    
    static var documentDirectoryURL: URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    //Lock a folder using FolderLockObj provided.
    @discardableResult public func setFolderAccess(_ lockObjects: [FolderLockObj]) -> Bool {
        guard let baseDir = baseDirectory() else { return false }
        for lockObj in lockObjects {
            do {
                try self.setAttributes([.posixPermissions: (lockObj.lock ? 0 : 0o755)], ofItemAtPath: baseDir + lockObj.folder.rawValue)
            } catch {
                os_log(.error, log: Log.filesystem, "Failed to %{public}s item at path %s, %{public}s",
                       lockObj.lock ? "Lock" : "Unlock", lockObj.folder.rawValue, error.localizedDescription)
                return false
            }
        }
        return true
    }
    
    // Check the locked status of a folder. Returns true for locked.
    public func checkLockedStatus(folder: Folder) -> Bool {
        guard let baseDir = baseDirectory() else { return false }
        do {
            if let lockValue = try self.attributesOfItem(atPath: baseDir + folder.rawValue)[.posixPermissions] as? NSNumber {
                return lockValue == 0o755
            }
        } catch {
            os_log(.error, log: Log.filesystem, "Failed to check lock status on item at path %s, %{public}s",
                   folder.rawValue, error.localizedDescription)
        }
        return false
    }
    
    func writeToDiskInFolder(_ data: Data, fileName: String, folderName: String) -> Bool {
        
        guard let folderUrl = getOrCreateFolder(name: folderName) else { return false }
        
        do {
            let fileUrl = folderUrl.appendingPathComponent(fileName)
            try data.write(to: fileUrl, options: [.atomic])
        } catch {
            os_log(.error, log: Log.filesystem, "Failed to write data, %{public}s", error.localizedDescription)
            return false
        }

        return true
    }
    
    /// Creates a folder at documents directory and returns its URL.
    /// If folder already exists, returns its URL as well.
    func getOrCreateFolder(name: String, excludeFromBackups: Bool = true) -> URL? {
        guard let documentsDir = FileManager.documentDirectoryURL else { return nil }
        
        var folderDir = documentsDir.appendingPathComponent(name)
        
        if fileExists(atPath: folderDir.path) { return folderDir }
        
        do {
            try createDirectory(at: folderDir, withIntermediateDirectories: true, attributes: nil)
            
            if excludeFromBackups {
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = true
                try folderDir.setResourceValues(resourceValues)
            }
            
            return folderDir
        } catch {
            os_log(.error, log: Log.filesystem, "Failed to create folder with name %s, %{public}s",
                   name, error.localizedDescription)
            return nil
        }
    }
    
    private func baseDirectory() -> String? {
         return NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first
    }
}
