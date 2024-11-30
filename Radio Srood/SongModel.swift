//
//  SongModel.swift
//  Radio Srood
//
//  Created by Tech on 22/05/2023.
//  Copyright © 2023 Appteve. All rights reserved.
//

import Foundation

class SongModel : NSObject, NSCoding{
    var trackid: Int = 0
    var artist: String = ""
    var track: String = ""
    var playcounts: String = ""
    var likes: String = ""
    var dislikes: String = ""
    var composer: String = ""
    var lyricWriter: String = ""
    var music: String = ""
    var dateAdded: String = ""
    var lyric: String = ""
    var explicit: Bool = false
    var allowDownload: Bool = false
    var mediaPath: String = ""
    var artcover: String = ""
    var ytLink: String = ""
    var fbLink: String = ""
    var igLink: String = ""
    var playlistid: Int = 0
    var isFav : Bool = false
    var isBookMarked : Bool = false
    var isRecentlyPlayed = false
    var lyric_synced : String = ""
    
    override init(){
        self.trackid = 0
        self.artist = ""
        self.track = ""
        self.playcounts = ""
        self.likes = ""
        self.dislikes = ""
        self.composer = ""
        self.lyricWriter = ""
        self.music = ""
        self.dateAdded = ""
        self.lyric = ""
        self.explicit = false
        self.allowDownload = false
        self.mediaPath = ""
        self.artcover = ""
        self.ytLink = ""
        self.fbLink = ""
        self.igLink = ""
        self.playlistid = 0
        self.isFav = false
        self.isBookMarked = false
        self.isRecentlyPlayed = false
        self.lyric_synced = ""
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.trackid, forKey: "trackid")
        aCoder.encode(self.artist, forKey: "artist")
        aCoder.encode(self.track, forKey: "track")
        aCoder.encode(self.playcounts, forKey: "playcounts")
        aCoder.encode(self.likes, forKey: "likes")
        aCoder.encode(self.dislikes, forKey: "dislikes")
        aCoder.encode(self.composer, forKey: "composer")
        aCoder.encode(self.lyricWriter, forKey: "lyricWriter")
        aCoder.encode(self.music, forKey: "music")
        aCoder.encode(self.dateAdded, forKey: "dateAdded")
        aCoder.encode(self.lyric, forKey: "lyric")
        aCoder.encode(self.explicit, forKey: "explicit")
        aCoder.encode(self.allowDownload, forKey: "allowDownload")
        aCoder.encode(self.mediaPath, forKey: "mediaPath")
        aCoder.encode(self.artcover, forKey: "artcover")
        aCoder.encode(self.ytLink, forKey: "ytLink")
        aCoder.encode(self.fbLink, forKey: "fbLink")
        aCoder.encode(self.igLink, forKey: "igLink")
        aCoder.encode(self.playlistid, forKey: "playlistid")
        aCoder.encode(self.isFav, forKey: "isFav")
        aCoder.encode(self.isBookMarked, forKey: "isBookMarked")
        aCoder.encode(self.isRecentlyPlayed, forKey: "isRecentlyPlayed")
        aCoder.encode(self.lyric_synced, forKey: "lyric_synced")
        
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        self.init()
        self.trackid = aDecoder.decodeInteger(forKey: "trackid")
        self.artist = aDecoder.decodeObject(forKey: "artist") as? String ?? ""
        self.track = aDecoder.decodeObject(forKey: "track") as? String ?? ""
        self.playcounts = aDecoder.decodeObject(forKey: "playcounts") as? String ?? ""
        self.likes = aDecoder.decodeObject(forKey: "likes") as? String ?? ""
        self.dislikes = aDecoder.decodeObject(forKey: "dislikes") as? String ?? ""
        self.composer = aDecoder.decodeObject(forKey: "composer") as? String ?? ""
        self.lyricWriter = aDecoder.decodeObject(forKey: "music") as? String ?? ""
        self.music = aDecoder.decodeObject(forKey: "trackImageUrl") as? String ?? ""
        self.dateAdded = aDecoder.decodeObject(forKey: "dateAdded") as? String ?? ""
        self.lyric = aDecoder.decodeObject(forKey: "lyric") as? String ?? ""
        self.explicit = aDecoder.decodeBool(forKey: "explicit")
        self.allowDownload = aDecoder.decodeBool(forKey: "allowDownload")
        self.mediaPath = aDecoder.decodeObject(forKey: "mediaPath") as? String ?? ""
        self.artcover = aDecoder.decodeObject(forKey: "artcover") as? String ?? ""
        self.ytLink = aDecoder.decodeObject(forKey: "ytLink") as? String ?? ""
        self.fbLink = aDecoder.decodeObject(forKey: "fbLink") as? String ?? ""
        self.igLink = aDecoder.decodeObject(forKey: "igLink") as? String ?? ""
        self.playlistid = aDecoder.decodeInteger(forKey: "playlistid")
        self.isFav = aDecoder.decodeBool(forKey: "isFav")
        self.isBookMarked = aDecoder.decodeBool(forKey: "isBookMarked")
        self.isRecentlyPlayed = aDecoder.decodeBool(forKey: "isRecentlyPlayed")
        self.lyric_synced = aDecoder.decodeObject(forKey: "lyric_synced") as? String ?? ""
    }
    
    func convertToPodcastModel() -> PodcastObject{
        if let urlString = self.mediaPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: songPath + urlString) {
            let podcastData = PodcastObject(file: url, trackName: self.track , artistName: self.artist , imageURL: URL(string: self.artcover)!)
            return podcastData
        }
        else{
            let podcastData = PodcastObject(file: URL(string: self.mediaPath)!, trackName: self.track , artistName: self.artist , imageURL: URL(string: self.artcover)!)
            return podcastData
        }
    }
}
