//
//  FlickrConvenience.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 10/08/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
//  Adapted from previous project "On The Map".
//  Flickr API Documentation: https://www.flickr.com/services/api/

import Foundation
import CoreData

extension FlickrClient {
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - Variables, Outlets and Constants
    //--------------------------------------------------------------------------------------------------------
    
    func getPhotosForPin(pin: Pin, completionHandler: (success: Bool, errorString: String?) -> Void) {
        
        // see if we previously  received total number of pages for pin
        var pageNumber = 1
        
        if let numPages = pin.numPages {
            var numPagesInt = numPages as Int
                // Flickr Caps at 250 pages, ensure we don't return too many
            if numPagesInt > 200 {
                numPagesInt = 200
            }
            pageNumber = Int((arc4random_uniform(UInt32(numPagesInt)))) + 1
            print("Downloading photos for these coordinates...")
        }
        // Shuffly the sorts to  ensure random results
        let possibleSorts = ["date-posted-desc", "date-posted-asc", "date-taken-desc", "date-taken-asc", "interstingness-desc", "interestingness-asc"]
        let sortBy = possibleSorts[Int((arc4random_uniform(UInt32(possibleSorts.count))))]
        
        let parameters = [
            ParameterKeys.METHOD: Methods.SEARCH,
            ParameterKeys.EXTRAS: ParameterValues.URL_M,
            ParameterKeys.FORMAT: ParameterValues.JSON_FORMAT,
            ParameterKeys.NO_JSON_CALLBACK: "1",
            ParameterKeys.SAFE_SEARCH: "1",
            ParameterKeys.BBOX: createBoundingBoxString(pin),
            ParameterKeys.PAGE: pageNumber,
            ParameterKeys.PER_PAGE: 21,
            ParameterKeys.SORT: sortBy
        ]
        
        //--------------------------------------------------------------------------------------------------------
        // MARK: - GET Method to assign result photos from Flickr API search to dictionary
        //--------------------------------------------------------------------------------------------------------
        
        taskForGETMethod(nil, parameters: parameters as? [String : AnyObject], parseJSON: true) { (JSONResult, error) in
            if let error = error {
                var errorMessage = ""
                switch error.code {
                case 2:
                    errorMessage = "No Network Connection"
                    break
                default:
                    errorMessage = "An error occured while fetching photos"
                    break
                }
                completionHandler(success: false, errorString: errorMessage)
            } else {
                if let photosDictionary = JSONResult.valueForKey("photos") as? [String: AnyObject],
                    photosArray = photosDictionary["photo"] as? [[String: AnyObject]],
                    numPages = photosDictionary["pages"] as? Int {
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        pin.numPages = numPages
                        
                        for photoDictionary in photosArray {
                            let photoURLString = photoDictionary["url_m"] as! String
                            let photo = Photo(photoURL: photoURLString, pin: pin, context: self.sharedContext)
                            
                            self.downloadImageForPhoto(photo) { (success, errorString) in
                                if success {
                                    dispatch_async(dispatch_get_main_queue(), {
                                        CoreDataStackManager.sharedInstance().saveContext()
                                        completionHandler(success: true, errorString: nil)
                                    })
                                } else {
                                    dispatch_async(dispatch_get_main_queue(), {
                                        completionHandler(success: false, errorString: errorString)
                                    })
                                }
                            }
                        }
                    })
                } else {
                    completionHandler(success: false, errorString: "Unable to download Photos")
                }
            }
        }
    }
    
    func downloadImageForPhoto(photo: Photo, completionHandler: (success: Bool, errorString: String?) -> Void) {
        
        taskForGETMethod(photo.photoURL, parameters: nil, parseJSON: false) { (result, error) in
            if error != nil {
                photo.imagePath = "unavailable"
                completionHandler(success: false, errorString: "Unable to download Photo")
            } else {
                if let result = result {
                    dispatch_async(dispatch_get_main_queue(), {
                        let fileName = (photo.photoURL as NSString).lastPathComponent
                        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
                        let pathArray = [path, fileName]
                        let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
                        
                        NSFileManager.defaultManager().createFileAtPath(fileURL.path!, contents: result as? NSData, attributes: nil)
                        
                        photo.imagePath = fileURL.path
                        completionHandler(success: true, errorString: nil)
                       
                    })
                } else {
                    completionHandler(success: false, errorString: "Unable to download Photo")
                }
            }
        }
    }
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - Bounding Box Creation
    //--------------------------------------------------------------------------------------------------------
    
    func createBoundingBoxString(pin: Pin) -> String {
        
        //"Geo queries require some sort of limiting agent in order to prevent the database from crying. This is basically like the check against "parameterless searches" for queries without a geo component."
        //  Although the Flickr API documentation implies bbox is optional, it seems that it doesn't always return results properly unless this is specified. Long & Lat values set to max.
        
        let latitude = pin.coordinate.latitude
        let longitude = pin.coordinate.longitude
        let bottom_left_lon = max(longitude - BBoxParameters.BOUNDING_BOX_HALF_WIDTH, BBoxParameters.LON_MIN)
        let bottom_left_lat = max(latitude - BBoxParameters.BOUNDING_BOX_HALF_HEIGHT, BBoxParameters.LAT_MIN)
        let top_right_lon = min(longitude + BBoxParameters.BOUNDING_BOX_HALF_HEIGHT, BBoxParameters.LON_MAX)
        let top_right_lat = min(latitude + BBoxParameters.BOUNDING_BOX_HALF_HEIGHT, BBoxParameters.LAT_MAX)
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    var sharedContext: NSManagedObjectContext {
        print("Image cached!")
        return CoreDataStackManager.sharedInstance().managedObjectContext

    }
}