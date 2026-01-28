import UIKit
import SWRevealViewController
import Alamofire
import AlamofireImage
import GoogleMobileAds
import StoreKit
import MediaPlayer
import AVKit
import AVPlayerViewControllerSubtitles
import SpotlightLyrics

protocol MusicPlayerViewControllerDelegate: AnyObject {
    func dismissMusicPlayer()
}

 struct LyricLine {
    let time: TimeInterval
    let text: String
}

class MusicPlayerViewController: UIViewController, GADBannerViewDelegate, AdsAPIViewDelegate {
    
    @IBOutlet weak var lblLyrics: UILabel!
    @IBOutlet weak var viewLyrics: UIView!
    @IBOutlet weak var heightView: NSLayoutConstraint!
    @IBOutlet weak var radioTableView: UITableView!
    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var tableBgHeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var artCoverImage: UIImageView!
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var artistName: UILabel!
    @IBOutlet weak var playPauseBtn: UIButton!
    @IBOutlet weak var btnBackward: UIButton!
    @IBOutlet weak var btnForward: UIButton!
    @IBOutlet weak var btnDownload: UIButton!
    @IBOutlet weak var btnRepeat: UIButton!
    @IBOutlet weak var lblStartTime: UILabel!
    @IBOutlet weak var lblEndTime: UILabel!
    @IBOutlet weak var playerSlider: UISlider!
    @IBOutlet weak var btnLike: UIButton!
    
    @IBOutlet weak var vwDownloadProgress: UIProgressView!
    var circularProgressView: CircularProgressView!

    @IBOutlet var vwProgress: UIView!
    var isPlayingQueueTrack: Bool = false // New: Tracks if a queue track is playing
    var currentQueueIndex: Int? = nil // New: Tracks the index of the current queue track
    var dataHelper: DataHelper!
    var nativeAd: GADUnifiedNativeAd?
    var adLoader: GADAdLoader!
    var isSetupRemoteTransport = false
    var isPlay: Bool = false
    var track: [Track]?
    var tempTrack: [Track]?
    var firstTrackList: [Track]?
    var selectedIndex: Int = 0
    var homeHeader: HomeHeader = .hotTrackes
    var groupID: Int?
    var isSetMusic = false
    var isLike = false
    var isDownload = false
    var isRepeat = false
    var timeObserver: Any?
    private var lastIndex: Int? = nil
    private var parser: LyricsParser? = nil
    private var isPurchaseSuccess: Bool = false
    private var currentPlayer: AVPlayer? // Track the current player for timeObserver
    // KVO observer for player item status, used to detect HLS failure and fallback
    private var playerItemStatusObserver: NSKeyValueObservation?
    private var hasTriedFallbackForItem: Bool = false
    var bannerAdViews: [GADBannerView] = []
    var imageURl: URL?
    var isMyMusic = false
    var playerListTapCount = 0
    var forwardButtonTapCount = 0
    private var parsedLyrics: [LyricLine] = []
    var isPlayerListTap = false
    var songCounter = 0
    var pendingTrackAfterAd: (index: Int, fromQueue: Bool)?
    var isWaitingForAd = false

