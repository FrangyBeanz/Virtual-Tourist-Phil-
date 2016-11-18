//
//  Photo.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 09/09/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(Photo)

class Photo: NSManagedObject {
    
    @NSManaged var photoURL: String
    @NSManaged var imagePath: String?
    @NSManaged var pin: Pin
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(photoURL: String, pin: Pin, context: NSManagedObjectContext) {
        
        //Core Data
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.photoURL = photoURL
        self.pin = pin
    }
    
    var image: UIImage? {
        if imagePath != nil {
            let fileURL = getFileURL()
            return UIImage(contentsOfFile: fileURL.path!)
        }
        return nil
    }
    
    func getFileURL() -> NSURL {
        let fileName = (imagePath! as NSString).lastPathComponent
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let pathArray:[String] = [dirPath, fileName]
        let fileURL = NSURL.fileURLWithPathComponents(pathArray)
        return fileURL!
    }
    
    // Remove the data from the core data database when a pin is actually deleted so that we don;t just remove it from the view
    override func prepareForDeletion() {
        if (imagePath == nil) {
            return
        }
        let fileURL = getFileURL()
        if NSFileManager.defaultManager().fileExistsAtPath(fileURL.path!) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(fileURL.path!)
            } catch let error as NSError {
                print(error.userInfo) // fail silent
            }
        }
    }
}