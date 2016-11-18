//
//  MapDefaults.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 11/07/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
//
// Map Region/Span/Zoom assist http://stackoverflow.com/questions/28289230/mapkit-default-zoom


import Foundation
import CoreData
import MapKit

//Reference the Region (Map Defaults) object from the data model
@objc(MapDefaults)

class MapDefaults: NSManagedObject {
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - Variables, Outlets and Constants
    //--------------------------------------------------------------------------------------------------------
    
    @NSManaged var cLat: Double
    @NSManaged var cLong: Double
    @NSManaged var sLat: Double
    @NSManaged var sLong: Double
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - Map Region Defaults - Core Data
    //--------------------------------------------------------------------------------------------------------
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(region: MKCoordinateRegion, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("MapDefaults", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.region = region
    }
    
    var region: MKCoordinateRegion {
        set {
            cLat = newValue.center.latitude
            cLong = newValue.center.longitude
            sLat = newValue.span.latitudeDelta
            sLong = newValue.span.longitudeDelta
        }
        get {
            let center = CLLocationCoordinate2DMake(cLat, cLong); print("Got coordinates from core data!")
            let span = MKCoordinateSpanMake(sLat, sLong); print("Got spans from core data!")
            return MKCoordinateRegionMake(center, span)
        }
    }
}