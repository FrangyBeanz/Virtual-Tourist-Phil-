//
//  MapViewController.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 25/05/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
// Pin drop on long touch reference: http://stackoverflow.com/questions/3959994/how-to-add-a-push-pin-to-a-mkmapviewios-when-touching
// Assistance with NSUserDefaults syntax for bools: http://stackoverflow.com/questions/31070163/need-help-saving-bool-to-nsuserdefaults-and-using-it-in-a-if-statement-using-swi
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    var location: CLLocation!
    var LongPress = UILongPressGestureRecognizer.self
    let locationManager = CLLocationManager()
    let firstLoadString = "First Load String"
    var longPressGestureRecognizerToAdd : UILongPressGestureRecognizer!
    var mapViewDefaults:MapDefaults?
    @NSManaged var latitude : NSNumber
    @NSManaged var longitude : NSNumber
    @NSManaged var page : Int

    //Grab the managed object context leveraged from the Favorite Actors class
    lazy var sharedContext : NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    @IBOutlet var mapView: MKMapView!
    
    
    func Pins() -> [Pin] {
        let error: NSErrorPointer = nil
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        let results: [AnyObject]?
        do {
            results = try sharedContext.executeFetchRequest(fetchRequest)
        } catch let error1 as NSError {
            error.memory = error1
            results = nil
        }
        if error != nil {
            print("Could not execute fetch request due to: \(error)")
        }
        return results as! [Pin]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.mapView.delegate = self
        
        //Was this the first time loading the App? If so, no need to load from core data.
        
        if NSUserDefaults.standardUserDefaults().boolForKey("First Load String") == false
        {
            // This was indeed the first time loading the app, need to record that this first load was successful so that we will attempt to load core data in future app loads
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: firstLoadString)
            print("This is the first load! Will not attempt to load any defaults from core data")
        }
        else
        {
            //If this was not the first time loading the app, the user is likely to have saved some data we need to retrieve
            print("This is not the first load, continue to load defaults from core data")

            // Load the last saved location on the map
            loadMapDefaults()
            
            //Check for previous user saved pin locations, if found display them on the map at launch. If not, do nothing.
            let pins = Pins()
            if pins.isEmpty {
                return
            } else {
                mapView.addAnnotations(pins)
            }
        }
        
        //Load the long press recogniser when the page loads
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.handleLongPress(_:)))
            longPressRecogniser.minimumPressDuration = 0.5 //user must hold the press for 1.5 seconds for the pin to drop
            mapView.addGestureRecognizer(longPressRecogniser)
    
    }
    
    //Function to recognise the long press gesture
    func setGestureRecognizers() {
        gestureRecognizerTo()
        longPressGestureRecognizerToAdd.enabled = true
    }
    func gestureRecognizerTo() {
        longPressGestureRecognizerToAdd = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.handleLongPress(_:)))
        longPressGestureRecognizerToAdd.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressGestureRecognizerToAdd)
    }
    
    //Detect a long press and add a pin to the map
    func handleLongPress(getstureRecognizer : UIGestureRecognizer){
      
        let touchPoint = getstureRecognizer.locationInView(self.mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)

        // Save the pin location to non-volatile memory (core data) so it can be recalled after app close
          if getstureRecognizer.state == UIGestureRecognizerState.Ended {
            let dictionary = ["latitude": touchMapCoordinate.latitude, "longitude": touchMapCoordinate.longitude]
            let pin = Pin(dictionary: dictionary, context: sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()
            print("Location saved to dictionary!")
            
        // Add the new Pin to the map view
            mapView.addAnnotation(pin)
            print("Location added to the map!")
        }

    }
    
    // The following code is leveraged from my "On The Map, Phil!" Project. It determines how pins will be renered on the map.
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "Pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.animatesDrop = true
            pinView!.pinTintColor = UIColor.orangeColor()
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView!
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // We need to detect any changes in region to store them
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
         saveMapDefaults()
         print("New user default map region has been saved!")
    }
    
    
    // define the struct to save coordinates and map to the database entity
    struct mapKeys {
        static let cLat = "CenterLatitudeKey"
        static let cLong = "CenterLongitude"
        static let sLat = "SpanLatitudeDeltaKey"
        static let sLong = "SpanLongitudeDeltaKey"
    }
    
    //Store the map region in core data
    func saveMapDefaults() {
        if mapViewDefaults == nil {
            mapViewDefaults = MapDefaults(region: mapView.region, context: sharedContext)
        } else {
            mapViewDefaults!.region = mapView.region
        }
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    //function to allow loading of the map region that was saved during the last app session in core data. Called on view load.
    func loadMapDefaults() {
        let fetchRequest = NSFetchRequest(entityName: "MapDefaults")
        var regions:[MapDefaults] = []
        do {
            let results = try sharedContext.executeFetchRequest(fetchRequest)
            regions = results as! [MapDefaults]
        } catch let error as NSError {
            // only map region failed, so failing silent
            print("An error occured accessing managed object context \(error.localizedDescription)")
        }
        if regions.count > 0 {
            mapViewDefaults = regions[0]
            mapView.region = mapViewDefaults!.region
        } else {
            mapViewDefaults = MapDefaults(region: mapView.region, context: sharedContext)
        }
    }
    
    
    //TODO when a pin is dropped, call the Flickr API and pass photos from API into a new view
    
    //TODO photos should be selectable and removable
    
    //User changes to selected photos should be loaded into Core Data
    

}

