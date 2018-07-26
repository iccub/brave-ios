// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import Data

class CoreDataTestCase: XCTestCase {
    var dataController: DataController! 
    
    override func setUp() {
        super.setUp()
        dataController = DataController.shared
    }
    
    override func tearDown() {
        dataController = nil
    }
}
