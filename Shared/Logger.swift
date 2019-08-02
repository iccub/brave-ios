/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCGLogger
import os.log

private let subsystem = "com.brave.logs"

public struct Log {
    public static let browser = OSLog(subsystem: subsystem, category: "browser")
    public static let tests = OSLog(subsystem: subsystem, category: "tests")
    public static let migration = OSLog(subsystem: subsystem, category: "migration")
    public static let referrals = OSLog(subsystem: subsystem, category: "URP")
    public static let webAuthentication = OSLog(subsystem: subsystem, category: "webauth")
    public static let adBlocking = OSLog(subsystem: subsystem, category: "adblock")
    
    /// Logs related to saving files, creting, reading directories, granting r/w permissions..
    public static let filesystem = OSLog(subsystem: subsystem, category: "filesystem")
    public static let sync = OSLog(subsystem: subsystem, category: "sync")
    public static let networking = OSLog(subsystem: subsystem, category: "networking")
    public static let rewards = OSLog(subsystem: subsystem, category: "rewards")
    public static let database = OSLog(subsystem: subsystem, category: "database")
    public static let DAU = OSLog(subsystem: subsystem, category: "dau")
}
