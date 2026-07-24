//
//  PlayListModel.swift
//  Radio Srood
//
//  Created by Tech on 22/05/2023.
//  Copyright © 2023 Appteve. All rights reserved.
//

import Foundation

class PlayListModel : NSObject, NSCoding{
    var name : String = ""
    var songs = [SongModel]()
    /// Local file path for custom playlist cover (e.g. Smart Mix collage). Empty = fall back to first song art.
    var coverImagePath: String = ""
    
    override init(){
        self.name = ""
        self.songs = [SongModel]()
        self.coverImagePath = ""
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: "name")
        aCoder.encode(self.songs, forKey: "songs")
        aCoder.encode(self.coverImagePath, forKey: "coverImagePath")
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        self.init()
        self.name = aDecoder.decodeObject(forKey: "name") as? String ?? ""
        self.songs = aDecoder.decodeObject(forKey: "songs") as? [SongModel] ?? [SongModel]()
        self.coverImagePath = aDecoder.decodeObject(forKey: "coverImagePath") as? String ?? ""
    }
}
