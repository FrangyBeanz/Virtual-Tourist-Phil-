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

class Photo : NSManagedObject {
    
    struct Keys {
        static let filePath = "filePath"
        static let urlPath = "urlPath"
    }
    
    @NSManaged var pin : Pin?
    @NSManaged var filePath : String
    @NSManaged var urlPath : String
    var status: FlickrClient.Download.Status = .Idle
    
    lazy var sharedContext : NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        if let image = Cache.sharedInstance().imageForIdentifier(filePath) {
            status = .Done
        }
    }
    
    init(dictionary : [String : AnyObject], context : NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
        
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        filePath = dictionary[Photo.Keys.filePath] as! String
        urlPath = dictionary[Photo.Keys.urlPath] as! String
    }
    
    func deleteImage() {
        Cache.sharedInstance().deleteImage(filePath)
        managedObjectContext?.deleteObject(self)
        
        let error : NSErrorPointer = NSErrorPointer()
        do {
            try managedObjectContext?.save()
        } catch let error1 as NSError {
            error.memory = error1
        }
        if error != nil {
            print("Could not delete the photo for path \(filePath) due to \(error)")
        }
    }
    
    /**
     MARK: As soon as the image is saved, a notification is posted to the
     default notification center with the identifier: Flickr.Notifications.
     PhotosLoaded.
     **/
    func saveImage(image: UIImage) {
        Cache.sharedInstance().saveImage(image, identifier: filePath)
        status = .Done
        print("image \(image) saved!")
        let notification = NSNotification(name: FlickrClient.Notifications.PhotoLoaded, object: self)
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
}
