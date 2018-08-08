// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CoreData
import Shared
@testable import Data

class TabMOTests: CoreDataTestCase {
    let fetchRequest = NSFetchRequest<TabMO>(entityName: String(describing: TabMO.self))
    
    private func entity(for context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: String(describing: TabMO.self), in: context)!
    }

    func testCreate() {
        _ = TabMO.create()
        
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 1)
        let object = try! DataController.viewContext.fetch(fetchRequest).first!
        
        XCTAssertNotNil(object.syncUUID)
        XCTAssertNotNil(object.imageUrl)
        XCTAssertNil(object.url)
        XCTAssertEqual(object.title, Strings.New_Tab)
        
        // Testing default values
        XCTAssertEqual(object.order, 0)
        XCTAssertEqual(object.urlHistoryCurrentIndex, 0)
        
        XCTAssertFalse(object.isSelected)
        
        XCTAssertNil(object.color)
        XCTAssertNil(object.screenshot)
        XCTAssertNil(object.screenshotUUID)
        XCTAssertNil(object.url)
        XCTAssertNil(object.urlHistorySnapshot)
        
    }
    
    func testUpdate() {
        let newTitle = "UpdatedTitle"
        let newUrl = "http://example.com"
        
        _ = TabMO.create()
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 1)
        
        var object = try! DataController.viewContext.fetch(fetchRequest).first!
        
        XCTAssertNotEqual(object.title, newTitle)
        XCTAssertNotEqual(object.url, newUrl)
        
        let tabData = SavedTab(id: object.syncUUID!, title: newTitle, url: newUrl, isSelected: true, order: 10, 
                               screenshot: UIImage.sampleImage(), history: ["history1", "history2"], historyIndex: 20)
        
        TabMO.update(tabData: tabData)
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 1)
        
        // Need to refresh context here.
        DataController.viewContext.reset()
        
        object = try! DataController.viewContext.fetch(fetchRequest).first!
        
        XCTAssertNotNil(object.syncUUID)
        XCTAssertNotNil(object.imageUrl)
        XCTAssertNotNil(object.screenshot)
        
        XCTAssertEqual(object.url, newUrl)
        XCTAssertEqual(object.title, newTitle)
        XCTAssertEqual(object.order, 10)
        XCTAssertEqual(object.urlHistoryCurrentIndex, 20)
        XCTAssertEqual(object.urlHistorySnapshot?.count, 2)
        
        XCTAssert(object.isSelected)
        
        XCTAssertNil(object.color)
        XCTAssertNil(object.screenshotUUID)
    }
    
    func testUpdateWrongId() {
        let newTitle = "UpdatedTitle"
        let newUrl = "http://example.com"
        let wrongId = "999"
        
        _ = TabMO.create()
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 1)
        
        var object = try! DataController.viewContext.fetch(fetchRequest).first!
        
        XCTAssertNotEqual(object.title, newTitle)
        XCTAssertNotEqual(object.url, newUrl)
        
        let tabData = SavedTab(id: wrongId, title: newTitle, url: newUrl, isSelected: true, order: 10, 
                               screenshot: UIImage.sampleImage(), history: ["history1", "history2"], historyIndex: 20)
        
        TabMO.update(tabData: tabData)
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 1)
        
        // Need to refresh context here.
        DataController.viewContext.reset()
        object = try! DataController.viewContext.fetch(fetchRequest).first!
        
        // Nothing should change
        XCTAssertNotEqual(object.title, newTitle)
        XCTAssertNotEqual(object.url, newUrl)
    }
    
    func testDelete() {
        _ = TabMO.create()
        let object = try! DataController.viewContext.fetch(fetchRequest).first!
        
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 1)
        object.delete()
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 0)
    }
    
    func testImageUrl() {
        _ = TabMO.create()
        let object = try! DataController.viewContext.fetch(fetchRequest).first!
        
        XCTAssertEqual(object.imageUrl, URL(string: "https://imagecache.mo/\(object.syncUUID!).png"))
    }
    
    func testSaveScreenshotUUID() {
        _ = TabMO.create()
        let newUUID = UUID()
        var object = try! DataController.viewContext.fetch(fetchRequest).first!
        
        XCTAssertNil(object.screenshotUUID)
        TabMO.saveScreenshotUUID(newUUID, tabId: object.syncUUID)
        DataController.viewContext.reset()
        
        object = try! DataController.viewContext.fetch(fetchRequest).first!
        XCTAssertNotNil(object.screenshotUUID)
    }
    
    func testSaveScreenshotUUIDWrongId() {
        let wrongId = "999"
        _ = TabMO.create()
        let newUUID = UUID()
        var object = try! DataController.viewContext.fetch(fetchRequest).first!
        
        XCTAssertNil(object.screenshotUUID)
        TabMO.saveScreenshotUUID(newUUID, tabId: wrongId)
        DataController.viewContext.reset()
        
        object = try! DataController.viewContext.fetch(fetchRequest).first!
        XCTAssertNil(object.screenshotUUID)
    }
    
    private func createAndUpdate(order: Int) {
        let object = TabMO.create()
        let tabData = SavedTab(id: object.syncUUID!, title: "title", url: "url", isSelected: false, order: Int16(order), 
                               screenshot: nil, history: [], historyIndex: 0)
        TabMO.update(tabData: tabData)
        
    }
    
    func testGetAll() {
        createAndUpdate(order: 1)
        createAndUpdate(order: 3)
        createAndUpdate(order: 2)
        
        // Getting all objects and sorting them manually by order
        let objectsSortedByOrder = try! DataController.viewContext.fetch(fetchRequest).sorted(by: { $0.order < $1.order })
        
        
        let all = TabMO.getAll()
        XCTAssertEqual(all.count, 3)
        
        // getAll() also should return objects sorted by order
        XCTAssertEqual(all[0], objectsSortedByOrder[0])
        XCTAssertEqual(all[1].syncUUID, objectsSortedByOrder[1].syncUUID)
        XCTAssertEqual(all[2].syncUUID, objectsSortedByOrder[2].syncUUID)
        
        // Need to update order of each of our objects
    }
    
    func testGetFromId() {
        _ = TabMO.create()
        let wrongId = "999"
        let object = try! DataController.viewContext.fetch(fetchRequest).first!
        
        XCTAssertNotNil(TabMO.get(fromId: object.syncUUID!))
        XCTAssertNil(TabMO.get(fromId: wrongId))
    }
}

private extension UIImage {
    class func sampleImage() -> UIImage {
        let color = UIColor.blue
        let rect = CGRect(origin: CGPoint(x: 0, y:0), size: CGSize(width: 1, height: 1))
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        
        context.setFillColor(color.cgColor)
        context.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}
