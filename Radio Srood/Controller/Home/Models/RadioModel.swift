//
//  RadioModel.swift
//  Radio Srood
//
//  Created by Hardik on 18/10/24.
//  Copyright © 2024 Radio Srood Inc. All rights reserved.
//

import Foundation


struct RadioModel: Codable {
    let type: String
    let radio: [RadioModelData]

    enum CodingKeys: String, CodingKey {
        case type
        case radio = "Radio"
    }
}

// MARK: - Radio
struct RadioModelData: Codable {
    let radioID: Int
    let radioTitle: String
    let radioStreamLink: String
    let radioImage: String

    enum CodingKeys: String, CodingKey {
        case radioID = "Radio_ID"
        case radioTitle = "Radio_Title"
        case radioStreamLink = "Radio_Stream_Link"
        case radioImage = "Radio_Image"
    }
}
