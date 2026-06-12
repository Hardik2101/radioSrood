import Foundation
import UIKit

class PodcastObject: NSObject, NSCoding {
    var file: URL?
    var mediaPath: String?
    var hlsMediaPath: String?
    var trackName: String?
    var artistName: String?
    var image: UIImage?
    var imageURL: URL?
    var trackid: Int?
    var likes: String?
    var dislikes: String?
    var playcounts: Double?
    var dateAdded: String?
    var artcover: String?
    var artcover_200: String?
    var artcover200: URL?
    var isBookMarked: Bool?

    // Additional fields from SongModel
    var composer: String?
    var lyricWriter: String?
    var music: String?
    var lyric: String?
    var lyric_synced: String?
    var explicit: Bool?
    var allowDownload: Bool?
    var ytLink: String?
    var fbLink: String?
    var igLink: String?
    var playlistid: Int?
    var isFav: Bool?
    var isDownload: Bool?
    var isRecentlyPlayed: Bool?

    init(
        file: URL? = nil,
        mediaPath: String? = nil,
        hlsMediaPath: String? = nil,
        trackName: String? = nil,
        artistName: String? = nil,
        image: UIImage? = nil,
        imageURL: URL? = nil,
        trackid: Int? = nil,
        likes: String? = nil,
        dislikes: String? = nil,
        playcounts: Double? = nil,
        dateAdded: String? = nil,
        artcover: String? = nil,
        artcover_200: String? = nil,
        artcover200: URL? = nil,
        isBookMarked: Bool = false,
        composer: String? = nil,
        lyricWriter: String? = nil,
        music: String? = nil,
        lyric: String? = nil,
        lyric_synced: String? = nil,
        explicit: Bool? = nil,
        allowDownload: Bool? = nil,
        ytLink: String? = nil,
        fbLink: String? = nil,
        igLink: String? = nil,
        playlistid: Int? = nil,
        isFav: Bool? = nil,
        isDownload: Bool? = nil,
        isRecentlyPlayed: Bool? = nil
    ) {
        self.file = file
        self.mediaPath = mediaPath
        self.hlsMediaPath = hlsMediaPath
        self.trackName = trackName
        self.artistName = artistName
        self.image = image
        self.imageURL = imageURL
        self.trackid = trackid
        self.likes = likes
        self.dislikes = dislikes
        self.playcounts = playcounts
        self.dateAdded = dateAdded
        self.artcover = artcover
        self.artcover_200 = artcover_200
        self.artcover200 = artcover200
        self.isBookMarked = isBookMarked
        self.composer = composer
        self.lyricWriter = lyricWriter
        self.music = music
        self.lyric = lyric
        self.lyric_synced = lyric_synced
        self.explicit = explicit
        self.allowDownload = allowDownload
        self.ytLink = ytLink
        self.fbLink = fbLink
        self.igLink = igLink
        self.playlistid = playlistid
        self.isFav = isFav
        self.isDownload = isDownload
        self.isRecentlyPlayed = isRecentlyPlayed
    }

    // MARK: - NSCoding
    func encode(with coder: NSCoder) {
        coder.encode(file, forKey: "file")
        coder.encode(mediaPath, forKey: "mediaPath")
        coder.encode(hlsMediaPath, forKey: "hlsMediaPath")
        coder.encode(trackName, forKey: "trackName")
        coder.encode(artistName, forKey: "artistName")
        coder.encode(image, forKey: "image")
        coder.encode(imageURL, forKey: "imageURL")
        coder.encode(trackid, forKey: "trackid")
        coder.encode(likes, forKey: "likes")
        coder.encode(dislikes, forKey: "dislikes")
        coder.encode(playcounts, forKey: "playcounts")
        coder.encode(dateAdded, forKey: "dateAdded")
        coder.encode(artcover, forKey: "artcover")
        coder.encode(artcover_200, forKey: "artcover_200")
        coder.encode(artcover200, forKey: "artcover200")
        coder.encode(isBookMarked, forKey: "isBookMarked")
        coder.encode(composer, forKey: "composer")
        coder.encode(lyricWriter, forKey: "lyricWriter")
        coder.encode(music, forKey: "music")
        coder.encode(lyric, forKey: "lyric")
        coder.encode(lyric_synced, forKey: "lyric_synced")
        coder.encode(explicit, forKey: "explicit")
        coder.encode(allowDownload, forKey: "allowDownload")
        coder.encode(ytLink, forKey: "ytLink")
        coder.encode(fbLink, forKey: "fbLink")
        coder.encode(igLink, forKey: "igLink")
        coder.encode(playlistid, forKey: "playlistid")
        coder.encode(isFav, forKey: "isFav")
        coder.encode(isDownload, forKey: "isDownload")
        coder.encode(isRecentlyPlayed, forKey: "isRecentlyPlayed")
    }

