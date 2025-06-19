
import UIKit

//let BASE_BACKEND_URL =  "http://pamirtech.com/backend/srood/" // your  backend
let BASE_BACKEND_URL =  "https://api.radiosrood.com/static/app/api/rSroodMainRadioData.json" // your  backend
let baseURL = "https://radiosrood.com/api/"
let recentListURL = baseURL + "currentsongappv2.json"
let currentLyricURL = baseURL + "currentlyric.json"
let songPath = "https://mediahost.srood.stream/media/mp3/"
let musicBaseUrl = "https://api.srood.stream/static/app/api/"
let redioHomeURL = musicBaseUrl + "rSroodMusicPageData.json"
let newReleaseURL = musicBaseUrl + "newRelease.json"
let trendingPlaylistURL = musicBaseUrl + "trendingTracks.json"
let popularPlaylistURL = musicBaseUrl + "popularTracks.json"
let playlistURL = musicBaseUrl + "rSroodPlaylistData.json"
let featuredArtistURL = musicBaseUrl + "rSroodFeaturedArtistData.json"
let lyricsURL = "https://api.srood.stream/static/app/lyrics/"
let homeSponserURL = "https://api.srood.stream/static/app/api/rSroodMusicPageData.json"
let homeSponserURL1 = "https://api.srood.stream/static/app/api/FeaturedData.json"

let todayPickURLDetailed = "https://api.app.srood.stream/jostojo?v=today_top_pick&api_key=3bXcLWToFQkTDBqyknaediavkmTwW"
let todayPickURL = "https://radiosrood.com/api/TodayTopPicksData.json"


let recentlyAdded = "https://radiosrood.com/api/RecentlyAddedData.json"
let recentlyAddedDetailed = "https://api.app.srood.stream/jostojo?v=recently_added&api_key=3bXcLWToFQkTDBqyknaediavkmTwW"

let featuredRadio = musicBaseUrl + "FeaturedRadio.json"

let GOOGLE_ADMOB_KEY                 =    IAPHandler.shared.isGetPurchase() ? "" :  "ca-app-pub-7049872613588191/4747855668"
let GOOGLE_ADMOB_INTER               =    IAPHandler.shared.isGetPurchase() ? "" : "ca-app-pub-7049872613588191/5635919690"
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




