// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CoreData
@testable import Data

class DataControllerTests: CoreDataTestCase {
    let entityName = String(describing: TopSite.self)
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: TopSite.self))

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        // TODO: This will be most likely abstracted in CoreDataTestCase
        let mainContext = DataController.shared.mainThreadContext
        (try! mainContext.fetch(fetchRequest) as! [NSManagedObject]).forEach {
            mainContext.delete($0)
        }       
        try! mainContext.save()
        
        let workerContext = DataController.shared.workerContext
        (try! workerContext.fetch(fetchRequest) as! [NSManagedObject]).forEach {
            workerContext.delete($0)
        }       
        try! workerContext.save()
        
        super.tearDown()
    }
    
    private func entity(for context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: String(describing: TopSite.self), in: context)!
    }
    
    func testStoreIsEmpty() {
        let mainContext = DataController.shared.mainThreadContext
        let mainResult = try! mainContext.fetch(fetchRequest)
        XCTAssert(mainResult.isEmpty)
        
        let workerContext = DataController.shared.workerContext
        let workerResult = try! workerContext.fetch(fetchRequest)
        XCTAssert(workerResult.isEmpty)
    }
    
    func testSavingMainContext() {
        let context = DataController.shared.mainThreadContext
        
        _ = TopSite(entity: entity(for: context), insertInto: context)
        DataController.saveContext(context: context)
        
        let result = try! context.fetch(fetchRequest)
        XCTAssertEqual(result.count, 1)
    }
    
    func testSavingWorkerContext() {
        let context = DataController.shared.mainThreadContext
        
        _ = TopSite(entity: entity(for: context), insertInto: context)
        DataController.saveContext(context: context)
        
        let result = try! context.fetch(fetchRequest)
        XCTAssertEqual(result.count, 1)
    }
    
    func testRemoveObject() {
        let context = DataController.shared.mainThreadContext
        
        let object = TopSite(entity: entity(for: context), insertInto: context)
        DataController.saveContext(context: context)
        
        var result = try! context.fetch(fetchRequest)
        XCTAssertEqual(result.count, 1)
        
        DataController.remove(object: object)
        result = try! context.fetch(fetchRequest)
        XCTAssertEqual(result.count, 0)
    }
}
