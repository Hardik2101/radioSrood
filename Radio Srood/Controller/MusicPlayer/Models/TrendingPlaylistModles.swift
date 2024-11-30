
import Foundation

// MARK: - TrendingPlaylistModles
struct TrendingPlaylistModles: Codable {
    let trendingTracks: [TrendingPlaylist]
}

// MARK: - TrendingPlaylist
struct TrendingPlaylist: Codable {
    let id: Int
    let playlistInfo: PlaylistInfo?
    let tracks: [Track]
}

// MARK: - PlaylistInfo
struct PlaylistInfo: Codable {
    let playlist: String
    let createdBy: String
    let dateCreated: String
    let totalTracks: String
    let playlistPlayCounts: String
    let playlistLikes: String
    let allowDownload: Bool
    let playlistCover: String

    enum CodingKeys: String, CodingKey {
        case playlist
        case createdBy = "created_by"
        case dateCreated = "date_created"
        case totalTracks, playlistPlayCounts
        case playlistLikes = "playlist_likes"
        case allowDownload = "allow_download"
        case playlistCover
    }
}