    private var lyricSynced: String = ""
        var currentQueueTrack: Track? = nil // New: Stores the current queue track before removal
    override func viewDidLoad() {
        super.viewDidLoad()
              
        let yourBackImage = UIImage(named: "left-arrow")
        self.navigationController?.navigationBar.backIndicatorImage = yourBackImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = yourBackImage
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.topItem?.title = ""
        self.navigationController?.navigationBar.backItem?.title = ""
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItem.Style.plain, target: nil, action: nil)
        radioTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 0.1))
        radioTableView.tableFooterView = UIView()
        loadNativeAd()
        prepareView()
        isSetupRemoteTransport = true
        vwDownloadProgress.isHidden = true
        vwDownloadProgress.setProgress(0.0, animated: false)
        NotificationCenter.default.addObserver(
            self, selector: #selector(didBecomeActiveNotificationReceived),
            name: NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"),
            object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(playerInterruption(notification:)),
            name: NSNotification.Name(rawValue: "AVAudioSessionInterruptionNotification"),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(audioChanged),
            name: .musicDidPlay, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(audioChanged),
            name: .musicDidPause, object: nil
        )
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleIAPPurchase), name: .PurchaseSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleIAPPurchase1), name: .aaaaaaaaaa, object: nil)

        radioTableView.register(UINib(nibName: "BannerAdCell", bundle: nil), forCellReuseIdentifier: "BannerAdCell")
        radioTableView.register(UINib(nibName: "HeaderCell", bundle: nil), forCellReuseIdentifier: "HeaderCell")
        radioTableView.translatesAutoresizingMaskIntoConstraints = false
        radioTableView.isScrollEnabled = false
        radioTableView.rowHeight = UITableView.automaticDimension
        radioTableView.estimatedRowHeight = 90
        setupCircularProgressView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        radioTableView.reloadData()
        manageTableViewScroll()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
            self.navigationController?.navigationBar.shadowImage = UIImage()
            self.navigationController?.navigationBar.isTranslucent = true
        }
        TabbarVC.available?.miniPlayer.miniplayer(hide: true)
        navigationItem.hidesBackButton = true
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Restore navigation bar
        navigationController?.setNavigationBarHidden(false, animated: animated)
        self.popToBack()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        TabbarVC.available?.miniPlayer.miniplayer(hide: false)
        self.dismiss(animated: true)
        if let vc = TabbarVC.available?.selectedViewController as? MusicPlayerViewControllerDelegate {
            vc.dismissMusicPlayer()
        }
    }
    
    deinit {
        UIApplication.shared.endReceivingRemoteControlEvents()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]
        NotificationCenter.default.removeObserver(
            self, name: NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"),
            object: nil)
        NotificationCenter.default.removeObserver(
            self, name: NSNotification.Name(rawValue: "AVAudioSessionInterruptionNotification"),
            object: nil)
        NotificationCenter.default.removeObserver(
            self, name: .musicDidPlay, object: nil
        )
        NotificationCenter.default.removeObserver(
            self, name: .musicDidPause, object: nil
        )
        NotificationCenter.default.removeObserver(self)
        if let timeObserver = timeObserver, let player = currentPlayer {
            player.removeTimeObserver(timeObserver)
        }
        print("Remove screen")
    }

    private func setupCircularProgressView() {
        circularProgressView = CircularProgressView(frame: vwProgress.bounds)
        circularProgressView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        circularProgressView.isHidden = true
        vwProgress.addSubview(circularProgressView)
    }

    func manageTableViewScroll() {
        DispatchQueue.main.async {
            self.radioTableView.reloadData()
            self.radioTableView.layoutIfNeeded()
            
            let mainCount = 2 // Banner + Options
            let trackCount = self.tempTrack?.count ?? 0 // Include all tracks
            let queueCount = PlaybackQueueManager.shared.getQueue().count
            let queueRows = queueCount > 0 ? queueCount + 1 : 0
            let totalRows = mainCount + queueRows + (trackCount > 0 ? 1 : 0) + trackCount
            
            var totalHeight: CGFloat = 0
            totalHeight += IAPHandler.shared.isGetPurchase() ? 0 : 65 // Banner height
            totalHeight += 90 // Options cell height
            totalHeight += queueRows > 0 ? CGFloat(queueRows * 90) : 0 // Queue rows
            totalHeight += trackCount > 0 ? 40 : 0 // "Up Next" header
            totalHeight += CGFloat(trackCount * 90) + 90 // Tracks
            
            self.tableBgHeightConstraints.constant = totalHeight
            print("TableView content height: \(totalHeight), totalRows: \(totalRows), queueCount: \(queueCount), trackCount: \(trackCount), isPlayingQueueTrack: \(self.isPlayingQueueTrack), currentQueueIndex: \(self.currentQueueIndex ?? -1)")
        }
    }

    func prepareView() {
        switch homeHeader {
        case .featured:       loadFeaturedDataItems()
        case .hotTrackes:    loadNewReleaseData()
        case .currentRadio:   break
        case .trending:       loadTrendingPlaylistData()
        case .popularTracks:  loadPopularPlaylistData()
        case .playlists:      loadPlaylistData()
        case .featuredArtist: loadFeaturedArtistData()
        case .myPlaylist:     break
        case .recentlyPlayed: break
        case .todayTopPic:
            loadTodayTopPicData()
        case .recentlyAdded:
            loadRecentlyAddedDetailedData()
        }
    }
    
    @objc func didBecomeActiveNotificationReceived() {
        updateNowPlaying(isPause: true)
    }
    
    @objc func playerInterruption(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        if type == .began {
            player?.pause()
            updateNowPlaying(isPause: false)
        }
        else if type == .ended {
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                    if UIApplication.shared.applicationState == .background {
                        print("App in Background")
                        player?.play()
                        self.setupNowPlaying()
                        self.updateNowPlaying(isPause: true)
                    } else {
                        player?.play()
                    }
                }
            }
        }
    }
    
    private func loadNewReleaseData() {
        dataHelper = DataHelper()
        dataHelper.getNewReleaseData { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.track = resp.newRelease.first(where: { $0.id == self.groupID})?.tracks
                self.tempTrack = self.track
                self.isSetMusic = true
                self.isPlay = true
                self.handleRecentInView(index: self.selectedIndex)
                self.manageTableViewScroll()
            }
        }
    }
    
    private func loadTodayTopPicData() {
        dataHelper = DataHelper()
        print("🚨 loadTodayTopPicData() called with groupID = \(String(describing: self.groupID))")
        dataHelper.getTodayTopPicDetailed { [weak self] resp in
            guard let self = self else { return }
            self.track = []
            self.tempTrack = []
            if let resp = resp {
                print("📥 Received API response for TodayTopPic")
                self.track = resp.todayTopPick.first(where: { $0.playlistID == self.groupID })?.tracks
                self.tempTrack = self.track
                print("🎵 Matched Tracks: \(self.track ?? [])")
                print("📀 Matching Playlist Object: \(String(describing: resp.todayTopPick.first(where: { $0.playlistID == self.groupID })))")
                print("🎯 Current groupID: \(String(describing: self.groupID))")
                print("📚 All playlistIDs from API:")
                for playlist in resp.todayTopPick {
                    print("🆔 \(playlist.playlistID)")
                }
                self.isSetMusic = true
                self.isPlay = true
                self.handleRecentInView(index: self.selectedIndex)
                self.manageTableViewScroll()
            }
        }
    }
    
    func loadRecentlyAddedDetailedData() {
        dataHelper = DataHelper()
        dataHelper.getRecentlyAddedDataDetailed { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.track = resp.recentlyAddedPlayListDetailed.first(where: { $0.playlistID == self.groupID})?.tracks
                self.tempTrack = self.track
                self.isSetMusic = true
                self.isPlay = true
                self.handleRecentInView(index: self.selectedIndex)
                self.manageTableViewScroll()
            }
        }
    }
    
    private func loadFeaturedDataItems() {
        dataHelper = DataHelper()
        dataHelper.getFeaturedArtistSponserdDetailsData { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.track = resp.featuredData.first(where: { $0.fDid == self.groupID})?.featuredItem
                self.tempTrack = self.track
                self.isSetMusic = true
                self.isPlay = true
                self.handleRecentInView(index: self.selectedIndex)
                self.manageTableViewScroll()
            }
        }
    }

    private func loadTrendingPlaylistData() {
        dataHelper = DataHelper()
        dataHelper.getTrendingPlaylistData { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.track = resp.trendingTracks.first(where: { $0.id == self.groupID})?.tracks
                self.tempTrack = self.track
                self.isSetMusic = true
                self.isPlay = true
                self.handleRecentInView(index: self.selectedIndex)
                self.manageTableViewScroll()
            }
        }
    }
    
    private func loadPopularPlaylistData() {
        dataHelper = DataHelper()
        dataHelper.getPopularPlaylistData { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.track = resp.popularTracks.first(where: { $0.id == self.groupID})?.tracks
                self.tempTrack = self.track
                self.isSetMusic = true
                self.isPlay = true
                self.handleRecentInView(index: self.selectedIndex)
                self.manageTableViewScroll()
            }
        }
    }
    
    private func loadPlaylistData() {
        dataHelper = DataHelper()
        dataHelper.getPlaylistData { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.track = resp.trendingPlaylist.first(where: { $0.id == self.groupID})?.tracks
                self.tempTrack = self.track
                self.isSetMusic = true
                self.isPlay = true
                self.handleRecentInView(index: self.selectedIndex)
                self.manageTableViewScroll()
            }
        }
    }
    
    private func loadFeaturedArtistData() {
        dataHelper = DataHelper()
        dataHelper.getFeaturedArtistData { [weak self] resp in
            guard let self = self else { return }
            if let resp = resp {
                self.track = resp.rSroodFeaturedArtistData.first(where: { $0.id == self.groupID})?.tracks
                self.tempTrack = self.track
                self.isSetMusic = true
                self.isPlay = true
                self.handleRecentInView(index: self.selectedIndex)
                self.manageTableViewScroll()
            }
        }
    }
    
    private func parseLyricSynced() {
        parsedLyrics.removeAll()
        let lines = lyricSynced.components(separatedBy: .newlines)
        let regex = try? NSRegularExpression(pattern: #"\[(\d{2}):(\d{2})\.(\d{2})\](.*)"#)
        for line in lines {
            guard let match = regex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                  match.numberOfRanges == 5,
                  let minRange = Range(match.range(at: 1), in: line),
                  let secRange = Range(match.range(at: 2), in: line),
                  let msecRange = Range(match.range(at: 3), in: line),
                  let textRange = Range(match.range(at: 4), in: line)
            else { continue }
            let minutes = Double(line[minRange]) ?? 0
            let seconds = Double(line[secRange]) ?? 0
            let millis = Double(line[msecRange]) ?? 0
            let time = minutes * 60 + seconds + millis / 100
            let text = String(line[textRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            parsedLyrics.append(LyricLine(time: time, text: text))
        }
    }

    func handleRecentInView(index: Int, isQueueTrack: Bool = false) {
        self.artCoverImage.layer.cornerRadius = 3
        self.artCoverImage.layer.masksToBounds = true
        let item = isQueueTrack ? currentQueueTrack : track?[safe: index]
        guard let item = item else {
            print("Error: No track found at index \(index), isQueueTrack: \(isQueueTrack)")
            return
        }
        if let url = URL(string: item.artcover ?? "") {
            self.artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
            self.bgImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "b1.png"))
            imageURl = url
        }
        self.trackTitle.text = item.track
        self.artistName.text = item.artist
        self.isAlreadyLiked(track: item)
        self.isAlreadyDownloaded(track: item)
        if isQueueTrack {
            self.configureRecentlyPlayed()
        } else {
            self.configureRecentlyPlayed(index: index)
        }
        lastIndex = nil
        
        DataHelper.getLyricsData(artist: item.artist ?? "", track: item.track ?? "") { lyricItem in

            guard let lyricItem = lyricItem else {
                print("⚠️ No lyrics found.")
                DispatchQueue.main.async {
                    self.hideLyrics()
                }
                return
            }

            let synced = lyricItem.syncedLyrics.trimmingCharacters(in: .whitespacesAndNewlines)
            let plain  = lyricItem.plainLyrics.trimmingCharacters(in: .whitespacesAndNewlines)

            DispatchQueue.main.async {
                if !synced.isEmpty {
                    // ✅ Prefer synced lyrics
                    self.lyricSynced = synced
                    self.parseLyricSynced()
                    self.showLyrics()
                    self.lblLyrics.text = ""
                } else if !plain.isEmpty {
                    // ✅ Fallback to plain lyrics
                    self.lyricSynced = plain   // safe for passing to other views
                    self.parser = nil          // no parser for plain lyrics
                    self.showLyrics()
                    self.lblLyrics.text = plain
                } else {
                    // ❌ No lyrics at all
                    self.hideLyrics()
                }
            }
        }

        // Prefer HLS; fallback to MP3
        let urls = self.playbackURLs(for: item)
        if let primary = urls.primary {
            if isSetMusic {
                isSetMusic = false
                self.play(url: primary, isPlay: self.isPlay, fallbackURL: urls.fallback)
            }
        } else if let fallback = urls.fallback {
            if isSetMusic {
                isSetMusic = false
                self.play(url: fallback, isPlay: self.isPlay, fallbackURL: nil)
            }
        } else {
            print("Error: Invalid media URL for track \(item.track ?? "Unknown")")
            pausePlayer()
        }
        AppPlayer.miniPlayerInfo = BasicDetail(
            songImage: item.artcover ?? "",
            songNameTitle: item.track ?? "",
            artistSubtitle: item.artist ?? "",
            musicVC: self
        )
    }
    
    // Build primary (HLS) and fallback (MP3) URLs for a Track
    private func playbackURLs(for track: Track) -> (primary: URL?, fallback: URL?) {
        var primaryURL: URL? = nil
        var fallbackURL: URL? = nil

        if let hls = track.hlsMediaPath?.trimmingCharacters(in: .whitespacesAndNewlines), !hls.isEmpty {
            // hlsMediaPath may be full URL or a path component
            if let url = URL(string: hls), url.scheme != nil {
                primaryURL = url
            } else if let encoded = hls.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: hlsSongPath + encoded) {
                primaryURL = url
            }
        }

        if let media = track.mediaPath?.trimmingCharacters(in: .whitespacesAndNewlines), !media.isEmpty {
            if let url = URL(string: media), url.scheme != nil {
                fallbackURL = url
            } else if let encoded = media.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: songPath + encoded) {
                fallbackURL = url
            }
        }

        return (primaryURL, fallbackURL)
    }
    
    private func showLyrics() {
        self.heightView.constant = 40
        self.viewLyrics.isHidden = false
    }

    private func hideLyrics() {
        self.heightView.constant = 0
        self.viewLyrics.isHidden = true
        self.parser = nil
        self.lblLyrics.text = ""
    }

    func showLyric(toTime time: TimeInterval) {
        guard !parsedLyrics.isEmpty else { return }
        guard let index = parsedLyrics.firstIndex(where: { $0.time >= time }) else {
            return
        }
        guard lastIndex == nil || index - 1 != lastIndex else {
            return
        }
        if index > 0 {
            let line = parsedLyrics[index - 1]
            self.lblLyrics.text = line.text
            lastIndex = index - 1
            print("🎵 Lyric: \(line.text)")
        }
    }

    @objc func lyricsBtnClicked() {
        let item: Track?
        if isPlayingQueueTrack, let queueTrack = currentQueueTrack {
            item = queueTrack
            print("Opening lyrics for queue track: \(queueTrack.track ?? "Unknown")")
        } else if let upNextItem = track?[safe: selectedIndex] {
            item = upNextItem
            print("Opening lyrics for Up Next track: \(upNextItem.track ?? "Unknown") at index \(selectedIndex)")
        } else {
            print("Error: No track for lyrics")
            return
        }
        guard let trackItem = item else { return }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "LyricPlayViewController") as! LyricPlayViewController
        vc.currentSong = trackItem.convertToSongModel()
        vc.imageURl = self.imageURl
        vc.lyricnew = self.lyricSynced
        self.present(vc, animated: true)
    }

    @objc func optionMenuBtnClicked() {
        let item: Track?
        if isPlayingQueueTrack, let queueTrack = currentQueueTrack {
            item = queueTrack
            print("Opening options for queue track: \(queueTrack.track ?? "Unknown")")
        } else if let upNextItem = track?[safe: selectedIndex] {
            item = upNextItem
            print("Opening options for Up Next track: \(upNextItem.track ?? "Unknown") at index \(selectedIndex)")
        } else {
            print("Error: No track for options")
            return
        }
        guard let trackItem = item else { return }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlayerOptionViewController") as! PlayerOptionViewController
        vc.currentSong = trackItem.convertToSongModel()
        vc.track = trackItem
        vc.lyricsNew = self.lyricSynced
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }

    @objc func moreInfoBtnClicked() {
        let item: Track?
        if isPlayingQueueTrack, let queueTrack = currentQueueTrack {
            item = queueTrack
            print("Opening more info for queue track: \(queueTrack.track ?? "Unknown")")
        } else if let upNextItem = track?[safe: selectedIndex] {
            item = upNextItem
            print("Opening more info for Up Next track: \(upNextItem.track ?? "Unknown") at index \(selectedIndex)")
        } else {
            print("Error: No track for more info")
            return
        }
        guard let trackItem = item else { return }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlayListViewController") as! PlayListViewController
        vc.songToSave = trackItem.convertToSongModel()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    @objc func addToCollection() {
        isMyMusic = !isMyMusic
        let item: Track?
        if isPlayingQueueTrack, let queueTrack = currentQueueTrack {
            item = queueTrack
            print("Adding to collection: Queue track \(queueTrack.track ?? "Unknown")")
        } else if let upNextItem = track?[safe: selectedIndex] {
            item = upNextItem
            print("Adding to collection: Up Next track \(upNextItem.track ?? "Unknown") at index \(selectedIndex)")
        } else {
            print("Error: No track to add to collection")
            return
        }
        guard let trackItem = item?.convertToSongModel() else {
            print("Error: Failed to convert track to SongModel")
            return
        }
        var savedTracks = UserDefaultsManager.shared.localTracksData
        let trackIndex = savedTracks.firstIndex(where: { $0.trackid == trackItem.trackid })
        if let trackIndex = trackIndex {
            savedTracks[trackIndex].isBookMarked = !savedTracks[trackIndex].isBookMarked
            if savedTracks[trackIndex].isBookMarked {
                showToast(message: "Successfully add in My Collection", font: .systemFont(ofSize: 12.0))
            } else {
                showToast(message: "Remove from my collection", font: .systemFont(ofSize: 12.0))
            }
        } else {
            var newItem = trackItem
            newItem.isBookMarked = true
            savedTracks.append(newItem)
            showToast(message: "Successfully add in My Collection", font: .systemFont(ofSize: 12.0))
        }
        UserDefaultsManager.shared.localTracksData = savedTracks
        radioTableView.reloadData()
    }
    

    
    @objc func backwardBtnPressed() {
        print("Backward pressed, selectedIndex: \(selectedIndex), track count: \(track?.count ?? 0), isPlayingQueueTrack: \(isPlayingQueueTrack)")
        if isPlayingQueueTrack {
            // Handle backward for queue tracks (optional: could skip to previous queue track or revert to Up Next)
            if let queueIndex = currentQueueIndex, queueIndex > 0 {
                print("Playing previous queue track at index: \(queueIndex - 1)")
                playTrackAtIndex(queueIndex - 1, fromQueue: true)
            } else {
                print("No previous queue track, reverting to Up Next or pausing")
                if let track = track, selectedIndex > 0 {
                    isPlayingQueueTrack = false
                    currentQueueIndex = nil
                    playTrackAtIndex(selectedIndex - 1, fromQueue: false)
                } else {
                    pausePlayer()
                }
            }
        } else if let track = track, selectedIndex > 0 {
            // Play the previous track from "Up Next"
            playTrackAtIndex(selectedIndex - 1, fromQueue: false)
        } else {
            // No previous track, restart current or pause
            print("No previous track, pausing")
            pausePlayer()
        }
    }
    
    @objc func forwardBtnPressed() {
        forwardButtonTapCount += 1
        let queue = PlaybackQueueManager.shared.getQueue()
        print("Forward pressed, queue count: \(queue.count), selectedIndex: \(selectedIndex), track count: \(track?.count ?? 0), forwardButtonTapCount: \(forwardButtonTapCount), isPlayingQueueTrack: \(isPlayingQueueTrack), queue: \(queue.map { $0.track ?? "Unknown" })")
        
        // Determine next track
        let nextTrackInfo: (index: Int, fromQueue: Bool)?
        if !queue.isEmpty {
            nextTrackInfo = (0, true)
            print("Next track will be from queue at index 0")
        } else if let track = track, selectedIndex < track.count - 1 {
            nextTrackInfo = (selectedIndex + 1, false)
            print("Next track will be from Up Next at index \(selectedIndex + 1)")
        } else {
            nextTrackInfo = nil
            print("No next track available")
        }
        
        // Check ad condition
        if shouldPlayAdForwardBtnPressed() && !IAPHandler.shared.isGetPurchase() {
            print("Showing ad due to forwardButtonTapCount: \(forwardButtonTapCount)")
            player?.pause()
            
            // Store the next track info to play after ad
            pendingTrackAfterAd = nextTrackInfo
            isWaitingForAd = true
            
            let vc = storyboard?.instantiateViewController(withIdentifier: "AdsAPIView") as! AdsAPIView
            vc.delegate = self
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
            forwardButtonTapCount = 0
        } else {
            // Play immediately if no ad
            if let nextTrack = nextTrackInfo {
                print("Playing next track immediately at index: \(nextTrack.index), fromQueue: \(nextTrack.fromQueue)")
                playTrackAtIndex(nextTrack.index, fromQueue: nextTrack.fromQueue)
            } else {
                print("No more tracks to play")
                pausePlayer()
            }
        }
    }


    private func shouldPlayAdForwardBtnPressed() -> Bool {
        return forwardButtonTapCount >= 6
    }
    
    func adsPlaybackDidFinish() {
        print("🎬 Ad finished, isWaitingForAd: \(isWaitingForAd), pendingTrackAfterAd: \(String(describing: pendingTrackAfterAd))")
        
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            self.isWaitingForAd = false
            
            // Play the pending track stored before showing the ad
            if let pending = self.pendingTrackAfterAd {
                print("▶️ Playing pending track at index: \(pending.index), fromQueue: \(pending.fromQueue)")
                self.playTrackAtIndex(pending.index, fromQueue: pending.fromQueue)
                self.pendingTrackAfterAd = nil
            } else {
                print("⚠️ No pending track after ad, attempting fallback")
                // Fallback logic if no pending track
                let queue = PlaybackQueueManager.shared.getQueue()
                if !queue.isEmpty {
                    print("▶️ Fallback: Playing first queue track")
                    self.playTrackAtIndex(0, fromQueue: true)
                } else if let track = self.track, self.selectedIndex < track.count {
                    print("▶️ Fallback: Playing current Up Next track at \(self.selectedIndex)")
                    self.playTrackAtIndex(self.selectedIndex, fromQueue: false)
                } else {
                    print("❌ No tracks to resume after ad")
                    self.pausePlayer()
                }
            }
        }
    }

    
    private func playNextSong() {
        if let track = track, selectedIndex < track.count - 1 {
            let nextSongIndexPath = IndexPath(row: selectedIndex + 1, section: 0)
            radioTableView.scrollToRow(at: nextSongIndexPath, at: .top, animated: true)
        }
    }

    func shareBtnClicked(url: URL) {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: [])
        vc.modalPresentationStyle = .popover
        if let wPPC = vc.popoverPresentationController {
            wPPC.sourceView = self.view
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func actionLyrics(_ sender: Any) {
        lyricsBtnClicked()
    }
    
    @IBAction func actionClose(_ sender: Any) {
        self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleIAPPurchase() {
        isPurchaseSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: {
            self.isPurchaseSuccess = false
        })
    }
    
    @objc private func handleIAPPurchase1() {
        print("ahsahksajkshajkhsahsa")
    }
    @IBAction func clickOn_btnDownload(_ sender: Any) {
        let purchase = IAPHandler.shared.isGetPurchase()
        if purchase || self.isPurchaseSuccess {
            let item: Track?
            if isPlayingQueueTrack, let queueTrack = currentQueueTrack {
                item = queueTrack
                print("Downloading queue track: \(queueTrack.track ?? "Unknown")")
            } else if let upNextItem = track?[safe: selectedIndex] {
                item = upNextItem
                print("Downloading Up Next track: \(upNextItem.track ?? "Unknown") at index \(selectedIndex)")
            } else {
                print("Error: No track to download")
                return
            }
            guard let trackItem = item else { return }
            // Downloads should still use the MP3 mediaPath
            let urlString = trackItem.mediaPath?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            guard let mediaPathInfo = urlString,
                  let url = URL(string: songPath + mediaPathInfo) else {
                print("Error: Invalid media URL for track \(trackItem.track ?? "Unknown")")
                return
            }
            let name = url.lastPathComponent
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsURL.appendingPathComponent(name)
            btnDownload.isHidden = true
            vwProgress.isHidden = false
            circularProgressView.setProgress(0)
            circularProgressView.isHidden = false
            AF.download(url, to: { _, _ in
                return (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
            })
            .downloadProgress { progress in
                DispatchQueue.main.async {
                    self.circularProgressView.setProgress(Float(CGFloat(Float(progress.fractionCompleted))))
                }
                if progress.fractionCompleted == 1.0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.circularProgressView.setProgress(1.0)
                        self.circularProgressView.lineWidth = 2
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.vwProgress.isHidden = true
                            self.btnDownload.isHidden = false
                            self.isDownload = true
                            self.circularProgressView.resetProgress()
                            let image = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
                            self.btnDownload.setImage(image, for: .normal)
                            self.btnDownload.tintColor = .systemGreen
                            self.btnDownload.layer.cornerRadius = 15
                            self.btnDownload.layer.borderColor = UIColor.systemGreen.cgColor
                            self.btnDownload.layer.borderWidth = 2
                            self.btnDownload.clipsToBounds = true
                            self.btnDownload.isUserInteractionEnabled = false
                            // Update download status
                            if self.isPlayingQueueTrack {
                                self.configureDownload() // No index needed, uses currentQueueTrack
                            } else {
                                self.configureDownload(index: self.selectedIndex)
                            }
                        }
                    }
                }
            }
            .response { response in
                if let destinationURL = response.fileURL {
                    print("File downloaded to: \(destinationURL)")
                }
            }
            UserDefaults.standard.set(trackItem.artcover, forKey: "\(url.deletingPathExtension().lastPathComponent)")
        } else {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "IAPVC") as! IAPVC
            vc.isshowbackButton = true
            let navVC = UINavigationController(rootViewController: vc)
            navVC.navigationBar.isHidden = true
            navVC.modalPresentationStyle = .fullScreen
            self.present(navVC, animated: true)
        }
    }

    private func setHeaderData(headerTitle: String) -> UIView {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 30))
        let lblTitle = UILabel(frame: CGRect(x: 15, y: 5, width: screenSize.width - 30, height: 20))
        lblTitle.text = headerTitle
        lblTitle.textColor = .white.withAlphaComponent(1.1)
        lblTitle.font = UIFont(name: "Avenir Next Ultra Light", size: 19)
        containerView.addSubview(lblTitle)
        return containerView
    }
}

