//
//  FlickrClient.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 10/08/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
//  Some code leveraged from my third project, "On the Map, Phil!"

import Foundation

class FlickrClient: NSObject {
    
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    
    //GET
    
    func taskForGETMethod(method: String, parse: Bool, parameters: [String : AnyObject]?, completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        //1. Set the parameters
        
        //2/3. Build the URL and configure the request
        var urlString:String
        if let mutableParameters = parameters {
            urlString = method + FlickrClient.escapedParameters(mutableParameters)
        }else{
            urlString = method
        }
        
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        if(parse){// Check it if is for the parse application and apply the keys
            request.addValue(FlickrClient.Constants.APIKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        }
        //4. Make the request
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            //5/6. Parse the data and use the data (happens in completion handler)
            if let error = downloadError {
                _ = FlickrClient.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: downloadError)
            } else {
                var newData = data
                if(!parse){// If it isn't for parse, it is for the Udacity API which it requires to ommit the first 5 characters for security reasons
                    newData = data!.subdataWithRange(NSMakeRange(5, data!.length - 5)) /* subset response data! */
                }
                FlickrClient.parseJSONWithCompletionHandler(newData!, completionHandler: completionHandler)
            }
        }
        
        //7. Start the request
        task.resume()
        
        return task
    }
    
    //Photo loading status notifications 
    
    struct Notifications {
        
        static let PhotosLoadedForPin = "PhotosLoadedForPinNotification"
        static let PhotoLoaded = "PhotoLoadedNotification"
    }
    
    //Download Status

    struct Download {
        enum Status {
            case Idle, Loading, Done
        }
    }
    
    // Helpers
    
    // Helper: Substitute the key for the value that is contained within the method name
    class func subtituteKeyInMethod(method: String, key: String, value: String) -> String? {
        if method.rangeOfString("{\(key)}") != nil {
            return method.stringByReplacingOccurrencesOfString("{\(key)}", withString: value)
        } else {
            return nil
        }
    }
    
    //Helper: Given a response with error, see if a status_message is returned, otherwise return the previous error
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if let parsedResult = (try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as? [String : AnyObject] {
            
            if let errorMessage = parsedResult[FlickrClient.JSONResponseKeys.StatusMessage] as? String {
                
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                
                return NSError(domain: "Virtual Tourist Error", code: 1, userInfo: userInfo)
            }
        }
        
        return error
    }

    
    //Helper: Given raw JSON, return a usable Foundation object
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
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
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
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
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
}