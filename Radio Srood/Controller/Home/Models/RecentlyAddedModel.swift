//
//  RecentlyAddedModel.swift
//  Radio Srood
//
//  Created by Hardik on 12/06/25.
//  Copyright © 2025 Radio Srood Inc. All rights reserved.
//

import UIKit
import Foundation

struct RecentlyAddedModel: Decodable {
    let type: String
    let items: [RecentlyAdded]

    enum CodingKeys: String, CodingKey {
        case type
        case items = "Recently_Added"
    }
}

struct RecentlyAdded: Decodable, Identifiable {
    let RAArtist: String
    let RATrack: String
    let RAID: Int
    let RACover: String
    let Shomara: Int

    var id: Int { RAID }
}


struct RecentlyAddedPlaylist: Codable {
    let recentlyAddedPlayListDetailed: [RecentlyAddedPlayListDetailed]

    enum CodingKeys: String, CodingKey {
        case recentlyAddedPlayListDetailed = "Recently_Added_Playlist"
    }
}

struct RecentlyAddedPlayListDetailed: Codable {
    let playlistID: Int
    let tracks: [Track]

    enum CodingKeys: String, CodingKey {
        case playlistID = "PlaylistID"
        case tracks
    }
}


