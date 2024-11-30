
import UIKit

enum HomeHeader: Int, CaseIterable {
    case featured
    case newReleases
    case currentRadio
    case trending
    case popularTracks
    case playlists
    case myPlaylist
    case recentlyPlayed
    case featuredArtist
    
    var title: String {
        switch self {
        case .featured:
            return "Featured"
        case .newReleases:
            return "New Releases"
        case .currentRadio:
            return "Currently Playing on Radio srood"
        case .trending:
            return "Trending"
        case .popularTracks:
            return "Popular Tracks"
        case .playlists:
            return "Playlists"
        case .myPlaylist:
            return "My Playlist"
        case .recentlyPlayed:
            return "Recently Played"
        case .featuredArtist:
            return "Featured Artist"
        }
    }
}


enum Browseheader: Int, CaseIterable {
    case playlist
    case newMusic
    case popularMusic
    case rjtv
    case radio
    case recentlyPlay
    
    var title: String {
        switch self {
        case .playlist:
            return "PlayList"
        case .newMusic:
            return "New Music"
        case .popularMusic:
            return "Popular Music"
        case .rjtv:
            return "SROOD TV"
        case .radio:
            return "Radio"
        case .recentlyPlay:
            return "Recently Played"
        }
    }
    
    var toHomeHeader: HomeHeader? {
        switch self {
        case .playlist:
            return .playlists
        case .newMusic:
            return .newReleases
        case .popularMusic:
            return .popularTracks
        case .rjtv:
            return nil
        case .radio:
            return .currentRadio
        case .recentlyPlay:
            return .recentlyPlayed
        }
    }
}
