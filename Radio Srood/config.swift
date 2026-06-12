
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

let GOOGLE_ADMOB_KEY                 =    IAPHandler.shared.isGetPurchase() ? "" :  "ca-app-pub-7049872613588191/4747855668"
let GOOGLE_ADMOB_INTER               =    IAPHandler.shared.isGetPurchase() ? "" :  "ca-app-pub-7049872613588191/5635919690"
let GOOGLE_ADMOB_NATIVE              =    IAPHandler.shared.isGetPurchase() ? "" :  "ca-app-pub-7049872613588191/7385126578"
let GOOGLE_ADMOB_ForMiniPlayer       =    IAPHandler.shared.isGetPurchase() ? "" :  "ca-app-pub-7049872613588191/5977355028"
let GOOGLE_ADMOB_ForMusicPlayer      =    IAPHandler.shared.isGetPurchase() ? "" :  "ca-app-pub-7049872613588191/7260832328"
let ONESIGNAL_APP_KEY                =     "cc867855-4271-4909-aa4b-24a48b4319f7"
let SHOW_BANNER_ADMOB                =     true // true - show ads, false - not
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




