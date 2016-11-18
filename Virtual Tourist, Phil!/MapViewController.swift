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
    @IBOutlet weak var editButton: UIBarButtonItem!
    let firstLoadString = "First Load String"
    var selectedPin:Pin!
    var lastAddedPin:Pin? = nil
    var editPinMode = false
    var mapViewRegion:MapDefaults?
    
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
            loadMapRegion()
            mapView.addAnnotations(fetchAllPins())
        }
    }
    //--------------------------------------------------------------------------------------------------------
    // MARK: - Core Data implementation
    //--------------------------------------------------------------------------------------------------------
    
    func fetchAllPins() -> [Pin] {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        var pins:[Pin] = []
        do {
            let results = try sharedContext.executeFetchRequest(fetchRequest)
            pins = results as! [Pin]
        } catch let error as NSError {
            showAlert("Uh-oh", message: "Something went wrong when trying to load existing data")
            print("An error occured accessing managed object context \(error.localizedDescription)")
        }
        return pins
    }
    //--------------------------------------------------------------------------------------------------------
    // MARK: - Adding, removing and editing Pins
    //---------------------------------------------------------------------------------------------------------
    
    // References:
    // Pin drop on long touch reference: http://stackoverflow.com/questions/3959994/how-to-add-a-push-pin-to-a-mkmapviewios-when-touching

    func addPin(gestureRecognizer: UIGestureRecognizer) {
        
        let locationInMap = gestureRecognizer.locationInView(mapView)
        let coord:CLLocationCoordinate2D = mapView.convertPoint(locationInMap, toCoordinateFromView: mapView)
        
        switch gestureRecognizer.state {
        case UIGestureRecognizerState.Began:
            lastAddedPin = Pin(coordinate: coord, context: sharedContext)
            mapView.addAnnotation(lastAddedPin!)
        case UIGestureRecognizerState.Changed:
            lastAddedPin!.willChangeValueForKey("coordinate")
            lastAddedPin!.coordinate = coord
            lastAddedPin!.didChangeValueForKey("coordinate")
        case UIGestureRecognizerState.Ended:
            getPhotosForPin(lastAddedPin!) { (success, errorString) in
                self.lastAddedPin!.isDownloading = false
                if success == false {
                    self.showAlert("An error occurred", message: errorString!)
                    return
                }
            }
            CoreDataStackManager.sharedInstance().saveContext()
        default:
            return
        }
    }
    
    func deletePin(pin: Pin) {
        mapView.removeAnnotation(pin)
        sharedContext.deleteObject(pin)
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    //Editing toggle
    @IBAction func pinEditAction(sender: AnyObject) {
        if editPinMode == false {
            editPinMode = true
            editButton.title = "Finished"
            print("Pin deletion mode activated")
        } else {
            editPinMode = false
            editButton.title = "Delete Pins"
            print("Pin selection mode activated")
        }
    }
    
    //--------------------------------------------------------------------------------------------------------
    // MARK - save and load map region
    //--------------------------------------------------------------------------------------------------------

    struct mapKeys {
        static let centerLatitude = "cLat"
        static let centerLongitude = "cLong"
        static let spanLatitude = "sLat"
        static let spanLongitude = "sLong"
    }
    
    // We need to detect any changes in region to store them
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("Saving Map Coordinates")
        saveMapRegion()
    }
    
    func saveMapRegion() {
        if mapViewRegion == nil {
            mapViewRegion = MapDefaults(region: mapView.region, context: sharedContext)
        } else {
            mapViewRegion!.region = mapView.region
        }
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func loadMapRegion() {
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
            mapViewRegion = regions[0]
            mapView.region = mapViewRegion!.region
        } else {
            mapViewRegion = MapDefaults(region: mapView.region, context: sharedContext)
        }
    }
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - Navigation
    //--------------------------------------------------------------------------------------------------------
    
    // Perform a segue to the Photo View Controller, unless delete toggle is on, in which case, delete.
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        print("Pin selected")
        let annotation = view.annotation as! Pin
        selectedPin = annotation
        if editPinMode == false {
            performSegueWithIdentifier("OpenPhotoCollection", sender: self)
        } else {
            let alert = UIAlertController(title: "Delete Pin", message: "Do you want to remove this pin?", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
            
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction) in
                self.selectedPin = nil
                self.deletePin(annotation)
            }))
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "OpenPhotoCollection" {
            mapView.deselectAnnotation(selectedPin, animated: false)
            let controller = segue.destinationViewController as! PhotoViewController
            controller.pin = selectedPin
        }
    }
}