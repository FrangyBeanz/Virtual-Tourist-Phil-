//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist, Phil!
//
//  Created by Phillip Hughes on 09/09/2016.
//  Copyright © 2016 Phillip Hughes. All rights reserved.
//
//  Brief description: Holds the individual photo and loading icon for each individual photo cell on the photo collection view.


import Foundation
import UIKit

class PhotoCollectionViewCell : UICollectionViewCell {
    
    //--------------------------------------------------------------------------------------------------------
    // MARK: - Variables, Outlets and Constants
    //--------------------------------------------------------------------------------------------------------
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

}
    