extension MusicPlayerViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let mainCount = 2 // Banner + Options
        let trackCount = (tempTrack?.count ?? 0) > 0 ? (tempTrack!.count - 1) : 0 // Skip first track
        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows = queueCount > 0 ? queueCount + 1 : 0
        let totalRows = mainCount + queueRows + (trackCount > 0 ? 1 : 0) + trackCount // Banner, Options, Queue, "Up Next" header (if tracks), Tracks (excluding first)
        print("Row count: mainCount=\(mainCount), queueRows=\(queueRows), trackCount=\(trackCount), total=\(totalRows), queue: \(PlaybackQueueManager.shared.getQueue().map { $0.track ?? "Unknown" })")
        return totalRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows = queueCount > 0 ? queueCount + 1 : 0
        
        print("Configuring cell for row: \(indexPath.row), queueCount: \(queueCount), queueRows: \(queueRows), selectedIndex: \(selectedIndex), isPlayingQueueTrack: \(isPlayingQueueTrack), queue: \(PlaybackQueueManager.shared.getQueue().map { $0.track ?? "Unknown" })")
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BannerAdCell", for: indexPath) as! BannerAdCell
            for subview in cell.vwMain.subviews {
                subview.removeFromSuperview()
            }
            if IAPHandler.shared.isGetPurchase() {
                cell.vwMain.isHidden = true
                cell.heightOfVw.constant = 0
            } else {
                cell.vwMain.isHidden = false
                cell.heightOfVw.constant = 65
            }
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            let bannerView = GADBannerView(adSize: kGADAdSizeBanner)
            bannerView.adUnitID = GOOGLE_ADMOB_ForMusicPlayer
            bannerView.rootViewController = self
            bannerView.delegate = self
            bannerView.load(GADRequest())
            bannerView.frame = cell.vwMain.bounds
            cell.vwMain.addSubview(bannerView)
            return cell
        } else if indexPath.row == 1 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "RecentPlayerOptionCell", for: indexPath) as? RecentPlayerOptionCell else {
                print("Error: Failed to dequeue RecentPlayerOptionCell")
                let fallbackCell = UITableViewCell()
                fallbackCell.textLabel?.text = "Options Unavailable"
                fallbackCell.textLabel?.textColor = .white
                fallbackCell.backgroundColor = .clear
                fallbackCell.selectionStyle = .none
                return fallbackCell
            }
            cell.selectionStyle = .none
            cell.btnLyrics.addTarget(self, action: #selector(lyricsBtnClicked), for: .touchUpInside)
            cell.btnMoreInfo.addTarget(self, action: #selector(moreInfoBtnClicked), for: .touchUpInside)
            cell.btnOption.addTarget(self, action: #selector(optionMenuBtnClicked), for: .touchUpInside)
            cell.btnAddtoCollection.addTarget(self, action: #selector(addToCollection), for: .touchUpInside)
            let item: Track?
            if isPlayingQueueTrack, let queueTrack = currentQueueTrack {
                item = queueTrack
            } else {
                item = track?[safe: selectedIndex]
            }
            let savedTracks = UserDefaultsManager.shared.localTracksData
            let trackIndex = savedTracks.firstIndex(where: { $0.trackid == item?.convertToSongModel().trackid })
            let isBookmarked = trackIndex.flatMap { savedTracks[safe: $0]?.isBookMarked } ?? false
            let imageName = isBookmarked ? "ic_bookmark_fill" : "ic_bookmark"
            cell.btnAddtoCollection.setImage(UIImage(named: imageName), for: .normal)
            return cell
        } else if indexPath.row == 2 && queueRows > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath) as! HeaderCell
            cell.headerLabel.text = "Up Next from Queue"
            print("Total queues=========\(queueCount)")
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.contentView.isUserInteractionEnabled = false
            return cell
        } else if indexPath.row >= 2 && indexPath.row < 2 + queueRows {
            let queue = PlaybackQueueManager.shared.getQueue()
            let queueIndex = indexPath.row - 3
            print("Queue item at row: \(indexPath.row), queueIndex: \(queueIndex), queue.count: \(queue.count), queue: \(queue.map { $0.track ?? "Unknown" })")
            if queueIndex >= 0 && queueIndex < queue.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RecentListCell", for: indexPath) as! RecentListCell
                cell.selectionStyle = .none
                cell.artCoverImage.layer.cornerRadius = 3
                cell.artCoverImage.layer.masksToBounds = true
                let item = queue[queueIndex]
                cell.trackTitle.text = item.track
                cell.artistName.text = item.artist
                if let url = URL(string: item.artcover ?? "" + "?s=200") {
                    cell.artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                    cell.imgBg.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                }
                return cell
            }
            print("Error: Invalid queue index \(queueIndex)")
            return UITableViewCell()
        } else {
            let adjustedRow = indexPath.row - queueRows
            print("Main content at row: \(indexPath.row), adjustedRow: \(adjustedRow), tempTrack.count: \(tempTrack?.count ?? 0), selectedIndex: \(selectedIndex)")
            if adjustedRow == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath) as! HeaderCell
                cell.headerLabel.text = "Up Next"
                cell.selectionStyle = .none
                cell.backgroundColor = .clear
                cell.contentView.isUserInteractionEnabled = false
                return cell
            } else {
                let trackIndex = adjustedRow - 3 + 1 // Start from index 1 to skip first track
                print("Up Next trackIndex: \(trackIndex), tempTrack.count: \(tempTrack?.count ?? 0)")
                if trackIndex >= 1 && trackIndex < tempTrack?.count ?? 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "RecentListCell", for: indexPath) as! RecentListCell
                    cell.selectionStyle = .none
                    cell.artCoverImage.layer.cornerRadius = 3
                    cell.artCoverImage.layer.masksToBounds = true
                    if let item = tempTrack?[trackIndex] {
                        cell.trackTitle.text = item.track
                        cell.artistName.text = item.artist
                        if let url = URL(string: item.artcover ?? "" + "?s=200") {
                            cell.artCoverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                            cell.imgBg.af_setImage(withURL: url, placeholderImage: UIImage(named: "Lav_Radio_Logo.png"))
                        }
                        print("Displaying Up Next track: \(item.track ?? "Unknown") at trackIndex: \(trackIndex), isPlaying: \(trackIndex == selectedIndex && !isPlayingQueueTrack)")
                    } else {
                        print("Error: No track at index \(trackIndex)")
                    }
                    return cell
                }
                print("Error: Invalid track index \(trackIndex)")
                return UITableViewCell()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let queueCount = PlaybackQueueManager.shared.getQueue().count
        let queueRows = queueCount > 0 ? queueCount + 1 : 0
        print("Selected row: \(indexPath.row), queueCount: \(queueCount), queueRows: \(queueRows), isPlayerListTap: \(isPlayerListTap), isPlayingQueueTrack: \(isPlayingQueueTrack), queue: \(PlaybackQueueManager.shared.getQueue().map { $0.track ?? "Unknown" })")
        
        if indexPath.row >= 2 && indexPath.row < 2 + queueRows && indexPath.row != 2 {
            // Queue item selection
            let queueIndex = indexPath.row - 3
            if queueIndex >= 0 && queueIndex < PlaybackQueueManager.shared.getQueue().count {
                let queue = PlaybackQueueManager.shared.getQueue()
                if let selectedQueueTrack = queue[safe: queueIndex] {
                    print("Selected queue track: \(selectedQueueTrack.track ?? "Unknown") at queueIndex: \(queueIndex)")
                    isPlayerListTap = false
                    playTrackAtIndex(queueIndex, fromQueue: true)
                    DispatchQueue.main.async {
                        self.radioTableView.reloadData()
                        self.manageTableViewScroll()
                    }
                } else {
                    print("Error: Queue track not found at index \(queueIndex)")
                }
            } else {
                print("Error: Invalid queue index \(queueIndex)")
            }
        } else if indexPath.row >= 2 + queueRows {
            // "Up Next" item selection
            let adjustedRow = indexPath.row - queueRows
            let trackIndex = adjustedRow - 3 + 1
            if trackIndex >= 1 && trackIndex < tempTrack?.count ?? 0 {
                if let selectedTrack = tempTrack?[safe: trackIndex] {
                    print("Selected Up Next track: \(selectedTrack.track ?? "Unknown") at trackIndex: \(trackIndex)")
                    isPlayerListTap = true
                    playTrackAtIndex(trackIndex, fromQueue: false)
                    playerListTapCount += 1
                    
                    if shouldPlayerListPressed() && !IAPHandler.shared.isGetPurchase() {
                        print("📺 Showing ad due to playerListTapCount: \(playerListTapCount)")
                        isPlayerListTap = true
                        playerListTapCount = 0
                        player?.pause()
                        
                        // Store pending track before showing ad
                        pendingTrackAfterAd = (trackIndex, false)
                        isWaitingForAd = true
                        
                        let vc = storyboard?.instantiateViewController(withIdentifier: "AdsAPIView") as! AdsAPIView
                        vc.delegate = self
                        vc.modalPresentationStyle = .fullScreen
                        self.present(vc, animated: true)
                    }
                    
                    DispatchQueue.main.async {
                        self.radioTableView.reloadData()
                        self.manageTableViewScroll()
                    }
                } else {
                    print("Error: Up Next track not found at index \(trackIndex)")
                }
            } else {
                print("Error: Invalid track index \(trackIndex)")
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

extension MusicPlayerViewController: GADAdLoaderDelegate, GADUnifiedNativeAdLoaderDelegate {
    func loadNativeAd() {
        guard !IAPHandler.shared.isGetPurchase() else {
            return
        }
        adLoader = GADAdLoader(adUnitID: GOOGLE_ADMOB_NATIVE,
                               rootViewController: self,
                               adTypes: [.unifiedNative],
                               options: nil)
        adLoader.delegate = self
        adLoader.load(GADRequest())
    }
    
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADUnifiedNativeAd) {
        guard !IAPHandler.shared.isGetPurchase() else {
            return
        }
        self.nativeAd = nativeAd
        self.manageTableViewScroll()
    }
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        print("\(adLoader) failed with error: \(error.localizedDescription)")
    }
}

