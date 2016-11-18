//
//  MapViewController.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 25/05/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.

//  Brief Description: Controller to handle the initial view (in this case, the interactive map). Users can perform a long-press gesture to add pins to the map, to which photos will be assigned from Flickr. Upon tapping a pin, the Photo View controller is called.

import UIKit
import MapKit
import CoreData

class MapViewController: MasterViewController, MKMapViewDelegate {
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - Variables, Outlets and Constants
    //--------------------------------------------------------------------------------------------------------
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    let firstLoadString = "First Load String"
    var selectedPin:Pin!
    var latestPin:Pin? = nil
    var mapViewDefaults:MapDefaults?
    var deletePinMode = false
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - View Load
    //--------------------------------------------------------------------------------------------------------
    
    // References:
    //  Assistance with NSUserDefaults syntax for bools: http://stackoverflow.com/questions/31070163/need-help-saving-bool-to-nsuserdefaults-and-using-it-in-a-if-statement-using-swi

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add a LongPressGestureRecognizer to add a new Pin
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addPin(_:)))
        longPress.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPress)
        
        //Check to see if this is the first time running the App. No need to attempt to load core data if so.
        if NSUserDefaults.standardUserDefaults().boolForKey("First Load String") == false
        {
            // This was the first time loading the app, so need to record that this first load was successful so that we will attempt to load core data in future app loads
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: firstLoadString)
            print("This is the first load! Will not attempt to load any defaults from core data")
        }
        else
        {
            print("This is not the first load, proceed to load core data")
            loadMapDefaults()
            mapView.addAnnotations(fetchAllPins())
        }
    }
    //--------------------------------------------------------------------------------------------------------
    // MARK: - Fetch Pin Core Data
    //--------------------------------------------------------------------------------------------------------
    
    func fetchAllPins() -> [Pin] {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        var pins:[Pin] = []
        do {
            let results = try sharedContext.executeFetchRequest(fetchRequest)
            pins = results as! [Pin]
        } catch let error as NSError {
            showAlert("Error", message: "Unable to load your data. Details: \(error.localizedDescription)")
        }
        return pins
    }
    //--------------------------------------------------------------------------------------------------------
    // MARK: - Adding, removing and editing Pins
    //---------------------------------------------------------------------------------------------------------
    // References:
    // Gesture Recogniser: https://guides.codepath.com/ios/Using-Gesture-Recognizers
    // Pin drop on long touch reference: http://stackoverflow.com/questions/3959994/how-to-add-a-push-pin-to-a-mkmapviewios-when-touching

    func addPin(gestureRecognizer: UIGestureRecognizer) {
        
        let locationInMap = gestureRecognizer.locationInView(mapView)
        let coord:CLLocationCoordinate2D = mapView.convertPoint(locationInMap, toCoordinateFromView: mapView)
        
        if gestureRecognizer.state == .Began {
            latestPin = Pin(coordinate: coord, context: sharedContext)
            mapView.addAnnotation(latestPin!)
        } else
        if gestureRecognizer.state == .Changed {
            latestPin!.willChangeValueForKey("coordinate")
            latestPin!.coordinate = coord
            latestPin!.didChangeValueForKey("coordinate")
        } else
        if gestureRecognizer.state == .Ended {
            getPhotosForPin(latestPin!) { (success, errorString) in
                self.latestPin!.isDownloading = false
                if success == false {
                    self.showAlert("An error occurred", message: errorString!)
                    return
                }
            }
            CoreDataStackManager.sharedInstance().saveContext()

        }
        else
        {return}
    }
    
    func deletePin(pin: Pin) {
        mapView.removeAnnotation(pin)
        sharedContext.deleteObject(pin)
        CoreDataStackManager.sharedInstance().saveContext()
        print("Pin deleted from core data successfully")
    }
    
    //Pin deletion toggle
    @IBAction func pinDeletion(sender: AnyObject) {
        if deletePinMode == false {
            deletePinMode = true
            deleteButton.title = "Finished"
            print("Pin deletion mode activated")
        } else {
            deletePinMode = false
            deleteButton.title = "Delete Pins"
            print("Pin selection mode activated")
        }
    }
    
    //--------------------------------------------------------------------------------------------------------
    // MARK - load the map default region coordinates & save changes
    //--------------------------------------------------------------------------------------------------------
    struct mapKeys {
        static let centerLatitude = "cLat"
        static let spanLatitude = "sLat"
        static let centerLongitude = "cLong"
        static let spanLongitude = "sLong"
    }
    
    func loadMapDefaults() {
        let fetchRequest = NSFetchRequest(entityName: "MapDefaults")
        var mapDefaults:[MapDefaults] = []
        
        do{
          let results = try! sharedContext.executeFetchRequest(fetchRequest)
            mapDefaults = results as! [MapDefaults] }
          // No need for error handling here as we can be sure it will never fail due to our "is first load" checker in "View Load"
        
        if mapDefaults.count > 0 {
            mapViewDefaults = mapDefaults[0]
            mapView.region = mapViewDefaults!.region
        } else {
            mapViewDefaults = MapDefaults(region: mapView.region, context: sharedContext)
        }
    }

    
    // We need to detect any changes in region to store them
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
        print("Map Region Saved!")
    }
    
    func saveMapRegion() {
        if mapViewDefaults == nil {
            mapViewDefaults = MapDefaults(region: mapView.region, context: sharedContext)
        } else {
            mapViewDefaults!.region = mapView.region
        }
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - View navigation
    //--------------------------------------------------------------------------------------------------------
    
    // Perform a segue to the Photo View Controller, unless delete toggle is on, in which case, delete.
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        let annotation = view.annotation as! Pin
        selectedPin = annotation
        if deletePinMode == false {
            performSegueWithIdentifier("OpenPhotoCollection", sender: self)
            print("Pin selected, loading photo collection view")
        } else {
            let alert = UIAlertController(title: "Delete Pin", message: "Are you sure? This cannot be undone.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
            alert.addAction(UIAlertAction(title: "Do it!", style: .Default, handler: { (action: UIAlertAction) in
                //Execute the function to remove the pin data from core data
                self.deletePin(annotation)
                //Nullify the pin from the map
                self.selectedPin = nil
                print("Pin annotation removed from Map View")
            }))
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "OpenPhotoCollection" {
            mapView.deselectAnnotation(selectedPin, animated: false)
            let controller = segue.destinationViewController as! PhotoViewController
            controller.pin = selectedPin
        }
    }
}