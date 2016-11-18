//
//  MasterViewController.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 14/09/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.

//  Brief description: Parent controller allowing for the use of re-usable code in Map and Photo views.


import UIKit
import CoreData

class MasterViewController: UIViewController {
    
    let pinFinishedDownloadingNotification = "pinFinishedDownloadNotification"
    
    //MARK: Download Photo Set
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
    
    //MARK: Modal alerts
    //A re-usable function to display a modal alert message
    func showAlert(title: String, message: String, buttonText: String = "Ok") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: buttonText, style: UIAlertActionStyle.Default, handler: nil))

        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //MARK: Core Data
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
}