extension MusicPlayerViewController {
    private func playTrackAtIndex(_ index: Int, fromQueue: Bool = false) {
        let queue = PlaybackQueueManager.shared.getQueue()
        print("playTrackAtIndex: index=\(index), fromQueue=\(fromQueue), queue count: \(queue.count), track count: \(track?.count ?? 0), queue: \(queue.map { $0.track ?? "Unknown" }), isPlayingQueueTrack: \(isPlayingQueueTrack), currentQueueTrack: \(currentQueueTrack?.track ?? "None")")
        guard let track = fromQueue ? queue : self.track,
              index >= 0, index < track.count else {
            print("Error: Invalid track index \(index) for \(fromQueue ? "queue" : "track")")
            pausePlayer()
            return
        }
        let item = track[index]
        // Build playback URLs and prefer HLS
        let urls = self.playbackURLs(for: item)
        guard let primary = urls.primary ?? urls.fallback else {
            print("Error: Invalid media URL for track \(item.track ?? "Unknown")")
            pausePlayer()
            return
        }
        if !fromQueue {
            selectedIndex = index
            isPlayingQueueTrack = false
            currentQueueIndex = nil
            currentQueueTrack = nil // Clear queue state for Up Next track
            print("Updated selectedIndex to \(index) for Up Next track: \(item.track ?? "Unknown")")
        } else {
            isPlayingQueueTrack = true
            currentQueueIndex = index
            currentQueueTrack = item // Store queue track before removal
            print("Playing queue track: \(item.track ?? "Unknown") at index: \(index)")
        }
        // Reset player completely
        pausePlayer()
        player = nil
        isSetMusic = false
        isPlay = true
        // pass fallback URL so we can switch if HLS fails
        self.play(url: primary, isPlay: true, fallbackURL: urls.primary == nil ? nil : urls.fallback)
        // Update UI with the current track
        handleRecentInView(index: index, isQueueTrack: fromQueue)
        if fromQueue {
            print("Removing queue track at index: \(index), queue before: \(queue.map { $0.track ?? "Unknown" })")
            PlaybackQueueManager.shared.removeFromQueue(at: index)
            print("Queue after removal: \(PlaybackQueueManager.shared.getQueue().map { $0.track ?? "Unknown" })")
            // Update currentQueueIndex to point to the next track, if any
            if queue.count > 1 && index < queue.count - 1 {
                currentQueueIndex = index // Next track is now at the same index due to shift
            } else {
                currentQueueIndex = nil // No more tracks in queue
            }
            DispatchQueue.main.async {
                self.radioTableView.reloadData()
                self.manageTableViewScroll()
            }
        } else {
            print("Playing Up Next track, no queue modification")
        }
    }

