//
//  FlickrConstants.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 10/08/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
////  Some code leveraged from my third project, "On the Map, Phil!"
//  Reference from Julia Will and Spirosrap GitHub Repo's and previous "On The Map".
//  https://github.com/mileandra/udacity-virtual-tourist/tree/master/Virtual%20Tourist
//  https://github.com/spirosrap/On-The-Map/blob/master/On%20The%20Map/UdacityConvenience.swift


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
    
    struct Methods {
        static let SEARCH = "flickr.photos.search"
    }
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - API Keys & Values
    //--------------------------------------------------------------------------------------------------------
    
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
    
    struct BBoxParameters {
        static let BOUNDING_BOX_HALF_WIDTH = 1.0
        static let BOUNDING_BOX_HALF_HEIGHT = 1.0
        static let LAT_MIN = -90.0
        static let LAT_MAX = 90.0
        static let LON_MIN = -180.0
        static let LON_MAX = 180.0
    }
}