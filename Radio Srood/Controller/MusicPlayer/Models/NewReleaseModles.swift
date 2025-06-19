import Foundation

// MARK: - NewReleaseModles
struct NewReleaseModles: Codable {
    let newRelease: [NewReleaseObject]
}

// MARK: - NewReleaseObject
struct NewReleaseObject: Codable {
    let id: Int
    let tracks: [Track]
}

// MARK: - Track
struct Track: Codable {
    let trackid: Int?
    let artist, track, playcounts, likes: String?
    let dislikes, composer, lyricWriter, music: String?
    let dateAdded, lyric: String?
    let explicit, allowDownload: Bool?
    let mediaPath: String?
    let artcover: String?
    let ytLink: String?
    let fbLink: String?
    let igLink: String?
    let playlistid: Int?
    let lyric_synced: String?

    enum CodingKeys: String, CodingKey {
        case trackid, artist, track, playcounts, likes, dislikes, composer
        case lyricWriter = "lyric_writer"
        case music
        case dateAdded = "date_added"
        case lyric, explicit
        case allowDownload = "allow_download"
        case mediaPath, artcover
        case ytLink = "yt_link"
        case fbLink = "fb_link"
        case igLink = "ig_link"
        case playlistid
        case lyric_synced
    }

    // ✅ Robust Decoder: handles Int or String for `trackid`
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let intValue = try? container.decode(Int.self, forKey: .trackid) {
            trackid = intValue
        } else if let stringValue = try? container.decode(String.self, forKey: .trackid),
                  let intFromString = Int(stringValue) {
            trackid = intFromString
        } else {
            trackid = nil
        }

        artist = try? container.decode(String.self, forKey: .artist)
        track = try? container.decode(String.self, forKey: .track)
        playcounts = try? container.decode(String.self, forKey: .playcounts)
        likes = try? container.decode(String.self, forKey: .likes)
        dislikes = try? container.decode(String.self, forKey: .dislikes)
        composer = try? container.decode(String.self, forKey: .composer)
        lyricWriter = try? container.decode(String.self, forKey: .lyricWriter)
        music = try? container.decode(String.self, forKey: .music)
        dateAdded = try? container.decode(String.self, forKey: .dateAdded)
        lyric = try? container.decode(String.self, forKey: .lyric)
        explicit = try? container.decode(Bool.self, forKey: .explicit)
        allowDownload = try? container.decode(Bool.self, forKey: .allowDownload)
        mediaPath = try? container.decode(String.self, forKey: .mediaPath)
        artcover = try? container.decode(String.self, forKey: .artcover)
        ytLink = try? container.decode(String.self, forKey: .ytLink)
        fbLink = try? container.decode(String.self, forKey: .fbLink)
        igLink = try? container.decode(String.self, forKey: .igLink)
        playlistid = try? container.decode(Int.self, forKey: .playlistid)
        lyric_synced = try? container.decode(String.self, forKey: .lyric_synced)
    }

    // Convert to internal model
    func convertToSongModel() -> SongModel {
        let song = SongModel()
        song.trackid = self.trackid ?? 0
        song.artist = self.artist ?? ""
        song.track = self.track ?? ""
        song.playcounts = self.playcounts ?? "0"
        song.likes = self.likes ?? "0"
        song.dislikes = self.dislikes ?? "0"
        song.composer = self.composer ?? ""
        song.lyricWriter = self.lyricWriter ?? ""
        song.music = self.music ?? ""
        song.dateAdded = self.dateAdded ?? ""
        song.lyric = self.lyric ?? ""
        song.explicit = self.explicit ?? false
        song.allowDownload = self.allowDownload ?? false
        song.lyric_synced = self.lyric_synced ?? ""
        song.mediaPath = self.mediaPath ?? ""
        song.artcover = self.artcover ?? ""
        song.ytLink = self.ytLink ?? ""
        song.fbLink = self.fbLink ?? ""
        song.igLink = self.igLink ?? ""
        song.playlistid = self.playlistid ?? 0
        song.isFav = false
        song.isBookMarked = false
        song.isRecentlyPlayed = false
        return song
    }
}
