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

class MapViewController: UIViewController, MKMapViewDelegate {

    var location: CLLocation!
    var LongPress = UILongPressGestureRecognizer.self
    @IBOutlet var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.mapView.delegate = self
        
        //Load the long press recogniser when the page loads
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.handleLongPress(_:)))
            longPressRecogniser.minimumPressDuration = 1.5 //user must hold the press for 1.5 seconds for the pin to drop
            mapView.addGestureRecognizer(longPressRecogniser)
    }
    
    func handleLongPress(getstureRecognizer : UIGestureRecognizer){
        if getstureRecognizer.state != .Began { return }
        
        let touchPoint = getstureRecognizer.locationInView(self.mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        let annotation = MKPointAnnotation()
        
        //TODO - Animate the Pin Drop

        // Add the Pin to the map
        annotation.coordinate = touchMapCoordinate
        mapView.addAnnotation(annotation)
        print("I'm in handleLong")
    }
   
    /*
    func PinOptions(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        print("I see your function, but i choose to ignore it!")
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.animatesDrop = true
            pinView!.pinTintColor = UIColor.orangeColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    */

    //TODO Drop pin
       //Adding annotations
    
    //TODO Save the Pins location in NS User Defaults
    
    //TODO when a pin is dropped, call the Flickr API and pass photos from API into a new view
    
    //TODO photos should be selectable and removable
    
    //User changes to selected photos should be loaded into Core Data
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

