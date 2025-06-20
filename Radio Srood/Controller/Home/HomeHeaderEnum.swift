
import UIKit

enum HomeHeader: Int, CaseIterable {
    case featured
    case recentlyAdded
    case todayTopPic
    case hotTrackes
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
        case .recentlyAdded:
            return "Recently Added"
        case .todayTopPic:
            return "Today Top Picks"
        case .hotTrackes:
            return "Hot Tracks"
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
    case currentRadio
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
        case .currentRadio:
            return "Currently Playing on Radio srood"
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
            return .hotTrackes
        case .popularMusic:
            return .popularTracks
        case .currentRadio:
            return .currentRadio
        case .rjtv:
            return nil
        case .radio:
            return .currentRadio
        case .recentlyPlay:
            return .recentlyPlayed
        }
    }
}
