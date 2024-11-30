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
}