    // Main play function with optional fallback URL (HLS primary, MP3 fallback)
    func play(url: URL, isPlay: Bool = false, fallbackURL: URL? = nil) {
        print("Playing URL: \(url)")
        // Ensure previous player is fully cleared
        if let player = player, let timeObserver = timeObserver {
            player.pause()
            player.removeTimeObserver(timeObserver)
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            self.timeObserver = nil
            self.currentPlayer = nil
        }
        hasTriedFallbackForItem = false
        // remove previous observer if any
        playerItemStatusObserver = nil
        let playerItem = AVPlayerItem(url: url)
        // Observe item status to detect failure and switch to fallback if provided
        if let fallback = fallbackURL {
            playerItemStatusObserver = playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, change in
                guard let self = self else { return }
                if item.status == .failed {
                    guard !self.hasTriedFallbackForItem else { return }
                    self.hasTriedFallbackForItem = true
                    print("Primary playback failed, attempting fallback: \(fallback)")
                    DispatchQueue.main.async {
                        // replace current item with fallback
                        let fallbackItem = AVPlayerItem(url: fallback)
                        player?.replaceCurrentItem(with: fallbackItem)
                        // remove observer for old item and observe fallback if needed
                        self.playerItemStatusObserver = fallbackItem.observe(\.status, options: [.new, .initial]) { [weak self] it, _ in
                            guard let self = self else { return }
                            if it.status == .readyToPlay {
                                // update UI duration
                                DispatchQueue.main.async {
                                    self.playerSlider.maximumValue = Float(player?.currentItem?.asset.duration.seconds ?? 0.0)
                                    self.populateLabelWithTime(self.lblEndTime, time: player?.currentItem?.asset.duration.seconds ?? 0.0)
                                }
                            }
                        }
                        player?.play()
                    }
                } else if item.status == .readyToPlay {
                    DispatchQueue.main.async {
                        self.playerSlider.maximumValue = Float(item.asset.duration.seconds)
                        self.populateLabelWithTime(self.lblEndTime, time: item.asset.duration.seconds)
                    }
                }
            }
        } else {
            // If no fallback, still observe readyToPlay to set duration
            playerItemStatusObserver = playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
                guard let self = self else { return }
                if item.status == .readyToPlay {
                    DispatchQueue.main.async {
                        self.playerSlider.maximumValue = Float(item.asset.duration.seconds)
                        self.populateLabelWithTime(self.lblEndTime, time: item.asset.duration.seconds)
                    }
                }
            }
        }
        player = PlayObserver(playerItem: playerItem)
        currentPlayer = player
        self.playerSlider.minimumValue = 0.0
        self.playerSlider.maximumValue = Float(player?.currentItem?.asset.duration.seconds ?? 0.0)
        populateLabelWithTime(self.lblStartTime, time: 0.0)
        populateLabelWithTime(self.lblEndTime, time: player?.currentItem?.asset.duration.seconds ?? 0.0)
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        self.playerSlider.value = 0.0
        playerSlider.setValue(0, animated: true)
        if !isPlay {
            self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
            self.updateNowPlaying(isPause: true)
            player?.pause()
        } else {
            self.playPauseBtn.setImage(UIImage(named: "ic_pause"), for: .normal)
            self.updateNowPlaying(isPause: false)
            let subtitleURL = URL(string: "https://lyric.srood.stream/jostojo?artist=Fardin%20Faryad&track=Aziz%20Jan&api_key=arman")
            let parser = try? Subtitles(file: subtitleURL!, encoding: .utf8)
            player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: .main) { [weak self] time in
                guard let self = self else { return }
                if player?.currentItem?.status == .readyToPlay {
                    let currentSeconds = CMTimeGetSeconds(player?.currentTime() ?? .zero)
                    self.showLyric(toTime: currentSeconds)
                }
            }
            player?.play()
            print("Player started for URL: \(url)")
        }
        self.setupNowPlaying()
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(sender:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 1), queue: DispatchQueue.global(), using: { [weak self] (progressTime) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.playerSlider.value = Float(progressTime.seconds)
                self.populateLabelWithTime(self.lblStartTime, time: progressTime.seconds)
            }
        })
    }

    @objc func playerDidFinishPlaying(sender: Notification) {
        print("🎵 Player finished, songCounter: \(songCounter), isRepeat: \(isRepeat), isPlayerListTap: \(isPlayerListTap), isPlayingQueueTrack: \(isPlayingQueueTrack), isWaitingForAd: \(isWaitingForAd), queue: \(PlaybackQueueManager.shared.getQueue().map { $0.track ?? "Unknown" })")
        
        playerSlider.setValue(0, animated: true)
        populateLabelWithTime(self.lblStartTime, time: 0.0)
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        
        if let timeObserver = timeObserver, let player = currentPlayer {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
            self.currentPlayer = nil
        }
        
        // Don't continue if we're waiting for an ad to finish
        if isWaitingForAd {
            print("⏸️ Waiting for ad to finish, not continuing playback")
            return
        }
        
        songCounter += 1
        if songCounter % 5 == 0 && !IAPHandler.shared.isGetPurchase() {
            print("📺 Showing ad due to songCounter: \(songCounter)")
            displayAdsView()
        } else {
            continuePlaying()
        }
    }


    func displayAdsView() {
        if !IAPHandler.shared.isGetPurchase() {
            player?.pause()
            
            // Determine next track to play after ad
            let queue = PlaybackQueueManager.shared.getQueue()
            if !queue.isEmpty {
                pendingTrackAfterAd = (0, true)
                print("📺 Ad from song finish: Next track will be from queue at index 0")
            } else if let track = track, selectedIndex < track.count - 1 {
                pendingTrackAfterAd = (selectedIndex + 1, false)
                print("📺 Ad from song finish: Next track will be from Up Next at index \(selectedIndex + 1)")
            } else {
                pendingTrackAfterAd = nil
                print("📺 Ad from song finish: No next track available")
            }
            
            isWaitingForAd = true
            
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "AdsAPIView") as! AdsAPIView
            vc.delegate = self
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        }
    }


    func continuePlaying() {
        // Don't continue if we're waiting for an ad
        if isWaitingForAd {
            print("⏸️ Waiting for ad to finish in continuePlaying")
            return
        }
        
        let queue = PlaybackQueueManager.shared.getQueue()
        print("▶️ continuePlaying: isRepeat=\(isRepeat), isPlayerListTap=\(isPlayerListTap), queue count: \(queue.count), selectedIndex: \(selectedIndex), track count: \(track?.count ?? 0), isPlayingQueueTrack: \(isPlayingQueueTrack), queue: \(queue.map { $0.track ?? "Unknown" })")
        
        if isRepeat {
            if isPlayingQueueTrack, let queueIndex = currentQueueIndex {
                print("🔁 Repeating current queue track at index: \(queueIndex)")
                playTrackAtIndex(queueIndex, fromQueue: true)
            } else {
                print("🔁 Repeating current Up Next track at selectedIndex: \(selectedIndex)")
                playTrackAtIndex(selectedIndex, fromQueue: false)
            }
        } else if isPlayerListTap {
            print("▶️ Resuming Up Next track at selectedIndex: \(selectedIndex)")
            playTrackAtIndex(selectedIndex, fromQueue: false)
            isPlayerListTap = false
        } else if !queue.isEmpty {
            if let firstQueueTrack = queue.first {
                print("▶️ Playing next queue track: \(firstQueueTrack.track ?? "Unknown")")
                playTrackAtIndex(0, fromQueue: true)
            } else {
                print("❌ Error: Queue not empty but first track is nil")
                pausePlayer()
            }
        } else if let track = track, selectedIndex < track.count - 1 {
            print("▶️ Playing next Up Next track at index: \(selectedIndex + 1)")
            playTrackAtIndex(selectedIndex + 1, fromQueue: false)
        } else {
            print("⏹️ No more tracks to play")
            pausePlayer()
        }
    }


    func populateLabelWithTime(_ label: UILabel, time: Double) {
        let minutes = Int(time / 60)
        let seconds = Int(time) - minutes * 60
        label.text = String(format: "%02d", minutes) + ":" + String(format: "%02d", seconds)
    }

    @objc func audioChanged() {
        if player?.isPlaying ?? false {
            self.playPauseBtn.setImage(UIImage(named: "ic_pause"), for: .normal)
        } else {
            self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
        }
    }
    
    @IBAction func pausePressed() {
        if player?.isPlaying ?? false {
            player?.pause()
            playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
            updateNowPlaying(isPause: true)
        } else {
            player?.play()
            playPauseBtn.setImage(UIImage(named: "ic_pause"), for: .normal)
            updateNowPlaying(isPause: false)
        }
    }

    @IBAction func likeBtnPressed(_ sender: Any) {
        if isLike {
            btnLike.setImage(UIImage(named: "ic_like"), for: .normal)
            isLike = false
        } else {
            btnLike.setImage(UIImage(named: "ic_like_filled"), for: .normal)
            isLike = true
        }
        if isPlayingQueueTrack {
            configureLike() // No index needed, uses currentQueueTrack
        } else {
            configureLike(index: selectedIndex)
        }
    }

    @IBAction func repeatBtnPressed(_ sender: Any) {
        let image = UIImage(named: "ic_repeat")?.withRenderingMode(.alwaysTemplate)
        self.btnRepeat.setImage(image, for: .normal)
        if isRepeat {
            isRepeat = false
            self.btnRepeat.tintColor = .white
        } else {
            isRepeat = true
            self.btnRepeat.tintColor = .red
        }
    }

    @IBAction func backwardBtnEvent(_ sender: Any) {
        if isLastTrack() {
            return
        }
        self.pausePlayer()
        self.backwardBtnPressed()
    }
    
    func isLastTrack() -> Bool {
        guard let track = track else {
            return false
        }
        return selectedIndex == track.count - 1 && !isPlayingQueueTrack && PlaybackQueueManager.shared.getQueue().isEmpty
    }

    @IBAction func forwardBtnEvent(_ sender: Any) {
        if isLastTrack() {
            return
        }
        isPlayerListTap = false
        self.pausePlayer()
        self.forwardBtnPressed()
    }
    
    @IBAction func progressSliderValueChanged() {
        let seconds: Int64 = Int64(playerSlider.value)
        let targetTime: CMTime = CMTimeMake(value: seconds, timescale: 1)
        player?.seek(to: targetTime)
    }

    func updateNowPlaying(isPause: Bool) {
        if var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo {
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPause ? 0 : 1
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }

    func setupNowPlaying() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            var nowPlayingInfo = [String: Any]()
            nowPlayingInfo[MPMediaItemPropertyArtist] = self.artistName.text
            nowPlayingInfo[MPMediaItemPropertyTitle] = self.trackTitle.text
            nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
            if let image = self.artCoverImage.image {
                if #available(iOS 10.0, *) {
                    DispatchQueue.global(qos: .background).async {
                        let mediaArtwork = MPMediaItemArtwork(boundsSize: image.size) { (size: CGSize) -> UIImage in
                            return image
                        }
                        nowPlayingInfo[MPMediaItemPropertyArtwork] = mediaArtwork
                        DispatchQueue.main.async {
                            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                        }
                    }
                }
            } else {
                print("Error: artCoverImage.image is nil")
            }
        }
    }

    func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            if let player = player {
                if !player.isPlaying {
                    player.play()
                    self.playPauseBtn.setImage(UIImage(named: "ic_pause"), for: .normal)
                    return .success
                }
            }
            return .commandFailed
        }
        commandCenter.pauseCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            if let player = player {
                if player.isPlaying {
                    player.pause()
                    self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
                    return .success
                }
            }
            return .commandFailed
        }
        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            if player != nil {
                self.pausePlayer()
                self.forwardBtnPressed()
                return .success
            }
            return .commandFailed
        }
        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            if player != nil {
                self.pausePlayer()
                self.backwardBtnPressed()
                return .success
            }
            return .commandFailed
        }
    }

    func pausePlayer() {
        if let player = player, let timeObserver = timeObserver {
            player.pause()
            player.removeTimeObserver(timeObserver)
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            self.timeObserver = nil
            self.currentPlayer = nil
        }
        self.playerSlider.setValue(0, animated: true)
        self.populateLabelWithTime(self.lblStartTime, time: 0.0)
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        self.playPauseBtn.setImage(UIImage(named: "ic_play"), for: .normal)
        updateNowPlaying(isPause: true)
        print("Player paused, player: \(player != nil ? "exists" : "nil")")
    }

    private func shouldPlayerListPressed() -> Bool {
        return playerListTapCount >= 6
    }
}

