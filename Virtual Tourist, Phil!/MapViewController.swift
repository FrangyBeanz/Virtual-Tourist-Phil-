//
//  MapViewController.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 25/05/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.

//Brief Description: Controller to handle the initial view (in this case, the interactive map). Users can perform a long-press gesture to add pins to the map, to which photos will be assigned from Flickr. Upon tapping a pin, the Photo View controller is called. 

// Pin drop on long touch reference: http://stackoverflow.com/questions/3959994/how-to-add-a-push-pin-to-a-mkmapviewios-when-touching
// Assistance with NSUserDefaults syntax for bools: http://stackoverflow.com/questions/31070163/need-help-saving-bool-to-nsuserdefaults-and-using-it-in-a-if-statement-using-swi
//


import UIKit
import MapKit
import CoreData

class MapViewController: MasterViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var selectedPin:Pin!
    var lastAddedPin:Pin? = nil
    var editPinMode = false
    var mapViewRegion:MapDefaults?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add a LongPressGestureRecognizer to add a new Pin
        let longPress = UILongPressGestureRecognizer(target: self, action: "addPin:")
        longPress.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPress)
        
        loadMapRegion()
        mapView.addAnnotations(fetchAllPins())
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
    
    // MARK: - Core Data implementation
    
    func fetchAllPins() -> [Pin] {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        var pins:[Pin] = []
        do {
            let results = try sharedContext.executeFetchRequest(fetchRequest)
            pins = results as! [Pin]
        } catch let error as NSError {
            showAlert("Ooops", message: "Something went wrong when trying to load existing data")
            print("An error occured accessing managed object context \(error.localizedDescription)")
        }
        return pins
    }
    
    
    // MARK: - Adding, removing and editing Pins
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
        } else {
            editPinMode = false
            editButton.title = "Delete Pins"
        }
    }
    
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
    
    // We need to detect any changes in region to store them
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("Saving Map Coordinates")
        saveMapRegion()
    }
    
    
    // MARK - save and load map region
    struct mapKeys {
        static let centerLatitude = "cLat"
        static let centerLongitude = "cLong"
        static let spanLatitude = "sLat"
        static let spanLongitude = "sLong"
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
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "OpenPhotoCollection" {
            mapView.deselectAnnotation(selectedPin, animated: false)
            let controller = segue.destinationViewController as! PhotoViewController
            controller.pin = selectedPin
        }
    }
    
}














/*

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    var location: CLLocation!
    var LongPress = UILongPressGestureRecognizer.self
    var editPinMode = false
    let locationManager = CLLocationManager()
    let firstLoadString = "First Load String"
    var longPressGestureRecognizerToAdd : UILongPressGestureRecognizer!
    
    //Vars to capture context of pin add and pass to photo view controller
    var pressedPin:Pin!
    var mapViewDefaults:MapDefaults?
    
    //non-volatile vars
    @NSManaged var latitude : NSNumber
    @NSManaged var longitude : NSNumber
    @NSManaged var page : Int

    //Grab the managed object context leveraged from the Favorite Actors class
    lazy var sharedContext : NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet var mapView: MKMapView!
    
    //Editing toggle
    @IBAction func pinEditAction(sender: AnyObject) {
        if editPinMode == false {
            editPinMode = true
            editButton.title = "Finished Editing"
        } else {
            editPinMode = false
            editButton.title = "Edit"
        }
    }
    
    //Fetch the Pins we got from Core Data
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

    override func viewDidAppear(animated: Bool) {
        //always ensure that editing mode is off when this view appears (not sure this is really needed, but i somehow managed to get it stuck in edit mode once, might remove it later)
        editPinMode = false
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
            
        // Open up the photo collection view
            pressedPin = pin
            loadPhotosView()
        }
    }
    
    //When pressing an existing pin, need to also route it to the photo collection.
   func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        let annotation = view.annotation as! Pin
        pressedPin = annotation
        print("A Pin was Pressed!")
        if editPinMode == false {
            performSegueWithIdentifier("OpenPhotoCollection", sender: self)
        } else {
            //Present a confirmation to the user
            let alert = UIAlertController(title: "Delete Pin", message: "Are you sure?", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "On second thought...", style: .Default, handler: nil))
            alert.addAction(UIAlertAction(title: "Do it!", style: .Default, handler: { (action: UIAlertAction) in
                
            //nullify the pressed pin from the view and call the function to ensure it is removed from core data
                self.pressedPin = nil
                self.pinDestruction(annotation)
            }))
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    //If a pin was deleted, make sure we properly delete it from Core Data
    func pinDestruction(pin: Pin) {
        mapView.removeAnnotation(pin)
        sharedContext.deleteObject(pin)
        CoreDataStackManager.sharedInstance().saveContext()
        print("A Pin has fallen in battle!")
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
            print("")
        } else {
            mapViewDefaults!.region = mapView.region
        }
        CoreDataStackManager.sharedInstance().saveContext()
        print("New user default map region has been saved!")
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
            print("Using default rather than last known user location")
        } else {
            mapViewDefaults = MapDefaults(region: mapView.region, context: sharedContext)
            print("Last known user region has been applied to the map")
       }
    }
    
    
    //TODO when a pin is dropped, call the Flickr API and pass photos from API into a new view
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "OpenPhotoCollection") {
            mapView.deselectAnnotation(pressedPin, animated: false)
            let Controller = segue.destinationViewController as! PhotoViewController
            Controller.pin = pressedPin
            let backItem = UIBarButtonItem()
            backItem.title = "Back"
            navigationItem.backBarButtonItem = backItem

        }
    }
    
    func loadPhotosView(){
        performSegueWithIdentifier("OpenPhotoCollection", sender: self)
        }
    
    //TODO photos should be selectable and removable
    
    //User changes to selected photos should be loaded into Core Data
    

}
 */

