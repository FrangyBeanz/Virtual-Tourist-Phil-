//
//  FlickrConvenience.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 10/08/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
//

import Foundation
import CoreData

extension FlickrClient {
    
    
    func getPhotosForPin(pin: Pin, completionHandler: (success: Bool, errorString: String?) -> Void) {
        
        // see if we previously  received total number of pages for pin
        var pageNumber = 1
        
        if let numPages = pin.numPages {
            var numPagesInt = numPages as Int
            // We might only access the first 4000 images returned by a search, so limit the results
            if numPagesInt > 190 {
                numPagesInt = 190
            }
            pageNumber = Int((arc4random_uniform(UInt32(numPagesInt)))) + 1
            print("Getting photos for page number \(pageNumber) in \(numPages) total pages")
        }
        // Shuffle Sort to get more random images
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
        
        taskForGETMethod(nil, parameters: parameters as? [String : AnyObject], parseJSON: true) { (JSONResult, error) in
            if let error = error {
                var errorMessage = ""
                switch error.code {
                case 2:
                    errorMessage = "Network connection lost"
                    break
                default:
                    errorMessage = "A technical error occured while fetching photos"
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
    
    func createBoundingBoxString(pin: Pin) -> String {
        
        let latitude = pin.coordinate.latitude
        let longitude = pin.coordinate.longitude
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - BBoxParameters.BOUNDING_BOX_HALF_WIDTH, BBoxParameters.LON_MIN)
        let bottom_left_lat = max(latitude - BBoxParameters.BOUNDING_BOX_HALF_HEIGHT, BBoxParameters.LAT_MIN)
        let top_right_lon = min(longitude + BBoxParameters.BOUNDING_BOX_HALF_HEIGHT, BBoxParameters.LON_MAX)
        let top_right_lat = min(latitude + BBoxParameters.BOUNDING_BOX_HALF_HEIGHT, BBoxParameters.LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
}




/*

extension FlickrClient {
 
 
    func getPhotosForPin(pin: Pin, completionHandler: (success: Bool, errorString: String?) -> Void) {
        
        // see if we previously  received total number of pages for pin
        var pageNumber = 1
        
        if let numPages = pin.numPages {
            var numPagesInt = numPages as Int
            // We might only access the first 4000 images returned by a search, so limit the results
            if numPagesInt > 190 {
                numPagesInt = 190
            }
            pageNumber = Int((arc4random_uniform(UInt32(numPagesInt)))) + 1
            print("Getting photos for page number \(pageNumber) in \(numPages) total pages")
        }
        // Shuffle Sort to get more random images
        let possibleSorts = ["date-posted-desc", "date-posted-asc", "date-taken-desc", "date-taken-asc", "interstingness-desc", "interestingness-asc"]
        let sortBy = possibleSorts[Int((arc4random_uniform(UInt32(possibleSorts.count))))]
        
        let parameters = [
            JSONResponseKeys.METHOD: Methods.SEARCH,
            JSONResponseKeys.EXTRAS: ParameterValues.URL_M,
            JSONResponseKeys.FORMAT: ParameterValues.JSON_FORMAT,
            JSONResponseKeys.NO_JSON_CALLBACK: "1",
            JSONResponseKeys.SAFE_SEARCH: "1",
            JSONResponseKeys.BBOX: createBoundingBoxString(pin),
            JSONResponseKeys.PAGE: pageNumber,
            JSONResponseKeys.PER_PAGE: 21,
            JSONResponseKeys.SORT: sortBy
        ]
        
        taskForGETMethod(nil, parameters: parameters as! [String : AnyObject], parseJSON: true) { (JSONResult, error) in
            if let error = error {
                var errorMessage = ""
                switch error.code {
                case 2:
                    errorMessage = "Network connection lost"
                    break
                default:
                    errorMessage = "A technical error occured while fetching photos"
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
    
    
    func createBoundingBoxString(pin: Pin) -> String {
        
        let latitude = pin.coordinate.latitude
        let longitude = pin.coordinate.longitude
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - BBoxParameters.BOUNDING_BOX_HALF_WIDTH, BBoxParameters.LON_MIN)
        let bottom_left_lat = max(latitude - BBoxParameters.BOUNDING_BOX_HALF_HEIGHT, BBoxParameters.LAT_MIN)
        let top_right_lon = min(longitude + BBoxParameters.BOUNDING_BOX_HALF_HEIGHT, BBoxParameters.LON_MAX)
        let top_right_lat = min(latitude + BBoxParameters.BOUNDING_BOX_HALF_HEIGHT, BBoxParameters.LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }

    
    // Helpers
    
    // Helper: Substitute the key for the value that is contained within the method name
    func subtituteKeyInMethod(method: String, key: String, value: String) -> String? {
        if method.rangeOfString("{\(key)}") != nil {
            return method.stringByReplacingOccurrencesOfString("{\(key)}", withString: value)
        } else {
            return nil
        }
    }
    
    //Helper: Given a response with error, see if a status_message is returned, otherwise return the previous error
    func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if let parsedResult = (try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as? [String : AnyObject] {
            
            if let errorMessage = parsedResult[FlickrClient.JSONResponseKeys.StatusMessage] as? String {
                
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                
                return NSError(domain: "Virtual Tourist Error", code: 1, userInfo: userInfo)
            }
        }
        
        return error
    }
    
    
    //Helper: Given raw JSON, return a usable Foundation object
    func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    //Helper: Given a dictionary of parameters, convert to a string for a url
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            // Make sure that it is a string value
            let stringValue = "\(value)"
            
            // Escape it //
            _ = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            // FIX: Replace spaces with '+'
            let replaceSpaceValue = stringValue.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
            
            // Append it
            urlVars += [key + "=" + "\(replaceSpaceValue)"]
        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    
    // Shared Instance
    
    func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
    
} */