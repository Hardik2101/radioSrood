
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
    case artistProfiles
    case popularMusic
    case newMusic
    case rjtv
    case radio
    case currentRadio
    case recentlyPlay
    
    var title: String {
        switch self {
        case .playlist:
            return "Featured Playlists"
        case .artistProfiles:
            return "Artist Profiles"
        case .newMusic:
            return "Just For You"
        case .popularMusic:
            return "Popular Music"
        case .currentRadio:
            return "Currently Playing on Radio srood"
        case .rjtv:
            return "Srood TV"
        case .radio:
            return "Srood Radio's"
        case .recentlyPlay:
            return "Recently Played"
        }
    }
    
    var toHomeHeader: HomeHeader? {
        switch self {
        case .playlist:
            return .playlists
        case .artistProfiles:
            return nil
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
