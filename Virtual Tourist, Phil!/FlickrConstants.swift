//
//  FlickrConstants.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 10/08/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
//  Brief Description: defines constants required for interation with the Flickr API

import Foundation


extension FlickrClient {
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - API Constants
    //--------------------------------------------------------------------------------------------------------
    
    struct Constants {
        static let APIKey   = "3753c0beb4500db7dccbeb11726dc85a"
        static let BASE_URL = "https://api.flickr.com/services/rest/"
    }
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - API Methods
    //--------------------------------------------------------------------------------------------------------
    // Flickr Photos Search https://www.flickr.com/services/api/flickr.photos.search.html
    
    struct Methods {
        static let SEARCH = "flickr.photos.search"
    }
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - API Keys & Values
    //--------------------------------------------------------------------------------------------------------
    // Flickr API Arguments https://www.flickr.com/services/api/flickr.photos.search.html
    
    struct ParameterKeys {
        static let API_KEY          = "api_key"
        static let METHOD           = "method"
        static let SAFE_SEARCH      = "safe_search"
        static let EXTRAS           = "extras"
        static let FORMAT           = "format"
        static let NO_JSON_CALLBACK = "nojsoncallback"
        static let BBOX             = "bbox"
        static let PAGE             = "page"
        static let PER_PAGE         = "per_page"
        static let SORT             = "sort"
    }
    
    struct ParameterValues {
        static let JSON_FORMAT  = "json"
        static let URL_M        = "url_m"
    }
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - Bounding Box Settings
    //--------------------------------------------------------------------------------------------------------
    //"Geo queries require some sort of limiting agent in order to prevent the database from crying. This is basically like the check against "parameterless searches" for queries without a geo component."
    //  Although the Flickr API documentation implies bbox is optional, it seems that it doesn't always return results properly unless this is specified. Long & Lat values set to max.
    
    struct BBoxParameters {
        static let BOUNDING_BOX_HALF_WIDTH = 1.0
        static let BOUNDING_BOX_HALF_HEIGHT = 1.0
        static let LAT_MIN = -90.0
        static let LAT_MAX = 90.0
        static let LON_MIN = -180.0
        static let LON_MAX = 180.0
    }
}