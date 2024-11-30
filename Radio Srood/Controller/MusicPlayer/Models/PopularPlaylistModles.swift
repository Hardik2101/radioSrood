import Foundation

// MARK: - PopularPlaylistModles
struct PopularPlaylistModles: Codable {
    let popularTracks: [PopularPlaylistTrack]
}

// MARK: - PopularTrack
struct PopularPlaylistTrack: Codable {
    let id: Int
    let tracks: [Track]
}

