import Foundation

// MARK: - HomeMusicModles
struct HomeMusicModles: Codable {
    let type: String
    let newReleases: [NewRelease]
    let trendingTracks: [TrendingTrack]
    let popularTracks: [PopularTrack]
    let playlists: [Playlist]
    let featuredArtist: [FeaturedArtist]
}

// MARK: - FeaturedArtist
struct FeaturedArtist: Codable {
    let featuredArtist: String
    let featuredTrackID: Int
    let featuredCover: String
    let shomara: Int

    enum CodingKeys: String, CodingKey {
        case featuredArtist, featuredTrackID, featuredCover
        case shomara = "Shomara"
    }
}

// MARK: - NewRelease
struct NewRelease: Codable {
    let newReleasesArtist, newReleasesTrack: String
    let newReleasesTrackID: Int
    let newReleasesPlayCounts: String
    let allowDownload: Bool
    let newReleasesCover: String
    let newReleasesMP3Path: String
    let shomara: Int

    enum CodingKeys: String, CodingKey {
        case newReleasesArtist, newReleasesTrack, newReleasesTrackID, newReleasesPlayCounts
        case allowDownload = "allow_download"
        case newReleasesCover, newReleasesMP3Path
        case shomara = "Shomara"
    }
}

// MARK: - Playlist
struct Playlist: Codable {
    let playlist: String
    let createdBy: String
    let dateCreated: String
    let playlistid: Int
    let totalTracks: String
    let playlistPlayCounts: String
    let playlistLikes: String
    let allowDownload: Bool
    let playlistCover: String
    let shomara: Int
    let playlistName: String?

    enum CodingKeys: String, CodingKey {
        case playlist
        case createdBy = "created_by"
        case dateCreated = "date_created"
        case playlistid, totalTracks, playlistPlayCounts
        case playlistLikes = "playlist_likes"
        case allowDownload = "allow_download"
        case playlistCover
        case shomara = "Shomara"
        case playlistName
    }
}

// MARK: - PopularTrack
struct PopularTrack: Codable {
    let popularArtist, popularTrack: String
    let popularTrackID: Int
    let popularPlayCounts: String
    let allowDownload: Bool
    let popularCover: String
    let shomara: Int

    enum CodingKeys: String, CodingKey {
        case popularArtist, popularTrack, popularTrackID, popularPlayCounts
        case allowDownload = "allow_download"
        case popularCover
        case shomara = "Shomara"
    }
}

// MARK: - TrendingTrack
struct TrendingTrack: Codable {
    let trendingArtist, trendingTrack: String
    let trendingTrackID: Int
    let trendingPlayCounts: String
    let allowDownload: Bool
    let trendingCover: String
    let shomara: Int

    enum CodingKeys: String, CodingKey {
        case trendingArtist, trendingTrack, trendingTrackID, trendingPlayCounts
        case allowDownload = "allow_download"
        case trendingCover
        case shomara = "Shomara"
    }
}

// MARK: - currentLyricData
struct CurrentLyricDataModle: Codable {
    let type: String
    let currentTrackInfo: CurrentTrackInfo
}

// MARK: - CurrentTrackInfo
struct CurrentTrackInfo: Codable {
    let currentArtistInfo, currentTrackInfo: String
    let currentTrackID, currentPlayCountsInfo: Int
    let songLastPlayedInfo, dateTrackAddedInfo, artistRecentPlayedInfo, socialMediaLinkInfo1: String
    let socialMediaLinkInfo2, upComingConcertInfo, artistMusicComposerInfo, artistLyricWriterInfo: String
    let currentArtCoverInfo: String
    let comingNextInfo, currentLyricInfo, mediaPathInfo: String

    enum CodingKeys: String, CodingKey {
        case currentArtistInfo, currentTrackInfo, currentTrackID, currentPlayCountsInfo
        case songLastPlayedInfo = "SongLastPlayedInfo"
        case dateTrackAddedInfo = "DateTrackAddedInfo"
        case artistRecentPlayedInfo = "ArtistRecentPlayedInfo"
        case socialMediaLinkInfo1 = "SocialMediaLinkInfo1"
        case socialMediaLinkInfo2 = "SocialMediaLinkInfo2"
        case upComingConcertInfo = "UpComingConcertInfo"
        case artistMusicComposerInfo = "ArtistMusicComposerInfo"
        case artistLyricWriterInfo = "ArtistLyricWriterInfo"
        case currentArtCoverInfo, comingNextInfo, currentLyricInfo, mediaPathInfo
    }

    /// Builds track info from `currentsongappv2.json` `currentTrack` (or legacy `currentTrackInfo`) payload.
    init?(dictionary: NSDictionary) {
        let artist = dictionary["currentArtist"] as? String
            ?? dictionary["currentArtistInfo"] as? String
        let track = dictionary["currentTrack"] as? String
            ?? dictionary["currentTrackInfo"] as? String
        guard let artist, let track else { return nil }

        currentArtistInfo = artist
        currentTrackInfo = track
        currentTrackID = dictionary["currentTrackID"] as? Int ?? 0
        currentPlayCountsInfo = dictionary["currentPlayCounts"] as? Int
            ?? dictionary["currentPlayCountsInfo"] as? Int ?? 0
        songLastPlayedInfo = dictionary["SongLastPlayedInfo"] as? String ?? ""
        dateTrackAddedInfo = dictionary["DateTrackAddedInfo"] as? String ?? ""
        artistRecentPlayedInfo = dictionary["ArtistRecentPlayedInfo"] as? String ?? ""
        socialMediaLinkInfo1 = dictionary["SocialMediaLinkInfo1"] as? String ?? ""
        socialMediaLinkInfo2 = dictionary["SocialMediaLinkInfo2"] as? String ?? ""
        upComingConcertInfo = dictionary["UpComingConcertInfo"] as? String ?? ""
        artistMusicComposerInfo = dictionary["ArtistMusicComposerInfo"] as? String ?? ""
        artistLyricWriterInfo = dictionary["ArtistLyricWriterInfo"] as? String ?? ""
        currentArtCoverInfo = dictionary["currentArtCover"] as? String
            ?? dictionary["currentArtCoverInfo"] as? String ?? ""
        comingNextInfo = dictionary["comingNextInfo"] as? String ?? ""
        currentLyricInfo = dictionary["currentLyricInfo"] as? String ?? ""
        mediaPathInfo = dictionary["mediaPathInfo"] as? String ?? ""
    }
}

