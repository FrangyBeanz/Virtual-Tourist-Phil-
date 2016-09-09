//
//  FlickrConvenience.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 10/08/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    
    
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
    
    
}