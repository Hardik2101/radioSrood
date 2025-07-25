import Foundation
import UIKit

class PodcastObject: NSObject, NSCoding {
    var file: URL?
    var mediaPath: String?
    var trackName: String?
    var artistName: String?
    var image: UIImage?
    var imageURL: URL?
    var trackid: Int?
    var likes: String?
    var playcounts: Double?
    var dateAdded: String?
    var artcover: String?
    var artcover200: URL?

    init(file: URL? = nil, mediaPath: String? = nil, trackName: String? = nil, artistName: String? = nil, image: UIImage? = nil, imageURL: URL? = nil, trackid: Int? = nil, likes: String? = nil, playcounts: Double? = nil, dateAdded: String? = nil, artcover: String? = nil, artcover200: URL? = nil) {
        self.file = file
        self.mediaPath = mediaPath
        self.trackName = trackName
        self.artistName = artistName
        self.image = image
        self.imageURL = imageURL
        self.trackid = trackid
        self.likes = likes
        self.playcounts = playcounts
        self.dateAdded = dateAdded
        self.artcover = artcover
        self.artcover200 = artcover200
    }

    // MARK: - NSCoding
    func encode(with coder: NSCoder) {
        coder.encode(file, forKey: "file")
        coder.encode(mediaPath, forKey: "mediaPath")
        coder.encode(trackName, forKey: "trackName")
        coder.encode(artistName, forKey: "artistName")
        coder.encode(image, forKey: "image")
        coder.encode(imageURL, forKey: "imageURL")
        coder.encode(trackid, forKey: "trackid")
        coder.encode(likes, forKey: "likes")
        coder.encode(playcounts, forKey: "playcounts")
        coder.encode(dateAdded, forKey: "dateAdded")
        coder.encode(artcover, forKey: "artcover")
        coder.encode(artcover200, forKey: "artcover200")
    }

    required init?(coder: NSCoder) {
        self.file = coder.decodeObject(forKey: "file") as? URL
        self.mediaPath = coder.decodeObject(forKey: "mediaPath") as? String
        self.trackName = coder.decodeObject(forKey: "trackName") as? String
        self.artistName = coder.decodeObject(forKey: "artistName") as? String
        self.image = coder.decodeObject(forKey: "image") as? UIImage
        self.imageURL = coder.decodeObject(forKey: "imageURL") as? URL
        self.trackid = coder.decodeObject(forKey: "trackid") as? Int
        self.likes = coder.decodeObject(forKey: "likes") as? String
        self.playcounts = coder.decodeObject(forKey: "playcounts") as? Double
        self.dateAdded = coder.decodeObject(forKey: "dateAdded") as? String
        self.artcover = coder.decodeObject(forKey: "artcover") as? String
        self.artcover200 = coder.decodeObject(forKey: "artcover200") as? URL
    }
}

extension PodcastObject {
    func convertToSongModel() -> SongModel {
        // Break up the initializer into sub-expressions
        let songModel = SongModel()
        
        // Set trackid
        songModel.trackid = trackid ?? Int("\(trackName ?? "")_\(artistName ?? "")".hashValue & 0x7FFFFFFF)
        
        // Set basic track info
        songModel.artist = artistName ?? ""
        songModel.track = trackName ?? ""
        songModel.artcover = artcover ?? imageURL?.absoluteString ?? ""
        songModel.mediaPath = mediaPath ?? file?.absoluteString ?? ""
        
        // Set additional metadata
        songModel.playcounts = playcounts != nil ? String(playcounts!) : ""
        songModel.likes = likes ?? ""
        songModel.dateAdded = dateAdded ?? ""
        
        // Set default values for remaining fields
        songModel.dislikes = ""
        songModel.composer = ""
        songModel.lyricWriter = ""
        songModel.music = ""
        songModel.lyric = ""
        songModel.explicit = false
        songModel.allowDownload = true
        songModel.ytLink = ""
        songModel.fbLink = ""
        songModel.igLink = ""
        songModel.playlistid = 0
        songModel.isFav = false
        songModel.isDownload = false
        songModel.isBookMarked = false
        songModel.isRecentlyPlayed = false
        songModel.lyric_synced = ""
        
        return songModel
    }
}