    required init?(coder: NSCoder) {
        self.file = coder.decodeObject(forKey: "file") as? URL
        self.mediaPath = coder.decodeObject(forKey: "mediaPath") as? String
        self.hlsMediaPath = coder.decodeObject(forKey: "hlsMediaPath") as? String
        self.trackName = coder.decodeObject(forKey: "trackName") as? String
        self.artistName = coder.decodeObject(forKey: "artistName") as? String
        self.image = coder.decodeObject(forKey: "image") as? UIImage
        self.imageURL = coder.decodeObject(forKey: "imageURL") as? URL
        self.trackid = coder.decodeObject(forKey: "trackid") as? Int
        self.likes = coder.decodeObject(forKey: "likes") as? String
        self.dislikes = coder.decodeObject(forKey: "dislikes") as? String
        self.playcounts = coder.decodeObject(forKey: "playcounts") as? Double
        self.dateAdded = coder.decodeObject(forKey: "dateAdded") as? String
        self.artcover = coder.decodeObject(forKey: "artcover") as? String
        self.artcover_200 = coder.decodeObject(forKey: "artcover_200") as? String
        self.artcover200 = coder.decodeObject(forKey: "artcover200") as? URL
        self.isBookMarked = coder.decodeObject(forKey: "isBookMarked") as? Bool
        self.composer = coder.decodeObject(forKey: "composer") as? String
        self.lyricWriter = coder.decodeObject(forKey: "lyricWriter") as? String
        self.music = coder.decodeObject(forKey: "music") as? String
        self.lyric = coder.decodeObject(forKey: "lyric") as? String
        self.lyric_synced = coder.decodeObject(forKey: "lyric_synced") as? String
        self.explicit = coder.decodeObject(forKey: "explicit") as? Bool
        self.allowDownload = coder.decodeObject(forKey: "allowDownload") as? Bool
        self.ytLink = coder.decodeObject(forKey: "ytLink") as? String
        self.fbLink = coder.decodeObject(forKey: "fbLink") as? String
        self.igLink = coder.decodeObject(forKey: "igLink") as? String
        self.playlistid = coder.decodeObject(forKey: "playlistid") as? Int
        self.isFav = coder.decodeObject(forKey: "isFav") as? Bool
        self.isDownload = coder.decodeObject(forKey: "isDownload") as? Bool
        self.isRecentlyPlayed = coder.decodeObject(forKey: "isRecentlyPlayed") as? Bool
    }
}

// MARK: - convertToSongModel
extension PodcastObject {
    func convertToSongModel() -> SongModel {
        let songModel = SongModel()
        songModel.trackid = trackid ?? Int("\(trackName ?? "")_\(artistName ?? "")".hashValue & 0x7FFFFFFF)
        songModel.artist = artistName ?? ""
        songModel.track = trackName ?? ""
        songModel.artcover = artcover ?? imageURL?.absoluteString ?? ""
        songModel.artcover_200 = artcover_200 ?? artcover200?.absoluteString ?? ""
        songModel.mediaPath = mediaPath ?? file?.absoluteString ?? ""
        songModel.playcounts = playcounts != nil ? String(playcounts!) : ""
        songModel.likes = likes ?? ""
        songModel.dislikes = dislikes ?? ""
        songModel.composer = composer ?? ""
        songModel.lyricWriter = lyricWriter ?? ""
        songModel.music = music ?? ""
        songModel.dateAdded = dateAdded ?? ""
        songModel.lyric = lyric ?? ""
        songModel.lyric_synced = lyric_synced ?? ""
        songModel.explicit = explicit ?? false
        songModel.allowDownload = allowDownload ?? true
        songModel.ytLink = ytLink ?? ""
        songModel.fbLink = fbLink ?? ""
        songModel.igLink = igLink ?? ""
        songModel.playlistid = playlistid ?? 0
        songModel.isFav = isFav ?? false
        songModel.isDownload = isDownload ?? false
        songModel.isBookMarked = isBookMarked ?? false
        songModel.isRecentlyPlayed = isRecentlyPlayed ?? false
        return songModel
    }
}

extension PodcastObject {
    var thumbnailArtCoverURL: URL? {
        if let artcover_200, !artcover_200.isEmpty, let url = URL(string: artcover_200) {
            return url
        }
        if let artcover200 {
            return artcover200
        }
        if let artcover, !artcover.isEmpty, let url = URL(string: artcover) {
            return url
        }
        return imageURL
    }
}

// MARK: - convertToTrackModel
extension PodcastObject {
    func convertToTrackModel() -> Track {
        return Track(
            trackid: trackid ?? Int("\(trackName ?? "")_\(artistName ?? "")".hashValue & 0x7FFFFFFF),
            artist: artistName,
            track: trackName,
            playcounts: playcounts != nil ? String(playcounts!) : nil,
            likes: likes,
            dislikes: dislikes,
            composer: composer,
            lyricWriter: lyricWriter,
            music: music,
            dateAdded: dateAdded,
            lyric: lyric,
            explicit: explicit,
            allowDownload: allowDownload,
            mediaPath: mediaPath ?? file?.absoluteString,
            artcover: artcover ?? imageURL?.absoluteString,
            artcover_200: artcover_200 ?? artcover200?.absoluteString,
            ytLink: ytLink,
            fbLink: fbLink,
            igLink: igLink,
            playlistid: playlistid,
            lyric_synced: lyric_synced,
            hlsMediaPath: hlsMediaPath
        )
    }
}
