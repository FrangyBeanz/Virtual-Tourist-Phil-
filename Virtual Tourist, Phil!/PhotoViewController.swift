//
//  PhotoViewController.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 26/07/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class PhotoViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate
{
    @IBOutlet var MapView: MKMapView!
    @IBOutlet var PhotoCollection: UICollectionView!
    
    var pin: Pin?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Add the selected Pin to the Map, but check we got it first!
        if pin == nil {
            print("Failing Gracefully - for some reason I don't have a Pin")
        } else {
        MapView.addAnnotation(pin!)
        MapView.setCenterCoordinate(pin!.coordinate, animated: true)
            
        //Ensure we zoom in on the Pin that was selected
        let span = MKCoordinateSpanMake(0.075, 0.075)
        let region = MKCoordinateRegion(center: pin!.coordinate, span: span)
        MapView.setRegion(region, animated: true)
        }
        
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}