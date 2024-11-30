//
//  PodcastObject.swift
//  GlobalOneV2
//
//  Created by appteve on 24/04/2017.
//  Copyright © 2017 Appteve. All rights reserved.
//

import UIKit

class PodcastObject: NSObject {
    
    var file: URL!
    var trackName: String!
    var artistName: String!
    var image: UIImage?
    var imageURL: URL?
    
    init(file: URL, trackName: String, artistName: String, image: UIImage? = nil, imageURL: URL? = nil) {
        self.file = file
        self.trackName = trackName
        self.artistName = artistName
        self.image = image
        self.imageURL = imageURL
    }

}
