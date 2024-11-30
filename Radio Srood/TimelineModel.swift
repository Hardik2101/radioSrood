//
//  TimelineModel.swift
//  GlobalOneV2
//
//  Created by appteve on 24/04/2017.
//  Copyright © 2017 Appteve. All rights reserved.
//

import UIKit

class TimelineModel: NSObject {
    
    var trackName: String!
    var trackUrl: String!
    var trackImageUrl: String!
    
    init(trackName: String, trackUrl: String, trackImageUrl: String) {
        
        self.trackName = trackName
        self.trackUrl = trackUrl
        self.trackImageUrl = trackImageUrl
        
    }
    
    func trackName_() -> String {
        return trackName
    }
    
    func trackUrl_() -> String {
        return trackUrl
    }
    
    func trackImageUrl_() -> String {
        
        return trackImageUrl
    }
   

}