extension CurrentLyricDataModle {
    /// Builds the home-screen model from `currentsongappv2.json`.
    static func from(radioData: NSDictionary) -> CurrentLyricDataModle? {
        let trackDictionary = (radioData["currentTrack"] as? NSDictionary)
            ?? (radioData["currentTrackInfo"] as? NSDictionary)
        guard let trackDictionary, let trackInfo = CurrentTrackInfo(dictionary: trackDictionary) else {
            return nil
        }
        return CurrentLyricDataModle(
            type: radioData["type"] as? String ?? "currentData",
            currentTrackInfo: trackInfo
        )
    }
}

enum RadioCurrentSongMapper {
    /// Maps `currentsongappv2.json` `currentTrack` to the legacy `currentTrackInfo` dictionary shape.
    static func legacyCurrentTrackInfo(from currentTrack: NSDictionary) -> NSDictionary {
        [
            "currentArtistInfo": currentTrack["currentArtist"] ?? currentTrack["currentArtistInfo"] ?? "",
            "currentTrackInfo": currentTrack["currentTrack"] ?? currentTrack["currentTrackInfo"] ?? "",
            "currentTrackID": currentTrack["currentTrackID"] ?? 0,
            "currentPlayCountsInfo": currentTrack["currentPlayCounts"] ?? currentTrack["currentPlayCountsInfo"] ?? 0,
            "SongLastPlayedInfo": currentTrack["SongLastPlayedInfo"] ?? "",
            "DateTrackAddedInfo": currentTrack["DateTrackAddedInfo"] ?? "",
            "ArtistRecentPlayedInfo": currentTrack["ArtistRecentPlayedInfo"] ?? "",
            "SocialMediaLinkInfo1": currentTrack["SocialMediaLinkInfo1"] ?? "",
            "SocialMediaLinkInfo2": currentTrack["SocialMediaLinkInfo2"] ?? "",
            "UpComingConcertInfo": currentTrack["UpComingConcertInfo"] ?? "",
            "ArtistMusicComposerInfo": currentTrack["ArtistMusicComposerInfo"] ?? "",
            "ArtistLyricWriterInfo": currentTrack["ArtistLyricWriterInfo"] ?? "",
            "currentArtCoverInfo": currentTrack["currentArtCover"] ?? currentTrack["currentArtCoverInfo"] ?? "",
            "comingNextInfo": currentTrack["comingNextInfo"] ?? "",
            "currentLyricInfo": currentTrack["currentLyricInfo"] ?? "",
            "mediaPathInfo": currentTrack["mediaPathInfo"] ?? "",
            "currentSongLikes": currentTrack["currentSongLikes"] ?? 0
        ] as NSDictionary
    }

    /// Wraps mapped track info for screens that expect `{ currentTrackInfo: ... }`.
    static func legacyLyricDataPayload(from radioData: NSDictionary) -> NSDictionary? {
        guard let currentTrack = radioData["currentTrack"] as? NSDictionary else { return nil }
        return ["currentTrackInfo": legacyCurrentTrackInfo(from: currentTrack)] as NSDictionary
    }

    /// Maps a recently played item to the legacy more-info payload shape.
    static func legacyLyricDataPayload(fromRecentItem item: NSDictionary) -> NSDictionary {
        let mapped: [String: Any] = [
            "currentArtistInfo": item["recentArtist"] ?? "",
            "currentTrackInfo": item["recentTrack"] ?? "",
            "currentTrackID": item["recentTrackID"] ?? 0,
            "currentArtCoverInfo": item["recentArtCover"] ?? "",
            "mediaPathInfo": item["mediaPathInfo"] ?? "",
            "currentLyricInfo": item["recentLyric"] ?? ""
        ]
        return ["currentTrackInfo": mapped] as NSDictionary
    }
}

extension TrendingTrack {
    func asNewRelease() -> NewRelease {
        NewRelease(
            newReleasesArtist: trendingArtist,
            newReleasesTrack: trendingTrack,
            newReleasesTrackID: trendingTrackID,
            newReleasesPlayCounts: trendingPlayCounts,
            allowDownload: allowDownload,
            newReleasesCover: trendingCover,
            newReleasesMP3Path: "",
            shomara: shomara
        )
    }
}

extension PopularTrack {
    func asNewRelease() -> NewRelease {
        NewRelease(
            newReleasesArtist: popularArtist,
            newReleasesTrack: popularTrack,
            newReleasesTrackID: popularTrackID,
            newReleasesPlayCounts: popularPlayCounts,
            allowDownload: allowDownload,
            newReleasesCover: popularCover,
            newReleasesMP3Path: "",
            shomara: shomara
        )
    }
}
