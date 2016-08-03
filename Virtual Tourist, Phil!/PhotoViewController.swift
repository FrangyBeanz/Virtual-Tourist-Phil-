//
//  PhotoViewController.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 26/07/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
//
// Map Region/Span/Zoom assist http://stackoverflow.com/questions/28289230/mapkit-default-zoom

import Foundation
import MapKit
import CoreData

class PhotoViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate
{
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var PhotoCollection: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    var pin: Pin?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Add the selected Pin to the Map, but check we got it first!
        if pin == nil {
            print("Failing Gracefully - for some reason I don't have a Pin")
        } else {
        mapView.addAnnotation(pin!)
        mapView.setCenterCoordinate(pin!.coordinate, animated: true)
            
        //Ensure we zoom in on the Pin that was selected
        let span = MKCoordinateSpanMake(0.075, 0.075)
        let region = MKCoordinateRegion(center: pin!.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        mapView.delegate = self
            
            }
    }
    
    override func viewWillAppear(animated: Bool) {
        newCollectionButton.enabled = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // The following code is leveraged from my "On The Map, Phil!" Project. It determines how pins will be renered on the map. "Make it pretty!"
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
            pinView!.animatesDrop = true
            pinView!.pinTintColor = UIColor.orangeColor()
        }
        return pinView!
    }

}