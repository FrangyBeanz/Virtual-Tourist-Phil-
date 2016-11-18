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



class PhotoViewController: MasterViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, MKMapViewDelegate {
    
    
    //General Variables:
    var pin:Pin!
    var allPhotosLoaded = false
    var noPhotosLoaded = true
    
    //Core Data
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        fetchRequest.sortDescriptors = []
        
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    // store updated indexes
    var selectedIndexes   = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths : [NSIndexPath]!
    var updatedIndexPaths : [NSIndexPath]!
    
    //Storyboard References
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    //Begin 
    
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
                self.showAlert("An error occurred", message: errorString!)
                return
            }
        }
    }
    
    func pinFinishedDownload() {
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
    
    // MARK: Collection View
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



/*
class PhotoViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate
{
    @IBOutlet var mapView: MKMapView!
    @IBOutlet weak var PhotoCollection: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    var pin: Pin?
    var allPhotosLoaded = false
    var noPhotosLoaded = true
    let pinFinishedDownloadingNotification = "pinFinishedDownloadNotification"
    
    // store updated indexes
    var selectedIndexes   = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths : [NSIndexPath]!
    var updatedIndexPaths : [NSIndexPath]!
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!)
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
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
            if pin!.isDownloading {
                newCollectionButton.enabled = false
            }
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PhotoViewController.pinFinishedDownload), name: pinFinishedDownloadingNotification, object: nil)
            
            
        //Go Get Photos!
        //    fetchedResultsController.delegate = self
       //     fetch()
       //     print("Attempting to fetch photos...")
       //     setDelegates()
        
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
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // GET PHOTOS
    
    func loadNewCollectionSet() {
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            sharedContext.deleteObject(photo)
        }
        CoreDataStackManager.sharedInstance().saveContext()
        
        self.newCollectionButton.enabled = false
        print(pin!.photos.count)
        
        getPhotosForPin(pin!) { (success, errorString) in
            self.pinFinishedDownload()
            
            if success == false {
                self.showAlert("An error occurred", message: errorString!)
                return
            }
        }
    }
    
    func getPhotosForPin(pin: Pin, completionHandler: (success: Bool, errorString: String?) -> Void) {
        if (pin.isDownloading) {
            return
        }
        pin.isDownloading = true
        FlickrClient.sharedInstance.getPhotosForPin(pin) { (success, errorString) in
            pin.isDownloading = false
            
            CoreDataStackManager.sharedInstance().saveContext()
            NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: self.pinFinishedDownloadingNotification, object: self))
            completionHandler(success: success, errorString: errorString)
        }
    }

    
    func pinFinishedDownload() {
        if pin!.isDownloading == true {
            return
        }
        self.newCollectionButton.enabled = true
        
        if let objects = self.fetchedResultsController.fetchedObjects {
            if objects.count == 0 {
                self.newCollectionButton.enabled = false
            }
        }
    }
    
    
    
    // MARK: Collection View
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        return 0
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if photo.imagePath != nil {
            cell.activityIndicator.stopAnimating()
            cell.photoImageView.image = photo.image
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
    

    func showAlert(title: String, message: String, buttonText: String = "Ok", shake: Bool = false) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: buttonText, style: UIAlertActionStyle.Default, handler: nil))
        if shake {
            self.shakeScreen()
        }
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func shakeScreen() {
        let anim = CAKeyframeAnimation( keyPath:"transform" )
        anim.values = [
            NSValue( CATransform3D:CATransform3DMakeTranslation(-5, 0, 0 ) ),
            NSValue( CATransform3D:CATransform3DMakeTranslation( 5, 0, 0 ) )
        ]
        anim.autoreverses = true
        anim.repeatCount = 2
        anim.duration = 7/100
        
        view.layer.addAnimation( anim, forKey:nil )
    }


    
    /*
    // function to fetch the photos
    func fetch() {
        let error = NSErrorPointer()
        do {
            try fetchedResultsController.performFetch()
        } catch let error1 as NSError {
            error.memory = error1
        }
        if error != nil {
            print("Could not perform fetch due to \(error)")
        }
    }
    */
    
    /*
    // Load the collection view
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = PhotoCollection.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        cell.photoImageView.image = UIImage(named: "Picture-100")
        cell.activityIndicator.startAnimating()
        
        if let image = Cache.sharedInstance().imageForIdentifier(photo.imagePath ) {
            cell.activityIndicator.stopAnimating()
            cell.photoImageView.image = image
        } else if photo.status == .Idle {
            configureCell(cell, photo: photo)
        }
        
        return cell
    }
    
    func configureCell(cell: PhotoCollectionViewCell, photo: Photo) {
        let task = Cache.sharedInstance().downloadImage(photo.imagePath!) { imageData, error in
            if imageData != nil {
                let image = UIImage(data: imageData!)
                photo.getFileURL()
                cell.photoImageView.image = image
                cell.activityIndicator.stopAnimating()
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    print("error downloading image \(error)")
                    photo.prepareForDeletion()
                }
            }
        }
        cell.urlTask = task
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        if photo.status == .Done {
            photo.prepareForDeletion()
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: 110.0, height: 110.0)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    }

    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
  /*  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: AnyObject = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath:indexPath)
        return cell as! UICollectionViewCell
        
    }
    */
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    

    func photosFinishedLoading(notification : NSNotification) {
        
        dispatch_async(dispatch_get_main_queue()) {
            self.newCollectionButton.title = "New Collection"
            self.allPhotosLoaded = true
            self.newCollectionButton.enabled = true
        }
    }
    
    func photoFinishedLoading(photo: Photo) {
        
        dispatch_async(dispatch_get_main_queue()) {
            self.PhotoCollection.reloadData()
            self.noPhotosLoaded = false
            if self.allPhotosLoaded {
                self.newCollectionButton.title = "New Collection"
            } else {
                self.newCollectionButton.title = "Loading..."
            }
        }
    }
    
    
    func setDelegates() {
        mapView.delegate = self
        PhotoCollection.delegate = self
        PhotoCollection.dataSource = self
    }
    */


} */