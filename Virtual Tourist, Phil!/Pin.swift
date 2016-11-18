//
//  Pin.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 08/06/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
//

import UIKit
import MapKit
import CoreData

//Reference the Pin object from the data model
@objc(Pin)

class Pin: NSManagedObject, MKAnnotation {
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - Variables, Outlets and Constants
    //--------------------------------------------------------------------------------------------------------
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var numPages: NSNumber?
    @NSManaged var photos:[Photo]
    var isDownloading = false
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - Pin Coordinates - Core Data
    //--------------------------------------------------------------------------------------------------------

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2DMake(latitude, longitude)
        }
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
    }
}