// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CoreData
@testable import Data

class BookmarkTests: CoreDataTestCase {
    let fetchRequest = NSFetchRequest<Bookmark>(entityName: String(describing: Bookmark.self))
    
    private func entity(for context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: String(describing: Bookmark.self), in: context)!
    }
    
    func testSimpleCreate() {
        let url = "htt:/bravecom"
        let title = "Brave"
        Bookmark.create(url: URL(string: url), title: title)
        
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 1)
        let result = try! DataController.viewContext.fetch(fetchRequest).first
        
        XCTAssertEqual(result?.url, url)
        XCTAssertEqual(result?.title, title)
        assertDefaultValues(for: result!)
    }
    
    func testCreateNilUrlAndTitle() {
        Bookmark.create(url: nil, title: nil)
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 1)
        let result = try! DataController.viewContext.fetch(fetchRequest).first
        
        XCTAssertNil(result?.url)
        XCTAssertNil(result?.title)
        assertDefaultValues(for: result!)
    }
    
    func testCreateFolder() {
        let url = "http://brave.com"
        let title = "Brave"
        let folderName = "FolderName"
        
        Bookmark.create(url: URL(string: url), title: title, customTitle: folderName, isFolder: true)
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 1)
        let result = try! DataController.viewContext.fetch(fetchRequest).first
        
        XCTAssertEqual(result?.title, title)
        XCTAssertEqual(result?.customTitle, folderName)
        XCTAssert(result!.isFolder)
        XCTAssertEqual(result?.displayTitle, folderName)
    }
    
    func testDisplayTitle() {
        let title = "Brave"
        let customTitle = "CustomBrave"
        
        // Case 1: custom title always takes precedence over regular title
        Bookmark.create(url: nil, title: title, customTitle: customTitle)
        var result = try! DataController.viewContext.fetch(fetchRequest).first
        
        XCTAssertEqual(result?.displayTitle, customTitle)
        result?.delete()
        
        Bookmark.create(url: nil, title: nil, customTitle: customTitle)
        result = try! DataController.viewContext.fetch(fetchRequest).first
        XCTAssertEqual(result?.displayTitle, customTitle)
        result?.delete()
        
        // Case 2: Use title if no custom title provided
        Bookmark.create(url: nil, title: title)
        result = try! DataController.viewContext.fetch(fetchRequest).first
        XCTAssertEqual(result?.displayTitle, title)
        result?.delete()
        
        // Case 3: Return nil if neither title or custom title provided
        Bookmark.create(url: nil, title: nil)
        result = try! DataController.viewContext.fetch(fetchRequest).first
        
        XCTAssertNil(result?.displayTitle)
        
        // Case 4: Titles not nil but empty
        Bookmark.create(url: nil, title: title, customTitle: "")
        result = try! DataController.viewContext.fetch(fetchRequest).first
        XCTAssertEqual(result?.displayTitle, title)
        result?.delete()
        
        Bookmark.create(url: nil, title: "", customTitle: "")
        result = try! DataController.viewContext.fetch(fetchRequest).first
        XCTAssertNil(result?.displayTitle)
    }
    
    
    func testFrc() {
        let frc = Bookmark.frc(parentFolder: nil)
        let request = frc.fetchRequest
        
        XCTAssertEqual(frc.managedObjectContext, DataController.viewContext)
        XCTAssertEqual(request.fetchBatchSize, 20)
        XCTAssertEqual(request.fetchLimit, 0)
        
        XCTAssertNotNil(request.sortDescriptors)
        XCTAssertNotNil(request.predicate)
        
        let bookmarksToAdd = 10
        insertBookmarks(amount: bookmarksToAdd)
        
        XCTAssertNoThrow(try frc.performFetch()) 
        let objects = frc.fetchedObjects
        
        XCTAssertNotNil(objects)
        XCTAssertEqual(objects?.count, bookmarksToAdd)
        
        // Testing if it sorts correctly
        XCTAssertEqual(objects?.first?.title, "1")
        XCTAssertEqual(objects?[5].title, "6")
        XCTAssertEqual(objects?.last?.title, "10")
        
        // Folder sort is before create sort, the folder should appear at the top.
        let folderTitle = "100"
        Bookmark.create(url: URL(string: ""), title: folderTitle, isFolder: true)
        
        try! frc.performFetch()
        XCTAssertEqual(frc.fetchedObjects?.first?.title, folderTitle)
    }
    
    func testFrcWithParentFolder() {
        Bookmark.create(url: URL(string: ""), title: nil, customTitle: "Folder", isFolder: true)
        let folder = try! DataController.viewContext.fetch(fetchRequest).first!
        
        // Few not nested bookmarks
        let nonNestedBookmarksToAdd = 3
        insertBookmarks(amount: nonNestedBookmarksToAdd)
        
        // Few bookmarks inside our folder.
        insertBookmarks(amount: 5, parent: folder)
        
        let frc = Bookmark.frc(parentFolder: folder)
        
        XCTAssertNoThrow(try frc.performFetch()) 
        let objects = frc.fetchedObjects
        
        let bookmarksNotInsideOfFolder = nonNestedBookmarksToAdd + 1 // + 1 for folder
        XCTAssertEqual(objects?.count, Bookmark.all()!.count - bookmarksNotInsideOfFolder)
    }
    
    func testContains() {
        let url = URL(string: "http://brave.com")!
        let wrongUrl = URL(string: "http://wrong.brave.com")!
        Bookmark.create(url: url, title: nil)
        
        XCTAssert(Bookmark.contains(url: url))
        XCTAssertFalse(Bookmark.contains(url: wrongUrl))
    }
    
    
    func testGetChildren() {
        Bookmark.create(url: URL(string: ""), title: nil, customTitle: "Folder", isFolder: true)
        let folder = try! DataController.viewContext.fetch(fetchRequest).first!
        
        let nonNestedBookmarksToAdd = 3
        insertBookmarks(amount: nonNestedBookmarksToAdd)
        
        // Few bookmarks inside our folder.
        let nestedBookmarksCount = 5
        insertBookmarks(amount: nestedBookmarksCount, parent: folder)
        
        XCTAssertEqual(Bookmark.getChildren(forFolderUUID: folder.syncUUID)?.count, nestedBookmarksCount)
    }
    
    func testGetFolders() {
        
    }
    
    func getGetAllBookmarks() {
        
    }
    
    private func insertBookmarks(amount: Int, parent: Bookmark? = nil) {
        let bookmarksBeforeInsert = try! DataController.viewContext.count(for: fetchRequest)
        
        let url = "http://brave.com/"
        for i in 1...amount {
            let title = String(i)
            Bookmark.create(url: URL(string: url + title), title: title, parentFolder: parent)
        }
        
        let difference = bookmarksBeforeInsert + amount
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), difference)
    }
    
    private func assertDefaultValues(for record: Bookmark) {
        // Test awakeFromInsert()
        XCTAssertNotNil(record.created)
        XCTAssertNotNil(record.lastVisited)
        XCTAssertEqual(record.created, record.lastVisited)
        // Make sure date doesn't point to 1970-01-01
        let initialDate = Date(timeIntervalSince1970: 0)
        XCTAssertNotEqual(record.created, initialDate)
        
        // Test defaults
        XCTAssertFalse(record.isFolder)
        XCTAssertFalse(record.isFavorite)
        
        XCTAssertNil(record.parentFolder)
        XCTAssertNil(record.customTitle)
        XCTAssertNil(record.syncParentDisplayUUID)
        XCTAssertNil(record.syncParentUUID)
        
        XCTAssertNotNil(record.syncDisplayUUID)
        XCTAssertNotNil(record.color)
        XCTAssertNotNil(record.children)
        XCTAssert(record.children!.isEmpty)
    }
}
