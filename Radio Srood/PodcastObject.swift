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

extension PodcastObject {
    func convertToSongModel() -> SongModel {
        let song = SongModel()
        song.trackid = 0 // Default, as PodcastObject doesn't have trackid
        song.artist = self.artistName ?? ""
        song.track = self.trackName ?? ""
        song.playcounts = "0" // Default
        song.likes = "0" // Default
        song.dislikes = "0" // Default
        song.composer = "" // Default
        song.lyricWriter = "" // Default
        song.music = "" // Default
        song.dateAdded = "" // Default
        song.lyric = "" // Default
        song.explicit = false // Default
        song.allowDownload = false // Default
        song.lyric_synced = "" // Default
        song.mediaPath = self.file?.absoluteString ?? ""
        song.artcover = self.imageURL?.absoluteString ?? ""
        song.ytLink = "" // Default
        song.fbLink = "" // Default
        song.igLink = "" // Default
        song.playlistid = 0 // Default
        song.isFav = false
        song.isBookMarked = false
        song.isRecentlyPlayed = false
        return song
    }
}
