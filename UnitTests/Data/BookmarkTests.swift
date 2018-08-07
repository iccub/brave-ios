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
    
    // MARK: - Getters/properties
    
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
    
    // MARK: - Create
    
    func testSimpleCreate() {
        let url = "http://brave.com"
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
    
    // MARK: - Read
    
    func testContains() {
        let url = URL(string: "http://brave.com")!
        let wrongUrl = URL(string: "http://wrong.brave.com")!
        Bookmark.create(url: url, title: nil)
        
        XCTAssert(Bookmark.contains(url: url))
        XCTAssertFalse(Bookmark.contains(url: wrongUrl))
    }
    
    func testGetChildren() {
        Bookmark.create(url: nil, title: nil, customTitle: "Folder", isFolder: true)
        let folder = try! DataController.viewContext.fetch(fetchRequest).first!
        
        let nonNestedBookmarksToAdd = 3
        insertBookmarks(amount: nonNestedBookmarksToAdd)
        
        // Few bookmarks inside our folder.
        let nestedBookmarksCount = 5
        insertBookmarks(amount: nestedBookmarksCount, parent: folder)
        
        XCTAssertEqual(Bookmark.getChildren(forFolderUUID: folder.syncUUID)?.count, nestedBookmarksCount)
    }
    
    func testGetTopLevelFolders() {
        Bookmark.create(url: nil, title: nil, customTitle: "Folder1", isFolder: true)
        let folder = try! DataController.viewContext.fetch(fetchRequest).first!
        
        insertBookmarks(amount: 3)
        Bookmark.create(url: nil, title: nil, customTitle: "Folder2", isFolder: true)
        
        // Adding some bookmarks and one folder to our nested folder, to check that only top level folders are fetched.
        insertBookmarks(amount: 3, parent: folder)
        Bookmark.create(url: nil, title: nil, customTitle: "Folder3", parentFolder: folder, isFolder: true)
        
        // 3 folders in total, 2 in root directory
        XCTAssertEqual(Bookmark.count(predicate: NSPredicate(format: "isFolder = YES")), 3)
        XCTAssertEqual(Bookmark.getTopLevelFolders().count, 2)
    }
    
    func testGetAllBookmarks() {
        let bookmarksCount = 3
        insertBookmarks(amount: bookmarksCount)
        // Adding a favorite(non-bookmark type of bookmark)
        Bookmark.create(url: URL(string: "http://brave.com"), title: "Brave", isFavorite: true)
        XCTAssertEqual(Bookmark.getAllBookmarks().count, bookmarksCount)
    }
    
    // MARK: - Update
    
    func testUpdateBookmark() {
        let url = "http://brave.com"
        let customTitle = "Brave"
        let newUrl = "http://updated.example.com"
        let newCustomTitle = "Example"
        
        Bookmark.create(url: URL(string: url), title: "title", customTitle: customTitle)
        let object = try! DataController.viewContext.fetch(fetchRequest).first!
        XCTAssertEqual(Bookmark.all()?.count, 1)
        
        XCTAssertEqual(object.displayTitle, customTitle)
        XCTAssertEqual(object.url, url)
        
        object.update(newCustomTitle: newCustomTitle, url: newUrl)
        // Let's make sure not any new record was added to DB
        XCTAssertEqual(Bookmark.all()?.count, 1)
        
        XCTAssertNotEqual(object.displayTitle, customTitle)
        XCTAssertNotEqual(object.url, url)
        
        XCTAssertEqual(object.displayTitle, newCustomTitle)
        XCTAssertEqual(object.url, newUrl)
    }
    
    func testUpdateBookmarkNoChanges() {
        let customTitle = "Brave"
        let url = "http://brave.com"
        
        Bookmark.create(url: URL(string: url), title: "title", customTitle: customTitle)
        let object = try! DataController.viewContext.fetch(fetchRequest).first!
        XCTAssertEqual(Bookmark.all()?.count, 1)
        
        
        object.update(newCustomTitle: customTitle, url: object.url)
        // Let's make sure not any new record was added to DB
        XCTAssertEqual(Bookmark.all()?.count, 1)
        
        XCTAssertEqual(object.customTitle, customTitle)
        XCTAssertEqual(object.url, url)
    }
    
    func testUpdateBookmarkBadUrl() {
        let customTitle = "Brave"
        let url = "http://brave.com"
        let badUrl = "   " // Empty spaces cause URL(string:) to return nil
        
        Bookmark.create(url: URL(string: url), title: "title", customTitle: customTitle)
        let object = try! DataController.viewContext.fetch(fetchRequest).first!
        XCTAssertEqual(Bookmark.all()?.count, 1)
        
        XCTAssertNotNil(object.domain)
        
        object.update(newCustomTitle: customTitle, url: badUrl)
        // Let's make sure not any new record was added to DB
        XCTAssertEqual(Bookmark.all()?.count, 1)
        XCTAssertNil(object.domain)
    }
    
    func testUpdateFolder() {
        let customTitle = "Folder"
        let newCustomTitle = "FolderUpdated"
        
        Bookmark.create(url: nil, title: nil, customTitle: customTitle, isFolder: true)
        let object = try! DataController.viewContext.fetch(fetchRequest).first!
        XCTAssertEqual(Bookmark.all()?.count, 1)
        
        XCTAssertEqual(object.displayTitle, customTitle)
        
        object.update(newCustomTitle: newCustomTitle, url: nil)
        // Let's make sure not any new record was added to DB
        XCTAssertEqual(Bookmark.all()?.count, 1)
        
        XCTAssertEqual(object.displayTitle, newCustomTitle)
    }
    
    func testBookmarkReorderDragDown() {
        let result = reorder(sourcePosition: 0, destinationposition: 5)
        let sourceObject = result.src
        let destinationObject = result.dest
        
        XCTAssertEqual(sourceObject.order, 5)
        XCTAssertEqual(destinationObject.order, 4)
    }
    
    func testBookmarkReorderDragUp() {
        let result = reorder(sourcePosition: 5, destinationposition: 1)
        let sourceObject = result.src
        let destinationObject = result.dest
        
        XCTAssertEqual(sourceObject.order, 1)
        XCTAssertEqual(destinationObject.order, 2)
    }
    
    func testBookmarkReorderTopToBottom() {
        let result = reorder(sourcePosition: 9, destinationposition: 0, skipOrderChangeTests: true)
        let sourceObject = result.src
        let destinationObject = result.dest
        
        XCTAssertEqual(sourceObject.order, 0)
        XCTAssertEqual(destinationObject.order, 1)
    }
    
    func testBookmarkReorderBottomToTop() {
        let result = reorder(sourcePosition: 0, destinationposition: 9)
        let sourceObject = result.src
        let destinationObject = result.dest
        
        XCTAssertEqual(sourceObject.order, 9)
        XCTAssertEqual(destinationObject.order, 8)
    }
    
    func testBookmarksReorderSameIndexPaths() {
        insertBookmarks(amount: 10)
        
        let frc = Bookmark.frc(parentFolder: nil)
        try! frc.performFetch()
        
        let sourceIndexPath = IndexPath(row: 5, section: 0)
        let destinationIndexPath = IndexPath(row: 5, section: 0)
        
        let sourceOrderBefore = frc.object(at: sourceIndexPath).order
        let destinationOrderBefore = frc.object(at: destinationIndexPath).order
        
        Bookmark.reorderBookmarks(frc: frc, sourceIndexPath: sourceIndexPath, destinationIndexPath: destinationIndexPath)
        
        // Test order haven't changed
        XCTAssertEqual(frc.object(at: sourceIndexPath).order, sourceOrderBefore)
        XCTAssertEqual(frc.object(at: destinationIndexPath).order, destinationOrderBefore)
    }
    
    func testBookmarksReorderNilFrc() {
        let sourceIndexPath = IndexPath(row: 0, section: 0)
        let destinationIndexPath = IndexPath(row: 5, section: 0)
        
        Bookmark.reorderBookmarks(frc: nil, sourceIndexPath: sourceIndexPath, destinationIndexPath: destinationIndexPath)
        // Assert nothing.
    }
    
    // MARK: - Delete
    
    func testRemoveByUrl() {
        let url = URL(string: "http://brave.com")!
        let wrongUrl = URL(string: "http://wrong.brave.com")!
        
        Bookmark.create(url: url, title: "Brave")
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 1)
        
        Bookmark.remove(forUrl: wrongUrl)
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 1)
        
        Bookmark.remove(forUrl: url)
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 0)
    }
    
    // MARK: - Syncable
    
    func testAddSyncable() {
        let url = URL(string: "http://brave.com")!
        let title = "Brave"
        
        let site = SyncSite()
        site.title = title
        site.location = url.absoluteString
        
        let bookmark = SyncBookmark()
        bookmark.site = site
        
        let result = Bookmark.add(rootObject: bookmark, save: true, sendToSync: true, 
                                  context: DataController.newBackgroundContext())
        XCTAssertNil(result)
        
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 1)
    }
    
    func testUpdateSyncable() {
        let url = URL(string: "http://brave.com")!
        let title = "Brave"
        
        let newUrl = "http://example.com"
        let newTitle = "BraveUpdated"
        
        let site = SyncSite()
        site.title = newTitle
        site.location = newUrl
        
        let syncBookmark = SyncBookmark()
        syncBookmark.site = site
        
        Bookmark.create(url: url, title: title)
        let object = try! DataController.viewContext.fetch(fetchRequest).first
        
        let oldCreated = object?.created
        let oldLastVisited = object?.lastVisited
        
        XCTAssertNotEqual(object?.title, newTitle)
        XCTAssertNotEqual(object?.url, newUrl)
        
        object?.update(syncRecord: syncBookmark)
        
        XCTAssertEqual(object?.title, newTitle)
        XCTAssertEqual(object?.url, newUrl)
        
        XCTAssertEqual(object?.created, oldCreated)
        XCTAssertNotEqual(object?.lastVisited, oldLastVisited)
    }
    
    func testAsDictionary() {
        let url = URL(string: "http://brave.com")!
        let title = "Brave"
        
        let deviceId = Device.currentDevice()?.deviceId
        
        Bookmark.create(url: url, title: title)
        let object = try! DataController.viewContext.fetch(fetchRequest).first!
        
        let dict = object.asDictionary(deviceId: deviceId, action: 0)
        
        // Just checking if keys exist. More robust tests should be placed in SyncableTests.
        XCTAssertNotNil(dict["objectId"])
        XCTAssertNotNil(dict["bookmark"])
        XCTAssertNotNil(dict["action"])
        XCTAssertNotNil(dict["objectData"])
    }
    
    // MARK: - Helpers
    
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
    
    private func reorder(sourcePosition: Int, destinationposition: Int, 
                         skipOrderChangeTests: Bool = false) -> (src: Bookmark, dest: Bookmark) {
        insertBookmarks(amount: 10)
        
        let frc = Bookmark.frc(parentFolder: nil)
        try! frc.performFetch()
        
        let sourceIndexPath = IndexPath(row: sourcePosition, section: 0)
        let destinationIndexPath = IndexPath(row: destinationposition, section: 0)
        
        let sourceObject = frc.object(at: sourceIndexPath)
        let destinationObject = frc.object(at: destinationIndexPath)
        
        let sourceOrderBefore = frc.object(at: sourceIndexPath).order
        let destinationOrderBefore = frc.object(at: destinationIndexPath).order
        
        // CD objects we saved before will get updated after this call.
        Bookmark.reorderBookmarks(frc: frc, sourceIndexPath: sourceIndexPath, destinationIndexPath: destinationIndexPath)
        
        
        // Test order has changed, won't work when swapping bookmarks with order = 0
        if !skipOrderChangeTests {
            XCTAssertNotEqual(sourceObject.order, sourceOrderBefore)
            XCTAssertNotEqual(destinationObject.order, destinationOrderBefore)
        }
        
        return (sourceObject, destinationObject)
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
