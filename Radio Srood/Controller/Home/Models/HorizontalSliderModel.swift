//
//  HorizontalSliderModel.swift
//  Radio Srood
//
//  Created by Hardik Chotaliya on 24/07/24.
//  Copyright © 2024 Appteve. All rights reserved.
//

import UIKit


// To parse the JSON, add this file to your project and do:
//
//   let welcome = try? newJSONDecoder().decode(Welcome.self, from: jsonData)

import Foundation

struct NewSponserModel: Codable {
    let type: String
    let featuredTop: [FeaturedTop]
    let newReleases: [NewReleaseNew]
    let trendingTracks: [TrendingTrackNew]
    let popularTracks: [PopularTrackNew]
    let playlists: [PlaylistNew]
    let featuredArtist: [FeaturedArtistNew]

    enum CodingKeys: String, CodingKey {
        case type
        case featuredTop = "FeaturedTop"
        case newReleases, trendingTracks, popularTracks, playlists, featuredArtist
    }
}

struct FeaturedTop: Codable {
    let featuredType: String
    let featuredID: Int
    let featuredTitle, featuredSubtitle: String
    let featuredSongID: Int?
    let featuredImage: String
    let featuredItem: Track?
    let sponsored: Bool?
    let externalLink: String?

    enum CodingKeys: String, CodingKey {
        case featuredType = "Featured_Type"
        case featuredID = "Featured_ID"
        case featuredTitle = "Featured_Title"
        case featuredSubtitle = "Featured_Subtitle"
        case featuredSongID = "Featured_SongID"
        case featuredImage = "Featured_Image"
        case featuredItem = "Featured_Item"
        case sponsored = "Sponsored"
        case externalLink = "External_link"
    }
}
struct FeaturedArtistNew: Codable {
    let featuredArtist: String
    let featuredTrackID: Int
    let featuredCover: String
    let shomara: Int

    enum CodingKeys: String, CodingKey {
        case featuredArtist, featuredTrackID, featuredCover
        case shomara = "Shomara"
    }
}



struct FeaturedItem: Codable {
    let trackid: Int
    let artist, track, playcounts: String
    let likes: NewReleasesPlayCounts
    let dislikes, composer, lyricWriter, music: String
    let dateAdded, lyric, lyricSynced: String
    let explicit, allowDownload: Bool
    let mediaPath: String
    let artcover: String
    let ytLink, fbLink: String
    let igLink: String

    enum CodingKeys: String, CodingKey {
        case trackid, artist, track, playcounts, likes, dislikes, composer
        case lyricWriter = "lyric_writer"
        case music
        case dateAdded = "date_added"
        case lyric
        case lyricSynced = "lyric_synced"
        case explicit
        case allowDownload = "allow_download"
        case mediaPath, artcover
        case ytLink = "yt_link"
        case fbLink = "fb_link"
        case igLink = "ig_link"
    }
}

enum NewReleasesPlayCounts: String, Codable {
    case the1K = "1K"
}

struct NewReleaseNew: Codable {
    let newReleasesArtist, newReleasesTrack: String
    let newReleasesTrackID: Int
    let newReleasesPlayCounts: NewReleasesPlayCounts
    let allowDownload: Bool
    let newReleasesCover: String
    let newReleasesMP3Path: String
    let shomara: Int

    enum CodingKeys: String, CodingKey {
        case newReleasesArtist, newReleasesTrack, newReleasesTrackID, newReleasesPlayCounts
        case allowDownload = "allow_download"
        case newReleasesCover, newReleasesMP3Path
        case shomara = "Shomara"
    }
}

struct PlaylistNew: Codable {
    let playlist: String
    let createdBy: CreatedBy
    let dateCreated: DateCreated
    let playlistid: Int
    let totalTracks: String
    let playlistPlayCounts: PlaylistPlayCounts
    let playlistLikes: PlaylistLikes
    let allowDownload: Bool
    let playlistCover: String
    let shomara: Int

    enum CodingKeys: String, CodingKey {
        case playlist
        case createdBy = "created_by"
        case dateCreated = "date_created"
        case playlistid, totalTracks, playlistPlayCounts
        case playlistLikes = "playlist_likes"
        case allowDownload = "allow_download"
        case playlistCover
        case shomara = "Shomara"
    }
}

enum CreatedBy: String, Codable {
    case radioSrood = "Radio Srood"
}

enum DateCreated: String, Codable {
    case apr32023 = "Apr 3, 2023"
    case feb22023 = "Feb 2, 2023"
}

enum PlaylistLikes: String, Codable {
    case the1420 = "1,420"
    case the2014 = "2,014"
}

enum PlaylistPlayCounts: String, Codable {
    case the21570 = "21,570"
    case the29104 = "29,104"
}

struct PopularTrackNew: Codable {
    let popularArtist, popularTrack: String
    let popularTrackID: Int
    let popularPlayCounts: String
    let allowDownload: Bool
    let popularCover: String
    let shomara: Int

    enum CodingKeys: String, CodingKey {
        case popularArtist, popularTrack, popularTrackID, popularPlayCounts
        case allowDownload = "allow_download"
        case popularCover
        case shomara = "Shomara"
    }
}

struct TrendingTrackNew: Codable {
    let trendingArtist, trendingTrack: String
    let trendingTrackID: Int
    let trendingPlayCounts: String
    let allowDownload: Bool
    let trendingCover: String
    let shomara: Int

    enum CodingKeys: String, CodingKey {
        case trendingArtist, trendingTrack, trendingTrackID, trendingPlayCounts
        case allowDownload = "allow_download"
        case trendingCover
        case shomara = "Shomara"
    }
}


struct NewFeaturedArtistModles: Codable {
    let featuredData: [NewFeaturedArtistObject]

    enum CodingKeys: String, CodingKey {
        case featuredData = "FeaturedData"
    }
}

// MARK: - FeaturedDatum
struct NewFeaturedArtistObject: Codable {
    let fDid: Int
    let featuredItem: [Track]

    enum CodingKeys: String, CodingKey {
        case fDid = "FDid"
        case featuredItem = "Featured_Item"
    }
}
