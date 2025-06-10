//
//  TodayTopPicModel.swift
//  Radio Srood
//
//  Created by Hardik on 28/05/25.
//  Copyright © 2025 Radio Srood Inc. All rights reserved.
//

import UIKit
import Foundation

struct TodayPickModel: Decodable {
    let type: String
    let items: [RadioSuroodTodayPickItem]

    enum CodingKeys: String, CodingKey {
        case type
        case items = "Today_Top_Pick"
    }
}

struct RadioSuroodTodayPickItem: Decodable, Identifiable {
    let TTPArtist: String
    let TTPTrack: String
    let TTPID: Int
    let TTPCover: String
    let Shomara: Int

    var id: Int { TTPID }
}


struct TodayTopPickPlaylistModel: Decodable {
    let todayTopPick: [PlaylistTTP]

    enum CodingKeys: String, CodingKey {
        case todayTopPick = "Today_Top_Pick_Playlist"
    }
}


struct PlaylistTTP: Decodable {
    let playlistID: Int
    let tracks: [Track]
}


