// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CoreData
@testable import Data

class CoreDataTestCase: XCTestCase {
    
    // Always call super.setUp() in your subclasses to reset the database.
    override func setUp() {
        DataController.resetDatabase()
        
        NotificationCenter.default.addObserver(self, selector: #selector(contextSaved), 
                                               name: NSNotification.Name.NSManagedObjectContextDidSave, 
                                               object: nil)
        super.setUp()
    }
    
    override func tearDown() {
        NotificationCenter.default.removeObserver(self)
        contextSaveCompletionHandler = nil
        super.tearDown()
    }
    
    // MARK: - Handling background context reads/writes

    var contextSaveCompletionHandler: (()->())?
    
    @objc func contextSaved() {
        contextSaveCompletionHandler?()
    }
    
    /// This expecation can be used on most tests.
    /// For more complex multi thread tests, expectations need to be written manually.
    func contextSaveExpectation() {
        let contextSaveExpectation = expectation(description: "Save context expectation")
        
        contextSaveCompletionHandler = {
            contextSaveExpectation.fulfill()
        }
    }
}