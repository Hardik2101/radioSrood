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

struct SimilarArtist: Decodable {
    let artist: String
    let artistDari: String?
    let artistPhoto: String
    let artistProfileid: String

    enum CodingKeys: String, CodingKey {
        case artist
        case artistDari = "artist_dari"
        case artistPhoto = "artist_photo"
        case artistProfileid = "artist_profileid"
    }
}

enum ArtistProfileSectionContent {
    case tracks([Track])
    case similarArtists([SimilarArtist])
}

struct ArtistProfileSection {
    let key: String
    let title: String
    let content: ArtistProfileSectionContent

    var layout: ArtistProfileSectionLayout {
        ArtistProfileSectionLayout.layout(for: key)
    }

    var tracks: [Track]? {
        if case .tracks(let items) = content { return items }
        return nil
    }

    var similarArtists: [SimilarArtist]? {
        if case .similarArtists(let items) = content { return items }
        return nil
    }

    var itemCount: Int {
        switch content {
        case .tracks(let items): return items.count
        case .similarArtists(let items): return items.count
        }
    }

    var hasMoreItems: Bool {
        switch layout {
        case .listTracks:
            return itemCount > ArtistProfilePage.listPreviewLimit
        case .latestRelease, .carouselTracks, .similarArtists:
            return false
        }
    }
}

enum ArtistProfileSectionLayout {
    case latestRelease
    case carouselTracks
    case listTracks
    case similarArtists

    static func layout(for key: String) -> ArtistProfileSectionLayout {
        switch key {
        case "artist_latest_track":
            return .latestRelease
        case "artist_top_tracks", "artist_trending_tracks", "artist_recent_tracks":
            return .carouselTracks
        case "artist_featured_tracks", "artist_all_tracks":
            return .listTracks
        case "similar_artist":
            return .similarArtists
        default:
            return .listTracks
        }
    }
}

struct ArtistProfilePage {
    static let listPreviewLimit = 5
    static let similarArtistsLimit = 10

    private static let apiSectionOrder = [
        "artist_latest_track",
        "artist_top_tracks",
        "artist_trending_tracks",
        "artist_featured_tracks",
        "artist_recent_tracks",
        "artist_all_tracks",
        "similar_artist"
    ]

    let profileData: ArtistProfileData
    let sections: [ArtistProfileSection]
    let playbackTracks: [Track]

    static func parse(from data: Data) throws -> ArtistProfilePage? {
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let profiles = root["artist_profile"] as? [[String: Any]],
            let container = profiles.first,
            let profileDict = container["artist_profile_data"] as? [String: Any]
        else {
            return nil
        }

        let profileData = try JSONDecoder().decode(
            ArtistProfileData.self,
            from: JSONSerialization.data(withJSONObject: profileDict)
        )

        let orderedKeys = Self.apiSectionOrder.filter { key in
            guard let value = container[key], !(value is NSNull) else { return false }
            return true
        }

        let decoder = JSONDecoder()
        var sections: [ArtistProfileSection] = []
        var playbackTracks: [Track] = []

        for key in orderedKeys {
            guard let value = container[key], !(value is NSNull) else { continue }

            if key == "similar_artist", let array = value as? [[String: Any]] {
                let artists = try decoder.decode(
                    [SimilarArtist].self,
                    from: JSONSerialization.data(withJSONObject: array)
                )
                guard !artists.isEmpty else { continue }
                sections.append(ArtistProfileSection(
                    key: key,
                    title: title(for: key),
                    content: .similarArtists(artists)
                ))
                continue
            }

            if key == "artist_latest_track", let dict = value as? [String: Any] {
                let track = try decoder.decode(
                    Track.self,
                    from: JSONSerialization.data(withJSONObject: dict)
                )
                sections.append(ArtistProfileSection(
                    key: key,
                    title: title(for: key),
                    content: .tracks([track])
                ))
                continue
            }

            if let array = value as? [[String: Any]] {
                let tracks = try decoder.decode(
                    [Track].self,
                    from: JSONSerialization.data(withJSONObject: array)
                )
                guard !tracks.isEmpty else { continue }
                sections.append(ArtistProfileSection(
                    key: key,
                    title: title(for: key),
                    content: .tracks(tracks)
                ))
                if key == "artist_all_tracks" {
                    playbackTracks = tracks
                }
            }
        }

        if playbackTracks.isEmpty {
            playbackTracks = deduplicatedTracks(from: sections)
        }

        return ArtistProfilePage(
            profileData: profileData,
            sections: sections,
            playbackTracks: playbackTracks
        )
    }

    private static func title(for key: String) -> String {
        switch key {
        case "artist_latest_track": return "Latest Releases"
        case "artist_top_tracks": return "Top Tracks"
        case "artist_trending_tracks": return "Trending Now"
        case "artist_featured_tracks": return "Featured in"
        case "artist_recent_tracks": return "Recent Tracks"
        case "artist_all_tracks": return "Tracks"
        case "similar_artist": return "Srood Artists"
        default:
            return key
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }

    private static func deduplicatedTracks(from sections: [ArtistProfileSection]) -> [Track] {
        var seen = Set<Int>()
        var tracks: [Track] = []

        for section in sections {
            guard let sectionTracks = section.tracks else { continue }
            for track in sectionTracks {
                guard let trackID = track.trackid else {
                    tracks.append(track)
                    continue
                }
                guard !seen.contains(trackID) else { continue }
                seen.insert(trackID)
                tracks.append(track)
            }
        }

        return tracks
    }
}

extension Track {
    var artistProfileSubtitle: String {
        var parts: [String] = []
        if let dateAdded, !dateAdded.isEmpty {
            parts.append(ArtistProfileTrackFormatting.displayDate(from: dateAdded))
        }
//        if let playcounts, !playcounts.isEmpty {
//            parts.append("\(playcounts.uppercased()) PLAYS")
//        }
        return parts.joined(separator: " · ")
    }
}

enum ArtistProfileTrackFormatting {
    private static let inputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d-MMM-yy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static let outputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static func displayDate(from value: String) -> String {
        if let date = inputFormatter.date(from: value) {
            return outputFormatter.string(from: date)
        }
        return value
    }
}
