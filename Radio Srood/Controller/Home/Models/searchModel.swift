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

extension SearchModel {
    func convertToPodcastModel() -> PodcastObject {
        // Build the cover URL
        let coverURL = URL(string: artcover) ?? URL(string: "https://defaultcover.com/placeholder.jpg")!

        // Encode the media path
        if let urlString = mediaPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let fullURL = URL(string: songPath + urlString) {
            return PodcastObject(
                file: fullURL,
                trackName: track,
                artistName: artist,
                imageURL: coverURL,
                trackid: trackid
            )
        }
        // Fallback if songPath is not needed
        else if let fallbackURL = URL(string: mediaPath) {
            return PodcastObject(
                file: fallbackURL,
                trackName: track,
                artistName: artist,
                imageURL: coverURL,
                trackid: trackid
            )
        } else {
            // Last fallback
            return PodcastObject(
                file: URL(string: "https://defaultaudio.com/placeholder.mp3")!,
                trackName: track,
                artistName: artist,
                imageURL: coverURL,
                trackid: trackid
            )
        }
    }
}
