//
//  PhotoViewController.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 26/07/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
//
//  Brief Description: Controller to handle the Photo Collection view which is presented when a user selects a pin from the Map View. Fetches photos collected for that location and presents them in a collection view. Allows the user to also load a new collection, replacing the initially downloaded photo set. Also allows users to remove items from the saved photo collection by selecting the desired photo. 
//  Page Enhancement idea: Have a toggle to allow the user to view the photo in full-screen mode when pressed rather than just the option to delete.



import Foundation
import MapKit
import CoreData

class PhotoViewController: MasterViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, MKMapViewDelegate {
    
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - Variables, Outlets and Constants
    //--------------------------------------------------------------------------------------------------------
    
    //Storyboard References
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    var pin:Pin!
    var allPhotosLoaded = false
    var noPhotosLoaded = true

    // store updated indexes
    var selectedIndexes   = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths : [NSIndexPath]!
    var updatedIndexPaths : [NSIndexPath]!
    
    //Core Data
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - Dynamic Button Labels
    //--------------------------------------------------------------------------------------------------------
    
    override func viewWillAppear(animated: Bool) {
        
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
        collectionView.hidden = false
    }
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - View Load
    //--------------------------------------------------------------------------------------------------------
    //References:
    // Map Region/Span/Zoom assist http://stackoverflow.com/questions/28289230/mapkit-default-zoom
    
    override func viewDidLoad() {
        //Add the selected Pin to the Map, but check we got it first!
        if pin == nil {
            print("for some reason I don't have a Pin!!")
        } else {
        mapView.addAnnotation(pin)
        mapView.setCenterCoordinate(pin.coordinate, animated: true)
        
        var error: NSError?
        do {
            try fetchedResultsController.performFetch()
        } catch let error1 as NSError {
            error = error1
            print(error)
        }
        
        if error != nil  || fetchedResultsController.fetchedObjects?.count == 0 {
            // fail gracfully - download new collection
            loadNewCollectionSet()
        }
        
        //disable new collection button if we are already downloading
        if pin.isDownloading {
            noPhotosLoaded = true
            allPhotosLoaded = false
        } else{
            noPhotosLoaded = false
            allPhotosLoaded = true
            }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PhotoViewController.pinFinishedDownload), name: pinFinishedDownloadingNotification, object: nil)
        }
    }

    //--------------------------------------------------------------------------------------------------------
    // MARK: - Loading the Photo Collection
    //--------------------------------------------------------------------------------------------------------

    func loadNewCollectionSet() {
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            sharedContext.deleteObject(photo)
        }
        CoreDataStackManager.sharedInstance().saveContext()
        
        self.newCollectionButton.enabled = false
        print(pin.photos.count)
        
        getPhotosForPin(pin) { (success, errorString) in
            self.pinFinishedDownload()
            if success == false {
                self.showAlert("No photos available at this location", message: errorString!)
                return
            }
        }
    }
    
    func pinFinishedDownload() {
        //return a null value until the pin has finished downloading
        if pin.isDownloading == true {
            return
        }
        self.newCollectionButton.enabled = true
        
        if let objects = self.fetchedResultsController.fetchedObjects {
            if objects.count == 0 {
                self.collectionView.hidden = true
                self.newCollectionButton.enabled = false
            }
        }
    }
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - Presenting the Loaded Photo Collection
    //--------------------------------------------------------------------------------------------------------
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if photo.imagePath != nil {
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.hidden = true
            cell.photoImageView.image = photo.image
        }else{
            cell.activityIndicator.startAnimating()
        }
        
        return cell
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }
        
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        let alert = UIAlertController(title: "Delete Photo", message: "Do you want to remove this photo?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { (action: UIAlertAction) in
            collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction) in
            collectionView.deselectItemAtIndexPath(indexPath, animated: true)
            self.sharedContext.deleteObject(photo)
            CoreDataStackManager.sharedInstance().saveContext()
        }))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - Fetching new Photo Collection & Presenting
    //--------------------------------------------------------------------------------------------------------

    @IBAction func newCollectionButtonTouch(sender: AnyObject) {
        loadNewCollectionSet()
    }

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths  = [NSIndexPath]()
        updatedIndexPaths  = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
        case .Update:
            updatedIndexPaths.append(indexPath!)
        case .Delete:
            deletedIndexPaths.append(indexPath!)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView.performBatchUpdates({
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            }, completion: nil)
    }
}