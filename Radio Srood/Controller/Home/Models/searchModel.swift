//
//  searchModel.swift
//  Radio Srood
//
//  Created by Hardik on 30/06/25.
//  Copyright © 2025 Radio Srood Inc. All rights reserved.
//

import Foundation

struct SearchModel: Decodable {
    let trackid: Int
    let artist: String
    let track: String
    let likes: String
    let playcounts: String
    let date_added: String
    let mediaPath: String
    let artcover: String
    let artcover_200: String
}

struct SearchResponse: Decodable {
    let Search_Data: [SearchModel]
}

// MARK: - convertToPodcastModel
extension SearchModel {
    func convertToPodcastModel() -> PodcastObject {
        let coverURL = URL(string: artcover)
                    ?? URL(string: "https://defaultcover.com/placeholder.jpg")!

        let fileURL: URL?
        if let urlString = mediaPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let fullURL = URL(string: songPath + urlString) {
            fileURL = fullURL
        } else if let fallbackURL = URL(string: mediaPath) {
            fileURL = fallbackURL
        } else {
            fileURL = URL(string: "https://defaultaudio.com/placeholder.mp3")!
        }

        return PodcastObject(
            file: fileURL,
            mediaPath: mediaPath,
            trackName: track,
            artistName: artist,
            imageURL: coverURL,
            trackid: trackid,
            likes: likes,
            dislikes: nil,          // SearchModel doesn't have this
            playcounts: Double(playcounts),
            dateAdded: date_added,
            artcover: artcover,
            artcover_200: artcover_200,
            isBookMarked: false,
            composer: nil,          // SearchModel doesn't have this
            lyricWriter: nil,       // SearchModel doesn't have this
            music: nil,             // SearchModel doesn't have this
            lyric: nil,             // SearchModel doesn't have this
            lyric_synced: nil,      // SearchModel doesn't have this
            explicit: nil,          // SearchModel doesn't have this
            allowDownload: nil,     // SearchModel doesn't have this
            ytLink: nil,            // SearchModel doesn't have this
            fbLink: nil,            // SearchModel doesn't have this
            igLink: nil,            // SearchModel doesn't have this
            playlistid: nil,        // SearchModel doesn't have this
            isFav: false,
            isDownload: false,
            isRecentlyPlayed: false
        )
    }
}

// MARK: - convertToTrack
extension SearchModel {
    func convertToTrack() -> Track {
        return Track(
            trackid: self.trackid,
            artist: self.artist,
            track: self.track,
            playcounts: self.playcounts,
            likes: self.likes,
            dislikes: nil,          // SearchModel doesn't have this
            composer: nil,          // SearchModel doesn't have this
            lyricWriter: nil,       // SearchModel doesn't have this
            music: nil,             // SearchModel doesn't have this
            dateAdded: self.date_added,
            lyric: nil,             // SearchModel doesn't have this
            explicit: nil,          // SearchModel doesn't have this
            allowDownload: nil,     // SearchModel doesn't have this
            mediaPath: self.mediaPath,
            artcover: self.artcover,
            artcover_200: self.artcover_200,
            ytLink: nil,            // SearchModel doesn't have this
            fbLink: nil,            // SearchModel doesn't have this
            igLink: nil,            // SearchModel doesn't have this
            playlistid: nil,        // SearchModel doesn't have this
            lyric_synced: nil,      // SearchModel doesn't have this
            hlsMediaPath: nil       // SearchModel doesn't have this
        )
    }
}
