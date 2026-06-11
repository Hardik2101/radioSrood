//
//  SearchPlaylistCategoryModel.swift
//  Radio Srood
//

import UIKit

struct SearchBrowseAllResponse: Decodable {
    let playlistCategories: [SearchPlaylistCategory]
    let subCategories: [SearchSubCategoryGroup]
    let updatedAt: Int?

    enum CodingKeys: String, CodingKey {
        case playlistCategories = "playlist_categories"
        case subCategories = "sub_categories"
        case updatedAt = "updated_at"
    }
}

struct SearchPlaylistCategory: Decodable {
    let title: String
    let categoryCover: String

    enum CodingKeys: String, CodingKey {
        case title
        case categoryCover = "category_cover"
    }

    func backgroundColor(at index: Int) -> UIColor {
        SearchPlaylistCategory.palette[index % SearchPlaylistCategory.palette.count]
    }

    private static let palette: [UIColor] = [
        UIColor(red: 0.93, green: 0.58, blue: 0.30, alpha: 1.0),
        UIColor(red: 0.83, green: 0.18, blue: 0.18, alpha: 1.0),
        UIColor(red: 0.85, green: 0.25, blue: 0.55, alpha: 1.0),
        UIColor(red: 0.90, green: 0.70, blue: 0.15, alpha: 1.0),
        UIColor(red: 0.80, green: 0.45, blue: 0.25, alpha: 1.0),
        UIColor(red: 0.45, green: 0.25, blue: 0.75, alpha: 1.0),
        UIColor(red: 0.25, green: 0.55, blue: 0.85, alpha: 1.0),
        UIColor(red: 0.85, green: 0.30, blue: 0.35, alpha: 1.0),
        UIColor(red: 0.20, green: 0.65, blue: 0.45, alpha: 1.0),
        UIColor(red: 0.55, green: 0.35, blue: 0.75, alpha: 1.0)
    ]
}

struct SearchSubCategoryGroup: Decodable {
    let playlistTitle: String
    let subPlaylist: [SearchSubPlaylist]

    enum CodingKeys: String, CodingKey {
        case playlistTitle = "playlist_title"
        case subPlaylist = "sub_playlist"
    }
}

struct SearchSubPlaylist: Decodable {
    let title: String
    let pid: String
    let tracksCount: Int
    let likesCount: String
    let playCount: String
    let cover: String
    let shared: Bool?

    enum CodingKeys: String, CodingKey {
        case title, pid, cover, shared
        case tracksCount = "tracks_count"
        case likesCount = "likes_count"
        case playCount = "play_count"
    }
}
