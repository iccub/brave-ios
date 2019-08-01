// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import os.log

struct ScriptOpener {
    /// Opens a javascript file with a given name. Uses Data framework's bundle by default.
    static func get(withName name: String, fromMainBundle: Bool = false) -> String? {
        let bundleId = "com.brave.Data"
        
        guard let bundle = fromMainBundle ? Bundle.main : Bundle(identifier: bundleId) else {
            assertionFailure("Could not get a Data framework with identifier: \(bundleId)")
            return nil
        }
        
        guard let filePath = bundle.path(forResource: name, ofType: "js") else {
            os_log(.error, log: Log.filesystem, "Could not find script named: %s", name)
            return nil
        }
        
        do {
            let contents = try String(contentsOfFile: filePath, encoding: String.Encoding.utf8)
            return contents
        } catch {
            os_log(.error, log: Log.filesystem, "Could not find or parse script named: %s", name)
            return nil
        }
    }
}
