//
//  MapDefaults.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 11/07/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class MapDefaults: NSManagedObject {
    
    @NSManaged var cLat: Double
    @NSManaged var cLong: Double
    @NSManaged var sLat: Double
    @NSManaged var sLong: Double
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(region: MKCoordinateRegion, context: NSManagedObjectContext) {
        
        //Core Data
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
            let center = CLLocationCoordinate2DMake(cLat, cLong); print("Got coordinates")
            let span = MKCoordinateSpanMake(sLat, sLong); print("Got Spans")
            return MKCoordinateRegionMake(center, span)
        }
    }
}
