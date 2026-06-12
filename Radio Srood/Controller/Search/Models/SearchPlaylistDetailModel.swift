//
//  SearchPlaylistDetailModel.swift
//  Radio Srood
//

import Foundation

struct SearchPlaylistDetailResponse: Decodable {
    let subPlaylist: [SearchPlaylistDetailItem]

    enum CodingKeys: String, CodingKey {
        case subPlaylist = "sub_playlist"
    }

    var playlist: SearchPlaylistDetailItem? {
        subPlaylist.first
    }
}

struct SearchPlaylistDetailItem: Decodable {
    let pid: String
    let info: SearchPlaylistInfo
    let tracks: [Track]
}

struct SearchPlaylistInfo: Decodable {
    let title: String
    let tracksCount: Int
    let likesCount: String
    let playCount: String
    let cover: String

    enum CodingKeys: String, CodingKey {
        case title, cover
        case tracksCount = "tracks_count"
        case likesCount = "likes_count"
        case playCount = "play_count"
    }
}

extension Track {
    func convertToPodcastModel() -> PodcastObject {
        convertToSongModel().convertToPodcastModel()
    }
}
