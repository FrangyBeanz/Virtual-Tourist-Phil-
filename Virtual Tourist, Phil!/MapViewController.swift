//
//  MapViewController.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 25/05/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
// Pin drop on long touch reference: http://stackoverflow.com/questions/3959994/how-to-add-a-push-pin-to-a-mkmapviewios-when-touching
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    var location: CLLocation!
    var LongPress = UILongPressGestureRecognizer.self
    let locationManager = CLLocationManager()
    var firstLoad = true

    @IBOutlet var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.mapView.delegate = self
        
        //Check for previous user saved pin locations, if found display them on the map at launch. If not, do nothing.
        firstLoad = NSUserDefaults.standardUserDefaults().boolForKey("firstLoad")
        print(firstLoad)
        
        // if let latitudeload = NSUserDefaults.standardUserDefaults().doubleForKey("locationDataLat")
        
      /*  {
            let loadedLocation = location as? CLLocation {
                print(loadedLocation.coordinate.latitude)
                print(loadedLocation.coordinate.longitude)
                let location = CLLocationCoordinate2D(
                    latitude: loadedLocation.coordinate.latitude,
                    longitude: loadedLocation.coordinate.longitude
                )
                let annotation = MKPointAnnotation()
                annotation.coordinate = location
                self.mapView.addAnnotation(annotation)

            }
        }*/
        
        //Load the long press recogniser when the page loads
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.handleLongPress(_:)))
            longPressRecogniser.minimumPressDuration = 1.5 //user must hold the press for 1.5 seconds for the pin to drop
            mapView.addGestureRecognizer(longPressRecogniser)
    }
    
    //Detect a long press and add a pin to the map
    func handleLongPress(getstureRecognizer : UIGestureRecognizer){
        if getstureRecognizer.state != .Began { return }
        
        let touchPoint = getstureRecognizer.locationInView(self.mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        let annotation = MKPointAnnotation()
        
        //TODO - Animate the Pin Drop

        // Add the Pin to the map
        annotation.coordinate = touchMapCoordinate
        mapView.addAnnotation(annotation);
        print("I'm in handleLong")
        
        // Save the pin location
        let location = CLLocationCoordinate2D(
            latitude: annotation.coordinate.latitude,
            longitude: annotation.coordinate.longitude
        )

        //let location = NSValue(MKCoordinate: touchMapCoordinate)
        //let locationData = NSKeyedArchiver.archivedDataWithRootObject(location)
       // NSUserDefaults.standardUserDefaults().setFloat(sliderView.value, forKey: SliderValueKey)
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "firstLoad")
        NSUserDefaults.standardUserDefaults().setDouble(Double(location.latitude), forKey: "locationDataLat");
        NSUserDefaults.standardUserDefaults().setDouble(Double(location.longitude), forKey: "locationDataLong");
        
        print(annotation.coordinate.latitude);
        print(annotation.coordinate.longitude)
    }
   

    //TODO Save the Pins location in NS User Defaults
    
    //TODO when a pin is dropped, call the Flickr API and pass photos from API into a new view
    
    //TODO photos should be selectable and removable
    
    //User changes to selected photos should be loaded into Core Data
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

