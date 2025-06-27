//
//  LyricsModel.swift
//  Radio Srood
//
//  Created by Hardik on 27/06/25.
//  Copyright © 2025 Radio Srood Inc. All rights reserved.
//

import Foundation

struct LyricsResponse: Codable {
    let type: String
    let nateja: [LyricsItem]

    enum CodingKeys: String, CodingKey {
        case type
        case nateja = "Nateja"
    }
}

struct LyricsItem: Codable {
    let artistName: String
    let artistID: String
    let artistImage: String
    let trackName: String
    let trackID: String
    let trackCover: String
    let mp3Link: String
    let instrumentalLink: String
    let plainLyrics: String
    let syncedLyrics: String
}
