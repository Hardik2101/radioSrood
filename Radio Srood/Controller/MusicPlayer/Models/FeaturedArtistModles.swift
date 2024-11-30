
import Foundation

// MARK: - FeaturedArtistModles
struct FeaturedArtistModles: Codable {
    let rSroodFeaturedArtistData: [RSroodFeaturedArtistDatum]
}

// MARK: - RSroodFeaturedArtistDatum
struct RSroodFeaturedArtistDatum: Codable {
    let id: Int
    let artistInformation: ArtistInformation
    let tracks: [Track]

    enum CodingKeys: String, CodingKey {
        case id
        case artistInformation = "artist_information"
        case tracks
    }
}

// MARK: - ArtistInformation
struct ArtistInformation: Codable {
    let artist, featureMessage, dateFeatured, totalTracks: String
    let artistMonthlyPlays, artistTotalLikes, artistTotalPlays, artistRank: String
    let allowDownload: Bool
    let featuredCover: String

    enum CodingKeys: String, CodingKey {
        case artist
        case featureMessage = "feature_message"
        case dateFeatured = "date_featured"
        case totalTracks = "total_tracks"
        case artistMonthlyPlays = "artist_monthly_plays"
        case artistTotalLikes = "artist_total_likes"
        case artistTotalPlays = "artist_total_plays"
        case artistRank = "artist_rank#"
        case allowDownload = "allow_download"
        case featuredCover = "featured_cover"
    }
}
