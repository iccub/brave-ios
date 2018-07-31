// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CoreData
@testable import Data

class DataControllerTests: CoreDataTestCase {
    // TopSite is the simplest model we have to test DataController internals.
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: TopSite.self))
    
    private func entity(for context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: String(describing: TopSite.self), in: context)!
    }
    
    func testStoreIsEmpty() {
        // Checking main and background contexts with TopSite model
        let mainContext = DataController.mainContext
        XCTAssertEqual(try! mainContext.count(for: fetchRequest), 0)
        
        let workerContext = DataController.backgroundContext
        XCTAssertEqual(try! workerContext.count(for: fetchRequest), 0)
        
        // Checking rest of entities
        let bookmarkFR = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: Bookmark.self))
        XCTAssertEqual(try! mainContext.count(for: bookmarkFR), 0)
        
        let tabFR = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: TabMO.self))
        XCTAssertEqual(try! mainContext.count(for: tabFR), 0)
        
        // FaviconMO class name is different from its model(probably due to firefox having favicon class already)
        // Need to use hardcoded string here.
        let faviconFR = NSFetchRequest<NSFetchRequestResult>(entityName: "Favicon")
        XCTAssertEqual(try! mainContext.count(for: faviconFR), 0)
        
        let domainFR = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: Domain.self))
        XCTAssertEqual(try! mainContext.count(for: domainFR), 0)
        
        let deviceFR = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: Device.self))
        XCTAssertEqual(try! mainContext.count(for: deviceFR), 0)
        
        let historyFR = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: History.self))
        XCTAssertEqual(try! mainContext.count(for: historyFR), 0)
    }
    
    func testSavingMainContext() {
        let context = DataController.mainContext
        
        _ = TopSite(entity: entity(for: context), insertInto: context)
        DataController.save(context)
        
        let result = try! context.fetch(fetchRequest)
        XCTAssertEqual(result.count, 1)
    }
    
    func testSavingWorkerContext() {
        let context = DataController.backgroundContext
        
        contextSaveExpectation()
        
        _ = TopSite(entity: entity(for: context), insertInto: context)
        DataController.save(context)
        
        let result = try! context.fetch(fetchRequest)
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertEqual(result.count, 1)
    }
    
    // TODO: This probably falls into CRUDProtocolTests.
    func testRemoveObject() {
        let context = DataController.backgroundContext
        
        contextSaveExpectation()
        
        let object = TopSite(entity: entity(for: context), insertInto: context)
        DataController.save(context)
        
        var result = try! context.fetch(fetchRequest)
        XCTAssertEqual(result.count, 1)
        
        object.delete()
        waitForExpectations(timeout: 1, handler: nil)
        
        result = try! context.fetch(fetchRequest)
        
        XCTAssertEqual(result.count, 0)
    }
}
