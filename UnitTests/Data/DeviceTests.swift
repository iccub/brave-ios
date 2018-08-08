// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CoreData
@testable import Data

class DeviceTests: CoreDataTestCase {
    
    let fetchRequest = NSFetchRequest<Bookmark>(entityName: String(describing: Bookmark.self))
    
    private func entity(for context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: String(describing: Bookmark.self), in: context)!
    }
    
    func testCurrentDevice() {
        let device = Device.currentDevice()
        let newDevice = Device.currentDevice()
        
        XCTAssertEqual(try! DataController.viewContext.fetch(fetchRequest).count, 1)
        
        XCTAssertEqual(device, newDevice)
        
    }

    func testDeleteAll() {
        // TODO: Finish it
        
    }

}
