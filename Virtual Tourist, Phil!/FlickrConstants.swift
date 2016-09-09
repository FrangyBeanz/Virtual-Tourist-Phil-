//
//  FlickrConstants.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 10/08/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
////  Some code leveraged from my third project, "On the Map, Phil!"


import Foundation

extension FlickrClient {
    
    struct Constants {
        
    //API Key
        static let APIKey : String = "3753c0beb4500db7dccbeb11726dc85a"
        static let FlickrURL: String = "https://api.flickr.com/services/rest/"
    }
    
    // API Method
    struct Methods {
        static let FlickrSearch = "flickr.photos.search"
    }
    
    // Default Longitude and Latitude to refresh the map to
    struct LongLat {
        static let DefaultLat = 51.9080387
        static let DefaultLong = -2.0772528
    }
    
    // JSON Response Keys
    struct JSONResponseKeys {
        
        // Data
        static let APIKey           = "api_key"
        static let Method           = "method"
        static let SAFE_SEARCH      = "safe_search"
        static let EXTRAS           = "extras"
        static let FORMAT           = "format"
        static let NO_JSON_CALLBACK = "nojsoncallback"
        static let BBOX             = "bbox"
        static let PAGE             = "page"
        static let PER_PAGE         = "per_page"
        static let SORT             = "sort"
        static let StatusMessage    = "Error"
    }

    struct ParameterValues {
        static let JSON_FORMAT  = "json"
        static let URL_M        = "url_m"
    }
    
    struct BBoxParameters {
        static let BOUNDING_BOX_HALF_WIDTH = 1.0
        static let BOUNDING_BOX_HALF_HEIGHT = 1.0
        static let LAT_MIN = -90.0
        static let LAT_MAX = 90.0
        static let LON_MIN = -180.0
        static let LON_MAX = 180.0
    }
    
   }