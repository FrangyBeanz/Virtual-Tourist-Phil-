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

class PhotoViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate
{
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var PhotoCollection: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    var pin: Pin?
    var allPhotosLoaded = false
    var noPhotosLoaded = true
    
    lazy var fetchedResultsController : NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "urlPath", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }()
    
    lazy var sharedContext : NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        //Add the selected Pin to the Map, but check we got it first!
        if pin == nil {
            print("for some reason I don't have a Pin!!")
        } else {
        mapView.delegate = self
        mapView.addAnnotation(pin!)
        mapView.setCenterCoordinate(pin!.coordinate, animated: true)
            
        //Ensure we zoom in on the Pin that was selected
        let span = MKCoordinateSpanMake(0.075, 0.075)
        let region = MKCoordinateRegion(center: pin!.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        mapView.userInteractionEnabled = false

            }
    }
    
    override func viewWillAppear(animated: Bool) {
        //Disable the new collection Button until after everything has loaded
        newCollectionButton.enabled = false
        
        //Change the text of the new collection button to show "Loading" while photos are loading
        newCollectionButton.enabled = false
        dispatch_async(dispatch_get_main_queue()) {
            self.newCollectionButton.title = "Loading..."
        }
        
        if noPhotosLoaded {
            dispatch_async(dispatch_get_main_queue()) {
                self.newCollectionButton.title = "No Photos Found"
                self.newCollectionButton.enabled = false
            }
        } else if allPhotosLoaded {
            dispatch_async(dispatch_get_main_queue()) {
                self.newCollectionButton.title = "New Collection"
                self.newCollectionButton.enabled = true
            }
        }
        
    }
    
    // Load the collection view
    func PhotoCollection(PhotoCollection: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = PhotoCollection.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        cell.photoImageView.image = UIImage(named: "Picture-100")
        cell.activityIndicator.startAnimating()
        
        if let image = Cache.sharedInstance().imageForIdentifier(photo.filePath) {
            cell.activityIndicator.stopAnimating()
            cell.photoImageView.image = image
        } else if photo.status == .Idle {
            configureCell(cell, photo: photo)
        }
        
        return cell
    }
    
    func configureCell(cell: PhotoCollectionViewCell, photo: Photo) {
        let task = Cache.sharedInstance().downloadImage(photo.filePath) { imageData, error in
            if imageData != nil {
                let image = UIImage(data: imageData!)
                photo.saveImage(image!)
                cell.photoImageView.image = image
                cell.activityIndicator.stopAnimating()
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    print("error downloading image \(error)")
                    photo.deleteImage()
                }
            }
        }
        cell.urlTask = task
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // The following code is leveraged from my "On The Map, Phil!" Project. It determines how pins will be renered on the map. "Make it pretty!"
     func mapView (mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "Pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = UIColor.orangeColor()
        }
        else {
            pinView!.annotation = annotation
            pinView!.pinTintColor = UIColor.orangeColor()
        }
        return pinView
    }

}