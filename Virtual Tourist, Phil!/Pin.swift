//
//  Pin.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 08/06/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
//

import Foundation
import MapKit
import CoreData

//Reference the object from the data model
@objc(Pin)

class Pin : NSManagedObject, MKAnnotation {
    
    //Create a struct to host the Location Keys
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
    }
    
    //The "Magical" Variables!
    @NSManaged var pin : Pin?
    @NSManaged var latitude : NSNumber
    @NSManaged var longitude : NSNumber
    @NSManaged var page : Int

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    //Create the Location Dictionary
    init(dictionary : [String : AnyObject], context : NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        latitude = dictionary[Pin.Keys.Latitude] as! Double
        longitude = dictionary[Pin.Keys.Longitude] as! Double
        //page = 1
    }
    
    //Grab the managed object context leveraged from the Favorite Actors class
    lazy var sharedContext : NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    //Grab the coordinates of the pin
    var coordinate:CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude as Double, longitude: longitude as Double)
        }
    }
}

