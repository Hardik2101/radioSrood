//
//  ArtistProfileModels.swift
//  Radio Srood
//

import Foundation

struct ArtistProfilesListResponse: Decodable {
    let artistProfilesList: [ArtistProfileSummary]

    enum CodingKeys: String, CodingKey {
        case artistProfilesList = "artist_profiles_list"
    }
}

struct ArtistProfileSummary: Decodable {
    let artistid: String
    let artist: String
    let artistDari: String?
    let playcountsTotal: String?
    let artistPhoto: String

    enum CodingKeys: String, CodingKey {
        case artistid, artist
        case artistDari = "artist_dari"
        case playcountsTotal = "playcounts_total"
        case artistPhoto = "artist_photo"
    }
}

struct ArtistProfileDetailResponse: Decodable {
    let artistProfile: [ArtistProfileDetailContainer]

    enum CodingKeys: String, CodingKey {
        case artistProfile = "artist_profile"
    }

    var detail: ArtistProfileDetailContainer? {
        artistProfile.first
    }
}

struct ArtistProfileDetailContainer: Decodable {
    let artistProfileData: ArtistProfileData
    let artistLatestTrack: Track?
    let artistTopTracks: [Track]?

    enum CodingKeys: String, CodingKey {
        case artistProfileData = "artist_profile_data"
        case artistLatestTrack = "artist_latest_track"
        case artistTopTracks = "artist_top_tracks"
    }
}

struct ArtistProfileData: Decodable {
    let artistid: String
    let artist: String
    let artistDari: String?
    let tracksTotal: String?
    let playcountsTotal: String?
    let likesTotal: String?
    let artistPhoto: String?
    let artistPhoto200: String?
    let artistPhoto700: String?

    enum CodingKeys: String, CodingKey {
        case artistid, artist
        case artistDari = "artist_dari"
        case tracksTotal = "tracks_total"
        case playcountsTotal = "playcounts_total"
        case likesTotal = "likes_total"
        case artistPhoto = "artist_photo"
        case artistPhoto200 = "artist_photo_200"
        case artistPhoto700 = "artist_photo_700"
    }
}