extension MusicPlayerViewController {
    func isAlreadyLiked(track: Track) {
        let savedTracks = UserDefaultsManager.shared.localTracksData
        let isInFav = savedTracks.filter { $0.isFav && $0.trackid == track.trackid }
        isLike = isInFav.count > 0
        btnLike.setImage(UIImage(named: isLike ? "ic_like_filled" : "ic_like"), for: .normal)
        print("Checked like status for track: \(track.track ?? "Unknown"), isLike: \(isLike)")
    }
    
    func isAlreadyDownloaded(track: Track) {
        let savedTracks = UserDefaultsManager.shared.localTracksData
        let isInFav = savedTracks.filter { $0.isDownload && $0.trackid == track.trackid }
        isDownload = isInFav.count > 0
        if isDownload {
            let image = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
            btnDownload.setImage(image, for: .normal)
            btnDownload.tintColor = .systemGreen
            btnDownload.layer.cornerRadius = 15
            btnDownload.layer.borderColor = UIColor.systemGreen.cgColor
            btnDownload.layer.borderWidth = 2
            btnDownload.clipsToBounds = true
            btnDownload.isUserInteractionEnabled = false
        } else {
            btnDownload.setImage(UIImage(named: "ic_download"), for: .normal)
            btnDownload.layer.cornerRadius = 0
            btnDownload.layer.borderWidth = 0
            btnDownload.layer.borderColor = nil
            btnDownload.clipsToBounds = false
            btnDownload.isUserInteractionEnabled = true
        }
        print("Checked download status for track: \(track.track ?? "Unknown"), isDownload: \(isDownload)")
    }
    func configureLike(index: Int? = nil, queueIndex: Int? = nil) {
        let item: Track?
        if isPlayingQueueTrack, let queueTrack = currentQueueTrack {
            item = queueTrack
            print("Configuring like for queue track: \(queueTrack.track ?? "Unknown")")
        } else if let index = index, let upNextItem = track?[safe: index] {
            item = upNextItem
            print("Configuring like for Up Next track: \(upNextItem.track ?? "Unknown") at index \(index)")
        } else {
            print("Error: No track to configure like")
            return
        }
        guard let trackItem = item else { return }
        var savedTracks = UserDefaultsManager.shared.localTracksData
        let trackIndex = savedTracks.firstIndex(where: { $0.trackid == trackItem.trackid })
        if let trackIndex = trackIndex {
            savedTracks[trackIndex].isFav = isLike
        } else {
            let newItem = trackItem.convertToSongModel()
            newItem.isFav = isLike
            savedTracks.append(newItem)
        }
        UserDefaultsManager.shared.localTracksData = savedTracks
    }
    
