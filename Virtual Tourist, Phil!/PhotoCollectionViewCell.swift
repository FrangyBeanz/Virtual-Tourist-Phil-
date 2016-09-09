//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 09/09/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
//

import Foundation
import UIKit

class PhotoCollectionViewCell : UICollectionViewCell {
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    /**
     MARK: cancels the cells download task by cancelling
     the NSURLSessionTask
     **/
    var urlTask: NSURLSessionTask? {
        
        didSet {
            if let task = oldValue {
                task.cancel()
            }
        }
    }
    
}