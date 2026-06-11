import Foundation

class SongModel: NSObject, NSCoding {
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
    var artcover_200: String = ""
    var ytLink: String = ""
    var fbLink: String = ""
    var igLink: String = ""
    var playlistid: Int = 0
    var isFav: Bool = false
    var isDownload: Bool = false
    var isBookMarked: Bool = false
    var isRecentlyPlayed: Bool = false
    var lyric_synced: String = ""

    override init() {
        super.init()
    }

    // MARK: - NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(trackid, forKey: "trackid")
        aCoder.encode(artist, forKey: "artist")
        aCoder.encode(track, forKey: "track")
        aCoder.encode(playcounts, forKey: "playcounts")
        aCoder.encode(likes, forKey: "likes")
        aCoder.encode(dislikes, forKey: "dislikes")
        aCoder.encode(composer, forKey: "composer")
        aCoder.encode(lyricWriter, forKey: "lyricWriter")
        aCoder.encode(music, forKey: "music")
        aCoder.encode(dateAdded, forKey: "dateAdded")
        aCoder.encode(lyric, forKey: "lyric")
        aCoder.encode(explicit, forKey: "explicit")
        aCoder.encode(allowDownload, forKey: "allowDownload")
        aCoder.encode(mediaPath, forKey: "mediaPath")
        aCoder.encode(artcover, forKey: "artcover")
        aCoder.encode(artcover_200, forKey: "artcover_200")
        aCoder.encode(ytLink, forKey: "ytLink")
        aCoder.encode(fbLink, forKey: "fbLink")
        aCoder.encode(igLink, forKey: "igLink")
        aCoder.encode(playlistid, forKey: "playlistid")
        aCoder.encode(isFav, forKey: "isFav")
        aCoder.encode(isDownload, forKey: "isDownload")
        aCoder.encode(isBookMarked, forKey: "isBookMarked")
        aCoder.encode(isRecentlyPlayed, forKey: "isRecentlyPlayed")
        aCoder.encode(lyric_synced, forKey: "lyric_synced")
    }

    required convenience init(coder aDecoder: NSCoder) {
        self.init()
        trackid = aDecoder.decodeInteger(forKey: "trackid")
        artist = aDecoder.decodeObject(forKey: "artist") as? String ?? ""
        track = aDecoder.decodeObject(forKey: "track") as? String ?? ""
        playcounts = aDecoder.decodeObject(forKey: "playcounts") as? String ?? ""
        likes = aDecoder.decodeObject(forKey: "likes") as? String ?? ""
        dislikes = aDecoder.decodeObject(forKey: "dislikes") as? String ?? ""
        composer = aDecoder.decodeObject(forKey: "composer") as? String ?? ""
        lyricWriter = aDecoder.decodeObject(forKey: "lyricWriter") as? String ?? ""
        music = aDecoder.decodeObject(forKey: "music") as? String ?? ""
        dateAdded = aDecoder.decodeObject(forKey: "dateAdded") as? String ?? ""
        lyric = aDecoder.decodeObject(forKey: "lyric") as? String ?? ""
        explicit = aDecoder.decodeBool(forKey: "explicit")
        allowDownload = aDecoder.decodeBool(forKey: "allowDownload")
        mediaPath = aDecoder.decodeObject(forKey: "mediaPath") as? String ?? ""
        artcover = aDecoder.decodeObject(forKey: "artcover") as? String ?? ""
        artcover_200 = aDecoder.decodeObject(forKey: "artcover_200") as? String ?? ""
        ytLink = aDecoder.decodeObject(forKey: "ytLink") as? String ?? ""
        fbLink = aDecoder.decodeObject(forKey: "fbLink") as? String ?? ""
        igLink = aDecoder.decodeObject(forKey: "igLink") as? String ?? ""
        playlistid = aDecoder.decodeInteger(forKey: "playlistid")
        isFav = aDecoder.decodeBool(forKey: "isFav")
        isDownload = aDecoder.decodeBool(forKey: "isDownload")
        isBookMarked = aDecoder.decodeBool(forKey: "isBookMarked")
        isRecentlyPlayed = aDecoder.decodeBool(forKey: "isRecentlyPlayed")
        lyric_synced = aDecoder.decodeObject(forKey: "lyric_synced") as? String ?? ""
    }

    // MARK: - Dictionary Initializers
    convenience init?(dictionary: NSDictionary) {
        self.init()
        self.trackid = dictionary["trackid"] as? Int ?? 0
        self.artist = dictionary["currentArtist"] as? String ?? ""
        self.track = dictionary["currentTrack"] as? String ?? ""
        self.playcounts = dictionary["playcounts"] as? String ?? ""
        self.likes = dictionary["likes"] as? String ?? ""
        self.dislikes = dictionary["dislikes"] as? String ?? ""
        self.composer = dictionary["composer"] as? String ?? ""
        self.lyricWriter = dictionary["lyricWriter"] as? String ?? ""
        self.music = dictionary["music"] as? String ?? ""
        self.dateAdded = dictionary["dateAdded"] as? String ?? ""
        self.lyric = dictionary["lyric"] as? String ?? ""
        self.explicit = dictionary["explicit"] as? Bool ?? false
        self.allowDownload = dictionary["allowDownload"] as? Bool ?? false
        self.mediaPath = dictionary["mediaPath"] as? String ?? ""
        self.artcover = dictionary["artcover"] as? String ?? ""
        self.artcover_200 = dictionary["artcover_200"] as? String ?? ""
        self.ytLink = dictionary["ytLink"] as? String ?? ""
        self.fbLink = dictionary["fbLink"] as? String ?? ""
        self.igLink = dictionary["igLink"] as? String ?? ""
        self.playlistid = dictionary["playlistid"] as? Int ?? 0
        self.isFav = dictionary["isFav"] as? Bool ?? false
        self.isDownload = dictionary["isDownload"] as? Bool ?? false
        self.isBookMarked = dictionary["isBookMarked"] as? Bool ?? false
        self.isRecentlyPlayed = dictionary["isRecentlyPlayed"] as? Bool ?? false
        self.lyric_synced = dictionary["lyric_synced"] as? String ?? ""
    }

    convenience init?(recentItem: NSDictionary) {
        self.init()
        self.trackid = recentItem["recentTrackID"] as? Int ?? 0
        self.track = recentItem["recentTrack"] as? String ?? ""
        self.artist = recentItem["recentArtist"] as? String ?? ""
        self.artcover = recentItem["recentArtCover"] as? String ?? ""
        self.artcover_200 = recentItem["recentArtCover_200"] as? String
            ?? recentItem["artcover_200"] as? String ?? ""
        self.mediaPath = recentItem["mediaPathInfo"] as? String ?? ""
        self.lyric = recentItem["recentLyric"] as? String ?? ""
        self.allowDownload = (recentItem["allow_download"] as? Int == 1)
        self.isRecentlyPlayed = true
    }

    convenience init?(currentTrack: NSDictionary) {
        self.init()
        self.trackid = currentTrack["currentTrackID"] as? Int ?? 0
        self.track = currentTrack["currentTrack"] as? String ?? ""
        self.artist = currentTrack["currentArtist"] as? String ?? ""
        self.artcover = currentTrack["currentArtCover"] as? String ?? ""
        self.artcover_200 = currentTrack["currentArtCover_200"] as? String
            ?? currentTrack["artcover_200"] as? String ?? ""
        self.mediaPath = currentTrack["mediaPathInfo"] as? String ?? ""
        self.lyric = currentTrack["currentLyricInfo"] as? String ?? ""
        self.playcounts = currentTrack["currentPlayCounts"] as? String ?? ""
        self.likes = currentTrack["currentSongLikes"] as? String ?? ""
        self.dateAdded = currentTrack["DateTrackAddedInfo"] as? String ?? ""
        self.allowDownload = (currentTrack["allow_download"] as? Int == 1)
        self.lyric_synced = currentTrack["lyric_synced"] as? String ?? ""
    }

    // MARK: - Convert to Podcast
        func convertToPodcastModel() -> PodcastObject {
            let coverURL = URL(string: artcover) ?? URL(string: "https://defaultcover.com/placeholder.jpg")!

            let fileURL: URL?
            if let urlString = mediaPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let fullURL = URL(string: songPath + urlString) {
                fileURL = fullURL
            } else if let fallbackURL = URL(string: mediaPath) {
                fileURL = fallbackURL
            } else {
                fileURL = URL(string: "https://defaultaudio.com/placeholder.mp3")!
            }

            return PodcastObject(
                file: fileURL,
                mediaPath: mediaPath,
                trackName: track,
                artistName: artist,
                imageURL: coverURL,
                trackid: trackid,
                likes: likes,
                dislikes: dislikes,
                playcounts: Double(playcounts),
                dateAdded: dateAdded,
                artcover: artcover,
                artcover_200: artcover_200.isEmpty ? nil : artcover_200,
                isBookMarked: isBookMarked,
                composer: composer,
                lyricWriter: lyricWriter,
                music: music,
                lyric: lyric,
                lyric_synced: lyric_synced,
                explicit: explicit,
                allowDownload: allowDownload,
                ytLink: ytLink,
                fbLink: fbLink,
                igLink: igLink,
                playlistid: playlistid,
                isFav: isFav,
                isDownload: isDownload,
                isRecentlyPlayed: isRecentlyPlayed
            )
        }

    // MARK: - Debug Description
    override var description: String {
        return "SongModel(trackid: \(trackid), track: \(track), artist: \(artist), isFav: \(isFav), isDownload: \(isDownload))"
    }

    var thumbnailArtCoverURL: URL? {
        if !artcover_200.isEmpty, let url = URL(string: artcover_200) {
            return url
        }
        if !artcover.isEmpty, let url = URL(string: artcover) {
            return url
        }
        return nil
    }
}
