//
//  MapViewController.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 25/05/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet var MapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Get the stack
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
    }

    //TODO Drop pin
    
    //TODO Save the Pins location in NS User Defaults
    
    //TODO when a pin is dropped, call the Flickr API and pass photos from API into a new view
    
    //TODO photos should be selectable and removable
    
    //User changes to selected photos should be loaded into Core Data
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

