//
//  BrowseFeaturedPlaylistModel.swift
//  Radio Srood
//

import Foundation

struct BrowsePlaylistResponse: Decodable {
    let browsePlaylist: [BrowseFeaturedPlaylist]

    enum CodingKeys: String, CodingKey {
        case browsePlaylist = "browse_playlist"
    }
}

struct BrowseFeaturedPlaylist: Decodable {
    let title: String
    let pid: String
    let tracksCount: Int
    let likesCount: String
    let cover: BrowsePlaylistCover

    enum CodingKeys: String, CodingKey {
        case title, pid, cover
        case tracksCount = "tracks_count"
        case likesCount = "likes_count"
    }

    var coverURL: String { cover.medium }

    func toSearchSubPlaylist() -> SearchSubPlaylist {
        SearchSubPlaylist(
            title: title,
            pid: pid,
            tracksCount: tracksCount,
            likesCount: likesCount,
            playCount: likesCount,
            cover: coverURL,
            shared: nil
        )
    }
}

struct BrowsePlaylistCover: Decodable {
    let small: String
    let medium: String
    let large: String
}
