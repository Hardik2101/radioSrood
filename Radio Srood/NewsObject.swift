//
//  NewsObject.swift
//  GlobalOneV2
//
//  Created by appteve on 24/04/2017.
//  Copyright © 2017 Appteve. All rights reserved.
//

import UIKit

class NewsObject: NSObject {
    
    var newsTitle: String!
    var newsText: String!
    var newsImage: String!
    
    init(newsTitle: String, newsText: String, newsImage: String) {
        
        self.newsTitle = newsTitle
        self.newsText = newsText
        self.newsImage = newsImage
    }
    
    

}
