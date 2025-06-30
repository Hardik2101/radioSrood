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
