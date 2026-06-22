
import UIKit

let BASE_BACKEND_URL =  "https://api.app.scdn.stream/rSroodMainRadioData.json" // your  backend
let baseURL = "https://radiosrood.com/api/"
let recentListURL = baseURL + "currentsongappv2.json"
let songPath = "https://mediahost.srood.stream/media/mp3/"
let hlsSongPath = "https://mediahost.srood.stream/media/hls/"
let musicBaseUrl = "https://api.app.scdn.stream/"
let redioHomeURL = musicBaseUrl + "rSroodMusicPageData.json"
let newReleaseURL = musicBaseUrl + "newRelease.json"
let trendingPlaylistURL = musicBaseUrl + "trendingTracks.json"
let popularPlaylistURL = musicBaseUrl + "popularTracks.json"
let playlistURL = musicBaseUrl + "rSroodPlaylistData.json"
let featuredArtistURL = musicBaseUrl + "rSroodFeaturedArtistData.json"
let lyricsURL = "https://api.app.scdn.stream/lyrics/"
let homeSponserURL = "https://api.app.scdn.stream/rSroodMusicPageData.json"
let homeSponserURL1 = "https://api.app.scdn.stream/FeaturedData.json"

let todayPickURLDetailed = "https://api.app.srood.stream/jostojo?v=today_top_pick&api_key=3bXcLWToFQkTDBqyknaediavkmTwW"
let todayPickURL = "https://api.app.srood.stream/TodayTopPicksData.json"

let recentlyAdded = "https://api.app.scdn.stream/RecentlyAddedData.json"
let recentlyAddedDetailed = "https://api.app.scdn.stream/SroodRecentlyAdded-2jPol5W34knjMkdi3.json"

let featuredRadio = musicBaseUrl + "FeaturedRadio.json"


let lyricsBaseURL = "https://lyric.srood.stream/jostojo"
let searchBaseURL = "https://search.srood.stream/jostojo"
let searchBrowseAllURL = musicBaseUrl + "playlists/Srood-Playlist-All-SgRtObOwDD5ptU3Z8efiVEj5EBWIoVklO9.json"
let browseFeaturedPlaylistsURL = musicBaseUrl + "playlists/Srood-Playlist-Browse-YHe1olYrAiOdgqDI6xN.json"
let artistProfilesListURL = musicBaseUrl + "artist_profiles/srood_artist_ids-SsRsOJOYDoPVw6RcgarlMpdh4UPK8Yask1kj1lxdoj25.json"

func searchPlaylistURL(pid: String) -> String {
    musicBaseUrl + "playlists/\(pid).json"
}

func artistProfileURL(artistID: String) -> String {
    musicBaseUrl + "artist_profiles/\(artistID).json"
}

let SHOW_BANNER_ADMOB                =     true // true - show ads, false - not

// MARK: - AdMob (DEBUG = Google test units, RELEASE = production units)

enum AdMobUnit {
    case bannerKey
    case interstitial
    case native
    case miniPlayer
    case musicPlayer

    fileprivate static var isEnabled: Bool {
        SHOW_BANNER_ADMOB && !IAPHandler.shared.isGetPurchase()
    }

    var adUnitID: String {
        guard AdMobUnit.isEnabled else { return "" }
        #if DEBUG
        return debugAdUnitID
        #else
        return releaseAdUnitID
        #endif
    }

    private var debugAdUnitID: String {
        switch self {
        case .bannerKey, .miniPlayer, .musicPlayer:
            return "ca-app-pub-3940256099942544/2934735716"
        case .interstitial:
            return "ca-app-pub-3940256099942544/4411468910"
        case .native:
            return "ca-app-pub-3940256099942544/2247696110"
        }
    }

    private var releaseAdUnitID: String {
        switch self {
        case .bannerKey:
            return "ca-app-pub-7049872613588191/4747855668"
        case .interstitial:
            return "ca-app-pub-7049872613588191/5635919690"
        case .native:
            return "ca-app-pub-7049872613588191/7385126578"
        case .miniPlayer:
            return "ca-app-pub-7049872613588191/5977355028"
        case .musicPlayer:
            return "ca-app-pub-3940256099942544/2435281174"
        }
    }
}

var GOOGLE_ADMOB_KEY: String { AdMobUnit.bannerKey.adUnitID }
var GOOGLE_ADMOB_INTER: String { AdMobUnit.interstitial.adUnitID }
var GOOGLE_ADMOB_NATIVE: String { AdMobUnit.native.adUnitID }
var GOOGLE_ADMOB_ForMiniPlayer: String { AdMobUnit.miniPlayer.adUnitID }
var GOOGLE_ADMOB_ForMusicPlayer: String { AdMobUnit.musicPlayer.adUnitID }

let ONESIGNAL_APP_KEY                =     "cc867855-4271-4909-aa4b-24a48b4319f7"
let SECONDS_BEFORE_SHOW_INTERSTITIAL =     10
let SHOW_PODCAST                     =     true    // true - show modules , false - hide module
let SHOW_ABOUT                       =     true
let SHOW_NEWS                        =     true
let SHOW_TIMELINE                    =     true
let DOWNLOAD_PODCAST                 =     true
let LOCAL_NOTIFICATION               =     false
let FACEBOOK_URL                     =     "https://facebook.com/radiosrood"
let GOOGLE_URL                       =     "https://instagram.com/radiosrood"
let TWITTER_URL                      =     "https://twitter.com/radiosrood"
var screenSize: CGSize {
    return UIScreen.main.bounds.size
}