    func configureDownload(index: Int? = nil, queueIndex: Int? = nil) {
        let item: Track?
        if isPlayingQueueTrack, let queueTrack = currentQueueTrack {
            item = queueTrack
            print("Configuring download for queue track: \(queueTrack.track ?? "Unknown")")
        } else if let index = index, let upNextItem = track?[safe: index] {
            item = upNextItem
            print("Configuring download for Up Next track: \(upNextItem.track ?? "Unknown") at index \(index)")
        } else {
            print("Error: No track to configure download")
            return
        }
        guard let trackItem = item else { return }
        var savedTracks = UserDefaultsManager.shared.localTracksData
        let trackIndex = savedTracks.firstIndex(where: { $0.trackid == trackItem.trackid })
        if let trackIndex = trackIndex {
            savedTracks[trackIndex].isDownload = isDownload
        } else {
            let newItem = trackItem.convertToSongModel()
            newItem.isDownload = isDownload
            savedTracks.append(newItem)
        }
        UserDefaultsManager.shared.localTracksData = savedTracks
    }
    
    func configureRecentlyPlayed(index: Int? = nil, queueIndex: Int? = nil) {
        let item: Track?
        if isPlayingQueueTrack, let queueTrack = currentQueueTrack {
            item = queueTrack
            print("Configuring recently played for queue track: \(queueTrack.track ?? "Unknown")")
        } else if let index = index, let upNextItem = track?[safe: index] {
            item = upNextItem
            print("Configuring recently played for Up Next track: \(upNextItem.track ?? "Unknown") at index \(index)")
        } else {
            print("Error: No track to configure recently played")
            return
        }
        guard let trackItem = item else { return }
        var savedTracks = UserDefaultsManager.shared.localTracksData
        let trackIndex = savedTracks.firstIndex { $0.trackid == trackItem.trackid }
        if let trackIndex = trackIndex {
            savedTracks[trackIndex].isRecentlyPlayed = true
        } else {
            let newItem = trackItem.convertToSongModel()
            newItem.isRecentlyPlayed = true
            savedTracks.append(newItem)
        }
        UserDefaultsManager.shared.localTracksData = savedTracks
    }
}

// Safe subscript extension
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
